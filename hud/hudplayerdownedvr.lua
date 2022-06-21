--[[
	HUDPlayerDownedVR

	Hide/show the armor/health wheel when the player is downed, if
	the it has been moved to the player's watch.
--]]

-- Cannot change while in-game
if not VRPlusMod._data.hud.watch_health_wheel then return end

function HUDPlayerDownedVR:hide()
	local hp = self._teammate_panels[HUDManager.PLAYER_PANEL]:panel()

	-- TODO remove when downed
	self._heist_timer_panel:hide()
end

function HUDPlayerDownedVR:show()
	self._heist_timer_panel:show()
end
