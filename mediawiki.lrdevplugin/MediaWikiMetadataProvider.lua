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
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/DescriptionEn=Description (en)',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'description_de',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/DescriptionDe=Description (de)',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'description_additional',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/DescriptionAdditional=Description (other)',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'templates',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/Templates=Templates',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'categories',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/Categories=Categories',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		-- Additional fields of template "Artwork":
		{
			id = 'artist',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/Artist=Artist',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'author',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/Author=Author',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'title',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/Title=Title',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'date',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/Date=Date',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'medium',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/Medium=Medium',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'dimensions',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/Dimensions=Dimensions',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'institution',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/Institution=Institution',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'department',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/Department=Department',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'accessionNumber',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/AccessionNumber=Accession number',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'placeOfCreation',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/PlaceOfCreation=Place of creation',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'placeOfDiscovery',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/PlaceOfDiscovery=Place of discovery',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'objectHistory',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/ObjectHistory=Object history',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'exhibitionHistory',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/ExhibitionHistory=Exhibition history',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'creditLine',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/CreditLine=Credit line',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'inscriptions',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/Inscriptions=Inscriptions',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'notes',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/Notes=Notes',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'references',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/References=References',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'source',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/Source=Source',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'otherVersions',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/OtherVersions=Other versions',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'otherFields',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/OtherFields=Other fields',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'wikidata',
			version = 2,
			title = LOC '$$$/LrMediaWiki/Metadata/Wikidata=Wikidata',
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
	},
	schemaVersion = 6,
}
