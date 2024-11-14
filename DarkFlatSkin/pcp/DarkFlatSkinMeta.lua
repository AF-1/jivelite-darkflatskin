----   piCorePlayer version   ----
--[[
=head1 NAME

applets.DarkFlatSkin.DarkFlatSkinMeta

=head1 DESCRIPTION

See L<applets.DarkFlatSkin.DarkFlatSkinApplet>.

=head1 FUNCTIONS

See L<jive.AppletMeta> for a description of standard applet meta functions.

=cut
--]]

local tostring, tonumber  = tostring, tonumber

local oo            = require("loop.simple")
local os            = require("os")
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
		rew = true,
		play = true,
		fwd = true,
		repeatMode = false,
		shuffleMode = false,
		volDown = true,
		volSlider = false,
		volUp = true
	}
end

function registerApplet(self)
	jiveMain:addItem(
		self:menuItem(
			'appletDarkFlatSkin',
			'screenSettings',
			'DARK_FLAT_SKIN_SETTINGS',
			function(applet, ...)
				applet:settingsShow(...)
			end
		)
	)
	self:registerService('getNowPlayingScreenButtonsDFS')
	self:registerService('setNowPlayingScreenButtonsDFS')

	jiveMain:registerSkin(self:string("DARK_FLAT_SKIN"), "DarkFlatSkin", "skin")
end

--[[

=head1 LICENSE

Copyright 2010 Logitech. All Rights Reserved.

This file is licensed under BSD. Please see the LICENSE file for details.

=cut
--]]
