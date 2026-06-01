local Renderer = nil
local RunService = game:GetService("RunService")

local PlayerESP = {}

local tracked = {}

local ENEMY_COLOR    = Color3.fromRGB(255, 60, 60)
local FRIENDLY_COLOR = Color3.fromRGB(60, 255, 60)

local BODY_PARTS = {
	"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart",
	"LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
	"RightUpperLeg", "RightLowerLeg", "RightFoot",
}

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

			local bounds = nil
			local minX, minY = math.huge, math.huge
			local maxX, maxY = -math.huge, -math.huge
			local count = 0

			for _, partName in ipairs(BODY_PARTS) do
				local part = model:FindFirstChild(partName)
				if not part or not part:IsA("BasePart") then continue end

				local s = part.Size
				local cf = part.CFrame
				local corners = {
					cf * Vector3.new( s.X/2,  s.Y/2,  s.Z/2),
					cf * Vector3.new(-s.X/2,  s.Y/2,  s.Z/2),
					cf * Vector3.new( s.X/2, -s.Y/2,  s.Z/2),
					cf * Vector3.new(-s.X/2, -s.Y/2,  s.Z/2),
					cf * Vector3.new( s.X/2,  s.Y/2, -s.Z/2),
					cf * Vector3.new(-s.X/2,  s.Y/2, -s.Z/2),
					cf * Vector3.new( s.X/2, -s.Y/2, -s.Z/2),
					cf * Vector3.new(-s.X/2, -s.Y/2, -s.Z/2),
				}
				for _, corner in ipairs(corners) do
					local screen, _, depth = workspace.CurrentCamera:WorldToViewportPoint(corner)
					if depth <= 0 then continue end
					count += 1
					if screen.X < minX then minX = screen.X end
					if screen.Y < minY then minY = screen.Y end
					if screen.X > maxX then maxX = screen.X end
					if screen.Y > maxY then maxY = screen.Y end
				end
			end

			if count > 0 then
				bounds = { x = minX, y = minY, width = maxX - minX, height = maxY - minY }
			end

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
