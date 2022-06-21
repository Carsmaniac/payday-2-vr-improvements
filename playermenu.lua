--[[
	HUDManagerVR

	Make the laser pointer in the menu have a configurable colour, with a disco mode
--]]

-- From https://gist.github.com/GigsD4X/8513963
local function HSVToRGB( hue, saturation, value )
	-- Returns the RGB equivalent of the given HSV-defined color
	-- (adapted from some code found around the web)

	-- If it's achromatic, just return the value
	if saturation == 0 then
		return value
	end

	-- Get the hue sector
	local hue_sector = math.floor( hue / 60 )
	local hue_sector_offset = ( hue / 60 ) - hue_sector

	if hue_sector > 5 then hue_sector = 0 end

	local p = value * ( 1 - saturation );
	local q = value * ( 1 - saturation * hue_sector_offset )
	local t = value * ( 1 - saturation * ( 1 - hue_sector_offset ) )

	if hue_sector == 0 then
		return value, t, p
	elseif hue_sector == 1 then
		return q, value, p
	elseif hue_sector == 2 then
		return p, value, t
	elseif hue_sector == 3 then
		return p, q, value
	elseif hue_sector == 4 then
		return t, p, value
	elseif hue_sector == 5 then
		return value, p, q
	end
end

Hooks:PreHook(PlayerMenu, "update", "VRPlusUpdateLaserColour", function(self, t, dt)
	if not self._is_start_menu or self.__laser_is_updated then
		return
	end

	local hue = VRPlusMod._data.tweaks.laser_hue
	if VRPlusMod._data.tweaks.laser_disco then
		local speedup = 2 -- maximum of once every 0.5 seconds
		local delta = hue * hue * speedup * dt -- square hue to get a nice logrhytmic timescale
		local last = self.__laser_last_hue or 0
		hue = (last + delta) % 1
		self.__laser_last_hue = hue
	end

	-- don't constantly update if we don't need to
	self.__laser_is_updated = not VRPlusMod._data.tweaks.laser_disco

	local r, g, b = HSVToRGB(hue * 360, 1, 1)
	local colour = Color(0.15, r, g, b)
	self._brush_laser:set_color(colour)
	self._brush_laser_dot:set_color(colour)
end)
