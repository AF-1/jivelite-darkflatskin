---- Dark Flat (Grid) Skin version (AF) ----
----   based on piCorePlayer 10.0.1   ----

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
		analogVUmeter = 'Blue_Glow',
		displayStatusIcons = true,
		displayAudioMetaData = true,
		displayYear = true,
		displayRating = true,
		displayGenre = true,
		NPscreenRating = true,
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
			end
		)
	)
	jiveMain:addItem(
		self:menuItem(
			'appletNowPlayingViewsSettings',
			'screenSettingsNowPlaying',
			'NOW_PLAYING_VIEWS',
			function(applet, ...)
				applet:npviewsSettingsShow(...)
			end
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
