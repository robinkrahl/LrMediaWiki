-- This file is part of the LrMediaWiki project and distributed under the terms
-- of the MIT license (see LICENSE.txt file in the project root directory or
-- [0]).  See [1] for more information about LrMediaWiki.
--
-- Copyright (C) 2015 by the LrMediaWiki team (see CREDITS.txt file in the
-- project root directory or [2])
--
-- [0]  <https://raw.githubusercontent.com/robinkrahl/LrMediaWiki/master/LICENSE.txt>
-- [1]  <https://commons.wikimedia.org/wiki/Commons:LrMediaWiki>
-- [2]  <https://raw.githubusercontent.com/robinkrahl/LrMediaWiki/master/CREDITS.txt>

-- Code status:
-- doc:   missing
-- i18n:  complete

-- This Metadata Set "LrMediaWiki – All Fields" shows all fields defined by
-- LrMediaWiki, grouped by the supported infobox templates:
-- * General (without label), used by all infobox templates
-- * Artwork
-- * Object photo
-- This Metadata Set supports multiple Wikimedia Commons infobox templates:
-- * <https://commons.wikimedia.org/wiki/Template:Information>
-- * <https://commons.wikimedia.org/wiki/Template:Artwork>
-- * <https://commons.wikimedia.org/wiki/Template:Object_photo>
-- The fields "Permission", "Source" and "Author" are added at export dialog.

local Info = require 'Info'
local pf = Info.LrToolkitIdentifier .. '.' -- Prefix, e.g. 'org.ireas.lightroom.mediawiki.'

return {
	id = 'LrMediaWikiMetadataSetAll', -- needs to be unique!
	title = LOC "$$$/LrMediaWiki/MetadataSetAll=LrMediaWiki – All Fields",
	items = {
		-- first group
		{ pf .. 'description_en', height_in_lines = 3 },
		pf .. 'description_de',
		pf .. 'description_additional',
		pf .. 'date',
		pf .. 'source',
		pf .. 'author',
		pf .. 'otherVersions',
		pf .. 'otherFields',
		pf .. 'templates',
		pf .. 'categories',
		-- second group
		'com.adobe.separator',
		{ 'com.adobe.label', label = 'Artwork' },
		pf .. 'artist',
		pf .. 'title',
		pf .. 'medium',
		pf .. 'dimensions',
		pf .. 'institution',
		pf .. 'department',
		pf .. 'accessionNumber',
		pf .. 'placeOfCreation',
		pf .. 'placeOfDiscovery',
		pf .. 'objectHistory',
		pf .. 'exhibitionHistory',
		pf .. 'creditLine',
		pf .. 'inscriptions',
		pf .. 'notes',
		pf .. 'references',
		pf .. 'wikidata',
		-- third group
		'com.adobe.separator',
		{ 'com.adobe.label', label = 'Object photo' },
		pf .. 'object',
		pf .. 'detail',
		pf .. 'detailPosition',
	},
}
