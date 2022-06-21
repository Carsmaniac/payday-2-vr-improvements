--
-- Created by IntelliJ IDEA.
-- User: znix
-- Date: 7/21/18
-- Time: 10:40 AM
-- To change this template use File | Settings | File Templates.
--

-- Make sure this is loaded, even if we're not in VR
-- AFAIK there are no side-effects of loading it that could be a problem

local env = {}
VRPlusMod._ControlManager = env
setmetatable(env, {
	__index = _G
})
env._G = env
env.__G = _G
env.ModPath = _G.ModPath
env.ModInstance = _G.ModInstance

function env.dofile(name)
	local path = env.ModPath .. "menus/controls/" .. name
	local file = io.open(path)
	assert(file, "Missing file " .. name)
	local code = file:read("*all")
	file:close()
	local func = loadstring(code, path)
	setfenv(func, env)
	return func()
end

env.dofile("Data.lua")
env.dofile("RadioButton.lua")
env.dofile("BindButton.lua")
env.dofile("MainMenu.lua")
