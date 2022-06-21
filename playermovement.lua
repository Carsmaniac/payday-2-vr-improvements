
local old_update_vr = PlayerMovement._update_vr
function PlayerMovement:_update_vr(unit, t, dt)
	local mode = VRPlusMod._data.comfort.crouching
	if mode == VRPlusMod.C.CROUCH_NONE then
		return old_update_vr(self, unit, t, dt)
	end

	if self._block_input then
		return
	end

	local hmd_pos = VRManager:hmd_position()
	self:__affect_vrobj_position(hmd_pos)

	mvector3.set(self._hmd_delta, hmd_pos)
	mvector3.subtract(self._hmd_delta, self._hmd_pos)
	mvector3.set(self._hmd_pos, hmd_pos)
end

function PlayerMovement:__affect_vrobj_position(pos)
	-- Working around a vanilla crash, happens on load only and is possibly related to VR arm movements
	-- Does not happen for the host, does not happen on late joiners
	-- Does not happen for flat-screen clients
	if not self:current_state() then
		return
	end
	
	if self:current_state().__bttn_ducking then
		local height_mult = VRPlusMod._data.comfort.crouch_scale / 100
		local crouch_dist = managers.vr:get_setting("height") * (1 - height_mult)
		mvector3.set_z(pos, pos.z - crouch_dist)
	end
end
