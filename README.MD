Named Entity Redactor
=====================

![This script was last tested in Nuix 7.8](https://img.shields.io/badge/Script%20Tested%20in%20Nuix-7.8-green.svg)

View the GitHub project [here](https://github.com/Nuix/Named-Entity-Redactor) or download the latest release [here](https://github.com/Nuix/Named-Entity-Redactor/releases).

# Overview

**Written By:** Jason Wells

This script generates custom metadata fields with "redacted" versions of metadata property and item text values.  The values redacted are based on named entity matches on items in a case.

Imagine an example item with the following content text and named entity matches.  **Note:** Example data below was generated entirely randomly.

**Content Text**

```
Hello Von,
  
Are we really charging $5.33 for Aerodynamic Paper Plate?  Being made of Wooden that seems too cheap!
And with that we move on to:
I acquired the following credit card numbers: 4321246058941234, 4321-319681-51234



Bailey
noelia.bailey@fake.com
408-555-5567
```

| Entity Type | Matches |
|-------------|---------|
| `credit-card-num` | `4321246058941234`, `4321-319681-51234` |
| `email` | `noelia.bailey@fake.com` |
| `money` | `$5.33` |
| `person` | `Von`, `Bailey` |
| `phone-number` | `408-555-5567` |

This script can create a copy of the content text (stored in a custom metadata field) with the named entity matches redacted like so:

```
Hello [REDACTED PERSON], 
  
Are we really charging [REDACTED MONEY] for Aerodynamic Paper Plate?  Being made of Wooden that seems too cheap! 
And with that we move on to: 
I acquired the following credit card numbers: [REDACTED CREDIT-CARD-NUM], [REDACTED CREDIT-CARD-NUM]

[REDACTED PERSON] 
[REDACTED EMAIL] 
[REDACTED PHONE-NUMBER]
```

The script can perform the same process for select metadata properties of items as well.

# Getting Started

## Setup

Begin by downloading the latest release of this code.  Extract the contents of the archive into your Nuix scripts directory.  In Windows the script directory is likely going to be either of the following:

- `%appdata%\Nuix\Scripts` - User level script directory
- `%programdata%\Nuix\Scripts` - System level script directory

## Script Settings

### Main Tab

| Setting | Description |
|---------|-------------|
| **Process Properties** | Whether redacted copies should be made for metadata properties. Specific properties scanned can be configure on the **Properties Processed** tab.|
| **Process Item Content Text** | Whether redacted copies should be made for items' content text. |
| **Only Record Changes** | Only record custom metadata fields for values in which a redaction was actually performed. |
| **Redaction Template** | A template used to specify what the replacement value should be in the redacted copy.  The placeholder `{entity_name}` will be replaced with the name of the appropriate named entity.  For example if the template is `[REDACTED {entity_name}]` and an `email` named entity is redacted, the replacement text will be `[REDACTED EMAIL]`. |
| **Custom Metadata Field Prefix** | Custom metadata fields used to record redacted copies of value will be named either after the property the original value came from or `ContentText` for an item's content text.  This value allows you to specify a prefix to be added to that custom metadata field's name.  For example, for a property named `From`, a prefix of `R_` will yield a custom metadata field being created named `R_From`.  This value can be left blank if you do not wish to have a prefix added to the custom metadata field names. |
| **Record Redaction Time Stamp** | Determines whether a custom metadata field will be assigned to items which are updated to record when the values were last updated. |
| **Redaction Time Stamp Field Name** | Named of custom metadata field used to store redaction time stamp when **Record Redaction Time Stamp** is checked. |
| **Save Redaction Profile to System** | When checked, the script will generate a metadata profile containing derived fields for each metadata property updated.  Each derived field uses "first non-blank" logic, first looking to the custom metadata redacted copy field, then looking to the normal base property value. Due to complications around creating a metadata profile from a script, currently the profile can only be saved to the system level profile store.  On windows this directory is usually `%appdata%\Nuix\Metadata Profiles`.|
| **Redaction Profile Name** | The name of the metadata profile to create when **Save Redaction Profile to System** is checked.  Cannot conflict with name of existing metadata profiles (script will warn you if this is detected). |

### Entities Processed Tab

On this tab you may select 1 or more named entities to have redactions made for.  At least 1 named entity must be selected.

### Properties Processed Tab

On this tab you may select 1 or more metadata properties to have redactions made for.  When **Process Properties** is checked on the main tab, at least one metadata property from this list must be selected.

## Cloning this Repository

This script relies on code from [Nx](https://github.com/Nuix/Nx) to present a settings dialog and progress dialog.  This JAR file is not included in the repository (although it is included in release downloads).  If you clone this repository, you will also want to obtain a copy of Nx.jar by either:
1. Building it from [the source](https://github.com/Nuix/Nx)
2. Downloading an already built JAR file from the [Nx releases](https://github.com/Nuix/Nx/releases)

Once you have a copy of Nx.jar, make sure to include it in the same directory as the script.

This script also relies on code from [SuperUtilities](https://github.com/Nuix/SuperUtilities), which contains the code to do the report generation.  This JAR file is not included in the repository (although it is included in release downloads).  If you clone this repository, you will also want to obtain a copy of SuperUtilities.jar by either:
1. Building it from [the source](https://github.com/Nuix/SuperUtilities)
2. Downloading an already built JAR file from the [Nx releases](https://github.com/Nuix/SuperUtilities/releases)

Once you also have a copy of SuperUtilities.jar, make sure to include it in the same directory as the script.

# License

```
Copyright 2019 Nuix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```