local hb = VRPlusMod.HUD_BELT

Hooks:PreHook(VRBeltCustomization, "save_grid", "VRPlusCustomBeltItemSaving", function(self)
	local belt_layout = managers.vr:get_setting("belt_layout")
	hb:adjust_position_size_table(self._belt, belt_layout, hb.POSITION)

	local belt_box_sizes = managers.vr:get_setting("belt_box_sizes")
	hb:adjust_position_size_table(self._belt, belt_box_sizes, hb.SIZE)
end)
