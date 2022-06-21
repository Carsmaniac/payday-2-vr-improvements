-- Same as vanilla, but fixes a bug with procedural arm movement causing crashes.
function PlayerHandStateItem:at_enter(prev_state, params)
	PlayerHandStateItem.super.at_enter(self, prev_state, params)

	if not params then
		debug_pause("[PlayerHandStateItem:at_enter] Entered item state without params!")
	end

	if params.type ~= "magazine" then
		-- Problematic line, add a bunch of sanity checks
		if managers.player and managers.player:player_unit() and managers.player:player_unit().movement and managers.player:player_unit():movement() and managers.player:player_unit():movement():current_state() then
			managers.player:player_unit():movement():current_state():_interupt_action_reload()
		end
	end

	if alive(params.unit) then
		self:_link_item(params.unit, params.body, params.offset)
	end

	self._item_type = params.type
	self._controller_state = "item"

	if self._item_type == "mask" then
		for _, linked_unit in ipairs(self._item_unit:children()) do
			linked_unit:set_visible(true)
		end

		self._item_unit:set_visible(true)

		local offset = tweak_data.vr:get_offset_by_id(managers.blackmarket:equipped_mask().mask_id)

		if offset then
			self._item_unit:set_local_rotation(offset.rotation or Rotation())
			self._item_unit:set_local_position(offset.position or Vector3())
		end

		self._hand_unit:set_visible(false)

		self._controller_state = "mask"
	elseif self._item_type == "deployable" then
		self._controller_state = "equipment"

		self._hand_unit:damage():run_sequence_simple("ready")

		self._secondary_deployable = params.secondary
	elseif self._item_type == "throwable" then
		if self._dynamic_geometry then
			self._dynamic_geometry:set_visibility(true)
		end

		local offset = tweak_data.vr:get_offset_by_id(managers.blackmarket:equipped_grenade())

		if offset then
			self._item_unit:set_local_rotation(offset.rotation or Rotation())
			self._item_unit:set_local_position(offset.position or Vector3())

			local sequence = self._sequence

			if offset.grip then
				sequence = offset.grip
			end

			if self._hand_unit and sequence and self._hand_unit:damage():has_sequence(sequence) then
				self._hand_unit:damage():run_sequence_simple(sequence)
			end
		end
	end

	self:hsm():enter_controller_state(self._controller_state)

	if params.prompt then
		self:_prompt(params.prompt)
	end

	if self._item_type == "bag" or self._item_type == "deployable" or self._item_type == "throwable" then
		managers.hud:belt():set_state(self._secondary_deployable and "deployable_secondary" or self._item_type, "active")
	end

	if self._item_type == "deployable" then
		managers.hud:link_watch_prompt_as_hand(self._hand_unit, self:hsm():hand_id())
	end
end