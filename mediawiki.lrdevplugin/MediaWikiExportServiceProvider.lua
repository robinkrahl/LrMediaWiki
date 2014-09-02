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
local LrFileUtils = import 'LrFileUtils'
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
	local progressScope = exportContext:configureProgress{
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

	-- iterate over photos
	for i, rendition in exportContext:renditions() do
		-- render photo
		local success, pathOrMessage = rendition:waitForRender()
		if success then
			-- do upload to MediaWiki
			local photo = rendition.photo
			
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
			if MediaWikiUtils.isStringEmpty(description) then
				rendition:uploadFailed(LOC '$$$/LrMediaWiki/Export/NoDescription=No description given for this file!')
				return
			end
			local source = exportSettings.info_source
			local timestampSeconds = photo:getRawMetadata('dateTimeOriginal')
			local timestamp = ''
			if timestampSeconds then
				timestamp = os.date("!%Y-%m-%d", timestampSeconds + 978307200)
			end
			local author = exportSettings.info_author
			local license = exportSettings.info_license
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
			
			local fileDescription = MediaWikiInterface.buildFileDescription(description, source, timestamp, author, license, templates, other, categories, additionalCategories)
			
			MediaWikiInterface.uploadFile(pathOrMessage, fileDescription)
			LrFileUtils.delete(pathOrMessage)
		else
			-- rendering failed --> report failure
			rendition:uploadFailed(pathOrMessage)
		end
	end
end

MediaWikiExportServiceProvider.sectionsForTopOfDialog = function(viewFactory, propertyTable)
	return {
		{
			title = LOC '$$$/LrMediaWiki/Section/User/Title=Login Information',
			synopsis = bind 'username',
			
			viewFactory:row {
				spacing = viewFactory:control_spacing(),
				
				viewFactory:static_text {
					title = LOC '$$$/LrMediaWiki/Section/User/Username=Username',
				},
				
				viewFactory:edit_field {
					value = bind 'username',
					immediate = true,
				},
			},
				
			viewFactory:row {
				spacing = viewFactory:control_spacing(),
				
				viewFactory:static_text {
					title = LOC '$$$/LrMediaWiki/Section/User/Password=Password',
				},
				
				viewFactory:password_field {
					value = bind 'password',
				},
			},
			
			viewFactory:row {
				spacing = viewFactory:control_spacing(),
				
				viewFactory:static_text {
					title = LOC '$$$/LrMediaWiki/Section/User/ApiPath=API path',
				},
				
				viewFactory:edit_field {
					value = bind 'api_path',
					immediate = true,
					width_in_chars = 30,
				},
				
				viewFactory:static_text {
					title = LOC '$$$/LrMediaWiki/Section/User/ApiPath/Details=Path to the api.php file',
				},
			},
		},
		{
			title = LOC "$$$/LrMediaWiki/Section/Licensing/Title=Upload Information",
			synopsis = bind 'info_license',
			
			viewFactory:row {
				spacing = viewFactory:control_spacing(),
				
				viewFactory:static_text {
					title = LOC '$$$/LrMediaWiki/Section/Licensing/Source=Source',
				},
				
				viewFactory:edit_field {
					value = bind 'info_source',
					immediate = true,
				},
			},
			
			viewFactory:row {
				spacing = viewFactory:control_spacing(),
				
				viewFactory:static_text {
					title = LOC '$$$/LrMediaWiki/Section/Licensing/Author=Author',
				},
				
				viewFactory:edit_field {
					value = bind 'info_author',
					immediate = true,
				},
			},
			
			viewFactory:row {
				spacing = viewFactory:control_spacing(),
				
				viewFactory:static_text {
					title = LOC '$$$/LrMediaWiki/Section/Licensing/License=License',
				},
				
				viewFactory:combo_box {
					value = bind 'info_license',
					immediate = true,
					items = {
						'{{Cc-by-sa-4.0}}',
						'{{Cc-by-4.0}}',
						'{{Cc-zero}}',
					},
				},
			},
			
			viewFactory:row {
				spacing = viewFactory:control_spacing(),
				
				viewFactory:static_text {
					title = LOC '$$$/LrMediaWiki/Section/Licensing/OtherTemplates=Other templates',
				},
				
				viewFactory:edit_field {
					value = bind 'info_templates',
					immediate = true,
				},
			},
			
			viewFactory:row {
				spacing = viewFactory:control_spacing(),
				
				viewFactory:static_text {
					title = LOC '$$$/LrMediaWiki/Section/Licensing/Other=Other fields',
				},
				
				viewFactory:edit_field {
					value = bind 'info_other',
					immediate = true,
				},
			},

			viewFactory:row {
				spacing = viewFactory:control_spacing(),
				
				viewFactory:static_text {
					title = LOC '$$$/LrMediaWiki/Section/Licensing/Categories=Categories',
				},
				
				viewFactory:edit_field {
					value = bind 'info_categories',
					immediate = true,
					width_in_chars = 30,
					height_in_lines = 3,
				},
				
				viewFactory:static_text {
					title = LOC '$$$/LrMediaWiki/Section/Licensing/Categories/Details=separate with ;',
				},
			},
			
			viewFactory:row {
				spacing = viewFactory:control_spacing(),
				
				viewFactory:push_button {
					title = LOC '$$$/LrMediaWiki/Section/Licensing/Preview=Preview generated wikitext',
					action = function(button)
						local wikitext = MediaWikiInterface.buildFileDescription('<!-- description -->', propertyTable.info_source, '<!-- date -->', propertyTable.info_author, propertyTable.info_license, '<!-- {{Location}} if GPS metadata is available -->\n' . propertyTable.info_templates, propertyTable.info_other, propertyTable.info_categories, '<!-- per-file categories -->')
						LrDialogs.message(LOC '$$$/LrMediaWiki/Section/Licensing/Preview=Preview generated wikitext', wikitext, 'info')
					end,
				},
			},
		},
	}
end

MediaWikiExportServiceProvider.hidePrintResolution = true

MediaWikiExportServiceProvider.showSections = {'fileNaming', 'metadata', 'fileSettings'}

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
	{ key = 'info_templates', default = '' },
	{ key = 'info_other', default = '' },
	{ key = 'info_categories', default = '' },
}

return MediaWikiExportServiceProvider
