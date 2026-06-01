local Renderer = nil
local RunService = game:GetService("RunService")

local BotESP = {}

local tracked = {}
local BOT_COLOR = Color3.fromRGB(255, 165, 0)

local function isBot(instance)
	return instance:FindFirstChild("Humanoid")
		and instance:FindFirstChild("HumanoidRootPart")
		and instance:FindFirstChild("Collider")
end

local function trackRoom(room)
	local entities = room:FindFirstChild("Entities")
	if not entities then return end

	for _, entity in ipairs(entities:GetChildren()) do
		if isBot(entity) and not tracked[entity] then
			tracked[entity] = { box = Renderer.NewBox() }
		end
	end

	entities.ChildAdded:Connect(function(entity)
		task.wait()
		if isBot(entity) and not tracked[entity] then
			tracked[entity] = { box = Renderer.NewBox() }
		end
	end)

	entities.ChildRemoved:Connect(function(entity)
		local entry = tracked[entity]
		if entry then
			Renderer.RemoveBox(entry.box)
			tracked[entity] = nil
		end
	end)
end

function BotESP.Init(renderer)
	Renderer = renderer

	local worldFolder = workspace:WaitForChild("World")

	for _, room in ipairs(worldFolder:GetChildren()) do
		trackRoom(room)
	end

	worldFolder.ChildAdded:Connect(function(room)
		task.wait()
		trackRoom(room)
	end)

	RunService.RenderStepped:Connect(function()
		local Toggles = getgenv().Toggles
		local espEnabled = Toggles and Toggles["BotESP_Enabled"] and Toggles["BotESP_Enabled"].Value

		for entity, entry in pairs(tracked) do
			if not espEnabled or not entity.Parent then
				Renderer.UpdateBox(entry.box, nil, nil)
				continue
			end

			local bounds = Renderer.GetBoundingBox(entity)
			Renderer.UpdateBox(entry.box, bounds, BOT_COLOR, 1)
		end
	end)
end

function BotESP.Unload()
	for _, entry in pairs(tracked) do
		Renderer.RemoveBox(entry.box)
	end
	tracked = {}
end

return BotESP
