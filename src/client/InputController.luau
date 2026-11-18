-- InputController.luau: Controles de teclado para bloques, barricadas, powerups, linterna y sprint

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local GameUtils = require(Shared:WaitForChild("GameUtils"))

local InputController = {}

local BLOCK_KEYS = {
    [Enum.KeyCode.One] = "oak",
    [Enum.KeyCode.Two] = "stone",
    [Enum.KeyCode.Three] = "amethyst",
    [Enum.KeyCode.Four] = "obsidian",
    [Enum.KeyCode.Five] = "ancient",
    [Enum.KeyCode.Six] = "shock",
    [Enum.KeyCode.Seven] = "decoy",
}

function InputController.init(remotes)
    local localPlayer = Players.LocalPlayer

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        local kc = input.KeyCode

        local blockKind = BLOCK_KEYS[kc]
        if blockKind then
            remotes.PlayerAction:FireServer("select_block", { kind = blockKind })
            return
        end

        if kc == Enum.KeyCode.F then
            -- Colocar bloque frente al jugador
            local char = localPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local payload = nil
            if root then
                local ahead = root.Position + root.CFrame.LookVector * (GameConfig.STUD_SCALE * 1.5)
                payload = {
                    gx = GameUtils.toMeters(ahead.X),
                    gz = GameUtils.toMeters(ahead.Z),
                }
            end
            remotes.PlayerAction:FireServer("place_block", payload)
        elseif kc == Enum.KeyCode.X then
            remotes.PlayerAction:FireServer("salvage_block")
        elseif kc == Enum.KeyCode.Z then
            remotes.PlayerAction:FireServer("use_powerup", { kind = "speed" })
        elseif kc == Enum.KeyCode.C then
            remotes.PlayerAction:FireServer("use_powerup", { kind = "cloak" })
        elseif kc == Enum.KeyCode.Q then
            remotes.PlayerAction:FireServer("use_powerup", { kind = "net" })
        elseif kc == Enum.KeyCode.L then
            remotes.PlayerAction:FireServer("toggle_flashlight")
        elseif kc == Enum.KeyCode.G then
            remotes.PlayerAction:FireServer("squad_ping")
        elseif kc == Enum.KeyCode.LeftShift then
            remotes.PlayerAction:FireServer("set_sprint", { active = true })
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.LeftShift then
            remotes.PlayerAction:FireServer("set_sprint", { active = false })
        end
    end)
end

return InputController
