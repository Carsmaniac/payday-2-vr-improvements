--
-- Created by IntelliJ IDEA.
-- User: znix
-- Date: 7/25/18
-- Time: 6:00 PM
-- To change this template use File | Settings | File Templates.
--

--[[
	MiniButton

	A small button, consisting of only a clickable string and no background

	Used to create the 'X' to reset a bind
]]

local MiniButton = blt_class()
function MiniButton:init(panel, parameters)
	self._parameters = parameters

	-- Note that tweak_data.screen_colors.title is (AFAIK) nil, so don't
	-- crash if that's passed in (it just relies on the default).
	self._colour = parameters.color or tweak_data.screen_colors.text

	self._text = panel:text({
		x = parameters.x,
		y = parameters.y,
		font_size = small_font_size,
		font = small_font,
		layer = 10,
		color = self._colour,
		text = parameters.text,
		vertical = parameters.vertical or "top",
		align = parameters.align or "left",
	})

	-- text_rect returns the world x,y,w,h not the local ones
	self._text:set_world_shape(self._text:text_rect())
end

function MiniButton:inside(x, y)
	return self._text:inside(x, y)
end

function MiniButton:set_highlight(enabled, no_sound)
	if self._enabled ~= enabled then
		self._enabled = enabled
		self._text:set_color(enabled and tweak_data.screen_colors.button_stage_2 or self._colour)
		if enabled and not no_sound then
			managers.menu_component:post_event("highlight")
		end
	end
end

function MiniButton:panel()
	return self._text
end

function MiniButton:parameters()
	return self._parameters
end

----------------------

BindButton = blt_class()

function BindButton:init(panel, parameters)
	self._parameters = parameters
	self._control_id = parameters.control_id

	assert(parameters.on_modified)
	assert(parameters.control_id)

	self._btns = {}
	self._actions = {}

	-- Main panel
	self._panel = panel:panel({
		x = parameters.x or 0,
		y = parameters.y or 0,
		w = parameters.w or 128,
		h = parameters.h or 128,
		layer = 5
	})

	local label = get_human_control_name(self._control_id)
	self._panel:text({
		name = "control_id",
		x = padding,
		y = 0,
		font_size = small_font_size,
		font = small_font,
		layer = 10,
		blend_mode = "add",
		color = tweak_data.screen_colors.title,
		text = label,
		vertical = "top",
	})
end

--[[
	Run the on_modified callback, passing in the appropriate values
]]
function BindButton:_save_changes()
	self:_setup_buttons()

	if self._enabled then
		self._parameters.on_modified(self._actions)
	else
		self._parameters.on_modified(nil)
	end
end

function BindButton:set(defaults, data)
	if type(data) ~= "table" then
		data = nil
	end

	self._enabled = data ~= nil

	self._defaults = {}

	-- Since all actions have both a left- and right-hand input, this isn't
	-- a problem only looking for one of them
	local handed_control_id = self._control_id .. "_r"

	for action_id, action_data in pairs(defaults) do
		-- TODO hand
		for _, input_id in ipairs(action_data.inputs) do
			if input_id == handed_control_id then

				local result_aid
				for aid, adata in pairs(Data.actions) do
					if aid == action_id or adata.right == action_id or adata.left == action_id then
						result_aid = aid
					end
				end

				-- If there are two inputs with the same ID, that's because
				-- there are seperate left- and right-handed versions.
				-- In this case, make them both-hand usable
				if result_aid then
					if not self._defaults[result_aid] then
						self._defaults[result_aid] = {
							hand = action_data.hand
						}
					else
						self._defaults[result_aid].hand = nil
					end
				end
			end
		end
	end

	self._actions = {}
	for name, value in pairs(data or self._defaults) do
		if Data.actions[name] then
			self._actions[name] = deep_clone(value)
		else
			log("[vrplus][controls] Error - trying to load (and ignoring) invalid key " .. name)
		end
	end

	self:_setup_buttons()
end

function BindButton:_setup_buttons()
	self._current_button = nil
	for _, button in ipairs(self._btns) do
		self._panel:remove(button:panel())
	end
	self._btns = {}

	local y = small_font_size
	local h = small_font_size + padding
	local i = 0

	--self._disabled_blur:set_visible(self._enabled)
	if self._enabled then
		local reset_button = MiniButton:new(self._panel, {
			x = 0,
			y = 0,
			w = self._panel:w(),
			text = "X",
			callback = callback(self, self, "clbk_uncustomize"),
			align = "right",
		})
		table.insert(self._btns, reset_button)
	else
		local disabled_button = BLTUIButton:new(self._panel, {
			x = 0,
			y = y,
			w = self._panel:w(),
			h = self._panel:h() - y,
			text = managers.localization:text("vrplus_controls_manager_customise"),
			center_text = true,
			callback = callback(self, self, "clbk_customize"),
			layer = 1,
			color = Color(1, 0.3, 0.3, 0.3)
		})
		disabled_button._background:set_layer(11)
		disabled_button._background:set_blend_mode("mul")
		disabled_button:text():set_layer(12)
		table.insert(self._btns, disabled_button)
	end

	local bttn_colour = not self._enabled and tweak_data.screen_colors.item_stage_1

	for id, data in pairs(self._actions) do
		i = i + 1

		local button = BLTUIButton:new(self._panel, {
			x = 0,
			y = y, -- + (h + padding) * (i - 1)
			w = self._panel:w() - h * 2 - padding,
			h = h,
			text = id, -- TODO
			center_text = true,
			callback = callback(self, self, "clbk_edit_bind", id),
			color = bttn_colour,
		})
		table.insert(self._btns, button)

		local button = BLTUIButton:new(self._panel, {
			x = self._panel:w() - h * 2 - padding / 2,
			y = y, -- + (h + padding) * (i - 1)
			w = h,
			h = h,
			text = data.hand and (data.hand == 1 and "R" or "L") or "-",
			center_text = true,
			callback = callback(self, self, "clbk_change_handiness", id),
			color = bttn_colour,
		})
		table.insert(self._btns, button)

		local button = BLTUIButton:new(self._panel, {
			x = self._panel:w() - h,
			y = y, -- + (h + padding) * (i - 1)
			w = h,
			h = h,
			text = "X",
			center_text = true,
			callback = callback(self, self, "clbk_remove_bind", id),
			color = bttn_colour,
		})
		table.insert(self._btns, button)

		y = y + h + padding / 2
	end

	if i < 4 then
		local button = BLTUIButton:new(self._panel, {
			x = 0,
			y = y, -- + (h + padding) * (i - 1)
			w = self._panel:w(),
			h = h,
			text = "+",
			center_text = true,
			callback = callback(self, self, "clbk_add_bind"),
			color = bttn_colour,
		})
		table.insert(self._btns, button)
	end
end

function BindButton:clbk_add_bind()
	self:_ask_for_action(function(id)
		self._actions[id] = {}
		self:_save_changes()
	end)
end

function BindButton:clbk_edit_bind(old_id)
	self:_ask_for_action(function(new_id)
		self._actions[new_id] = self._actions[old_id]
		self._actions[old_id] = nil
		self:_save_changes()
	end)
end

function BindButton:clbk_remove_bind(id)

	local dialog_data = {
		title = managers.localization:text("vrplus_controls_manager_remove"),
		text = managers.localization:text("vrplus_controls_manager_remove_desc")
	}
	local yes_button = {
		text = managers.localization:text("dialog_yes"),
		callback_func = function()
			self._actions[id] = nil
			self:_save_changes()
		end
	}
	local no_button = {
		text = managers.localization:text("dialog_no"),
		cancel_button = true
	}
	dialog_data.button_list = {
		yes_button,
		no_button
	}

	managers.system_menu:show(dialog_data)
end

function BindButton:_ask_for_action(clbk)
	local dialog_data = {
		title = managers.localization:text("vrplus_controls_manager_select_action"),
		text = "",
		button_list = {}
	}

	local is_analog = self:control_id() == "dpad"

	for id, option in pairs(Data.actions) do
		if not self._actions[id] and (option.analog_only or false) == is_analog then
			-- TODO (i18n) use real human names for these
			local text = id --option

			table.insert(dialog_data.button_list, {
				text = text,
				callback_func = function()
					local res, err = pcall(clbk, id)
					if not res then
						log(err)
					end
				end
			})
		end
	end

	local divider = {
		no_text = true,
		no_selection = true
	}

	table.insert(dialog_data.button_list, divider)

	local no_button = {
		text = managers.localization:text("dialog_cancel"),
		cancel_button = true
	}

	table.insert(dialog_data.button_list, no_button)

	dialog_data.image_blend_mode = "normal"
	dialog_data.text_blend_mode = "add"
	dialog_data.use_text_formating = true
	--dialog_data.w = 480
	--dialog_data.h = 532
	dialog_data.title_font = tweak_data.menu.pd2_medium_font
	dialog_data.title_font_size = tweak_data.menu.pd2_medium_font_size
	dialog_data.font = tweak_data.menu.pd2_small_font
	dialog_data.font_size = tweak_data.menu.pd2_small_font_size
	dialog_data.text_formating_color = Color.white
	dialog_data.text_formating_color_table = {}
	--dialog_data.clamp_to_screen = true

	managers.system_menu:show_buttons(dialog_data)
end

function BindButton:clbk_change_handiness(id)
	local function set_hand(hid)
		self._actions[id].hand = hid
		self:_save_changes()
	end

	local dialog_data = {
		title = managers.localization:text("vrplus_controls_manager_select_hand"),
		text = "",
		button_list = {
			{
				text = managers.localization:text("vrplus_right"),
				callback_func = function()
					set_hand(1)
				end
			},
			{
				text = managers.localization:text("vrplus_left"),
				callback_func = function()
					set_hand(2)
				end
			},
			{
				text = managers.localization:text("vrplus_both_hands"),
				callback_func = function()
					set_hand(nil)
				end
			},
			{ -- divider
				no_text = true,
				no_selection = true
			},
			{ -- cancel
				text = managers.localization:text("dialog_cancel"),
				cancel_button = true
			}
		}
	}

	managers.system_menu:show_buttons(dialog_data)
end

function BindButton:clbk_customize()
	self._enabled = true
	self:_save_changes()
end

function BindButton:clbk_uncustomize()
	local dialog_data = {
		title = managers.localization:text("vrplus_controls_manager_reset"),
		text = managers.localization:text("vrplus_controls_manager_reset_desc")
	}
	local yes_button = {
		text = managers.localization:text("dialog_yes"),
		callback_func = function()
			self._actions = deep_clone(self._defaults)
			self._enabled = false
			self:_save_changes()
		end
	}
	local no_button = {
		text = managers.localization:text("dialog_no"),
		cancel_button = true
	}
	dialog_data.button_list = {
		yes_button,
		no_button
	}

	managers.system_menu:show(dialog_data)
end

function BindButton:mouse_moved(o, x, y)
	self._current_button = nil

	for _, item in pairs(self._btns) do
		if self._panel:inside(x, y) and item:inside(x, y) then
			item:set_highlight(true)
			self._current_button = item
			return true, "link"
		else
			item:set_highlight(false)
		end
	end
end

function BindButton:mouse_pressed(button, x, y)
	local item = self._current_button
	if item and item:inside(x, y) then
		if item.parameters then
			local clbk = item:parameters().callback
			if clbk then
				clbk()
			end
		end
		return true
	end
end

function BindButton:control_id()
	return self._control_id
end
