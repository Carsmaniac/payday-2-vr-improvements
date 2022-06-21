
-- Be sure NOT to use PreHook and PostHook, as they break if more than one argument is returned
local old_transition = WarpTargetState.transition
function WarpTargetState:transition(...)
	if VRPlusMod._data.teleport_on_release then
		local targeting = self.params.input:state().warp_target

		if not targeting and self.__touch_warp_last then
			self.params.input:state().warp_target = true
			self.params.input:state().warp = true
			self.params.input._is_movement_warp = true
		end

		self.__touch_warp_last = targeting
	end

	return old_transition(self, ...)
end
