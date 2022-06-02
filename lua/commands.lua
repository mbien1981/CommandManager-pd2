-- import utils
CommandManager:import("_utils.lua")

-- clear existing commands
CommandManager.commands = {}

-- * base commands
CommandManager:add_command("aliases", {
	aliases = { "alias" },
	help = {
		"Description: Shows you the alternative names of the given command.",
		"Arguments: command_name",
		"Example: /aliases halo",
	},
	callback = function(args)
		local output = ""

		local cmd_name = args[1]
		if not cmd_name then
			return "usage: /alias command_name"
		end

		local cmd_data = CommandManager.commands[cmd_name]
		if not cmd_data then
			return string.format("The command '%s' does not exist in the database.", cmd_name)
		end

		if not cmd_data.aliases then
			return string.format("The command '%s' does not have any alias.", cmd_name)
		end

		if cmd_data.is_alias then
			cmd_name = cmd_data.parent
		end

		for i, alias in pairs(cmd_data.aliases or {}) do
			output = output .. alias .. ((next(cmd_data.aliases, i) and ", ") or "")
		end

		return string.format("Aliases for command '%s': %s", cmd_name, output)
	end,
})

CommandManager:add_command("help", {
	aliases = { "description", "desc" },
	help = {
		"Description: Shows you the description and arguments of a command.",
		"Arguments: command_name",
		"Usage: /help command_name",
	},
	callback = function(args)
		local cmd_name = args[1]
		if not cmd_name then
			return "usage: /help command_name, use /list for a list of commands."
		end

		local cmd_data = CommandManager.commands[cmd_name]
		if not cmd_data then
			return string.format("The command '%s' does not exist in the database.", cmd_name)
		end

		if not cmd_data.help then
			return string.format("The command '%s' does not have any description.", cmd_name)
		end

		local output = string.format("Command: %s\n", cmd_name)
		for i, line in pairs(cmd_data.help) do
			output = output .. line .. (next(cmd_data.help, i) and "\n" or "")
		end

		return output
	end,
})

CommandManager:add_command("list", {
	aliases = { "commands" },
	help = {
		"Description: Shows you an alphabetically sorted list of commands.",
	},
	callback = function(_, sender)
		local cmd_list = CommandManager.commands
		local output_commands = {}
		for cmd_name, cmd_data in pairs(cmd_list) do
			if (cmd_data.private and (not CommandManager:is_local(sender))) or cmd_data.is_alias then
				goto next
			end

			table.insert(output_commands, cmd_name)

			::next::
		end

		table.sort(output_commands)

		local output = "Command list: "
		for i, command in pairs(output_commands) do
			output = output .. command .. (next(output_commands, i) and ", " or "")
		end

		return output
	end,
})

CommandManager:add_command("reload", {
	private = true,
	help = {
		"Description: Reloads the command definition file.",
		"Purpose: Easily apply your changes to chat commands without restarting the session.",
	},
	callback = function()
		dofile(CommandManager._path .. "commands.lua")
		return "Commands reloaded!"
	end,
})

-- * listing players
CommandManager:add_command("users", {
	aliases = { "peers", "status" },
	callback = function()
		local output = "Player list: \n"
		local peer_list = CommandManager:peer_list()
		for _, peer in pairs(peer_list) do
			output = output
				.. string.format("Id: %d, name: %s, Steam Id: %s", peer:id(), peer:name(), peer:user_id())
				.. (next(peer_list) and "\n" or "")
		end

		return output
	end,
})

-- * chat translating
CommandManager:add_command("translate", {
	aliases = { "tl", "tr", "t" },
	private = true,
	help = {
		"Description: Translates given text through the public GTranslate API.",
		"Usage: /translate language_code text",
	},
	callback = function(args)
		local lang = args[1]
		if not lang then
			return
		end

		local text = ""
		for i, msg in pairs(args) do
			if i ~= 1 then
				text = string.format("%s %s", text, msg)
			end
		end

		CommandManager:translate(text, "en", lang, true)
	end,
})

-- * private messaging
CommandManager:add_command("say", {
	private = true,
	help = {
		"Description: Sends a message in chat like you would normally do.",
		"Purpose: chat messages that start with a command prefix will not be sent,\nthis command is a workaround for that inconvenience.",
	},
	callback = function(args)
		local text = (args and table.concat(args, " ")) or ""
		if text == "" then
			return
		end

		for _, peer in pairs(CommandManager:peer_list()) do
			CommandManager:send_message(peer:id(), string.format("%s", text))
		end

		local lPeer = CommandManager:local_peer()
		CommandManager:message(text, lPeer:name(), tweak_data.chat_colors[lPeer:id()])
	end,
})

CommandManager:add_command("private", {
	aliases = { "prv", "dm", "pm" },
	private = true,
	help = {
		"Description: Sends a private message to a player.",
		"Arguments: peer_id, text",
		"Example: /private 1 Hello, world!",
		"Info: use the '/users' command get a list of peers.",
	},
	callback = function(args)
		local peer = CommandManager:peer(args[1])
		if not peer then
			return "peer not found!"
		end

		local text = ""
		for i, msg in pairs(args) do
			if i ~= 1 then -- peer id
				text = string.format("%s %s", text, msg)
			end
		end

		CommandManager:send_message(peer:id(), string.format("[PRIVATE]: %s", text))
		return string.format("dm sent to %s.\ntext: %s", peer:name(), text)
	end,
})

CommandManager:add_command("reply", {
	aliases = { "re" },
	private = true,
	help = {
		"Description: Shortcut of the 'Private' command.",
		"Arguments: text",
		"Info: The receiver will be the last person who has sent you a private message.",
	},
	callback = function(args)
		local peer = CommandManager.peer_to_reply
		if peer and peer then
			local text = ""
			for _, msg in pairs(args) do
				text = string.format("%s %s", text, msg)
			end

			CommandManager:send_message(peer:id(), string.format("[PRIVATE]: %s", text))
			return string.format("Quick reply sent to %s.\ntext: %s", peer:name(), text)
		end
	end,
})

-- * Shape module
CommandManager:add_command("halo", {
	aliases = { "portal", "ring" },
	help = {
		"Description: Spawns a halo with units wherever the player is looking at.",
		"Optional arguments: number (1-4), tilt (0-90)",
		"Info: number represents the equipment id. 1: Medic bag, 2: Ammo bag, 3: First Aid Kit, 4: Trip Mine.",
		"Example: /halo 4",
	},
	callback = function(args, sender)
		CommandManager:import("shapes")

		spawnPortal(sender:unit(), true, tonumber(args[1]), tonumber(args[2]))

		return string.format("%s spawned a portal.", sender:name())
	end,
})

CommandManager:add_command("sphere", {
	help = {
		"Description: Spawns a sphere with units wherever the player is looking at.",
		"Optional arguments: number (1-4)",
		"Info: number represents the equipment id. 1: Medic bag, 2: Ammo bag, 3: First Aid Kit, 4: Trip Mine.",
		"Example: /sphere 4",
	},
	callback = function(args, sender)
		CommandManager:import("shapes")

		spawnCubeSphere(sender:unit(), true, tonumber(args[1]), 3, 150, 0)

		return string.format("%s spawned a sphere.", sender:name())
	end,
})

CommandManager:add_command("round", {
	help = {
		"Description: Spawns a round with units wherever the player is looking at.",
		"Optional arguments: number (1-4)",
		"Info: number represents the equipment id. 1: Medic bag, 2: Ammo bag, 3: First Aid Kit, 4: Trip Mine.",
		"Example: /round 4",
	},
	callback = function(args, sender)
		CommandManager:import("shapes")

		spawnRound(sender:unit(), true, tonumber(args[1]))

		return string.format("%s spawned a round.", sender:name())
	end,
})

CommandManager:add_command("circle", {
	help = {
		"Description: Spawns a circle with units wherever the player is looking at.",
		"Optional arguments: number (1-4)",
		"Info: number represents the equipment id. 1: Medic bag, 2: Ammo bag, 3: First Aid Kit, 4: Trip Mine.",
		"Example: /circle 4",
	},
	callback = function(args, sender)
		CommandManager:import("shapes")

		spawnCircle(sender:unit(), true, tonumber(args[1]))

		return string.format("%s spawned a round.", sender:name())
	end,
})

CommandManager:add_command("void", {
	help = {
		"Description: Spawns a void with units wherever the player is looking at.",
		"Optional arguments: number (1-4)",
		"Info: number represents the equipment id. 1: Medic bag, 2: Ammo bag, 3: First Aid Kit, 4: Trip Mine.",
		"Example: /void 4",
	},
	callback = function(args, sender)
		CommandManager:import("shapes")

		spawnVoid(sender:unit(), true, tonumber(args[1]))

		return string.format("%s spawned a void.", sender:name())
	end,
})

CommandManager:add_command("stair", {
	help = {
		"Description: Spawns a staircase with units wherever the player is looking at.",
		"Optional arguments: number (1-4)",
		"Info: number represents the equipment id. 1: Medic bag, 2: Ammo bag, 3: First Aid Kit, 4: Trip Mine.",
		"Example: /stair 4",
	},
	callback = function(args, sender)
		CommandManager:import("shapes")

		spawnStairUp(sender:unit(), true, tonumber(args[1]))

		return string.format("%s spawned a stair.", sender:name())
	end,
})

CommandManager:add_command("file", {
	private = true,
	help = {
		"Description: Loads a coord file and spawns units based on it.",
		"Arguments: file_name",
		"Optional arguments: number (1-4)",
	},
	callback = function(args, sender)
		CommandManager:import("shapes")

		spawnFromFile(args[1] or "troll", sender:unit(), true, tonumber(args[2]))

		return string.format("%s spawned a shape from file.", sender:name())
	end,
})

-- * other
CommandManager:add_command("breaking_feds", {
	aliases = { "bf", "bfcode", "fcode" },
	callback = function()
		local codes = {
			"Mentions his wife: 1212",
			"Simple/obvious: 1234",
			"Historical: 1776",
			"Involves the Payday Gang/Starts with the number 2: 2015",
		}
		local output = ""
		for i, line in pairs(codes) do
			output = output .. line .. (next(codes, i) and "\n" or "")
		end

		return output
	end,
})
