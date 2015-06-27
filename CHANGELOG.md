# LrMediaWiki changelog

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
