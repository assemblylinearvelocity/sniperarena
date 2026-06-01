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
		Visible = false,
	})

	PlayerGroup:AddToggle("PlayerESP_Box", {
		Text = "Box",
		Default = true,
		Visible = false,
	})

	PlayerGroup:AddToggle("PlayerESP_Health", {
		Text = "Health",
		Default = false,
		Visible = false,
	})

	PlayerGroup:AddToggle("PlayerESP_Name", {
		Text = "Name",
		Default = false,
		Visible = false,
	})

	PlayerGroup:AddToggle("PlayerESP_Distance", {
		Text = "Distance",
		Default = false,
		Visible = false,
	})

	PlayerGroup:AddDropdown("PlayerESP_DistUnit", {
		Text = "Distance Unit",
		Values = { "Studs", "Meters" },
		Default = 1,
		Visible = false,
	})

	Toggles["PlayerESP_Enabled"]:OnChanged(function(value)
		Toggles["PlayerESP_TeamCheck"]:SetVisible(value)
		Toggles["PlayerESP_Box"]:SetVisible(value)
		Toggles["PlayerESP_Health"]:SetVisible(value)
		Toggles["PlayerESP_Name"]:SetVisible(value)
		Toggles["PlayerESP_Distance"]:SetVisible(value)
		if not value then
			Options["PlayerESP_DistUnit"]:SetVisible(false)
		else
			Options["PlayerESP_DistUnit"]:SetVisible(Toggles["PlayerESP_Distance"].Value)
		end
	end)

	Toggles["PlayerESP_Distance"]:OnChanged(function(value)
		if Toggles["PlayerESP_Enabled"].Value then
			Options["PlayerESP_DistUnit"]:SetVisible(value)
		end
	end)

	local BotGroup = Tab:AddRightGroupbox("Bot ESP")

	BotGroup:AddToggle("BotESP_Enabled", {
		Text = "Bot ESP",
		Default = false,
	})

	BotGroup:AddToggle("BotESP_Box", {
		Text = "Box",
		Default = true,
		Visible = false,
	})

	BotGroup:AddToggle("BotESP_Health", {
		Text = "Health",
		Default = false,
		Visible = false,
	})

	BotGroup:AddToggle("BotESP_Name", {
		Text = "Name",
		Default = false,
		Visible = false,
	})

	BotGroup:AddToggle("BotESP_Distance", {
		Text = "Distance",
		Default = false,
		Visible = false,
	})

	BotGroup:AddDropdown("BotESP_DistUnit", {
		Text = "Distance Unit",
		Values = { "Studs", "Meters" },
		Default = 1,
		Visible = false,
	})

	Toggles["BotESP_Enabled"]:OnChanged(function(value)
		Toggles["BotESP_Box"]:SetVisible(value)
		Toggles["BotESP_Health"]:SetVisible(value)
		Toggles["BotESP_Name"]:SetVisible(value)
		Toggles["BotESP_Distance"]:SetVisible(value)
		if not value then
			Options["BotESP_DistUnit"]:SetVisible(false)
		else
			Options["BotESP_DistUnit"]:SetVisible(Toggles["BotESP_Distance"].Value)
		end
	end)

	Toggles["BotESP_Distance"]:OnChanged(function(value)
		if Toggles["BotESP_Enabled"].Value then
			Options["BotESP_DistUnit"]:SetVisible(value)
		end
	end)
end

return BuildVisualsTab
