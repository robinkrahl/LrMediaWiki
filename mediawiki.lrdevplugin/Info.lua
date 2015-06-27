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
	LrSdkVersion = 5.0,
	LrToolkitIdentifier = 'org.ireas.lightroom.mediawiki',
	LrPluginName = LOC '$$$/LrMediaWiki/PluginName=MediaWiki for Lightroom',

	LrExportServiceProvider = {
		title = LOC '$$$/LrMediaWiki/MediaWiki=MediaWiki',
		file = 'MediaWikiExportServiceProvider.lua',
	},

	LrMetadataProvider = 'MediaWikiMetadataProvider.lua',

	VERSION = {
		major = 0,
		minor = 3,
		revision = 1,
	},
}
