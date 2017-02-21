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

local LrApplication = import 'LrApplication'
local LrBinding = import 'LrBinding'
local LrDate = import 'LrDate'
local LrDialogs = import 'LrDialogs'
local LrErrors = import 'LrErrors'
local LrFileUtils = import 'LrFileUtils'
local LrFunctionContext = import 'LrFunctionContext'
local LrPathUtils = import 'LrPathUtils'
local LrTasks = import 'LrTasks'
local LrView = import 'LrView'

local bind = LrView.bind

local Info = require 'Info'
local MediaWikiInterface = require 'MediaWikiInterface'
local MediaWikiUtils = require 'MediaWikiUtils'

local MediaWikiExportServiceProvider = {}

MediaWikiExportServiceProvider.processRenderedPhotos = function(functionContext, exportContext) -- luacheck: ignore functionContext
	-- configure progress display
	local exportSession = exportContext.exportSession
	local photoCount = exportSession:countRenditions()
	local MessageSingle = LOC("$$$/LrMediaWiki/Export/Progress=Exporting ^1 photos to a MediaWiki", photoCount)
	local MessageMultiple = LOC "$$$/LrMediaWiki/Export/Progress/One=Exporting one photo to a MediaWiki"
	exportContext:configureProgress{
		title = photoCount > 1 and MessageSingle or MessageMultiple
	}

	local exportSettings = assert(exportContext.propertyTable)

	-- require username, password, apipath, source, author, license
	if MediaWikiUtils.isStringEmpty(exportSettings.username) then
		LrErrors.throwUserError(LOC "$$$/LrMediaWiki/Export/NoUsername=No username given!")
	end
	if MediaWikiUtils.isStringEmpty(exportSettings.password) then
		LrErrors.throwUserError(LOC "$$$/LrMediaWiki/Export/NoPassword=No password given!")
	end
	if MediaWikiUtils.isStringEmpty(exportSettings.api_path) then
		LrErrors.throwUserError(LOC "$$$/LrMediaWiki/Export/NoApiPath=No API path given!")
	end
	if exportSettings.info_template == 'Information' and MediaWikiUtils.isStringEmpty(exportSettings.info_source) then
		LrErrors.throwUserError(LOC "$$$/LrMediaWiki/Export/NoSource=No source given!")
	end
	if exportSettings.info_template == 'Information' and MediaWikiUtils.isStringEmpty(exportSettings.info_author) then
		LrErrors.throwUserError(LOC "$$$/LrMediaWiki/Export/NoAuthor=No author given!")
	end
	if MediaWikiUtils.isStringEmpty(exportSettings.info_license) and MediaWikiUtils.isStringEmpty(exportSettings.info_permission) then
		LrErrors.throwUserError(LOC "$$$/LrMediaWiki/Export/NoLicense=No license given!")
	end

	MediaWikiInterface.prepareUpload(exportSettings.username, exportSettings.password, exportSettings.api_path, exportSettings.info_template)

	-- file names for gallery creation
	local fileNames = {}

	-- iterate over photos
	for i, rendition in exportContext:renditions() do -- luacheck: ignore i
		-- render photo
		local success, pathOrMessage = rendition:waitForRender()
		if success then
			local photo = rendition.photo
			local catalog = photo.catalog
			-- do upload to MediaWiki
			local artworkParameters = { -- Parameters of infobox template "Artwork" without "description" and "permission"
				artist = '',
				author = '',
				title = '',
				date = '',
				medium = '',
				dimensions = '',
				institution = '',
				department = '',
				accessionNumber = '',
				placeOfCreation = '',
				placeOfDiscovery = '',
				objectHistory = '',
				exhibitionHistory = '',
				creditLine = '',
				inscriptions = '',
				notes = '',
				references = '',
				source = '',
				wikidata = '',
			}
			local objectPhotoParameters = { -- Parameters of infobox template "Object photo" without "description" and "permission"
				object = '',
				detail = '',
				detailPosition = '',
			}
			local exportFields = { -- Fields set at export dialog, ordered by UI
				info_template = exportSettings.info_template,
				info_source = exportSettings.info_source,
				info_author = exportSettings.info_author,
				info_license = exportSettings.info_license,
				info_permission = exportSettings.info_permission,
				info_templates = exportSettings.info_templates,
				info_categories = exportSettings.info_categories,
				-- fields by file, to be filled by fillExportFields(), order by UI
				description = '',
				location = '',
				templates = '',
				categories = '',
				otherVersions = '',
				otherFields = '',
				date = '',
				art = artworkParameters, -- Parameters of infobox template "Artwork"
				objectPhoto = objectPhotoParameters, -- Parameters of infobox template "Object photo"
			}

			local filledExportFields = MediaWikiExportServiceProvider.fillFieldsByFile(exportFields, photo)
			local fileDescription = MediaWikiInterface.buildFileDescription(filledExportFields, photo)

			-- ensure that the target file name does not contain a series of spaces or
			-- underscores (as this would cause the upload to fail without a proper
			-- error message)
			local fileName = string.gsub(LrPathUtils.leafName(pathOrMessage), '[ _]+', '_')
			local hasDescription = MediaWikiUtils.isStringFilled(filledExportFields.description)
			local message = MediaWikiInterface.uploadFile(pathOrMessage, fileDescription, hasDescription, fileName)
			if message then
				rendition:uploadFailed(message)
			else
				-- create new snapshot if the upload was successful
				if MediaWikiUtils.getCreateSnapshots() then
					local currentTimeStamp = LrDate.currentTime()
					local currentDate = LrDate.formatShortDate(currentTimeStamp)
					local currentTime = LrDate.formatShortTime(currentTimeStamp)
					local snapshotTitle = LOC("$$$/LrMediaWiki/Export/Snapshot=MediaWiki export, ^1 ^2, ^3", currentDate, currentTime, exportSettings.api_path)
					catalog:withWriteAccessDo('CreateDevelopSnapshot', function(context) -- luacheck: ignore context
						photo:createDevelopSnapshot(snapshotTitle, true)
					end)
				end

				-- add configured export keyword
				local keyword = MediaWikiUtils.getExportKeyword()
				if MediaWikiUtils.isStringFilled(keyword) then
					catalog:withWriteAccessDo('AddExportKeyword', function(context) -- luacheck: ignore context
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

	if MediaWikiUtils.isStringFilled(exportSettings.gallery) and fileNames then
		MediaWikiInterface.addToGallery(fileNames, exportSettings.gallery)
	end
end

MediaWikiExportServiceProvider.sectionsForTopOfDialog = function(viewFactory, propertyTable)
	local labelAlignment = 'right'
	local widthLong = 440

	return {
		{
			title = LOC "$$$/LrMediaWiki/Section/User/Title=Login Information",
			synopsis = bind 'username',

			viewFactory:column {
				spacing = viewFactory:control_spacing(),

				viewFactory:row {
					viewFactory:static_text {
						title = LOC "$$$/LrMediaWiki/Section/User/Username=Username:",
						alignment = labelAlignment,
						width = LrView.share 'label_width',
					},
					viewFactory:edit_field {
						value = bind 'username',
						immediate = true,
						width = widthLong,
					},
				},
				viewFactory:row {
					viewFactory:static_text {
						title = LOC "$$$/LrMediaWiki/Section/User/Password=Password:",
						alignment = labelAlignment,
						width = LrView.share 'label_width',
					},
					viewFactory:password_field {
						value = bind 'password',
						width = widthLong,
					},
				},
				viewFactory:row {
					viewFactory:static_text {
						title = LOC "$$$/LrMediaWiki/Section/User/ApiPath=API Path:",
						alignment = labelAlignment,
						width = LrView.share 'label_width',
					},
					viewFactory:edit_field {
						value = bind 'api_path',
						immediate = true,
						width = widthLong,
					},
				},
				viewFactory:row {
					viewFactory:static_text {
						title = LOC "$$$/LrMediaWiki/Section/User/Gallery=Gallery:",
						alignment = labelAlignment,
						width = LrView.share 'label_width',
					},
					viewFactory:edit_field {
						value = bind 'gallery',
						immediate = true,
						width = widthLong,
					},
				},
			},
		},
		{
			title = LOC "$$$/LrMediaWiki/Section/Licensing/Title=Upload Information",
			synopsis = bind 'info_template',

			viewFactory:column {
				spacing = viewFactory:control_spacing(),
				viewFactory:row {
					viewFactory:static_text {
						title = LOC "$$$/LrMediaWiki/Section/Licensing/InfoboxTemplate=Infobox Template:",
						alignment = labelAlignment,
						width = LrView.share 'label_width',
					},
					viewFactory:popup_menu {
						value = bind 'info_template',
						items = {
							'Information',
							'Information (de)',
							'Artwork',
							'Object photo',
						},
					},
					viewFactory:push_button {
						title = LOC "$$$/LrMediaWiki/Section/Licensing/Preview=Preview of generated wikitext",
							action = function(button) -- luacheck: ignore button
								MediaWikiExportServiceProvider.showPreview(propertyTable)
							end,
					},
				},
				viewFactory:row {
					place = "overlapping",
					viewFactory:view {
						spacing = viewFactory:control_spacing(),
						visible = LrBinding.keyIsNot( 'info_template', 'Artwork' ),
						viewFactory:row {
							viewFactory:static_text {
								title = LOC "$$$/LrMediaWiki/Section/Licensing/Source=Source:",
								alignment = labelAlignment,
								width = LrView.share 'label_width',
							},
							viewFactory:edit_field {
								value = bind 'info_source',
								immediate = true,
								width = widthLong,
							},
						},
						viewFactory:row {
							viewFactory:static_text {
								title = LOC "$$$/LrMediaWiki/Section/Licensing/Author=Author:",
								alignment = labelAlignment,
								width = LrView.share 'label_width',
							},
							viewFactory:edit_field {
								value = bind 'info_author',
								immediate = true,
								width = widthLong,
							},
						},
					},
					viewFactory:view {
						visible = LrBinding.keyEquals( 'info_template', 'Artwork' ),
						viewFactory:row {
							viewFactory:spacer {
								width = LrView.share 'label_width',
							},
							viewFactory:static_text {
								title = LOC "$$$/LrMediaWiki/Section/Licensing/HintArtwork=“Author” and “Source” of infobox template “Artwork” can not maintained here.^nThey are maintained per file.",
								alignment = 'center',
								width = widthLong,
							},
						},
					},
				},
				viewFactory:row {
					viewFactory:static_text {
						title = LOC "$$$/LrMediaWiki/Section/Licensing/Permission=Permission:",
						alignment = labelAlignment,
						width = LrView.share 'label_width',
					},
					viewFactory:edit_field {
						value = bind 'info_permission',
						immediate = true,
						width = widthLong,
					},
				},
				viewFactory:row {
					viewFactory:static_text {
						title = LOC "$$$/LrMediaWiki/Section/Licensing/OtherTemplates=Other Templates:",
						alignment = labelAlignment,
						width = LrView.share 'label_width',
					},
					viewFactory:edit_field {
						value = bind 'info_templates',
						immediate = true,
						width = widthLong,
					},
				},
				viewFactory:row {
					viewFactory:static_text {
						title = LOC "$$$/LrMediaWiki/Section/Licensing/License=License:",
						alignment = labelAlignment,
						width = LrView.share 'label_width',
					},
					viewFactory:combo_box {
						value = bind 'info_license',
						immediate = true,
						width = widthLong,
						items = {
							'{{Cc-by-sa-4.0}}',
							'{{Cc-by-4.0}}',
							'{{Cc-zero}}',
						},
					},
				},
				viewFactory:row {
					viewFactory:static_text {
						title = LOC "$$$/LrMediaWiki/Section/Licensing/Categories=Categories:^nseparated by ;",
						alignment = labelAlignment,
						width = LrView.share 'label_width',
					},
					viewFactory:edit_field {
						value = bind 'info_categories',
						immediate = true,
						width = widthLong,
						height_in_lines = 3,
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
			LrFunctionContext.callWithContext ('showPreview', function(context) -- luacheck: ignore context
			local properties = LrBinding.makePropertyTable(context)
			local activeCatalog = LrApplication.activeCatalog()
			properties.photoList = activeCatalog:getTargetPhotos()
			local photo = properties.photoList[1] -- first photo of the selection
			properties.fileName = photo:getFormattedMetadata('fileName')
			properties.index = 1

			local setCurrentOfAll = function(current)
				properties.currentOfAll = current .. '/' .. #properties.photoList
			end

			local setPhoto = function(pos)
				local max = #properties.photoList
				if pos == 'first' then
					properties.index = 1
				elseif pos == 'previous' then
					if properties.index > 1 then
						properties.index = properties.index - 1
					else -- we are at first position
						return
					end
				elseif pos == 'next' then
					if properties.index < max then
						properties.index = properties.index + 1
					else -- we are at last position
						return
					end
				elseif pos == 'last' then
					properties.index = max
				else -- invalid parameter "pos"
					return
				end
				LrTasks.startAsyncTask( function ()
					-- LrFunctionContext.callWithContext ('showPreview', function(context) -- luacheck: ignore context
						setCurrentOfAll(properties.index)
						photo = properties.photoList[properties.index]
						properties.fileName = photo:getFormattedMetadata('fileName')
						local ExportFields = MediaWikiExportServiceProvider.fillFieldsByFile(propertyTable, photo)
						local wikitext = MediaWikiInterface.buildFileDescription(ExportFields, photo)
						properties.dialogValue = wikitext
					-- end)
				end)
			end

			setCurrentOfAll(1)
			local wikitext
			local result, message = MediaWikiInterface.loadFileDescriptionTemplate(propertyTable.info_template)
			if not result then
				LrDialogs.message(LOC "$$$/LrMediaWiki/Export/DescriptionError=Error reading the file description", message, 'error')
				return
			end

			local ExportFields = MediaWikiExportServiceProvider.fillFieldsByFile(propertyTable, photo)
			wikitext = MediaWikiInterface.buildFileDescription(ExportFields, photo)
			local dialogTitle = LOC "$$$/LrMediaWiki/Section/Licensing/Preview=Preview of generated wikitext"
			local factory = LrView.osFactory()
			properties.dialogValue = wikitext

			local contents = factory:column {
				fill_horizontal = 1,
				fill_vertical = 1,
				spacing = factory:label_spacing(),
				factory:row {
					fill_vertical = 1,
					bind_to_object = properties,
					factory:static_text {
						title = LrView.bind('dialogValue'),
						height_in_lines = -1, -- to let the text wrap
						width_in_chars = 60, -- text wrap needs a value too
						height = 200, -- initial value
						fill_horizontal = 1,
						fill_vertical = 1,
						font = { -- see [1]
							name = MediaWikiUtils.getPreviewWikitextFontName(),
							size = MediaWikiUtils.getPreviewWikitextFontSize(),
						},
						tooltip = LOC "$$$/LrMediaWiki/Preview/TooltipWikitext=Font name and font size of the wikitext are customizable at the plug-in’s configuration.",
					},
				},
				factory:row {
					factory:separator {
						fill_horizontal = 1, -- "1" means full width
					},
				},
				factory:row {
					factory:push_button {
						-- 2 x U+25C0 = BLACK LEFT-POINTING TRIANGLE = ◀◀
						title = '◀◀',
						action = function() setPhoto('first') end,
						tooltip = LOC "$$$/LrMediaWiki/Preview/TooltipButtonFirst=First file",
					},
					factory:push_button {
						-- U+25C0 = BLACK LEFT-POINTING TRIANGLE = ◀
						title = '◀',
						action = function() setPhoto('previous') end,
						tooltip = LOC "$$$/LrMediaWiki/Preview/TooltipButtonPrevious=Previous file",
					},
					factory:push_button {
						-- U+25B6 = BLACK RIGHT-POINTING TRIANGLE = ▶
						title = '▶',
						action = function() setPhoto('next') end,
						tooltip = LOC "$$$/LrMediaWiki/Preview/TooltipButtonNext=Next file",
					},
					factory:push_button {
						-- 2 x U+25B6 = BLACK RIGHT-POINTING TRIANGLE = ▶▶
						title = '▶▶',
						action = function() setPhoto('last') end,
						tooltip = LOC "$$$/LrMediaWiki/Preview/TooltipButtonLast=Last file",
					},
					factory:static_text {
						bind_to_object = properties,
						title = LrView.bind('currentOfAll'),
						width_in_chars = 30,
						tooltip = LOC "$$$/LrMediaWiki/Preview/TooltipCurrentOfAll=Current index in relation to the total number of selected files",
					},
				},
				factory:row {
					factory:static_text {
						title = LOC "$$$/LrMediaWiki/Preview/FileName=File Name:",
					},
					factory:static_text {
						bind_to_object = properties,
						title = LrView.bind('fileName'),
						width_in_chars = 30,
						fill_horizontal = 1,
						tooltip = LOC "$$$/LrMediaWiki/Preview/TooltipFileName=Current file name",
					},
				},
			}

			LrDialogs.presentModalDialog({
				title = dialogTitle,
				contents = contents,
				-- cancelVerb = '< exclude >', -- no cancel button
				resizable = true,
				save_frame= 'PreviewDialogSaveFrame',
			})

		end)
	end)
end

MediaWikiExportServiceProvider.fillFieldsByFile = function(propertyTable, photo)
	-- All decisions done by this function should be documented at user's guide.
	local artworkParameters = { -- Parameters of infobox template "Artwork"
		artist = '', -- '<!-- Artist -->',
		author = '', -- '<!-- Author -->',
		title = '', -- '<!-- Title -->',
		date = '', -- '<!-- Date -->',
		medium = '', -- '<!-- Medium -->',
		dimensions = '', -- '<!-- Dimensions -->',
		institution = '', -- '<!-- Institution -->',
		department = '', -- '<!-- Department -->',
		accessionNumber = '', -- '<!-- Accession number -->',
		placeOfCreation = '', -- '<!-- Place of creation -->',
		placeOfDiscovery = '', -- '<!-- Place of discovery -->',
		objectHistory = '', -- '<!-- Object history -->',
		exhibitionHistory = '', -- '<!-- Exhibition history -->',
		creditLine = '', -- '<!-- Credit line -->',
		inscriptions = '', -- '<!-- Inscriptions -->',
		notes = '', -- '<!-- Notes -->',
		references = '', -- '<!-- References -->',
		source = '', -- '<!-- Source -->',
		wikidata = '', -- '<!-- Wikidata -->',
	}
	local objectPhotoParameters = { -- Parameters of infobox template "Object photo" without "description" and "permission"
		object = '',
		detail = '',
		detailPosition = '',
	}
	local exportFields = { -- Fields set at export dialog, copied to return object, order by UI
		info_template = propertyTable.info_template,
		info_source = propertyTable.info_source,
		info_author = propertyTable.info_author,
		info_license = propertyTable.info_license,
		info_permission = propertyTable.info_permission,
		info_templates = propertyTable.info_templates,
		info_categories = propertyTable.info_categories,
		-- Fields by file, to be filled by this function, ordered by UI:
		description = '', -- '<!-- Description -->',
		location = '', -- '<!-- {{Location}} if GPS metadata is available -->',
		templates = '', -- '<!-- Templates -->',
		categories = '', -- '<!-- Per-file categories -->',
		otherVersions = '', -- '<!-- Other versions -->',
		otherFields = '', -- '<!-- Other fields -->',
		date = '', -- '<!-- Date -->',
		art = artworkParameters, -- Parameters of infobox template "Artwork"
		objectPhoto = objectPhotoParameters, -- Parameters of infobox template "Object photo"
	}

	-- Required "Information" template parameters:
	-- * Description
	-- * Source
	-- * Author
	-- Required "Artwork" template parameters:
	-- * Source

	-- Field "source"
	if exportFields.info_template == 'Information' and MediaWikiUtils.isStringEmpty(exportFields.info_source) then
		exportFields.info_source = '<!-- A source is required. -->'
	elseif exportFields.info_template == 'Artwork' and MediaWikiUtils.isStringEmpty(exportFields.art.source) then
		exportFields.art.source = '<!-- A source is required. -->'
	end

	-- Field "author"
	if exportFields.info_template == 'Information' and MediaWikiUtils.isStringEmpty(exportFields.info_author) then
		exportFields.info_author = '<!-- An author is required. -->'
	end

	-- Field "license"
	-- "== {{int:license-header}} ==" is only used, if followed by a filled license line
	if MediaWikiUtils.isStringFilled(exportFields.info_license)  then
		exportFields.info_license = '== {{int:license-header}} ==\n' .. exportFields.info_license .. '\n'
	end

	-- Field "description"
	local descriptionEn = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'description_en')
	local descriptionDe = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'description_de')
	local descriptionAdditional = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'description_additional')
	local description = ''
	local existDescription = false
	-- If multiple description fields are set, priorities are considered. The sequence of detections
	-- handles low priorities first, higher priorities are handled later and override prior handlings.
	-- If multiple LrMediaWiki fields are set, they are concatenated, by avoiding empty lines.
	-- Appending a newline character depends on the context.
	if MediaWikiUtils.isStringFilled(descriptionEn) then
		description = '{{en|1=' .. descriptionEn .. '}}'
		existDescription = true
	end
	if MediaWikiUtils.isStringFilled(descriptionDe) then
		if existDescription then
			description = description .. '\n' -- Newline
		end
		if propertyTable.info_template == 'Information (de)' then
			description = descriptionDe
		else
			description = description .. '{{de|1=' .. descriptionDe .. '}}'
		end
		existDescription = true
	end
	if MediaWikiUtils.isStringFilled(descriptionAdditional) then
		if existDescription then
			description = description .. '\n' -- Newline
		end
		description = description .. descriptionAdditional
		existDescription = true
	end
	if existDescription == false and exportFields.info_template == 'Information' then
		description = '<!-- A description is required. -->'
	end
	exportFields.description = description

	-- Field "templates"
	-- Needs to be handled before field "location"
	exportFields.templates = ''
	local templates = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'templates') or ''
	local additionalTemplates = propertyTable.info_templates
	if MediaWikiUtils.isStringFilled(templates) then
		if MediaWikiUtils.isStringEmpty(additionalTemplates) then
			exportFields.templates = templates
		else
			exportFields.templates = templates .. '\n' .. additionalTemplates
		end
	else
		if MediaWikiUtils.isStringFilled(additionalTemplates) then
			exportFields.templates = additionalTemplates
		-- else
			-- "templates" and "additionalTemplates" are empty, an empty line ('\n') replaces "${templates}".
		end
	end

	-- Field "location"
	-- Needs to be handled after field "templates" because it will precede templates
	local gps = photo:getRawMetadata('gps')
	local LrMajorVersion = LrApplication.versionTable().major -- number type
	local LrVersionString = LrApplication.versionString() -- string with major, minor and revison numbers
	local subText = LOC "$$$/LrMediaWiki/Interface/MessageByLrMediaWiki=Message by LrMediaWiki"
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
				local hintLine1 = LOC ("$$$/LrMediaWiki/Interface/HintHeadingTrueL1=Hint: The Lightroom field ^[Direction^] has a value of ^1^D.", headingRounded) -- ^D is a degree symbol
				local hintLine2 = LOC ("$$$/LrMediaWiki/Interface/HintHeadingTrueL2=This value has been used to set the ^[heading^] parameter at {{Location}} template.")
				local hintLine3 = LOC ("$$$/LrMediaWiki/Interface/HintHeadingTrueL3=This feature requires a Lightroom version 6/CC or higher.")
				local hintLine4 = LOC ("$$$/LrMediaWiki/Interface/HintHeadingTrueL4=This Lightroom version is ^1, therefore this feature works.", LrVersionString)
				local hintMessage = hintLine1 .. '\n' .. hintLine2 .. '\n' .. hintLine3 .. '\n' .. hintLine4
				local messageTable = {message = hintMessage, info = subText, actionPrefKey = 'Show hint message of used LR version'}
				LrDialogs.messageWithDoNotShow(messageTable)
			end
		elseif LrMajorVersion == 5 then
			-- Newlines could be inserted in ZStrings by "^n". Whereas, splitting the message text into multiple lines, improves code readability.
			local hintLine1 = LOC ("$$$/LrMediaWiki/Interface/HintHeadingFalseL1=Hint: If the Lightroom field ^[Direction^] has a value, this can not be used to set a ^[heading^] parameter at {{Location}} template.")
			local hintLine2 = LOC ("$$$/LrMediaWiki/Interface/HintHeadingFalseL2=This feature requires a Lightroom version 6/CC or higher.")
			local hintLine3 = LOC ("$$$/LrMediaWiki/Interface/HintHeadingFalseL3=This Lightroom version is ^1, therefore this feature works not.", LrVersionString)
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
			error 'Unsupported Lightroom version' -- unlikely use case
		end
		location = location .. '}}' -- close Location template
		exportFields.location = location
		exportFields.templates = location .. '\n' .. exportFields.templates -- location precedes templates
	end

	-- Field "categories"
	exportFields.categories = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'categories') or ''

	-- Field "otherVersions"
	local otherVersions = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'otherVersions')
	if MediaWikiUtils.isStringFilled(otherVersions) then
		exportFields.otherVersions = otherVersions
	end

	-- Field "otherFields"
	local otherFields = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'otherFields')
	if MediaWikiUtils.isStringFilled(otherFields) then
		exportFields.otherFields = otherFields
	end

	-- Field "date"
	local timestamp = ''
	local dateCreated = photo:getFormattedMetadata('dateCreated')
	if MediaWikiUtils.isStringFilled(dateCreated) then
		-- If metadata set is set to "EXIF and IPTC", "IPTC" or "Location", the field
		-- "Date Created" is editable. At some cases field checks work, at other cases not.
		-- The format is "YYYY-MM-DDThh:mm:ss", according to ISO 8601.
		-- To improve human readability, "T" is replaced with a blank sign:
		dateCreated = string.gsub(dateCreated, 'T', ' ')
		timestamp = dateCreated
	end
	exportFields.date = timestamp
	local date = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'date')
	if MediaWikiUtils.isStringFilled(date) then
		exportFields.date = date
	end

	-- Fields of infobox template "Artwork":
	local artist = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'artist')
	if MediaWikiUtils.isStringFilled(artist) then
		exportFields.art.artist = artist
	end
	local author = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'author')
	if MediaWikiUtils.isStringFilled(author) then
		exportFields.art.author = author
	end
	local title = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'title')
	if MediaWikiUtils.isStringFilled(title) then
		exportFields.art.title = title
	end
	local medium = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'medium')
	if MediaWikiUtils.isStringFilled(medium) then
		exportFields.art.medium = medium
	end
	local dimensions = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'dimensions')
	if MediaWikiUtils.isStringFilled(dimensions) then
		exportFields.art.dimensions = dimensions
	end
	local institution = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'institution')
	if MediaWikiUtils.isStringFilled(institution) then
		exportFields.art.institution = institution
	end
	local department = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'department')
	if MediaWikiUtils.isStringFilled(department) then
		exportFields.art.department = department
	end
	local accessionNumber = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'accessionNumber')
	if MediaWikiUtils.isStringFilled(accessionNumber) then
		exportFields.art.accessionNumber = accessionNumber
	end
	local placeOfCreation = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'placeOfCreation')
	if MediaWikiUtils.isStringFilled(placeOfCreation) then
		exportFields.art.placeOfCreation = placeOfCreation
	end
	local placeOfDiscovery = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'placeOfDiscovery')
	if MediaWikiUtils.isStringFilled(placeOfDiscovery) then
		exportFields.art.placeOfDiscovery = placeOfDiscovery
	end
	local objectHistory = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'objectHistory')
	if MediaWikiUtils.isStringFilled(objectHistory) then
		exportFields.art.objectHistory = objectHistory
	end
	local exhibitionHistory = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'exhibitionHistory')
	if MediaWikiUtils.isStringFilled(exhibitionHistory) then
		exportFields.art.exhibitionHistory = exhibitionHistory
	end
	local creditLine = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'creditLine')
	if MediaWikiUtils.isStringFilled(creditLine) then
		exportFields.art.creditLine = creditLine
	end
	local inscriptions = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'inscriptions')
	if MediaWikiUtils.isStringFilled(inscriptions) then
		exportFields.art.inscriptions = inscriptions
	end
	local notes = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'notes')
	if MediaWikiUtils.isStringFilled(notes) then
		exportFields.art.notes = notes
	end
	local references = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'references')
	if MediaWikiUtils.isStringFilled(references) then
		exportFields.art.references = references
	end
	local source = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'source')
	if MediaWikiUtils.isStringFilled(source) then
		exportFields.art.source = source
	end
	local wikidata = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'wikidata')
	if MediaWikiUtils.isStringFilled(wikidata) then
		exportFields.art.wikidata = wikidata
	end
	local object = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'object')
	if MediaWikiUtils.isStringFilled(object) then
		exportFields.objectPhoto.object = object
	end
	local detail = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'detail')
	if MediaWikiUtils.isStringFilled(detail) then
		exportFields.objectPhoto.detail = detail
	end
	local detailPosition = photo:getPropertyForPlugin(Info.LrToolkitIdentifier, 'detailPosition')
	if MediaWikiUtils.isStringFilled(detailPosition) then
		exportFields.objectPhoto.detailPosition = detailPosition
	end

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
	{ key = 'info_template', default = 'Information' },
	{ key = 'info_source', default = '{{own}}' },
	{ key = 'info_author', default = '' },
	{ key = 'info_license', default = '{{Cc-by-sa-4.0}}' },
	{ key = 'info_permission', default = '' },
	{ key = 'info_templates', default = '' },
	{ key = 'info_categories', default = '' },
}

return MediaWikiExportServiceProvider

--[[

[1]	According to the LR SDK 6 documentation, fonts can be specified by a table
	with keys "name" and "size" – beside specifying the font by a simple string.
	See LR 6 SDK documantaion PDF, page 95.

	In fact, it has to be done this way – we have to avoid to specify a
	a font by a simple string.

	Setting a font name by a simple string works at macOS, not at Windows.
	Therefore, this kind of naming a font has to be avoided.
	Instead, the format with the both keys "name" and "size" should be used.

	LR 6 SDK documentation mentions, the "size" property should be a string.
	This can be done at macOS without causing an error.
	But, this setting will be ignored.
	Doing the same at Windows causes an internal error:
	"bad argument #-1 to 'fontFromValue' (number expected, got string)"

	Therefore, setting a font by a simple string should be avoided.
	Instead, the font should be specified by a table with keys "name" and "size".
	The value of "size" has to be a number, not a string (as mentioned by
	the SDK documentaion).

	Obviously, it's a bug of both: the SDK and it's documentation.

	Rob Cole initiated a related thread at
	https://forums.adobe.com/message/3110373

--]]
