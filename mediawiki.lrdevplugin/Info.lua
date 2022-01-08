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

return {
	LrSdkVersion = 6.0,
	LrSdkMinimumVersion = 4.0,
	LrToolkitIdentifier = 'org.ireas.lightroom.mediawiki',
	LrPluginName = 'LrMediaWiki',

	LrInitPlugin = 'MediaWikiInit.lua',

	LrExportServiceProvider = {
		title = 'MediaWiki',
		file = 'MediaWikiExportServiceProvider.lua',
	},

	LrMetadataTagsetFactory = {
		'MediaWikiMetadataSetAll.lua',
		'MediaWikiMetadataSetInformation.lua',
		'MediaWikiMetadataSetInformationDe.lua',
		'MediaWikiMetadataSetArtwork.lua',
		'MediaWikiMetadataSetObjectPhoto.lua',
	},

	LrMetadataProvider = 'MediaWikiMetadataProvider.lua',

	LrPluginInfoProvider = 'MediaWikiPluginInfoProvider.lua',

	LrPluginInfoUrl = 'https://commons.wikimedia.org/wiki/Commons:LrMediaWiki',

	VERSION = {
		major = 1,
<<<<<<< HEAD
		minor = 5,
=======
		minor = 4,
>>>>>>> parent of 071f19e... v1.5.1
		revision = 0,
	},
}
