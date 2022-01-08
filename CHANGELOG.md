# LrMediaWiki changelog

<<<<<<< HEAD
=======
## v1.5: One issue: Placeholders in Gallery (2022-01-03)

### Fixed issues
- #39: Placeholders in Gallery (enhancement)

>>>>>>> parent of 071f19e... v1.5.1
## v1.4: One issue (2022-01-03)

### Fixed issues
- #41: LrMediaWiki still includes coordinates in the file page when 'Remove Location Info' is selected (enhancement)

## v1.3: Two enhancements (2021-02-27)

### Fixed issues
- #35: Support servers without structured data (enhancement)
- #36: "Caption (en)" should only be set if filled by a value (enhancement)

## v1.2.1: Issues #31 and #33 (2021-02-21)

### Fixed issues
- #31: HTML tags <br> and <hr> are no placeholders (bug)
- #33: Remove warning "The field “Description (other)” is filled, but “Language (other)” is not set." (enhancement)

## v1.2: Support for File captions (2021-01-20)

### Fixed issues
* #9: Support for File captions (enhancement)

## v1.1.2: Issue #26 fixed (2021-01-17)

### Fixed issues
* #26: Location template default should be "On" (bug)

## v1.1.1: Issue #27 (2021-01-16)

### Fixed issues
* #27: As private marked hashtag keywords should be used as categories (enhancement)

## v1.1: Two enhancements and a bug fix (2021-01-13)

### Fixed issues
* #45: Keyword-based categories (enhancement)
* #99: Remove duplicate categories (enhancement)
* #26: Location template default should be "On" (bug)

## v1.0.2: Several enhancements and a bug fix (2021-01-10)

### Fixed issues
- #97: Language (other) must be set for each item (enhancement)
- #100: Exception handling if a variable is empty missing (enhancement)
- #8: MetaWikiMetadataSetAll.lua has no com.adobe.title (bug fix)
- #12: Feature: Update only (enhancement)
- #13: Do not fill location template if "Remove Location Info" is checked (enhancement)
- #22: Current date as placeholder (enhancement)

## v0.8: Several usability improvements, a security improvement and two bug fixes (2017-03-25)

### Fixed issues
- #47: Customize description languages (enhancement)
- #79: Better support of translations (enhancement)
- #80: Additional metadata sets (enhancement)
- #81: Optimization of fields at export dialog (enhancement)
- #82: Consolidation of the plug-in’s names (enhancement)
- #83: Date field (enhancement)
- #84: Format of placeholder <creationDate> (bug)
- #85: Add German template Information (enhancement)
- #86: Alignment of UI elements at export dialog (enhancement)
- #87: Sections of export dialog (enhancement)
- #88: Source and author per file (enhancement)
- #89: Trim category names (enhancement)
- #90: Provide more tooltips (enhancement)
- #91: Additional placeholders derived from creation date (enhancement)
- #92: Encrypted password storage (enhancement)
- #93: Bug of placeholder substitution (bug)

## v0.7.1: Improvement of preview resizing (2017-02-15)

### Fixed issues
- #78: Improve resizing of preview (enhancement)

## v0.7: 4 enhancements (2017-02-13)

"Variables" have been renamed to "placeholders".

### Fixed issues
- #74: Additional variables (enhancement)
- #75: Support of template Object photo (enhancement)
- #76: Improve handling of fields "Other versions" and "Other fields" (enhancement)
- #77: Enhancement of "Preview of generated wikitext" (enhancement)

## v0.6: Introduction of variables (2017-01-14)

This version introduces variables.

### Fixed issues
- #72: Variables (enhancement)
- #73: Number of deleted control characters (bug)

## v0.5.3: Version number update (2017-01-11)

### Fixed issues
- #71: Version 0.5.2 didn't include an updated version number

## v0.5.2: Withdrawal of "Enable search of metadata fields #66" (2017-01-10)
- Withdrawal of #66: "Enable search of metadata fields (enhancement)" –
  this feature can cause an error by updating a catalog

## v0.5.1: 8 issues (2017-01-09)

### Fixed issues
- #62: Improvements of UI messages (enhancement)
- #63: Missing compliance with Lightroom version 4 (bug)
- #64: Version check fails (bug)
- #65: Warnings: Deprecated MediaWiki API calls (login, token) (enhancement)
- #66: Enable search of metadata fields (enhancement)
- #67: Login: Support both, main-accounts and bot-accounts (enhancement)
- #68: Malformed date field (bug)
- #69: Delete invisible control characters (enhancement)

## v0.5: 8 issues (2016-11-19)

### Fixed issues
 - #17: Add Template:Artwork as additional base template (enhancement)
 - #35: Extract direction/heading of the location out of EXIF/metadata (enhancement)

This enhancement is available by users of a Lightroom (LR) version 6 or higher.
The function to retrieve the direction has been introduced by Adobe with
version 6. Therefore this enhancement is not available by users of versions
lower 6.

This enhancement differs several LR versions. Depending on the version,
different information messages are shown (or not):
* LR 6 or higher: If the `Direction` field is set, the user gets informed about
this feature. Uploads of files without a direction setting don’t cause this
information message, because at such cases the user is not affected.
* LR 5: Users get informed, the feature is not available, due to the insufficient
LR version. Adobe introduced the `Direction` field with LR version 5, but forgot
to include it at the corresponding LR SDK 5. Therefore this feature can not be
used by users of LR 5. At release notes of LR SDK 6 this has been mentioned to
be a bug fix of LR SDK 5.
* LR 4: Users of this version are not affected, because Adobe introduced the
`Direction` field with version 5. Therefore users of LR 4 don’t get any
information message.
* LR versions lower 4: These versions are not supported by LrMediaWiki.

The information messages include a “Don’t show again” checkbox (German: „Nicht
erneut anzeigen“). If the user decides, to set this option and decides to
revert this decision later, a reset of warning dialogs at LR is needed:
* English: Edit -> Preferences... -> General -> Prompts -> Reset all warning
dialogs
* German: Bearbeiten -> Voreinstellungen -> Allgemein -> Eingabeaufforderungen
-> Alle Warndialogfelder zurücksetzen

LR can store a direction value with up to 4 digits beyond a decimal point, but
shows at user interface a rounded value without decimal places (by mouse over
the direction field). The information message shows the same rounded value,
to avoid confusion of the user seeing different values. The `{{Location}}`
template parameter `heading` is filled by the stored value of LR.
Sample: A direction input of 359.987654321 is stored as 359.9876, shown as 360°.
At `{{Location}}` template the LR stored value of 359.9876 is set.

 - #50: Support of LR 4
 - #51: Tests of Windows 10 and OS X
 - #52: Replace the placeholders in the wikitext preview with actual data
 - #55: Provide version of Lightroom and used operating system to upload comments
 - #56: Time differences of creation dates
 - #59: Add a plugin specific metadata preset

## v0.4.1: Bugfix for Lightroom 6.2 (2015-10-06)

This bugfix release fixes a typo that caused errors in the new Lightroom version.

### Fixed issues

 - #46: Malformed ZString (missing trailing quote)

## v0.4: Keywords, galleries, updates – and configuration (2015-06-28)

This release adds a configuration section to the plugin settings dialog. In this
section, you can configure the creation of export snapshots (before: always on),
the creation of export keywords (new feature), an automatic update check on
Lightroom starts (new feature) and logging (before: manual activation in a
Lua file). Hopefully, the next version will be the first stable release v1.0!

### Fixed issues
 - #24: Add gallery option (enhancement)
 - #31: Add configuration section in the export dialog (enhancement)
 - #34: Add custom tag when exporting (enhancement)
 - #44: Check for new versions after start (enhancement)

## v0.3.1: Bugfix and beauty (2015-06-27)

Fixes some bugs introduced by the last release v0.3 and aligns the export
dialog more properly.

### Fixed issues
 - #43: Fix errors introduced by refactoring (bug)

## v0.3: Errors (2015-06-27)

This release adds improved error handling or even avoids errors. For example,
the error messages for a missing network connection and for API warnings are
improved. And if the image title contains consecutive spaces or underscores, the
upload will no longer fail without a proper error message (but succeed!).

Furthermore, the file description template is moved in a dedicated text file
making it possible to customize it. As some users requested that, the
permission field is added to the export dialog and a development snapshot is
created after the export.

### Fixed issues
 - #26: Add snapshot on export (enhancement)
 - #27: Add permission field to export dialog (enhancement)
 - #28: Check error message when there is no internet connection (enhancement)
 - #29: Move file description template into a file and improve the string
   formatting (enhancement)
 - #30: Overwrite existing files without adding a description (enhancement)
 - #36: Improve error messages for API errors (enhancement)
 - #37: Ensure the image title does not contain consecutive spaces or
   underscores (enhancement)
 - #38: Date format (enhancement)

## v0.2.3: Bugfix (2014-10-06)

This release fixes a bug that caused all uploads to fail under certain
circumstances and adds image sizing and sharpening options to the export
dialog.

### Fixed issues
 - #22: Add image sizing and sharpening option to export dialog (enhancement)
 - #23: [string "MediaWikiApi.lua"]:68: table index is nil (bug)

## v0.2.2: Bundestag (2014-09-08)

This releases brings a few minor changes needed for uploads for the German
Bundestag project.

### Fixed issues
 - #13: Add LrMediaWiki version to upload comments (enhancement)
 - #14: Add ‘Other templates’ field to metadata (enhancement)
 - #15: Show {{Location}} template in wikitext preview (enhancement)

## v0.2.1: Templates! (2014-08-31)

The third beta release of **LrMediaWiki** improves template handling:  There is
an additional field for templates to be added below `{{Information}}`, but
above the license section, e. g. for `{{Panorama}}` or `{{Personality rights}}`.
Furthermore a `{{Location}}` template is added automatically if there is GPS
metadata.

### Fixed issues
 - #10: Show file settings section in export dialog (enhancement)
 - #11: Add ‘other templates’ field (enhancement)
 - #12: Add {{Location}} if GPS metadata is set (enhancement)

## v0.2: New metadata and improved reuploads (2014-08-25)
The second beta release of **LrMediaWiki** moves the per-file metadata
(description and categories) to dedicated metadata fields.  Furthermore the
behaviour for file reuploads is improved (allows version comments and file
renaming).

*Requires catalog update.*

### Fixed issues
 - #3: License dropdown (enhancement)
 - #5: Ask for comment for reuploads (enhancement)
 - #6: Allow new filenames for duplicates (enhancement)
 - #7: Move per-file data to custom metadata (enhancement)
 - #8: Remove fallback description (enhancement)
 - #9: Add "Preview generated wikitext" button to export dialog (enhancement)

## v0.1: First beta version (2014-08-21)
This is the first beta version of **LrMediaWiki**, a plugin that provides
MediaWiki support for Lightroom.  It adds the Export method *MediaWiki*.
See [Commons:LrMediaWiki][comlrmw] on Wikimedia Commons for usage information.

[comlrmw]: https://commons.wikimedia.org/wiki/Commons:LrMediaWiki
