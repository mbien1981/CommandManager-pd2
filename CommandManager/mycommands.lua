-- Here is where you place your own commands, you shouldnt replace/delete this file in updates.
if rawget(_G, "CommandManager") then
	function CommandManager:external_commands(message, peer_id)
		self.invis_player = false
		local args = {}
		local ret

		if not self:prefixes(message) or string.len(message) == 1 then
			return
		end

		-- args setup
		for cmd_args in string.sub(message,2):gsub("^.-%s", "", 1):gmatch("%S+") do
			table.insert(args, cmd_args)
		end

		-- your commands
		if self:HostCMD("host") then
			ret = "Hello, Host!"
		end

		if self:Command("test") then
			ret = "Hello, World!"
		end

		if self:HostCMD("meth") then
			if self:is_playing() then
				for _, script in pairs(managers.mission:scripts()) do
					for _, element in pairs(script:elements()) do
						if element._editor_name == "show_endproduct" or element._editor_name == "show_meth" then
							CommandManager:trigger_mission_element(element._id)
						end
					end
				end
				ret = "Meth Spawned."
			else
				ret = "You must be in-game and playing to do that."
			end
		end

		if self:Command("reload") then
			dofile("mods/commandmanager/handlers/commandmanager.lua")
			ret = "reloaded!"
		end

		-- ret message setup
		if self.retMessage and ret then
			self:Send_Message(peer_id, ret)
			ret = nil
		end
	end
end