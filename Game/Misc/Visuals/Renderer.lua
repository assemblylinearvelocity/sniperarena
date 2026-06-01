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

return Renderer
