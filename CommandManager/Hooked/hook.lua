local binds =
{
	["num *"]	= "Hooked/Core/CommandManager",
}

local hooks =
{
	["Hooked/Core/CommandManager"]				= { "core/lib/setups/coresetup" },
	["Hooked/Core/Requirements/delayedcalls"]	= { "lib/managers/menumanager" },
	["Hooked/chatmanager"]						= { "lib/managers/chatmanager" },
	["Hooked/hudchat"]							= { "lib/managers/hud/hudchat" },
}

local folder_path = "Hooked/Chat/Commands"

for file, hook in pairs(hooks) do
	for _, path in pairs(hook) do
		Hook(path, string.format("LightHook/%s/%s", folder_path, file))
	end
end

for key, file in pairs(binds) do
	if type(file) == "string" then
		path = string.format("LightHook/%s/%s", folder_path, file)
	end

	LightBind(key, path)
end
