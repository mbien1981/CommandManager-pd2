if rawget(_G, "CommandManager") then -- this allows us to reload the script in case we made some changes in-game.
	rawset(_G, "CommandManager", nil)
end

-- Note: loops cannot be stopped yet, I'm still working on a fix for that

if not rawget(_G, "CommandManager") then
	rawset(_G, "CommandManager", {})

	dofile("mods/commandmanager/commands.lua")
	dofile("mods/commandmanager/mycommands.lua")

	-- CommandManager settings.
	CommandManager.command_prefixes = {"!", "/", "."} -- Command prefixes, must be 1 char length
	CommandManager._calls = {}
	CommandManager.history = {}
	CommandManager.retMessage = true
	CommandManager.cmd = nil
	CommandManager.cmd_list = {
		"| help | peers | state | profile |",
		"| prv | inf | stop | timers | meth |"
	}
	CommandManager.cmd_info = {
		{id = "peers", text= "Display a list of players and their respective ID.\n\nThis command an also be executed as [ids]\n\nExample: %speers"},
		{id = "state", text = "This command changes a player's current state, you must specify the player's id [check peers command for more info] and the state.\n\nList of valid states:\nstandard,arrested,incapacitated,bleed_out\n\nExample: %state 1 tased"},
		{id = "prv", text = "This command sends a private message to a player, you must specify the player id."},
		{id = "profile", text = "This command opens a player steam profile in the steam UI, only works for the person who has the mod.\n\n This comand can also be executed as [prf]\n\nExample: %sprofile 4"},
		{id = "timers", text = "This command returns the timer from all devices/dills\n\nUse: %stime"},
		{id = "time", text = "This command will change all the current drills/devices timer to a specified amount of seconds.\n\nExample: %stimers 50"},
		{id = "inf", text = "This command sets a player state to tased for an unlimited amount of time, you can stop the loop with the stop command.\n\nExample: %sinf 2"},
		{id = "help", text = "This command returns info about the commands from this mod.\n\nYou must specify the command or page.\n\nExample: %shelp 1"},
		{id = "stop", text = "This command stops the infinite tase from a player.\n\nExample: %sstop 2"},
		{id = "meth", text = "This command spawns meth to pick up, the player who has the mod must be the server host.\n\nUse: %smeth"}
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
					else
						managers.network:session():send_to_host("to_server_mission_element_trigger", id, player)
					end
					break
				end
			end
		end
	end

	-- check if you are in-game
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
					if  not unitcheck or unitcheck and managers.network:session():peer(x):unit() then
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
				peerid = tab[math.random(1, #tab)]
			else -- self
				peerid = me
			end
	
			tab = nil
		end
	
		if peerid and managers.network:session():peer(peerid) then
			if not unitcheck or unitcheck and managers.network:session():peer(peerid):unit() then
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
	
	-- Command that only works as host
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

	function CommandManager:Update(time, deltaTime)
		local t = {}
		for _, v in pairs( self._calls ) do
			if v ~= nil then
				v.currentTime = v.currentTime + deltaTime
				if v.currentTime >= v.timeToWait then

					if v.functionCall then
						v.functionCall()
					end

					if v.loop then
						v.currentTime = 0
						table.insert(t, v)
					else
						v = nil
					end
				else
					table.insert(t, v)
				end
			end
		end
		self._calls = t
	end

	function CommandManager:Add(id, time, func, sloop)
		local queuedFunc = {
			functionCall = func,
			timeToWait = time,
			currentTime = 0,
			loop = (sloop or false)
		}
		self._calls[id] = queuedFunc
	end

	function CommandManager:Remove( id )
		self._calls[id] = nil
	end

end

