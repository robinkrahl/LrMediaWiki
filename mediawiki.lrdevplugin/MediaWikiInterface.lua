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
local LrDate = import 'LrDate'
local LrDialogs = import 'LrDialogs'
local LrErrors = import 'LrErrors'
local LrFunctionContext = import 'LrFunctionContext'
local LrView = import 'LrView'

local MediaWikiApi = require 'MediaWikiApi'
local MediaWikiUtils = require 'MediaWikiUtils'

local MediaWikiInterface = {
	username = nil,
	password = nil,
	loggedIn = false,
	fileDescriptionPattern = nil,
}

MediaWikiInterface.loadFileDescriptionTemplate = function(templateName)
	local fileName
	if templateName == 'Information' then -- default, see MediaWikiExportServiceProvider.exportPresetFields
		fileName = '/descriptionInformation.txt'
	elseif templateName == 'Artwork' then
		fileName = '/descriptionArtwork.txt'
	end

	local result, errorMessage = false
	local file, message = io.open(_PLUGIN.path .. fileName, 'r')
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

MediaWikiInterface.prepareUpload = function(username, password, apiPath, templateName)
	-- MediaWiki login
	if username and password then
		MediaWikiInterface.username = username
		MediaWikiInterface.password = password
		MediaWikiApi.apiPath = apiPath
		local loginResult = MediaWikiApi.login(username, password)
		if loginResult ~= true then
			LrErrors.throwUserError(LOC('$$$/LrMediaWiki/Interface/LoginFailed=Login failed: ^1', loginResult))
		end
		MediaWikiInterface.loggedIn = true
	else
		LrErrors.throwUserError(LOC '$$$/LrMediaWiki/Interface/UsernameOrPasswordMissing=Username or password missing')
	end
	-- file description
	local result, message = MediaWikiInterface.loadFileDescriptionTemplate(templateName)
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

MediaWikiInterface.addToGallery = function(fileNames, galleryName)
	local currentTimeStamp = LrDate.currentTime()
	local currentDate = LrDate.formatShortDate(currentTimeStamp)
	local currentTime = LrDate.formatShortTime(currentTimeStamp)
	local section = '== ' .. currentDate .. ' ' .. currentTime .. ' ==';
	local text = '<gallery>\n';
	for i, fileName in pairs(fileNames) do
		text = text .. fileName .. '\n'
	end
	text = text .. '</gallery>'
	local comment = 'Uploaded with LrMediaWiki ' .. MediaWikiUtils.getVersionString()
	MediaWikiApi.appendToPage(galleryName, section, text, comment)
end

MediaWikiInterface.uploadFile = function(filePath, description, hasDescription, targetFileName)
	if not MediaWikiInterface.loggedIn then
		LrErrors.throwUserError(LOC '$$$/LrMediaWiki/Interface/Internal/NotLoggedIn=Internal error: not logged in before upload.')
	end
	local comment = 'Uploaded with LrMediaWiki ' .. MediaWikiUtils.getVersionString()

	local ignorewarnings = false
	if MediaWikiApi.existsFile(targetFileName) then
		local continue = LrDialogs.confirm(LOC '$$$/LrMediaWiki/Interface/InUse=File name already in use', LOC('$$$/LrMediaWiki/Interface/InUse/Details=There already is a file with the name ^1.  Overwrite?  (File description won\'t be changed.)', targetFileName), LOC '$$$/LrMediaWiki/Interface/InUse/OK=Overwrite', LOC '$$$/LrMediaWiki/Interface/InUse/Cancel=Cancel', LOC '$$$/LrMediaWiki/Interface/InUse/Rename=Rename')
		if continue == 'ok' then
			local newComment = MediaWikiInterface.prompt(LOC '$$$/LrMediaWiki/Interface/VersionComment=Version comment', LOC '$$$/LrMediaWiki/Interface/VersionComment=Version comment')
			if MediaWikiUtils.isStringFilled(newComment) then
				comment = newComment .. ' (LrMediaWiki ' .. MediaWikiUtils.getVersionString() .. ')'
			end
			ignorewarnings = true
		elseif continue == 'other' then
			local newFileName = MediaWikiInterface.prompt(LOC '$$$/LrMediaWiki/Interface/Rename=Rename file', LOC '$$$/LrMediaWiki/Interface/Rename/NewName=New file name', targetFileName)
			if MediaWikiUtils.isStringFilled(newFileName) and newFileName ~= targetFileName then
				MediaWikiInterface.uploadFile(filePath, description, hasDescription, newFileName)
			end
			return
		else
			return
		end
	else
		if not hasDescription then
			return LOC '$$$/LrMediaWiki/Export/NoDescription=No description given for this file!'
		end
	end
	local uploadResult = MediaWikiApi.upload(targetFileName, filePath, description, comment, ignorewarnings)
	if uploadResult ~= true then
		return LOC('$$$/LrMediaWiki/Interface/UploadFailed=Upload failed: ^1', uploadResult)
	end
	return nil
end

MediaWikiInterface.buildFileDescription = function(exportFields, photo)
	local categoriesString = ''
	-- The following 2 calls of the Lua function "string.gmatch()" iterate the given strings
	-- "categories" and "info_categories" by the pattern "[^;]+".
	-- It separates all occurrences of categories (by using "+") without the character ";".
	-- The ";" preceding character "^" means NOT.
	-- In other words: The strings are separated by the character ";" and the Lua calls
	-- of gmatch() separate multiple occurrences of the categories.
	-- Lua uses a specific set of patterns, no regular expressions.
	-- Lua patterns reference: <http://www.lua.org/manual/5.1/manual.html#5.4.1>
	-- (LR 6 uses Lua 5.1.4)
	for category in string.gmatch(exportFields.categories, '[^;]+') do
		if category then
			categoriesString = categoriesString .. string.format('[[Category:%s]]\n', category)
		end
	end
	for category in string.gmatch(exportFields.info_categories, '[^;]+') do
		if category then
			categoriesString = categoriesString .. string.format('[[Category:%s]]\n', category)
		end
	end

	local arguments = {
		template = exportFields.info_template,
		source = exportFields.info_source,
		author = exportFields.info_author,
		license = exportFields.info_license,
		permission = exportFields.info_permission,
		other_fields = exportFields.info_other,
		categories = categoriesString,	-- The string concatenation of "categories" and "additionalCategories" is
		-- done prior in this function. The need of this list "arguments" is caused by this concatenation.
		description = exportFields.description,
		location = exportFields.location,
		templates = exportFields.templates,
		timestamp = exportFields.timestamp,
		-- Parameter of infobox template "Artwork":
		artArtist = exportFields.art.artist,
		artAuthor = exportFields.art.author,
		artTitle = exportFields.art.title,
		artDate = exportFields.art.date,
		artMedium = exportFields.art.medium,
		artDimensions = exportFields.art.dimensions,
		artInstitution = exportFields.art.institution,
		artDepartment = exportFields.art.department,
		artAccessionNumber = exportFields.art.accessionNumber,
		artPlaceOfCreation = exportFields.art.placeOfCreation,
		artPlaceOfDiscovery = exportFields.art.placeOfDiscovery,
		artObjectHistory = exportFields.art.objectHistory,
		artExhibitionHistory = exportFields.art.exhibitionHistory,
		artCreditLine = exportFields.art.creditLine,
		artInscriptions = exportFields.art.inscriptions,
		artNotes = exportFields.art.notes,
		artReferences = exportFields.art.references,
		artSource = exportFields.art.source,
		artOtherVersions = exportFields.art.otherVersions,
		artOtherFields = exportFields.art.otherFields,
		artWikidata = exportFields.art.wikidata,
	}
	local wikitext = MediaWikiUtils.formatString(MediaWikiInterface.fileDescriptionPattern, arguments)

	-- Delete left-to-right marks <https://en.wikipedia.org/wiki/Left-to-right_mark>
	-- local pattern = '‎' -- invisble character, inserted by copy & paste
	local pattern = '\226\128\142' -- 3 bytes, decimal notation of 0xE2 0x80 0x8E
	-- See <http://www.fileformat.info/info/unicode/char/200e/index.htm>
	local count
	wikitext, count = string.gsub(wikitext, pattern, '')
	local message = LOC('$$$/LrMediaWiki/Interface/DeletedControlCharacters=Number of deleted control characters: ^1', count)
	MediaWikiUtils.trace(message)
	if count > 0 then
		LrDialogs.showBezel(message, 5) -- 5: fade delay in seconds
		MediaWikiUtils.trace(message)
	end

	-- Substitution of variables
	arguments = {
		fileName = photo:getFormattedMetadata('fileName'),
		title = photo:getFormattedMetadata('title'),
		caption = photo:getFormattedMetadata('caption'),
		label = photo:getFormattedMetadata('label'),
		headline = photo:getFormattedMetadata('headline'),
	}
	wikitext = MediaWikiUtils.substituteVariables(wikitext, arguments)

	return wikitext
end

return MediaWikiInterface
