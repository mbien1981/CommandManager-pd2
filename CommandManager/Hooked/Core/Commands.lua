function string.empty(s)
	return s == nil or s == ''
end

CommandManager.commands = {}
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

function CommandManager:add_command(command_name, data)
	if self.commands[command_name] then
		return
	end

	self.commands[command_name] = data
end