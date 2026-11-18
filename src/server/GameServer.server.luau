-- GameServer.server.luau: Servidor autoritativo de Block Baboon: Fuga Cúbica (Roblox)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local GameUtils = require(Shared:WaitForChild("GameUtils"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))

local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local BaboonAI = require(script.Parent:WaitForChild("BaboonAI"))

local Remotes = RemoteEvents.initServer()

-- Estado global de la sala / partida
local room = {
    phase = "lobby", -- lobby | playing | escaped | gameover
    mode = "survival", -- survival | training
    level = 1,
    biome = "forest",
    timeOfDay = 0.25, -- 0..1
    weather = { kind = "clear", timerSec = 45 },
    eclipse = GameUtils.createDefaultEclipseState and GameUtils.createDefaultEclipseState("forest") or {
        active = false,
        remainingSec = 0,
        totalDurationSec = GameConfig.ECLIPSE_DURATION_SEC,
        sanctuaries = GameUtils.getBiomeLightSanctuaries("forest"),
    },
    eclipseCooldownSec = 55,
    horde = {
        phase = "calm",
        timerSec = 65,
        minions = {},
    },
    beaconsDeposited = 0,
    beaconsRequired = 4,
    portalUnlocked = false,
    score = 0,
    players = {}, -- [userId] = PlayerState
    placedBlocks = {}, -- [id] = PlacedBlockState
    pickups = {}, -- [id] = WorldPickupState
    nextId = 1,
    logs = {},
}

local arenaFolder, blocksFolder, pickupsFolder, portalCore, portalPrompt
local baboonState = nil
local baboonRig = nil
local minionRigs = {}
local lastTick = os.clock()
local syncAccumulator = 0

local function pushLog(msg)
    table.insert(room.logs, 1, msg)
    if #room.logs > 8 then
        table.remove(room.logs)
    end
end

local function applyAppearanceToCharacter(player, appearance)
    local char = player.Character
    if not char or not appearance then return end
    local jacketCol = Color3.fromHex(appearance.jacketColor or "#38bdf8")
    local pantsCol = Color3.fromHex(appearance.pantsColor or "#1e293b")
    local accentCol = Color3.fromHex(appearance.accentColor or "#fbbf24")

    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("BasePart") then
            local n = string.lower(desc.Name)
            if string.find(n, "torso") or string.find(n, "arm") or string.find(n, "hand") then
                desc.Color = jacketCol
            elseif string.find(n, "leg") or string.find(n, "foot") then
                desc.Color = pantsCol
            elseif string.find(n, "head") then
                desc.Color = accentCol
            end
        end
    end
end

local function createInitialPlayerState(player, profile)
    local bonuses = GameUtils.getRelicPermanentBonuses(profile.unlockedRelicsMask or 0)
    return {
        userId = player.UserId,
        name = player.DisplayName,
        alive = true,
        escaped = false,
        hp = 100,
        maxHp = 100,
        stamina = 100,
        maxStamina = 100,
        sprinting = false,
        flashlightOn = true,
        speedTimer = 0,
        cloakTimer = 0,
        cloakActive = false,
        carryingBeacons = 0,
        selectedBlock = "oak",
        x = GameConfig.SPAWN_POS.x,
        z = GameConfig.SPAWN_POS.z,
        blocks = {
            oak = 4,
            stone = 2,
            amethyst = 1,
            obsidian = 0,
            ancient = 0,
            shock = 1,
            decoy = 1,
        },
        powerups = {
            speed = 1,
            cloak = 1,
            net = 1,
        },
        bonuses = bonuses,
        maxBlockCapacity = 16 + bonuses.extraBlockCapacity,
    }
end

local function spawnRandomPickups(biomeSpec)
    local scaleLim = GameConfig.PLAYABLE_HALF_EXTENT - 5
    local function randCoord()
        return (math.random() * 2 - 1) * scaleLim
    end

    -- Núcleos del Portal (beacons)
    local totalBeacons = room.beaconsRequired + 2
    for _ = 1, totalBeacons do
        local id = room.nextId
        room.nextId = room.nextId + 1
        local px, pz = randCoord(), randCoord()
        local part = WorldBuilder.spawnPickupPart(pickupsFolder, id, "beacon", px, pz)
        room.pickups[id] = { id = id, kind = "beacon", x = px, z = pz, part = part }
    end

    -- Bloques del bioma
    local blockPool = { "oak", "stone", "amethyst", "obsidian", "ancient" }
    for i = 1, 18 do
        local id = room.nextId
        room.nextId = room.nextId + 1
        local kind = biomeSpec.featuredBlocks[((i - 1) % #biomeSpec.featuredBlocks) + 1]
        if math.random() < 0.35 then
            kind = blockPool[math.random(1, #blockPool)]
        end
        local px, pz = randCoord(), randCoord()
        local part = WorldBuilder.spawnPickupPart(pickupsFolder, id, kind, px, pz)
        room.pickups[id] = { id = id, kind = kind, x = px, z = pz, part = part }
    end

    -- Powerups
    for _, pKind in ipairs({ "power_speed", "power_cloak", "power_net" }) do
        for _ = 1, 2 do
            local id = room.nextId
            room.nextId = room.nextId + 1
            local px, pz = randCoord(), randCoord()
            local part = WorldBuilder.spawnPickupPart(pickupsFolder, id, pKind, px, pz)
            room.pickups[id] = { id = id, kind = pKind, x = px, z = pz, part = part }
        end
    end
end

local function setupMatch(mode, level)
    room.mode = mode or "survival"
    room.level = level or 1
    local biomeSpec = GameUtils.getBiomeForLevel(room.level)
    room.biome = biomeSpec.kind
    room.phase = "playing"
    room.timeOfDay = 0.25
    room.weather = { kind = "clear", timerSec = 45 }
    room.eclipse = {
        active = false,
        remainingSec = 0,
        totalDurationSec = GameConfig.ECLIPSE_DURATION_SEC,
        sanctuaries = GameUtils.getBiomeLightSanctuaries(room.biome),
    }
    room.eclipseCooldownSec = 50
    room.horde = { phase = "calm", timerSec = 60, minions = {} }
    room.beaconsDeposited = 0
    room.beaconsRequired = (room.mode == "training") and 2 or biomeSpec.beaconsBase
    room.portalUnlocked = false
    room.placedBlocks = {}
    room.pickups = {}
    room.logs = {}
    minionRigs = {}

    arenaFolder, blocksFolder, pickupsFolder, portalCore, portalPrompt = WorldBuilder.buildLevel(room.level, biomeSpec)

    -- Conectar ProximityPrompt del Portal
    portalPrompt.Triggered:Connect(function(player)
        local pState = room.players[player.UserId]
        if not pState or not pState.alive or room.phase ~= "playing" then return end

        if pState.carryingBeacons > 0 then
            local deposited = pState.carryingBeacons
            pState.carryingBeacons = 0
            room.beaconsDeposited = room.beaconsDeposited + deposited
            room.score = room.score + deposited * 150
            pushLog(string.format("%s depositó %d Núcleo(s) en el Portal.", player.DisplayName, deposited))
            Remotes.SoundCue:FireAllClients("beacon_deposit")

            if room.beaconsDeposited >= room.beaconsRequired then
                room.portalUnlocked = true
                portalCore.Color = Color3.fromRGB(52, 211, 153)
                Remotes.GameBanner:FireAllClients("¡PORTAL ACTIVADO! Corre hacia el Portal para escapar.", "#34d399")
            end
        elseif room.portalUnlocked then
            pState.escaped = true
            local profile = DataStoreManager.getProfile(player)
            if profile then
                profile.totalScore = (profile.totalScore or 0) + 300 + room.level * 100
                profile.escapesCompleted = (profile.escapesCompleted or 0) + 1
                DataStoreManager.evaluateAchievements(profile)
                DataStoreManager.saveProfile(player, profile)
                Remotes.ProfileSync:FireClient(player, profile)
            end
            Remotes.SoundCue:FireAllClients("escape")
            Remotes.GameBanner:FireAllClients(player.DisplayName .. " escapó por el Portal. ¡Avanzando al siguiente nivel!", "#34d399")
            room.phase = "escaped"
            task.delay(3.5, function()
                if room.phase == "escaped" then
                    setupMatch(room.mode, room.level + 1)
                end
            end)
        else
            Remotes.GameBanner:FireClient(player, string.format("Faltan %d Núcleos para activar el Portal.", room.beaconsRequired - room.beaconsDeposited), "#38bdf8")
        end
    end)

    spawnRandomPickups(biomeSpec)

    -- Spawnear Babuino
    baboonState = BaboonAI.createState(biomeSpec)
    baboonRig = BaboonAI.spawnModel(arenaFolder, "stalker", false)
    BaboonAI.setWorldPosition(baboonRig, baboonState.x, baboonState.z, 0, 0)

    -- Reposicionar jugadores en SPAWN_POS
    for _, player in ipairs(Players:GetPlayers()) do
        local profile = DataStoreManager.getProfile(player) or DataStoreManager.loadProfile(player)
        local pState = createInitialPlayerState(player, profile)
        room.players[player.UserId] = pState
        if not player.Character then
            player:LoadCharacter()
        end
        task.defer(function()
            if player.Character and player.Character.PrimaryPart then
                local sx = GameConfig.SPAWN_POS.x * GameConfig.STUD_SCALE
                local sz = GameConfig.SPAWN_POS.z * GameConfig.STUD_SCALE
                player.Character:PivotTo(CFrame.new(sx, 5, sz))
                applyAppearanceToCharacter(player, profile.appearance)
            end
        end)
    end

    pushLog(string.format("Nivel %d iniciado: %s (%s)", room.level, biomeSpec.name, room.mode))
    Remotes.GameBanner:FireAllClients(string.format("Nivel %d · %s", room.level, biomeSpec.name), biomeSpec.accentHex)
end

local function countTotalBlocks(pState)
    local total = 0
    for _, amt in pairs(pState.blocks) do
        total = total + amt
    end
    return total
end

local function handlePlayerAction(player, action, payload)
    local pState = room.players[player.UserId]
    if not pState or not pState.alive or room.phase ~= "playing" then return end

    if action == "select_block" then
        local kind = payload and payload.kind
        if GameConfig.BLOCK_SPECS[kind] then
            pState.selectedBlock = kind
        end
    elseif action == "toggle_flashlight" then
        pState.flashlightOn = not pState.flashlightOn
    elseif action == "set_sprint" then
        pState.sprinting = (payload and payload.active == true)
    elseif action == "place_block" then
        local kind = (payload and payload.kind) or pState.selectedBlock
        local spec = GameConfig.BLOCK_SPECS[kind]
        if not spec or (pState.blocks[kind] or 0) <= 0 then return end

        local gx = math.floor(pState.x + 0.5)
        local gz = math.floor(pState.z - 2 + 0.5)
        if payload and payload.gx and payload.gz then
            gx = math.floor(payload.gx + 0.5)
            gz = math.floor(payload.gz + 0.5)
        end

        for _, blk in pairs(room.placedBlocks) do
            if blk.gx == gx and blk.gz == gz then
                return
            end
        end

        pState.blocks[kind] = pState.blocks[kind] - 1
        local id = room.nextId
        room.nextId = room.nextId + 1
        local maxHp = math.floor(spec.maxHp * pState.bonuses.barricadeHpMult)
        local part = WorldBuilder.spawnPlacedBlock(blocksFolder, id, gx, gz, kind, maxHp, maxHp)
        room.placedBlocks[id] = {
            id = id,
            gx = gx,
            gz = gz,
            kind = kind,
            hp = maxHp,
            maxHp = maxHp,
            ownerUserId = player.UserId,
            part = part,
        }
        room.score = room.score + spec.placeScore
        pushLog(string.format("%s colocó %s.", player.DisplayName, spec.shortLabel))
        Remotes.SoundCue:FireAllClients("place_block")

        local profile = DataStoreManager.getProfile(player)
        if profile then
            profile.blocksPlaced = (profile.blocksPlaced or 0) + 1
            profile.totalScore = (profile.totalScore or 0) + spec.placeScore
            DataStoreManager.evaluateAchievements(profile)
            Remotes.ProfileSync:FireClient(player, profile)
        end
    elseif action == "salvage_block" then
        local bestId, bestDist = nil, 4.5
        for id, blk in pairs(room.placedBlocks) do
            local d = math.sqrt((blk.gx - pState.x) ^ 2 + (blk.gz - pState.z) ^ 2)
            if d < bestDist then
                bestDist = d
                bestId = id
            end
        end
        if bestId then
            local blk = room.placedBlocks[bestId]
            if blk.part then blk.part:Destroy() end
            room.placedBlocks[bestId] = nil
            pState.blocks[blk.kind] = (pState.blocks[blk.kind] or 0) + 1
            pushLog(string.format("%s recuperó un bloque.", player.DisplayName))
        end
    elseif action == "craft_block" then
        local targetKind = payload and payload.kind
        local recipe = (targetKind == "decoy") and GameConfig.DECOY_CRAFT_RECIPE or (targetKind == "shock" and GameConfig.SHOCK_CRAFT_RECIPE or nil)
        if not recipe then return end
        for k, req in pairs(recipe) do
            if (pState.blocks[k] or 0) < req then return end
        end
        for k, req in pairs(recipe) do
            pState.blocks[k] = pState.blocks[k] - req
        end
        pState.blocks[targetKind] = (pState.blocks[targetKind] or 0) + 1
        pushLog(string.format("%s fabricó %s.", player.DisplayName, GameConfig.BLOCK_SPECS[targetKind].shortLabel))
        Remotes.SoundCue:FireClient(player, "craft")
    elseif action == "use_powerup" then
        local pKind = payload and payload.kind
        local pSpec = GameConfig.POWERUP_SPECS[pKind]
        if not pSpec or (pState.powerups[pKind] or 0) <= 0 then return end
        pState.powerups[pKind] = pState.powerups[pKind] - 1

        if pKind == "speed" then
            pState.speedTimer = pSpec.durationSec
            Remotes.SoundCue:FireClient(player, "powerup")
        elseif pKind == "cloak" then
            pState.cloakTimer = pSpec.durationSec
            pState.cloakActive = true
            Remotes.SoundCue:FireClient(player, "powerup")
        elseif pKind == "net" then
            if baboonState then
                local d = math.sqrt((baboonState.x - pState.x) ^ 2 + (baboonState.z - pState.z) ^ 2)
                if d <= 16 then
                    baboonState.trapTimer = pSpec.durationSec + pState.bonuses.trapStunBonusSec
                    pushLog(string.format("¡%s atrapó al Babuino con Lanzarred!", player.DisplayName))
                    Remotes.SoundCue:FireAllClients("net_hit")
                    local profile = DataStoreManager.getProfile(player)
                    if profile then
                        profile.baboonsStunned = (profile.baboonsStunned or 0) + 1
                        DataStoreManager.evaluateAchievements(profile)
                        Remotes.ProfileSync:FireClient(player, profile)
                    end
                else
                    Remotes.GameBanner:FireClient(player, "Lanzarred fallida: acércate más al Babuino (< 16m).", "#fbbf24")
                end
            end
        end
    elseif action == "squad_ping" then
        pushLog(string.format("PING de %s en (%.0f, %.0f)", player.DisplayName, pState.x, pState.z))
        Remotes.SoundCue:FireAllClients("ping")
    end
end

Remotes.PlayerAction.OnServerEvent:Connect(handlePlayerAction)

Remotes.LobbyAction.OnServerEvent:Connect(function(player, action, payload)
    local profile = DataStoreManager.getProfile(player) or DataStoreManager.loadProfile(player)
    if action == "start_match" then
        local mode = (payload and payload.mode == "training") and "training" or "survival"
        setupMatch(mode, 1)
    elseif action == "update_appearance" and payload then
        profile.appearance = {
            characterId = payload.characterId or profile.appearance.characterId,
            outfitId = payload.outfitId or profile.appearance.outfitId,
            jacketColor = payload.jacketColor or profile.appearance.jacketColor,
            pantsColor = payload.pantsColor or profile.appearance.pantsColor,
            accentColor = payload.accentColor or profile.appearance.accentColor,
        }
        DataStoreManager.saveProfile(player, profile)
        applyAppearanceToCharacter(player, profile.appearance)
        Remotes.ProfileSync:FireClient(player, profile)
    elseif action == "join_clan" and payload then
        local clan = DataStoreManager.createOrJoinClan(player, profile, payload.tag, payload.name, payload.motto)
        Remotes.ProfileSync:FireClient(player, profile, clan)
    end
end)

Players.PlayerAdded:Connect(function(player)
    local profile = DataStoreManager.loadProfile(player)
    local clan = DataStoreManager.getClan(profile.clanId)
    Remotes.ProfileSync:FireClient(player, profile, clan)

    player.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        applyAppearanceToCharacter(player, profile.appearance)
        if room.phase == "playing" then
            local sx = GameConfig.SPAWN_POS.x * GameConfig.STUD_SCALE
            local sz = GameConfig.SPAWN_POS.z * GameConfig.STUD_SCALE
            char:PivotTo(CFrame.new(sx, 5, sz))
        end
    end)

    if room.phase == "playing" then
        room.players[player.UserId] = createInitialPlayerState(player, profile)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    local profile = DataStoreManager.getProfile(player)
    if profile then
        DataStoreManager.saveProfile(player, profile)
    end
    room.players[player.UserId] = nil
end)

-- Bucle principal del servidor (Heartbeat)
RunService.Heartbeat:Connect(function()
    local now = os.clock()
    local dt = math.min(0.1, now - lastTick)
    lastTick = now

    if room.phase ~= "playing" then
        return
    end

    local biomeSpec = GameUtils.getBiomeForLevel(room.level)

    -- Ciclo Día/Noche
    room.timeOfDay = (room.timeOfDay + dt / 150) % 1

    -- Clima dinámico
    room.weather.timerSec = room.weather.timerSec - dt
    if room.weather.timerSec <= 0 then
        room.weather.kind = GameUtils.rollRandomWeatherForBiome(room.biome)
        room.weather.timerSec = 35 + math.random(0, 20)
    end

    -- Evento Eclipse Carmesí (solo en survival)
    if room.mode == "survival" then
        if room.eclipse.active then
            room.eclipse.remainingSec = room.eclipse.remainingSec - dt
            if room.eclipse.remainingSec <= 0 then
                room.eclipse.active = false
                room.eclipseCooldownSec = 65
                pushLog("El Eclipse Carmesí ha terminado.")
            end
        else
            room.eclipseCooldownSec = room.eclipseCooldownSec - dt
            if room.eclipseCooldownSec <= 0 then
                room.eclipse.active = true
                room.eclipse.remainingSec = GameConfig.ECLIPSE_DURATION_SEC
                pushLog("¡ECLIPSE CARMESÍ! Refúgiate en los Santuarios de Luz o junto a Amatista.")
                Remotes.GameBanner:FireAllClients("¡ECLIPSE CARMESÍ! Busca luz de Santuario o Amatista.", "#fb7185")
                Remotes.SoundCue:FireAllClients("eclipse_start")
            end
        end
    end

    -- Evento de Horda
    if room.mode == "survival" then
        room.horde.timerSec = room.horde.timerSec - dt
        if room.horde.phase == "calm" and room.horde.timerSec <= GameConfig.HORDE_IMMINENT_WARN_SEC then
            room.horde.phase = "imminent"
            Remotes.GameBanner:FireAllClients("¡Horda de Babuinos inminente!", "#f59e0b")
        elseif room.horde.phase == "imminent" and room.horde.timerSec <= 0 then
            room.horde.phase = "active"
            room.horde.timerSec = GameConfig.HORDE_ACTIVE_DURATION_SEC
            for i = 1, 2 do
                local mState = BaboonAI.createState(biomeSpec)
                mState.x = (i == 1) and -24 or 24
                mState.z = -18
                local mRig = BaboonAI.spawnModel(arenaFolder, "stalker", true)
                table.insert(minionRigs, { state = mState, rig = mRig })
            end
            pushLog("¡Oleada de Horda activa!")
        elseif room.horde.phase == "active" and room.horde.timerSec <= 0 then
            room.horde.phase = "calm"
            room.horde.timerSec = 65
            for _, m in ipairs(minionRigs) do
                if m.rig and m.rig.model then m.rig.model:Destroy() end
            end
            minionRigs = {}
        end
    end

    local dayInfo = GameUtils.getDayPhaseInfo(room.timeOfDay, room.biome, room.eclipse.active)
    local weatherMods = GameUtils.getWeatherModifiers(room.weather, room.biome)

    -- Actualizar jugadores, posición, velocidad, pickups y protección de eclipse
    local aliveCount = 0
    for _, player in ipairs(Players:GetPlayers()) do
        local pState = room.players[player.UserId]
        if pState and pState.alive then
            aliveCount = aliveCount + 1

            if pState.speedTimer > 0 then
                pState.speedTimer = math.max(0, pState.speedTimer - dt)
            end
            if pState.cloakTimer > 0 then
                pState.cloakTimer = math.max(0, pState.cloakTimer - dt)
                pState.cloakActive = pState.cloakTimer > 0
            else
                pState.cloakActive = false
            end

            -- Estamina
            if pState.sprinting and pState.speedTimer <= 0 then
                pState.stamina = math.max(0, pState.stamina - 22 * dt)
                if pState.stamina <= 0 then pState.sprinting = false end
            else
                pState.stamina = math.min(pState.maxStamina, pState.stamina + 15 * pState.bonuses.staminaRegenMult * dt)
            end

            -- Sincronizar posición y velocidad en Roblox Character
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum then
                pState.x = GameUtils.toMeters(root.Position.X)
                pState.z = GameUtils.toMeters(root.Position.Z)

                local baseWalk = 18 * pState.bonuses.speedMult * weatherMods.speedMult
                if pState.speedTimer > 0 then
                    baseWalk = baseWalk * 1.55
                elseif pState.sprinting then
                    baseWalk = baseWalk * 1.38
                end
                hum.WalkSpeed = baseWalk

                -- Protección de Eclipse
                if room.eclipse.active then
                    local prot = GameUtils.evaluateEclipseLightProtection(pState.x, pState.z, room.eclipse.sanctuaries, room.placedBlocks)
                    pState.inEclipseLight = prot.inLight
                    if not prot.inLight then
                        pState.hp = math.max(0, pState.hp - 10 * dt)
                        if pState.hp <= 0 then
                            pState.alive = false
                            hum.Health = 0
                            pushLog(player.DisplayName .. " sucumbió ante el Eclipse Carmesí.")
                        end
                    end
                else
                    pState.inEclipseLight = true
                end

                -- Recoger pickups cercanos
                for pid, pk in pairs(room.pickups) do
                    local d = math.sqrt((pk.x - pState.x) ^ 2 + (pk.z - pState.z) ^ 2)
                    if d <= 2.2 then
                        local collected = false
                        if pk.kind == "beacon" then
                            pState.carryingBeacons = pState.carryingBeacons + 1
                            collected = true
                            pushLog(player.DisplayName .. " recogió un Núcleo del Portal.")
                        elseif pk.kind == "power_speed" then
                            pState.powerups.speed = pState.powerups.speed + 1
                            collected = true
                        elseif pk.kind == "power_cloak" then
                            pState.powerups.cloak = pState.powerups.cloak + 1
                            collected = true
                        elseif pk.kind == "power_net" then
                            pState.powerups.net = pState.powerups.net + 1
                            collected = true
                        elseif GameConfig.BLOCK_SPECS[pk.kind] then
                            if countTotalBlocks(pState) < pState.maxBlockCapacity then
                                pState.blocks[pk.kind] = (pState.blocks[pk.kind] or 0) + 1
                                collected = true
                            end
                        end
                        if collected then
                            if pk.part then pk.part:Destroy() end
                            room.pickups[pid] = nil
                            Remotes.SoundCue:FireClient(player, "pickup")
                        end
                    end
                end
            end
        end
    end

    -- Verificar derrota en modo survival si todos murieron
    if room.mode == "survival" and #Players:GetPlayers() > 0 and aliveCount == 0 then
        room.phase = "gameover"
        Remotes.GameBanner:FireAllClients("¡DERROTA! El Scary Baboon eliminó al escuadrón.", "#ef4444")
        task.delay(4.0, function()
            if room.phase == "gameover" then
                setupMatch("survival", 1)
            end
        end)
        return
    end

    -- Actualizar IA del Babuino principal
    local aiCallbacks = {
        onPlayerSlam = function(pState, dmg)
            if room.mode == "training" then
                dmg = math.floor(dmg * 0.35)
            end
            pState.hp = math.max(0, pState.hp - dmg)
            Remotes.SoundCue:FireAllClients("baboon_slam")
            local pl = Players:GetPlayerByUserId(pState.userId)
            if pl and pl.Character then
                local hum = pl.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.Health = math.max(0, (pState.hp / pState.maxHp) * hum.MaxHealth)
                end
            end
            if pState.hp <= 0 then
                pState.alive = false
                pushLog(pState.name .. " fue derribado por el Babuino.")
            end
        end,
        onBlockDamaged = function(blk, dmg)
            blk.hp = blk.hp - dmg
            Remotes.SoundCue:FireAllClients("block_hit")
            if blk.hp <= 0 then
                if blk.part then blk.part:Destroy() end
                room.placedBlocks[blk.id] = nil
                pushLog("El Babuino destruyó una barricada.")
            end
        end,
        onShockTriggered = function(blk)
            if blk.part then blk.part:Destroy() end
            room.placedBlocks[blk.id] = nil
            Remotes.SoundCue:FireAllClients("shock_stun")
            pushLog("¡Electro-Trampa activada! Babuino aturdido 3.8s.")
        end,
        onDecoyTriggered = function(blk)
            Remotes.SoundCue:FireAllClients("decoy_beep")
            pushLog("¡Señuelo Sónico atrayendo al Babuino!")
        end,
    }

    if baboonState and baboonRig then
        BaboonAI.update(baboonState, baboonRig, dt, room.players, room.placedBlocks, biomeSpec, dayInfo.nightFactor, room.level, aiCallbacks)
    end

    for _, m in ipairs(minionRigs) do
        BaboonAI.update(m.state, m.rig, dt, room.players, room.placedBlocks, biomeSpec, dayInfo.nightFactor, room.level, aiCallbacks)
    end

    -- Enviar Snapshot periódico a los clientes (~15 Hz)
    syncAccumulator = syncAccumulator + dt
    if syncAccumulator >= 0.066 then
        syncAccumulator = 0
        local snapshot = {
            phase = room.phase,
            mode = room.mode,
            level = room.level,
            biome = room.biome,
            timeOfDay = room.timeOfDay,
            dayPhase = dayInfo.phase,
            nightFactor = dayInfo.nightFactor,
            weather = room.weather,
            eclipse = {
                active = room.eclipse.active,
                remainingSec = room.eclipse.remainingSec,
            },
            horde = {
                phase = room.horde.phase,
                timerSec = room.horde.timerSec,
            },
            beaconsDeposited = room.beaconsDeposited,
            beaconsRequired = room.beaconsRequired,
            portalUnlocked = room.portalUnlocked,
            score = room.score,
            baboon = baboonState and {
                x = baboonState.x,
                z = baboonState.z,
                behavior = baboonState.behavior,
                variant = baboonState.variant,
            } or nil,
            players = room.players,
            logs = room.logs,
        }
        Remotes.StateSync:FireAllClients(snapshot)
    end
end)
