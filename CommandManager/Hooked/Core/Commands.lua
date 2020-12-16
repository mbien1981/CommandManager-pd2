local ret
function string.empty(s)
	return s == nil or s == ''
end

--* Loading Aliases from config file *--
CommandManager.commands	= {
	prv	= {
		aliases	= {
			"dm", "pm"
		},
		callback = function(args)
			local exist, peer = CommandManager:get_peer(args[1])
			if exist then
				local text = ""
				for i, msg in pairs(args) do
					if (i ~= 1) then -- peer id
						text = string.format("%s %s", text, msg)
					end
				end
	
				CommandManager:send_message(peer:id(), string.format("[PRIVATE]: %s", text))
				ret = string.format("Private Message Sent.\nTarget: %s,\nText: %s", peer:name(), text)
			end
			return ret
		end
	},
	r	= {
		callback = function(args)
			CommandManager:process_input(CommandManager.history[1])
		end
	},
	re	= {
		callback	= function(args)
			local peer = CommandManager.peer_to_reply
			if (peer and peer) then
				local text = ""
				for i, msg in pairs(args) do
					text = string.format("%s %s", text, msg)
				end

				CommandManager:send_message(peer:id(), string.format("[PRIVATE]: %s", text))
				return string.format("Quick reply sent.\nTarget: %s,\nText: %s", peer:name(), text)
			end
		end
	}
}

--* Loading aliases from predefined commands *--
for _, data in pairs(CommandManager.commands) do
	if data.aliases then
		for _, alias in pairs(data.aliases) do
			CommandManager.commands[alias] = data
		end
	end
end

--* Loading aliases from config file *--
for cmd, aliases in pairs(CommandManager.aliases) do
	local command = CommandManager.commands[cmd]
	if command then
		for _, alias in pairs(aliases) do
			CommandManager.commands[alias] = command
		end
	end
end

function CommandManager:process_command(input)
	local lower_cmd = string.match(string.sub(input, 2):lower(), "(%w+)")
	local args = {}
	if self.commands and self.commands[lower_cmd] then
		local command = self.commands[lower_cmd]
		for arg in string.sub(input, 2):gsub("^.-%s", "", 1):gmatch("%S+") do
			table.insert(args, arg)
		end

		if #args == 1 and args[1] == lower_cmd then
			args[1] = nil
		end

		if command.host and ( not Network:is_server() ) then
			self:mesasge("Host only!", lower_cmd)
			return false
		end

		if (command.in_menu and command.in_game)
			or command.in_menu and ( not self:in_game() )
			or command.in_game and ( self:is_playing() )
			or ( (not command.in_menu) and ( not command.in_game))
		then
			if command.callback and type(command.callback) == "function" then
				self:message(command.callback(args), lower_cmd)
			end
		end

		return true
	end

	return false
end

function CommandManager:process_input(input)
	if string.empty(input) then
		return
	end

	if self:process_command(input) then
		if string.sub(input, 2) ~= "r" then
			table.insert(self.history, 1, input)
		end
	end
end

--* Load aliases from config file for custom commands *--
function CommandManager:CheckAliases(command)
	local aliases = self.aliases[command]
	local command = self.commands[command]
	if (aliases and command) then
		for _, alias in pairs(aliases) do
			CommandManager.commands[alias] = command
		end
	end
end

function CommandManager:add_command(command_name, data)
	if self.commands[command_name] then
		return
	end

	self.commands[command_name] = data

	self:CheckAliases(command_name)
	if data.aliases then
		for _, alias in pairs(data.aliases) do
			self.commands[alias] = data
		end
	end
end
