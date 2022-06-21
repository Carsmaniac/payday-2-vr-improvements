
local old_update = HandMelee.update
function HandMelee:update(unit, t, dt)
	local mode = VRPlusMod._data.tweaks.weapon_melee

	if mode ~= VRPlusMod.C.WEAPON_MELEE_ENABLED and self:has_weapon() then
		if mode ~= VRPlusMod.C.WEAPON_MELEE_LOUD or managers.groupai:state():whisper_mode() then
			return
		end
	end

	return old_update(self, unit, t, dt)
end
