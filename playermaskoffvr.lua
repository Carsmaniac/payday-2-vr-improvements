--[[
	PlayerStandardVR

	Allow movement while not masked up
--]]

local old_update_check_actions = PlayerMaskOff._update_check_actions
function PlayerMaskOff:_update_check_actions(t, dt)
	-- _update_check_actions overwrites _move_dir, breaking movement
	local move_dir = self._move_dir -- Save
	old_update_check_actions(self, t, dt)
	self._move_dir = move_dir -- Load
end
