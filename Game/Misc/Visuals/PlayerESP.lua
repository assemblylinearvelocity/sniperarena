local Renderer = nil
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerESP = {}

local localPlayer = Players.LocalPlayer
local tracked = {}

local enemyHolder
local friendlyHolder

local ENEMY_COLOR    = Color3.fromRGB(255, 60, 60)
local FRIENDLY_COLOR = Color3.fromRGB(60, 255, 60)

local function getTeam(playerName)
	if enemyHolder:FindFirstChild(playerName) then
		return "enemy"
	elseif friendlyHolder:FindFirstChild(playerName) then
		return "friendly"
	end
	return nil
end

local function getCharacter(playerName)
	local inEnemy = enemyHolder:FindFirstChild(playerName)
	if inEnemy then return inEnemy end
	return friendlyHolder:FindFirstChild(playerName)
end

local function getHealth(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		return humanoid.Health, humanoid.MaxHealth
	end
	local healthVal = character:FindFirstChild("Health")
	if healthVal then
		return healthVal.Value, 100
	end
	return 100, 100
end

local function addPlayer(player)
	if player == localPlayer then return end
	if tracked[player] then return end
	tracked[player] = {
		box       = Renderer.NewBox(),
		healthBar = Renderer.NewHealthBar(),
		nameLabel = Renderer.NewLabel(),
		distLabel = Renderer.NewLabel(),
	}
end

local function removePlayer(player)
	local entry = tracked[player]
	if not entry then return end
	Renderer.RemoveBox(entry.box)
	Renderer.RemoveHealthBar(entry.healthBar)
	Renderer.RemoveLabel(entry.nameLabel)
	Renderer.RemoveLabel(entry.distLabel)
	tracked[player] = nil
end

function PlayerESP.Init(renderer)
	Renderer = renderer

	enemyHolder    = workspace:WaitForChild("Highlight"):WaitForChild("Enemy"):WaitForChild("HighlightHolder")
	friendlyHolder = workspace:WaitForChild("Highlight"):WaitForChild("Friendly"):WaitForChild("HighlightHolder")

	for _, player in ipairs(Players:GetPlayers()) do
		addPlayer(player)
	end

	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(removePlayer)

	RunService.RenderStepped:Connect(function()
		local Toggles = getgenv().Toggles
		local Options  = getgenv().Options

		local espEnabled  = Toggles and Toggles["PlayerESP_Enabled"]  and Toggles["PlayerESP_Enabled"].Value
		local teamCheck   = Toggles and Toggles["PlayerESP_TeamCheck"] and Toggles["PlayerESP_TeamCheck"].Value
		local showBox     = Toggles and Toggles["PlayerESP_Box"]       and Toggles["PlayerESP_Box"].Value
		local showHealth  = Toggles and Toggles["PlayerESP_Health"]    and Toggles["PlayerESP_Health"].Value
		local showName    = Toggles and Toggles["PlayerESP_Name"]      and Toggles["PlayerESP_Name"].Value
		local showDist    = Toggles and Toggles["PlayerESP_Distance"]  and Toggles["PlayerESP_Distance"].Value
		local distUnit    = Options  and Options["PlayerESP_DistUnit"] and Options["PlayerESP_DistUnit"].Value

		for player, entry in pairs(tracked) do
			if not espEnabled then
				Renderer.UpdateBox(entry.box, nil, nil)
				Renderer.UpdateHealthBar(entry.healthBar, nil, 0, 100)
				Renderer.UpdateLabel(entry.nameLabel, "", nil)
				Renderer.UpdateLabel(entry.distLabel, "", nil)
				continue
			end

			local team = getTeam(player.Name)
			if not team then
				Renderer.UpdateBox(entry.box, nil, nil)
				Renderer.UpdateHealthBar(entry.healthBar, nil, 0, 100)
				Renderer.UpdateLabel(entry.nameLabel, "", nil)
				Renderer.UpdateLabel(entry.distLabel, "", nil)
				continue
			end

			if teamCheck and team == "friendly" then
				Renderer.UpdateBox(entry.box, nil, nil)
				Renderer.UpdateHealthBar(entry.healthBar, nil, 0, 100)
				Renderer.UpdateLabel(entry.nameLabel, "", nil)
				Renderer.UpdateLabel(entry.distLabel, "", nil)
				continue
			end

			local character = getCharacter(player.Name)
			if not character then
				Renderer.UpdateBox(entry.box, nil, nil)
				Renderer.UpdateHealthBar(entry.healthBar, nil, 0, 100)
				Renderer.UpdateLabel(entry.nameLabel, "", nil)
				Renderer.UpdateLabel(entry.distLabel, "", nil)
				continue
			end

			local bounds = Renderer.GetBoundingBox(character)
			local color  = team == "enemy" and ENEMY_COLOR or FRIENDLY_COLOR

			if showBox then
				Renderer.UpdateBox(entry.box, bounds, color, 1)
			else
				Renderer.UpdateBox(entry.box, nil, nil)
			end

			if showHealth then
				local hp, maxHp = getHealth(character)
				Renderer.UpdateHealthBar(entry.healthBar, bounds, hp, maxHp)
			else
				Renderer.UpdateHealthBar(entry.healthBar, nil, 0, 100)
			end

			if showName and bounds then
				Renderer.UpdateLabel(entry.nameLabel, player.Name, Vector2.new(bounds.x + bounds.width / 2, bounds.y - 16))
			else
				Renderer.UpdateLabel(entry.nameLabel, "", nil)
			end

			if showDist and bounds then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local studs = Renderer.GetDistance(hrp.Position)
					local distText
					if distUnit == "Meters" then
						distText = string.format("%.1fm", studs * 0.28)
					else
						distText = string.format("%.0fstu", studs)
					end
					Renderer.UpdateLabel(entry.distLabel, distText, Vector2.new(bounds.x + bounds.width / 2, bounds.y + bounds.height + 4))
				else
					Renderer.UpdateLabel(entry.distLabel, "", nil)
				end
			else
				Renderer.UpdateLabel(entry.distLabel, "", nil)
			end
		end
	end)
end

function PlayerESP.Unload()
	for _, entry in pairs(tracked) do
		Renderer.RemoveBox(entry.box)
		Renderer.RemoveHealthBar(entry.healthBar)
		Renderer.RemoveLabel(entry.nameLabel)
		Renderer.RemoveLabel(entry.distLabel)
	end
	tracked = {}
end

return PlayerESP
