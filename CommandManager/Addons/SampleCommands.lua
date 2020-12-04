local C = CommandManager

-- repeat last used command
C:add_command("r", {
	callback = function(args)
		C:process_input(C.history[1])
	end
})

C:add_command("prv", {
	callback = function(args)
		local exist, peer = C:get_peer(args[1])
		if exist then
			local text = ""
			for i, msg in pairs(args) do
				if i ~= 1 then
					text = string.format("%s %s", text, msg)
				end
			end

			C:send_message(peer, string.format("[PRIVATE]: %s", text))
			ret = string.format("Private Message sent to %s.", managers.network:session():peer(peer):name())
		end
		return ret or tostring(exist)
	end
})

-- Quick reply to a private message
C:add_command("re", {
	callback = function(args)
		if C.peer_to_reply then
			local text = ""
			for i, msg in pairs(args) do
				text = string.format("%s %s", text, msg)
			end

			C:send_message(C.peer_to_reply:id(), string.format("[PRIVATE]: %s", text))
			return string.format("Private Message sent to %s.", C.peer_to_reply:name())
		end
	end
})


C:add_command("test", {
	callback = function()
		return "Hello, World!"
	end,
	host	= false,
	in_game	= true,
	in_menu	= true
})