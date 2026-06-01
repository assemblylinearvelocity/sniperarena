local Renderer = nil
local RunService = game:GetService("RunService")

local BotESP = {}

local tracked = {}
local BOT_COLOR = Color3.fromRGB(255, 165, 0)

local function isBot(instance)
	return instance:IsA("Model")
		and instance:FindFirstChildOfClass("Humanoid")
		and instance:FindFirstChild("HumanoidRootPart")
		and instance:FindFirstChild("Collider")
end

local function getHealth(entity)
	local humanoid = entity:FindFirstChildOfClass("Humanoid")
	if humanoid then
		return humanoid.Health, math.max(humanoid.MaxHealth, 1)
	end
	local healthVal = entity:FindFirstChild("Health")
	if healthVal then
		return healthVal.Value, 100
	end
	return 100, 100
end

local function newEntry()
	return {
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

local function trackEntities(entities)
	for _, entity in ipairs(entities:GetChildren()) do
		if isBot(entity) and not tracked[entity] then
			tracked[entity] = newEntry()
		end
	end

	entities.ChildAdded:Connect(function(entity)
		task.wait(0.1)
		if isBot(entity) and not tracked[entity] then
			tracked[entity] = newEntry()
		end
	end)

	entities.ChildRemoved:Connect(function(entity)
		local entry = tracked[entity]
		if entry then
			removeEntry(entry)
			tracked[entity] = nil
		end
	end)
end

local function trackRoom(room)
	local entities = room:FindFirstChild("Entities")
	if entities then
		trackEntities(entities)
	else
		room.ChildAdded:Connect(function(child)
			if child.Name == "Entities" then
				trackEntities(child)
			end
		end)
	end
end

function BotESP.Init(renderer)
	Renderer = renderer

	local worldFolder = workspace:WaitForChild("World", 30)
	if not worldFolder then return end

	for _, room in ipairs(worldFolder:GetChildren()) do
		task.spawn(trackRoom, room)
	end

	worldFolder.ChildAdded:Connect(function(room)
		task.spawn(trackRoom, room)
	end)

	RunService.RenderStepped:Connect(function()
		local Toggles = getgenv().Toggles
		local Options  = getgenv().Options
		if not Toggles then return end

		local espEnabled = Toggles["BotESP_Enabled"]  and Toggles["BotESP_Enabled"].Value
		local showBox    = Toggles["BotESP_Box"]       and Toggles["BotESP_Box"].Value
		local showHealth = Toggles["BotESP_Health"]    and Toggles["BotESP_Health"].Value
		local showName   = Toggles["BotESP_Name"]      and Toggles["BotESP_Name"].Value
		local showDist   = Toggles["BotESP_Distance"]  and Toggles["BotESP_Distance"].Value
		local distUnit   = Options and Options["BotESP_DistUnit"] and Options["BotESP_DistUnit"].Value or "Studs"

		for entity, entry in pairs(tracked) do
			if not espEnabled or not entity.Parent then
				clearEntry(entry)
				continue
			end

			local ok, bounds = pcall(Renderer.GetBoundingBox, entity)
			if not ok then bounds = nil end

			if showBox then
				Renderer.UpdateBox(entry.box, bounds, BOT_COLOR, 1)
			else
				Renderer.UpdateBox(entry.box, nil, nil)
			end

			if showHealth and bounds then
				local hp, maxHp = getHealth(entity)
				Renderer.UpdateHealthBar(entry.healthBar, bounds, hp, maxHp)
			else
				Renderer.UpdateHealthBar(entry.healthBar, nil, 0, 100)
			end

			if showName and bounds then
				Renderer.UpdateLabel(entry.nameLabel, entity.Name, Vector2.new(bounds.x + bounds.width / 2, bounds.y - 16))
			else
				Renderer.UpdateLabel(entry.nameLabel, "", nil)
			end

			if showDist and bounds then
				local hrp = entity:FindFirstChild("HumanoidRootPart")
				if hrp then
					local studs = Renderer.GetDistance(hrp.Position)
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
		end
	end)
end

function BotESP.Unload()
	for _, entry in pairs(tracked) do
		removeEntry(entry)
	end
	tracked = {}
end

return BotESP
