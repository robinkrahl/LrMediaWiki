-- This file is part of the LrMediaWiki project and distributed under the terms
-- of the MIT license (see LICENSE.txt file in the project root directory or
-- [0]).  See [1] for more information about LrMediaWiki.
--
-- Copyright (C) 2014 by the LrMediaWiki team (see CREDITS.txt file in the
-- project root directory or [2])
--
-- [0]  <https://raw.githubusercontent.com/LrMediaWiki/LrMediaWiki/master/LICENSE.txt>
-- [1]  <https://commons.wikimedia.org/wiki/Commons:LrMediaWiki>
-- [2]  <https://raw.githubusercontent.com/LrMediaWiki/LrMediaWiki/master/CREDITS.txt>

-- Code status:
-- doc:   missing
-- i18n:  complete

return {
	metadataFieldsForPhotos = {
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
			id = 'categories',
			title = LOC '$$$/LrMediaWiki/Metadata/Categories=Categories',
			dataType = 'string',
		},
	},
	
	schemaVersion = 2,
}