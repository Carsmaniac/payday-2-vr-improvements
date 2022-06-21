-- If you want to use the korean language patch, enable this
local LANG_KOREAN = false

--[[
	We setup the global table for our mod, along with some path variables, and a data table.
	We cache the ModPath directory, so that when our hooks are called, we aren't using the ModPath from a
		different mod.
]]
_G.VRPlusMod = _G.VRPlusMod or {}

-- Constants
VRPlusMod.C = {
	TURNING_OFF = 1,
	TURNING_SMOOTH = 2,
	TURNING_SNAP = 3,

	SPRINT_OFF = 1,
	SPRINT_STICKY = 2,
	SPRINT_HOLD = 3,
	SPRINT_HOLD_OUTER = 4,

	INTERACT_GRIP = 1,
	INTERACT_BOTH = 2,
	INTERACT_TRIGGER = 3,

	CROUCH_NONE = 1,
	CROUCH_TOGGLE = 2,
	CROUCH_HOLD = 3,

	WEAPON_MELEE_ENABLED = 1,
	WEAPON_MELEE_LOUD = 2,
	WEAPON_MELEE_DISABLED = 3,

	nil
}

-- Load the default options
dofile(ModPath .. "menus/defaults.lua")

VRPlusMod._path = ModPath
VRPlusMod._data_path = SavePath .. "vr_improvements.conf"
VRPlusMod._data = {}
VRPlusMod._menu_ids = {}

--[[
	A simple save function that json encodes our _data table and saves it to a file.
]]
function VRPlusMod:Save()
	local file = io.open( self._data_path, "w+" )
	if file then
		file:write( json.encode( self._data ) )
		file:close()
	end
end

local function load_defaults(defaults, target)
	for name, default in pairs(defaults) do
		-- Make sure to specificly say 'nil', so values set to false work
		if type(default) == "table" then
			local subtarget = target[name] or {}
			target[name] = subtarget
			load_defaults(default, target[name])
		elseif target[name] == nil then
			target[name] = default
		end
	end
end

--[[
	A simple load function that decodes the saved json _data table if it exists.
]]
function VRPlusMod:Load()
	local file = io.open( self._data_path, "r" )
	if file then
		self._data = json.decode( file:read("*all") )
		file:close()
	end
	
	-- Copy in any new properties'
	local need_save = not self._data.defaults_hmd
	local defaults, selected = VRPlusMod:_get_defaults(self._data.defaults_hmd)
	load_defaults(defaults, self._data)

	if need_save and selected then
		self:Save()
	end

	self._need_to_select_hmd = not selected
end

function VRPlusMod:_GetOptionTable(name)
	return name == "_G" and self._data or self._data[name]
end

function VRPlusMod:_ResetDefaultControls(hmd)
	self._need_to_select_hmd = false
	local defaults = VRPlusMod:_get_defaults(hmd)
	self._data = {}
	load_defaults(defaults, self._data)
	self:Save()

	-- Set the values for the GUI controls
	for menu_id, table_data_name in pairs(self._menu_ids) do
		local menu = MenuHelper:GetMenu(menu_id)
		for _, item in ipairs(menu._items_list) do
			if item.set_value then
				local val_name = item:name():sub(8) -- remove vrplus_
				local table_data = self:_GetOptionTable(table_data_name)
				local value = table_data[val_name]

				if item._type == "toggle" then
					item:set_value( value and "on" or "off" )
				else
					item:set_value( value )
				end
			end
		end
	end
end

function VRPlusMod:AskHMDType(cancellable)
	local defaults, selected = VRPlusMod:_get_defaults(self._data.defaults_hmd)
	load_defaults(defaults, self._data)

	local text = function(str) return managers.localization:text(str) end

	local options = {
		{
			text = text("vrplus_rift"),
			callback = function() self:_ResetDefaultControls("Rift") end
		},
		{
			text = text("vrplus_vive"),
			callback = function() self:_ResetDefaultControls("Vive") end
		},
		{
			text = text("vrplus_generic"),
			callback = function() self:_ResetDefaultControls("generic") end
		}
	}

	if cancellable then
		table.insert(options, {
			text = text("vrplus_cancel")
		})
	end

	QuickMenu:new(
		text("vrplus_ask_hmd_type"),
		text("vrplus_ask_hmd_type_message"),
		options
	):Show()
end

function VRPlusMod:OnMenusReady()
	if self._need_to_select_hmd then
		self._need_to_select_hmd = false
		self:AskHMDType(false)
	end
end

--[[
	Load our previously saved data from our save file.
]]
VRPlusMod:Load()

--[[
	Load our localization keys for our menu, and menu items.
]]
Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_VRPlusMod", function( loc )
	-- Load english as the fallback for any missing keys
	-- If a non-english language is in use, it will overwrite these keys
	loc:load_localization_file( VRPlusMod._path .. "lang/en.lang")

	if LANG_KOREAN then
		loc:load_localization_file( VRPlusMod._path .. "lang/kr.lang")
	end

	for key, code in pairs({
		russian = "ru",
		spanish = "es"
	}) do
		if Idstring(key) and Idstring(key):key() == SystemInfo:language():key() then
			loc:load_localization_file(VRPlusMod._path .. "lang/" .. code .. ".lang")
		end
	end
end)

--[[
	Setup our menu callbacks, load our saved data, and build the menu from our json file.
]]
Hooks:Add( "MenuManagerInitialize", "MenuManagerInitialize_VRPlusMod", function( menu_manager )
	local function add_inputs(scope, checkboxes, names, callback)
		for _, name in ipairs(names) do
			MenuCallbackHandler["vrplus_" .. name] = function(self, item)
				local options = VRPlusMod:_GetOptionTable(scope)
				if checkboxes then
					options[name] = (item:value() == "on" and true or false)
				else
					options[name] = item:value()
				end
				VRPlusMod:Save()

				if callback then
					callback(name, item)
				end
			end
		end
	end

	local function reload_hands()
		-- You can adjust settings on the flat version
		-- this would crash in that case
		if managers.vr then
			local hsm = managers.vr:hand_state_machine()
			-- If we're in the main menu, this will be nil
			if hsm then
				-- Apply the changes we made
				hsm:refresh()
			end
		end
	end

	function MenuCallbackHandler:vrplus_reset_options()
		VRPlusMod:AskHMDType(true)
	end

	function MenuCallbackHandler:vrplus_controls_manager()
		managers.menu:open_node("vrplus_controls_manager")
	end

	-- Checkboxes
	add_inputs("_G", true, {
		"movement_controller_direction",
		"cam_redout_enable",
		"movement_smoothing",
		"teleport_on_release",
	})

	add_inputs("_G", true, {
		"movement_locomotion",
	}, reload_hands)

	-- Sliders and multiselectors
	add_inputs("_G", false, {
		"deadzone",
		"sprint_time",
		"sprint_time",
		"turning_mode",

		"cam_fade_distance",
		"cam_reset_percent",
		"cam_reset_timer",

		"cam_redout_hp_start",
		"cam_redout_fade_max",

		"sprint_mode"
	})

	-- Comfort options
	add_inputs("comfort", true, {
		"max_movement_speed_enable",
		"interact_lock",
		nil
	})
	add_inputs("comfort", false, {
		"max_movement_speed",
		"crouch_scale",
		nil
	})

	add_inputs("comfort", false, {
		"interact_mode",
		"crouching",
		nil
	}, reload_hands)

	-- HUD options
	add_inputs("hud", true, {
		"watch_health_wheel",
		"belt_radio",
	})

	-- Tweak options
	add_inputs("tweaks", false, {
		"endscreen_speedup",
		"weapon_melee",
	})
	add_inputs("tweaks", true, {
		"force_quality_enable",
	})

	add_inputs("tweaks", false, {
		"force_quality",
	}, function(name, item)
		local quality_level = math.floor(VRPlusMod._data.tweaks.force_quality + 0.5)

		if VRPlusMod._data.tweaks.force_quality ~= quality_level then
			item:set_value( quality_level )
			VRPlusMod._data.tweaks.force_quality = quality_level
			VRPlusMod:Save()
		end
	end)

	local function reload_laser()
		if managers.menu._player then
			-- Make the changes take effeect
			managers.menu._player.__laser_is_updated = false
		end
	end
	add_inputs("tweaks", true, {
		"laser_disco"
	}, reload_laser)
	add_inputs("tweaks", false, {
		"laser_hue"
	}, reload_laser)

	local function addmenu(name, id, src)
		local srctable = VRPlusMod:_GetOptionTable(src)
		MenuHelper:LoadFromJsonFile(VRPlusMod._path .. "menus/" .. name .. ".json", nil, srctable)
		VRPlusMod._menu_ids[id] = src
	end

	--[[
		Load our menu json file and pass it to our MenuHelper so that it can build our in-game menu for us.
		The second option used to be for keybinds, however that seems to not be implemented on BLT2.
		We also pass our data table as the third argument so that our saved values can be loaded from it.
	]]
	MenuHelper:LoadFromJsonFile( VRPlusMod._path .. "menus/mainmenu.json", nil, nil )

	addmenu("camera",		"vrplus_menu_camera",		"_G" )
	addmenu("controllers",	"vrplus_menu_controllers",	"_G" )
	addmenu("comfort",		"vrplus_menu_comfort",		"comfort" )
	addmenu("hud",			"vrplus_menu_hud",			"hud" )
	addmenu("tweaks",		"vrplus_menu_tweaks",		"tweaks" )

end)
