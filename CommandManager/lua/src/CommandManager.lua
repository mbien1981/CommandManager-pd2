if rawget(_G, "CommandManager") then -- this allows us to reload the script in case we made some changes in-game.
	if not CommandManager:in_chat() then
		rawset(_G, "CommandManager", nil)
	end
end

if not rawget(_G, "CommandManager") then
	rawset(_G, "CommandManager", {})

	-- CommandManager settings.
	CommandManager.command_prefixes = {"!", "/", "."} -- Command prefixes, must be 1 char length
	CommandManager.history = {}
	CommandManager.retMessage = true
	CommandManager.cmd = nil
	CommandManager.help = {
		["dm"]      = { description = "Send a private message to a player.\n\nThis command can also be executed as /prv", example = "/dm player_id [your message]" },
		["example"] = { description = "Show the example of any command, use /example command_name", example = "/example dm" },
		["help"] = { description = "General info, use /help command_name to get the info about any command from this mod, use /list to get a full list of commands", example = "/help list" },
		["list"]    = { description = "Show a list of commands.", example = "/list" },
		["meth"]    = { description = "Spawn meth to pick up in any heist where there's a meth lab available except lab rats.", example = "/meth" },
		["peers"]   = { description = "Display a list of players and their respective ID.\n\nThis command an also be executed as [ids]", example = "/peers" },
		["profile"] = { description = "Open a specified player's steam profile in the game overlay.\n\nThis command can also be executed as /prf", example = "/profile 1" },
		["state"]   = { description = "Change a player's current state.\n\nList of Valid States:\narrested,tased,incapacitated,bleed_out,standard", example = "/state player_id state_name\n\n/state 2 tased" },
		["time"]    = { description = "Set all currently working Drills/saws/hacking devices remaining time to a specified value in seconds.", example = "/time 20" }
	}

	function CommandManager:prefixes(str)
		for _, prefix in pairs(self.command_prefixes) do
			if string.sub(str, 1, 1) == prefix then
				return true
			end
		end
	end
	
	function CommandManager:trigger_mission_element(element_id)
		local player = managers.player:player_unit()
		if not player or not alive(player) then
			return
		end
	
		for _, data in pairs(managers.mission._scripts) do
			for id, element in pairs(data:elements()) do
				if id == element_id then
					if Network:is_server() then
						element:on_executed(player)
					end
					break
				end
			end
		end
	end

	function CommandManager:in_game()
		if not game_state_machine then
			return false
		else
			return string.find(game_state_machine:current_state_name(), "game")
		end
	end

	function CommandManager:in_chat()
		if managers.hud and managers.hud._chat_focus == true then
			return true
		end
	end

	-- check if you are playing
	function CommandManager:is_playing()
		return BaseNetworkHandler._gamestate_filter.any_ingame_playing[game_state_machine.last_queued_state_name(game_state_machine)]
	end
	
	-- check if you are hosting the game
	function CommandManager:is_host()
		return Network:is_server()
	end

	-- get a list with all the players connected
	function CommandManager:get_peers(code, unitcheck)
		-- '*' returns all players
		-- '?' returns a random player
		-- '!' returns a random player except local (you)
		local peerid = tonumber(code)
		local me = managers.network:session():local_peer():id()
		
		if not peerid or peerid and (peerid < 1 or peerid > 4) then
			local tab = {}
	
			for x = 1, 4 do
				if managers.network:session():peer(x) then
					if not unitcheck or (unitcheck and managers.network:session():peer(x):unit()) then
						table.insert(tab, x)
					end
				end
			end
			
			if code == "*" then -- everyone
				return tab
			elseif code == "?" then -- random
				peerid = tab[math.random(1, #tab)]
			elseif code == "!" then -- anyone except self
				table.remove(tab, me)
				peerid = tab
			else -- self
				peerid = me
			end
			tab = nil
		end
	
		if peerid and managers.network:session():peer(peerid) then
			if not unitcheck or (unitcheck and managers.network:session():peer(peerid):unit()) then
				return {peerid}
			end
		end
	
		return
	end

	-- Send a message to a player
	function CommandManager:Send_Message(peer_id, message)
		if not message or message == "" then
			return
		end

		local peer = managers.network:session():peer(peer_id)

		if peer_id == managers.network:session():local_peer():id() then 
			managers.chat:feed_system_message(ChatManager.GAME, message)
		else
			if peer then
				managers.network:session():send_to_peer(peer, "send_chat_message", 1, message)
			end
		end
	end

	-- Check Command
	function CommandManager:Command(command)
		if self.cmd == command then
			return true
		end
	end
	
	-- Commands that only works as host
	function CommandManager:HostCMD(command)
		if self.cmd == command then
			if self:is_host() then
				return true
			else
				managers.chat:_receive_message(1, command, "Host Only!", tweak_data.system_chat_color)
				return false
			end
		end
	end

	dofile("mods/CommandManager/lua/src/Commands.lua")
	dofile("mods/CommandManager/lua/CustomCommands.lua")
end