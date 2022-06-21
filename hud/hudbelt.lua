
VRPlusMod.HUD_BELT = {
	-- Constants
	POSITION = "pos",
	SIZE = "size",

	-- Custom item constants (I_ prefix). Only used for ease of access, if you're using this
	--  system from your own mod you don't have to add one of these.
	I_RADIO = "vrplus_radio",

	-- All the custom belt items
	items = {
		vrplus_radio = { -- The index is the name of the belt item
			pos = {2, 4}, -- Default belt position
			size = {1, 1}, -- Default belt size
			setup = function(self, ws) -- Setup function. Returns the belt interaction, if the item is enabled.
				if not VRPlusMod._data.hud.belt_radio then return end
				return HUDBeltInteraction:new(ws, "vrplus_radio")
			end,
			grabbed = function(self, hand)
				local player = managers.player:player_unit()

				local id = Idstring(tweak_data.equipments.ecm_jammer.dummy_unit)
				local radio_unit = World:spawn_unit(id, Vector3(0, 0, 0), Rotation())

				hand._hsm:change_state_by_name("item", {
					type = VRPlusMod.HUD_BELT.I_RADIO,
					unit = radio_unit,
					offset = {
						position = Vector3(0, 0, 0),
						rotation = Rotation(-90)
					},
					prev_state = hand._prev_state
				})
			end
		}
	},

	-- Custom icons for the belt items. These can be used both by custom and vanilla items.
	-- The keys are the icon ids, and the values are either a string (texture filename), or
	--  a function that returns a texture string and accepts a HUDBeltInteraction instance.
	-- These do not have to match the names of custom belt items, but if they do you don't
	--  have to supply a custom icon id to HUDBeltInteraction:new in the setup() function.
	icons = {
		vrplus_radio = "guis/textures/vrplus/radio/icon"
	},

	adjust_position_size_table = function(self, belt, data, data_type)
		for id, default in pairs(data) do
			if not belt._interactions[id] then
				data[id] = nil
			end
		end

		for id, default in pairs(self.items) do
			if not data[id] and belt._interactions[id] then
				data[id] = default[data_type]
			end
		end
	end,
}

local hb = VRPlusMod.HUD_BELT

-- While we're at it, create the icon texture
DB:create_entry(Idstring("texture"), Idstring(hb.icons[hb.I_RADIO]), ModPath .. "assets/radio_icon.png")

-- HUDBeltInteraction

-- The game will probably crash if we use a custom icon, so use a default one
--  then immediately change the icon
local old_init = HUDBeltInteraction.init
function HUDBeltInteraction:init(ws, id, custom_icon_id, ...)
	local icon_id = custom_icon_id or id
	local modded_icon = hb.icons[icon_id] and true or false

	if not modded_icon then
		return old_init(self, ws, id, custom_icon_id, ...)
	end

	old_init(self, ws, id, "primary", ...)
	self._custom_icon_id = custom_icon_id
	self:update_icon()
end

-- Use our custom icons, if appropriate
local old_update_icon = HUDBeltInteraction.update_icon
function HUDBeltInteraction:update_icon(...)
	local id = self._custom_icon_id or self._id

	if not hb.icons[id] then
		return old_update_icon(self, ...)
	end

	local icon_raw = hb.icons[id]

	if type(icon_raw) == "function" then
		self._texture = icon_raw(self)
	else
		self._texture = icon_raw
	end

	self._icon:set_image(self._texture)

	local function scale_by_aspect(gui_obj, max_size)
		local w = gui_obj:texture_width()
		local h = gui_obj:texture_height()

		if h < w then
			gui_obj:set_size(max_size, max_size / w * h)
		else
			gui_obj:set_size(max_size / h * w, max_size)
		end
	end
	scale_by_aspect(self._icon, math.min(self._w, self._h))
	self._icon:set_center(self._panel:w() / 2, self._panel:h() / 2)
end

-- HUDBelt

-- This is run during HUDBelt setup, registering all new belt items
-- Being run directly before the first time the belt items are used, it
-- fixes the issue of the player's belt resetting each time the game is loaded.
Hooks:PreHook(HUDBelt, "verify_belt_ids", "VRPlusAddCustomBeltElements", function(self, ws)
	-- Only run this once, as it's run twice during setup and in later versions of PD2
	-- may be run in the future, though that doesn't seem to likely.
	if self.__vrplus_added_belt_items then
		return
	end
	self.__vrplus_added_belt_items = true

	-- Register all the custom items currently enabled.
	-- TODO maybe add some way to reload this while in-game?
	for id, val in pairs(hb.items) do
		-- If a new item in PAYDAY 2 is added and by some chance has the same ID,
		-- don't overwrite it.
		self._interactions[id] = val:setup(self._ws) or self._interactions[id]
	end
end)

-- Don't try to set the position or size for something that doesn't exist, and
--  also apply the default position/size for custom items
local old_layout_grid = HUDBelt.layout_grid
function HUDBelt:layout_grid(layout, ...)
	layout = clone(layout)
	hb:adjust_position_size_table(self, layout, hb.POSITION)
	return old_layout_grid(self, layout, ...)
end

local old_set_box_sizes = HUDBelt.set_box_sizes
function HUDBelt:set_box_sizes(layout, ...)
	layout = clone(layout)
	hb:adjust_position_size_table(self, layout, hb.SIZE)
	return old_set_box_sizes(self, layout, ...)
end
