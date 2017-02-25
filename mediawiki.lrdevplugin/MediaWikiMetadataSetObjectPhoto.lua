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

-- This Metadata Set "LrMediaWiki – Object Photo" shows fields defined by the
-- Wikimedia Commons infobox template "Object photo":
-- <https://commons.wikimedia.org/wiki/Template:Object_photo>
-- The fields "Source", "Author" and "Permission" are added at export dialog.

local Info = require 'Info'
local pf = Info.LrToolkitIdentifier .. '.' -- Prefix, e.g. 'org.ireas.lightroom.mediawiki.'

return {
	id = 'LrMediaWikiMetadataSetObjectPhoto', -- needs to be unique!
	title = 'LrMediaWiki – Object Photo', -- no localization needed
	items = {
		{ 'com.adobe.label', label = 'LrMediaWiki – Object Photo' }, -- no localization needed
		pf .. 'object',
		pf .. 'detail',
		pf .. 'detailPosition',
		{ pf .. 'description_en', height_in_lines = 3 },
		pf .. 'description_de',
		pf .. 'description_additional',
		pf .. 'date',
		{ pf .. 'author', label = LOC "$$$/LrMediaWiki/Metadata/AuthorObjectPhoto=Photographer" },
		pf .. 'source',
		pf .. 'otherVersions',
		pf .. 'otherFields',
		pf .. 'templates',
		{ pf .. 'categories', label = LOC "$$$/LrMediaWiki/Metadata/Categories=Categories" },
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
