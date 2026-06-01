local base = "https://raw.githubusercontent.com/assemblylinearvelocity/sniperarena/master/"

local function load(path)
	local ok, result = pcall(function()
		return loadstring(game:HttpGet(base .. path))()
	end)
	if not ok then
		warn("[Loader] Failed to load: " .. path .. "\n" .. tostring(result))
	end
	return ok and result or nil
end

local Renderer = load("Game/Misc/Visuals/Renderer.lua")

getgenv().Toggles = {}
getgenv().Options = {}

local Library     = load("ObsidianLib/Library.lua")
local SaveManager = load("ObsidianLib/addons/SaveManager.lua")
local ThemeManager = load("ObsidianLib/addons/ThemeManager.lua")

local Window = Library:CreateWindow({
	Title = "Sniper Arena",
	Footer = "assemblylinearvelocity",
	Center = true,
	AutoShow = true,
})

local Toggles = getgenv().Toggles
local Options = getgenv().Options

load("Menu/Visuals.lua")(Window, Toggles, Options)
load("Menu/Legit.lua")(Window, Toggles, Options)
load("Menu/Rage.lua")(Window, Toggles, Options)
load("Menu/Exploits.lua")(Window, Toggles, Options)
load("Menu/Settings.lua")(Window, Toggles, Options, SaveManager, ThemeManager)

local PlayerESP = load("Game/Misc/Visuals/PlayerESP.lua")
local BotESP    = load("Game/Misc/Visuals/BotESP.lua")

if Renderer and PlayerESP then
	PlayerESP.Init(Renderer)
end

if Renderer and BotESP then
	BotESP.Init(Renderer)
end

load("Game/Main/Legit/Legit.lua")
load("Game/Main/Rage/Rage.lua")
load("Game/Exploits/Misc.lua")

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)
SaveManager:SetFolder("SniperArena")
SaveManager:LoadAutoloadConfig()
