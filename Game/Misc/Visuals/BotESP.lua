local EspRenderer = nil
local RunService  = game:GetService("RunService")

local BotESP = {}

local tracked  = {}
local BOT_COLOR = Color3.fromRGB(255, 165, 0)

local function isBot(instance)
	return instance:IsA("Model")
		and instance:FindFirstChildOfClass("Humanoid")
		and instance:FindFirstChild("HumanoidRootPart")
		and instance:FindFirstChild("Collider")
end

local function trackEntities(entities)
	for _, entity in ipairs(entities:GetChildren()) do
		if isBot(entity) and not tracked[entity] then
			tracked[entity] = EspRenderer.new(entity.Name)
		end
	end
	entities.ChildAdded:Connect(function(entity)
		task.wait(0.1)
		if isBot(entity) and not tracked[entity] then
			tracked[entity] = EspRenderer.new(entity.Name)
		end
	end)
	entities.ChildRemoved:Connect(function(entity)
		local r = tracked[entity]
		if r then
			r:Destroy()
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
	EspRenderer = renderer

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

		for entity, r in pairs(tracked) do
			if not espEnabled or not entity.Parent then
				r:HideAll()
				continue
			end
			r:Update(entity, BOT_COLOR, showBox, showHealth, showName, showDist, distUnit)
		end
	end)
end

function BotESP.Unload()
	for _, r in pairs(tracked) do
		r:Destroy()
	end
	tracked = {}
end

return BotESP
