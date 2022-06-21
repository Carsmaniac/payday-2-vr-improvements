
local last_quality_level
local old_update_adaptive_quality_level = VRManagerPD2._update_adaptive_quality_level
function VRManagerPD2:_update_adaptive_quality_level(t, ...)
	if not VRPlusMod._data.tweaks.force_quality_enable then
		return old_update_adaptive_quality_level(self, t, ...)
	end

	if self._update_super_sample_scale_t and self._update_super_sample_scale_t < t then
		self._update_super_sample_scale_t = nil
	end

	local quality_level = math.floor(VRPlusMod._data.tweaks.force_quality + 0.5)
	local quality_changed = quality_level ~= last_quality_level

	local scale = VRManager:super_sample_scale()

	if (math.abs(scale - self._super_sample_scale) > 0.01 or quality_changed)
			and not self._update_super_sample_scale_t then
		self._update_super_sample_scale_t = t + 0.5
		self._super_sample_scale = scale

		Application:apply_render_settings()
	end

	if quality_changed then
		last_quality_level = quality_level
	end

	local x_scale = 1
	local y_scale = 1

	if quality_level < 7 then
		local tres = VRManager:target_resolution()
		local scaling = self._adaptive_scale[quality_level]
		x_scale = scaling / self._adaptive_scale_max
		local res_x = math.floor(tres.x * x_scale)

		if res_x % 4 > 0.01 then
			res_x = res_x + 4 - res_x % 4
		end

		x_scale = res_x / tres.x + 0.05 / tres.x
		y_scale = scaling / self._adaptive_scale_max
		local res_y = math.floor(tres.y * y_scale)

		if res_y % 2 > 0.01 then
			res_y = res_y + 1
		end

		y_scale = res_y / tres.y + 0.05 / tres.y
	end

	VRManager:set_output_scaling(x_scale, y_scale)
	managers.overlay_effect:viewport():set_dimensions(0, 0, x_scale, y_scale)

	for _, svp in ipairs(managers.viewport:all_really_active_viewports()) do
		if svp:use_adaptive_quality() then
			svp:vp():set_dimensions(0, 0, x_scale, y_scale)
		end
	end

	for _, svp in ipairs(self._viewports) do
		if svp:use_adaptive_quality() then
			svp:vp():set_dimensions(0, 0, x_scale, y_scale)
		end
	end
end
