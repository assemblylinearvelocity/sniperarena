local Renderer = nil
local RunService = game:GetService("RunService")

local PlayerESP = {}

local tracked = {}

local ENEMY_COLOR    = Color3.fromRGB(255, 60, 60)
local FRIENDLY_COLOR = Color3.fromRGB(60, 255, 60)

local function getHealth(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		return humanoid.Health, math.max(humanoid.MaxHealth, 1)
	end
	local h = model:FindFirstChild("Health")
	if h and h:IsA("NumberValue") then
		return h.Value, 100
	end
	return 100, 100
end

local function newEntry(model, color)
	return {
		model     = model,
		color     = color,
		box       = Renderer.NewBox(),
		healthBar = Renderer.NewHealthBar(),
		nameLabel = Renderer.NewLabel(),
		distLabel = Renderer.NewLabel(),
	}
end

local function removeEntry(entry)
	Renderer.RemoveBox(entry.box)
	Renderer.RemoveHealthBar(entry.healthBar)
	Renderer.RemoveLabel(entry.nameLabel)
	Renderer.RemoveLabel(entry.distLabel)
end

local function clearEntry(entry)
	Renderer.UpdateBox(entry.box, nil, nil)
	Renderer.UpdateHealthBar(entry.healthBar, nil, 0, 100)
	Renderer.UpdateLabel(entry.nameLabel, "", nil)
	Renderer.UpdateLabel(entry.distLabel, "", nil)
end

local function trackHolder(holder, color)
	for _, model in ipairs(holder:GetChildren()) do
		if model:IsA("Model") and not tracked[model] then
			tracked[model] = newEntry(model, color)
		end
	end

	holder.ChildAdded:Connect(function(model)
		if model:IsA("Model") and not tracked[model] then
			tracked[model] = newEntry(model, color)
		end
	end)

	holder.ChildRemoved:Connect(function(model)
		local entry = tracked[model]
		if entry then
			removeEntry(entry)
			tracked[model] = nil
		end
	end)
end

function PlayerESP.Init(renderer)
	Renderer = renderer

	task.spawn(function()
		local highlight    = workspace:WaitForChild("Highlight", 30)
		if not highlight then warn("[PlayerESP] No Highlight folder") return end

		local enemy        = highlight:WaitForChild("Enemy", 30)
		local friendly     = highlight:WaitForChild("Friendly", 30)

		if enemy then
			local enemyHolder = enemy:WaitForChild("HighlightHolder", 30)
			if enemyHolder then trackHolder(enemyHolder, ENEMY_COLOR) end
		end

		if friendly then
			local friendlyHolder = friendly:WaitForChild("HighlightHolder", 30)
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
				clearEntry(entry)
				continue
			end

			if teamCheck and entry.color == FRIENDLY_COLOR then
				clearEntry(entry)
				continue
			end

			local hrp = model:FindFirstChild("HumanoidRootPart")
			if not hrp then
				clearEntry(entry)
				continue
			end

			local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
			if not onScreen or screenPos.Z <= 0 then
				clearEntry(entry)
				continue
			end

			local h = workspace.CurrentCamera.ViewportSize.Y / screenPos.Z * 2
			local w = h * 0.6
			local bounds = {
				x      = screenPos.X - w / 2,
				y      = screenPos.Y - h / 2,
				width  = w,
				height = h,
			}

			if showBox then
				Renderer.UpdateBox(entry.box, bounds, entry.color, 1)
			else
				Renderer.UpdateBox(entry.box, nil, nil)
			end

			if showHealth and bounds then
				local hp, maxHp = getHealth(model)
				Renderer.UpdateHealthBar(entry.healthBar, bounds, hp, maxHp)
			else
				Renderer.UpdateHealthBar(entry.healthBar, nil, 0, 100)
			end

			if showName and bounds then
				Renderer.UpdateLabel(entry.nameLabel, model.Name, Vector2.new(bounds.x + bounds.width / 2, bounds.y - 16))
			else
				Renderer.UpdateLabel(entry.nameLabel, "", nil)
			end

			if showDist and bounds then
				local hrp = model:FindFirstChild("HumanoidRootPart")
				if hrp then
					local localChar = game:GetService("Players").LocalPlayer.Character
					local localHRP  = localChar and localChar:FindFirstChild("HumanoidRootPart")
					if localHRP then
						local studs = (localHRP.Position - hrp.Position).Magnitude
						local distText = distUnit == "Meters"
							and string.format("%.1fm", studs * 0.28)
							or  string.format("%.0fstu", studs)
						Renderer.UpdateLabel(entry.distLabel, distText, Vector2.new(bounds.x + bounds.width / 2, bounds.y + bounds.height + 4))
					else
						Renderer.UpdateLabel(entry.distLabel, "", nil)
					end
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
		removeEntry(entry)
	end
	tracked = {}
end

return PlayerESP
