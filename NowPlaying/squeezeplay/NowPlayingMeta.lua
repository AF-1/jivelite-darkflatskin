---- Dark Flat Skin version (AF) ----
----   based on SqueezePlay 8.4.1r1474   ----

local oo = require("loop.simple")
local AppletMeta = require("jive.AppletMeta")

local appletManager = appletManager
local jiveMain = jiveMain

module(...)
oo.class(_M, AppletMeta)

function jiveVersion(self)
	return 1, 1
end

function defaultSettings(self)
	return {
		scrollText = true,
		scrollTextOnce = false,
		coloredTrackTitleKeyword = '',
		views = {},
		doubleClickMode = false,
		doubleClickInterval = 500,
		analogVUmeter = 'Blue_Glow',
		displayStatusIcons = true,
		displayAudioMetaData = true,
		displayYear = true,
		displayRating = true,
		screenRating = true,
	}
end

function registerApplet(self)
	jiveMain:addItem(
		self:menuItem(
			'appletNowPlayingScrollMode',
			'screenSettingsNowPlaying',
			'SCREENSAVER_SCROLLMODE',
			function(applet, ...)
				applet:scrollSettingsShow(...)
			end,
			2
		)
	)
	jiveMain:addItem(
		self:menuItem(
			'appletNowPlayingViewsSettings',
			'screenSettingsNowPlaying',
			'NOW_PLAYING_VIEWS',
			function(applet, ...)
				applet:npviewsSettingsShow(...)
			end,
			1
		)
	)
	jiveMain:addItem(
		self:menuItem(
			'appletNowPlayingClickMode',
			'screenSettingsNowPlaying',
			'NOW_PLAYING_CLICK_MODE',
			function(applet, ...)
				applet:clickModeSettingsShow(...)
			end,
			3
		)
	)
	jiveMain:addItem(
		self:menuItem(
			'appletNowPlayingClickInterval',
			'screenSettingsNowPlaying',
			'NOW_PLAYING_CLICK_INTERVAL',
			function(applet, ...)
				applet:clickIntervalSettingsShow(...)
			end,
			4
		)
	)
	jiveMain:addItem(
		self:menuItem(
			'appletNowPlayingColoredTrackTitleCommentsKeyWord',
			'screenSettingsNowPlaying',
			'NOW_PLAYING_COLOREDTRACKTITLE_KEYWORD',
			function(applet, ...)
				applet:coloredTrackTitleCommentsKeywordSettingsShow(...)
			end
		)
	)
	jiveMain:addItem(
		self:menuItem(
			'appletNowPlayingScreenRating',
			'screenSettingsNowPlaying',
			'NOW_PLAYING_NPSCREEN_RATING',
			function(applet, ...)
				applet:NPscreenRatingSettingsShow(...)
			 end
		)
	)
	jiveMain:addItem(
		self:menuItem(
			'appletNowPlayingDisplayMoreTrackInfo',
			'screenSettingsNowPlaying',
			'NOW_PLAYING_DISPLAY_MORE_TRACKINFO',
			function(applet, ...)
				applet:displayMoreTrackInfoSettingsShow(...)
			end
		)
	)
	jiveMain:addItem(
		self:menuItem(
			'appletNowPlayingVUMeterSelection',
			'screenSettingsNowPlaying',
			'NOW_PLAYING_SELECT_VUMETER',
			function(applet, ...)
				applet:npVUMeterSelectionShow(...)
			end
		)
	)
	self:registerService('goNowPlaying')
	self:registerService("hideNowPlaying")
end

function configureApplet(self)
	appletManager:callService("addScreenSaver",
		self:string("SCREENSAVER_NOWPLAYING"),
		"NowPlaying",
		"openScreensaver",
		_,
		_,
		10,
		nil,
		nil,
		nil,
		{"whenOff"}
	)

	-- NowPlaying is a resident applet
	appletManager:loadApplet("NowPlaying")
end
