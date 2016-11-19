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
	LrSdkMinimumVersion = 5.0,
	LrToolkitIdentifier = 'org.ireas.lightroom.mediawiki',
	LrPluginName = LOC '$$$/LrMediaWiki/PluginName=MediaWiki for Lightroom',

	LrInitPlugin = 'MediaWikiInit.lua',

	LrLibraryMenuItems = {
		title = LOC '$$$/LrMediaWiki/Menu/Mapping=Keyword/category mapping',
		file = 'MediaWikiMappingMenuItem.lua',
	},

	LrExportServiceProvider = {
		title = LOC '$$$/LrMediaWiki/MediaWiki=MediaWiki',
		file = 'MediaWikiExportServiceProvider.lua',
	},

	LrMetadataTagsetFactory = { 'MediaWikiTagset.lua' },

	LrMetadataProvider = 'MediaWikiMetadataProvider.lua',

	LrPluginInfoProvider = 'MediaWikiPluginInfoProvider.lua',

	LrPluginInfoUrl = 'https://commons.wikimedia.org/wiki/Commons:LrMediaWiki',

	VERSION = {
		major = 0,
		minor = 5,
		revision = 0,
	},
}
