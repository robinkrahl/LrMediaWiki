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
	title = 'LrMediaWiki – Artwork', -- no localization needed
	items = {
		{ pf .. 'artist', LOC "$$$/LrMediaWiki/Metadata/Artist=Artist" },
		{ pf .. 'author', LOC "$$$/LrMediaWiki/Metadata/Author=Author" },
		{ pf .. 'title', LOC "$$$/LrMediaWiki/Metadata/Title=Title" },
		{ pf .. 'description_en', LOC "$$$/LrMediaWiki/Metadata/DescriptionEn=Description (en)" },
		{ pf .. 'description_de', LOC "$$$/LrMediaWiki/Metadata/DescriptionDe=Description (de)" },
		{ pf .. 'description_additional', LOC "$$$/LrMediaWiki/Metadata/DescriptionAdditional=Description (other)" },
		{ 'com.adobe.dateCreated', LOC "$$$/LrMediaWiki/Metadata/DateCreated=Date Created" },
		{ pf .. 'date', LOC "$$$/LrMediaWiki/Metadata/Date=Date" },
		{ pf .. 'medium', LOC "$$$/LrMediaWiki/Metadata/Medium=Medium" },
		{ pf .. 'dimensions', LOC "$$$/LrMediaWiki/Metadata/Dimensions=Dimensions" },
		{ pf .. 'institution', LOC "$$$/LrMediaWiki/Metadata/Institution=Institution" },
		{ pf .. 'department', LOC "$$$/LrMediaWiki/Metadata/Department=Department" },
		{ pf .. 'accessionNumber', LOC "$$$/LrMediaWiki/Metadata/AccessionNumber=Accession number" },
		{ pf .. 'placeOfCreation', LOC "$$$/LrMediaWiki/Metadata/PlaceOfCreation=Place of creation" },
		{ pf .. 'placeOfDiscovery', LOC "$$$/LrMediaWiki/Metadata/PlaceOfDiscovery=Place of discovery" },
		{ pf .. 'objectHistory', LOC "$$$/LrMediaWiki/Metadata/ObjectHistory=Object history" },
		{ pf .. 'exhibitionHistory', LOC "$$$/LrMediaWiki/Metadata/ExhibitionHistory=Exhibition history" },
		{ pf .. 'creditLine', LOC "$$$/LrMediaWiki/Metadata/CreditLine=Credit line" },
		{ pf .. 'inscriptions', LOC "$$$/LrMediaWiki/Metadata/Inscriptions=Inscriptions" },
		{ pf .. 'notes', LOC "$$$/LrMediaWiki/Metadata/Notes=Notes" },
		{ pf .. 'references', LOC "$$$/LrMediaWiki/Metadata/References=References" },
		{ pf .. 'source', LOC "$$$/LrMediaWiki/Metadata/Source=Source" },
		{ pf .. 'otherVersions', LOC "$$$/LrMediaWiki/Metadata/OtherVersions=Other versions" },
		{ pf .. 'otherFields', LOC "$$$/LrMediaWiki/Metadata/OtherFields=Other fields" },
		{ pf .. 'wikidata', LOC "$$$/LrMediaWiki/Metadata/Wikidata=Wikidata" },
		{ pf .. 'templates', LOC "$$$/LrMediaWiki/Metadata/Templates=Templates" },
		{ pf .. 'categories', LOC "$$$/LrMediaWiki/Metadata/Categories=Categories" },
	},
}
