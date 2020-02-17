if rawget(_G, "CommandManager") then
	function CommandManager:CommandHandler(message, peer_id)
		local peername = managers.network:session():peer(peer_id):name()
		local peeruserid = managers.network:session():peer(peer_id):user_id()
		local lpeer_id = managers.network:session():local_peer():id()
		local unit = managers.network:session():peer(peer_id):unit()
		local lunit = managers.player:player_unit()
		local args = {}
		local ret

		if not peername then 
			return 
		end

		-- prefix check
		if not self:prefixes(message) or string.len(message) == 1 then
			return
		end

		if peer_id == lpeer_id then
			table.insert(self.history, 1, message)
		end
		
		-- commands
		local command = string.sub(message, 2):lower()
		self.cmd = string.match(command, "(%w+)")

		for cmd_args in command:gsub("^.-%s", "", 1):gmatch("%S+") do -- setup command args
			table.insert(args, cmd_args)
		end

		--Send a private message to a player
		if self:Command("dm") or self:Command("prv") then
			if peer_id == lpeer_id then
				if managers.network:session():peer(tonumber(args[1])) then
					local peername = managers.network:session():peer(tonumber(args[1])):name()
					if peername then
						local text = ""
						for i, msg in pairs(args) do 
							if i ~= 1 then 
								text = string.format("%s %s", text, args[i])
							end 
						end
						self:Send_Message(tonumber(args[1]), string.format("[PRIVATE]: %s", text))
						ret = string.format("Private Message sent to %s.", peername)
					end
				end
			end
		end

		if self:Command("example") then
			local cmd = args[1] or "example"
			if self.help[cmd] and self.help[cmd].example then
				ret = self.help[cmd].example
			end
		end

		if self:Command("help") then
			local cmd = args[1]
			if self.help[cmd] then
				ret = self.help[cmd].description
			end
		end

		if self:Command("ids") or self:Command("peers") then
			local ids = self:get_peers("*")
			local list = ""
			if ids then
				for _, id in pairs(ids) do
					local peer = managers.network:session():peer(id)
					list = string.format("%s\n(%s) %s\n", list, peer:id(), peer:name())
				end
			end
			ret = string.format("Player List:\n%s", list)
		end

		if self:Command("profile") or self:Command("prf") then
			if peer_id == lpeer_id then
				local peerid = tonumber(args[1])
				local peer = managers.network and managers.network:session():peer(peerid)
				if peer then
					Steam:overlay_activate("url", string.format("http://steamcommunity.com/profiles/%s/", peer._user_id))
				end
			end
		end

		if self:Command("list") then
			local list = ""
			for key, value in pairs(self.help) do
				list = list..key..", "
			end
			ret = string.format("List of commands: %s", list)
		end

		if self:HostCMD("meth") then
			if self:is_playing() then
				for _, script in pairs(managers.mission:scripts()) do
					for _, element in pairs(script:elements()) do
						if element._editor_name == "show_endproduct" or element._editor_name == "show_meth" then
							CommandManager:trigger_mission_element(element._id)
							ret = "Meth Spawned"
						end
					end
				end
			end
		end
		
		if self:Command("state") then
			local ids = self:get_peers(args[1], true)
			if ids then
				for _, id in pairs(ids) do
					local peer = managers.network:session():peer(id)
					if peer and alive(peer:unit()) and peer:id() ~= lpeer_id then
						unit = peer:unit()
						unit:network():send("sync_player_movement_state", args[2], 0, unit:id())
					end
				end
				ret = string.format("'%s' status has been set for '%s'", args[2], args[1])
			end
		end
		
		if self:Command("time") then
			if self:is_playing() then
				for id,unit in pairs(World:find_units_quick("all", 1)) do
					local timer = unit:base() and unit:timer_gui() and unit:timer_gui()._current_timer
					if timer and math.floor(timer) ~= -1 then
						local newvalue = tonumber(args[1]) or 300
						unit:timer_gui():_start(newvalue)
						
						if managers.network:session() then
							managers.network:session():send_to_peers_synched("start_timer_gui", unit:timer_gui()._unit, newvalue)
						end
						
						if not unit:timer_gui()._jammed then
							unit:timer_gui():set_jammed(true)
						end
					end
				end
			end
		end
		
		if self.retMessage and ret then
			self:Send_Message(peer_id, ret)
			ret = nil
		end
	end
end