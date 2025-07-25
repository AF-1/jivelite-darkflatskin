---- Dark Flat Skin version (AF) ----
----   based on SB Radio 9.0.1   ----

local oo            = require("loop.simple")

local AppletMeta    = require("jive.AppletMeta")

local appletManager = appletManager
local jiveMain      = jiveMain


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
		displayStatusIcons = true,
		displayAudioMetaData = true,
		displayYear = true,
		displayRating = true,
		views = {},
	}
end

function registerApplet(self)
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
			'appletNowPlayingDisplayMoreTrackInfo',
			'screenSettingsNowPlaying',
			'NOW_PLAYING_DISPLAY_MORE_TRACKINFO',
			function(applet, ...)
				applet:displayMoreTrackInfoSettingsShow(...)
			end,
			2
		)
	)
	jiveMain:addItem(
		self:menuItem(
			'appletNowPlayingColoredTrackTitleCommentsKeyWord',
			'screenSettingsNowPlaying',
			'NOW_PLAYING_COLOREDTRACKTITLE_KEYWORD',
			function(applet, ...)
				applet:coloredTrackTitleCommentsKeywordSettingsShow(...)
			end,
			3
		)
	)
	jiveMain:addItem(
		self:menuItem(
			'appletNowPlayingScrollMode',
			'screenSettingsNowPlaying',
			'SCREENSAVER_SCROLLMODE',
			function(applet, ...)
				applet:scrollSettingsShow(...)
			end,
			4
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

