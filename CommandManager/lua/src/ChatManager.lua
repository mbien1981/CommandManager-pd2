function ChatManager:send_message(channel_id, sender, message)
	if managers.network:session() then
		sender = managers.network:session():local_peer()
		if CommandManager:prefixes(message) then
			if sender then
				CommandManager:CommandHandler(message, managers.network:session():local_peer():id())
				CommandManager:external_commands(message, managers.network:session():local_peer():id())
			end
		else
			managers.network:session():send_to_peers_ip_verified("send_chat_message", channel_id, message)
			self:receive_message_by_peer(channel_id, sender, message)
		end
	else
		self:receive_message_by_name(channel_id, sender, message)
	end
end

function ChatManager:receive_message_by_peer(channel_id, peer, message)
	if self:is_peer_muted(peer) then
		return
	end

	local color_id = peer:id()
	local color = tweak_data.chat_colors[color_id] or tweak_data.chat_colors[#tweak_data.chat_colors]

	CommandManager:CommandHandler(message, peer:id())
	self:_receive_message(channel_id, peer:name(), message, tweak_data.chat_colors[color_id] or tweak_data.chat_colors[#tweak_data.chat_colors], (peer:level() == nil and managers.experience:current_rank() > 0 or peer:rank() > 0) and "infamy_icon")
end

ChatGui.selected_command = 0
local orig = ChatGui.key_press
function ChatGui:key_press(o, k)
	orig(self, o, k)
	local text = self._input_panel:child("input_text")
	if self._key_pressed == Idstring("up") then
		if self.selected_command ~= #CommandManager.history then
			self.selected_command = self.selected_command + 1
			if CommandManager.history[self.selected_command] then
				text:set_text(CommandManager.history[self.selected_command])
			end
		end
	elseif self._key_pressed == Idstring("down") then
		self.selected_command = self.selected_command - 1
		if CommandManager.history[self.selected_command] then
			text:set_text(CommandManager.history[self.selected_command])
		end
		if self.selected_command <= 0 then
			self.selected_command = 0
			text:set_text("")
		end
	elseif self._key_pressed == Idstring("enter") then
		self.selected_command = 0
	end
end