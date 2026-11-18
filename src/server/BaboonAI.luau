-- BaboonAI.luau: Modelo 3D Voxel del Scary Baboon + Máquina de estados de IA

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local GameUtils = require(Shared:WaitForChild("GameUtils"))

local BaboonAI = {}

local function createBox(parent, name, size, offset, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.CanCollide = false
    p.Size = size
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.CFrame = CFrame.new(offset)
    p.Parent = parent
    return p
end

function BaboonAI.spawnModel(parentFolder, variantKind, isMinion)
    local spec = GameUtils.getBaboonVariantSpec(variantKind)
    local scaleMult = isMinion and 0.62 or 1.0
    local furColor = Color3.fromHex(spec.furHex)
    local accentColor = Color3.fromHex(spec.accentHex)

    local model = Instance.new("Model")
    model.Name = isMinion and "HordeMinion" or "ScaryBaboon"

    local root = createBox(model, "HumanoidRootPart", Vector3.new(4, 6, 4) * scaleMult, Vector3.new(0, 4 * scaleMult, 0), furColor)
    root.Transparency = 1
    model.PrimaryPart = root

    -- Torso
    createBox(model, "Torso", Vector3.new(4.8, 5.2, 3.6) * scaleMult, Vector3.new(0, 5.2 * scaleMult, 0), furColor, Enum.Material.Slate)
    -- Cabeza
    createBox(model, "Head", Vector3.new(3.6, 3.4, 3.4) * scaleMult, Vector3.new(0, 9.2 * scaleMult, -0.6 * scaleMult), furColor, Enum.Material.Slate)
    -- Hocico
    createBox(model, "Snout", Vector3.new(2.2, 1.8, 1.8) * scaleMult, Vector3.new(0, 8.5 * scaleMult, -2.6 * scaleMult), Color3.fromRGB(68, 42, 36))
    -- Ojos brillantes
    local eyeL = createBox(model, "EyeL", Vector3.new(0.65, 0.55, 0.4) * scaleMult, Vector3.new(-0.9 * scaleMult, 9.6 * scaleMult, -2.35 * scaleMult), accentColor, Enum.Material.Neon)
    createBox(model, "EyeR", Vector3.new(0.65, 0.55, 0.4) * scaleMult, Vector3.new(0.9 * scaleMult, 9.6 * scaleMult, -2.35 * scaleMult), accentColor, Enum.Material.Neon)

    local eyeLight = Instance.new("PointLight")
    eyeLight.Color = accentColor
    eyeLight.Range = isMinion and 14 or 26
    eyeLight.Brightness = 2.0
    eyeLight.Parent = eyeL

    -- Brazos largos de babuino
    createBox(model, "ArmL", Vector3.new(1.6, 5.6, 1.6) * scaleMult, Vector3.new(-3.3 * scaleMult, 4.4 * scaleMult, -0.5 * scaleMult), furColor, Enum.Material.Slate)
    createBox(model, "ArmR", Vector3.new(1.6, 5.6, 1.6) * scaleMult, Vector3.new(3.3 * scaleMult, 4.4 * scaleMult, -0.5 * scaleMult), furColor, Enum.Material.Slate)

    -- Piernas
    createBox(model, "LegL", Vector3.new(1.8, 3.2, 1.8) * scaleMult, Vector3.new(-1.4 * scaleMult, 1.6 * scaleMult, 0.3 * scaleMult), furColor, Enum.Material.Slate)
    createBox(model, "LegR", Vector3.new(1.8, 3.2, 1.8) * scaleMult, Vector3.new(1.4 * scaleMult, 1.6 * scaleMult, 0.3 * scaleMult), furColor, Enum.Material.Slate)

    -- Detalles de variante (cristales abisales, hombreras ancestrales, magma berserker)
    if variantKind == "abyssal" or variantKind == "ancestral" or variantKind == "berserker" then
        createBox(model, "ShoulderL", Vector3.new(1.8, 1.6, 2.0) * scaleMult, Vector3.new(-3.1 * scaleMult, 7.6 * scaleMult, 0), accentColor, Enum.Material.Neon)
        createBox(model, "ShoulderR", Vector3.new(1.8, 1.6, 2.0) * scaleMult, Vector3.new(3.1 * scaleMult, 7.6 * scaleMult, 0), accentColor, Enum.Material.Neon)
    end

    -- Billboard de estado sobre el Babuino
    if not isMinion then
        local bb = Instance.new("BillboardGui")
        bb.Name = "StatusGui"
        bb.Size = UDim2.new(0, 180, 0, 36)
        bb.StudsOffset = Vector3.new(0, 7.5, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = 90
        bb.Parent = root

        local lbl = Instance.new("TextLabel")
        lbl.Name = "StateLabel"
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 0.4
        lbl.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
        lbl.TextColor3 = accentColor
        lbl.Font = Enum.Font.GothamBold
        lbl.TextScaled = true
        lbl.Text = spec.name .. " [PATRULLA]"
        lbl.Parent = bb
    end

    -- Guardar offsets relativos para mover todas las partes suavemente
    local offsets = {}
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("BasePart") and desc ~= root then
            offsets[desc] = root.CFrame:ToObjectSpace(desc.CFrame)
        end
    end

    model.Parent = parentFolder
    return {
        model = model,
        root = root,
        offsets = offsets,
        variantKind = variantKind,
        isMinion = isMinion,
    }
end

function BaboonAI.setWorldPosition(rig, xMeters, zMeters, yawRad, animPhase)
    if not rig or not rig.root or not rig.model.Parent then return end
    local scale = GameConfig.STUD_SCALE
    local bob = math.abs(math.sin(animPhase or 0)) * (rig.isMinion and 0.6 or 1.0)
    local basePos = Vector3.new(xMeters * scale, (rig.isMinion and 2.5 or 4.0) + bob, zMeters * scale)
    local rootCf = CFrame.new(basePos) * CFrame.Angles(0, yawRad or 0, 0)
    rig.root.CFrame = rootCf

    for part, relCf in pairs(rig.offsets) do
        if part and part.Parent then
            part.CFrame = rootCf * relCf
        end
    end
end

function BaboonAI.createState(biomeSpec)
    return {
        x = 0,
        z = -12,
        yaw = 0,
        behavior = "patrol", -- patrol | stalk | chase | pack_stalk | smash | stunned | trapped | distracted
        variant = "stalker",
        targetUserId = nil,
        stunTimer = 0,
        trapTimer = 0,
        distractTimer = 0,
        distractX = 0,
        distractZ = 0,
        slamCooldown = 0,
        patrolX = 12,
        patrolZ = -10,
        animPhase = 0,
        biomeSpec = biomeSpec,
    }
end

function BaboonAI.update(state, rig, dt, playersMap, placedBlocks, biomeSpec, nightFactor, level, callbacks)
    if not state then return end
    local variant = GameUtils.getActiveBaboonVariant(level, biomeSpec.kind, nightFactor)
    state.variant = variant

    if state.slamCooldown > 0 then
        state.slamCooldown = math.max(0, state.slamCooldown - dt)
    end

    -- Estados de incapacidad / distracción
    if state.trapTimer > 0 then
        state.trapTimer = math.max(0, state.trapTimer - dt)
        state.behavior = "trapped"
        BaboonAI.setWorldPosition(rig, state.x, state.z, state.yaw, state.animPhase)
        return
    end

    if state.stunTimer > 0 then
        state.stunTimer = math.max(0, state.stunTimer - dt)
        state.behavior = "stunned"
        BaboonAI.setWorldPosition(rig, state.x, state.z, state.yaw, state.animPhase)
        return
    end

    -- Comprobar Trampa Señuelo Sónica cercana
    if state.distractTimer > 0 then
        state.distractTimer = math.max(0, state.distractTimer - dt)
        state.behavior = "distracted"
    else
        for _, blk in pairs(placedBlocks) do
            if blk.kind == "decoy" then
                local d = math.sqrt((blk.gx - state.x) ^ 2 + (blk.gz - state.z) ^ 2)
                if d <= GameConfig.DECOY_TRAP_RADIUS then
                    state.distractTimer = GameConfig.DECOY_DISTRACT_DURATION
                    state.distractX = blk.gx
                    state.distractZ = blk.gz
                    state.behavior = "distracted"
                    if callbacks and callbacks.onDecoyTriggered then
                        callbacks.onDecoyTriggered(blk)
                    end
                    break
                end
            end
        end
    end

    local speed = biomeSpec.patrolSpeed
    local goalX, goalZ = state.patrolX, state.patrolZ

    if state.behavior == "distracted" then
        goalX, goalZ = state.distractX, state.distractZ
        speed = biomeSpec.chaseSpeed * 0.85
    else
        -- Buscar jugador más cercano visible
        local bestPlayer = nil
        local bestDist = math.huge
        local baseDetect = biomeSpec.detectionRadius * (1 + nightFactor * 0.25)

        for _, pState in pairs(playersMap) do
            if pState.alive and not pState.escaped and not pState.cloakActive then
                local detect = baseDetect
                if pState.flashlightOn then
                    detect = detect + 3.2
                end
                local d = math.sqrt((pState.x - state.x) ^ 2 + (pState.z - state.z) ^ 2)
                if d <= detect and d < bestDist then
                    bestDist = d
                    bestPlayer = pState
                end
            end
        end

        if bestPlayer then
            state.targetUserId = bestPlayer.userId
            goalX, goalZ = bestPlayer.x, bestPlayer.z
            if bestDist <= 2.3 and state.slamCooldown <= 0 then
                state.behavior = "smash"
                state.slamCooldown = 1.6
                if callbacks and callbacks.onPlayerSlam then
                    callbacks.onPlayerSlam(bestPlayer, biomeSpec.slamDamage)
                end
            elseif bestDist <= baseDetect * 0.68 then
                state.behavior = "chase"
                speed = biomeSpec.chaseSpeed * (1 + nightFactor * 0.18)
            else
                state.behavior = "stalk"
                speed = biomeSpec.patrolSpeed * 1.15
            end
        else
            state.targetUserId = nil
            state.behavior = "patrol"
            local dPatrol = math.sqrt((state.patrolX - state.x) ^ 2 + (state.patrolZ - state.z) ^ 2)
            if dPatrol < 2.0 then
                local lim = GameConfig.PLAYABLE_HALF_EXTENT - 6
                state.patrolX = (math.random() * 2 - 1) * lim
                state.patrolZ = (math.random() * 2 - 1) * lim
                goalX, goalZ = state.patrolX, state.patrolZ
            end
        end
    end

    -- Mover hacia objetivo y verificar colisión con barricadas o trampas shock
    local dx = goalX - state.x
    local dz = goalZ - state.z
    local dist = math.sqrt(dx * dx + dz * dz)

    if dist > 0.2 then
        local nx = dx / dist
        local nz = dz / dist
        state.yaw = math.atan2(-nx, -nz)
        local step = math.min(dist, speed * dt)
        local nextX = state.x + nx * step
        local nextZ = state.z + nz * step

        local blockedBy = nil
        for _, blk in pairs(placedBlocks) do
            if math.abs(nextX - blk.gx) < 1.15 and math.abs(nextZ - blk.gz) < 1.15 then
                blockedBy = blk
                break
            end
        end

        if blockedBy then
            if blockedBy.kind == "shock" then
                state.stunTimer = 3.8
                state.behavior = "stunned"
                if callbacks and callbacks.onShockTriggered then
                    callbacks.onShockTriggered(blockedBy)
                end
            elseif state.slamCooldown <= 0 then
                state.behavior = "smash"
                state.slamCooldown = 1.2
                if callbacks and callbacks.onBlockDamaged then
                    callbacks.onBlockDamaged(blockedBy, biomeSpec.slamDamage)
                end
            end
        else
            local lim = GameConfig.PLAYABLE_HALF_EXTENT - 1.5
            state.x = math.clamp(nextX, -lim, lim)
            state.z = math.clamp(nextZ, -lim, lim)
            state.animPhase = state.animPhase + dt * speed * 1.8
        end
    end

    -- Actualizar etiqueta de estado sobre el Babuino
    if rig and rig.root then
        local bb = rig.root:FindFirstChild("StatusGui")
        if bb then
            local lbl = bb:FindFirstChild("StateLabel")
            if lbl then
                local spec = GameUtils.getBaboonVariantSpec(state.variant)
                lbl.Text = string.format("%s [%s]", spec.name, string.upper(state.behavior))
            end
        end
    end

    BaboonAI.setWorldPosition(rig, state.x, state.z, state.yaw, state.animPhase)
end

return BaboonAI
