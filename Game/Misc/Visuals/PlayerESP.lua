local EspRenderer = nil
local RunService  = game:GetService("RunService")

local PlayerESP = {}

local tracked = {}

local ENEMY_COLOR    = Color3.fromRGB(255, 60, 60)
local FRIENDLY_COLOR = Color3.fromRGB(60, 255, 60)

local enemyHolder
local friendlyHolder

local function getTeamAndCharacter(playerName)
	if enemyHolder then
		local c = enemyHolder:FindFirstChild(playerName)
		if c then return "enemy", c end
	end
	if friendlyHolder then
		local c = friendlyHolder:FindFirstChild(playerName)
		if c then return "friendly", c end
	end
	return nil, nil
end

local function trackHolder(holder, color)
	for _, model in ipairs(holder:GetChildren()) do
		if model:IsA("Model") and not tracked[model] then
			tracked[model] = { renderer = EspRenderer.new(model.Name), color = color }
		end
	end
	holder.ChildAdded:Connect(function(model)
		if model:IsA("Model") and not tracked[model] then
			tracked[model] = { renderer = EspRenderer.new(model.Name), color = color }
		end
	end)
	holder.ChildRemoved:Connect(function(model)
		local entry = tracked[model]
		if entry then
			entry.renderer:Destroy()
			tracked[model] = nil
		end
	end)
end

function PlayerESP.Init(renderer)
	EspRenderer = renderer

	task.spawn(function()
		local highlight = workspace:WaitForChild("Highlight", 30)
		if not highlight then warn("[PlayerESP] Highlight not found") return end

		local enemy   = highlight:WaitForChild("Enemy", 30)
		local friendly = highlight:WaitForChild("Friendly", 30)

		if enemy then
			enemyHolder = enemy:WaitForChild("HighlightHolder", 30)
			if enemyHolder then trackHolder(enemyHolder, ENEMY_COLOR) end
		end
		if friendly then
			friendlyHolder = friendly:WaitForChild("HighlightHolder", 30)
			if friendlyHolder then trackHolder(friendlyHolder, FRIENDLY_COLOR) end
		end
	end)

	RunService.RenderStepped:Connect(function()
		local Toggles = getgenv().Toggles
		local Options  = getgenv().Options
		if not Toggles then return end

		local espEnabled = Toggles["PlayerESP_Enabled"]  and Toggles["PlayerESP_Enabled"].Value
		local teamCheck  = Toggles["PlayerESP_TeamCheck"] and Toggles["PlayerESP_TeamCheck"].Value
		local showBox    = Toggles["PlayerESP_Box"]       and Toggles["PlayerESP_Box"].Value
		local showHealth = Toggles["PlayerESP_Health"]    and Toggles["PlayerESP_Health"].Value
		local showName   = Toggles["PlayerESP_Name"]      and Toggles["PlayerESP_Name"].Value
		local showDist   = Toggles["PlayerESP_Distance"]  and Toggles["PlayerESP_Distance"].Value
		local distUnit   = Options and Options["PlayerESP_DistUnit"] and Options["PlayerESP_DistUnit"].Value or "Studs"

		for model, entry in pairs(tracked) do
			if not espEnabled or not model.Parent then
				entry.renderer:HideAll()
				continue
			end
			if teamCheck and entry.color == FRIENDLY_COLOR then
				entry.renderer:HideAll()
				continue
			end
			entry.renderer:Update(model, entry.color, showBox, showHealth, showName, showDist, distUnit)
		end
	end)
end

function PlayerESP.Unload()
	for _, entry in pairs(tracked) do
		entry.renderer:Destroy()
	end
	tracked = {}
end

return PlayerESP
