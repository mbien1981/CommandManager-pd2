if rawget(_G, "CommandManager") then
	rawset(_G, "CommandManager", nil)
end

if not rawget(_G, "CommandManager") then
	rawset(_G, "CommandManager", {
		_path = ModPath .. "lua/",
		_script_path = ModPath .. "lua/scripts/",
		_prefixes = {
			["\\"] = true,
			["/"] = true,
			["$"] = true,
			["!"] = true,
			["."] = true,
			[","] = true,
		},
		commands = {},
		enable_translator = true,
	})

	function CommandManager:validPrefix(prefix)
		return self._prefixes[prefix]
	end

	function CommandManager:import(script)
		dofile(self._script_path .. script)
	end

	function CommandManager:message(text, title, color, sync)
		if sync then
			managers.chat:send_message(ChatManager.GAME, nil, text)

			return
		end

		if text and type(text) == "string" then
			color = not color and tweak_data.system_chat_color or color

			managers.chat:_receive_message(1, (title or "*"), text, color)
		end
	end

	function CommandManager:send_message(peer_id, message)
		if not message or (message == "") then
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

	function CommandManager:is_local(peer)
		return self:local_peer():id() == peer:id()
	end

	function CommandManager:peer(id)
		return managers.network:session():peer(tonumber(id))
	end

	function CommandManager:local_peer()
		return managers.network:session():local_peer()
	end

	function CommandManager:get_peer_by_name(name)
		for _, peer in pairs(managers.network:session():peers()) do
			if peer:name() == name then
				return peer
			end
		end

		return nil
	end

	function CommandManager:peer_list()
		local peers = {}
		for _, peer in pairs(managers.network:session():peers()) do
			if peer then
				table.insert(peers, peer)
			end
		end

		return peers
	end

	function CommandManager:urlencode(url)
		if url == nil then
			return
		end

		local char_to_hex = function(c)
			return string.format("%%%02X", string.byte(c))
		end

		url = url:gsub("\n", "\r\n")
		url = url:gsub("([^%w ])", char_to_hex)
		url = url:gsub(" ", "+")
		return url
	end

	function CommandManager:translate(text, from, to, sync)
		local api_url = "http://translate.googleapis.com/translate_a/single?client=gtx&sl=%s&tl=%s&dt=t&q=%s"
		local url = string.format(api_url, from, to, self:urlencode(text))

		local blacklist = {
			["en"] = true,
			["es"] = true,
		}

		result = {}
		dohttpreq(url, function(data)
			local json_data = json.decode(data)
			if not json_data then
				return
			end

			local translation = json_data[1][1][1]

			if type(translation) ~= "string" then
				return
			end

			if sync then
				managers.chat:send_message(ChatManager.GAME, nil, translation)
			else
				if blacklist[json_data[2]] then
					return
				end

				self:message(translation, "*", Color("1E90FF"))
			end
		end)
	end

	--* setup command aliases
	for cmd_name, cmd_data in pairs(CommandManager.commands) do
		if not cmd_data.aliases then
			goto next
		end

		for _, alias in pairs(cmd_data.aliases) do
			CommandManager.commands[alias] = deep_clone(data)
			CommandManager.commands[alias].is_alias = true
			CommandManager.commands[alias].parent = cmd_name
		end

		::next::
	end

	function CommandManager:process_command(input, sender)
		sender = sender or self:local_peer()

		local lower_cmd = string.match(input:sub(2):lower(), "(%w+)")

		local command = self.commands and self.commands[lower_cmd]
		if not command then
			return false
		end

		local args = {}
		input:gsub("([^%s]+)", function(word)
			if not next(args) and word:sub(2) == lower_cmd then
				return
			end

			table.insert(args, word)
		end)

		if command.private and not self:is_local(sender) then
			self:send_message(sender:id(), "You do not have permission to use this command.")
			return false
		end

		if command.host and Network:is_client() then
			self:message("Host only!", lower_cmd)

			return false
		end

		if command.callback and type(command.callback) == "function" then
			self:message(command.callback(args, sender), lower_cmd, Color("1E90FF"), not self:is_local(sender))
		end

		return true
	end

	function CommandManager:process_input(input, sender)
		if input == "" then
			return
		end

		if self:process_command(input, sender) then
			-- if string.sub(input, 2) ~= "r" then
			-- 	table.insert(self.history, 1, input)
			-- end
			return
		end
	end

	function CommandManager:add_command(command_name, cmd_data)
		self.commands[command_name] = cmd_data

		if cmd_data.aliases then
			for _, alias in pairs(cmd_data.aliases) do
				self.commands[alias] = deep_clone(cmd_data)
				self.commands[alias].is_alias = true
				self.commands[alias].parent = command_name
			end
		end
	end

	--* load user commands
	dofile(CommandManager._path .. "commands.lua")
end
