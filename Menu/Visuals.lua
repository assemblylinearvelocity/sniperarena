local function BuildVisualsTab(Window, Toggles, Options)
	local Tab = Window:AddTab("Visuals")

	local PlayerGroup = Tab:AddLeftGroupbox("Player ESP")

	PlayerGroup:AddToggle("PlayerESP_Enabled", {
		Text = "Player ESP",
		Default = false,
	})

	PlayerGroup:AddToggle("PlayerESP_TeamCheck", {
		Text = "Team Check",
		Default = false,
	})

	local BotGroup = Tab:AddRightGroupbox("Bot ESP")

	BotGroup:AddToggle("BotESP_Enabled", {
		Text = "Bot ESP",
		Default = false,
	})
end

return BuildVisualsTab
