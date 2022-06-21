-- Copypasted function from regular game
-- Changed to fix a crash
-- If nothing else, this will give clearer crash logs
function PlayerHandStateAkimbo:at_enter(prev_state)
	PlayerHandStateAkimbo.super.at_enter(self, prev_state)

	-- Added extra "if managers.player" check
	if managers.player and alive(managers.player:player_unit()) then
		local equipped_weapon = managers.player:player_unit():inventory():equipped_unit()

		if alive(equipped_weapon) and equipped_weapon:base().akimbo then
			self:_link_weapon(equipped_weapon:base()._second_gun)
		else
			self:hsm():set_default_state("idle")

			return
		end
	end

	self._hand_unit:melee():set_weapon_unit(self._weapon_unit)
	self:hsm():enter_controller_state("empty")
	self:hsm():enter_controller_state("akimbo")

	local sequence = self._sequence
	local tweak = tweak_data.vr:get_offset_by_id(self._weapon_unit:base().name_id)

	if tweak.grip then
		sequence = tweak.grip
	end

	if self._hand_unit and sequence and self._hand_unit:damage():has_sequence(sequence) then
		self._hand_unit:damage():run_sequence_simple(sequence)
	end
end