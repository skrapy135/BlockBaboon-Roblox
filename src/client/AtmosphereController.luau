-- AtmosphereController.luau: Iluminación dinámica Día/Noche, Clima, Eclipse y Linterna del jugador

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameUtils = require(Shared:WaitForChild("GameUtils"))

local AtmosphereController = {}

local localPlayer = Players.LocalPlayer

local function ensureFlashlight()
    local char = localPlayer.Character
    if not char then return nil end
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if not head then return nil end

    local light = head:FindFirstChild("PlayerFlashlight")
    if not light then
        light = Instance.new("SpotLight")
        light.Name = "PlayerFlashlight"
        light.Face = Enum.NormalId.Front
        light.Angle = 52
        light.Brightness = 2.6
        light.Range = 55
        light.Color = Color3.fromRGB(255, 248, 220)
        light.Parent = head
    end
    return light
end

function AtmosphereController.update(snapshot, myPlayerState)
    if not snapshot then return end

    local nightFactor = snapshot.nightFactor or 0.1
    local eclipseActive = snapshot.eclipse and snapshot.eclipse.active
    local weatherMods = GameUtils.getWeatherModifiers(snapshot.weather, snapshot.biome)

    -- Hora del día en Lighting
    if eclipseActive then
        Lighting.ClockTime = 0
        Lighting.Brightness = 0.45
        Lighting.Ambient = Color3.fromRGB(70, 14, 24)
        Lighting.OutdoorAmbient = Color3.fromRGB(95, 18, 32)
        Lighting.FogColor = Color3.fromRGB(48, 8, 16)
        Lighting.FogEnd = 115
    else
        Lighting.ClockTime = (snapshot.timeOfDay or 0.25) * 24
        Lighting.Brightness = 2.0 - nightFactor * 1.45

        local dayAmb = Color3.fromRGB(115, 128, 145)
        local nightAmb = Color3.fromRGB(18, 22, 38)
        Lighting.Ambient = dayAmb:Lerp(nightAmb, nightFactor)
        Lighting.OutdoorAmbient = dayAmb:Lerp(nightAmb, nightFactor)

        local dayFog = (snapshot.biome == "caverns") and Color3.fromRGB(24, 18, 42) or Color3.fromRGB(145, 175, 200)
        local nightFog = (snapshot.biome == "ruins") and Color3.fromRGB(38, 28, 22) or Color3.fromRGB(12, 16, 28)
        Lighting.FogColor = dayFog:Lerp(nightFog, nightFactor)
        Lighting.FogEnd = math.max(85, weatherMods.fogEnd * (1 - nightFactor * 0.35))
    end

    -- Linterna del jugador
    local flashlight = ensureFlashlight()
    if flashlight and myPlayerState then
        flashlight.Enabled = (myPlayerState.flashlightOn == true)
        local relicMult = (myPlayerState.bonuses and myPlayerState.bonuses.flashlightRangeMult) or 1.0
        flashlight.Range = 55 * weatherMods.flashlightRangeMult * relicMult
    end
end

return AtmosphereController
