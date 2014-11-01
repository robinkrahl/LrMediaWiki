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

local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrErrors = import 'LrErrors'
local LrFunctionContext = import 'LrFunctionContext'
local LrPathUtils = import 'LrPathUtils'
local LrView = import 'LrView'

local MediaWikiApi = require 'MediaWikiApi'
local MediaWikiUtils = require 'MediaWikiUtils'

local MediaWikiInterface = {
	username = nil,
	password = nil,
	loggedIn = false,
	fileDescriptionPattern = nil,
}

MediaWikiInterface.loadFileDescriptionTemplate = function()
	local result, errorMessage = false
	local file, message = io.open(_PLUGIN.path .. '/description.txt', 'r')
	if file then
		MediaWikiInterface.fileDescriptionPattern = file:read('*all')
		if not MediaWikiInterface.fileDescriptionPattern then
			errorMessage = LOC('$$$/LrMediaWiki/Interface/ReadingDescriptionFailed=Could not read the description template file.')
		else
			result = true
		end
		file:close()
	else
		errorMessage = LOC('$$$/LrMediaWiki/Interface/LoadingDescriptionFailed=Could not load the description template file: ^1', message)
	end
	return result, errorMessage
end

MediaWikiInterface.prepareUpload = function(username, password, apiPath)
	-- MediaWiki login
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
	-- file description
	result, message = MediaWikiInterface.loadFileDescriptionTemplate()
	if not result then
		LrErrors.throwUserError(message)
	end
end

MediaWikiInterface.prompt = function(title, label, default)
	return LrFunctionContext.callWithContext('MediaWikiInterface.prompt', function(context)
		return MediaWikiInterface._prompt(context, title, label, default)
	end)
end

MediaWikiInterface._prompt = function(functionContext, title, label, default)
	local factory = LrView.osFactory()
	local properties = LrBinding.makePropertyTable(functionContext)
	properties.dialogValue = default
	local contents = factory:row {
		spacing = factory:label_spacing(),
		bind_to_object = properties,
		factory:static_text {
			title = label,
		},
		factory:edit_field {
			fill_horizontal = 1,
			value = LrView.bind('dialogValue'),
			width_in_chars = 20,
		},
	}
	local dialogResult = LrDialogs.presentModalDialog({
		title = title,
		contents = contents,
	})
	local result = nil
	if dialogResult == 'ok' then
		result = properties.dialogValue
	end
	return result
end

MediaWikiInterface.uploadFile = function(filePath, description, fileName)
	if not MediaWikiInterface.loggedIn then
		LrErrors.throwUserError(LOC '$$$/LrMediaWiki/Interface/Internal/NotLoggedIn=Internal error: not logged in before upload.')
	end
	local comment = 'Uploaded with LrMediaWiki ' .. MediaWikiUtils.getVersionString()
	local targetFileName = fileName or LrPathUtils.leafName(filePath)
	local ignorewarnings = false
	if MediaWikiApi.existsFile(targetFileName) then
		local continue = LrDialogs.confirm(LOC '$$$/LrMediaWiki/Interface/InUse=File name already in use', LOC('$$$/LrMediaWiki/Interface/InUse/Details=There already is a file with the name ^1.  Overwrite?  (File description won\'t be changed.)', targetFileName), LOC '$$$/LrMediaWiki/Interface/InUse/OK=Overwrite', LOC '$$$/LrMediaWiki/Interface/InUse/Cancel=Cancel', LOC '$$$/LrMediaWiki/Interface/InUse/Rename=Rename')
		if continue == 'ok' then
			local newComment = MediaWikiInterface.prompt(LOC '$$$/LrMediaWiki/Interface/VersionComment=Version comment', LOC '$$$/LrMediaWiki/Interface/VersionComment=Version comment')
			if not MediaWikiUtils.isStringEmpty(newComment) then
				comment = newComment .. ' (LrMediaWiki ' .. MediaWikiUtils.getVersionString() .. ')'
			end
			ignorewarnings = true
		elseif continue == 'other' then
			local newFileName = MediaWikiInterface.prompt(LOC '$$$/LrMediaWiki/Interface/Rename=Rename file', LOC '$$$/LrMediaWiki/Interface/Rename/NewName=New file name', targetFileName)
			if not MediaWikiUtils.isStringEmpty(newFileName) and newFileName ~= targetFileName then
				MediaWikiInterface.uploadFile(filePath, description, newFileName)
			end
			return
		else
			return
		end
	end
	local uploadResult = MediaWikiApi.upload(targetFileName, filePath, description, comment, ignorewarnings)
	if uploadResult ~= true then
		LrErrors.throwUserError(LOC('$$$/LrMediaWiki/Interface/UploadFailed=Upload failed: ^1', uploadResult))
	end
end

MediaWikiInterface.buildFileDescription = function(description, source, timestamp, author, license, templates, other, categories, additionalCategories)
	local categoriesString = ''
	for category in string.gmatch(categories, '[^;]+') do
		if category then
			categoriesString = categoriesString .. string.format('[[Category:%s]]\n', category)
		end
	end
	for category in string.gmatch(additionalCategories, '[^;]+') do
		if category then
			categoriesString = categoriesString .. string.format('[[Category:%s]]\n', category)
		end
	end
	local arguments = {
		description = description,
		source = source,
		timestamp = timestamp,
		author = author,
		other_fields = other,
		templates = templates,
		license = license,
		categories = categoriesString,
	}
	return MediaWikiUtils.formatString(MediaWikiInterface.fileDescriptionPattern, arguments)
end

return MediaWikiInterface
