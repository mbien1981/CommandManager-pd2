function getPlayer()
	return managers.player:player_unit()
end

function getSession()
	return managers.network:session()
end

function getPeer(id)
	return getSession():peer(id)
end
