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
		-- According to SDK guide, searchable fields must not exceed 511 bytes.
		-- Therefore the three description fields are intentional NOT searchable
		-- (and browsable), because they might exceed this limit.
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
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/Templates=Templates',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'categories',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/Categories=Categories',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		-- Additional fields of template "Artwork":
		{
			id = 'artist',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/Artist=Artist',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'author',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/Author=Author',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'title',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/Title=Title',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'date',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/Date=Date',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'medium',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/Medium=Medium',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'dimensions',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/Dimensions=Dimensions',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'institution',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/Institution=Institution',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'department',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/Department=Department',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'accessionNumber',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/AccessionNumber=Accession number',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'placeOfCreation',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/PlaceOfCreation=Place of creation',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'placeOfDiscovery',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/PlaceOfDiscovery=Place of discovery',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'objectHistory',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/ObjectHistory=Object history',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'exhibitionHistory',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/ExhibitionHistory=Exhibition history',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'creditLine',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/CreditLine=Credit line',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'inscriptions',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/Inscriptions=Inscriptions',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'notes',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/Notes=Notes',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'references',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/References=References',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'source',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/Source=Source',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'otherVersions',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/OtherVersions=Other versions',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'otherFields',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/OtherFields=Other fields',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'wikidata',
			version = 1,
			title = LOC '$$$/LrMediaWiki/Metadata/Wikidata=Wikidata',
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
	},
	schemaVersion = 5,
}
