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

local function addPlayer(player)
	if player == localPlayer then return end
	if tracked[player] then return end
	tracked[player] = { box = Renderer.NewBox() }
end

local function removePlayer(player)
	local entry = tracked[player]
	if not entry then return end
	Renderer.RemoveBox(entry.box)
	tracked[player] = nil
end

function PlayerESP.Init(renderer)
	Renderer = renderer

	enemyHolder   = workspace:WaitForChild("Highlight"):WaitForChild("Enemy"):WaitForChild("HighlightHolder")
	friendlyHolder = workspace:WaitForChild("Highlight"):WaitForChild("Friendly"):WaitForChild("HighlightHolder")

	for _, player in ipairs(Players:GetPlayers()) do
		addPlayer(player)
	end

	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(removePlayer)

	RunService.RenderStepped:Connect(function()
		local Toggles = getgenv().Toggles
		local espEnabled = Toggles and Toggles["PlayerESP_Enabled"] and Toggles["PlayerESP_Enabled"].Value
		local teamCheck  = Toggles and Toggles["PlayerESP_TeamCheck"] and Toggles["PlayerESP_TeamCheck"].Value

		for player, entry in pairs(tracked) do
			if not espEnabled then
				Renderer.UpdateBox(entry.box, nil, nil)
				continue
			end

			local team = getTeam(player.Name)
			if not team then
				Renderer.UpdateBox(entry.box, nil, nil)
				continue
			end

			if teamCheck and team == "friendly" then
				Renderer.UpdateBox(entry.box, nil, nil)
				continue
			end

			local character = getCharacter(player.Name)
			if not character then
				Renderer.UpdateBox(entry.box, nil, nil)
				continue
			end

			local bounds = Renderer.GetBoundingBox(character)
			local color = team == "enemy" and ENEMY_COLOR or FRIENDLY_COLOR
			Renderer.UpdateBox(entry.box, bounds, color, 1)
		end
	end)
end

function PlayerESP.Unload()
	for _, entry in pairs(tracked) do
		Renderer.RemoveBox(entry.box)
	end
	tracked = {}
end

return PlayerESP
