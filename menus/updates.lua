--[[
	Custom update system.

	Hook into BLT to download from our server. Not a very nice thing
	to do, but until I get a paydaymods account this is the easiest/quickest
	way.

	This is based around having a "custom_urls" tag in the update data, that
	should contain three items: check, patchnotes, and download

	These are URLs that are suffixed with the mod ID and used to fetch stuff.
]]

-- Check for an outdated DLL that doesn't support HTTPS, breaking updating/update checks
local old_update_check = BLTModManager._RunAutoCheckForUpdates
function BLTModManager:_RunAutoCheckForUpdates()
	old_update_check(self)

	-- Don't bother checking if we're using SuperBLT, as we might not
	--   be using IPHLPAPI in which case this will cause a crash otherwise
	local dll_hash = XAudio and "SuperBLT" or file.FileHash("IPHLPAPI.dll")

	local outdated = {
		"8b110f1cf2802f7eb28a179871998e57dd5b053c1304187a7aa4cb40449cb5fc", -- 2.0VR5
		"2da0ae2df2985b7b883e150b1cf691bf6bb333bef51d8cef98e9f73503057450", -- 2.0VR4
		"c9a4f75f32b699f4d752a205c7c57c713c5159b14b4035fefeff0159852908b1", -- 2.0VR3

		-- The following shouldn't work, but incase ovk changes luaL_newstate and they start working in the future
		"790713453ef81f0494ea51f42e91f061c11f12cd09a556c6db9687d6135261f0", -- 2.0VR2
		"73352aae9639eb73180f0ec9f64975d0804abdb1a0babdf99140f34489a636d0" -- 2.0VR1
	}

	local text = function(str) return managers.localization:text(str) end

	for _, hash in ipairs(outdated) do
		if hash == dll_hash then
			local options = {
				{
					text = text("vrplus_dll_out_of_date_download"),
					callback = function()
						os.execute("cmd /c start http://steamcommunity.com/groups/payday-2-vr-mod/discussions/0/2425614361138298439/")
					end
				},
				{
					text = text("vrplus_dll_out_of_date_continue"),
					is_cancel_button = true,
				}
			}
			local menu = QuickMenu:new(
				text("vrplus_dll_out_of_date"),
				text("vrplus_dll_out_of_date_message"),
				options
			)
			menu:Show()
		end
	end

	-- The mod being in the wrong folder breaks updates, leaving them hanging at 'verifying'
	if VRPlusMod._path ~= "mods/vrplus/" then
		QuickMenu:new(
			text("vrplus_wrong_mod_name"),
			text("vrplus_wrong_mod_name_message"),
			{} -- Default 'ok' button
		):Show()
	end

	VRPlusMod:OnMenusReady()
end

local function reload_updates()
	-- Mods get loaded before us, so patch in a new set of updates
	-- Nothing will have used the updates before this runs, though, so it's safe.
	for _, mod in pairs(BLT.Mods:Mods()) do
		local dll_id

		for i, update in ipairs(mod.updates) do
			local update_data = mod.json_data["updates"][i]

			if update:GetId() == "payday2bltdll" then
				dll_id = i -- Remove their DLL update, as we use our own
			elseif update_data["custom_urls"] then
				local new_update = BLTUpdate:new( mod, update_data )
				new_update:SetEnabled(update:IsEnabled())
				mod.updates[i] = new_update
			end
		end

		-- Don't stuff with the updates if SuperBLT is loaded, as it has a VR-compatible DLL
		if dll_id and not _G.XAudio then
			table.remove(mod.updates, dll_id)
		end
	end
end

-- BLTUpdate
local old_init = BLTUpdate.init
function BLTUpdate:init(parent_mod, data)
	old_init(self, parent_mod, data)
	self._custom_urls = data["custom_urls"]
end

local old_CheckForUpdates = BLTUpdate.CheckForUpdates
function BLTUpdate:CheckForUpdates( clbk )
	-- Unless the mod uses custom URLs, use the default one
	local data = self._custom_urls
	if not data then
		return old_CheckForUpdates(self, clbk)
	end

	-- Flag this update as already requesting updates
	self._requesting_updates = true

	-- Perform the request from the server
	local url = data.check .. self:GetId()
	dohttpreq( url, function( json_data, http_id )
		self:clbk_got_update_data( clbk, json_data, http_id )
	end)
end

local old_ViewPatchNotes = BLTUpdate.ViewPatchNotes
function BLTUpdate:ViewPatchNotes()
	-- Unless the mod uses custom URLs, use the default one
	local data = self._custom_urls
	if not data then
		return old_ViewPatchNotes(self)
	end

	local url = data.patchnotes .. self:GetId()
	if Steam:overlay_enabled() then
		Steam:overlay_activate( "url", url )
	else
		os.execute( "cmd /c start " .. url )
	end
end

-- BLTDownloadManager
local old_start_download = BLTDownloadManager.start_download
function BLTDownloadManager:start_download( update )
	-- Unless the mod uses custom URLs, use the default one
	local data = update._custom_urls
	if not data then
		return old_start_download(self, update)
	end

	-- Check if the download already going
	if self:get_download( update ) then
		log(string.format("[Downloads] Download already exists for %s (%s)", update:GetName(), update:GetParentMod():GetName()))
		return false
	end

	-- Check if this update is allowed to be updated by the download manager
	if update:DisallowsUpdate() then
		MenuCallbackHandler[ update:GetDisallowCallback() ]( MenuCallbackHandler )
		return false
	end

	-- Start the download
	local url = data.download .. update:GetId()
	local http_id = dohttpreq( url, callback(self, self, "clbk_download_finished"), callback(self, self, "clbk_download_progress") )

	-- Cache the download for access
	local download = {
		update = update,
		http_id = http_id,
		state = "waiting"
	}
	table.insert( self._downloads, download )

	return true
end

reload_updates()
