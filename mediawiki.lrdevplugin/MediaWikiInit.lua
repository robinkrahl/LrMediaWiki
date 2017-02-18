-- This file is part of the LrMediaWiki project and distributed under the terms
-- of the MIT license (see LICENSE.txt file in the project root directory or
-- [0]). See [1] for more information about LrMediaWiki.
--
-- Copyright (C) 2015 by the LrMediaWiki team (see CREDITS.txt file in the
-- project root directory or [2])
--
-- [0] <https://raw.githubusercontent.com/robinkrahl/LrMediaWiki/master/LICENSE.txt>
-- [1] <https://commons.wikimedia.org/wiki/Commons:LrMediaWiki>
-- [2] <https://raw.githubusercontent.com/robinkrahl/LrMediaWiki/master/CREDITS.txt>

-- Code status:
-- doc: missing
-- i18n: complete

local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'

local MediaWikiApi = require 'MediaWikiApi'
local MediaWikiUtils = require 'MediaWikiUtils'

if MediaWikiUtils.getCheckVersion() then
	LrTasks.startAsyncTask(function()
	-- local installedFullVersion = MediaWikiUtils.getVersionString()
	local installedVersion = 'v' .. MediaWikiUtils.getInstalledVersion()
	local availableVersion = MediaWikiApi.getCurrentPluginVersion()
		if availableVersion ~= nil then
			-- MediaWikiUtils.trace('Installed LrMediaWiki version (with LR version and OS): ' .. installedFullVersion)
			-- MediaWikiUtils.trace('Installed LrMediaWiki version: ' .. installedVersion)
			-- MediaWikiUtils.trace('Available LrMediaWiki version: ' .. availableVersion)

			-- The following string comparison works with operator ">".
			-- If the operator would be "~=" the string comparison would deliver a false positive result e.g.
			-- if the versions are identical, because availableVersion might be "0.5" and installedVersion is "0.5.0".
			if availableVersion > installedVersion then -- string comparison
				-- new version available!
				local  msg = LOC("$$$/LrMediaWiki/Init/Version/InfoInstalledVersion=Installed LrMediaWiki version: ^1^n", installedVersion)
				msg = msg .. LOC("$$$/LrMediaWiki/Init/Version/InfoAvailableVersion=Available LrMediaWiki version: ^1^n", availableVersion)
				msg = msg .. LOC("$$$/LrMediaWiki/Init/Version/InfoSummary=Please update to new available version.")
				LrDialogs.message(LOC "$$$/LrMediaWiki/Init/Version/Message=New version available", msg, 'info')
			end
		end
	end)
end
