--[[
	HUDManagerVR

	Set a speedup effect when the heist ends
]]

Hooks:PostHook(HUDManager, "setup_endscreen_hud", "VRPlusSpeedUpEndscreen", function(self)
	self._hud_stage_endscreen:set_speed_up(VRPlusMod._data.tweaks.endscreen_speedup)
end)

-- Total replacement of the tablet GUI to add a new panel
function HUDManagerVR:_init_tablet_gui()
	self._tablet_ws = self._gui:create_world_workspace(402, 226, Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 1, 0))
	local tablet_panel = self._tablet_ws:panel()
	local main = tablet_panel:panel({
		name = "main_page"
	})
	local right = tablet_panel:panel({
		name = "right_page",
		x = tablet_panel:w()
	})
	local left = tablet_panel:panel({
		name = "left_page",
		x = -tablet_panel:w()
	})
	local left2 = tablet_panel:panel({
		name = "left2_page",
		x = -tablet_panel:w() * 2
	})
	self._tablet_highlight = tablet_panel:panel({
		layer = 10,
		name = "highlight"
	})

	self._tablet_highlight:bitmap({
		texture = "guis/dlcs/vr/textures/pd2/pad_state_rollover",
		name = "highlight",
		w = tablet_panel:w(),
		h = tablet_panel:h()
	})

	self._tablet_touch = self._tablet_highlight:bitmap({
		texture = "guis/dlcs/vr/textures/pd2/pad_state_touch",
		name = "highlight",
		h = 100,
		w = 100
	})

	self._tablet_highlight:hide()
	
	-- Manually add the backgrounds because of duplicate texture keys
	main:bitmap({
		name = "bg",
		layer = -2,
		texture = "guis/dlcs/vr/textures/pd2/pad_bg",
		w = tablet_panel:w(),
		h = tablet_panel:h()
	})
	left:bitmap({
		name = "bg",
		layer = -2,
		texture = "guis/dlcs/vr/textures/pd2/pad_bg",
		w = tablet_panel:w(),
		h = tablet_panel:h()
	})
	left2:bitmap({
		name = "bg",
		layer = -2,
		texture = "guis/dlcs/vr/textures/pd2/pad_bg_r",
		w = tablet_panel:w(),
		h = tablet_panel:h()
	})
	right:bitmap({
		name = "bg",
		layer = -2,
		texture = "guis/dlcs/vr/textures/pd2/pad_bg_l",
		w = tablet_panel:w(),
		h = tablet_panel:h()
	})

	self._page_panels = {
		main,
		right,
		left,
		left2
	}
	self._pages = {
		main = {
			left = "left",
			right = "right"
		},
		right = {
			left = "main"
		},
		left = {
			left = "left2",
			right = "main"
		},
		left2 = {
			right = "left"
		}
	}
	self._current_page = "main"
	self._page_callbacks = {
		on_interact = {},
		on_focus = {}
	}
	
	self:_init_vrplus_voicepanel(left2)

	self._tablet_ws:hide()
end

function HUDManagerVR:_init_vrplus_voicepanel(voice_panel)

	-- Rows and columns of voice lines
	self._voice_ids = {
		{
			{ id = "v56", name = "Hello" }, -- Hello
			{ id = "g15", name = "Over There" }, -- There/Look
			{ id = "v32", name = "Over Here" } -- Here it is
		},
		{
			{ id = "v46", name = "Yes" }, -- Yes
			{ id = "s05x_sin", name = "Thanks" }, -- Thanks
			{ id = "g11", name = "No" } -- No/Wrong
		},
		{
			{ id = "f38_any", name = "Follow me" }, -- Follow Me
			{ id = "g16", name = "Keep defending" }, -- Keep Defending
			{ id = "g17", name = "Time to go" } -- Time To Go
		}
	}
	
	self._voice_width = voice_panel:w()
	self._voice_height = voice_panel:h()
	
	self._voice_subpanels = {}
	
	local i = 0 -- X
	local j = 0 -- Y
	
	for row, data in ipairs(self._voice_ids) do
		i = 0
		for column, voice_data in ipairs(data) do
			local btn_panel = voice_panel:panel({
				name = voice_data.id,
				alpha = 1,
				x = (self._voice_width / 3) * i,
				y = (self._voice_height / 3) * j,
				w = self._voice_width / 3,
				h = self._voice_height / 3
			})
			
			btn_panel:bitmap({
				name = "bg",
				layer = -1,
				texture = "guis/textures/pd2/box_bg",
				w = btn_panel:w(),
				h = btn_panel:h()
			})
			
			btn_panel:text({
				x = 0,
				y = 0,
				name = "text_" .. voice_data.id,
				vertical = "center",
				hvertical = "center",
				align = "center",
				blend_mode = "normal",
				halign = "center",
				layer = 2,
				text = voice_data.name,
				font = tweak_data.menu.pd2_small_font,
				font_size = tweak_data.menu.pd2_small_font_size,
				color = Color.white
			})
			
			table.insert(self._voice_subpanels, btn_panel)
			
			i = i + 1
		end
		
		j = j + 1
	end
	
	self:add_page_callback("left2", "on_interact", callback(self, self, "_on_voicepanel_interact"))
end

function HUDManagerVR:_on_voicepanel_interact(position)	
	-- Get X and Y, but remap them from -1,1 to 0,1
	local x = (position.x * 0.5) + 0.5
	local y = (position.y * 0.5) + 0.5
	
	-- Convert X and Y to 1, 2 or 3
	x = math.ceil(x * 3)
	y = math.ceil(y * 3)
	
	-- Speak chosen line
	self:_voice_speak(self._voice_ids[y][x].id)
end

function HUDManagerVR:_voice_speak(voice_id)

	-- 2 sec cooldown, disallow voice spam
	if self._last_speak_t and managers.player:player_timer():time() - self._last_speak_t < 2 then
		return
	end

	if Utils:IsInHeist() and Utils:IsInCustody() == false and Utils:IsInGameState() then
		managers.player:local_player():sound():say(voice_id, true, true)
		self._last_speak_t = managers.player:player_timer():time()
	end
end