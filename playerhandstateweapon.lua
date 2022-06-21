--[[
	PlayerHandStateWeapon

	If view rotation is enabled, move gadget and firemode selectors
	Enable toggling gripping the weapon
	Update hand positions properly, using passed-in rotations for smoothness reasons
--]]

-- When rotation is enabled, show the hints for the gadget/firemode when the
-- thumbstick is in the correct direction
Hooks:PostHook(PlayerHandStateWeapon, "update", "VRPlusApplyWeaponThumbstickHints", function(self, t, dt)
	-- If turning is disabled, don't affect the mappings.
	if VRPlusMod._data.turning_mode == VRPlusMod.C.TURNING_OFF then return end

	local touch_limit = 0.3

	local controller = managers.vr:hand_state_machine():controller()
	local axis = controller:get_input_axis("touchpad_primary")

	if axis.y < -touch_limit then
		managers.hud:show_controller_assist("hud_vr_controller_firemode")
	elseif touch_limit < axis.y then
		managers.hud:show_controller_assist("hud_vr_controller_gadget")
	elseif axis.x < -touch_limit and self._can_switch_weapon_hand then
		managers.hud:show_controller_assist("hud_vr_controller_weapon_hand_switch")
	else
		managers.hud:hide_controller_assist()
	end
end)

-- Copypasted function from regular game
-- Changed to fix a crash
-- If nothing else, this will give clearer crash logs
function PlayerHandStateWeapon:at_enter(prev_state)
	PlayerHandStateWeapon.super.at_enter(self, prev_state)

	local player_unit = nil
	if managers.player then
		player_unit = managers.player:player_unit()
	end

	if player_unit and alive(player_unit) then
		player_unit:hand():sync_state()

		local weapon_unit = player_unit:inventory():equipped_unit()
		self._weapon_id = alive(weapon_unit) and weapon_unit:base().name_id

		self:_link_weapon(weapon_unit)
		player_unit:inventory():add_listener("PlayerHandStateWeapon_" .. tostring(self:hsm():hand_id()), nil, callback(self, self, "inventory_changed"))
	end

	if managers.hud then
		managers.hud:link_ammo_hud(self._hand_unit, self:hsm():hand_id())
		managers.hud:ammo_panel():set_visible(true)
	end
	
	self._hand_unit:melee():set_weapon_unit(self._weapon_unit)

	self._weapon_length = nil

	self:hsm():enter_controller_state("weapon")
	self:hsm():other_hand():enter_controller_state("empty")

	self._default_assist_tweak = {
		pistol_grip = true,
		grip = "idle_wpn",
		position = Vector3(0, 5, -5)
	}
	self._pistol_grip = false
	self._assist_position = nil
	self._grip_toggle = nil

	if alive(self._weapon_unit) or self._is_bow then
		local sequence = self._sequence
		local tweak = self._is_bow and tweak_data.vr:get_offset_by_id("bow", self._weapon_id) or tweak_data.vr:get_offset_by_id(self._weapon_id)

		if tweak.grip then
			sequence = tweak.grip
		end

		if self._hand_unit and sequence and self._hand_unit:damage():has_sequence(sequence) then
			self._hand_unit:damage():run_sequence_simple(sequence)
		end
	end
end
