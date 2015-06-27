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
			if gps and gps.latitude and gps.longitude then
				local location = '{{Location|' .. gps.latitude .. '|' .. gps.longitude .. '}}\n'
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
