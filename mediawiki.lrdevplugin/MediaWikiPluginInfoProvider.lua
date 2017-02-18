-- This file is part of the LrMediaWiki project and distributed under the terms
-- of the MIT license (see LICENSE.txt file in the project root directory or
-- [0]).  See [1] for more information about LrMediaWiki.
--
-- Copyright (C) 2015 by the LrMediaWiki team (see CREDITS.txt file in the
-- project root directory or [2])
--
-- [0]  <https://raw.githubusercontent.com/robinkrahl/LrMediaWiki/master/LICENSE.txt>
-- [1]  <https://commons.wikimedia.org/wiki/Commons:LrMediaWiki>
-- [2]  <https://raw.githubusercontent.com/robinkrahl/LrMediaWiki/master/CREDITS.txt>

-- Code status:
-- doc:   missing
-- i18n:  complete

local LrView = import 'LrView'

local MediaWikiUtils = require 'MediaWikiUtils'

local bind = LrView.bind

local MediaWikiPluginInfoProvider = {}

MediaWikiPluginInfoProvider.startDialog = function(propertyTable)
  propertyTable.logging = MediaWikiUtils.getLogging()
  propertyTable.create_snapshots = MediaWikiUtils.getCreateSnapshots()
  propertyTable.check_version = MediaWikiUtils.getCheckVersion()
  propertyTable.export_keyword = MediaWikiUtils.getExportKeyword()
  propertyTable.preview_wikitext_font_name = MediaWikiUtils.getPreviewWikitextFontName()
  propertyTable.preview_wikitext_font_size = MediaWikiUtils.getPreviewWikitextFontSize()
end

MediaWikiPluginInfoProvider.endDialog = function(propertyTable)
  MediaWikiUtils.setLogging(propertyTable.logging)
  MediaWikiUtils.setCreateSnapshots(propertyTable.create_snapshots)
  MediaWikiUtils.setCheckVersion(propertyTable.check_version)
  MediaWikiUtils.setExportKeyword(propertyTable.export_keyword)
  MediaWikiUtils.setPreviewWikitextFontName(propertyTable.preview_wikitext_font_name)
  MediaWikiUtils.setPreviewWikitextFontSize(propertyTable.preview_wikitext_font_size)
end

local fontNameTooltip = LOC "$$$/LrMediaWiki/Section/Config/Preview/FontNameTooltip=Font name of generated wikitext"
local fontSizeTooltip = LOC "$$$/LrMediaWiki/Section/Config/Preview/FontSizeTooltip=Font size of generated wikitext"

MediaWikiPluginInfoProvider.sectionsForBottomOfDialog = function(viewFactory, propertyTable)
	local labelAlignment = 'right'
	local widthLong = 50
	local labelWidth = 96 -- LrView.share 'label_width'

	return {
		{
			title = LOC "$$$/LrMediaWiki/Section/Config/Title=Configuration",
			bind_to_object = propertyTable,

			viewFactory:column {
				spacing = viewFactory:control_spacing(),

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:checkbox {
						value = bind 'create_snapshots',
						title = LOC "$$$/LrMediaWiki/Section/Config/Snapshots=Create snapshots on export",
					},
				},

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:static_text {
						alignment = labelAlignment,
						width = LrView.share "label_width",
						title = LOC "$$$/LrMediaWiki/Section/Config/ExportKeyword=Export keyword",
					},

					viewFactory:edit_field {
						value = bind 'export_keyword',
						immediate = true,
						width_in_chars = widthLong,
					},
				},

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:checkbox {
						value = bind 'check_version',
						title = LOC "$$$/LrMediaWiki/Section/Config/Version=Check for new plug-in version after Lightroom starts",
					},
				},

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:checkbox {
						value = bind 'logging',
						title = LOC "$$$/LrMediaWiki/Section/Config/Logging=Enable logging",
					},
				},

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:static_text {
						title = LOC "$$$/LrMediaWiki/Section/Config/Logging/Description=If you enable logging, all API requests are logged. The log file is located in the directory “Documents”.",
						wrap = true,
					},
				},

				viewFactory:row {
					spacing = viewFactory:label_spacing(),

					viewFactory:static_text {
						title = LOC "$$$/LrMediaWiki/Section/Config/Logging/Warning=Warning:",
						font = '<system/bold>',
					},

					viewFactory:static_text {
						title = LOC "$$$/LrMediaWiki/Section/Config/Logging/Password=The log file contains your password!",
					},
				},

				viewFactory:row {
					viewFactory:separator {
						fill_horizontal = 1, -- "1" means full width
					},
				},

				viewFactory:row {
					viewFactory:column {
							viewFactory:static_text {
								title = LOC "$$$/LrMediaWiki/Section/Config/Preview/Title=Preview",
								alignment = labelAlignment,
								width_in_chars = LrView.share 'label_width',
								font = '<system/bold>',
								tooltip = LOC "$$$/LrMediaWiki/Section/Config/Preview/TitleTooltip=Settings used at “Preview of generated wikitext”",
							},
					},
					viewFactory:column {
						spacing = viewFactory:label_spacing(),
						-- Font name
						viewFactory:row {
							viewFactory:static_text {
								title = LOC "$$$/LrMediaWiki/Section/Config/Preview/FontName=Font Name",
								alignment = labelAlignment,
								width = labelWidth,
								tooltip = fontNameTooltip,
							},
							viewFactory:combo_box {
								value = bind 'preview_wikitext_font_name',
								width_in_chars = widthLong - 30,
								immediate = true,
								items = { -- see [1]
									'Courier', -- Mac, monospace
									'Courier New', -- Win & Mac, monospace
									'Lucida Console', -- Win, monospace
									'Monaco', -- Mac, monospace
									'<system>', -- LR SDK
									'<system/small>', -- LR SDK
									'<system/bold>', -- LR SDK
									'<system/small/bold>', -- LR SDK
								},
								tooltip = fontNameTooltip,
							},
						-- Font size
							viewFactory:static_text {
								title = LOC "$$$/LrMediaWiki/Section/Config/Preview/FontSize=Font Size",
								alignment = labelAlignment,
								width = 68,
								tooltip = fontSizeTooltip,
							},
							viewFactory:combo_box {
								value = bind {
									key = 'preview_wikitext_font_size',
									transform = function(value) -- see [2]
										return tostring(value)
									end,
								},
								width_in_chars = 3,
								immediate = true,
								items = { -- values have to be strings, see [2]
									"10",
									"12",
									"14",
									"16",
									"18",
									"20",
								},
								tooltip = fontSizeTooltip,
							},
						},
					},
				},
			},
		},
	}
end

return MediaWikiPluginInfoProvider

--[[

[1]	Available fonts depend on user's OS configuration.
	Therefore, they need to be specified free.
	The list of proposals includes 4 examples of OS monospace fonts
	and all 4 available system values provided by LR SDK.

[2]	The value is stored as float and should be shown as integer.
	At Windows it is shown as integer, but at macOS as float with two
	decimal places. To make it shown at macOS as integer, the transform
	function tostring() is used. Alternate: string.format('%d', value)
	It's a workaround of a known bug, see
	https://forums.adobe.com/message/3139286.

--]]
