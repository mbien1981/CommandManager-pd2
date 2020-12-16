--[[
	Use the CommandManager:add_command() function to define your custom commands.

	args: command_name, command_data

	command_name:
		* must be a string, used to call the command, e.g: /test

	command_data:
		* must be a table, can contain the next elements:
			- aliases	(must be a table, optional), command aliases; can be used as an alternative for a command.
			- callback	(function, can return a string), function called with the command
			- host		(boolean, optional), Host only command
			- in_menu	(boolean, optional), In-menu only command
			- in_game	(boolean, optional), In-game only command

	* You can define aliases for your commands either in the command definition or inside aliases.json
--]]

local C = CommandManager

C:add_command("test", {
	aliases = {
		"hello_world"
	},
	callback = function()
		return "Hello, World!"
	end,
	host	= false,
	in_game	= true,
	in_menu	= true
})
