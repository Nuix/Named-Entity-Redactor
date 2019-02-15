script_directory = File.dirname(__FILE__)
require File.join(script_directory,"Nx.jar")
java_import "com.nuix.nx.NuixConnection"
java_import "com.nuix.nx.LookAndFeelHelper"
java_import "com.nuix.nx.dialogs.ChoiceDialog"
java_import "com.nuix.nx.dialogs.TabbedCustomDialog"
java_import "com.nuix.nx.dialogs.CommonDialogs"
java_import "com.nuix.nx.dialogs.ProgressDialog"
java_import "com.nuix.nx.dialogs.ProcessingStatusDialog"
java_import "com.nuix.nx.digest.DigestHelper"
java_import "com.nuix.nx.controls.models.Choice"

LookAndFeelHelper.setWindowsIfMetal
NuixConnection.setUtilities($utilities)
NuixConnection.setCurrentNuixVersion(NUIX_VERSION)

require File.join(script_directory,"SuperUtilities.jar")
java_import com.nuix.superutilities.namedentities.NamedEntityUtility
java_import com.nuix.superutilities.namedentities.NamedEntityRedactionSettings
java_import com.nuix.superutilities.query.QueryHelper
java_import com.nuix.superutilities.SuperUtilities
$su = SuperUtilities.init($utilities,NUIX_VERSION)

# =====================
# Collect choices
# =====================

named_entity_choices = $current_case.getAllEntityTypes.map{|en| Choice.new(en,en,"Named Entity #{en}",true)}
property_choices = $current_case.getMetadataItems.select{|mi|mi.getType == "PROPERTY"}.sort_by{|mi|mi.getName}
property_choices = property_choices.map{|mi| Choice.new(mi,mi.getName,"Property: #{mi.getName}",true)}

# =====================
# Build Settings Dialog
# =====================
dialog = TabbedCustomDialog.new("Named Entity Redactor")

main_tab = dialog.addTab("main_tab","Main")
if $current_selected_items.nil? == false && $current_selected_items.size > 0
	main_tab.appendRadioButton("use_selected_items","Used #{$current_selected_items.size} selected items","input_items_grp",true)
	main_tab.appendRadioButton("use_search_items","Use all items in case with relevant named entities","input_items_grp",false)
else
	main_tab.appendRadioButton("use_search_items","Use all items in case with relevant named entities","input_items_grp",true)
end
main_tab.appendCheckBox("process_properties","Process Properties",true)
main_tab.appendCheckBox("process_content_text","Process Item Content Text",true)
main_tab.appendCheckBox("only_record_changes","Only Record Changed Values",true)
main_tab.appendTextField("redaction_template","Redaction Template","[REDACTED {entity_name}]")
main_tab.appendTextField("cm_field_prefix","Custom Metadata Field Prefix","R_")
main_tab.appendCheckBox("record_time_stamp","Record Redaction Time Stamp",true)
main_tab.appendTextField("redaction_time_stamp_field","Redaction Time Stamp Field Name","TextualRedactionUpdated")
main_tab.enabledOnlyWhenChecked("redaction_time_stamp_field","record_time_stamp")
main_tab.appendCheckBox("save_redaction_profile","Save Redaction Profile to System",false)
profile_time_stamp = org.joda.time.DateTime.now.toString("YYYYMMdd")
main_tab.appendTextField("redaction_profile_name","Redaction Profile Name","RedactedFields_#{profile_time_stamp}")
main_tab.enabledOnlyWhenChecked("redaction_profile_name","save_redaction_profile")

entity_tab = dialog.addTab("entity_tab","Entities Processed")
entity_tab.appendChoiceTable("named_entities","Named Entities",named_entity_choices)

property_tab = dialog.addTab("property_tab","Properties Processed")
property_tab.appendChoiceTable("selected_properties","Properties To Redact",property_choices)

# ======================
# Validate User Settings
# ======================
dialog.validateBeforeClosing do |values|
	if values["process_properties"] && values["selected_properties"].size < 1
		CommonDialogs.showWarning("Please select at least 1 property on the 'Properties Processed' tab.")
		next false
	end

	if values["named_entities"].size < 1
		CommonDialogs.showWarning("Please select at least 1 named entity on the 'Entities Processed' tab.")
		next false
	end

	if !values["process_properties"] && !values["process_content_text"]
		CommonDialogs.showWarning("Please select 'Process Properties' and/or 'Process Item Content Text' on the 'Main' tab.")
		next false
	end

	existing_case_profile_names = {}
	$utilities.getMetadataProfileStore.getMetadataProfiles.map{|p|p.getName}.each{|p| existing_case_profile_names[p] = true}
	if values["save_redaction_profile"] && existing_case_profile_names[values["redaction_profile_name"]] == true
		CommonDialogs.showWarning("It appears there is already a case level profile named '#{values["redaction_profile_name"]}', please choose a different name.")
		next false
	end

	if values["redaction_template"].strip.empty?
		# Get user to confirm that they are about to remove some tags
		message = "You have provided a blank redaction template, meaning it will not be clear where text was removed in values, proceed?"
		title = "Proceed with Blank Redaction Template?"
		confirmed = CommonDialogs.getConfirmation(message,title)
		next false if confirmed == false
	end

	next true
end

# ==============================
# Display Dialog and Do the Work
# ==============================
dialog.display
if dialog.getDialogResult == true
	values = dialog.toMap

	use_selected_items = values["use_selected_items"]
	cm_field_prefix = values["cm_field_prefix"]
	only_record_changes = values["only_record_changes"]
	redaction_template = values["redaction_template"]
	process_properties = values["process_properties"]
	process_content_text = values["process_content_text"]
	named_entities = values["named_entities"]
	selected_properties = values["selected_properties"].map{|p|p.getName}
	record_time_stamp = values["record_time_stamp"]
	redaction_time_stamp_field = values["redaction_time_stamp_field"]
	save_redaction_profile = values["save_redaction_profile"]
	redaction_profile_name = values["redaction_profile_name"]

	ProgressDialog.forBlock do |pd|
		pd.setTitle("Named Entity Redactor")
		pd.setAbortButtonVisible(false)

		redaction_settings = NamedEntityRedactionSettings.new
		
		redaction_settings.setOnlyRecordChanges(only_record_changes)
		redaction_settings.setRedactionReplacementTemplate(redaction_template)
		redaction_settings.setRedactProperties(process_properties)
		redaction_settings.setRedactContentText(process_content_text)
		redaction_settings.addEntityNames(named_entities)
		redaction_settings.setSpecificProperties(selected_properties)
		redaction_settings.setRecordTimeOfRedaction(record_time_stamp)
		redaction_settings.setTimeOfRedactionFieldName(redaction_time_stamp_field)

		named_entity_utility = NamedEntityUtility.new
		last_progress = Time.now

		named_entity_utility.whenProgressUpdated do |current,total,results|
			if (Time.now - last_progress) > 1
				pd.setMainProgress(current,total)
				pd.setMainStatus("Processing Item #{current}/#{total}, Items Updated: #{results.getUpdatedItemCount}")
				pd.logMessage("#{Time.now} Processing Item #{current}/#{total}, Items Updated: #{results.getUpdatedItemCount}")
				last_progress = Time.now
			end
		end

		named_entity_utility.whenMessageGenerated do |message|
			pd.logMessage(message)
		end

		result = nil
		if use_selected_items
			result = named_entity_utility.recordRedactedCopies($current_case,$current_selected_items,redaction_settings)
		else
			result = named_entity_utility.recordRedactedCopies($current_case,redaction_settings)
		end
		pd.logMessage(result.toString)

		named_entity_query = QueryHelper.namedEntityQuery(redaction_settings.getEntityNames)
		if save_redaction_profile
			redaction_profile_path = File.join('C:\ProgramData\Nuix\Metadata Profiles',"#{redaction_profile_name}.profile")
			pd.logMessage("Saving profile to: #{redaction_profile_path}")
			NamedEntityUtility.saveRedactionProfile(redaction_profile_path,result,redaction_settings)
		end

		# Note that we dont use the profile we may have just created above.  This is because in my testing it randomly
		# fails sometimes if you do try to immediately open a tab using the profile you just created.  To reduce people
		# reporting errors for something the script cannot address, we don't try to immediately load that profile.
		$window.openTab("workbench",{"search"=>named_entity_query})

		pd.setCompleted
	end
end