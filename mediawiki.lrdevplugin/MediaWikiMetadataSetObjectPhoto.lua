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
-- The field "Date" is addded by the value of IPTC field "Date Created".

local Info = require 'Info'
local pf = Info.LrToolkitIdentifier .. '.' -- Prefix, e.g. 'org.ireas.lightroom.mediawiki.'

return {
	id = 'LrMediaWikiMetadataSetObjectPhoto', -- needs to be unique!
	title = 'LrMediaWiki – Object Photo', -- no localization needed
	items = {
		{ pf .. 'object', LOC "$$$/LrMediaWiki/Metadata/Object=Object" },
		{ pf .. 'detail', LOC "$$$/LrMediaWiki/Metadata/Detail=Detail" },
		{ pf .. 'detailPosition', LOC "$$$/LrMediaWiki/Metadata/DetailPosition=Detail position" },
		{ pf .. 'description_en', LOC "$$$/LrMediaWiki/Metadata/DescriptionEn=Description (en)" },
		{ pf .. 'description_de', LOC "$$$/LrMediaWiki/Metadata/DescriptionDe=Description (de)" },
		{ pf .. 'description_additional', LOC "$$$/LrMediaWiki/Metadata/DescriptionAdditional=Description (other)" },
		{ pf .. 'otherVersions', LOC "$$$/LrMediaWiki/Metadata/OtherVersions=Other versions" },
		{ pf .. 'otherFields', LOC "$$$/LrMediaWiki/Metadata/OtherFields=Other fields" },
		{ pf .. 'templates', LOC "$$$/LrMediaWiki/Metadata/Templates=Templates" },
		{ pf .. 'categories', LOC "$$$/LrMediaWiki/Metadata/Categories=Categories" },
	},
}
