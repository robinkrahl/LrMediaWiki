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

local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'
local logger = import 'LrLogger'
-- MediaWikiLogger = logger( 'MediaWiki.log' ) -- the log file name
-- MediaWikiLogger:enable( 'logfile' )

local MediaWikiApi = require 'MediaWikiApi'
local MediaWikiUtils = require 'MediaWikiUtils'

if MediaWikiUtils.getCheckVersion() then
  LrTasks.startAsyncTask(function()
    local currentVersion = MediaWikiApi.getCurrentPluginVersion()
    if currentVersion ~= nil then
      MediaWikiUtils.trace('Current version of LrMediaWiki is: ' .. currentVersion)
      if currentVersion ~= 'v' .. MediaWikiUtils.getVersionString() then
        -- new version available!
        LrDialogs.message(LOC '$$$/LrMediaWiki/Init/Version/Message=New version available', LOC('$$$/LrMediaWiki/Init/Version/Info=Please update to LrMediaWiki ^1.', currentVersion), 'info')
      end
    end
  end)
end
