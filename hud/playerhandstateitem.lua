
local last_ptt = false

local hiss_path = ModPath .. "assets/radio-hiss.ogg"
local hiss_buffer = nil
local hiss_source = nil

local function set_ptt(state, unit)
	-- Update the transmit light
	if unit then
		local green = unit:get_object(Idstring("g_glow_func1_green"))
		local red = unit:get_object(Idstring("g_glow_func1_red"))

		green:set_visibility(state)
		red:set_visibility(not state)
	end

	-- Update the voicechat state, but only if it has changed
	if state == last_ptt then
		return
	end

	managers.menu:push_to_talk(state)
	last_ptt = state

	-- Radio hiss

	-- Check XAudio is available
	if not XAudio then
		return
	end

	-- If a hiss is currently playing, stop it
	if hiss_source then
		hiss_source:close()
		hiss_source = nil
	end

	-- Check the hiss sound is loaded
	if not hiss_buffer then
		blt.xaudio.setup()
		hiss_buffer = XAudio.Buffer:new(hiss_path)
	end

	-- If the radio is pressed, start the hiss noise
	if state and unit then
		hiss_source = XAudio.UnitSource:new(unit, hiss_buffer)
		hiss_source:set_looping(true)
		hiss_source:set_volume(0.1)
	end
end

Hooks:PostHook(PlayerHandStateItem, "update", "VRPlusUpdateHeldItem", function(self, t, dt)
	if self._item_type ~= VRPlusMod.HUD_BELT.I_RADIO then
		return
	end

	local controller = managers.vr:hand_state_machine():controller()
	local state = controller:get_input_bool("use_item_vr")

	set_ptt(state, self._item_unit)
end)

Hooks:PostHook(PlayerHandStateItem, "at_exit", "VRPlusExitHeldItem", function(self, t, dt)
	if self._item_type ~= VRPlusMod.HUD_BELT.I_RADIO then
		return
	end

	set_ptt(false)
end)
