-- This file is part of the LrMediaWiki project and distributed under the terms
-- of the MIT license (see LICENSE.txt file in the project root directory or
-- [0]).  See [1] for more information about LrMediaWiki.
--
-- Copyright (C) 2014 by the LrMediaWiki team (see CREDITS.txt file in the
-- project root directory or [2])
--
-- [0]  <https://raw.githubusercontent.com/ireas/LrMediaWiki/master/LICENSE.txt>
-- [1]  <https://commons.wikimedia.org/wiki/Commons:LrMediaWiki>
-- [2]  <https://raw.githubusercontent.com/ireas/LrMediaWiki/master/CREDITS.txt>

-- Code status:
-- doc:   missing
-- i18n:  complete

return {
	title = LOC "$$$/LrMediaWiki/PluginName=MediaWiki for Lightroom",
	id = 'LrMediaWikiTagset',
	metadataFieldsForPhotos = {
		-- Fields of templates "Information" and "Artwork":
		{
			id = 'description_en',
			title = LOC '$$$/LrMediaWiki/Metadata/DescriptionEn=Description (en)',
			dataType = 'string',
		},
		{
			id = 'description_de',
			title = LOC '$$$/LrMediaWiki/Metadata/DescriptionDe=Description (de)',
			dataType = 'string',
		},
		{
			id = 'description_additional',
			title = LOC '$$$/LrMediaWiki/Metadata/DescriptionAdditional=Description (other)',
			dataType = 'string',
		},
		{
			id = 'templates',
			title = LOC '$$$/LrMediaWiki/Metadata/Templates=Templates',
			dataType = 'string',
		},
		{
			id = 'categories',
			title = LOC '$$$/LrMediaWiki/Metadata/Categories=Categories',
			dataType = 'string',
		},
		-- Additional fields of template "Artwork":
		{
			id = 'artist',
			title = LOC '$$$/LrMediaWiki/Metadata/Artist=Artist',
			dataType = 'string',
		},
		{
			id = 'author',
			title = LOC '$$$/LrMediaWiki/Metadata/Author=Author',
			dataType = 'string',
		},
		{
			id = 'title',
			title = LOC '$$$/LrMediaWiki/Metadata/Title=Title',
			dataType = 'string',
		},
		{
			id = 'date',
			title = LOC '$$$/LrMediaWiki/Metadata/Date=Date',
			dataType = 'string',
		},
		{
			id = 'medium',
			title = LOC '$$$/LrMediaWiki/Metadata/Medium=Medium',
			dataType = 'string',
		},
		{
			id = 'dimensions',
			title = LOC '$$$/LrMediaWiki/Metadata/Dimensions=Dimensions',
			dataType = 'string',
		},
		{
			id = 'institution',
			title = LOC '$$$/LrMediaWiki/Metadata/Institution=Institution',
			dataType = 'string',
		},
		{
			id = 'department',
			title = LOC '$$$/LrMediaWiki/Metadata/Department=Department',
			dataType = 'string',
		},
		{
			id = 'accessionNumber',
			title = LOC '$$$/LrMediaWiki/Metadata/AccessionNumber=Accession number',
			dataType = 'string',
		},
		{
			id = 'placeOfCreation',
			title = LOC '$$$/LrMediaWiki/Metadata/PlaceOfCreation=Place of creation',
			dataType = 'string',
		},
		{
			id = 'placeOfDiscovery',
			title = LOC '$$$/LrMediaWiki/Metadata/PlaceOfDiscovery=Place of discovery',
			dataType = 'string',
		},
		{
			id = 'objectHistory',
			title = LOC '$$$/LrMediaWiki/Metadata/ObjectHistory=Object history',
			dataType = 'string',
		},
		{
			id = 'exhibitionHistory',
			title = LOC '$$$/LrMediaWiki/Metadata/ExhibitionHistory=Exhibition history',
			dataType = 'string',
		},
		{
			id = 'creditLine',
			title = LOC '$$$/LrMediaWiki/Metadata/CreditLine=Credit line',
			dataType = 'string',
		},
		{
			id = 'inscriptions',
			title = LOC '$$$/LrMediaWiki/Metadata/Inscriptions=Inscriptions',
			dataType = 'string',
		},
		{
			id = 'notes',
			title = LOC '$$$/LrMediaWiki/Metadata/Notes=Notes',
			dataType = 'string',
		},
		{
			id = 'references',
			title = LOC '$$$/LrMediaWiki/Metadata/References=References',
			dataType = 'string',
		},
		{
			id = 'source',
			title = LOC '$$$/LrMediaWiki/Metadata/Source=Source',
			dataType = 'string',
		},
		{
			id = 'otherVersions',
			title = LOC '$$$/LrMediaWiki/Metadata/OtherVersions=Other versions',
			dataType = 'string',
		},
		{
			id = 'otherFields',
			title = LOC '$$$/LrMediaWiki/Metadata/OtherFields=Other fields',
			dataType = 'string',
		},
		{
			id = 'wikidata',
			title = LOC '$$$/LrMediaWiki/Metadata/Wikidata=Wikidata',
			dataType = 'string',
		},
	},
	schemaVersion = 4,
}
