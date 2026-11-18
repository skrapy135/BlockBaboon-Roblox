-- ClientMain.client.luau: Punto de entrada del cliente en Roblox

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))

local AtmosphereController = require(script.Parent:WaitForChild("AtmosphereController"))
local SoundController = require(script.Parent:WaitForChild("SoundController"))
local InputController = require(script.Parent:WaitForChild("InputController"))
local HudGui = require(script.Parent:WaitForChild("HudGui"))

local localPlayer = Players.LocalPlayer
local Remotes = RemoteEvents.getClient()

SoundController.init()
HudGui.init(Remotes)
InputController.init(Remotes)

Remotes.ProfileSync.OnClientEvent:Connect(function(profile, clan)
    HudGui.setProfile(profile, clan)
end)

Remotes.SoundCue.OnClientEvent:Connect(function(cueName)
    SoundController.play(cueName)
end)

Remotes.GameBanner.OnClientEvent:Connect(function(text, hexColor)
    HudGui.showBanner(text, hexColor)
end)

Remotes.StateSync.OnClientEvent:Connect(function(snapshot)
    local myState = snapshot.players and snapshot.players[localPlayer.UserId]
    AtmosphereController.update(snapshot, myState)
    HudGui.updateSnapshot(snapshot, myState)
end)
