-- GameUtils.luau: Funciones deterministas y utilidades compartidas

local GameConfig = require(script.Parent.GameConfig)

local GameUtils = {}

function GameUtils.seededHash(seed)
    local x = math.sin(seed * 127.1 + 311.7) * 43758.5453123
    return x - math.floor(x)
end

function GameUtils.toStuds(meters)
    return meters * GameConfig.STUD_SCALE
end

function GameUtils.toMeters(studs)
    return studs / GameConfig.STUD_SCALE
end

function GameUtils.getBiomeForLevel(level)
    local lvl = math.max(1, math.floor(level or 1))
    local mod = ((lvl - 1) % 3) + 1
    if mod == 1 then
        return GameConfig.BIOME_SPECS.forest
    elseif mod == 2 then
        return GameConfig.BIOME_SPECS.caverns
    else
        return GameConfig.BIOME_SPECS.ruins
    end
end

function GameUtils.groundHeightAt(x, z, biome)
    local b = biome or "forest"
    if b == "caverns" then
        return math.sin(x * 0.14) * math.cos(z * 0.12) * 0.25
    elseif b == "ruins" then
        return 0
    else
        return math.sin(x * 0.08) * math.cos(z * 0.08) * 0.18
    end
end

function GameUtils.getBaboonVariantSpec(kind)
    for _, v in ipairs(GameConfig.BABOON_VARIANTS) do
        if v.kind == kind then
            return v
        end
    end
    return GameConfig.BABOON_VARIANTS[1]
end

function GameUtils.getActiveBaboonVariant(level, biome, nightFactor)
    if nightFactor >= 0.88 or (level >= 4 and nightFactor >= 0.52) then
        return "berserker"
    end
    if biome == "ruins" then
        return "ancestral"
    end
    if biome == "caverns" then
        return "abyssal"
    end
    return "stalker"
end

function GameUtils.generateLevelObstacles(level)
    local biome = GameUtils.getBiomeForLevel(level).kind
    local boxes = {}
    local seedOffset = level * 97
    local portal = GameConfig.PORTAL_POS
    local spawn = GameConfig.SPAWN_POS

    local function overlapsAny(cx, cz, pad)
        for _, b in ipairs(boxes) do
            if (cx + pad) > b.minX and (cx - pad) < b.maxX and (cz + pad) > b.minZ and (cz - pad) < b.maxZ then
                return true
            end
        end
        return false
    end

    if biome == "forest" then
        table.insert(boxes, { minX = -7.5, maxX = -6.5, minZ = -5.5, maxZ = 5.5, height = 3.5, kind = "ruin_wall" })
        table.insert(boxes, { minX = 6.5, maxX = 7.5, minZ = -5.5, maxZ = 5.5, height = 3.5, kind = "ruin_wall" })
        table.insert(boxes, { minX = -7.5, maxX = -1.5, minZ = 4.5, maxZ = 5.5, height = 3.5, kind = "ruin_wall" })
        table.insert(boxes, { minX = 1.5, maxX = 7.5, minZ = 4.5, maxZ = 5.5, height = 3.5, kind = "ruin_wall" })
        table.insert(boxes, { minX = -7.5, maxX = -1.5, minZ = -5.5, maxZ = -4.5, height = 3.5, kind = "ruin_wall" })
        table.insert(boxes, { minX = 1.5, maxX = 7.5, minZ = -5.5, maxZ = -4.5, height = 3.5, kind = "ruin_wall" })

        local shelters = {
            { cx = -18, cz = -4 },
            { cx = 18, cz = 4 },
        }
        for _, s in ipairs(shelters) do
            table.insert(boxes, { minX = s.cx - 4.5, maxX = s.cx - 3.5, minZ = s.cz - 4.5, maxZ = s.cz + 4.5, height = 3, kind = "ruin_wall" })
            table.insert(boxes, { minX = s.cx + 3.5, maxX = s.cx + 4.5, minZ = s.cz - 4.5, maxZ = s.cz + 4.5, height = 3, kind = "ruin_wall" })
            table.insert(boxes, { minX = s.cx - 4.5, maxX = s.cx + 4.5, minZ = s.cz - 4.5, maxZ = s.cz - 3.5, height = 3, kind = "ruin_wall" })
            table.insert(boxes, { minX = s.cx - 4.5, maxX = s.cx - 1.0, minZ = s.cz + 3.5, maxZ = s.cz + 4.5, height = 3, kind = "ruin_wall" })
            table.insert(boxes, { minX = s.cx + 1.0, maxX = s.cx + 4.5, minZ = s.cz + 3.5, maxZ = s.cz + 4.5, height = 3, kind = "ruin_wall" })
        end

        for i = 0, 45 do
            local angle = GameUtils.seededHash(seedOffset + i * 3 + 1) * math.pi * 2
            local radius = 11 + GameUtils.seededHash(seedOffset + i * 3 + 2) * 21
            local tx = math.floor(math.cos(angle) * radius + 0.5)
            local tz = math.floor(math.sin(angle) * radius + 0.5)
            local distPortal = math.sqrt((tx - portal.x) ^ 2 + (tz - portal.z) ^ 2)
            local distSpawn = math.sqrt((tx - spawn.x) ^ 2 + (tz - spawn.z) ^ 2)
            local distW = math.sqrt((tx + 18) ^ 2 + (tz + 4) ^ 2)
            local distE = math.sqrt((tx - 18) ^ 2 + (tz - 4) ^ 2)

            if distPortal >= 8 and distSpawn >= 7 and not (math.abs(tx) < 9.5 and math.abs(tz) < 7.5) and distW >= 6.5 and distE >= 6.5 then
                if not overlapsAny(tx, tz, 1.2) then
                    table.insert(boxes, {
                        minX = tx - 0.65,
                        maxX = tx + 0.65,
                        minZ = tz - 0.65,
                        maxZ = tz + 0.65,
                        height = 7.5,
                        kind = "tree",
                    })
                end
            end
        end
        return boxes
    end

    if biome == "caverns" then
        table.insert(boxes, { minX = -12.5, maxX = -2.0, minZ = -1.5, maxZ = 0.5, height = 4.5, kind = "ruin_wall" })
        table.insert(boxes, { minX = 2.0, maxX = 12.5, minZ = -1.5, maxZ = 0.5, height = 4.5, kind = "ruin_wall" })
        table.insert(boxes, { minX = -15.5, maxX = -13.5, minZ = -12.5, maxZ = 10.5, height = 5.0, kind = "ruin_wall" })
        table.insert(boxes, { minX = 13.5, maxX = 15.5, minZ = -12.5, maxZ = 10.5, height = 5.0, kind = "ruin_wall" })

        for _, cx in ipairs({ -21, 21 }) do
            table.insert(boxes, { minX = cx - 3.5, maxX = cx + 3.5, minZ = -8.5, maxZ = -7.5, height = 4.0, kind = "ruin_wall" })
            table.insert(boxes, { minX = cx - 3.5, maxX = cx + 3.5, minZ = 7.5, maxZ = 8.5, height = 4.0, kind = "ruin_wall" })
        end

        for i = 0, 41 do
            local angle = GameUtils.seededHash(seedOffset + i * 5 + 3) * math.pi * 2
            local radius = 8 + GameUtils.seededHash(seedOffset + i * 5 + 4) * 23
            local sx = math.floor(math.cos(angle) * radius + 0.5)
            local sz = math.floor(math.sin(angle) * radius + 0.5)
            local distPortal = math.sqrt((sx - portal.x) ^ 2 + (sz - portal.z) ^ 2)
            local distSpawn = math.sqrt((sx - spawn.x) ^ 2 + (sz - spawn.z) ^ 2)
            local distC = math.sqrt(sx ^ 2 + (sz - 5) ^ 2)
            local distW = math.sqrt((sx + 21) ^ 2 + sz ^ 2)
            local distE = math.sqrt((sx - 21) ^ 2 + sz ^ 2)

            if distPortal >= 8 and distSpawn >= 7 and distC >= 4.2 and distW >= 4.2 and distE >= 4.2 then
                if not overlapsAny(sx, sz, 1.3) then
                    local isCrystal = (i % 3 == 0)
                    table.insert(boxes, {
                        minX = sx - 0.7,
                        maxX = sx + 0.7,
                        minZ = sz - 0.7,
                        maxZ = sz + 0.7,
                        height = isCrystal and 4.2 or 5.8,
                        kind = isCrystal and "crystal_spire" or "stalagmite",
                    })
                end
            end
        end
        return boxes
    end

    -- Ruinas Antiguas
    table.insert(boxes, { minX = -9.5, maxX = -8.5, minZ = -9.5, maxZ = -1.5, height = 4.2, kind = "ruin_wall" })
    table.insert(boxes, { minX = -9.5, maxX = -8.5, minZ = 1.5, maxZ = 9.5, height = 4.2, kind = "ruin_wall" })
    table.insert(boxes, { minX = 8.5, maxX = 9.5, minZ = -9.5, maxZ = -1.5, height = 4.2, kind = "ruin_wall" })
    table.insert(boxes, { minX = 8.5, maxX = 9.5, minZ = 1.5, maxZ = 9.5, height = 4.2, kind = "ruin_wall" })
    table.insert(boxes, { minX = -9.5, maxX = -1.5, minZ = 8.5, maxZ = 9.5, height = 4.2, kind = "ruin_wall" })
    table.insert(boxes, { minX = 1.5, maxX = 9.5, minZ = 8.5, maxZ = 9.5, height = 4.2, kind = "ruin_wall" })
    table.insert(boxes, { minX = -9.5, maxX = -1.5, minZ = -9.5, maxZ = -8.5, height = 4.2, kind = "ruin_wall" })
    table.insert(boxes, { minX = 1.5, maxX = 9.5, minZ = -9.5, maxZ = -8.5, height = 4.2, kind = "ruin_wall" })

    table.insert(boxes, { minX = -20.5, maxX = -14.5, minZ = -14.5, maxZ = -13.5, height = 3.6, kind = "ruin_wall" })
    table.insert(boxes, { minX = 14.5, maxX = 20.5, minZ = -14.5, maxZ = -13.5, height = 3.6, kind = "ruin_wall" })
    table.insert(boxes, { minX = -20.5, maxX = -14.5, minZ = 13.5, maxZ = 14.5, height = 3.6, kind = "ruin_wall" })
    table.insert(boxes, { minX = 14.5, maxX = 20.5, minZ = 13.5, maxZ = 14.5, height = 3.6, kind = "ruin_wall" })

    local obeliskCoords = {
        { -5, -16 }, { 5, -16 },
        { -5, 15 }, { 5, 15 },
        { -16, -6 }, { -16, 6 },
        { 16, -6 }, { 16, 6 },
        { -23, -18 }, { 23, -18 },
        { -23, 18 }, { 23, 18 },
        { -25, 0 }, { 25, 0 },
    }
    for _, coord in ipairs(obeliskCoords) do
        local ox, oz = coord[1], coord[2]
        table.insert(boxes, {
            minX = ox - 0.85,
            maxX = ox + 0.85,
            minZ = oz - 0.85,
            maxZ = oz + 0.85,
            height = 6.8,
            kind = "temple_obelisk",
        })
    end

    return boxes
end

function GameUtils.getDayPhaseInfo(timeOfDay, biome, eclipseActive)
    if eclipseActive then
        return { phase = "Eclipse Carmesí", nightFactor = 1.0 }
    end
    local t = ((timeOfDay % 1) + 1) % 1
    if biome == "caverns" then
        if t < 0.5 then
            local pulse = math.sin(t * math.pi * 2) * 0.15
            return { phase = "Bioluminiscencia", nightFactor = 0.58 - pulse }
        end
        return { phase = "Oscuridad Abisal", nightFactor = 0.96 }
    elseif biome == "ruins" then
        if t < 0.55 then
            return { phase = "Sol Áureo", nightFactor = 0.15 }
        end
        return { phase = "Tormenta Cenicienta", nightFactor = 0.92 }
    end

    if t < 0.15 then
        local u = t / 0.15
        return { phase = "Amanecer", nightFactor = 1 - u * 0.85 }
    elseif t < 0.52 then
        return { phase = "Día Cúbico", nightFactor = 0.05 }
    elseif t < 0.68 then
        local u = (t - 0.52) / 0.16
        return { phase = "Atardecer", nightFactor = 0.05 + u * 0.85 }
    else
        return { phase = "Noche Carmesí", nightFactor = 1.0 }
    end
end

function GameUtils.getWeatherLabelForKind(kind, biome)
    if kind == "rain" then
        return biome == "caverns" and "Lluvia Subterránea" or "Lluvia Torrencial"
    elseif kind == "fog" then
        return "Niebla Densa"
    elseif kind == "sandstorm" then
        return "Tormenta de Arena"
    end
    return "Despejado"
end

function GameUtils.getWeatherModifiers(weather, biome)
    local kind = (weather and weather.kind) or "clear"
    local label = GameUtils.getWeatherLabelForKind(kind, biome)
    if kind == "rain" then
        return {
            label = label,
            speedMult = 0.94,
            fogEnd = 220,
            flashlightRangeMult = 0.86,
            visibilityPct = 72,
        }
    elseif kind == "fog" then
        return {
            label = label,
            speedMult = 0.97,
            fogEnd = 120,
            flashlightRangeMult = 0.65,
            visibilityPct = 42,
        }
    elseif kind == "sandstorm" then
        return {
            label = label,
            speedMult = 0.86,
            fogEnd = 140,
            flashlightRangeMult = 0.72,
            visibilityPct = 48,
        }
    end
    return {
        label = label,
        speedMult = 1.0,
        fogEnd = 340,
        flashlightRangeMult = 1.0,
        visibilityPct = 100,
    }
end

function GameUtils.rollRandomWeatherForBiome(biome)
    local r = math.random()
    if biome == "forest" then
        if r < 0.45 then return "clear"
        elseif r < 0.75 then return "rain"
        else return "fog" end
    elseif biome == "caverns" then
        if r < 0.40 then return "clear"
        elseif r < 0.72 then return "fog"
        else return "rain" end
    else
        if r < 0.40 then return "clear"
        elseif r < 0.78 then return "sandstorm"
        else return "fog" end
    end
end

function GameUtils.getBiomeLightSanctuaries(biome)
    local specs
    if biome == "caverns" then
        specs = {
            { id = "sanc_center", label = "Geoda Solar Central", x = 0, z = 5 },
            { id = "sanc_west", label = "Faro de Cuarzo Oeste", x = -21, z = 0 },
            { id = "sanc_east", label = "Faro de Cuarzo Este", x = 21, z = 0 },
            { id = "sanc_north", label = "Altar Astral Norte", x = 0, z = -20 },
        }
    elseif biome == "ruins" then
        specs = {
            { id = "sanc_center", label = "Santuario del Templo Áureo", x = 0, z = 0 },
            { id = "sanc_west", label = "Pira Solar Poniente", x = -20, z = 0 },
            { id = "sanc_east", label = "Pira Solar Naciente", x = 20, z = 0 },
            { id = "sanc_north", label = "Altar del Portal Ancestral", x = 0, z = -20 },
        }
    else
        specs = {
            { id = "sanc_center", label = "Faro del Búnker Central", x = 0, z = 0 },
            { id = "sanc_west", label = "Faro del Refugio Oeste", x = -18, z = -4 },
            { id = "sanc_east", label = "Faro del Refugio Este", x = 18, z = 4 },
            { id = "sanc_north", label = "Altar Solar del Portal", x = 0, z = -20 },
        }
    end

    local result = {}
    for _, s in ipairs(specs) do
        table.insert(result, {
            id = s.id,
            label = s.label,
            x = s.x,
            y = GameUtils.groundHeightAt(s.x, s.z, biome),
            z = s.z,
            radius = GameConfig.ECLIPSE_SANCTUARY_RADIUS,
        })
    end
    return result
end

function GameUtils.evaluateEclipseLightProtection(px, pz, sanctuaries, blocks)
    local inLight = false
    local nearestDist = math.huge
    local nearestLabel = "Faro Solar"

    for _, s in ipairs(sanctuaries) do
        local d = math.sqrt((px - s.x) ^ 2 + (pz - s.z) ^ 2)
        if d <= s.radius then
            inLight = true
        end
        if d < nearestDist then
            nearestDist = d
            nearestLabel = s.label
        end
    end

    if blocks then
        for _, blk in pairs(blocks) do
            if blk.kind == "amethyst" then
                local d = math.sqrt((px - blk.gx) ^ 2 + (pz - blk.gz) ^ 2)
                if d <= GameConfig.ECLIPSE_AMETHYST_LIGHT_RADIUS then
                    inLight = true
                end
                if d < nearestDist then
                    nearestDist = d
                    nearestLabel = "Cristal de Amatista"
                end
            end
        end
    end

    return {
        inLight = inLight,
        nearestDist = (nearestDist == math.huge) and 0 or nearestDist,
        nearestLabel = nearestLabel,
    }
end

function GameUtils.getPlayerRank(totalScore, escapesCompleted)
    local safeScore = math.max(0, math.floor(tonumber(totalScore) or 0))
    local safeEscapes = math.max(0, math.floor(tonumber(escapesCompleted) or 0))
    local current = GameConfig.PLAYER_RANKS[1]
    for i = 2, #GameConfig.PLAYER_RANKS do
        local candidate = GameConfig.PLAYER_RANKS[i]
        if safeScore >= candidate.minScore and safeEscapes >= candidate.minEscapes then
            current = candidate
        end
    end
    return current
end

function GameUtils.getRelicPermanentBonuses(relicsMask)
    local mask = relicsMask or 0
    return {
        speedMult = (bit32.band(mask, 1) ~= 0) and 1.08 or 1.0,
        staminaRegenMult = (bit32.band(mask, 2) ~= 0) and 1.20 or 1.0,
        flashlightRangeMult = (bit32.band(mask, 4) ~= 0) and 1.30 or 1.0,
        extraBlockCapacity = (bit32.band(mask, 8) ~= 0) and 2 or 0,
        barricadeHpMult = (bit32.band(mask, 16) ~= 0) and 1.20 or 1.0,
        trapStunBonusSec = (bit32.band(mask, 32) ~= 0) and 1.5 or 0,
    }
end

function GameUtils.formatCountdownMMSS(seconds)
    local safe = math.max(0, math.floor(seconds or 0))
    local mins = math.floor(safe / 60)
    local secs = safe % 60
    return string.format("%02d:%02d", mins, secs)
end

return GameUtils
