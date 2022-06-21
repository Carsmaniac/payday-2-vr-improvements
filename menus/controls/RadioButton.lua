--
-- Created by IntelliJ IDEA.
-- User: znix
-- Date: 7/25/18
-- Time: 6:00 PM
-- To change this template use File | Settings | File Templates.
--

--[[
	RadioButton

	This is a button that can be selected, and when selected will deselect all
	other buttons in the 'radio_group' parameter
]]

RadioButton = blt_class(BLTUIButton)
function RadioButton:init(...)
	self.super.init(self, ...)

	assert(self:parameters().radio_group, "missing parameter radio_group")
	table.insert(self:parameters().radio_group, self)
end

function RadioButton:set_highlight(enabled, no_sound)
	if self._enabled ~= enabled then
		self._enabled = enabled
		self:_update_colour()
		if enabled and not no_sound then
			managers.menu_component:post_event("highlight")
		end
	end
end

function RadioButton:deselect()
	self._selected = false
	self:_update_colour()
end

function RadioButton:select()
	if self._selected then return end

	for _, bttn in ipairs(self:parameters().radio_group) do
		bttn:deselect()
	end

	self._selected = true
	self:_update_colour()
end

function RadioButton:_update_colour()
	self._background:set_color(self._selected and tweak_data.screen_colors.item_stage_1
			or self._enabled and tweak_data.screen_colors.button_stage_2
			or (self:parameters().color or tweak_data.screen_colors.button_stage_3))
end

function RadioButton:inside(x, y)
	if self._selected then
		return false
	end

	return self.super.inside(self, x, y)
end
