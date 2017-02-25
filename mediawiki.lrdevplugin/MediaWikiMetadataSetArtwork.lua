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

-- This Metadata Set "LrMediaWiki – Artwork" shows fields defined by the
-- Wikimedia Commons infobox template "Artwork":
-- <https://commons.wikimedia.org/wiki/Template:Artwork>
-- The field "Permission" is added at export dialog.

local Info = require 'Info'
local pf = Info.LrToolkitIdentifier .. '.' -- Prefix, e.g. 'org.ireas.lightroom.mediawiki.'

return {
	id = 'LrMediaWikiMetadataSetArtwork', -- needs to be unique!
	title = 'LrMediaWiki – Artwork',
	items = {
		{ 'com.adobe.label', label = 'LrMediaWiki – Artwork' },
		pf .. 'artist',
		pf .. 'author',
		pf .. 'title',
		{ pf .. 'description_en', height_in_lines = 3 },
		pf .. 'description_de',
		pf .. 'description_additional',
		pf .. 'date',
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
		{ pf .. 'source', label = LOC "$$$/LrMediaWiki/Metadata/SourceArtwork=Source/Photographer" },
		pf .. 'otherVersions',
		pf .. 'otherFields',
		pf .. 'wikidata',
		pf .. 'templates',
		pf .. 'categories',
		'com.adobe.separator',
		{ 'com.adobe.label', label = 'Lightroom' },
		'com.adobe.filename',
		'com.adobe.copyname',
		'com.adobe.headline',
		'com.adobe.title',
		{ 'com.adobe.caption', label = LOC "$$$/LrMediaWiki/Metadata/Caption=Description", height_in_lines = 3 },
		'com.adobe.dateCreated',
		'com.adobe.captureTime',
		'com.adobe.captureDate',
		'com.adobe.location',
		'com.adobe.city',
		'com.adobe.state',
		'com.adobe.country',
		'com.adobe.jobIdentifier',
		{ 'com.adobe.personInImage', label = LOC "$$$/LrMediaWiki/Metadata/PersonShown=Person Shown" },
		{ 'com.adobe.organisationInImageName', label = LOC "$$$/LrMediaWiki/Metadata/NameOrg=Name of Org Shown" },
		'com.adobe.event',
	},
}
