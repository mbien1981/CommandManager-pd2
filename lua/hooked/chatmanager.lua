local orig_send = ChatManager.send_message
function ChatManager:send_message(channel_id, sender, message)
	if channel_id ~= 1 then
		return
	end

	sender = managers.network:session():local_peer()

	local CM = _G["CommandManager"]
	if CM then
		if CM:validPrefix(message:sub(1, 1)) and sender then
			CM:process_input(message, sender)
			return
		end
	end

	orig_send(self, channel_id, sender, message)
end

local orig_receive = ChatManager.receive_message_by_peer
function ChatManager:receive_message_by_peer(channel_id, peer, message)
	orig_receive(self, channel_id, peer, message)

	local CM = _G["CommandManager"]
	if CM then
		if peer:id() ~= CM:local_peer():id() then
			if CM:validPrefix(message:sub(1, 1)) then
				CM:process_input(message, peer)
			else
				if channel_id == 1 and CM.enable_translator then
					CM:translate(message, "auto", "en", false)
				end
			end
		end

		if message:sub(1, 11) == "[PRIVATE]: " then
			CM.peer_to_reply = peer

			CM:message(string.format("Received private message from %s, use /re to do reply.", peer:name()), "*")
			CM:message(message:sub(12), "*", Color("1E90FF"))
			return
		end
	end
end
