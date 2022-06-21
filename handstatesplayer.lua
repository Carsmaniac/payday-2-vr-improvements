--[[
	Hand States Player

	Apply the custom control scheme as set by the player.

	This also applies the older fixed-style customisations, which I'd
	like to find an elegant replacement for, as tick-box customisation is
	quicker/easier for the user than mapping the controls across several differnt
	states.
]]

-- The fixed customisations
-- Register these first so user-defined customisations override
--  these, not vise-versa.
-- Note these apply to the defaults (but NOT in the UI), so if the user resets
--  the customisation for a control it will still include these.
-- TODO make these appear in the defaults in some way
-- TODO add some kind of note in the UI to indicate such changes.

local function add_offhand_actions(hand_name, key_map)
	if VRPlusMod._data.comfort.crouching ~= VRPlusMod.C.CROUCH_NONE then
		key_map["menu_" .. hand_name] = { "duck" }
	end

	if VRPlusMod._data.movement_locomotion then
		-- Shouldn't break warp, as dpad_ isn't used outside the weapon hand anymore
		-- Still do it here, just to be safe
		key_map["dpad_" .. hand_name] = { "move" }

		-- Don't use 'warp' for running/jumping, as it seems somehow tied
		-- to the Rift's 'Y' button.
		key_map["trackpad_button_" .. hand_name] = { "jump" }
	end
end

-- Note EmptyHandState deals with everything for your non-weapon hand.
-- including shouting down civs, bagging loot, etc.
Hooks:PostHook(EmptyHandState, "apply", "VRPlusOffHandActions", function(self, hand, key_map)
	local hand_name = hand == 1 and "r" or "l"
	local nice_name = hand == 1 and "right" or "left"

	if VRPlusMod._data.comfort.interact_mode ~= VRPlusMod.C.INTERACT_GRIP then
		-- TODO should we just override it completely?
		local key = "trigger_" .. hand_name

		if not key_map[key] then
			key_map[key] = {}
		end

		table.insert(key_map[key], "interact_" .. nice_name)
	end

	if VRPlusMod._data.comfort.interact_mode == VRPlusMod.C.INTERACT_TRIGGER then
		key_map["grip_" .. hand_name][1] = nil
	end

	if VRPlusMod._data.movement_locomotion then
		-- Prevent moving forwards from jumping for Rift users
		key_map["d_up_" .. hand_name] = nil
	end

	add_offhand_actions(hand_name, key_map)
end)

Hooks:PostHook(PointHandState, "apply", "VRPlusPointingHandActions", function(self, hand, key_map)
	local hand_name = hand == 1 and "r" or "l"

	if VRPlusMod._data.movement_locomotion then
		-- Prevent moving forwards from jumping for Rift users
		key_map["d_up_" .. hand_name] = nil
	end

	add_offhand_actions(hand_name, key_map)
end)

Hooks:PostHook(MaskHandState, "apply", "VRPlusCasingRotation", function(self, hand, key_map)
	if VRPlusMod._data.turning_mode == VRPlusMod.C.TURNING_OFF then return end

	local hand_name = hand == 1 and "r" or "l"

	key_map["dpad_" .. hand_name] = { "touchpad_primary" }
end)

Hooks:PostHook(BeltHandState, "apply", "VRPlusBeltActions", function(self, hand, key_map)
	local weapon_hand = managers.vr:get_setting("default_weapon_hand"):sub(1,1)
	local hand_name = hand == 1 and "r" or "l"

	if VRPlusMod._data.turning_mode ~= VRPlusMod.C.TURNING_OFF and hand_name == weapon_hand then
		key_map["dpad_" .. hand_name] = { "touchpad_primary" }
	end

	if hand_name ~= weapon_hand then
		add_offhand_actions(hand_name, key_map)
	end
end)

Hooks:PostHook(WeaponHandState, "apply", "VRPlusMoveGadgetFiremode", function(self, hand, key_map)
	if VRPlusMod._data.turning_mode == VRPlusMod.C.TURNING_OFF then
		return
	end

	-- By default
	-- switch_hands -> up
	-- weapon_firemode -> left
	-- weapon_gadget ->  right

	local hand_name = hand == 1 and "r" or "l"
	key_map["d_left_" .. hand_name] = nil
	key_map["d_right_" .. hand_name] = nil
	key_map["d_up_" .. hand_name] = { "weapon_gadget" }
	key_map["d_down_" .. hand_name] = { "weapon_firemode" }
end)

-----------------------------------------
-- User-defined Control Customisations --
-----------------------------------------

-- List of the states the player can edit
-- Some are disabled as they're not used in-game and their inclusion
--  would be confusing to players.
-- Updates may require us to add to these
-- TODO i18n?
local states = {
	"Empty",
	"Point",
	"Weapon",
	"Akimbo",
	"Mask",
	"Item",
	"Ability",
	"Equipment",
	"Tablet",
	"Belt",
	--"Repeater",
	"Driving",
	--"Arrow",
}

-- Make these available to the control manager UI
VRPlusMod._ControlManager._handstatesplayerdata = {
	states = states
}

for _, state in ipairs(states) do
	local class = _G[state .. "HandState"]

	Hooks:PostHook(class, "apply", "VRPlusCustomInputs_" .. state, function(self, hand, key_map)
		local hand_name = hand == 1 and "r" or "l"

		-- Grab the customisations
		-- The format of the table is as follows:
		--[[
{
	menu = { -- The ID of the button, minus the _l or _r suffix indicating which
	         --  hand it's on
		reload = {}, -- The action to be taken, and what special settings it has
		toggle_menu = { hand = 2 }, -- Only apply this input to the left hand
	}
}
		--]]

		-- If no controls are set, stop here
		if not VRPlusMod._data.control_rebindings then return end

		-- Grab the controls for this state
		local rebindings = VRPlusMod._data.control_rebindings[state]
		if not rebindings then return end

		for input_id, actions in pairs(rebindings) do
			-- The list of actions to be taken (running with out previous example,
			--  this would be {"reload"} or {"reload", "toggle_menu"} depending on
			--  which hand this is being bound to
			local result_action_list = {}

			-- The input ID as used by the game, eg menu_l or menu_r
			local handed_input_id = input_id .. "_" .. hand_name

			for action, action_data in pairs(actions) do
				local actinfo = VRPlusMod._ControlManager.Data.actions[action]
				local action_id

				if actinfo.right then
					-- If there is a special set of action IDs depending on
					--  the hand, match for those
					action_id = hand == 1 and actinfo.right or actinfo.left
				else
					action_id = action
				end

				-- If the action is not limited to one particular hand, or if
				--  it's limited to the hand we're currently setting up, add
				--  it to the list of actions to take when this input is used
				if not action_data.hand or action_data.hand == hand then
					table.insert(result_action_list, action_id)
				end
			end

			-- Set the resulting items to nil if we don't have any actions
			--  bound to this input, otherwise set it to the list we just compiled
			key_map[handed_input_id] = #result_action_list == 0 and nil or result_action_list
		end
	end)
end
