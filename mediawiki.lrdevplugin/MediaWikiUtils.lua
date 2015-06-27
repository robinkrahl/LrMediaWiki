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
local myLogger = LrLogger('LrMediaWikiLogger')

-- LOGGING
-- If enabled, the log file will appear in your "My Documents" folder. Warning:
-- LrMediaWiki will log all requests sent to MediaWiki, including your password!
-- If you share a log file, make sure you removed your password.
-- To enable logging, uncomment the following line:
-- myLogger:enable("logfile")

local MediaWikiUtils = {}

-- Allows formatting of strings like "${test} eins zwei drei ${test2}"
-- Based on a solution by http://lua-users.org/wiki/RiciLake shown here:
-- http://lua-users.org/wiki/StringInterpolation
MediaWikiUtils.formatString = function(str, arguments)
	return (str:gsub('($%b{})', function(w) return arguments[w:sub(3, -2)] or w end))
end

MediaWikiUtils.isStringEmpty = function(str)
	return str == nil or string.match(str, '^%s*$') ~= nil
end

MediaWikiUtils.getVersionString = function()
    local str = Info.VERSION.major .. '.' .. Info.VERSION.minor
    if Info.VERSION.revision > 0 then
        str = str .. '.' .. Info.VERSION.revision
    end
    return str
end

MediaWikiUtils.trace = function(message)
	myLogger:trace(message)
end

return MediaWikiUtils
