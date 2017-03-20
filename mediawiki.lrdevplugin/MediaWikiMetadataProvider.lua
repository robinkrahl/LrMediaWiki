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
	title = 'LrMediaWiki',
	id = 'LrMediaWikiTagset',
	metadataFieldsForPhotos = {
		-- Fields of templates "Information" and "Artwork":
		{
			id = 'description_en',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/DescriptionEnTooltip=Description (en)^n^nDescription in English",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'description_de',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/DescriptionDeTooltip=Description (de)^n^nDescription in German",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'description_other',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/DescriptionOtherTooltip=Description (other)^n^nDescription in another language (or in multiple other languages). Use language templates like {{fr|Une description française}}.^nOr choose for example “fr – French” at the next field “Language (other)”– then the text here may not be set in the language template {{fr|…}} – simply enter the text in French.",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'language',
			version = 1,
			title = LOC "$$$/LrMediaWiki/Metadata/LanguageTooltip=Language (other)^n^nLanguage of “Description (other)”.^nIf you select a language like “fr – French”, enter the text at “Description (other)” in French.^nIf you want to use a language not listed here of if you want to use multiple languages, choose “Other” and use at field “Description (other)” the syntax of language templates: “{{Language code|Text in another language}}”.",
			dataType = 'enum',
			values = {
				{
					value = nil,
					title = LOC "$$$/LrMediaWiki/Metadata/Language/Other=Other"
				},
				{
					value = 'ar',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/ar=ar – Arabic"
				},
				{
					value = 'be',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/be=be – Belarusian"
				},
				{
					value = 'bg',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/bg=bg – Bulgarian"
				},
				{
					value = 'bn',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/bn=bn – Bangla"
				},
				{
					value = 'ca',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/ca=ca – Catalan"
				},
				{
					value = 'cs',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/cs=cs – Czech"
				},
				{
					value = 'da',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/da=da – Danish"
				},
				{
					value = 'el',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/el=el – Greek"
				},
				{
					value = 'es',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/es=es – Spanish"
				},
				{
					value = 'et',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/et=et – Estonian"
				},
				{
					value = 'fa',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/fa=fa – Persian"
				},
				{
					value = 'fi',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/fi=fi – Finnish"
				},
				{
					value = 'fr',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/fr=fr – French"
				},
				{
					value = 'ga',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/ga=ga – Irish"
				},
				{
					value = 'he',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/he=he – Hebrew"
				},
				{
					value = 'hi',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/hi=hi – Hindi"
				},
				{
					value = 'hr',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/hr=hr – Croatian"
				},
				{
					value = 'hu',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/hu=hu – Hungarian"
				},
				{
					value = 'hy',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/hy=hy – Armenian"
				},
				{
					value = 'id',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/id=id – Indonesian"
				},
				{
					value = 'is',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/is=is – Icelandic"
				},
				{
					value = 'it',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/it=it – Italian"
				},
				{
					value = 'ja',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/ja=ja – Japanese"
				},
				{
					value = 'ka',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/ka=ka – Georgian"
				},
				{
					value = 'ko',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/ko=ko – Korean"
				},
				{
					value = 'la',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/la=la – Latin"
				},
				{
					value = 'lt',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/lt=lt – Lithuanian"
				},
				{
					value = 'lv',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/lv=lv – Latvian"
				},
				{
					value = 'mk',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/mk=mk – Macedonian"
				},
				{
					value = 'nb',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/nb=nb – Norwegian Bokmål"
				},
				{
					value = 'nl',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/nl=nl – Dutch"
				},
				{
					value = 'nn',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/nn=nn – Norwegian Nynorsk"
				},
				{
					value = 'pl',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/pl=pl – Polish"
				},
				{
					value = 'pt',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/pt=pt – Portuguese"
				},
				{
					value = 'ro',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/ro=ro – Romanian"
				},
				{
					value = 'ru',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/ru=ru – Russian"
				},
				{
					value = 'sk',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/sk=sk – Slovak"
				},
				{
					value = 'sl',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/sl=sl – Slovenian"
				},
				{
					value = 'sr',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/sr=sr – Serbian"
				},
				{
					value = 'sv',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/sv=sv – Swedish"
				},
				{
					value = 'th',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/th=th – Thai"
				},
				{
					value = 'tr',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/tr=tr – Turkish"
				},
				{
					value = 'uk',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/uk=uk – Ukrainian"
				},
				{
					value = 'vi',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/vi=vi – Vietnamese"
				},
				{
					value = 'yi',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/yi=yi – Yiddish"
				},
				{
					value = 'zh',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/zh=zh – Chinese (Simplified)"
				},
				{
					value = 'zh-hant',
					title = LOC "$$$/LrMediaWiki/Metadata/Language/zh-hant=zh-hant – Chinese (Traditional)"
				},
			},
			searchable = true,
			browsable = true,
		},
		{
			id = 'date',
			version = 3,
			title = LOC "$$$/LrMediaWiki/Metadata/DateTooltip=Date^n^nOptional field. If this field is empty and “Date Created” is filled, that field is used.^nExamples for this field:^n  2017-02-26 19:58^n  {{Other date|before|1947}}^n  {{Taken on|<dateCreated>}}",
			dataType = 'string',
			searchable = true,
			browsable = true,
		},
		{
			id = 'source',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/SourceTooltip=Source^n^nRequired field. Should be set per file or at export dialog. Setting per file has priority over setting at export dialog. Example: {{own}}.^nThe field is named “Source/Photographer” at infobox template “Artwork”.",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'author',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/AuthorTooltip=Author^n^nRequired field, if not “Artwork” has been chosen (“Artwork” recommends to use “Artist” or “Author”).^nShould be set per file or at export dialog. Setting per file has priority over setting at export dialog. Example:^n  [[User:MyUserName|MyRealName]]",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'otherVersions',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/OtherVersionsTooltip=Other Versions^n^nLinks to files with very similar content or derived files.^nUse thumbnails or gallery tags <gallery> </gallery>.",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'otherFields',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/OtherFieldsTooltip=Other Fields^n^nAdditional table fields added on the bottom of the template. Examples:^n  {{Information field}}^n  {{Credit line}}",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'templates',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/TemplatesTooltip=Templates^n^nTemplates are inserted after the infobox template and before the licensing section. Examples:^n  {{Panorama}}^n  {{Personality rights}}^n  {{Location estimated}}",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'categories',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/CategoriesTooltip=Categories^n^nThe categories all uploaded images should be added to; without the prefix “Category:” and without square brackets [[…]]. Multiple categories are separated by a ; (semicolon).",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		-- Additional fields of template "Artwork":
		{
			id = 'artist',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/ArtistTooltip=Artist^n^nArtist who created the original artwork. Use {{Creator:Name Surname}} with {{Creator}} template whenever possible. Use either “Artist” or “Author”, not both.",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'title',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/TitleTooltip=Title^n^nTitle of the artwork. If the artwork has no title, use a description field.",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'medium',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/MediumTooltip=Medium^n^nMedium (technique and materials) used to create artwork",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'dimensions',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/DimensionsTooltip=Dimensions^n^nDimensions of the artwork. Please use {{Size}} formatting template.",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'institution',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/InstitutionTooltip=Institution^n^nGallery, museum or collection owning the piece. Will be shown together with field “Department” as “Current location”.",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'department',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/DepartmentTooltip=Department^n^nDepartment or location within the museum or gallery",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'accessionNumber',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/AccessionNumberTooltip=Accession Number^n^nMuseum’s accession number or some other inventory or identification number",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'placeOfCreation',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/PlaceOfCreationTooltip=Place of Creation",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'placeOfDiscovery',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/PlaceOfDiscoveryTooltip=Place of Discovery^n^nPlace of discovery or location where given object was found. This field mostly makes sense with archeological artifacts.",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'objectHistory',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/ObjectHistoryTooltip=Object History^n^nProvenance (history of artwork ownership). Use {{ProvenanceEvent}}, {{Discovered}} and other similar templates.",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'exhibitionHistory',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/ExhibitionHistoryTooltip=Exhibition History^n^nExhibition history, {{Temporary Exhibition}}",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'creditLine',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/CreditLineTooltip=Credit Line^n^nDescribes how the artwork came into the museum’s collection, or how it came to be on view at the museum",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'inscriptions',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/InscriptionsTooltip=Inscriptions^n^nDescription of: inscriptions, watermarks, captions, coats of arm, etc. Use {{inscription}}.",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'notes',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/NotesTooltip=Notes^n^nAdditional information about the artwork and its history",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'references',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/ReferencesTooltip=References^n^nBooks and websites with information about the artwork. Please use {{Cite book}} and {{Cite web}} templates.",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'wikidata',
			version = 2,
			title = LOC "$$$/LrMediaWiki/Metadata/WikidataTooltip=Wikidata^n^nID of the Wikidata item about the artwork (if any)",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		-- Additional fields of template "Object photo":
		{
			id = 'object',
			version = 1,
			title = LOC "$$$/LrMediaWiki/Metadata/ObjectTooltip=Object^n^nName of the category with the object description",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'detail',
			version = 1,
			title = LOC "$$$/LrMediaWiki/Metadata/DetailTooltip=Detail^n^nWrite “yes” if you want a message “This photograph shows a detail …” to be displayed before the section “Object”. You can also explain what is shown in the detail, it will both display the message and explain what detail it is in the “Description” field of the section “Photograph”.",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
		{
			id = 'detailPosition',
			version = 1,
			title = LOC "$$$/LrMediaWiki/Metadata/DetailPositionTooltip=Detail Position^n^nPosition of the detail on the object",
			dataType = 'string',
			searchable = false,
			browsable = false,
		},
	},
	schemaVersion = 8,
}
