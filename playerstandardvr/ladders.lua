--[[
	PlayerStandardVR - Ladders

	Fix up ladder support
--]]

local old_check_action_ladder = PlayerStandardVR._check_action_ladder
function PlayerStandardVR:_check_action_ladder(t, input, ...)
	if not VRPlusMod._data.movement_locomotion then
		return old_check_action_ladder(self, t, input, ...)
	end

	local pos = self._ext_movement:ghost_position()

	if self._state_data.on_ladder then
		local ladder_unit = self._unit:movement():ladder_unit()

		if ladder_unit:ladder():check_end_climbing(pos, self._normal_move_dir, self._gnd_ray) then
				self:_end_action_ladder()
		end

		return
	end

	if not self._move_dir then
		return
	end

	for i = 1, math.min(Ladder.LADDERS_PER_FRAME, #Ladder.active_ladders), 1 do
		local ladder_unit = Ladder.next_ladder()

		if alive(ladder_unit) then
			local can_access = ladder_unit:ladder():can_access(pos, self._move_dir)

			if can_access then
				self:_start_action_ladder(t, ladder_unit)

				break
			end
		end
	end
end

local old_start_action_ladder = PlayerStandardVR._start_action_ladder
function PlayerStandardVR:_start_action_ladder(t, ladder_unit, ...)
	if not VRPlusMod._data.movement_locomotion then
		return old_start_action_ladder(self, t, ladder_unit, ...)
	end

	self._state_data.on_ladder = true

	self:_interupt_action_running(t)
	self._unit:mover():set_velocity(Vector3())
	self._unit:mover():set_gravity(Vector3(0, 0, 0))
	self._unit:mover():jump()
	self._unit:movement():on_enter_ladder(ladder_unit)
end

local old_end_action_ladder = PlayerStandardVR._end_action_ladder
function PlayerStandardVR:_end_action_ladder(t, input, ...)
	if not VRPlusMod._data.movement_locomotion then
		return old_end_action_ladder(self, t, input, ...)
	end

	if not self._state_data.on_ladder then
		return
	end

	self._state_data.on_ladder = false

	if self._unit:mover() then
		self._unit:mover():set_gravity(Vector3(0, 0, -982))
	end

	self._unit:movement():on_exit_ladder()
end

