-- Here is where you place your own commands, you shouldnt replace/delete this file in updates.
if rawget(_G, "CommandManager") then
	function CommandManager:external_commands(message, peer_id)
		local lunit = managers.player:player_unit()
		local args = {}
		local ret

		if not self:prefixes(message) or string.len(message) == 1 then
			return
		end

		-- args setup
		for cmd_args in string.sub(message,2):gsub("^.-%s", "", 1):gmatch("%S+") do
			table.insert(args, cmd_args)
		end

		if self:HostCMD("host") then
			ret = "Hello, Host!"
		end

		if self:Command("test") then
			ret = "Hello, World!"
		end

		if self:Command("reload") then
			dofile("mods/CommandManager/lua/src/CommandManager")
			ret = "reloaded!"
		end

		-- ret message setup
		if self.retMessage and ret then
			self:Send_Message(peer_id, ret)
			ret = nil
		end
	end
end