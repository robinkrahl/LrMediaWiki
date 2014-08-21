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

local LrDialogs = import 'LrDialogs'
local LrErrors = import 'LrErrors'
local LrPathUtils = import 'LrPathUtils'

local MediaWikiApi = require 'MediaWikiApi'


local MediaWikiInterface = {
	username = nil,
	password = nil,
	loggedIn = false,
	fileDescriptionPattern = [=[== {{int:filedesc}} ==
{{Information
|Description=%s
|Source=%s
|Date=%s
|Author=%s
|Permission=
|other_versions=
|other_fields=%s
}}
== {{int:license-header}} ==
%s
%s[[Category:Uploaded with LrMediaWiki]]]=],
}

MediaWikiInterface.prepareUpload = function(username, password, apiPath)
	if username and password then
		MediaWikiInterface.username = username
		MediaWikiInterface.password = password
		MediaWikiApi.apiPath = apiPath
		local loginResult = MediaWikiApi.login(username, password)
		if loginResult ~= true then
			LrErrors.throwUserError(LOC('$$$/LrMediaWiki/Interface/LoginFailed=Login failed: ^1.', loginResult))
		end
		MediaWikiInterface.loggedIn = true
	else
		LrErrors.throwUserError(LOC '$$$/LrMediaWiki/Interface/UsernameOrPasswordMissing=Username or password missing')
	end
end

MediaWikiInterface.uploadFile = function(filePath, description)
	if not MediaWikiInterface.loggedIn then
		LrErrors.throwUserError(LOC '$$$/LrMediaWiki/Interface/Internal/NotLoggedIn=Internal error: not logged in before upload.')
	end
	local targetFileName = LrPathUtils.leafName(filePath)
	local ignorewarnings = false
	if MediaWikiApi.existsFile(targetFileName) then
		local continue = LrDialogs.confirm(LOC '$$$/LrMediaWiki/Interface/InUse=File name already in use', LOC('$$$/LrMediaWiki/Interface/InUse/Details=There already is a file with the name ^1.  Overwrite?  (File description won\'t be changed.)', targetFileName))
		if continue == 'ok' then
			ignorewarnings = true
		else
			return
		end
	end
	local uploadResult = MediaWikiApi.upload(targetFileName, filePath, description, 'Uploaded with LrMediaWiki', ignorewarnings)
	if uploadResult ~= true then
		LrErrors.throwUserError(LOC('$$$/LrMediaWiki/Interface/UploadFailed=Upload failed: ^1', uploadResult))
	end
end

MediaWikiInterface.buildFileDescription = function(description, source, timestamp, author, license, other, categories)
	local categoriesString = ''
	for category in string.gmatch(categories, '[^;]+') do
		categoriesString = categoriesString .. string.format('[[Category:%s]]\n', category)
	end
	return string.format(MediaWikiInterface.fileDescriptionPattern, description, source, timestamp, author, other, license, categoriesString)
end

return MediaWikiInterface