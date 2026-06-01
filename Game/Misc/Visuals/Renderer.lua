local EspRenderer = {}
EspRenderer.__index = EspRenderer

local Camera  = workspace.CurrentCamera
local BAR_GAP = 3

local BODY_PARTS = {
	"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart",
	"LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
	"RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local function NewLine(color, thickness)
	local l = Drawing.new("Line")
	l.Visible   = false
	l.Color     = color
	l.Thickness = thickness
	return l
end

local function NewBoxSet(color, thickness)
	return {
		Top    = NewLine(color, thickness),
		Bottom = NewLine(color, thickness),
		Left   = NewLine(color, thickness),
		Right  = NewLine(color, thickness),
	}
end

local function SetSetVisible(set, visible)
	for _, l in pairs(set) do l.Visible = visible end
end

local function NewText(size)
	local t = Drawing.new("Text")
	t.Visible = false
	t.Size    = size
	t.Center  = true
	t.Outline = true
	t.Color   = Color3.fromRGB(255, 255, 255)
	return t
end

local function HpToColor(pct)
	pct = math.clamp(pct, 0, 1)
	if pct > 0.5 then
		return Color3.fromRGB(math.floor(255 * (1 - pct) * 2), 255, 0)
	else
		return Color3.fromRGB(255, math.floor(255 * pct * 2), 0)
	end
end

local function GetBoundingBox(character)
	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	local anyOnScreen = false

	for _, partName in ipairs(BODY_PARTS) do
		local part = character:FindFirstChild(partName)
		if not part or not part:IsA("BasePart") then continue end
		local size = part.Size
		local cf   = part.CFrame
		local offsets = {
			Vector3.new( size.X/2,  size.Y/2,  size.Z/2),
			Vector3.new(-size.X/2,  size.Y/2,  size.Z/2),
			Vector3.new( size.X/2, -size.Y/2,  size.Z/2),
			Vector3.new(-size.X/2, -size.Y/2,  size.Z/2),
			Vector3.new( size.X/2,  size.Y/2, -size.Z/2),
			Vector3.new(-size.X/2,  size.Y/2, -size.Z/2),
			Vector3.new( size.X/2, -size.Y/2, -size.Z/2),
			Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
		}
		for _, offset in ipairs(offsets) do
			local screen, onScreen = Camera:WorldToViewportPoint(cf * offset)
			if onScreen then
				anyOnScreen = true
				minX = math.min(minX, screen.X)
				minY = math.min(minY, screen.Y)
				maxX = math.max(maxX, screen.X)
				maxY = math.max(maxY, screen.Y)
			end
		end
	end

	if not anyOnScreen then return nil, nil end
	return Vector2.new(math.round(minX), math.round(minY)),
	       Vector2.new(math.round(maxX), math.round(maxY))
end

local function GetHealth(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return 100, 100 end
	local maxHp = humanoid.MaxHealth
	if maxHp <= 0 then maxHp = 100 end
	return math.clamp(humanoid.Health, 0, maxHp), maxHp
end

function EspRenderer.new(name)
	local self = setmetatable({}, EspRenderer)
	self.name     = name
	self._smoothHp = 1
	self.box = {
		outer = NewBoxSet(Color3.fromRGB(0, 0, 0), 1),
		main  = NewBoxSet(Color3.fromRGB(255, 255, 255), 1),
		inner = NewBoxSet(Color3.fromRGB(0, 0, 0), 1),
	}
	self.healthBar = {
		outlineLeft   = NewLine(Color3.fromRGB(0, 0, 0), 1),
		outlineRight  = NewLine(Color3.fromRGB(0, 0, 0), 1),
		outlineTop    = NewLine(Color3.fromRGB(0, 0, 0), 1),
		outlineBottom = NewLine(Color3.fromRGB(0, 0, 0), 1),
		fill          = NewLine(Color3.fromRGB(0, 255, 0), 2),
	}
	self.nameText = NewText(14)
	self.distText = NewText(11)
	return self
end

function EspRenderer:_UpdateBox(min, max, color)
	local o = 1
	self.box.outer.Top.From    = Vector2.new(min.X-o, min.Y-o)
	self.box.outer.Top.To      = Vector2.new(max.X+o+1, min.Y-o)
	self.box.outer.Bottom.From = Vector2.new(min.X-o, max.Y+o)
	self.box.outer.Bottom.To   = Vector2.new(max.X+o+1, max.Y+o)
	self.box.outer.Left.From   = Vector2.new(min.X-o, min.Y-o)
	self.box.outer.Left.To     = Vector2.new(min.X-o, max.Y+o+1)
	self.box.outer.Right.From  = Vector2.new(max.X+o, min.Y-o)
	self.box.outer.Right.To    = Vector2.new(max.X+o, max.Y+o+1)
	SetSetVisible(self.box.outer, true)

	self.box.main.Top.From    = Vector2.new(min.X, min.Y)
	self.box.main.Top.To      = Vector2.new(max.X+1, min.Y)
	self.box.main.Bottom.From = Vector2.new(min.X, max.Y)
	self.box.main.Bottom.To   = Vector2.new(max.X+1, max.Y)
	self.box.main.Left.From   = Vector2.new(min.X, min.Y)
	self.box.main.Left.To     = Vector2.new(min.X, max.Y+1)
	self.box.main.Right.From  = Vector2.new(max.X, min.Y)
	self.box.main.Right.To    = Vector2.new(max.X, max.Y+1)
	for _, l in pairs(self.box.main) do
		l.Color   = color
		l.Visible = true
	end

	local i = 1
	self.box.inner.Top.From    = Vector2.new(min.X+i, min.Y+i)
	self.box.inner.Top.To      = Vector2.new(max.X-i+1, min.Y+i)
	self.box.inner.Bottom.From = Vector2.new(min.X+i, max.Y-i)
	self.box.inner.Bottom.To   = Vector2.new(max.X-i+1, max.Y-i)
	self.box.inner.Left.From   = Vector2.new(min.X+i, min.Y+i)
	self.box.inner.Left.To     = Vector2.new(min.X+i, max.Y-i+1)
	self.box.inner.Right.From  = Vector2.new(max.X-i, min.Y+i)
	self.box.inner.Right.To    = Vector2.new(max.X-i, max.Y-i+1)
	SetSetVisible(self.box.inner, true)
end

function EspRenderer:_UpdateHealthBar(min, max, character)
	local hp, maxHp = GetHealth(character)
	self._smoothHp  = self._smoothHp + (hp / maxHp - self._smoothHp) * 0.12
	local pct    = math.clamp(self._smoothHp, 0, 1)
	local top    = math.round(min.Y)
	local bottom = math.round(max.Y)
	local height = bottom - top
	local barX   = math.round(min.X - BAR_GAP - 1)
	local fillY  = math.round(bottom - height * pct)

	self.healthBar.outlineLeft.From    = Vector2.new(barX-1, top-1)
	self.healthBar.outlineLeft.To      = Vector2.new(barX-1, bottom+1)
	self.healthBar.outlineLeft.Visible = true
	self.healthBar.outlineRight.From    = Vector2.new(barX+1, top-1)
	self.healthBar.outlineRight.To      = Vector2.new(barX+1, bottom+1)
	self.healthBar.outlineRight.Visible = true
	self.healthBar.outlineTop.From    = Vector2.new(barX-1, top-1)
	self.healthBar.outlineTop.To      = Vector2.new(barX+2, top-1)
	self.healthBar.outlineTop.Visible = true
	self.healthBar.outlineBottom.From    = Vector2.new(barX-1, bottom+1)
	self.healthBar.outlineBottom.To      = Vector2.new(barX+2, bottom+1)
	self.healthBar.outlineBottom.Visible = true
	self.healthBar.fill.From    = Vector2.new(barX, math.max(fillY, top))
	self.healthBar.fill.To      = Vector2.new(barX, bottom+1)
	self.healthBar.fill.Color   = HpToColor(pct)
	self.healthBar.fill.Visible = pct > 0
end

function EspRenderer:HideAll()
	for _, set in pairs(self.box) do SetSetVisible(set, false) end
	for _, l in pairs(self.healthBar) do l.Visible = false end
	self.nameText.Visible = false
	self.distText.Visible = false
end

function EspRenderer:Update(character, color, showBox, showHealth, showName, showDist, distUnit)
	if not character or not character.Parent then
		self:HideAll()
		return
	end

	local min, max = GetBoundingBox(character)
	if not min or not max then
		self:HideAll()
		return
	end

	if showBox then
		self:_UpdateBox(min, max, color)
	else
		for _, set in pairs(self.box) do SetSetVisible(set, false) end
	end

	if showHealth then
		self:_UpdateHealthBar(min, max, character)
	else
		for _, l in pairs(self.healthBar) do l.Visible = false end
	end

	if showName then
		local fontSize = math.clamp(math.round((max.Y - min.Y) * 0.15), 13, 18)
		self.nameText.Size     = fontSize
		self.nameText.Text     = self.name
		self.nameText.Position = Vector2.new(math.round((min.X + max.X) / 2), math.round(min.Y - fontSize - 2))
		self.nameText.Visible  = true
	else
		self.nameText.Visible = false
	end

	if showDist then
		local hrp      = character:FindFirstChild("HumanoidRootPart")
		local localChar = game:GetService("Players").LocalPlayer.Character
		local localHRP  = localChar and localChar:FindFirstChild("HumanoidRootPart")
		if hrp and localHRP then
			local studs = (hrp.Position - localHRP.Position).Magnitude
			local label = (distUnit == "Meters")
				and string.format("[%.0fm]", studs * 0.28)
				or  string.format("[%.0fstu]", studs)
			self.distText.Size     = 11
			self.distText.Text     = label
			self.distText.Position = Vector2.new(math.round((min.X + max.X) / 2), math.round(max.Y + 4))
			self.distText.Color    = Color3.fromRGB(200, 200, 200)
			self.distText.Visible  = true
		else
			self.distText.Visible = false
		end
	else
		self.distText.Visible = false
	end
end

function EspRenderer:Destroy()
	for _, set in pairs(self.box) do
		for _, l in pairs(set) do l:Remove() end
	end
	for _, l in pairs(self.healthBar) do l:Remove() end
	self.nameText:Remove()
	self.distText:Remove()
end

return EspRenderer
