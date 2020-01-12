dofile("mods/CommandManager/handlers/CommandManager")

if rawget(_G, "CommandManager") then
	if RequiredScript == "lib/managers/menumanager" then
		local __orig = MenuManager.update
		function MenuManager:update(t, dt)
			__orig(self, t, dt)
			CommandManager:Update(t, dt)
		end
	end
end