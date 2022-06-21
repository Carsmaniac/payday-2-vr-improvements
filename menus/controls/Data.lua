--
-- Created by IntelliJ IDEA.
-- User: znix
-- Date: 7/25/18
-- Time: 6:27 PM
-- To change this template use File | Settings | File Templates.
--

-- This not only defines the player hand states, but via
-- the handstatesplayer.lua hook, defines _handstatesplayerdata into
-- our custom environment
require("lib/input/HandStatesPlayer")

-- TODO i18n
local control_names = {
	menu = {
		Rift_left = "Y Button (upper)",
		Rift_right = "B Button (upper)",
		generic = "Menu Button",
	},
	a = {
		Rift_left = "X Button (lower)",
		Rift_right = "A Button (lower)",
		Vive = "'B' button (not present)", -- TODO make this disappear on Vives?
		generic = "B button",
	},
	trigger = {
		generic = "Trigger",
	},
	grip = {
		generic = "Grip",
	},
	trackpad_button = {
		Rift = "Thumbstick Button",
		Vive = "Touchpad Button",
		generic = "DPad Button",
	},
	dpad = {
		Rift = "Thumbstick Analog",
		Vive = "Touchpad Analog",
		generic = "DPad Analog",
	},
	d_up = {
		Rift = "Thumbstick Up",
		Vive = "Touchpad Up",
		generic = "DPad Up",
	},
	d_down = {
		Rift = "Thumbstick Down",
		Vive = "Touchpad Down",
		generic = "DPad Down",
	},
	d_left = {
		Rift = "Thumbstick Left",
		Vive = "Touchpad Left",
		generic = "DPad Left",
	},
	d_right = {
		Rift = "Thumbstick Right",
		Vive = "Touchpad Right",
		generic = "DPad Right",
	},
}

local actions = {
	akimbo_fire = {},
	automove = {},
	belt = {
		left = "belt_left",
		right = "belt_right",
	},
	disabled = {},
	hand_brake = {},
	interact = {
		left = "interact_left",
		right = "interact_right",
	},
	primary_attack = {},
	reload = {},
	run = {},
	tablet_interact = {},
	throw_grenade = {},
	toggle_menu = {},
	touchpad_move = {
		analog_only = true,
	},
	touchpad_primary = {
		analog_only = true,
	},
	move = {
		analog_only = true,
	},
	unequip = {},
	use_item = {},
	use_item_vr = {},
	warp = {},
	warp_target = {},
	weapon_firemode = {},
	weapon_gadget = {},
}

function get_human_control_name(id)
	local hmd_name = VRPlusMod._data.defaults_hmd

	-- TODO i18n localization support
	local texts = control_names[id]
	return texts[hmd_name .. "_left"] or texts[hmd_name] or texts["generic"]
end

local function find_inst_defaults(self, hand, results)
	if not self._connections then
		return
	end

	local hand_name = hand == 1 and "r" or "l"
	results = results or {}

	for name, data in pairs(self._connections) do
		local result = results[name] or {
			hand = data.hand,
			condition = data.condition,
			exclusive = data.exclusive,
			inputs = {}
		}

		local inputs = data.inputs

		if type(inputs) == "function" then
			-- TODO wrap in pcall
			inputs = inputs(hand, {})
		end

		for _, input in ipairs(inputs) do
			table.insert(result.inputs, input .. hand_name)
		end

		results[name] = result
	end

	return results
end

local function find_defaults()
	-- Stub out the VR manager, in case we're not in VR
	local old_manager = managers.vr
	if not old_manager then
		managers.vr = {
			is_oculus = function()
				return VRPlusMod._data.defaults_hmd == "Rift"
			end,
			walking_mode = function()
				-- TODO how to detmernine this
				return true
			end,
			get_setting = function(self, name)
				if name == "default_weapon_hand" then
					return "left" -- TODO really important, obviously
				end

				error("unknown setting name " .. name)
			end,
		}
	end

	local result = {}
	for _, state in ipairs(_handstatesplayerdata.states) do
		local class = _G[state .. "HandState"]
		local inst = class:new()

		-- Set a marker to prevent the mod from adjusting the controls
		inst.vrplus_config_marker = true

		local stateresult = {}
		find_inst_defaults(inst, 1, stateresult) -- Right
		find_inst_defaults(inst, 2, stateresult) -- Left
		--log(json.encode(stateresult))
		--local str = ""
		--for name, _ in pairs(stateresult) do str = str .. name .. "," end
		--log(state .. ": " .. str)

		result[state] = stateresult
	end

	managers.vr = old_manager

	return result
end

local defaults = find_defaults()
--log(json.encode(defaults))

Data = {
	control_names = control_names,
	actions = actions,
	states = _handstatesplayerdata.states, -- See handstatesplayer.lua
	defaults = defaults
}

padding = 10
small_font = tweak_data.menu.pd2_small_font
large_font_size = tweak_data.menu.pd2_large_font_size
small_font_size = tweak_data.menu.pd2_small_font_size
