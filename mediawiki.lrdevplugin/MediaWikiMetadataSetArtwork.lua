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
		{ pf .. 'artist', label = LOC "$$$/LrMediaWiki/Metadata/Artist=Artist" },
		{ pf .. 'author', label = LOC "$$$/LrMediaWiki/Metadata/Author=Author" },
		{ pf .. 'title', label = LOC "$$$/LrMediaWiki/Metadata/Title=Title" },
		{ pf .. 'description_en', label = LOC "$$$/LrMediaWiki/Metadata/DescriptionEn=Description (en)", height_in_lines = 3 },
		{ pf .. 'description_de', label = LOC "$$$/LrMediaWiki/Metadata/DescriptionDe=Description (de)" },
		{ pf .. 'description_other', label = LOC "$$$/LrMediaWiki/Metadata/DescriptionOther=Description (other)" },
		{ pf .. 'date', label = LOC "$$$/LrMediaWiki/Metadata/Date=Date" },
		{ pf .. 'medium', label = LOC "$$$/LrMediaWiki/Metadata/Medium=Medium" },
		{ pf .. 'dimensions', label = LOC "$$$/LrMediaWiki/Metadata/Dimensions=Dimensions" },
		{ pf .. 'institution', label = LOC "$$$/LrMediaWiki/Metadata/Institution=Institution" },
		{ pf .. 'department', label = LOC "$$$/LrMediaWiki/Metadata/Department=Department" },
		{ pf .. 'accessionNumber', label = LOC "$$$/LrMediaWiki/Metadata/AccessionNumber=Accession Number" },
		{ pf .. 'placeOfCreation', label = LOC "$$$/LrMediaWiki/Metadata/PlaceOfCreation=Place of Creation" },
		{ pf .. 'placeOfDiscovery', label = LOC "$$$/LrMediaWiki/Metadata/PlaceOfDiscovery=Place of Discovery" },
		{ pf .. 'objectHistory', label = LOC "$$$/LrMediaWiki/Metadata/ObjectHistory=Object History" },
		{ pf .. 'exhibitionHistory', label = LOC "$$$/LrMediaWiki/Metadata/ExhibitionHistory=Exhibition History" },
		{ pf .. 'creditLine', label = LOC "$$$/LrMediaWiki/Metadata/CreditLine=Credit Line" },
		{ pf .. 'inscriptions', label = LOC "$$$/LrMediaWiki/Metadata/Inscriptions=Inscriptions" },
		{ pf .. 'notes', label = LOC "$$$/LrMediaWiki/Metadata/Notes=Notes" },
		{ pf .. 'references', label = LOC "$$$/LrMediaWiki/Metadata/References=References" },
		{ pf .. 'source', label = LOC "$$$/LrMediaWiki/Metadata/SourceArtwork=Source/Photographer" },
		{ pf .. 'otherVersions', label = LOC "$$$/LrMediaWiki/Metadata/OtherVersions=Other Versions" },
		{ pf .. 'otherFields', label = LOC "$$$/LrMediaWiki/Metadata/OtherFields=Other Fields" },
		{ pf .. 'wikidata', label = LOC "$$$/LrMediaWiki/Metadata/Wikidata=Wikidata" },
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
