--[[
	WarpIdleState

	Disable warp pointer thing, and allow jumping and sprinting with a motion controller.
--]]

local old_transition = WarpIdleState.transition
function WarpIdleState:transition(...)
	if not VRPlusMod._data.movement_locomotion then
		return old_transition(self, ...)
	end

	-- Always stay on Idle (this does not affect the special ladder
	-- states, etc - only using the thumbpad to switch to WarpTargetState)
	return
end

local function custom_move_direction(self, stick_motion, forwards, fwd_vert, rotation)
	self._stick_move = stick_motion

	if self._state_data.on_zipline then
		return
	end

	if mvector3.length(self._stick_move) < (VRPlusMod._data.deadzone / 100) or self:_interacting() or self:_does_deploying_limit_movement() then
		self._stick_move = nil
	end

	if not self._stick_move then
		self._move_dir = nil
		self._normal_move_dir = nil
		return
	end

	local ladder_unit = self._unit:movement():ladder_unit()

	if alive(ladder_unit) then
		local ladder_ext = ladder_unit:ladder()
		self._move_dir = mvector3.copy(self._stick_move)
		self._normal_move_dir = mvector3.copy(self._move_dir)
		local cam_flat_rot = Rotation(forwards, math.UP)

		mvector3.rotate_with(self._normal_move_dir, cam_flat_rot)

		local cam_rot = Rotation(fwd_vert, rotation:z())

		mvector3.rotate_with(self._move_dir, cam_rot)

		local up_dot = math.dot(self._move_dir, ladder_ext:up())
		local w_dir_dot = math.dot(self._move_dir, ladder_ext:w_dir())
		local normal_dot = math.dot(self._move_dir, ladder_ext:normal()) * -1
		local normal_offset = ladder_ext:get_normal_move_offset(self._unit:movement():m_pos())

		mvector3.set(self._move_dir, ladder_ext:up() * (up_dot + normal_dot))
		mvector3.add(self._move_dir, ladder_ext:w_dir() * w_dir_dot)
		mvector3.add(self._move_dir, ladder_ext:normal() * normal_offset)
	else
		self._move_dir = mvector3.copy(self._stick_move)
		local cam_flat_rot = Rotation(forwards, math.UP)

		mvector3.rotate_with(self._move_dir, cam_flat_rot)

		self._normal_move_dir = mvector3.copy(self._move_dir)
	end
end

-- Copied from PlayerMovementInputVR:update
local function apply_smoothing(axis)
	if not VRPlusMod._data.movement_smoothing then return axis end

	local dz = VRPlusMod._data.deadzone / 100
	local raw_move_length = mvector3.length(axis)
	local m = raw_move_length
	m = math.clamp((m - dz) / (1 - dz), 0, 1)

	if m > 0.98 then
			m = 1
	end

	local unscaled_edge = 0.25 -- Should this be 0.3?

	if raw_move_length - dz < unscaled_edge then
			local edge = unscaled_edge / (1 - dz)
			local x = m / (2 * edge)
			x = x * x * (3 - 2 * x)
			x = x * x * (3 - 2 * x)
			m = x * 2 * edge
	end

	if math.abs(m) < 0.01 then
			m = 0
	end

	mvector3.normalize(axis)
	mvector3.multiply(axis, m)

	return axis
end

-- Cloned directly from the flat version of playerstandard
-- TODO get the old function somehow
local function orig_start_action_jump(self, t, action_start_data)
	if self._running and not self.RUN_AND_RELOAD and not self._equipped_unit:base():run_and_shoot_allowed() then
		self:_interupt_action_reload(t)
		self._ext_camera:play_redirect(self:get_animation("stop_running"), self._equipped_unit:base():exit_run_speed_multiplier())
	end

	self:_interupt_action_running(t)

	self._jump_t = t
	local jump_vec = action_start_data.jump_vel_z * math.UP

	assert(self._unit:mover(), "unit must have a mover")
	self._unit:mover():jump()

	if self._move_dir then
		local move_dir_clamp = self._move_dir:normalized() * math.min(1, self._move_dir:length())
		self._last_velocity_xy = move_dir_clamp * action_start_data.jump_vel_xy
		self._jump_vel_xy = mvector3.copy(self._last_velocity_xy)
	else
		self._last_velocity_xy = Vector3()
	end

	self:_perform_jump(jump_vec)
end

local function ps_trigger_jump(self, t)
	if not self:_can_jump() then return end

	-- Some player states (eg, downed) won't have mover()s,
	-- so they obviously can't jump.
	if not self._unit:mover() then return end

	-- Make the player jump
	local action_forbidden = self._jump_t and t < self._jump_t + 0.55
			action_forbidden = action_forbidden or self._unit:base():stats_screen_visible() or
			self._state_data.in_air or self:_interacting() or self:_on_zipline() or
			self:_does_deploying_limit_movement() or self:_is_using_bipod()
	if action_forbidden then return false end

	if self._state_data.on_ladder then
		self:_interupt_action_ladder(t)
	end

	local action_start_data = {}
	local jump_vel_z = tweak_data.player.movement_state.standard.movement.jump_velocity.z
	action_start_data.jump_vel_z = jump_vel_z

	if self._move_dir then
		local is_running = self._running and self._unit:movement():is_above_stamina_threshold() and t - self._start_running_t > 0.4
		local jump_vel_xy = tweak_data.player.movement_state.standard.movement.jump_velocity.xy[is_running and "run" or "walk"]
		action_start_data.jump_vel_xy = jump_vel_xy

		if is_running then
			self._unit:movement():subtract_stamina(tweak_data.player.movement_state.stamina.JUMP_STAMINA_DRAIN)
		end
	end

	new_action = orig_start_action_jump(self, t, action_start_data)
end

local mvec_hand_forward = Vector3()
local mvec_hand_forward_vert = Vector3()
function WarpIdleState:update(t)
	if not VRPlusMod._data.movement_locomotion then
		return -- no previous update state
	end

	local state = self.params.playerstate
	local hand_name = self.params.unit:hand():warp_hand()
	local controller = state._unit:base():controller()

	-- Find which way forwards is, depending on if we're using controller-relative locomotion
	local forwards, fwd_vert, rotation
	if VRPlusMod._data.movement_controller_direction then
		local hand_unit = self.params.unit:hand():hand_unit(hand_name)
		forwards = mvec_hand_forward
		fwd_vert = mvec_hand_forward_vert

		rotation = hand_unit:rotation()
		mrotation.y(rotation, fwd_vert)
		
		mvector3.set(forwards, fwd_vert)
		mvector3.set_z(forwards, 0)
		mvector3.normalize(forwards)
	else
		forwards = state._cam_fwd_flat
		fwd_vert = state._cam_fwd
		rotation = state._ext_camera:rotation()
	end

	-- Apply thumbstick-based movement to _stick_move
	custom_move_direction(state, apply_smoothing(controller:get_input_axis("move")), forwards, fwd_vert, rotation)

	-- Sprinting
	local sprit_pressed = controller:get_input_bool("jump")

	-- For whatever reason, at least on the Rift, pressing the 'Y' button
	-- also seems to trigger the warp input, even if it has been unbound.
	-- TODO FIXME this doesn't always seem to work.
	if VRPlusMod._data.comfort.crouching ~= VRPlusMod.C.CROUCH_NONE and controller:get_input_bool("duck") then
		sprint_pressed = false
	end

	if sprit_pressed and managers.player._messiah_charges > 0 and
			managers.player._current_state == "bleed_out" and managers.player._coroutine_mgr:is_running("get_up_messiah") then
		managers.player:use_messiah_charge()
		managers.player:send_message(Message.RevivePlayer, nil, nil)

		return
	end

	if VRPlusMod._data.sprint_mode == VRPlusMod.C.SPRINT_OFF then
		-- FIXME this allows bunny-hopping - Should we disable it or keep it?
		if sprit_pressed then
			ps_trigger_jump(state, t)
		end

		return
	end

	if VRPlusMod._data.sprint_mode == VRPlusMod.C.SPRINT_HOLD_OUTER then
		if sprit_pressed and not state._stick_move then
			ps_trigger_jump(state, t)
		end

		state._running_wanted = state._stick_move and sprit_pressed
		state.__stop_running = not state._running_wanted

		return
	end

	-- If the button is being held down, start the hold timer
	if sprit_pressed and not self._click_time_start then
		self._click_time_start = t
	end

	-- the clock is running, and more than _data.sprint_time seconds have elapsed
	local held_down = self._click_time_start and (t - self._click_time_start) > VRPlusMod._data.sprint_time

	if not sprit_pressed then
		if self._click_time_start and not held_down then
			ps_trigger_jump(state, t)
			self._click_time_start = nil
		end

		self._click_time_start = nil
	end

	if VRPlusMod._data.sprint_mode == VRPlusMod.C.SPRINT_STICKY then
		if held_down then
			state._running_wanted = true
			state.__stop_running = false
		end
	elseif VRPlusMod._data.sprint_mode == VRPlusMod.C.SPRINT_HOLD then
		state._running_wanted = held_down
		state.__stop_running = not state._running_wanted
	else
		error("Unknown sprint mode " .. tostring(VRPlusMod._data.sprint_mode))
	end
end
