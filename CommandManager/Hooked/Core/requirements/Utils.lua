function string.startswith(String, Start)
	return string.sub(String, 1, string.len(Start)) == Start
end

function CommandManager:get_peer_list(unitcheck, ignore_local)
	local session = managers.network:session()
	local peers = {}
	for i=1, 4 do
		local peer = session:peer(i)
		if peer then
			if ignore_local and ( peer:id() == session:local_peer():id()) then
			else
				if unitcheck and (not alive(peer:unit())) then
				else
					peers[peer:id()] = peer
				end
			end
		end
	end
	return peers
end

function CommandManager:get_peer(id, unitcheck, ignore_local)
	local session = managers.network:session()
	if session then
		if tonumber(id) then
			local peer = session:peer(id)
			if peer then
				if ( unitcheck and ( not alive(peer:unit())) )
					or (ignore_local and (peer:id() ~= session:local_peer():id()))
				then
					--?
				else
					return true, peer
				end
			end
		end

		-- if the peer does not exist, return a list with all available peers
		return false, self:get_peer_list( unitcheck, ignore_local)
	end
end

function CommandManager:in_chat()
	if managers.hud and managers.hud._chat_focus == true then
		return true
	end
end

function CommandManager:in_game()
	if not game_state_machine then
		return false
	else
		return string.find(game_state_machine:current_state_name(), "game")
	end
end

function CommandManager:is_playing()
	if not BaseNetworkHandler then 
		return false
	end
	return BaseNetworkHandler._gamestate_filter.any_ingame_playing[ game_state_machine:last_queued_state_name() ]
end

function CommandManager:message(text, title)
	if text and type(text) == "string" then
		managers.chat:_receive_message(1, (title or "SYSTEM"), text, tweak_data.system_chat_color)
	end
end

function CommandManager:send_message(peer_id, message)
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
