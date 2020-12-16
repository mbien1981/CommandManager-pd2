if rawget(_G, "CommandManager") then
	if (not CommandManager:in_chat()) then
		rawset(_G, "CommandManager", nil)
	end
end

if (not rawget(_G, "CommandManager")) then
	rawset(_G, "CommandManager", {
		aliases	= {},
		config	= {},
		history	= {},
		path	= "mods/CommandManager/Hooked/Chat/Commands/%s",
		command_prefixes = { "/", "!", "." }
	})

	function CommandManager:LoadAliases()
		local file = JSONClass:jsonFile(string.format(self.path, "Addons/aliases.json"))
		if file then
			local data = JSONClass:decode(file)
			if data then
				self.aliases = data
				self:log("[CommandManager:LoadAliases]: Loaded!")
			else
				self:log("[CommandManager:LoadAliases]: Error Decoding!")
			end
		else
			self:log("[CommandManager:LoadAliases]: Error Reading File!")
		end
	end

	function CommandManager:LoadConfig()
		local file = JSONClass:jsonFile(string.format(self.path, "Hooked/Core/config.json"))
		if file then
			local data = JSONClass:decode(file)
			if data then
				self.config = data
				self:log("[CommandManager:LoadConfig]: Loaded!")
			else
				self:log("[CommandManager:LoadConfig]: Error Decoding!")
			end
		else
			self:log("[CommandManager:LoadConfig]: Error Reading File!")
		end
	end

	function CommandManager:Save()
		local file = io.open(string.format(self.path, "Hooked/Core/config.json"), "w+")
		if file then
			local contents = JSONClass:encode_pretty(self.config)
			if contents then
				file:write(contents)
				self:log("[CommandManager:Save]: Saved!")
			else
				self:log("[CommandManager:Save]: Encoding Error!")
			end
			io.close(file)
		else
			self:log("[CommandManager:Save] Error Opening File!")
		end
	end

	function CommandManager:log(...)
		print(...)
	end

	function CommandManager:prefixes(str)
		for _, prefix in pairs(self.command_prefixes) do
			if string.sub(str, 1, 1) == prefix then
				return true
			end
		end
	end

	function CommandManager:init()
		--* Load Utils *--
		for _, util in pairs({
			'Hooked/Core/requirements/delayedcalls',
			'Hooked/Core/requirements/json',
			'Hooked/Core/requirements/utils',
		}) do
			dofile(string.format(self.path, util))
		end
		
		--* Load Config *--
		self:LoadAliases()
		self:LoadConfig()

		--* Setup Commands *--
		for _, req in pairs{
			'Hooked/Core/commands',
			'Addons/Custom'
		} do
			dofile(string.format(self.path, req))
		end
	end

	CommandManager:init()
end
