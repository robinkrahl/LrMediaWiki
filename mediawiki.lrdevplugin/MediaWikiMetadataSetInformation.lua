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

-- This Metadata Set "LrMediaWiki – Information" shows fields defined by the
-- Wikimedia Commons infobox template "Information":
-- <https://commons.wikimedia.org/wiki/Template:Information>
-- The fields "Permission", "Source" and "Author" are added at export dialog.

local Info = require 'Info'
local pf = Info.LrToolkitIdentifier .. '.' -- Prefix, e.g. 'org.ireas.lightroom.mediawiki.'

return {
	id = 'LrMediaWikiMetadataSetInformation', -- needs to be unique!
	title = 'LrMediaWiki – Information',
	items = {
		{ 'com.adobe.label', label = 'LrMediaWiki – Information' },
		{ pf .. 'description_en', label = LOC "$$$/LrMediaWiki/Metadata/DescriptionEn=Description (en)", height_in_lines = 3 },
		{ pf .. 'description_de', label = LOC "$$$/LrMediaWiki/Metadata/DescriptionDe=Description (de)" },
		{ pf .. 'description_other', label = LOC "$$$/LrMediaWiki/Metadata/DescriptionOther=Description (other)" },
		{ pf .. 'date', label = LOC "$$$/LrMediaWiki/Metadata/Date=Date" },
		{ pf .. 'source', label = LOC "$$$/LrMediaWiki/Metadata/Source=Source" },
		{ pf .. 'author', label = LOC "$$$/LrMediaWiki/Metadata/Author=Author" },
		{ pf .. 'otherVersions', label = LOC "$$$/LrMediaWiki/Metadata/OtherVersions=Other Versions" },
		{ pf .. 'otherFields', label = LOC "$$$/LrMediaWiki/Metadata/OtherFields=Other Fields" },
		{ pf .. 'templates', label = LOC "$$$/LrMediaWiki/Metadata/Templates=Templates" },
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
		{ 'com.adobe.personInImage', form = "shortTitle" },
		{ 'com.adobe.organisationInImageName', form = "shortTitle" },
		'com.adobe.event',
	},
}
