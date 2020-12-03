local orig_send = ChatManager.send_message
function ChatManager:send_message(channel_id, sender, message)
	if managers.network:session() then
		sender = managers.network:session():local_peer()
		if rawget(_G, "CommandManager") then
			if CommandManager:prefixes(message) and sender then
				if sender then
					CommandManager:process_input(message, sender:id())
					return
				end
			end
		end
		orig_send(self, channel_id, sender, message)
	end
end

local orig_receive = ChatManager.receive_message_by_peer
function ChatManager:receive_message_by_peer(channel_id, peer, message)
	if rawget(_G, "CommandManager") then
		if message:sub(1, 11) == "[PRIVATE]: " then
			CommandManager.peer_to_reply = peer
		end
	end

	orig_receive(self, channel_id, peer, message)
end

ChatGui.selected_command = 0
local orig = ChatGui.key_press
function ChatGui:key_press(o, k)
	orig(self, o, k)

	local text = self._input_panel:child("input_text")
	if self._key_pressed == Idstring("up") then
		self.selected_command = (self.selected_command + 1) % (#CommandManager.history + 1)
		local _text = CommandManager.history[self.selected_command] or ''

		text:set_text(_text)
	elseif self._key_pressed == Idstring("down") then
		self.selected_command = ( self.selected_command - 1 ) % -1

		local _text = CommandManager.history[self.selected_command] or ''
		text:set_text(_text)
	elseif (self._key_pressed == Idstring("enter")) or (self._key_pressed == Idstring("escape")) then
		self.selected_command = 0
		text:set_text('')
	end
end