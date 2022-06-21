--
-- Created by IntelliJ IDEA.
-- User: znix
-- Date: 7/25/18
-- Time: 6:17 PM
-- To change this template use File | Settings | File Templates.
--

ControlsManager = ControlsManager or blt_class(BLTCustomComponent)

function ControlsManager:setup()
	self._settings = VRPlusMod._data.control_rebindings or {}

	self:make_background()
	self:make_title(managers.localization:text("vrplus_controls_manager"), nil)

	local main_area_height = self._panel:h() - large_font_size * 2 - padding * 2

	-- Setup the state buttons
	local state_buttons = self:_setup_state_buttons(0, main_area_height)

	-- Setup the control buttons
	local state_buttons = self:_setup_control_buttons(state_buttons:w() + padding, main_area_height)

	-- Select the first item
	self:clbk_open_panel(Data.states[1])
end

function ControlsManager:_setup_state_buttons(panel_x, main_area_height)
	self._state_buttons = {}

	local w, h = 200, ((main_area_height - padding) / #Data.states) - padding --60

	local vert_button_count = math.floor((main_area_height - padding * 2) / (h + padding))
	local button_area = self._panel:panel({
		x = panel_x,
		y = large_font_size + padding,
		w = w + padding * 2,
		h = main_area_height,
		layer = 2,
	})
	self:make_background(button_area)
	button_area:bitmap({
		texture = "guis/textures/test_blur_df",
		w = button_area:w(),
		h = button_area:h(),
		render_template = "VertexColorTexturedBlur3D",
		layer = -1,
		halign = "scale",
		valign = "scale"
	})
	BoxGuiObject:new(button_area:panel({ layer = 100 }), { sides = { 1, 1, 1, 1 } })

	local radio_group = {}
	for i, state in ipairs(Data.states) do
		local button = RadioButton:new(button_area, {
			x = padding,
			y = padding + (h + padding) * (i - 1),
			w = w,
			h = h,
			text = state, -- TODO localization
			center_text = true,
			callback = callback(self, self, "clbk_open_panel", state),
			radio_group = radio_group
		})
		table.insert(self._buttons, button)
		self._state_buttons[state] = button
	end

	return button_area
end

function ControlsManager:_setup_control_buttons(panel_x, main_area_height)
	self._bind_buttons = {}

	local button_area = self._panel:panel({
		x = panel_x,
		y = large_font_size + padding,
		w = self._panel:w() - panel_x,
		h = main_area_height,
		layer = 2,
	})
	--local w, h = ((button_area:w() - padding) / 3) - padding, ((main_area_height - padding) / 4) - padding
	local w, h = 200, (main_area_height - padding * 4) / 3

	self:make_background(button_area)
	button_area:bitmap({
		texture = "guis/textures/test_blur_df",
		w = button_area:w(),
		h = button_area:h(),
		render_template = "VertexColorTexturedBlur3D",
		layer = -1,
		halign = "scale",
		valign = "scale"
	})
	--[[button_area:bitmap({
		texture = "guis/dlcs/vr/textures/pd2/menu_controls_touch_dash_walk",
		x = 0,
		y = 0,
		w = button_area:w(),
		h = button_area:h(),
		layer = 1
	})--]]
	BoxGuiObject:new(button_area:panel({ layer = 100 }), { sides = { 1, 1, 1, 1 } })

	local x, y = padding, padding
	for id, texts in pairs(Data.control_names) do

		local button = BindButton:new(button_area, {
			x = x,
			y = y,
			w = w,
			h = h,
			control_id = id,
			on_modified = callback(self, self, "clbk_control_modified", id)
		})
		table.insert(self._buttons, button)
		table.insert(self._bind_buttons, button)

		y = y + h + padding
		if y + h > button_area:h() then
			y = padding
			x = x + padding + w
		end
	end

	return button_area
end

function ControlsManager:clbk_open_panel(state)
	self._state = state
	local bttn = self._state_buttons[state]
	bttn:select()

	local settings = self._settings[state]

	for _, button in ipairs(self._bind_buttons) do
		local id = button:control_id()

		button:set(Data.defaults[state], settings and settings[id])
	end
end

function ControlsManager:clbk_control_modified(id, data)
	local settings = self._settings[self._state] or {}
	self._settings[self._state] = settings

	settings[id] = data

	if not next(settings) then
		self._settings[self._state] = nil
	end
end

function ControlsManager:Save()
	local result = next(self._settings) and self._settings
	VRPlusMod._data.control_rebindings = result
	VRPlusMod:Save()
	--log("Saving data: " .. json.encode(result))
end

--------------------------------------------------------------------------------
function ControlsManager:update(t, dt)
end

function ControlsManager:on_close()
	self:Save()
end

--[[
	Handle the mouse actually being moved.

	This function is called from mouse_moved, not from within Diesel

	This is copied/modified in, to support mouseovers for buttons
]]
function BLTCustomComponent:mouse_move(o, x, y)
	local used, pointer = self:update_back_button_hover(o, x, y)
	self._current_button = nil

	if alive(self._scroll) and not used then
		used, pointer = self._scroll:mouse_moved(o, x, y)
		if pointer then
			self:check_items()
			return used, pointer --focusing on scroll no need to continue.
		end
	end

	local inside_scroll = not alive(self._scroll) or self._scroll:panel():inside(x, y)
	for _, item in pairs(self._visible_buttons) do
		if item.mouse_moved then
			local state, result, capture = item:mouse_moved(o, x, y)
			if state then
				used = true
				pointer = result
			end
			if capture or (capture == nil and state) then
				self._current_button = item
			end
		end
		if item.set_highlight then
			if inside_scroll and (not used and item:inside(x, y)) then
				item:set_highlight(true)
				used, pointer = true, "link"
				self._current_button = item
			else
				item:set_highlight(false)
			end
		end
	end

	return used, pointer
end

--------------------------------------------------------------------------------
-- Patch MenuComponentManager to create the BLT Download Manager component

MenuHelper:AddComponent("vrplus_controls_manager", ControlsManager)

function MenuCallbackHandler:close_vrplus_controls_manager()
	managers.menu_component:close_vrplus_controls_manager_gui()
end

Hooks:Add("CoreMenuData.LoadDataMenu", "VRPlusMod.CoreMenuData.LoadDataMenu", function(menu_id, menu)
	if menu_id ~= "start_menu" and menu_id ~= "pause_menu" then return end

	--log(json.encode(menu))

	local new_node = {
		_meta = "node",
		name = "vrplus_controls_manager",
		menu_components = "vrplus_controls_manager",
		back_callback = "close_vrplus_controls_manager",
		scene_state = "crew_management",
		hide_bg = true,
		[1] = {
			_meta = "default_item",
			name = "back"
		}
	}
	table.insert(menu, new_node)
end)
