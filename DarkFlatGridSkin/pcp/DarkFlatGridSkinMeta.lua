--[[
=head1 NAME

applets.DarkFlatGridSkin.DarkFlatGridSkinMeta

=head1 DESCRIPTION

See L<applets.DarkFlatGridSkin.DarkFlatGridSkinApplet>.

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
	return {}
end

function registerApplet(self)
	jiveMain:addItem(
		self:menuItem(
			'appletDarkFlatGridSkin',
			'screenSettings',
			'DARK_FLAT_GRID_SKIN_SETTINGS',
			function(applet, ...)
				applet:gridSettingsShow(...)
			end
		)
	)
	jiveMain:registerSkin(self:string("DARK_FLAT_GRID_SKIN"), "DarkFlatGridSkin", "skin", "DarkFlatGridSkin")
end

--[[
=head1 LICENSE

Copyright 2010 Logitech. All Rights Reserved.

This file is licensed under BSD. Please see the LICENSE file for details.

=cut
--]]
