---- SB Radio version ----
---- based on QVGAlandscapeSkin FW 9.0.1 ----

--[[
=head1 NAME

applets.DarkFlatSkin.DarkFlatSkinApplet - The skin for the Squeezebox Controller

=head1 DESCRIPTION

This applet implements the skin for the Squeezebox Controller

=head1 FUNCTIONS

Applet related methods are described in L<jive.Applet>.

=cut
--]]

-- stuff we use
local ipairs, pairs, setmetatable, type, package, tostring = ipairs, pairs, setmetatable, type, package, tostring

local oo                     = require("loop.simple")

local Applet                 = require("jive.Applet")
local Audio                  = require("jive.ui.Audio")
local Font                   = require("jive.ui.Font")
local Framework              = require("jive.ui.Framework")
local Icon                   = require("jive.ui.Icon")
local Label                  = require("jive.ui.Label")
local RadioButton            = require("jive.ui.RadioButton")
local RadioGroup             = require("jive.ui.RadioGroup")
local SimpleMenu             = require("jive.ui.SimpleMenu")
local Surface                = require("jive.ui.Surface")
local Textarea               = require("jive.ui.Textarea")
local Tile                   = require("jive.ui.Tile")
local Window                 = require("jive.ui.Window")
local System                 = require("jive.System")

local table                  = require("jive.utils.table")
local debug                  = require("jive.utils.debug")
local autotable              = require("jive.utils.autotable")

local log                    = require("jive.utils.log").logger("applet.DarkFlatSkin")

local QVGAbaseSkinApplet     = require("applets.QVGAbaseSkin.QVGAbaseSkinApplet")

local LAYER_FRAME            = jive.ui.LAYER_FRAME
local LAYER_CONTENT_ON_STAGE = jive.ui.LAYER_CONTENT_ON_STAGE

local LAYOUT_NORTH           = jive.ui.LAYOUT_NORTH
local LAYOUT_EAST            = jive.ui.LAYOUT_EAST
local LAYOUT_SOUTH           = jive.ui.LAYOUT_SOUTH
local LAYOUT_WEST            = jive.ui.LAYOUT_WEST
local LAYOUT_CENTER          = jive.ui.LAYOUT_CENTER
local LAYOUT_NONE            = jive.ui.LAYOUT_NONE

local WH_FILL                = jive.ui.WH_FILL

local jiveMain               = jiveMain
local appletManager          = appletManager


module(..., Framework.constants)
oo.class(_M, QVGAbaseSkinApplet)

local fontpath = "applets/DarkFlatSkin/fonts/"
local FONT_NAME = "FreeSansMod"
local BOLD_PREFIX = "Bold"

function init(self)
	self.images = {}
end

function param(self)
	return {
		THUMB_SIZE = 41,
		POPUP_THUMB_SIZE = 120,
		NOWPLAYING_MENU = true,
		-- NOWPLAYING_TRACKINFO_LINES used in assisting scroll behavior animation on NP
                -- 3 is for a three line track, artist, and album (e.g., SBtouch)
                -- 2 is for a two line track, artist+album (e.g., SBradio, SBcontroller)
                NOWPLAYING_TRACKINFO_LINES = 2,
		nowPlayingScreenStyles = {
			{
				style = 'nowplaying',
				artworkSize = '320x320',
				text = self:string('LARGE_ART'),
			 },
			{
				style = 'nowplaying_small_art',
				artworkSize = '143x143',
				text = self:string('SMALL_ART'),
			},
		},
        }
end

-- skin
-- The meta arranges for this to be called to skin Jive.
function skin(self, s, reload, useDefaultSize)
	local screenWidth, screenHeight = Framework:getScreenSize()
	local imgpath = 'applets/DarkFlatSkin/images/'
	local baseImgpath = 'applets/QVGAbaseSkin/images/'

	if useDefaultSize or screenWidth < 320 or screenHeight < 240 then
		screenWidth = 320
		screenHeight = 240
	end

	Framework:setVideoMode(screenWidth, screenHeight, 16, jiveMain:isFullscreen())

	--init lastInputType so selected item style is not shown on skin load
	Framework.mostRecentInputType = "scroll"

	-- almost all styles come directly from QVGAbaseSkinApplet
	QVGAbaseSkinApplet.skin(self, s, reload, useDefaultSize)

	-- c is for constants
	local c = s.CONSTANTS

	-- styles specific to the landscape QVGA skin
	s.img.scrollBackground =
		Tile:loadVTiles({
							imgpath .. "Scroll_Bar/scrollbar_bkgrd_t.png",
							imgpath .. "Scroll_Bar/scrollbar_bkgrd.png",
							imgpath .. "Scroll_Bar/scrollbar_bkgrd_b.png",
						})

	s.img.scrollBar =
		Tile:loadVTiles({
							imgpath .. "Scroll_Bar/scrollbar_body_t.png",
							imgpath .. "Scroll_Bar/scrollbar_body.png",
							imgpath .. "Scroll_Bar/scrollbar_body_b.png",
					   })

	s.scrollbar = {
			w          = 20,
	h          = c.LANDSCAPE_LINE_ITEM_HEIGHT * 4 - 8,
			border     = { 0, 4, 0, 0},  -- bug in jive_menu, makes it so bottom and right values are ignored
			horizontal = 0,
			bgImg      = s.img.scrollBackground,
			img        = s.img.scrollBar,
			layer      = LAYER_CONTENT_ON_STAGE,
	}

	s.img.progressBackground = Tile:loadImage(imgpath .. "Alerts/alert_progress_bar_bkgrd.png")
	s.img.progressBar = Tile:loadHTiles({
                nil,
                imgpath .. "Alerts/alert_progress_bar_body.png",
        })

	s.track_list.menu.scrollbar = _uses(s.scrollbar, {
		h = 41 * 4 - 8,
	})

	-- specific to  Dark Flat Skin
	s.selected.item_choice = _uses(s.selected.item, {
		radio = {
        		img_on = Tile:loadImage(imgpath .. "Icons/radiobutton_on_sel.png"),
				padding = { 0, 10, 0, 0 },
		},
		checkbox = {
        		img_on = Tile:loadImage(imgpath .. "Icons/checkbox_on_sel.png"),
		},
	})
	s.checkbox.img_on = Tile:loadImage(imgpath .. "Icons/checkbox_on.png")
	s.radio.img_on = Tile:loadImage(imgpath .. "Icons/radiobutton_on.png")
	s.img.textinputEnterImg = Tile:loadImage(imgpath .. "Icons/selection_right_textentry.png")
	s.textinput.enterImg = s.img.textinputEnterImg

	s.img.multiLineSelectionBox =
		Tile:loadHTiles({
					nil,
				       imgpath .. "Menu_Lists/menu_sel_box_82.png",
				       imgpath .. "Menu_Lists/menu_sel_box_82_r.png",
			       })
	s.multiline_text_list.menu.selected.item.bgImg = s.img.multiLineSelectionBox

	s.img.timeInputSelectionBox = Tile:loadImage(imgpath .. "Menu_Lists/menu_box_36.png")
	s.input_time_12h.hour.selected.item.bgImg = s.img.timeInputSelectionBox

	s.img.oneLineItemSelectionBox =
		Tile:loadHTiles({
					nil,
				       imgpath .. "Menu_Lists/menu_sel_box.png",
				       imgpath .. "Menu_Lists/menu_sel_box_r.png",
			       })

	s.selected.item.bgImg = s.img.oneLineItemSelectionBox
	s.selected.item_info.bgImg = s.img.oneLineItemSelectionBox
	s.icon_list.menu.selected.item.bgImg = s.img.oneLineItemSelectionBox
	s.play_list.menu.selected.item.bgImg = s.img.oneLineItemSelectionBox

	s.img.contextMenuSelectionBox =
		Tile:loadTiles({
		imgpath .. "Popup_Menu/button_cm.png",
		nil,
		nil,
		nil,
		imgpath .. "Popup_Menu/button_cm_r.png",
		nil,
		nil,
		nil,
		imgpath .. "Popup_Menu/button_cm_l.png",
		})

	s.context_menu.menu.selected.item.bgImg = s.img.contextMenuSelectionBox
	s.context_menu.menu.locked.item.bgImg = s.img.contextMenuSelectionBox
	s.alarm_popup.menu.selected.item.bgImg = s.img.contextMenuSelectionBox

	-- software update window
	s.update_popup = _uses(s.popup)

	s.update_popup.text = {
			w = WH_FILL,
			h = (c.POPUP_TEXT_SIZE_1 + 8 ) * 2,
			position = LAYOUT_NORTH,
			border = { 0, 14, 0, 0 },
			padding = { 12, 0, 12, 0 },
			align = "center",
			font = _font(c.POPUP_TEXT_SIZE_1),
			lineHeight = c.POPUP_TEXT_SIZE_1 + 8,
			fg = c.TEXT_COLOR,
			sh = c.TEXT_SH_COLOR,
	}

	s.update_popup.subtext = {
			w = WH_FILL,
			-- note this is a hack as the height and padding push
			-- the content out of the widget bounding box.
			h = 30,
			padding = { 0, 0, 0, 36 },
			font = _boldfont(c.UPDATE_SUBTEXT_SIZE),
			fg = c.TEXT_COLOR,
			sh = TEXT_SH_COLOR,
			align = "bottom",
			position = LAYOUT_SOUTH,
	}
	s.update_popup.progress = {
			border = { 12, 0, 12, 12 },
			--padding = { 0, 0, 0, 24 },
			position = LAYOUT_SOUTH,
			horizontal = 1,
			bgImg = s.img.progressBackground,
			img = s.img.progressBar,
	}

	local NP_ARTISTALBUM_FONT_SIZE = 18
	local NP_TRACK_FONT_SIZE = 21

	local controlHeight   = 38
	local controlWidth    = 45
	local volumeBarWidth  = 150
	local buttonPadding   = 0
	local NP_TITLE_HEIGHT = 31
	local NP_TRACKINFO_RIGHT_PADDING = 40

	local _tracklayout = {
		position = LAYOUT_NORTH,
		w = WH_FILL,
		align = "left",
		lineHeight = NP_TRACK_FONT_SIZE,
		fg = { 0xe7, 0xe7, 0xe7 },
	}

	s.nowplaying = _uses(s.window, {
		bgImg = Tile:fillColor(0x000000ff),
		title = {
			zOrder = 9,
			h = 60,
			text = {
				hidden = 1,
			},
		},
		-- Song metadata
		nptitle = {
			zOrder = 10,
			order = { 'nptrack', 'xofy' },
			position   = _tracklayout.position,
			nptrack =  {
				padding    = { 10, 10, 2, 0 },
				w          = WH_FILL,
				align      = _tracklayout.align,
				lineHeight = _tracklayout.lineHeight,
				fg         = _tracklayout.fg,
				font       = _boldfont(NP_TRACK_FONT_SIZE),
			},
			nptrack_colored =  {
				padding    = { 10, 10, 2, 0 },
				w          = WH_FILL,
				align      = _tracklayout.align,
				lineHeight = _tracklayout.lineHeight,
				fg         = { 0, 0xbe, 0xbe },
				font       = _boldfont(NP_TRACK_FONT_SIZE),
			},
			xofy = {
				padding    = { 0, 10, 10, 0 },
				position   = _tracklayout.position,
				w          = 50,
				align      = 'right',
				fg         = _tracklayout.fg,
				font       = _font(14),
			},
			xofySmall = {
				padding    = { 0, 10, 10, 0 },
				position   = _tracklayout.position,
				w          = 50,
				align      = 'right',
				fg         = _tracklayout.fg,
				font       = _font(10),
			},
		},
		npartistalbum  = {
			zOrder = 10,
			position   = _tracklayout.position,
			w          = _tracklayout.w,
			align      = _tracklayout.align,
			lineHeight = _tracklayout.lineHeight,
			fg         = { 0xb3, 0xb3, 0xb3 },
			padding    = { 10, NP_TRACK_FONT_SIZE + 14, 10, 0 },
			font       = _font(NP_ARTISTALBUM_FONT_SIZE),
		},
		nptrack       = { hidden = 1},
		npalbumgroup  = { hidden = 1},
		npartistgroup = { hidden = 1},
		npalbum       = { hidden = 1},
		npartist      = { hidden = 1},
		npvisu        = { hidden = 1},

		-- cover art
		npartwork = {
			position = LAYOUT_NORTH,
			w = WH_FILL,
			align = "center",
			artwork = {
				zOrder = 1,
				w = WH_FILL,
				align = "center",
				img = false,
			},
		},
		npratinggroup = {
			zOrder = 10,
			position = LAYOUT_NORTH,
			align = "left",
			x = 108,
			y = 190,
			padding = { 0, 0, 0, 0 },
			h          = 18,
			w			= WH_FILL,

			nprating = {
				w          = 105,
				align 	   = "left",
				img 	   = false,

			},
			ratingLevel10	= {	w			 = 105,
								padding = { 40, 0, 0, 0 },
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_10.png")},
			ratingLevel20	= {	w			 = 105,
								padding = { 40, 0, 0, 0 },
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_20.png")},
			ratingLevel30	= {	w			 = 105,
								padding = { 30, 0, 0, 0 },
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_30.png")},
			ratingLevel40	= {	w			 = 105,
								padding = { 30, 0, 0, 0 },
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_40.png")},
			ratingLevel50	= {	w			 = 105,
								padding = { 20, 0, 0, 0 },
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_50.png")},
			ratingLevel60	= {	w			 = 105,
								padding = { 20, 0, 0, 0 },
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_60.png")},
			ratingLevel70	= {	w			 = 105,
								padding = { 10, 0, 0, 0 },
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_70.png")},
			ratingLevel80	= {	w			 = 105,
								padding = { 10, 0, 0, 0 },
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_80.png")},
			ratingLevel90	= {	w			 = 105,
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_90.png")},
			ratingLevel100	= {	w			 = 105,
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_100.png")},
		},

		--transport controls
		npcontrols = { hidden = 1 },

		-- Progress bar
		npprogress = {
			zOrder = 10,
			position = LAYOUT_NORTH,
			padding = { 0, 0, 0, 0 },
			border = { 0, 59, 0, 0 },
			w = WH_FILL,
			order = { "slider" },
			npprogressB = {
				w = screenWidth,
				align = 'center',
				horizontal = 1,
				bgImg = s.img.songProgressBackground,
				img = s.img.songProgressBar,
				h = 15,
				padding = { 0, 0, 0, 15 },
			}
		},

		-- special style for when there shouldn't be a progress bar (e.g., internet radio streams)
		npprogressNB = {
			hidden = 1,
		},
	})

	s.nowplaying.npprogress.npprogressB_disabled = _uses(s.nowplaying.npprogress.npprogressB)

	--FIXME: Bug 15030, need way to cycle through NP views on Baby/Controller
	s.nowplaying_small_art = _uses(s.nowplaying, {
		title = {
			h = 60,
		},
		bgImg = false,
		npartwork = {
			position = LAYOUT_NORTH,
			artwork = {
				padding = { 0, 66, 0, 0 },
			},
		},
		npaudiometagroup = {
			zOrder = 10,
			order = { 'npaudiometa' },
			position = LAYOUT_NONE,
			border = {0,0,0,0},
			x = -screenWidth/2 + 44,
			y = 106,
			padding = { 0, 0, 0, 0 },
			h          = 18,
			w			= WH_FILL,
			npaudiometa =  {
				w          = WH_FILL,
				h          = 18,
				align      = "center",
				lineHeight = 18,
				fg         = { 0x87, 0x87, 0x87 },
				font       = _font(14),
			},
		},
		npaudiometagroupyearonly = {
			zOrder = 10,
			order = { 'npaudiometa' },
			position = LAYOUT_NONE,
			border = {0,0,0,0},
			x = -screenWidth/2 + 44,
			y = 79,
			padding = { 0, 0, 0, 0 },
			h          = 18,
			w			= WH_FILL,
			npaudiometa =  {
				w          = WH_FILL,
				h          = 18,
				align      = "center",
				lineHeight = 18,
				fg         = { 0x87, 0x87, 0x87 },
				font       = _font(14),
			},
		},
		npratinggroup = {
			zOrder = 10,
			position = LAYOUT_NORTH,
			align = "top",
			x = 268,
			y = 87,
			padding = { 0, 0, 0, 0 },
			h           = 155,
			w			= 18,

			nprating = {
				w          = 18,
				align 	   = "top",
				img 	   = false,

			},
			ratingLevel10	= {	w			 = 18,
								padding = { 0, 40, 0, 0 },
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_10_vertical.png")},
			ratingLevel20	= {	w			 = 18,
								padding = { 0, 40, 0, 0 },
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_20_vertical.png")},
			ratingLevel30	= {	w			 = 18,
								padding = { 0, 30, 0, 0 },
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_30_vertical.png")},
			ratingLevel40	= {	w			 = 18,
								padding = { 0, 30, 0, 0 },
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_40_vertical.png")},
			ratingLevel50	= {	w			 = 18,
								padding = { 0, 20, 0, 0 },
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_50_vertical.png")},
			ratingLevel60	= {	w			 = 18,
								padding = { 0, 20, 0, 0 },
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_60_vertical.png")},
			ratingLevel70	= {	w			 = 18,
								padding = { 0, 10, 0, 0 },
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_70_vertical.png")},
			ratingLevel80	= {	w			 = 18,
								padding = { 0, 10, 0, 0 },
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_80_vertical.png")},
			ratingLevel90	= {	w			 = 18,
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_90_vertical.png")},
			ratingLevel100	= {	w			 = 18,
								img = Tile:loadImage(imgpath .. "NowPlaying/stars_100_vertical.png")},
		},
		npstatusicongroupnorth = {
			order = { 'npstatuscsst', 'npstatusremote' },
			position = LAYOUT_NORTH,
			align = "top",
			x = 20,
			y = 167,
			padding = { 0, 0, 0, 0 },
			h = 18,

			npstatusremote = {
				w = 28,
				img = false,
			},
			isremote_0	= {	w = 28,
						img = Tile:loadImage(imgpath .. "NowPlaying/remote_0.png")},
			isremote_1	= {	w = 28,
						img = Tile:loadImage(imgpath .. "NowPlaying/remote_1.png")},
			isspotify = { w = 28,
						img = Tile:loadImage(imgpath .. "NowPlaying/service_spotify.png")},
			isdeezer = { w = 28,
						img = Tile:loadImage(imgpath .. "NowPlaying/service_deezer.png")},
			istidal = { w = 28,
						img = Tile:loadImage(imgpath .. "NowPlaying/service_tidal.png")},
			isqobuz = { w = 28,
						img = Tile:loadImage(imgpath .. "NowPlaying/service_qobuz.png")},

			npstatuscsst = {
				w = 28,
				img = false,
			},
			hascsst_0 = {	w = 24,
							img = Tile:loadImage(imgpath .. "NowPlaying/csst_0.png")},
			hascsst_1 = {	w = 24,
							img = Tile:loadImage(imgpath .. "NowPlaying/csst_1.png")},
		},
		npstatusicongroupnorthyearonly = {
			order = { 'npstatuscsst', 'npstatusremote' },
			position = LAYOUT_NORTH,
			align = "top",
			x = 20,
			y = 162,
			padding = { 0, 0, 0, 0 },
			h = 18,

			npstatusremote = {
				w = 28,
				img = false,
			},
			isremote_0	= {	w = 28,
						img = Tile:loadImage(imgpath .. "NowPlaying/remote_0.png")},
			isremote_1	= {	w = 28,
						img = Tile:loadImage(imgpath .. "NowPlaying/remote_1.png")},
			isspotify = { w = 28,
						img = Tile:loadImage(imgpath .. "NowPlaying/service_spotify.png")},
			isdeezer = { w = 28,
						img = Tile:loadImage(imgpath .. "NowPlaying/service_deezer.png")},
			istidal = { w = 28,
						img = Tile:loadImage(imgpath .. "NowPlaying/service_tidal.png")},
			isqobuz = { w = 28,
						img = Tile:loadImage(imgpath .. "NowPlaying/service_qobuz.png")},

			npstatuscsst = {
				w = 28,
				img = false,
			},
			hascsst_0 = {	w = 24,
							img = Tile:loadImage(imgpath .. "NowPlaying/csst_0.png")},
			hascsst_1 = {	w = 24,
							img = Tile:loadImage(imgpath .. "NowPlaying/csst_1.png")},
		},
		npstatusicongroupsouth = {
			order = { 'npstatuslossless', 'npstatuslyrics' },
			position = LAYOUT_NORTH,
			align = "top",
			x = 20,
			y = 190,
			padding = { 0, 0, 0, 0 },
			h           = 18,

			npstatuslossless = {
				w		= 30,
				img		= false,
			},
			islossless_0 = { w = 30,
							img = Tile:loadImage(imgpath .. "NowPlaying/hq_0.png")},
			islossless_1 = { w = 30,
							img = Tile:loadImage(imgpath .. "NowPlaying/hq_1.png")},

			npstatuslyrics = {
				w		= 24,
				img		= false,
			},
			haslyrics_0	= {	w = 24,
							img = Tile:loadImage(imgpath .. "NowPlaying/lyrics_0.png")},
			haslyrics_1	= {	w = 24,
							img = Tile:loadImage(imgpath .. "NowPlaying/lyrics_1.png")},

		},
		npstatusicongroupsouthyearonly = {
			order = { 'npstatuslossless', 'npstatuslyrics' },
			position = LAYOUT_NORTH,
			align = "top",
			x = 20,
			y = 185,
			padding = { 0, 0, 0, 0 },
			h           = 18,

			npstatuslossless = {
				w		= 30,
				img		= false,
			},
			islossless_0 = { w = 30,
							img = Tile:loadImage(imgpath .. "NowPlaying/hq_0.png")},
			islossless_1 = { w = 30,
							img = Tile:loadImage(imgpath .. "NowPlaying/hq_1.png")},

			npstatuslyrics = {
				w		= 24,
				img		= false,
			},
			haslyrics_0	= {	w = 24,
							img = Tile:loadImage(imgpath .. "NowPlaying/lyrics_0.png")},
			haslyrics_1	= {	w = 24,
							img = Tile:loadImage(imgpath .. "NowPlaying/lyrics_1.png")},

		},
	})
	s.nowplaying.pressed = s.nowplaying
	s.nowplaying_small_art.pressed = s.nowplaying_small_art

	-- line in window is the same as nowplaying but with transparent background
	s.linein = _uses(s.nowplaying, {
		bgImg = false,
	})

	-- sliders
	s.npvolumeB = { hidden = 1 }
	s.npvolumeB_disabled = { hidden = 1 }

	s.icon_photo_loading = _uses(s._icon, {
		img = _loadImage(self, "Icons/image_viewer_loading.png"),
		padding = { 5, 5, 0, 5 }
	})

end

function free(self)
	local desktop = not System:isHardware()
	if desktop then
		log:warn("reload parent")

		package.loaded["applets.QVGAbaseSkin.QVGAbaseSkinApplet"] = nil
		QVGAbaseSkinApplet     = require("applets.QVGAbaseSkin.QVGAbaseSkinApplet")
	end
	return true
end

--[[

=head1 LICENSE

Copyright 2010 Logitech. All Rights Reserved.

This file is licensed under BSD. Please see the LICENSE file for details.

=cut
--]]
