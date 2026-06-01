local Renderer = nil
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerESP = {}
PlayerESP.__index = PlayerESP

local localPlayer = Players.LocalPlayer
local tracked = {}

local enemyHolder   = workspace:WaitForChild("Highlight"):WaitForChild("Enemy"):WaitForChild("HighlightHolder")
local friendlyHolder = workspace:WaitForChild("Highlight"):WaitForChild("Friendly"):WaitForChild("HighlightHolder")

local ENEMY_COLOR   = Color3.fromRGB(255, 60, 60)
local FRIENDLY_COLOR = Color3.fromRGB(60, 255, 60)

local Options = getgenv().Options

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
	local inFriendly = friendlyHolder:FindFirstChild(playerName)
	if inFriendly then return inFriendly end
	return nil
end

local function addPlayer(player)
	if player == localPlayer then return end
	if tracked[player] then return end

	local entry = {
		player = player,
		box = Renderer.NewBox(),
	}
	tracked[player] = entry
end

local function removePlayer(player)
	local entry = tracked[player]
	if not entry then return end
	Renderer.RemoveBox(entry.box)
	tracked[player] = nil
end

function PlayerESP.Init(renderer)
	Renderer = renderer

	for _, player in ipairs(Players:GetPlayers()) do
		addPlayer(player)
	end

	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(removePlayer)

	RunService.RenderStepped:Connect(function()
		local espEnabled = Options and Options["PlayerESP_Enabled"] and Options["PlayerESP_Enabled"].Value
		local teamCheck  = Options and Options["PlayerESP_TeamCheck"] and Options["PlayerESP_TeamCheck"].Value

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
	for player, entry in pairs(tracked) do
		Renderer.RemoveBox(entry.box)
	end
	tracked = {}
end

return PlayerESP
