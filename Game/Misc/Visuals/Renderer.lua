local Renderer = {}

local camera = workspace.CurrentCamera

function Renderer.WorldToViewport(position)
	local screenPos, onScreen = camera:WorldToViewportPoint(position)
	return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

function Renderer.GetBoundingBox(character)
	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	local onScreenCount = 0

	local parts = {
		"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart",
		"LeftUpperArm", "LeftLowerArm", "LeftHand",
		"RightUpperArm", "RightLowerArm", "RightHand",
		"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
		"RightUpperLeg", "RightLowerLeg", "RightFoot",
	}

	for _, partName in ipairs(parts) do
		local part = character:FindFirstChild(partName)
		if not part then continue end

		local size = part.Size
		local cf = part.CFrame

		local corners = {
			cf * Vector3.new( size.X / 2,  size.Y / 2,  size.Z / 2),
			cf * Vector3.new(-size.X / 2,  size.Y / 2,  size.Z / 2),
			cf * Vector3.new( size.X / 2, -size.Y / 2,  size.Z / 2),
			cf * Vector3.new(-size.X / 2, -size.Y / 2,  size.Z / 2),
			cf * Vector3.new( size.X / 2,  size.Y / 2, -size.Z / 2),
			cf * Vector3.new(-size.X / 2,  size.Y / 2, -size.Z / 2),
			cf * Vector3.new( size.X / 2, -size.Y / 2, -size.Z / 2),
			cf * Vector3.new(-size.X / 2, -size.Y / 2, -size.Z / 2),
		}

		for _, corner in ipairs(corners) do
			local screen, onScreen, depth = Renderer.WorldToViewport(corner)
			if depth <= 0 then continue end
			onScreenCount += 1
			if screen.X < minX then minX = screen.X end
			if screen.Y < minY then minY = screen.Y end
			if screen.X > maxX then maxX = screen.X end
			if screen.Y > maxY then maxY = screen.Y end
		end
	end

	if onScreenCount == 0 then
		return nil
	end

	return {
		x = minX,
		y = minY,
		width = maxX - minX,
		height = maxY - minY,
	}
end

function Renderer.NewBox()
	local box = {}
	box.top    = Drawing.new("Line")
	box.bottom = Drawing.new("Line")
	box.left   = Drawing.new("Line")
	box.right  = Drawing.new("Line")

	for _, line in pairs(box) do
		line.Thickness = 1
		line.Visible = false
	end

	return box
end

function Renderer.UpdateBox(box, bounds, color, thickness)
	if not bounds then
		for _, line in pairs(box) do
			line.Visible = false
		end
		return
	end

	local x, y, w, h = bounds.x, bounds.y, bounds.width, bounds.height
	thickness = thickness or 1

	box.top.From    = Vector2.new(x, y)
	box.top.To      = Vector2.new(x + w, y)
	box.bottom.From = Vector2.new(x, y + h)
	box.bottom.To   = Vector2.new(x + w, y + h)
	box.left.From   = Vector2.new(x, y)
	box.left.To     = Vector2.new(x, y + h)
	box.right.From  = Vector2.new(x + w, y)
	box.right.To    = Vector2.new(x + w, y + h)

	for _, line in pairs(box) do
		line.Color = color
		line.Thickness = thickness
		line.Visible = true
	end
end

function Renderer.RemoveBox(box)
	for _, line in pairs(box) do
		line:Remove()
	end
end

function Renderer.NewHealthBar()
	local bar = {}
	bar.bg  = Drawing.new("Line")
	bar.fg  = Drawing.new("Line")
	bar.bg.Thickness = 3
	bar.fg.Thickness = 3
	bar.bg.Color = Color3.fromRGB(0, 0, 0)
	bar.fg.Color = Color3.fromRGB(0, 255, 0)
	bar.bg.Visible = false
	bar.fg.Visible = false
	return bar
end

function Renderer.UpdateHealthBar(bar, bounds, health, maxHealth)
	if not bounds then
		bar.bg.Visible = false
		bar.fg.Visible = false
		return
	end

	local x = bounds.x - 6
	local top = bounds.y
	local bottom = bounds.y + bounds.height
	local ratio = math.clamp(health / maxHealth, 0, 1)
	local fillY = bottom - (bounds.height * ratio)

	bar.bg.From = Vector2.new(x, top)
	bar.bg.To   = Vector2.new(x, bottom)
	bar.fg.From = Vector2.new(x, fillY)
	bar.fg.To   = Vector2.new(x, bottom)

	local r = 1 - ratio
	local g = ratio
	bar.fg.Color = Color3.new(r, g, 0)

	bar.bg.Visible = true
	bar.fg.Visible = true
end

function Renderer.RemoveHealthBar(bar)
	bar.bg:Remove()
	bar.fg:Remove()
end

function Renderer.NewLabel()
	local label = Drawing.new("Text")
	label.Size = 13
	label.Center = true
	label.Outline = true
	label.OutlineColor = Color3.new(0, 0, 0)
	label.Color = Color3.new(1, 1, 1)
	label.Visible = false
	return label
end

function Renderer.UpdateLabel(label, text, position)
	if not position then
		label.Visible = false
		return
	end
	label.Text = text
	label.Position = position
	label.Visible = true
end

function Renderer.RemoveLabel(label)
	label:Remove()
end

function Renderer.GetDistance(worldPosition)
	local localChar = game:GetService("Players").LocalPlayer.Character
	local root = localChar and localChar:FindFirstChild("HumanoidRootPart")
	if not root then return 0 end
	return (root.Position - worldPosition).Magnitude
end

return Renderer
