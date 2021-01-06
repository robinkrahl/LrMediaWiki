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
  propertyTable.create_snapshots = MediaWikiUtils.getCreateSnapshots()
  propertyTable.export_keyword = MediaWikiUtils.getExportKeyword()
  propertyTable.check_version = MediaWikiUtils.getCheckVersion()
  propertyTable.location_template = MediaWikiUtils.getLocationTemplate()
  propertyTable.logging = MediaWikiUtils.getLogging()
  propertyTable.preview_wikitext_font_name = MediaWikiUtils.getPreviewWikitextFontName()
  propertyTable.preview_wikitext_font_size = MediaWikiUtils.getPreviewWikitextFontSize()
end

MediaWikiPluginInfoProvider.endDialog = function(propertyTable)
  MediaWikiUtils.setCreateSnapshots(propertyTable.create_snapshots)
  MediaWikiUtils.setExportKeyword(propertyTable.export_keyword)
  MediaWikiUtils.setCheckVersion(propertyTable.check_version)
  MediaWikiUtils.setLocationTemplate(propertyTable.location_template)
  MediaWikiUtils.setLogging(propertyTable.logging)
  MediaWikiUtils.setPreviewWikitextFontName(propertyTable.preview_wikitext_font_name)
  MediaWikiUtils.setPreviewWikitextFontSize(propertyTable.preview_wikitext_font_size)
end

MediaWikiPluginInfoProvider.sectionsForTopOfDialog = function(viewFactory, propertyTable)
	local labelAlignment = 'right'

	local exportKeywordTooltip = LOC "$$$/LrMediaWiki/Section/Config/ExportKeywordTooltip=If set, this keyword is added after successful export."
	local fontNameTooltip = LOC "$$$/LrMediaWiki/Section/Config/Preview/FontNameTooltip=Font name of generated wikitext"
	local fontSizeTooltip = LOC "$$$/LrMediaWiki/Section/Config/Preview/FontSizeTooltip=Font size of generated wikitext"

	return {
		{
			title = LOC "$$$/LrMediaWiki/Section/Config/Title=LrMediaWiki Configuration",
			synopsis = bind 'preview_wikitext_font_name',
			bind_to_object = propertyTable,

			viewFactory:row {
				spacing = viewFactory:control_spacing(),

				viewFactory:static_text {
					title = LOC "$$$/LrMediaWiki/Section/Config/Preview/FontName=Font Name of Preview" .. ':',
					width = LrView.share 'label_width',
					alignment = labelAlignment,
					tooltip = fontNameTooltip,
				},
				viewFactory:combo_box {
					value = bind 'preview_wikitext_font_name',
					width = 222,
					immediate = true,
					items = { -- see [1]
						'Courier', -- Mac, monospace
						'Courier New', -- Win & Mac, monospace
						'Lucida Console', -- Win, monospace
						'Monaco', -- Mac, monospace
						'<system>', -- LR SDK
						'<system/bold>', -- LR SDK
					},
					tooltip = fontNameTooltip,
				},

				viewFactory:static_text {
					title = LOC "$$$/LrMediaWiki/Section/Config/Preview/FontSize=Font Size" .. ':',
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
						'10',
						'12',
						'14',
						'16',
						'18',
						'20',
					},
					tooltip = fontSizeTooltip,
				},
			},

			viewFactory:row {
				spacing = viewFactory:control_spacing(),
				viewFactory:static_text {
					width = LrView.share 'label_width',
					title = LOC "$$$/LrMediaWiki/Section/Config/ExportKeyword=Export Keyword" .. ':',
					alignment = labelAlignment,
					tooltip = exportKeywordTooltip,
				},

				viewFactory:edit_field {
					value = bind 'export_keyword',
					immediate = true,
					width = 222,
					-- fill_horizontal = 1,
					tooltip = exportKeywordTooltip,
				},
			},

			viewFactory:row {
				viewFactory:checkbox {
					value = bind 'create_snapshots',
					title = LOC "$$$/LrMediaWiki/Section/Config/Snapshots=Create snapshots on export",
					tooltip = LOC "$$$/LrMediaWiki/Section/Config/SnapshotsTooltip=If set, a snapshot is created after successful export.",
				},
			},

			viewFactory:row {
				viewFactory:checkbox {
					value = bind 'check_version',
					title = LOC "$$$/LrMediaWiki/Section/Config/Version=Check for new plug-in version after Lightroom starts",
					tooltip = LOC "$$$/LrMediaWiki/Section/Config/VersionTooltip=If set, a call to GitHub is performed to determine the latest version number, which is then compared to the installed version.",
				},
			},

			viewFactory:row {
				viewFactory:checkbox {
					value = bind 'location_template',
					title = LOC "$$$/LrMediaWiki/Section/Config/LocationTemplate=Enable {{Location}} template",
					tooltip = LOC "$$$/LrMediaWiki/Section/Config/LocationTemplateTooltip=Enables the creation of a {{Location}} template on base of GPS data",
				},
			},

			viewFactory:separator {
				fill_horizontal = 1,
			},

			viewFactory:row {
				viewFactory:checkbox {
					value = bind 'logging',
					title = LOC "$$$/LrMediaWiki/Section/Config/Logging=Enable logging",
				},
			},

			viewFactory:row {
				viewFactory:static_text {
					title = LOC "$$$/LrMediaWiki/Section/Config/Logging/Description=If logging is enabled, all API requests are logged to “Documents/LrMediaWikiLogger.log”.",
					wrap = true,
				},
			},

			viewFactory:row {
				viewFactory:static_text {
					title = LOC "$$$/LrMediaWiki/Section/Config/Logging/Warning=Warning" .. ':',
					font = '<system/bold>',
				},

				viewFactory:static_text {
					title = LOC "$$$/LrMediaWiki/Section/Config/Logging/Password=The log file contains your password!",
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
