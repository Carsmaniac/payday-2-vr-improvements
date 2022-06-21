--[[
	HUDHeistTimerVR

	Move the health/armor wheel to the wristwatch.
--]]

-- Cannot change while in-game
if not VRPlusMod._data.hud.watch_health_wheel then return end

-- TODO leave a duplicate on the ammo panel

local radial_size = 96 -- 96 px, or 1.5x normal
local outer_size = 100 -- the size of the parent panel

local padding = (outer_size - radial_size) / 2

local function get_health_panel(self)
	-- was ammo_panel()
	local panel = managers.hud:watch_panel():panel({
		name = "radial",
		w = radial_size, -- was 70
		h = radial_size,
		x = padding,
		y = padding
	})

	return panel
end

-- FIXME we shouldn't be duplicating this much.
-- but I don't know of any ways to move a panel once it's
-- been created.
local old_create_radial_health = HUDTeammateVR._create_radial_health
function HUDTeammateVR:_create_radial_health(radial_health_panel)
	if not self._main_player then
		-- the old function then forwards it onto the non-vr function
		-- which we can't get without a pre-hook
		return old_create_radial_health(self, radial_health_panel)
	end

	radial_health_panel = get_health_panel(self)
	self._radial_health_panel = radial_health_panel

	local radial_bg = radial_health_panel:bitmap({
		texture = "guis/textures/pd2/progress_warp_black",
		name = "radial_bg",
		alpha = 1,
		layer = 0,
		w = radial_health_panel:w(),
		h = radial_health_panel:h()
	})
	local radial_health = radial_health_panel:bitmap({
		texture = "guis/textures/pd2/progress_health",
		name = "radial_health",
		alpha = 1,
		layer = 2,
		blend_mode = "add",
		render_template = "VertexColorTexturedRadial",
		texture_rect = {
			128,
			0,
			-128,
			128
		},
		w = radial_health_panel:w(),
		h = radial_health_panel:h()
	})

	radial_health:set_color(Color(1, 1, 0, 0))

	local radial_shield = radial_health_panel:bitmap({
		texture = "guis/textures/pd2/progress_shield",
		name = "radial_shield",
		alpha = 1,
		layer = 1,
		blend_mode = "add",
		render_template = "VertexColorTexturedRadial",
		texture_rect = {
			128,
			0,
			-128,
			128
		},
		w = radial_health_panel:w(),
		h = radial_health_panel:h()
	})

	radial_shield:set_color(Color(1, 1, 0, 0))

	local damage_indicator = radial_health_panel:bitmap({
		blend_mode = "add",
		name = "damage_indicator",
		alpha = 0,
		texture = "guis/textures/pd2/hud_radial_rim",
		layer = 1,
		w = radial_health_panel:w(),
		h = radial_health_panel:h()
	})

	damage_indicator:set_color(Color(1, 1, 1, 1))

	local radial_custom = radial_health_panel:bitmap({
		texture = "guis/textures/pd2/hud_swansong",
		name = "radial_custom",
		blend_mode = "add",
		visible = false,
		render_template = "VertexColorTexturedRadial",
		layer = 5,
		color = Color(1, 0, 0, 0),
		w = radial_health_panel:w(),
		h = radial_health_panel:h()
	})
	local radial_ability_panel = radial_health_panel:panel({
		visible = false,
		name = "radial_ability"
	})
	local radial_ability_meter = radial_ability_panel:bitmap({
		blend_mode = "add",
		name = "ability_meter",
		texture = "guis/textures/pd2/hud_fearless",
		render_template = "VertexColorTexturedRadial",
		layer = 5,
		color = Color(1, 0, 0, 0),
		w = radial_health_panel:w(),
		h = radial_health_panel:h()
	})
	local radial_ability_icon = radial_ability_panel:bitmap({
		blend_mode = "add",
		name = "ability_icon",
		alpha = 1,
		layer = 5,
		w = radial_size * 0.5,
		h = radial_size * 0.5
	})

	radial_ability_icon:set_center(radial_ability_panel:center())

	local radial_delayed_damage_panel = radial_health_panel:panel({name = "radial_delayed_damage"})
	local radial_delayed_damage_armor = radial_delayed_damage_panel:bitmap({
		texture = "guis/textures/pd2/hud_dot_shield",
		name = "radial_delayed_damage_armor",
		visible = false,
		render_template = "VertexColorTexturedRadialFlex",
		layer = 5,
		w = radial_delayed_damage_panel:w(),
		h = radial_delayed_damage_panel:h()
	})
	local radial_delayed_damage_health = radial_delayed_damage_panel:bitmap({
		texture = "guis/textures/pd2/hud_dot",
		name = "radial_delayed_damage_health",
		visible = false,
		render_template = "VertexColorTexturedRadialFlex",
		layer = 5,
		w = radial_delayed_damage_panel:w(),
		h = radial_delayed_damage_panel:h()
	})

	if self._main_player then
		local radial_rip = radial_health_panel:bitmap({
			texture = "guis/textures/pd2/hud_rip",
			name = "radial_rip",
			alpha = 1,
			layer = 3,
			blend_mode = "add",
			render_template = "VertexColorTexturedRadial",
			texture_rect = {
				128,
				0,
				-128,
				128
			},
			w = radial_health_panel:w(),
			h = radial_health_panel:h()
		})

		radial_rip:set_color(Color(1, 0, 0, 0))
		radial_rip:hide()

		local radial_rip_bg = radial_health_panel:bitmap({
			texture = "guis/textures/pd2/hud_rip_bg",
			name = "radial_rip_bg",
			alpha = 1,
			layer = 1,
			blend_mode = "normal",
			render_template = "VertexColorTexturedRadial",
			texture_rect = {
				128,
				0,
				-128,
				128
			},
			w = radial_health_panel:w(),
			h = radial_health_panel:h()
		})

		radial_rip_bg:set_color(Color(1, 0, 0, 0))
		radial_rip_bg:hide()
	end

	local radial_absorb_shield_active = radial_health_panel:bitmap({
		blend_mode = "normal",
		name = "radial_absorb_shield_active",
		alpha = 1,
		texture = "guis/dlcs/coco/textures/pd2/hud_absorb_shield",
		render_template = "VertexColorTexturedRadial",
		layer = 5,
		w = radial_health_panel:w(),
		h = radial_health_panel:h()
	})

	radial_absorb_shield_active:set_color(Color(1, 0, 0, 0))
	radial_absorb_shield_active:hide()

	local radial_absorb_health_active = radial_health_panel:bitmap({
		blend_mode = "normal",
		name = "radial_absorb_health_active",
		alpha = 1,
		texture = "guis/dlcs/coco/textures/pd2/hud_absorb_health",
		render_template = "VertexColorTexturedRadial",
		layer = 5,
		w = radial_health_panel:w(),
		h = radial_health_panel:h()
	})

	radial_absorb_health_active:set_color(Color(1, 0, 0, 0))
	radial_absorb_health_active:hide()
	radial_absorb_health_active:animate(callback(self, self, "animate_update_absorb_active"))

	local radial_info_meter = radial_health_panel:bitmap({
		blend_mode = "add",
		name = "radial_info_meter",
		alpha = 1,
		texture = "guis/dlcs/coco/textures/pd2/hud_absorb_stack_fg",
		render_template = "VertexColorTexturedRadial",
		layer = 3,
		w = radial_health_panel:w(),
		h = radial_health_panel:h()
	})

	radial_info_meter:set_color(Color(1, 0, 0, 0))
	radial_info_meter:hide()

	local radial_info_meter_bg = radial_health_panel:bitmap({
		texture = "guis/dlcs/coco/textures/pd2/hud_absorb_stack_bg",
		name = "radial_info_meter_bg",
		alpha = 1,
		layer = 1,
		blend_mode = "normal",
		render_template = "VertexColorTexturedRadial",
		texture_rect = {
			128,
			0,
			-128,
			128
		},
		w = radial_health_panel:w(),
		h = radial_health_panel:h()
	})

	radial_info_meter_bg:set_color(Color(1, 0, 0, 0))
	radial_info_meter_bg:hide()
	self:_create_condition(radial_health_panel)
end

function HUDTeammateVR:set_hand(hand)
        if PlayerHand.hand_id(hand) == PlayerHand.RIGHT then
                self._ammo_panel:set_x(100)
                --self._radial_health_panel:set_x(15)
                self._stamina_panel:set_x(15)
        else
                self._ammo_panel:set_x(0)
                --self._radial_health_panel:set_x(215)
                self._stamina_panel:set_x(215)
        end

        self._ammo_flash:set_shape(self._ammo_panel:shape())
end
