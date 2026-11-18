-- WorldBuilder.luau: Construcción procedural del mundo 3D en Workspace/Arena

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local GameUtils = require(Shared:WaitForChild("GameUtils"))

local WorldBuilder = {}

local function getOrCreateFolder(parent, name)
    local f = parent:FindFirstChild(name)
    if f then f:Destroy() end
    f = Instance.new("Folder")
    f.Name = name
    f.Parent = parent
    return f
end

local function makePart(props)
    local p = Instance.new("Part")
    p.Anchored = (props.Anchored ~= false)
    p.CanCollide = (props.CanCollide ~= false)
    p.Size = props.Size or Vector3.new(4, 4, 4)
    p.CFrame = props.CFrame or CFrame.new(props.Position or Vector3.new(0, 0, 0))
    p.Color = props.Color or Color3.fromRGB(120, 120, 120)
    p.Material = props.Material or Enum.Material.SmoothPlastic
    p.Name = props.Name or "BlockPart"
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    if props.Transparency then
        p.Transparency = props.Transparency
    end
    p.Parent = props.Parent
    return p
end

function WorldBuilder.buildLevel(level, biomeSpec)
    local arena = getOrCreateFolder(workspace, "Arena")
    local blocksFolder = Instance.new("Folder")
    blocksFolder.Name = "PlacedBlocks"
    blocksFolder.Parent = arena

    local pickupsFolder = Instance.new("Folder")
    pickupsFolder.Name = "Pickups"
    pickupsFolder.Parent = arena

    local scale = GameConfig.STUD_SCALE
    local halfStuds = GameConfig.PLAYABLE_HALF_EXTENT * scale

    -- Suelo principal del bioma
    local groundMat = Enum.Material.Grass
    if biomeSpec.kind == "caverns" then
        groundMat = Enum.Material.Slate
    elseif biomeSpec.kind == "ruins" then
        groundMat = Enum.Material.Sandstone
    end

    makePart({
        Name = "Ground",
        Size = Vector3.new(halfStuds * 2 + 24, 4, halfStuds * 2 + 24),
        Position = Vector3.new(0, -2, 0),
        Color = Color3.fromHex(biomeSpec.groundHex),
        Material = groundMat,
        Parent = arena,
    })

    -- Muros perimetrales de la arena
    local wallHeight = 20
    local wallThick = 4
    local wallColor = Color3.fromHex(biomeSpec.wallHex)
    local perimeters = {
        { pos = Vector3.new(0, wallHeight / 2, -halfStuds - wallThick / 2), size = Vector3.new(halfStuds * 2 + wallThick * 2, wallHeight, wallThick) },
        { pos = Vector3.new(0, wallHeight / 2, halfStuds + wallThick / 2), size = Vector3.new(halfStuds * 2 + wallThick * 2, wallHeight, wallThick) },
        { pos = Vector3.new(-halfStuds - wallThick / 2, wallHeight / 2, 0), size = Vector3.new(wallThick, wallHeight, halfStuds * 2) },
        { pos = Vector3.new(halfStuds + wallThick / 2, wallHeight / 2, 0), size = Vector3.new(wallThick, wallHeight, halfStuds * 2) },
    }
    for i, w in ipairs(perimeters) do
        makePart({
            Name = "BorderWall_" .. i,
            Size = w.size,
            Position = w.pos,
            Color = wallColor,
            Material = Enum.Material.Slate,
            Parent = arena,
        })
    end

    -- Obstáculos estáticos del bioma
    local obstacles = GameUtils.generateLevelObstacles(level)
    for idx, box in ipairs(obstacles) do
        local cx = ((box.minX + box.maxX) * 0.5) * scale
        local cz = ((box.minZ + box.maxZ) * 0.5) * scale
        local sx = math.max(1.5, (box.maxX - box.minX) * scale)
        local sz = math.max(1.5, (box.maxZ - box.minZ) * scale)
        local sy = box.height * scale

        if box.kind == "tree" then
            -- Tronco + copa cúbica de secuoya
            local trunkH = sy * 0.65
            makePart({
                Name = "TreeTrunk_" .. idx,
                Size = Vector3.new(sx, trunkH, sz),
                Position = Vector3.new(cx, trunkH * 0.5, cz),
                Color = Color3.fromRGB(88, 56, 36),
                Material = Enum.Material.Wood,
                Parent = arena,
            })
            makePart({
                Name = "TreeLeaves_" .. idx,
                Size = Vector3.new(sx * 2.8, sy * 0.45, sz * 2.8),
                Position = Vector3.new(cx, trunkH + sy * 0.2, cz),
                Color = Color3.fromRGB(28, 78, 42),
                Material = Enum.Material.Grass,
                Parent = arena,
            })
        elseif box.kind == "crystal_spire" then
            local spire = makePart({
                Name = "CrystalSpire_" .. idx,
                Size = Vector3.new(sx, sy, sz),
                Position = Vector3.new(cx, sy * 0.5, cz),
                Color = Color3.fromHex("#c084fc"),
                Material = Enum.Material.Neon,
                Parent = arena,
            })
            local light = Instance.new("PointLight")
            light.Color = Color3.fromHex("#c084fc")
            light.Range = 22
            light.Brightness = 1.4
            light.Parent = spire
        elseif box.kind == "temple_obelisk" then
            makePart({
                Name = "Obelisk_" .. idx,
                Size = Vector3.new(sx, sy, sz),
                Position = Vector3.new(cx, sy * 0.5, cz),
                Color = Color3.fromRGB(95, 82, 62),
                Material = Enum.Material.Brick,
                Parent = arena,
            })
            makePart({
                Name = "ObeliskCap_" .. idx,
                Size = Vector3.new(sx * 0.8, 2.5, sz * 0.8),
                Position = Vector3.new(cx, sy + 1.25, cz),
                Color = Color3.fromHex("#f59e0b"),
                Material = Enum.Material.Neon,
                Parent = arena,
            })
        else
            makePart({
                Name = "Obstacle_" .. idx,
                Size = Vector3.new(sx, sy, sz),
                Position = Vector3.new(cx, sy * 0.5, cz),
                Color = wallColor,
                Material = (biomeSpec.kind == "ruins") and Enum.Material.Brick or Enum.Material.Cobblestone,
                Parent = arena,
            })
        end
    end

    -- Santuarios de Luz (para protegerse en el Eclipse)
    local sanctuaries = GameUtils.getBiomeLightSanctuaries(biomeSpec.kind)
    for _, s in ipairs(sanctuaries) do
        local sx = s.x * scale
        local sz = s.z * scale
        local pad = makePart({
            Name = "SanctuaryPad_" .. s.id,
            Size = Vector3.new(s.radius * scale * 1.4, 0.4, s.radius * scale * 1.4),
            Position = Vector3.new(sx, 0.2, sz),
            Color = Color3.fromRGB(253, 224, 71),
            Material = Enum.Material.Neon,
            Transparency = 0.72,
            CanCollide = false,
            Parent = arena,
        })
        local pillar = makePart({
            Name = "SanctuaryPillar_" .. s.id,
            Size = Vector3.new(2.4, 9, 2.4),
            Position = Vector3.new(sx, 4.5, sz),
            Color = Color3.fromRGB(250, 204, 21),
            Material = Enum.Material.Neon,
            Parent = arena,
        })
        local pLight = Instance.new("PointLight")
        pLight.Color = Color3.fromRGB(254, 240, 138)
        pLight.Range = s.radius * scale * 1.5
        pLight.Brightness = 2.0
        pLight.Parent = pillar
        pad:SetAttribute("SanctuaryId", s.id)
    end

    -- Portal de Escape en PORTAL_POS
    local px = GameConfig.PORTAL_POS.x * scale
    local pz = GameConfig.PORTAL_POS.z * scale
    local portalModel = Instance.new("Model")
    portalModel.Name = "EscapePortal"
    portalModel.Parent = arena

    makePart({
        Name = "PortalBase",
        Size = Vector3.new(16, 1, 12),
        Position = Vector3.new(px, 0.5, pz),
        Color = Color3.fromRGB(30, 41, 59),
        Material = Enum.Material.Metal,
        Parent = portalModel,
    })
    makePart({
        Name = "PortalLeft",
        Size = Vector3.new(2.5, 16, 2.5),
        Position = Vector3.new(px - 6.5, 8.5, pz),
        Color = Color3.fromRGB(51, 65, 85),
        Material = Enum.Material.Slate,
        Parent = portalModel,
    })
    makePart({
        Name = "PortalRight",
        Size = Vector3.new(2.5, 16, 2.5),
        Position = Vector3.new(px + 6.5, 8.5, pz),
        Color = Color3.fromRGB(51, 65, 85),
        Material = Enum.Material.Slate,
        Parent = portalModel,
    })
    makePart({
        Name = "PortalTop",
        Size = Vector3.new(15.5, 2.5, 2.5),
        Position = Vector3.new(px, 16.5, pz),
        Color = Color3.fromRGB(51, 65, 85),
        Material = Enum.Material.Slate,
        Parent = portalModel,
    })

    local core = makePart({
        Name = "PortalCore",
        Size = Vector3.new(10.5, 14, 1),
        Position = Vector3.new(px, 8.5, pz),
        Color = Color3.fromRGB(56, 189, 248),
        Material = Enum.Material.Neon,
        Transparency = 0.45,
        CanCollide = false,
        Parent = portalModel,
    })
    local portalLight = Instance.new("PointLight")
    portalLight.Color = Color3.fromRGB(56, 189, 248)
    portalLight.Range = 36
    portalLight.Brightness = 2.4
    portalLight.Parent = core

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "PortalPrompt"
    prompt.ActionText = "Depositar Núcleos / Escapar"
    prompt.ObjectText = "Portal de Escape"
    prompt.MaxActivationDistance = 14
    prompt.HoldDuration = 0.35
    prompt.Parent = core

    return arena, blocksFolder, pickupsFolder, core, prompt
end

function WorldBuilder.spawnPlacedBlock(blocksFolder, blockId, gx, gz, kind, hp, maxHp)
    local spec = GameConfig.BLOCK_SPECS[kind]
    if not spec then return nil end

    local scale = GameConfig.STUD_SCALE
    local part = makePart({
        Name = "Block_" .. tostring(blockId),
        Size = Vector3.new(scale, scale, scale),
        Position = Vector3.new(gx * scale, scale * 0.5, gz * scale),
        Color = Color3.fromHex(spec.accentHex),
        Material = spec.material,
        Parent = blocksFolder,
    })
    part:SetAttribute("BlockId", blockId)
    part:SetAttribute("Kind", kind)
    part:SetAttribute("Hp", hp)
    part:SetAttribute("MaxHp", maxHp)

    if kind == "amethyst" or kind == "shock" or kind == "decoy" then
        local light = Instance.new("PointLight")
        light.Color = Color3.fromHex(spec.accentHex)
        light.Range = (kind == "amethyst") and (GameConfig.ECLIPSE_AMETHYST_LIGHT_RADIUS * scale) or 14
        light.Brightness = 1.6
        light.Parent = part
    end

    return part
end

function WorldBuilder.spawnPickupPart(pickupsFolder, pickupId, kind, x, z)
    local scale = GameConfig.STUD_SCALE
    local color = Color3.fromRGB(255, 255, 255)
    local label = "Objeto"

    if kind == "beacon" then
        color = Color3.fromRGB(56, 189, 248)
        label = "Núcleo del Portal"
    elseif kind == "power_speed" then
        color = Color3.fromHex(GameConfig.POWERUP_SPECS.speed.accentHex)
        label = "Impulso de Velocidad"
    elseif kind == "power_cloak" then
        color = Color3.fromHex(GameConfig.POWERUP_SPECS.cloak.accentHex)
        label = "Manto Invisible"
    elseif kind == "power_net" then
        color = Color3.fromHex(GameConfig.POWERUP_SPECS.net.accentHex)
        label = "Lanzarred Captora"
    elseif GameConfig.BLOCK_SPECS[kind] then
        local bSpec = GameConfig.BLOCK_SPECS[kind]
        color = Color3.fromHex(bSpec.accentHex)
        label = bSpec.name
    end

    local part = makePart({
        Name = "Pickup_" .. tostring(pickupId),
        Size = Vector3.new(2.2, 2.2, 2.2),
        Position = Vector3.new(x * scale, 2.2, z * scale),
        Color = color,
        Material = Enum.Material.Neon,
        CanCollide = false,
        Parent = pickupsFolder,
    })
    part:SetAttribute("PickupId", pickupId)
    part:SetAttribute("Kind", kind)

    local light = Instance.new("PointLight")
    light.Color = color
    light.Range = 12
    light.Brightness = 1.3
    light.Parent = part

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 140, 0, 28)
    billboard.StudsOffset = Vector3.new(0, 2.4, 0)
    billboard.AlwaysOnTop = false
    billboard.MaxDistance = 45
    billboard.Parent = part

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = label
    txt.TextColor3 = color
    txt.TextStrokeTransparency = 0.3
    txt.Font = Enum.Font.GothamBold
    txt.TextScaled = true
    txt.Parent = billboard

    return part
end

return WorldBuilder
