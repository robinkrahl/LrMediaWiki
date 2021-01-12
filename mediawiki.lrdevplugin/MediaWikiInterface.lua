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
		fileName = '/descriptionInformationEn.txt'
	elseif templateName == 'Information (de)' then
		fileName = '/descriptionInformationDe.txt'
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

MediaWikiInterface.uploadFile = function(filePath, description, hasDescription, targetFileName, info_mode, updateCommentForAll)
	if not MediaWikiInterface.loggedIn then
		LrErrors.throwUserError(LOC "$$$/LrMediaWiki/Interface/Internal/NotLoggedIn=Internal error: not logged in before upload")
	end
	local comment = 'Uploaded with LrMediaWiki ' .. MediaWikiUtils.getVersionString() -- for new files
	local commentSuffix = ' (LrMediaWiki ' .. MediaWikiUtils.getVersionString() .. ')' -- for updates

	local ignorewarnings = false
	if MediaWikiApi.existsFile(targetFileName) then
		if MediaWikiUtils.isStringEmpty(updateCommentForAll) then
			local message = LOC "$$$/LrMediaWiki/Interface/InUse=File name already in use"
			local info = LOC("$$$/LrMediaWiki/Interface/InUse/Details=There already is a file with the name ^1. Overwrite? (File description won’t be changed.)", targetFileName)
			local actionVerb = LOC "$$$/LrMediaWiki/Interface/InUse/OK=Overwrite"
			local cancelVerb = LOC "$$$/LrMediaWiki/Interface/InUse/Cancel=Cancel"
			local otherVerb = LOC "$$$/LrMediaWiki/Interface/InUse/Rename=Rename"
			local continue = LrDialogs.confirm(message, info, actionVerb, cancelVerb, otherVerb)
			if continue == 'ok' then -- Overwrite
				local versionComment = LOC "$$$/LrMediaWiki/Interface/VersionComment=Version comment"
				local newComment = MediaWikiInterface.prompt(versionComment, versionComment)
				if MediaWikiUtils.isStringFilled(newComment) then
					comment = newComment .. commentSuffix
				end
				ignorewarnings = true
			elseif continue == 'other' then -- Rename
				local renameFile = LOC "$$$/LrMediaWiki/Interface/Rename=Rename file"
				local newName = LOC "$$$/LrMediaWiki/Interface/Rename/NewName=New file name"
				local newFileName = MediaWikiInterface.prompt(renameFile, newName, targetFileName)
				if MediaWikiUtils.isStringFilled(newFileName) and newFileName ~= targetFileName then
					MediaWikiInterface.uploadFile(filePath, description, hasDescription, newFileName, 'Standard')
				end
				return
			else -- Cancel
				return
			end
		else -- File exists, updateCommentForAll is filled, no interaction with user is needed, overwrite
			assert(info_mode == 'UpdateOnly') -- updateCommentForAll is only filled if mode is UpdateOnly
			comment = updateCommentForAll .. commentSuffix
			ignorewarnings = true
		end
	else -- targetFileName exists not, the file is a new upload. New files need a description.
		if not hasDescription then
			return LOC "$$$/LrMediaWiki/Export/NoDescription=No description given for this file!"
		end
		if info_mode == 'UpdateOnly' then
			LrDialogs.message(LOC "$$$/LrMediaWiki/Interface/NoUpload=Information: No upload of this new file in mode “Update only”",
								LOC "$$$/LrMediaWiki/Interface/NoUploadFile=File" .. ': ' .. targetFileName)
			return nil -- Don't upload if it's a new file
		end
	end
	local uploadResult = MediaWikiApi.upload(targetFileName, filePath, description, comment, ignorewarnings)
	if uploadResult ~= true then
		return LOC("$$$/LrMediaWiki/Interface/UploadFailed=Upload failed: ^1", uploadResult)
	end
	return nil
end

MediaWikiInterface.buildFileDescription = function(exportFields, photo)
		local categoriesList = {}
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
			category = MediaWikiUtils.trim(category)
			table.insert(categoriesList, category)
		end
	end

	for category in string.gmatch(exportFields.info_categories, '[^;]+') do
		if category then
			category = MediaWikiUtils.trim(category)
			table.insert(categoriesList, category)
		end
	end

	-- remove duplicate categories, see https://stackoverflow.com/questions/20066835/lua-remove-duplicate-elements
	local categoriesListTwo = {}
	local hash = {}
	for _,v in ipairs(categoriesList) do
		if not hash[v] then
			categoriesListTwo[#categoriesListTwo + 1] = v
			hash[v] = true
		end
	end
	local categoriesString = ''
	local category
	for i = 1, #categoriesListTwo do
		category = string.format('[[Category:%s]]\n',  categoriesListTwo[i])
		categoriesString = categoriesString .. category
	end

	local arguments = {
		template = exportFields.info_template,
		permission = exportFields.info_permission,
		license = exportFields.info_license,
		categories = categoriesString,	-- The string concatenation of "categories" and "additionalCategories" is
		-- done prior in this function. The need of this list "arguments" is caused by this concatenation.
		description = exportFields.description,
		date = exportFields.date,
		source = exportFields.source,
		author = exportFields.author,
		otherVersions = exportFields.otherVersions,
		otherFields = exportFields.otherFields,
		location = exportFields.location,
		templates = exportFields.templates,
		-- Parameter of infobox template "Artwork":
		artArtist = exportFields.art.artist,
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

	arguments.creationDate = ''
	arguments.creationLongDate = ''
	arguments.creationMediumDate = ''
	arguments.creationShortDate = ''
	arguments.creationYear = ''
	arguments.creationMonthXX = ''
	arguments.creationMonth = ''
	arguments.creationMonthName = ''
	arguments.creationMonthNameLoc = ''
	arguments.creationDayXX = ''
	arguments.creationDay = ''
	arguments.creationDayName = ''
	arguments.creationDayNameLoc = ''
	arguments.creationTime = ''
	arguments.creationHour = ''
	arguments.creationMinute = ''
	arguments.creationSecond = ''

	local currentTime = LrDate.currentTime() -- number of seconds since midnight UTC on January 1, 2001
	arguments.currentIsoDate = LrDate.timeToIsoDate(currentTime) -- 2021-01-09
	arguments.currentLongDate = LrDate.formatLongDate(currentTime) -- 9. Januar 2021
	arguments.currentMediumDate = LrDate.formatMediumDate(currentTime) -- 09.01.2021
	arguments.currentShortDate = LrDate.formatShortDate(currentTime) -- 09.01.21
	arguments.currentYear = LrDate.timeToUserFormat(currentTime, '%Y') -- 2021
	arguments.currentYearXX = LrDate.timeToUserFormat(currentTime, '%y') -- 21
	arguments.currentMonthXX = LrDate.timeToUserFormat(currentTime, '%m') -- 01
	arguments.currentMonth = tonumber(arguments.currentMonthXX) -- 1
	arguments.currentMonthName = LrDate.timeToUserFormat(currentTime, '%B') -- January
	arguments.currentDayXX = LrDate.timeToUserFormat(currentTime, '%d') -- 09
	arguments.currentDay = LrDate.timeToUserFormat(currentTime, '%e') -- 9
	arguments.currentDayName = LrDate.timeToUserFormat(currentTime, '%A') -- Saturday
	arguments.currentTime = LrDate.timeToUserFormat(currentTime, '%H:%M:%S') -- 20:40:15
	arguments.currentHour = LrDate.timeToUserFormat(currentTime, '%H') -- 20
	arguments.currentMinute = LrDate.timeToUserFormat(currentTime, '%M') -- 40
	arguments.currentSecond = LrDate.timeToUserFormat(currentTime, '%S') -- 15

	if arguments.dateCreated ~= '' then
		local function getMonth(month)
			local months = { 'January', 'February', 'March', 'April', 'May', 'June',
			'July', 'August', 'September', 'October', 'November', 'December' }
			return months[month]
		end

		-- Source: http://lua-users.org/wiki/DayOfWeekAndDaysInMonthExample
		local function getDay(yy, mm, dd)
			local dw = os.date('*t', os.time{year=yy, month=mm, day=dd}).wday
			return ({ 'Sunday', 'Monday', 'Tuesday', 'Wednesday',
						'Thusday', 'Friday', 'Saturday' })[dw]
		end

		-- Assumed format: "YYYY-MM-DDThh:mm:ss"
		-- Index helper:    1234567890123456789
		arguments.creationDate = string.sub(arguments.dateCreated, 1, 10) -- "YYYY-MM-DD"
		arguments.creationYear = string.sub(arguments.creationDate, 1, 4) -- "YYYY"
		arguments.creationYear = tonumber(arguments.creationYear)
		arguments.creationMonthXX = string.sub(arguments.creationDate, 6, 7) -- "MM"
		if MediaWikiUtils.isStringFilled(arguments.creationMonthXX) then
			arguments.creationMonth = tonumber(arguments.creationMonthXX)
			arguments.creationMonthName = getMonth(arguments.creationMonth)
		end
		arguments.creationDayXX = string.sub(arguments.creationDate, 9, 10) -- "DD"
		if	MediaWikiUtils.isStringFilled(arguments.creationDayXX) then
			arguments.creationDay = tonumber(arguments.creationDayXX)
			arguments.creationDayName = getDay(arguments.creationYear, arguments.creationMonth, arguments.creationDay)
		end
		arguments.creationTime = string.sub(arguments.dateCreated, 12, 19) -- "hh:mm:ss"
		arguments.creationHour = string.sub(arguments.dateCreated, 12, 13) -- "hh"
		arguments.creationMinute = string.sub(arguments.dateCreated, 15, 16) -- "mm"
		arguments.creationSecond = string.sub(arguments.dateCreated, 18, 19) -- "ss"
		if	MediaWikiUtils.isStringFilled(arguments.creationYear) and
			MediaWikiUtils.isStringFilled(arguments.creationMonth) and
			MediaWikiUtils.isStringFilled(arguments.creationDay) then
			local cocoaDate = LrDate.timeFromComponents(
				arguments.creationYear,
				arguments.creationMonth,
				arguments.creationDay,
				arguments.creationHour,
				arguments.creationMinute,
				arguments.creationSecond
				)
			arguments.creationLongDate = LrDate.formatLongDate(cocoaDate)
			arguments.creationMediumDate = LrDate.formatMediumDate(cocoaDate)
			arguments.creationShortDate = LrDate.formatShortDate(cocoaDate)
			arguments.creationMonthNameLoc = LrDate.timeToUserFormat(cocoaDate, '%B')
			arguments.creationDayNameLoc = LrDate.timeToUserFormat(cocoaDate, '%A')
		end
		-- Test templates and outputs see:
		-- https://github.com/robinkrahl/LrMediaWiki/issues/91
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

	-- Search for placeholders which are not substituted by a filled variable.
	-- A typical error is an empty variable.
	-- Another error can be caused by a faulty placeholder name, e. g. <personsShown> instead of <personShown>,
	local success
	local placeholder = wikitext:match("<%a+>") -- a pattern starting with "<", multiple ASCII chars, ending with ">"
	if placeholder then
		message = LOC("$$$/LrMediaWiki/Interface/PlaceholderErrorMessage=The placeholder ^1 was not replaced.", placeholder)
		local info = LOC("$$$/LrMediaWiki/Interface/PlaceholderErrorInfo=File: ^1", arguments.fileName)
		LrDialogs.message(message, info, "critical")
		success = false
	else
		success = true
	end

	return wikitext, success
end

return MediaWikiInterface
