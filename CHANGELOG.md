# LrMediaWiki changelog

## v0.4.2: 

- Issue [#35]: Extract direction/heading of the location out of EXIF/metadata (enhancement)
[#35]: https://github.com/robinkrahl/LrMediaWiki/issues/35

The development of this pre-release of version 0.4.2 is considered to be finished, now several use cases are tested.
The pre-release is shared for tests and code inspections, it's not yet intended to be merged with the major branch of LrMediaWiki.

The enhancement is available by users of a Lightroom (LR) version >= 6.
The version dependency is caused by Adobe: The function to retrieve the direction has been
introduced by Adobe at LR and LR SDK version 6.0, stated to be a bug fix.
Therefore this enhancement is not available by users of a LR version < 6, like LR 5 or LR 4.

This enhancement introduces a LR version check during export. The version check differs two cases of major LR versions: (a) >= 6 and (b) < 6

At both cases a hint message box is shown – with different messages, depending on the LR version:
* (a) Users of a LR version 6 or higher get informed about this feature, if the user has set the `Direction` field.
* (b) Users of a LR version 5 or 4 get informed, the feature is not available, due to the insufficient LR version.

At both cases the hint message box includes a "Don't show again" (German: "Nicht erneut anzeigen") checkbox.
If the user decides, to set this option and decides to revert this decision later, a reset of warning dialogs at LR is needed:
* English: Edit -> Preferences... -> General -> Prompts -> Reset all warning dialogs
* German: Bearbeiten -> Voreinstellungen -> Allgemein -> Eingabeaufforderungen -> Alle Warndialogfelder zurücksetzen

At users with a LR version >= 6:

LR can store a direction value with up to 4 digits beyond a decimal point,
but shows at user interface a rounded value without decimal places (by mouse over the direction field).
Showing a rounded value is done by the two LrMediaWiki hint messages too, to avoid confusion of the user seeing different values.
The `Location` template parameter `heading` is filled by the storage value of LR.
Sample: A LR direction input of 359.987654321 is stored by LR as 359.9876, shown by LR and by the hint messages
as 360°, at Location template the LR stored value of 359.9876 is set.

Comments by Eckhard Henkel:
Today (February 3, 2016), I consider the development of the enhancement to be complete.
At this stadium of development and testing, most of my recent tests show expected results.
Exceptions/restrictions are described at this section later.
As a next step, code inspections and/or tests by other users can be done.
My next steps are, to check a comprehensive set of test cases, using
* 3 different LR versions (LR 6, 5, 4)
* 2 different operating systems (Windows, OS X)
* 2 different LR language settings (English, German)

In summary, there are 3 x 2 x 2 = 12 test cases. I'm able to do these tests, because I own licenses of the 3 LR versions and have access to machines running the both operating systems supported by Adobe, Windows and OS X.

In general, I don't intend, to perform these comprehensive test cases in future, due to the high effort.
But it seems to me, it's useful, to do these tests at minimum once. The need to test different LR versions
is caused by the need to test the implemented LR version check.

The aim of these multiple test cases is
* to test the new enhancement under several conditions
* to test LrMediaWiki in general, if it works with different LR versions and operating systems.

It seems to me, up to now LrMediaWiki has been tested only using LR version 5, running at Windows,
using English and German LR language settings.
As a side effect of my changes and tests, a compatibility with LR version 4
could be achieved by setting "LrSdkMinimumVersion = 4.0" at file "info.lua".
Prior of this change, at LR 4 the plug-in manager mentioned, the plug-in has been installed, but works improperly.
Maybe, this small change is out of interest. Maybe, there are users, still working with LR 4. I don't know.

LR versions < 4 are out of my interests, because I don't own licences of these "ancient" versions and I assume, there is no need, to let LrMediaWiki be compliant with antique LR versions.

However, potential users of LrMediaWiki, using the old version LR 4, could be affected by this change.

Up to now, this description section is not complete and is a matter of change.
The results of the comprehensive version test set I will describe here in next days, after completion of these tests.
At the moment it seems, LrMediaWiki works with LR 4 and OS X is supported – with a restriction:
* The localized descriptions (in German) are not loaded.

This means, messages are shown in English, even the LR user has set e.g. German as interface language.
I will examine in detail, which test cases cause this behaviour.
Until now I have only one idea, what could trigger this effect: the version of the included "JSON.lua" package, http://regex.info/blog/lua/json. This is only an assumption. Any hint to get rid of this restriction are welcome!

## v0.4.1: Bugfix for Lightroom 6.2

This bugfix releases fixes a typo that caused errors in the new Lightroom
version.

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
