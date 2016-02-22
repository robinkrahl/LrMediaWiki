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

local LrDate = import 'LrDate'
local LrDialogs = import 'LrDialogs'
local LrErrors = import 'LrErrors'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrView = import 'LrView'
local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrFunctionContext = import 'LrFunctionContext'
-- local LrExportContext = import 'LrExportContext'
-- local LrExportSession = import 'LrExportSession'
-- local LrSystemInfo = import 'LrSystemInfo'

local bind = LrView.bind

local Info = require 'Info'
local MediaWikiInterface = require 'MediaWikiInterface'
local MediaWikiUtils = require 'MediaWikiUtils'

local MediaWikiExportServiceProvider = {}

MediaWikiExportServiceProvider.processRenderedPhotos = function(functionContext, exportContext)
	-- configure progress display
	local exportSession = exportContext.exportSession
	local photoCount = exportSession:countRenditions()
	exportContext:configureProgress{
		title = photoCount > 1 and LOC('$$$/LrMediaWiki/Export/Progress=Exporting ^1 photos to a MediaWiki', photoCount) or LOC '$$$/LrMediaWiki/Export/Progress/One=Exporting one photo to a MediaWiki',
	}

	local exportSettings = assert(exportContext.propertyTable)

	-- require username, password, apipath, license, author, source
	if MediaWikiUtils.isStringEmpty(exportSettings.username) then
		LrErrors.throwUserError(LOC '$$$/LrMediaWiki/Export/NoUsername=No username given!')
	end
	if MediaWikiUtils.isStringEmpty(exportSettings.password) then
		LrErrors.throwUserError(LOC '$$$/LrMediaWiki/Export/NoPassword=No password given!')
	end
	if MediaWikiUtils.isStringEmpty(exportSettings.api_path) then
		LrErrors.throwUserError(LOC '$$$/LrMediaWiki/Export/NoApiPath=No API path given!')
	end
	if MediaWikiUtils.isStringEmpty(exportSettings.info_license) then
		LrErrors.throwUserError(LOC '$$$/LrMediaWiki/Export/NoLicense=No license given!')
	end
	if MediaWikiUtils.isStringEmpty(exportSettings.info_author) then
		LrErrors.throwUserError(LOC '$$$/LrMediaWiki/Export/NoAuthor=No author given!')
	end
	if MediaWikiUtils.isStringEmpty(exportSettings.info_source) then
		LrErrors.throwUserError(LOC '$$$/LrMediaWiki/Export/NoSource=No source given!')
	end

	MediaWikiInterface.prepareUpload(exportSettings.username, exportSettings.password, exportSettings.api_path)

	-- file names for gallery creation
	local fileNames = {}

	-- iterate over photos
	for i, rendition in exportContext:renditions() do
		-- render photo
		local success, pathOrMessage = rendition:waitForRender()
		if success then
			local photo = rendition.photo
			local catalog = photo.catalog

			-- do upload to MediaWiki
			local exportFields = {
				-- fields set at export dialogue, order by UI
				info_source = exportSettings.info_source,
				info_author = exportSettings.info_author,
				info_license = exportSettings.info_license,
				info_permission = exportSettings.info_permission,
				info_templates = exportSettings.info_templates,
				info_other = exportSettings.info_other,
				info_categories = exportSettings.info_categories,
				-- fields by file, to be filled by fillExportFields(), order by UI
				description = '',
				location = '',
				templates = '',
				categories = '',
				timestamp = '',
			}

			local filledExportFields = MediaWikiExportServiceProvider.fillFieldsByFile(exportFields, photo)
			local fileDescription = MediaWikiInterface.buildFileDescription(filledExportFields)

			-- ensure that the target file name does not contain a series of spaces or
			-- underscores (as this would cause the upload to fail without a proper
			-- error message)
			local fileName = string.gsub(LrPathUtils.leafName(pathOrMessage), '[ _]+', '_')
			local hasDescription = not MediaWikiUtils.isStringEmpty(filledExportFields.description)
			local message = MediaWikiInterface.uploadFile(pathOrMessage, fileDescription, hasDescription, fileName)
			if message then
				rendition:uploadFailed(message)
			else
				-- create new snapshot if the upload was successful
				if MediaWikiUtils.getCreateSnapshots() then
					local currentTimeStamp = LrDate.currentTime()
					local currentDate = LrDate.formatShortDate(currentTimeStamp)
					local currentTime = LrDate.formatShortTime(currentTimeStamp)
					local snapshotTitle = LOC('$$$/LrMediaWiki/Export/Snapshot=MediaWiki export, ^1 ^2, ^3', currentDate, currentTime, exportSettings.api_path)
					catalog:withWriteAccessDo('CreateDevelopSnapshot', function(context)
						photo:createDevelopSnapshot(snapshotTitle, true)
					end)
				end

				-- add configured export keyword
				local keyword = MediaWikiUtils.getExportKeyword()
				if not MediaWikiUtils.isStringEmpty(keyword) then
					catalog:withWriteAccessDo('AddExportKeyword', function(context)
						photo:addKeyword(catalog:createKeyword(keyword, {}, false, nil, true))
					end)
				end

				-- file name for gallery creation
				fileNames[#fileNames + 1] = fileName
			end
			LrFileUtils.delete(pathOrMessage)
		else
			-- rendering failed --> report failure
			rendition:uploadFailed(pathOrMessage)
		end
	end

	if (not MediaWikiUtils.isStringEmpty(exportSettings.gallery)) and fileNames then
		MediaWikiInterface.addToGallery(fileNames, exportSettings.gallery)
	end
end

MediaWikiExportServiceProvider.sectionsForTopOfDialog = function(viewFactory, propertyTable)
	local labelAlignment = 'right';
	local widthLong = 50;

	return {
		{
			title = LOC '$$$/LrMediaWiki/Section/User/Title=Login Information',
			synopsis = bind 'username',

			viewFactory:column {
				spacing = viewFactory:control_spacing(),

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:static_text {
						title = LOC '$$$/LrMediaWiki/Section/User/Username=Username',
						alignment = labelAlignment,
						width = LrView.share "label_width",
					},

					viewFactory:edit_field {
						value = bind 'username',
						immediate = true,
						width_in_chars = widthLong,
					},
				},

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:static_text {
						title = LOC '$$$/LrMediaWiki/Section/User/Password=Password',
						alignment = labelAlignment,
						width = LrView.share "label_width",
					},

					viewFactory:password_field {
						value = bind 'password',
						width_in_chars = widthLong,
					},
				},

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:static_text {
						title = LOC '$$$/LrMediaWiki/Section/User/ApiPath=API path',
						alignment = labelAlignment,
						width = LrView.share "label_width",
					},

					viewFactory:edit_field {
						value = bind 'api_path',
						immediate = true,
						width_in_chars = widthLong,
					},

					viewFactory:static_text {
						title = LOC '$$$/LrMediaWiki/Section/User/ApiPath/Details=Path to the api.php file',
					},
				},

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:static_text {
						title = LOC '$$$/LrMediaWiki/Section/User/Gallery=Gallery',
						alignment = labelAlignment,
						width = LrView.share "label_width",
					},

					viewFactory:edit_field {
						value = bind 'gallery',
						immediate = true,
						width_in_chars = widthLong,
					},
				},
			},
		},
		{
			title = LOC "$$$/LrMediaWiki/Section/Licensing/Title=Upload Information",
			synopsis = bind 'info_license',

			viewFactory:column {
				spacing = viewFactory:control_spacing(),

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:static_text {
						title = LOC '$$$/LrMediaWiki/Section/Licensing/Source=Source',
						alignment = labelAlignment,
						width = LrView.share "label_width",
					},

					viewFactory:edit_field {
						value = bind 'info_source',
						immediate = true,
						width_in_chars = widthLong,
					},
				},

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:static_text {
						title = LOC '$$$/LrMediaWiki/Section/Licensing/Author=Author',
						alignment = labelAlignment,
						width = LrView.share "label_width",
					},

					viewFactory:edit_field {
						value = bind 'info_author',
						immediate = true,
						width_in_chars = widthLong,
					},
				},

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:static_text {
						title = LOC '$$$/LrMediaWiki/Section/Licensing/License=License',
						alignment = labelAlignment,
						width = LrView.share "label_width",
					},

					viewFactory:combo_box {
						value = bind 'info_license',
						immediate = true,
						width_in_chars = widthLong - 2,
						items = {
							'{{Cc-by-sa-4.0}}',
							'{{Cc-by-4.0}}',
							'{{Cc-zero}}',
						},
					},
				},

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:static_text {
						title = LOC '$$$/LrMediaWiki/Section/Licensing/Permission=Permission',
						alignment = labelAlignment,
						width = LrView.share "label_width",
					},

					viewFactory:edit_field {
						value = bind 'info_permission',
						immediate = true,
						width_in_chars = widthLong,
					},
				},

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:static_text {
						title = LOC '$$$/LrMediaWiki/Section/Licensing/OtherTemplates=Other templates',
						alignment = labelAlignment,
						width = LrView.share "label_width",
					},

					viewFactory:edit_field {
						value = bind 'info_templates',
						immediate = true,
						width_in_chars = widthLong,
					},
				},

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:static_text {
						title = LOC '$$$/LrMediaWiki/Section/Licensing/Other=Other fields',
						alignment = labelAlignment,
						width = LrView.share "label_width",
					},

					viewFactory:edit_field {
						value = bind 'info_other',
						immediate = true,
						width_in_chars = widthLong,
					},
				},

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:static_text {
						title = LOC '$$$/LrMediaWiki/Section/Licensing/Categories=Categories',
						alignment = labelAlignment,
						width = LrView.share "label_width",
					},

					viewFactory:edit_field {
						value = bind 'info_categories',
						immediate = true,
						width_in_chars = widthLong,
						height_in_lines = 3,
					},

					viewFactory:static_text {
						title = LOC '$$$/LrMediaWiki/Section/Licensing/Categories/Details=separate with ;',
					},
				},

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:static_text {
						alignment = labelAlignment,
						width = LrView.share "label_width",
					},

					viewFactory:push_button {
						title = LOC '$$$/LrMediaWiki/Section/Licensing/Preview=Preview generated wikitext',
							action = function(button)
								MediaWikiExportServiceProvider.showPreview(propertyTable)
							end,
					},
				},
			},
		},
	}
end

MediaWikiExportServiceProvider.showPreview = function(propertyTable)
	-- This function to provide a preview message box needs to run as a separate task,
	-- according to this discussion post: <https://forums.adobe.com/message/8493589#8493589>
	LrTasks.startAsyncTask( function ()
			LrFunctionContext.callWithContext ('LrMediaWiki', function(context)
			local activeCatalog = LrApplication.activeCatalog()
			local listOfTargetPhotos = activeCatalog:getTargetPhotos()
			local photo = listOfTargetPhotos[1] -- first photo of the selection
			local fileName = photo:getFormattedMetadata('fileName')
			local header
			-- t = string.format('# of selected photos: %d, first photo: %s', #listOfTargetPhotos, fileName) ; MediaWikiUtils.trace(t)
			local result, message = MediaWikiInterface.loadFileDescriptionTemplate()
			if result then
				local ExportFields = MediaWikiExportServiceProvider.fillFieldsByFile(propertyTable, photo)
				local wikitext = MediaWikiInterface.buildFileDescription(ExportFields)
				if #listOfTargetPhotos > 1 then
				header = LOC ('$$$/LrMediaWiki/Section/Licensing/PreviewHeader=The first photo ^1 has been used to create this preview text:', fileName)
					wikitext = header .. '\n\n' .. wikitext -- to let the additional text be shown prior of the wikitext
				end
				LrDialogs.message(LOC '$$$/LrMediaWiki/Section/Licensing/Preview=Preview generated wikitext', wikitext, 'info')
			else
				LrDialogs.message(LOC '$$$/LrMediaWiki/Export/DescriptionError=Error reading the file description', message, 'error')
			end
		end)
	end)
end

MediaWikiExportServiceProvider.fillFieldsByFile = function(propertyTable, photo)
	local exportFields = {
		-- fields set at export dialogue, copied to return object, order by UI
		info_source = propertyTable.info_source,
		info_author = propertyTable.info_author,
		info_license = propertyTable.info_license,
		info_permission = propertyTable.info_permission,
		info_templates = propertyTable.info_templates,
		info_other = propertyTable.info_other,
		info_categories = propertyTable.info_categories,
		-- fields by file, to be filled by this function, order by UI
		description = '<!-- description -->',
		location = '<!-- {{Location}} if GPS metadata is available -->',
		templates = '<!-- templates -->',
		categories = '<!-- per-file categories -->',
		timestamp = '<!-- date -->', -- meta data, no LrMediaWiki field
	}
	
	-- Field "description"
	local descriptionEn = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'description_en')
	local descriptionDe = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'description_de')
	local descriptionAdditional = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'description_additional')
	local description = ''
	local existDescription = false
	if not MediaWikiUtils.isStringEmpty(descriptionEn) then
		description = '{{en|1=' .. descriptionEn .. '}}'
		existDescription = true
	end
	if not MediaWikiUtils.isStringEmpty(descriptionDe) then
		if existDescription then
			description = description .. '\n'
		end
		description = description .. '{{de|1=' .. descriptionDe .. '}}'
		existDescription = true
	end
	if not MediaWikiUtils.isStringEmpty(descriptionAdditional) then
		if existDescription then
			description = description .. '\n'
		end
		description = description .. descriptionAdditional
		existDescription = true
	end
	if existDescription == false then
		description = LOC '$$$/LrMediaWiki/Section/Licensing/MandatoryDescription=A description is mandatory!'
	end
	exportFields.description = description

	-- Field "templates"
	-- Needs to be handled before field "location"
	exportFields.templates = ''
	local templates = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'templates') or ''
	local additionalTemplates = propertyTable.info_templates
	if not MediaWikiUtils.isStringEmpty(templates) then
		if MediaWikiUtils.isStringEmpty(additionalTemplates) then
			exportFields.templates = templates
		else
			exportFields.templates = templates .. '\n' .. additionalTemplates
		end
	else
		if not MediaWikiUtils.isStringEmpty(additionalTemplates) then
			exportFields.templates = additionalTemplates
		-- else
			-- "templates" and "additionalTemplates" are empty, an empty line ('\n') replaces "${templates}".
		end
	end
	-- local tpl = string.format('exportFields.templates: <%s>', exportFields.templates) ; MediaWikiUtils.trace(tpl)

	-- Field "location"
	-- Needs to be handled after field "templates"
	local gps = photo:getRawMetadata('gps')
	local LrMajorVersion = LrApplication.versionTable().major -- number type
	local LrVersionString = LrApplication.versionString() -- string with major, minor and revison numbers
	local subText = LOC '$$$/LrMediaWiki/Interface/MessageByMediaWiki=Message by MediaWiki for Lightroom'
	exportFields.location = '' 
	if gps and gps.latitude and gps.longitude then
		local location = '{{Location|' .. gps.latitude .. '|' .. gps.longitude
		if LrMajorVersion >= 6 then
			local heading = photo:getRawMetadata('gpsImgDirection')
			 -- The call of "getRawMetadata" with parameter "gpsImgDirection" is supported since LR 6.0
			if heading then
				location = location .. '|heading:' .. heading -- append heading at location
				local headingRounded = string.format("%.0f", heading) -- rounding, e.g. 359.9876 -> 360
				-- Newlines could be inserted in ZStrings by "^n". Whereas, splitting the message text into multiple lines, improves code readability.
				local hintLine1 = LOC ('$$$/LrMediaWiki/Interface/HintHeadingTrueL1=Hint: The Lightroom field ^[Direction^] has a value of ^1^D.', headingRounded) -- "^D" is a degree symbol
				local hintLine2 = LOC ('$$$/LrMediaWiki/Interface/HintHeadingTrueL2=This value has been used to set the ^[heading^] parameter at {{Location}} template.')
				local hintLine3 = LOC ('$$$/LrMediaWiki/Interface/HintHeadingTrueL3=This feature requires a Lightroom version 6/CC or higher.')
				local hintLine4 = LOC ('$$$/LrMediaWiki/Interface/HintHeadingTrueL4=This Lightroom version is ^1, therefore this feature works.', LrVersionString)
				local hintMessage = hintLine1 .. '\n' .. hintLine2 .. '\n' .. hintLine3 .. '\n' .. hintLine4
				local messageTable = {message = hintMessage, info = subText, actionPrefKey = 'Show hint message of used LR version'}
				LrDialogs.messageWithDoNotShow(messageTable)
			end
		elseif LrMajorVersion == 5 then 
			-- Newlines could be inserted in ZStrings by "^n". Whereas, splitting the message text into multiple lines, improves code readability.
			local hintLine1 = LOC ('$$$/LrMediaWiki/Interface/HintHeadingFalseL1=Hint: If the Lightroom field ^[Direction^] has a value, this can not be used to set a ^[heading^] parameter at {{Location}} template.')
			local hintLine2 = LOC ('$$$/LrMediaWiki/Interface/HintHeadingFalseL2=This feature requires a Lightroom version 6/CC or higher.')
			local hintLine3 = LOC ('$$$/LrMediaWiki/Interface/HintHeadingFalseL3=This Lightroom version is ^1, therefore this feature works not.', LrVersionString)
			local hintMessage = hintLine1 .. '\n' .. hintLine2 .. '\n' .. hintLine3
			local table = {message = hintMessage, info = subText, actionPrefKey = 'Show hint message of used LR version'}
			LrDialogs.messageWithDoNotShow(table)
		elseif LrMajorVersion == 4 then 
			-- LR version 4 has no "Direction" field; setting of "location" works, without setting "heading"
			-- To avoid this if branch to be empty, add a "no change" statement
			location = location .. '' -- add empty string
		else -- LrMajorVersion < 4
			-- LrMediaWiki supports LR versions >= 4.
			-- The following error message is a sample usage of it, with module name and line number, an example is
			-- here: <http://wwwimages.adobe.com/content/dam/Adobe/en/devnet/photoshoplightroom/pdfs/lr6/lightroom-sdk-guide.pdf#page=19>
			error 'Unsupported Lightroom version' -- no need of i18n the message text, due to the unlikely use case
		end
		location = location .. '}}' -- close Location template
		exportFields.location = location
		exportFields.templates = location .. '\n' .. exportFields.templates -- location precedes templates
	end

	-- Field "categories"
	exportFields.categories = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'categories') or ''

	-- Field "timestamp"
	local timestamp, Day, Month, Year, Time = ''
	local dateCreated = photo:getFormattedMetadata('dateCreated') -- LR IPTC field "Date Created"
	-- The return value has to be checked, not to be an empty string (different to parameter 'dateTimeOriginal')
	if dateCreated ~= '' then
		-- If "Metadata Set" is set to "EXIF and IPTC", "IPTC" or "Location", the field "Date Created"
		-- is freely editable. At some cases field checks work, at other cases not.
		-- The format of "dateCreated" might be "YYYY-MM-DDTHH:MM:SS" ("T" delimits date/time).
		--                        Index helper: "1234567890123456789"
		Day   = string.sub(dateCreated, 1, 10) -- "YYYY-MM-DD"
		Time  = string.sub(dateCreated, 12, 19) -- "HH:MM:SS"
		if Day and Time then
			-- result format: "YYYY-MM-DD HH:MM:SS"
			timestamp = Day .. ' ' .. Time
		else -- use the user defined value of "Date Created"
			timestamp = dateCreated
		end
	end

	local dateTimeOriginal = photo:getFormattedMetadata('dateTimeOriginal') -- LR EXIF field "Date Time Original"
	-- The return value has to be checked, not to be "nil" (different to parameter 'dateCreated')
	if dateTimeOriginal ~= nil then -- The source device supports Exif.
		-- If LR EXIF field "Date Created" is set too, the "timestamp" value will be overwritten.
		-- This follows the logic, how LR gives the "Date Time Original" priority over "Date Created",
		-- if the user sets at LR section "Metadata" the "Metadata Set" to "Default".
		-- In this case, fields "Capture Time" and "Capture Date" are shown, based on "Date Time Original",
		-- and changes are restricted to valid values at dialog "Edit Capture Time".
		-- The format of "dateTimeOriginal" is "DD.MM.YYYY HH:MM:SS".
		--                       Index helper: "1234567890123456789"
		Day   = string.sub(dateTimeOriginal, 1, 2) -- "DD"
		Month = string.sub(dateTimeOriginal, 4, 5) -- "MM"
		Year  = string.sub(dateTimeOriginal, 7, 10) -- "YYYY"
		Time  = string.sub(dateTimeOriginal, 12, 19) -- "HH:MM:SS"
		if Day and Month and Year and Time then
			-- result format: "YYYY-MM-DD HH:MM:SS"
			timestamp = Year .. '-' .. Month .. '-' .. Day .. ' ' .. Time
		end
	end
	exportFields.timestamp = timestamp

	return exportFields
end

MediaWikiExportServiceProvider.hidePrintResolution = true

MediaWikiExportServiceProvider.showSections = {'fileNaming', 'metadata', 'fileSettings', 'imageSettings', 'outputSharpening'}

MediaWikiExportServiceProvider.allowFileFormats = {'JPEG', 'TIFF'}

MediaWikiExportServiceProvider.allowColorSpaces = {'sRGB'}

MediaWikiExportServiceProvider.canExportVideo = false

MediaWikiExportServiceProvider.exportPresetFields = {
	{ key = 'username', default = '' },
	{ key = 'password', default = '' },
	{ key = 'api_path', default = 'https://commons.wikimedia.org/w/api.php' },
	{ key = 'gallery', default = '' },
	{ key = 'info_source', default = '{{own}}' },
	{ key = 'info_author', default = '' },
	{ key = 'info_license', default = '{{Cc-by-sa-4.0}}' },
	{ key = 'info_permission', default = '' },
	{ key = 'info_templates', default = '' },
	{ key = 'info_other', default = '' },
	{ key = 'info_categories', default = '' },
}

return MediaWikiExportServiceProvider
