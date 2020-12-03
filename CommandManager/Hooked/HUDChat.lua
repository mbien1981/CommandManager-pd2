HUDChat.selected_command = 0

local orig = HUDChat.key_press
function HUDChat:key_press(o, k)
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

	elseif self._key_pressed == Idstring("enter") or self.key_pressed == Idstring("escape") then
		self.selected_command = 0
	end
end