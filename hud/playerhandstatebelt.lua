
Hooks:PostHook(PlayerHandStateBelt, "update", "VRPlusAddModBeltItems", function(self, t, dt)
	local item = VRPlusMod.HUD_BELT.items[self._belt_state]
	if not item then
		return
	end

	if not managers.vr:hand_state_machine():controller():get_input_pressed(self._belt_button) then
		return
	end

	if item.grabbed then
		item:grabbed(self)
	end
end)
