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
local bind = LrView.bind

local Info = require 'Info'
local MediaWikiInterface = require 'MediaWikiInterface'
local MediaWikiUtils = require 'MediaWikiUtils'

local MediaWikiExportServiceProvider = {}

MediaWikiExportServiceProvider.processRenderedPhotos = function(functionContext, exportContext)
	-- configure progess display
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
			local descriptionEn = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'description_en')
			local descriptionDe = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'description_de')
			local descriptionAdditional = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'description_additional')
			local description = ''
			if not MediaWikiUtils.isStringEmpty(descriptionEn) then
				description = '{{en|1=' .. descriptionEn .. '}}\n'
			end
			if not MediaWikiUtils.isStringEmpty(descriptionDe) then
				description = description .. '{{de|1=' .. descriptionDe .. '}}\n'
			end
			if not MediaWikiUtils.isStringEmpty(descriptionAdditional) then
				description = description .. descriptionAdditional
			end
			local hasDescription = not MediaWikiUtils.isStringEmpty(description)
			local source = exportSettings.info_source
			local timestampSeconds = photo:getRawMetadata('dateTimeOriginal')
			local timestamp = ''
			if timestampSeconds then
				timestamp = os.date("!%Y-%m-%d %H:%M:%S", timestampSeconds + 978307200)
			end
			local author = exportSettings.info_author
			local license = exportSettings.info_license
			local permission = exportSettings.info_permission
			local templates = exportSettings.info_templates
			local additionalTemplates = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'templates') or ''
			if not MediaWikiUtils.isStringEmpty(additionalTemplates) then
				templates = templates .. '\n' .. additionalTemplates
			end
			local other = exportSettings.info_other
			local categories = exportSettings.info_categories
			local additionalCategories = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'categories') or ''

			local gps = photo:getRawMetadata('gps')
			local LrMajorVersion = LrApplication.versionTable().major -- number type
			local LrVersionString = LrApplication.versionString() -- string with major, minor and revison numbers
			local hintMessage = nil
			local subText = LOC('$$$/LrMediaWiki/Interface/MessageByMediaWiki=Message by MediaWiki for Lightroom')
			if gps and gps.latitude and gps.longitude then
				local location = '{{Location|' .. gps.latitude .. '|' .. gps.longitude
				-- If LR field "Direction" (German: "Richtung") is set, add "heading" parameter to Commons template "Location"

				-- The LR version is checked, because Adobe introduced the parameter "gpsImgDirection" to the 
				-- call of photo:getRawMetadata with LR SDK 6.0.
				-- Without LR version check, the usage of this plug-in shows
				-- a warning message at export, if using LR version < 6 (e.g. 5):
				-- English: Warning – Unable to Export: An internal error has occurred: Unknown key: "gpsImgDirection"
				-- German: Warnung – Export nicht möglich: Ein interner Fehler ist aufgetreten: Unknown key: "gpsImgDirection"
				-- Even it's a warning, the export is cancelled.
				-- To avoid this warning message, the version check is needed – substituted by a hint message.

				-- The version check differs between two cases of major LR versions: (a) >= 6 and (b) < 6
				-- At both cases a hint message box is shown – with different messages, depending on the LR version:
				-- * (a) Users of LR 6 or higher get informed about this feature, if the user has set the "Direction" field.
				-- * (b) Users of LR 5 or LR 4 get informed, the feature is not available, due to the insufficient LR version.
				-- At both cases the hint message box includes a "Don't show again" (German: "Nicht erneut anzeigen") checkbox.
				-- If the user decides, to set this option and decides to revert this decision later, a reset of warning dialogs at LR is needed:
				-- English: Edit -> Preferences... -> General -> Prompts -> Reset all warning dialogs
				-- German: Bearbeiten -> Voreinstellungen -> Allgemein -> Eingabeaufforderungen -> Alle Warndialogfelder zurücksetzen

				if LrMajorVersion >= 6 then
					local heading = photo:getRawMetadata('gpsImgDirection')
					 -- The call of "getRawMetadata" with parameter "gpsImgDirection" is supported since LR 6.0
					if heading then
						-- At users with a LR version >= 6:
						-- LR can store a direction value with up to 4 digits beyond a decimal point,
						-- but shows at user interface a rounded value without decimal places (by mouse over the direction field).
						-- Showing a rounded value is done by the two LrMediaWiki hint messages too, to avoid confusion of the user seeing different values.
						-- The Location template parameter "heading" is filled by the storage value of LR.
						-- Sample: A LR direction input of 359.987654321 is stored by LR as 359.9876, shown by LR and by the hint messages
						-- as 360°, at Location template the LR stored value of 359.9876 is set.
						location = location .. '|heading:' .. heading -- append heading at location
						local headingRounded = string.format("%.0f", heading) -- rounding, e.g. 359.9876 -> 360
						-- There are problems inserting newlines (\n) in JASON strings. Workaround, splitting the message in 4 parts:
						local hintLine1 = LOC('$$$/LrMediaWiki/Interface/HintHeadingTrueL1=Hint: The Lightroom field “Direction” has a value of ^1°.', headingRounded)
						local hintLine2 = LOC('$$$/LrMediaWiki/Interface/HintHeadingTrueL2=This value has been used to set the “heading” parameter at {{Location}} template.')
						local hintLine3 = LOC('$$$/LrMediaWiki/Interface/HintHeadingTrueL3=This feature requires a Lightroom version 6/CC or higher.')
						local hintLine4 = LOC('$$$/LrMediaWiki/Interface/HintHeadingTrueL4=This Lightroom version is ^1, therefore this feature works.', LrVersionString )
						hintMessage = hintLine1 .. '\n' .. hintLine2 .. '\n' .. hintLine3 .. '\n' .. hintLine4
						local messageTable = {message = hintMessage, info = subText, actionPrefKey = 'Show hint message of used LR version'}
						LrDialogs.messageWithDoNotShow(messageTable)
					else
						-- This shouldn't happen, because LR has a good direction field check, accepting only valid values.
						-- It might be impossible, to test this case. However, shit happens.
						LrDialogs.message(LOC '$$$/LrMediaWiki/Interface/InvalidDirectionValue=“Direction” has an invalid value.', subText, 'critical')
					end
				else -- LrMajorVersion < 6
					if LrMajorVersion == 5 then 
						-- LR versions < 5 don't have a "Direction" field
						-- There are problems inserting newlines (\n) in JASON strings. Workaround, splitting the message in 3 parts:
						local hintLine1 = LOC('$$$/LrMediaWiki/Interface/HintHeadingFalseL1=Hint: If the Lightroom field “Direction” has a value, this can not be used to set a “heading” parameter at {{Location}} template.')
						local hintLine2 = LOC('$$$/LrMediaWiki/Interface/HintHeadingFalseL2=This feature requires a Lightroom version 6/CC or higher.')
						local hintLine3 = LOC('$$$/LrMediaWiki/Interface/HintHeadingFalseL3=This Lightroom version is ^1, therefore this feature works not.', LrVersionString )
						hintMessage = hintLine1 .. '\n' .. hintLine2 .. '\n' .. hintLine3
						local table = {message = hintMessage, info = subText, actionPrefKey = 'Show hint message of used LR version'}
						LrDialogs.messageWithDoNotShow(table)
					end
				end
				location = location .. '}}\n' -- close Location template
				templates = location .. templates
			end

			local fileDescription = MediaWikiInterface.buildFileDescription(description, source, timestamp, author, license, templates, other, categories, additionalCategories, permission)

			-- ensure that the target file name does not contain a series of spaces or
			-- underscores (as this would cause the upload to fail without a proper
			-- error message)
			local fileName = string.gsub(LrPathUtils.leafName(pathOrMessage), '[ _]+', '_')
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
							local result, message = MediaWikiInterface.loadFileDescriptionTemplate()
							if result then
								local wikitext = MediaWikiInterface.buildFileDescription('<!-- description -->', propertyTable.info_source, '<!-- date -->', propertyTable.info_author, propertyTable.info_license, '<!-- {{Location}} if GPS metadata is available -->\n' .. propertyTable.info_templates, propertyTable.info_other, propertyTable.info_categories, '<!-- per-file categories -->', '<!-- permission -->')
								LrDialogs.message(LOC '$$$/LrMediaWiki/Section/Licensing/Preview=Preview generated wikitext', wikitext, 'info')
							else
								LrDialogs.message(LOC '$$$/LrMediaWiki/Export/DescriptionError=Error reading the file description', message, 'error')
							end
						end,
					},
				},
			},
		},
	}
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
	{ key = 'info_source', default = '{{own}}' },
	{ key = 'info_author', default = '' },
	{ key = 'info_license', default = '{{Cc-by-sa-4.0}}' },
	{ key = 'info_permission', default = '' },
	{ key = 'info_templates', default = '' },
	{ key = 'info_other', default = '' },
	{ key = 'info_categories', default = '' },
	{ key = 'gallery', default = '' },
}

return MediaWikiExportServiceProvider
