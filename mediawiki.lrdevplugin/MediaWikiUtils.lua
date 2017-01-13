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

local LrApplication = import 'LrApplication'
local LrLogger = import 'LrLogger'
local Info = require 'Info'

local MediaWikiUtils = {}
local myLogger = LrLogger('LrMediaWikiLogger')

local prefs = import 'LrPrefs'.prefsForPlugin()
if prefs.logging then
	myLogger:enable('logfile')
end

-- Allows formatting of strings like "${test} one two three ${test2}"
-- Based on a solution by http://lua-users.org/wiki/RiciLake shown here:
-- http://lua-users.org/wiki/StringInterpolation
MediaWikiUtils.formatString = function(str, arguments)
	return (str:gsub('($%b{})', function(w) return arguments[w:sub(3, -2)] or w end))
end

-- Substitue variables of format "<var>" – similar to function "formatString"
MediaWikiUtils.substituteVariables = function(str, arguments)
	return (str:gsub('(%b<>)', function(w) return arguments[w:sub(2, -2)] or w end))
end

MediaWikiUtils.isStringEmpty = function(str)
	return str == nil or string.match(str, '^%s*$') ~= nil
	-- see e.g. http://stackoverflow.com/questions/10328211/how-to-check-if-a-value-is-empty-in-lua
end

MediaWikiUtils.isStringFilled = function(str)
	return not MediaWikiUtils.isStringEmpty(str)
end

MediaWikiUtils.getFirstKey = function(table)
  for key, value in pairs(table) do
		return key
	end
  return nil
end

MediaWikiUtils.getInstalledVersion = function()
	local str = Info.VERSION.major .. '.' .. Info.VERSION.minor .. '.' .. Info.VERSION.revision
	return str
end

MediaWikiUtils.getVersionString = function()
	local installedVersion = Info.VERSION.major .. '.' .. Info.VERSION.minor .. '.' .. Info.VERSION.revision
	local platform = '?'
	-- Boolean global variables WIN_ENV and MAC_ENV are documented at LR SDK programmers guide
	if WIN_ENV == true then
		platform = 'Win'
	elseif MAC_ENV == true then
		platform = 'Mac' -- OS name has been changed in 2016 from "OS X" to "macOS"
	else
		error 'Unsupported platform – neither Windows nor macOS' -- unlikely case
	end
	return installedVersion .. ', LR ' .. LrApplication.versionString() .. ' ' .. platform
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

MediaWikiUtils.getExportKeyword = function()
	return prefs.export_keyword or nil
end

MediaWikiUtils.setExportKeyword = function(tag)
	prefs.export_keyword = tag
end

MediaWikiUtils.trace = function(message)
	myLogger:trace(message)
end

return MediaWikiUtils
