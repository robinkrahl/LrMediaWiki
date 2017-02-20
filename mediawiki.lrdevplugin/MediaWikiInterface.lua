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
	elseif templateName == 'Object photo' then
		fileName = '/descriptionObjectPhoto.txt'
	else
		fileName = '/unknown'
	end

	local result, errorMessage = false
	local file, message = io.open(_PLUGIN.path .. fileName, 'r')
	if file then
		MediaWikiInterface.fileDescriptionPattern = file:read('*all')
		if not MediaWikiInterface.fileDescriptionPattern then
			errorMessage = LOC("$$$/LrMediaWiki/Interface/ReadingDescriptionFailed=Could not read the description template file.")
		else
			result = true
		end
		file:close()
	else
		errorMessage = LOC("$$$/LrMediaWiki/Interface/LoadingDescriptionFailed=Could not load the description template file: ^1", message)
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
			LrErrors.throwUserError(LOC("$$$/LrMediaWiki/Interface/LoginFailed=Login failed: ^1", loginResult))
		end
		MediaWikiInterface.loggedIn = true
	else
		LrErrors.throwUserError(LOC "$$$/LrMediaWiki/Interface/UsernameOrPasswordMissing=Username or password missing")
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
	for i, fileName in pairs(fileNames) do -- luacheck: ignore i
		text = text .. fileName .. '\n'
	end
	text = text .. '</gallery>'
	local comment = 'Uploaded with LrMediaWiki ' .. MediaWikiUtils.getVersionString()
	MediaWikiApi.appendToPage(galleryName, section, text, comment)
end

MediaWikiInterface.uploadFile = function(filePath, description, hasDescription, targetFileName)
	if not MediaWikiInterface.loggedIn then
		LrErrors.throwUserError(LOC "$$$/LrMediaWiki/Interface/Internal/NotLoggedIn=Internal error: not logged in before upload.")
	end
	local comment = 'Uploaded with LrMediaWiki ' .. MediaWikiUtils.getVersionString()

	local ignorewarnings = false
	if MediaWikiApi.existsFile(targetFileName) then
		local message = LOC "$$$/LrMediaWiki/Interface/InUse=File name already in use"
		local info = LOC("$$$/LrMediaWiki/Interface/InUse/Details=There already is a file with the name ^1. Overwrite? (File description won’t be changed.)", targetFileName)
		local actionVerb = LOC "$$$/LrMediaWiki/Interface/InUse/OK=Overwrite"
		local cancelVerb = LOC "$$$/LrMediaWiki/Interface/InUse/Cancel=Cancel"
		local otherVerb = LOC "$$$/LrMediaWiki/Interface/InUse/Rename=Rename"
		local continue = LrDialogs.confirm(message, info, actionVerb, cancelVerb, otherVerb)
		if continue == 'ok' then
			local versionComment = LOC "$$$/LrMediaWiki/Interface/VersionComment=Version comment"
			local newComment = MediaWikiInterface.prompt(versionComment, versionComment)
			if MediaWikiUtils.isStringFilled(newComment) then
				comment = newComment .. ' (LrMediaWiki ' .. MediaWikiUtils.getVersionString() .. ')'
			end
			ignorewarnings = true
		elseif continue == 'other' then
			local renameFile = LOC "$$$/LrMediaWiki/Interface/Rename=Rename file"
			local newName = LOC "$$$/LrMediaWiki/Interface/Rename/NewName=New file name"
			local newFileName = MediaWikiInterface.prompt(renameFile, newName, targetFileName)
			if MediaWikiUtils.isStringFilled(newFileName) and newFileName ~= targetFileName then
				MediaWikiInterface.uploadFile(filePath, description, hasDescription, newFileName)
			end
			return
		else
			return
		end
	else
		if not hasDescription then
			return LOC "$$$/LrMediaWiki/Export/NoDescription=No description given for this file!"
		end
	end
	local uploadResult = MediaWikiApi.upload(targetFileName, filePath, description, comment, ignorewarnings)
	if uploadResult ~= true then
		return LOC("$$$/LrMediaWiki/Interface/UploadFailed=Upload failed: ^1", uploadResult)
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
		categories = categoriesString,	-- The string concatenation of "categories" and "additionalCategories" is
		-- done prior in this function. The need of this list "arguments" is caused by this concatenation.
		description = exportFields.description,
		location = exportFields.location,
		templates = exportFields.templates,
		otherVersions = exportFields.otherVersions,
		otherFields = exportFields.otherFields,
		date = exportFields.date,
		-- Parameter of infobox template "Artwork":
		artArtist = exportFields.art.artist,
		artAuthor = exportFields.art.author,
		artTitle = exportFields.art.title,
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
		artWikidata = exportFields.art.wikidata,
		-- Parameter of infobox template "Object photo":
		object = exportFields.objectPhoto.object,
		detail = exportFields.objectPhoto.detail,
		detailPosition = exportFields.objectPhoto.detailPosition,
	}
	local wikitext = MediaWikiUtils.formatString(MediaWikiInterface.fileDescriptionPattern, arguments)

	-- Delete left-to-right marks <https://en.wikipedia.org/wiki/Left-to-right_mark>
	-- local pattern = '‎' -- invisble character, inserted by copy & paste
	local pattern = '\226\128\142' -- 3 bytes, decimal notation of 0xE2 0x80 0x8E
	-- See <http://www.fileformat.info/info/unicode/char/200e/index.htm>
	local count
	wikitext, count = string.gsub(wikitext, pattern, '')
	local message = LOC("$$$/LrMediaWiki/Interface/DeletedControlCharacters=Number of deleted control characters: ^1", count)
	-- MediaWikiUtils.trace(message)
	if count > 0 then
		LrDialogs.showBezel(message, 5) -- 5: fade delay in seconds
		MediaWikiUtils.trace(message)
	end

	-- Substitution of placeholders
	arguments = {
		fileName = photo:getFormattedMetadata('fileName'),
		copyName = photo:getFormattedMetadata('copyName'),
		folderName = photo:getFormattedMetadata('folderName'),
		path = photo:getRawMetadata('path'),
		fileSize = photo:getFormattedMetadata('fileSize'),
		fileType = photo:getFormattedMetadata('fileType'),
		rating = photo:getFormattedMetadata('rating'),
		label = photo:getFormattedMetadata('label'),
		colorNameForLabel = photo:getRawMetadata('colorNameForLabel'),
		title = photo:getFormattedMetadata('title'),
		caption = photo:getFormattedMetadata('caption'),
		-- EXIF
		dimensions = photo:getFormattedMetadata('dimensions'),
		width = photo:getRawMetadata('dimensions').width,
		height = photo:getRawMetadata('dimensions').height,
		aspectRatio = photo:getRawMetadata('aspectRatio'),
		croppedWidth = photo:getRawMetadata('croppedDimensions').width,
		croppedHeight = photo:getRawMetadata('croppedDimensions').height,
		croppedDimensions = photo:getFormattedMetadata('croppedDimensions'),
		exposure = photo:getFormattedMetadata('exposure'),
		shutterSpeed = photo:getFormattedMetadata('shutterSpeed'),
		shutterSpeedRaw = photo:getRawMetadata('shutterSpeed'),
		aperture = photo:getFormattedMetadata('aperture'),
		apertureRaw = photo:getRawMetadata('aperture'),
		brightnessValue = photo:getFormattedMetadata('brightnessValue'),
		exposureBias = photo:getFormattedMetadata('exposureBias'),
		flash = photo:getFormattedMetadata('flash'),
		exposureProgram = photo:getFormattedMetadata('exposureProgram'),
		meteringMode = photo:getFormattedMetadata('meteringMode'),
		isoSpeedRating = photo:getFormattedMetadata('isoSpeedRating'),
		focalLength = photo:getFormattedMetadata('focalLength'),
		focalLength35mm = photo:getFormattedMetadata('focalLength35mm'),
		lens = photo:getFormattedMetadata('lens'),
		subjectDistance = photo:getFormattedMetadata('subjectDistance'),
		dateTimeOriginal = photo:getFormattedMetadata('dateTimeOriginal'),
		dateTimeDigitized = photo:getFormattedMetadata('dateTimeDigitized'),
		dateTime = photo:getFormattedMetadata('dateTime'),
		cameraMake = photo:getFormattedMetadata('cameraMake'),
		cameraModel = photo:getFormattedMetadata('cameraModel'),
		cameraSerialNumber = photo:getFormattedMetadata('cameraSerialNumber'),
		artist = photo:getFormattedMetadata('artist'),
		software = photo:getFormattedMetadata('software'),
		gps = photo:getFormattedMetadata('gps'),
		gpsAltitude = photo:getFormattedMetadata('gpsAltitude'),
		gpsAltitudeRaw = photo:getRawMetadata('gpsAltitude'),
		-- IPTC – Contact
		creator = photo:getFormattedMetadata('creator'),
		creatorJobTitle = photo:getFormattedMetadata('creatorJobTitle'),
		creatorAddress = photo:getFormattedMetadata('creatorAddress'),
		creatorCity = photo:getFormattedMetadata('creatorCity'),
		creatorStateProvince = photo:getFormattedMetadata('creatorStateProvince'),
		creatorPostalCode = photo:getFormattedMetadata('creatorPostalCode'),
		creatorCountry = photo:getFormattedMetadata('creatorCountry'),
		creatorPhone = photo:getFormattedMetadata('creatorPhone'),
		creatorEmail = photo:getFormattedMetadata('creatorEmail'),
		creatorUrl = photo:getFormattedMetadata('creatorUrl'),
		-- IPTC – Content
		headline = photo:getFormattedMetadata('headline'),
		-- description = caption, see first section
		iptcSubjectCode = photo:getFormattedMetadata('iptcSubjectCode'),
		descriptionWriter = photo:getFormattedMetadata('descriptionWriter'),
		iptcCategory = photo:getFormattedMetadata('iptcCategory'),
		iptcOtherCategories = photo:getFormattedMetadata('iptcOtherCategories'),
		-- IPTC – Image
		dateCreated = photo:getFormattedMetadata('dateCreated'),
		intellectualGenre = photo:getFormattedMetadata('intellectualGenre'),
		scene = photo:getFormattedMetadata('scene'),
		location = photo:getFormattedMetadata('location'),
		city = photo:getFormattedMetadata('city'),
		stateProvince = photo:getFormattedMetadata('stateProvince'),
		country = photo:getFormattedMetadata('country'),
		isoCountryCode = photo:getFormattedMetadata('isoCountryCode'),
		-- IPTC – Status/Workflow
		-- title see first section
		jobIdentifier = photo:getFormattedMetadata('jobIdentifier'),
		instructions = photo:getFormattedMetadata('instructions'),
		provider = photo:getFormattedMetadata('provider'),
		source = photo:getFormattedMetadata('source'),
		-- IPTC – Copyright
		copyrightState = photo:getFormattedMetadata('copyrightState'),
		copyright = photo:getFormattedMetadata('copyright'),
		rightsUsageTerms = photo:getFormattedMetadata('rightsUsageTerms'),
		copyrightInfoUrl = photo:getFormattedMetadata('copyrightInfoUrl'),
		-- IPTC Extension – Description
		personShown = photo:getFormattedMetadata('personShown'),
		nameOfOrgShown = photo:getFormattedMetadata('nameOfOrgShown'),
		codeOfOrgShown = photo:getFormattedMetadata('codeOfOrgShown'),
		event = photo:getFormattedMetadata('event'),
		-- Keyword Tags
		keywordTags = photo:getFormattedMetadata('keywordTags'),
		keywordTagsForExport = photo:getFormattedMetadata('keywordTagsForExport'),
	}

	if arguments.dateCreated ~= '' then
		-- assumed format: "YYYY-MM-DDThh:mm:ss"
		arguments.creationDate = string.sub(arguments.dateCreated, 1, 10) -- "YYYY-MM-DD"
		arguments.creationTime = string.sub(arguments.dateCreated, 12, 20) -- "hh:mm:ss"
	else
		arguments.creationDate = ''
		arguments.creationTime = ''
	end

	local gpsRaw = photo:getRawMetadata('gps')
	if gpsRaw ~= nil then
		arguments.gpsLat = gpsRaw.latitude
		arguments.gpsLon = gpsRaw.longitude
	end

	-- "gpsImgDirection" is supported since LR 6.0
	-- LR versions < 6 may not use this parameter
	local LrApplication = import 'LrApplication'
	local LrMajorVersion = LrApplication.versionTable().major -- number type
	if LrMajorVersion >= 6 then
		arguments.gpsImgDirection = photo:getFormattedMetadata('gpsImgDirection')
		arguments.gpsImgDirectionRaw = photo:getRawMetadata('gpsImgDirection')
	end

	wikitext = MediaWikiUtils.substitutePlaceholders(wikitext, arguments)
	-- local msg = 'Wikitext:\n' .. wikitext
	-- MediaWikiUtils.trace(msg)

	return wikitext
end

return MediaWikiInterface
