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

		if self:Command("h") or self:Command("help") then
			local index = args[1] or "help"
			local page = tonumber(index)
			if page then
				if page == 1 then
					self:Send_Message(peer_id, string.format("To get info about the next commands you must use help followed by the command name.\n\nExample: %shelp timers", self.command_prefixes[2]))
				end
				if page <= #self.cmd_list then
					ret = string.format("page %d of %d\n%s", page, #self.cmd_list, self.cmd_list[page])
				end
			else
				for _, cmd in pairs(self.cmd_info) do
					if index == cmd.id then
						ret = string.format(cmd.text, self.command_prefixes[2])
						break
					end
				end
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

		if self:Command("inf") then
			local ids = self:get_peers(args[1], true)
			if ids then
				for _, id in pairs(ids) do
					local peer = managers.network:session():peer(id)
					if peer and alive(peer:unit()) and peer:id() ~= lpeer_id then
						local unit = peer:unit()
						if peer.inf_tase == nil then -- start loop
							peer.inf_tase = true
							for i = 1, 100 do
								managers.enemy:add_delayed_clbk("_"..i, function()
									if peer and peer.inf_tase and alive(peer:unit()) then
										unit:network():send("sync_player_movement_state", "standard", 0, unit:id())
										unit:network():send("sync_player_movement_state", "tased", 0, unit:id())
									end
								end, Application:time() + (9 * i))
							end
							ret = string.format("tasing %s, use stop command to stop the loop.", peer:name())
						else -- resume loop
							peer.inf_tase = true
							ret = "loop resumed!"
						end
					end
				end
			end
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

		if self:Command("say") then
			local text = ""
			for i, msg in pairs(args) do 
				text = string.format("%s %s", text, args[i])
			end
			managers.chat:send_message( 1, managers.network:session():local_peer(), text )
		end
		
		if self:Command("state") then
			local ids = self:get_peers(args[1], true)
			if ids then
				for _, id in pairs(ids) do
					local peer = managers.network:session():peer(id)
					if peer and alive(peer:unit()) and peer:id() ~= lpeer_id then
						unit = peer:unit()
						unit:network():send("sync_player_movement_state", args[2], 0, unit:id())
						ret = string.format("%s's status has been changed to %s", peer:name(), args[2])
					end
				end
			end
		end

		if self:Command("stop") then -- stop a player from being tased
			local ids = self:get_peers(args[1], true)
			if ids then
				for _, id in pairs(ids) do
					local peer = managers.network:session():peer(id)
					if peer:id() ~= lpeer_id then
						if peer and alive(peer:unit()) and peer.inf_tase then
							peer.inf_tase = false
						end
						ret = string.format("loop paused for %s", peer:name())
					end
				end
			end
		end
		
		if self:Command("time") then
			if self:is_playing() then
				for _,unit in pairs(World:find_units_quick("all", 1)) do
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