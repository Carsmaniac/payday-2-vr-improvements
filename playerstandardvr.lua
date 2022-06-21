--[[
	PlayerStandardVR

	Change the movement method to thumbstick/trackpad locomotion
--]]

dofile(ModPath .. "playerstandardvr/warpidlestate.lua")
dofile(ModPath .. "playerstandardvr/warptargetstate.lua")
dofile(ModPath .. "playerstandardvr/ladders.lua")

-- Apply the movement speed cap
local old_get_max_walk_speed = PlayerStandard._get_max_walk_speed
function PlayerStandard:_get_max_walk_speed(...)
	local final_speed = old_get_max_walk_speed(self, ...)

	-- Apply a speed cap, as per the comfort options
	if VRPlusMod._data.comfort.max_movement_speed_enable then
		final_speed = math.min(final_speed, VRPlusMod._data.comfort.max_movement_speed)
	end

	return final_speed
end

function PlayerStandard:_check_action_run(t, input)
	-- Don't read input for _running_wanted - this is updated on the hand controller.
	
	-- Don't do anything if we're not moving. Saves on crashes, eg when downed.
	if not self._move_dir then
		self._running_wanted = false
		self.__stop_running = false
	end
	
	if self._running and self.__stop_running then
		self:_end_action_running(t)
	elseif not self._running and self._running_wanted then
		self:_start_action_running(t)
	end
end

-- Prevent crashes when stopping sprinting by letting go of the stick
local old_can_run_directional = PlayerStandard._can_run_directional
function PlayerStandard:_can_run_directional()
	return self._stick_move and old_can_run_directional(self) or false
end

-- Hand ourselves ('playerstate') to the states
local old_init = PlayerStandardVR.init
function PlayerStandardVR:init(unit)
	old_init(self, unit)

	-- Pass in our playerstate
	-- Always do this in case locomotion is later enabled.
	local controller = self._unit:base():controller()
	self._warp_state_machine = CoreFiniteStateMachine.FiniteStateMachine:new(WarpIdleState, "params", {
			state_data = self._state_data,
			unit = self._unit,
			input = self._movement_input,
			playerstate = self
	})

	self._warp_state_machine:set_debug(false)

	-- Non-time compensated movement, only counting locomotion
	-- See FPCameraPlayerBase
	self.__last_movement_xy = Vector3()
end

-- TODO remove when basegame rotation is confirmed to work
local function do_rotation(self, t, dt)
	local mode = VRPlusMod._data.turning_mode
	if mode == VRPlusMod.C.TURNING_OFF then return end

	local controller = self._unit:base():controller()
	local axis = controller:get_input_axis("touchpad_primary")
	local rot = VRManager:hmd_rotation():yaw() + self._camera_base_rot:yaw()

	if not axis then return end

	if mode == VRPlusMod.C.TURNING_SMOOTH then
		local deadzone = 0.75 -- TODO add option

		if math.abs(axis.x) > deadzone then
			-- Scale from nothing to 100% over the course of the active zone
			local amt = (axis.x > 0) and (axis.x - deadzone) or (axis.x + deadzone)
			amt = amt * 1/(1-deadzone)

			-- One full revolution per second on maxed stick
			local delta = dt * 360 / 2 * -amt
			self:set_base_rotation(Rotation(rot + delta, 0, 0))
		end
	else
		-- Snap turning
		-- TODO move to options GUI
		local turn, nonturn = 0.75, 0.5
		local delay = 0.25 -- Delay before turning
		local rotation_amt = 30 -- Rotation in degrees

		-- Apply cooldown
		self.__snap_rotate_timer = math.max(-1, (self.__snap_rotate_timer or 0) - dt)

		if math.abs(axis.x) > turn and self.__snap_rotate_timer < 0 then
			self.__snap_rotate_timer = delay
			local amt = ((axis.x > 0) and 1 or -1) * rotation_amt

			self:set_base_rotation(Rotation(rot - amt, 0, 0))
		end
	end
end

-- Same as vanilla, but lacks the dedicated snap turn buttons on Oculus Touch
function PlayerStandardVR:_check_vr_actions(t, dt)
	local state = self._warp_state_machine:state()

	if state.update then
		state:update(t, dt)
	end

	self._warp_state_machine:transition()

	if self._warp_state_machine:state():warp() and not self._state_data.warping then
		self:_start_action_warp(t)
	end
end

local old_update = PlayerStandardVR.update
function PlayerStandardVR:update(t, dt)
	do_rotation(self, t, dt) -- Handle smooth/snap rotation

	old_update(self, t, dt)
	
	-- Reset all movement-related stuff so nothing blows up
	-- if the idle controller disappears (both hands are busy)
	-- Very important we do this after everything else is done updating.
	if VRPlusMod._data.movement_locomotion then -- TODO is this if necessary?
		self._move_dir = nil
		self._normal_move_dir = nil
	end
end

-- Prevent _calculate_standard_variables from changing our velocity. Fixes #51
local mvec_throwaway_last_velocity = Vector3()
local old_calculate_standard_variables = PlayerStandard._calculate_standard_variables
function PlayerStandard:_calculate_standard_variables(t, dt)
	local real_last_velocity = self._last_velocity_xy
	self._last_velocity_xy = mvec_throwaway_last_velocity
	old_calculate_standard_variables(self, t, dt)
	self._last_velocity_xy = real_last_velocity
end

-- Handled in WarpIdleState:update and custom_move_direction
function PlayerStandardVR:_determine_move_direction() end

local mvec_prev_pos = Vector3() -- Our custom one
local mvec_achieved_walk_vel = Vector3()
local mvec_move_dir_normalized = Vector3()
local function inject_movement(self, t, dt, pos_new)
	local anim_data = self._unit:anim_data()
	local weapon_id = alive(self._equipped_unit) and self._equipped_unit:base() and self._equipped_unit:base():get_name_id()
	local weapon_tweak_data = weapon_id and tweak_data.weapon[weapon_id]
	self._target_headbob = self._target_headbob or 0
	self._headbob = self._headbob or 0
	
	mvector3.set(mvec_prev_pos, pos_new)

	if self._state_data.on_zipline and self._state_data.zipline_data.position then
		-- Do nothing
	elseif self._move_dir then
		local enter_moving = not self._moving
		self._moving = true

		if enter_moving then
			self._last_sent_pos_t = t

			self:_update_crosshair_offset()
		end

		local WALK_SPEED_MAX = self:_get_max_walk_speed(t)

		mvector3.set(mvec_move_dir_normalized, self._move_dir)
		mvector3.normalize(mvec_move_dir_normalized)

		local wanted_walk_speed = WALK_SPEED_MAX * math.min(1, self._move_dir:length())
		local acceleration = self._state_data.in_air and 700 or self._running and 5000 or 3000
		local achieved_walk_vel = mvec_achieved_walk_vel

		if self._jump_vel_xy and self._state_data.in_air and mvector3.dot(self._jump_vel_xy, self._last_velocity_xy) > 0 then
			local input_move_vec = wanted_walk_speed * self._move_dir
			local jump_dir = mvector3.copy(self._last_velocity_xy)
			local jump_vel = mvector3.normalize(jump_dir)
			local fwd_dot = jump_dir:dot(input_move_vec)

			if fwd_dot < jump_vel then
				local sustain_dot = (input_move_vec:normalized() * jump_vel):dot(jump_dir)
				local new_move_vec = input_move_vec + jump_dir * (sustain_dot - fwd_dot)

				mvector3.step(achieved_walk_vel, self._last_velocity_xy, new_move_vec, 700 * dt)
			else
				mvector3.multiply(mvec_move_dir_normalized, wanted_walk_speed)
				mvector3.step(achieved_walk_vel, self._last_velocity_xy, wanted_walk_speed * self._move_dir:normalized(), acceleration * dt)
			end

			local fwd_component = nil
		else
			mvector3.multiply(mvec_move_dir_normalized, wanted_walk_speed)
			mvector3.step(achieved_walk_vel, self._last_velocity_xy, mvec_move_dir_normalized, acceleration * dt)
		end

		if mvector3.is_zero(self._last_velocity_xy) then
			mvector3.set_length(achieved_walk_vel, math.max(achieved_walk_vel:length(), 100))
		end

		mvector3.set(pos_new, achieved_walk_vel)
		mvector3.multiply(pos_new, dt)
		mvector3.add(pos_new, mvec_prev_pos)

		self._target_headbob = self:_get_walk_headbob()
		self._target_headbob = self._target_headbob * self._move_dir:length()

		if weapon_tweak_data and weapon_tweak_data.headbob and weapon_tweak_data.headbob.multiplier then
			self._target_headbob = self._target_headbob * weapon_tweak_data.headbob.multiplier
		end
--[[	elseif not mvector3.is_zero(self._last_velocity_xy) then
		local decceleration = self._state_data.in_air and 250 or math.lerp(2000, 1500, math.min(self._last_velocity_xy:length() / tweak_data.player.movement_state.standard.movement.speed.RUNNING_MAX, 1))
		local achieved_walk_vel = math.step(self._last_velocity_xy, Vector3(), decceleration * dt)

		mvector3.set(pos_new, achieved_walk_vel)
		mvector3.multiply(pos_new, dt)
		mvector3.add(pos_new, mvec_prev_pos)

		self._target_headbob = 0]]
	elseif self._moving then
		self._target_headbob = 0
		self._moving = false

		--self:_update_crosshair_offset()
	end

	--[[if pos_new then
		self._unit:movement():set_position(pos_new)
		mvector3.set(self._last_velocity_xy, pos_new)
		mvector3.subtract(self._last_velocity_xy, self._pos)

		if not self._state_data.on_ladder and not self._state_data.on_zipline then
			mvector3.set_z(self._last_velocity_xy, 0)
		end

		mvector3.divide(self._last_velocity_xy, dt)
	else
		mvector3.set_static(self._last_velocity_xy, 0, 0, 0)
	end]]
end

-- These aren't used elsewhere, so it's safe to duplicate them
-- they're just to prevent reallocating vectors each frame
local mvec_pos_initial = Vector3()
local mvec_pos_new = Vector3()
local mvec_hmd_delta = Vector3()

local old_update_movement = PlayerStandardVR._update_movement
function PlayerStandardVR:_update_movement(t, dt)
	if not VRPlusMod._data.movement_locomotion then
		return old_update_movement(self, t, dt)
	end

	local pos_new = mvec_pos_new
	local init_pos_ghost = mvec_pos_initial

	-- Use the unit position rather than ghost position, so that we collide against stuff
	mvector3.set(pos_new, self._pos)

	if self._state_data.on_zipline and self._state_data.zipline_data.position then
		local rot = Rotation()

		mrotation.set_look_at(rot, self._state_data.zipline_data.zipline_unit:zipline():current_direction(), math.UP)

		self._ext_camera:camera_unit():base()._output_data.rotation = rot

		mvector3.set(pos_new, self._state_data.zipline_data.position)
	else
		mvector3.set_z(pos_new, self._pos.z)

		local hmd_delta = mvec_hmd_delta

		if not self._state_data._block_input then
			mvector3.set(hmd_delta, self._ext_movement:hmd_delta())
		else
			mvector3.set_zero(hmd_delta)
		end

		mvector3.set_z(hmd_delta, 0)
		mvector3.rotate_with(hmd_delta, self._camera_base_rot)
		mvector3.add(pos_new, hmd_delta)
	end
	
	-- only start tracking velocity from here - the HMD movement doesn't count.
	mvector3.set(init_pos_ghost, pos_new)

	inject_movement(self, t, dt, pos_new)

	self._ext_movement:set_ghost_position(pos_new)

	-- Non-time compensated version we can use to
	-- fix up camera error (see FPCameraPlayerBase)
	--
	-- TODO set this even when locomotion is off, so that
	-- the hands no longer disappear (shift back a lot).
	mvector3.set(self.__last_movement_xy, pos_new)
	mvector3.subtract(self.__last_movement_xy, init_pos_ghost)

	-- Time-compensated version
	mvector3.set(self._last_velocity_xy, self.__last_movement_xy)
	mvector3.divide(self._last_velocity_xy, dt)

	local cur_pos = pos_new or self._pos

	self._update_network_jump(self, cur_pos, false, t, dt)
	self._update_network_position(self, t, dt, cur_pos, pos_new)

	local move_dis = mvector3.distance_sq(cur_pos, self._last_sent_pos)

	if self.is_network_move_allowed(self) and (22500 < move_dis or (400 < move_dis and (1.5 < t - self._last_sent_pos_t or not pos_new))) then
		self._ext_network:send("action_walk_nav_point", cur_pos)
		mvector3.set(self._last_sent_pos, cur_pos)

		self._last_sent_pos_t = t
	end

	if self._is_jumping then
		self._jump_timer = self._jump_timer + dt
	end
end

Hooks:PreHook(PlayerStandard, "_check_action_interact", "VRPlusLockInteration", function(self, t, input)
	if not self._interact_params or not VRPlusMod._data.comfort.interact_lock then
		return
	end

	-- Prevent the interation from stopping
	input.btn_interact_release = false

	if not input.btn_interact_press then
		return
	end

	-- Prevent the player from interacting again
	-- IDK what would happen, but it wouldn't be any good.
	input.btn_interact_press = false

	local release_hand = input.btn_interact_left_press and PlayerHand.LEFT or PlayerHand.RIGHT
	if release_hand ~= self._interact_hand then
		-- Player let go with the hand they weren't interacting with
		return
	end

	-- Cancel the interaction
	input.btn_interact_release = true

	if self._interact_hand == PlayerHand.LEFT then
		input.btn_interact_left_release = true
	else
		input.btn_interact_right_release = true
	end
end)

Hooks:PostHook(PlayerStandardVR, "_check_action_duck", "VRPlusSetDuckStatus", function(self, t, input)
	local mode = VRPlusMod._data.comfort.crouching
	if mode == VRPlusMod.C.CROUCH_TOGGLE then
		if input.btn_duck_press then
			self.__bttn_ducking = not self.__bttn_ducking
		end
	elseif mode == VRPlusMod.C.CROUCH_HOLD then
		if input.btn_duck_release then
			self.__bttn_ducking = false
		elseif input.btn_duck_press then
			self.__bttn_ducking = true
		end
	else
		self.__bttn_ducking = false
	end
end)

-- Respect _can_duck, to prevent ducking during mask-off
local old_start_action_ducking = PlayerStandardVR._start_action_ducking
function PlayerStandardVR:_start_action_ducking(t)
	if not self:_can_duck() then return end
	old_start_action_ducking(self, t)
end

-- Permission functions that are overridden by the mask off state
-- define them so we can check them later
function PlayerStandardVR:_can_jump() return true end
function PlayerStandardVR:_can_duck() return true end

-- Since the 'jump' input isn't used by the vanilla game in VR, it's
-- action isn't disabled. As we use it for sprinting/jumping, make
-- sure the vanilla jumping logic doesn't fire (and lead to a crash).
function PlayerStandardVR:_check_action_jump(t, input) return false end

-- Fix weapons breaking (minigun firerate in automatic, won't fire in
-- semifire mode) after being tazed.
--
-- This is caused when the player fires on the same frame they are tazed.
-- When they stop being tazed, _shooting is set to false but _shooting_weapons
-- isn't necessaraly cleared.
--
-- For _shooting_weapons to be emptied, _shooting must be true - we're getting
-- stuck in a state where _shooting is false and _shooting_weapons is not empty.

Hooks:PreHook(PlayerStandardVR, "_check_fire_per_weapon", "VRPlusFixWeaponFireRate", function(self)
	if not self._shooting and self._shooting_weapons and next(self._shooting_weapons) then
		self._shooting_weapons = {}
	end
end)
