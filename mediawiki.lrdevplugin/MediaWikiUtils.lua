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

local LrLogger = import 'LrLogger'
local Info = require 'Info'

local MediaWikiUtils = {}
local myLogger = LrLogger('LrMediaWikiLogger')
local prefs = import 'LrPrefs'.prefsForPlugin()
if prefs.logging then
	myLogger:enable('logfile')
end

-- Allows formatting of strings like "${test} eins zwei drei ${test2}"
-- Based on a solution by http://lua-users.org/wiki/RiciLake shown here:
-- http://lua-users.org/wiki/StringInterpolation
MediaWikiUtils.formatString = function(str, arguments)
	return (str:gsub('($%b{})', function(w) return arguments[w:sub(3, -2)] or w end))
end

MediaWikiUtils.isStringEmpty = function(str)
	return str == nil or string.match(str, '^%s*$') ~= nil
end

MediaWikiUtils.getFirstKey = function(table)
  for key, value in pairs(table) do
		return key
	end
  return nil
end

MediaWikiUtils.getVersionString = function()
    local str = Info.VERSION.major .. '.' .. Info.VERSION.minor
    if Info.VERSION.revision > 0 then
        str = str .. '.' .. Info.VERSION.revision
    end
    return str
end

-- configuration

MediaWikiUtils.getCreateSnapshots = function()
	return prefs.create_snapshot or false
end

MediaWikiUtils.setCreateSnapshots = function(create_snapshot)
	prefs.create_snapshot = create_snapshot
end

MediaWikiUtils.getCheckVersion = function()
	return prefs.check_version or false
end

MediaWikiUtils.setCheckVersion = function(check_version)
	prefs.check_version = check_version
end

MediaWikiUtils.getLogging = function()
	return prefs.logging or false
end

MediaWikiUtils.setLogging = function(logging)
	prefs.logging = logging
	if logging then
		myLogger:enable('logfile')
	else
		myLogger:disable()
	end
end

MediaWikiUtils.trace = function(message)
	myLogger:trace(message)
end

return MediaWikiUtils
