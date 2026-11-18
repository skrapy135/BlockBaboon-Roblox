-- SoundController.luau: Gestión de efectos de sonido en Roblox SoundService

local SoundService = game:GetService("SoundService")

local SoundController = {}
SoundController.muted = false

local SOUND_IDS = {
    pickup = "rbxassetid://12221967",
    place_block = "rbxassetid://12222030",
    craft = "rbxassetid://12222216",
    powerup = "rbxassetid://12222253",
    net_hit = "rbxassetid://12222084",
    beacon_deposit = "rbxassetid://12222216",
    escape = "rbxassetid://12222253",
    baboon_slam = "rbxassetid://12222084",
    block_hit = "rbxassetid://12222030",
    shock_stun = "rbxassetid://12222152",
    decoy_beep = "rbxassetid://12221976",
    eclipse_start = "rbxassetid://12222152",
    ping = "rbxassetid://12221976",
}

local soundPool = {}

function SoundController.init()
    for name, assetId in pairs(SOUND_IDS) do
        local s = Instance.new("Sound")
        s.Name = "Cue_" .. name
        s.SoundId = assetId
        s.Volume = 0.55
        s.Parent = SoundService
        soundPool[name] = s
    end
end

function SoundController.play(cueName)
    if SoundController.muted then return end
    local s = soundPool[cueName]
    if s then
        pcall(function()
            s:Play()
        end)
    end
end

function SoundController.toggleMute()
    SoundController.muted = not SoundController.muted
    return SoundController.muted
end

return SoundController
