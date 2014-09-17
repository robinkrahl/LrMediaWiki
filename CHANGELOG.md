# LrMediaWiki changelog

## v0.2.2: Bundestag (2014-09-08)

This releases brings a few minor changes needed for uploads for the German
Bundestag project, e. g. 

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
