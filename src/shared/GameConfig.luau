--!strict
-- GameConfig.luau: Constantes y especificaciones completas de Block Baboon: Fuga Cúbica (Roblox)

local GameConfig = {}

-- Escala del mundo: 1 metro del motor web = 4 studs en Roblox
GameConfig.STUD_SCALE = 4
GameConfig.PLAYABLE_HALF_EXTENT = 34 -- 136 studs desde el centro
GameConfig.PORTAL_POS = { x = 0, z = -26 }
GameConfig.SPAWN_POS = { x = 0, z = 22 }

GameConfig.DECOY_TRAP_RADIUS = 9.5
GameConfig.DECOY_DISTRACT_DURATION = 5.5
GameConfig.ECLIPSE_DURATION_SEC = 24
GameConfig.ECLIPSE_SANCTUARY_RADIUS = 5.2
GameConfig.ECLIPSE_AMETHYST_LIGHT_RADIUS = 3.6
GameConfig.HORDE_IMMINENT_WARN_SEC = 12
GameConfig.HORDE_ACTIVE_DURATION_SEC = 22

GameConfig.DECOY_CRAFT_RECIPE = {
    oak = 2,
    stone = 1,
    amethyst = 1,
}
GameConfig.DECOY_CRAFT_RECIPE_TEXT = "2 Roble + 1 Piedra + 1 Amatista"

GameConfig.SHOCK_CRAFT_RECIPE = {
    stone = 2,
    obsidian = 1,
}
GameConfig.SHOCK_CRAFT_RECIPE_TEXT = "2 Piedra + 1 Obsidiana"

GameConfig.PLAYER_RANKS = {
    {
        id = "recruit",
        tier = 1,
        title = "Recluta Cúbico",
        shortTitle = "Recluta",
        minScore = 0,
        minEscapes = 0,
        primaryColor = Color3.fromHex("#94a3b8"),
        secondaryColor = Color3.fromHex("#475569"),
    },
    {
        id = "tracker",
        tier = 2,
        title = "Rastreador de Biomas",
        shortTitle = "Rastreador",
        minScore = 500,
        minEscapes = 1,
        primaryColor = Color3.fromHex("#34d399"),
        secondaryColor = Color3.fromHex("#065f46"),
    },
    {
        id = "fortifier",
        tier = 3,
        title = "Artífice de Bastión",
        shortTitle = "Artífice",
        minScore = 1500,
        minEscapes = 2,
        primaryColor = Color3.fromHex("#38bdf8"),
        secondaryColor = Color3.fromHex("#0369a1"),
    },
    {
        id = "veteran",
        tier = 4,
        title = "Veterano del Eclipse",
        shortTitle = "Veterano",
        minScore = 3200,
        minEscapes = 4,
        primaryColor = Color3.fromHex("#c084fc"),
        secondaryColor = Color3.fromHex("#6b21a8"),
    },
    {
        id = "commander",
        tier = 5,
        title = "Comandante de Escuadrón",
        shortTitle = "Comandante",
        minScore = 6000,
        minEscapes = 7,
        primaryColor = Color3.fromHex("#fbbf24"),
        secondaryColor = Color3.fromHex("#b45309"),
    },
    {
        id = "legend",
        tier = 6,
        title = "Leyenda Ancestral",
        shortTitle = "Leyenda",
        minScore = 10000,
        minEscapes = 12,
        primaryColor = Color3.fromHex("#fb7185"),
        secondaryColor = Color3.fromHex("#fde047"),
    },
}

GameConfig.CHARACTER_ARCHETYPES = {
    {
        id = "explorer",
        name = "Explorador Forestal",
        roleTitle = "Rastreador de Vanguardia",
        specialty = "Reconocimiento rápido de rutas hacia el Portal y recolección ágil.",
        defaultOutfit = "ranger",
        presetColors = {
            jacketColor = "#38bdf8",
            pantsColor = "#1e293b",
            accentColor = "#fbbf24",
        },
    },
    {
        id = "engineer",
        name = "Ingeniera Táctica",
        roleTitle = "Maestra de Trampas",
        specialty = "Diseño de barricadas escalonadas, señuelos sónicos y redes energéticas.",
        defaultOutfit = "stealth",
        presetColors = {
            jacketColor = "#fb7185",
            pantsColor = "#0f172a",
            accentColor = "#22d3ee",
        },
    },
    {
        id = "miner",
        name = "Minero Abisal",
        roleTitle = "Excavador de Geodas",
        specialty = "Extracción en Cavernas Oscuras con blindaje de amatista y obsidiana.",
        defaultOutfit = "miner",
        presetColors = {
            jacketColor = "#a855f7",
            pantsColor = "#1e1b4b",
            accentColor = "#34d399",
        },
    },
    {
        id = "sentinel",
        name = "Centinela Rúnico",
        roleTitle = "Guardián del Templo",
        specialty = "Defensa pesada del escuadrón frente al Alfa Ancestral en Ruinas.",
        defaultOutfit = "guardian",
        presetColors = {
            jacketColor = "#f59e0b",
            pantsColor = "#292524",
            accentColor = "#ef4444",
        },
    },
}

GameConfig.OUTFIT_STYLES = {
    {
        id = "ranger",
        name = "Equipo Explorador",
        description = "Chaleco táctico ligero con arnés de campo y botas de sendero.",
    },
    {
        id = "miner",
        name = "Traje Minero",
        description = "Casco frontal de minería, peto reforzado y cinturón de geodas.",
    },
    {
        id = "stealth",
        name = "Sigilo Nocturno",
        description = "Capucha oscura, visor táctico y recubrimiento antirreflejos.",
    },
    {
        id = "guardian",
        name = "Armadura Rúnica",
        description = "Hombreras blindadas y placa pectoral grabada con runas solares.",
    },
}

GameConfig.AVATAR_JACKET_SWATCHES = {
    "#38bdf8", "#fb7185", "#a855f7", "#f59e0b",
    "#34d399", "#ef4444", "#6366f1", "#e2e8f0",
}

GameConfig.AVATAR_PANTS_SWATCHES = {
    "#1e293b", "#0f172a", "#1e1b4b", "#292524",
    "#14532d", "#450a0a", "#334155",
}

GameConfig.AVATAR_ACCENT_SWATCHES = {
    "#fbbf24", "#22d3ee", "#34d399", "#ef4444",
    "#c084fc", "#f472b6", "#ffffff",
}

GameConfig.BABOON_VARIANTS = {
    {
        kind = "stalker",
        bit = 1,
        name = "Rastreador Forestal",
        codeName = "ESPÉCIMEN B-01",
        habitat = "Bosque Denso · Nivel 1+",
        dangerRating = 2,
        accentHex = "#ef4444",
        furHex = "#2a1b18",
        summary = "Primate cuadrúpedo de pelaje oscuro y ojos carmesí que acecha entre las secuoyas.",
    },
    {
        kind = "abyssal",
        bit = 2,
        name = "Acechador Abisal",
        codeName = "ESPÉCIMEN B-02",
        habitat = "Cavernas Oscuras · Nivel 2+",
        dangerRating = 4,
        accentHex = "#c084fc",
        furHex = "#1a162b",
        summary = "Mutación subterránea con drusas de amatista bioluminiscente y oído hipersensible.",
    },
    {
        kind = "ancestral",
        bit = 4,
        name = "Alfa Ancestral",
        codeName = "ESPÉCIMEN B-03",
        habitat = "Ruinas Antiguas · Nivel 3+",
        dangerRating = 5,
        accentHex = "#f59e0b",
        furHex = "#332417",
        summary = "Guardián colosal revestido con hombreras y cresta de oro antiguo.",
    },
    {
        kind = "berserker",
        bit = 8,
        name = "Coloso Carmesí Nocturno",
        codeName = "ESPÉCIMEN B-04",
        habitat = "Noche Cerrada / Oleadas Nv. 4+",
        dangerRating = 5,
        accentHex = "#fb7185",
        furHex = "#290c11",
        summary = "Estado de furia volcánica desatado bajo la luna carmesí.",
    },
}

GameConfig.BIOME_SPECS = {
    forest = {
        kind = "forest",
        levelNumber = 1,
        bit = 1,
        name = "Bosque Denso",
        subtitle = "Secuoyas oscuras, niebla nocturna y refugios de madera.",
        featuredBlocks = { "oak", "stone", "decoy" },
        threatLabel = "Amenaza Media · Rastreador Forestal",
        patrolSpeed = 3.4,
        chaseSpeed = 5.8,
        detectionRadius = 21,
        slamDamage = 45,
        windupSec = 0.8,
        beaconsBase = 4,
        groundHex = "#1f3a24",
        wallHex = "#4b5563",
        accentHex = "#34d399",
    },
    caverns = {
        kind = "caverns",
        levelNumber = 2,
        bit = 2,
        name = "Cavernas Oscuras",
        subtitle = "Grutas profundas de pizarra, estalactitas y geodas de amatista.",
        featuredBlocks = { "amethyst", "obsidian", "decoy" },
        threatLabel = "Amenaza Alta · Acechador Subterráneo",
        patrolSpeed = 4.0,
        chaseSpeed = 6.7,
        detectionRadius = 26,
        slamDamage = 55,
        windupSec = 0.62,
        beaconsBase = 5,
        groundHex = "#1e1b2e",
        wallHex = "#312e4a",
        accentHex = "#c084fc",
    },
    ruins = {
        kind = "ruins",
        levelNumber = 3,
        bit = 4,
        name = "Ruinas Antiguas",
        subtitle = "Templo ancestral de piedra cincelada, obeliscos y braseros.",
        featuredBlocks = { "ancient", "obsidian", "decoy", "shock" },
        threatLabel = "Amenaza Extrema · Alfa Ancestral",
        patrolSpeed = 4.5,
        chaseSpeed = 7.5,
        detectionRadius = 30,
        slamDamage = 65,
        windupSec = 0.48,
        beaconsBase = 6,
        groundHex = "#3d3324",
        wallHex = "#6b5a42",
        accentHex = "#f59e0b",
    },
}

GameConfig.BLOCK_ORDER = { "oak", "stone", "amethyst", "obsidian", "ancient", "shock", "decoy" }

GameConfig.BLOCK_SPECS = {
    oak = {
        kind = "oak",
        name = "Roble Robusto",
        shortLabel = "Roble",
        maxHp = 220,
        hotkey = "1",
        accentHex = "#b4783c",
        material = Enum.Material.WoodPlanks,
        placeScore = 30,
        pickupScore = 20,
        description = "Barricada ligera del Bosque Denso.",
    },
    stone = {
        kind = "stone",
        name = "Piedra Musgosa",
        shortLabel = "Piedra",
        maxHp = 460,
        hotkey = "2",
        accentHex = "#7c8a94",
        material = Enum.Material.Cobblestone,
        placeScore = 40,
        pickupScore = 25,
        description = "Muro fortificado de roca cúbica.",
    },
    amethyst = {
        kind = "amethyst",
        name = "Cristal de Amatista",
        shortLabel = "Amatista",
        maxHp = 640,
        hotkey = "3",
        accentHex = "#c084fc",
        material = Enum.Material.Neon,
        placeScore = 55,
        pickupScore = 35,
        description = "Cristal bioluminiscente que protege contra el Eclipse.",
    },
    obsidian = {
        kind = "obsidian",
        name = "Obsidiana Rúnica",
        shortLabel = "Obsidiana",
        maxHp = 920,
        hotkey = "4",
        accentHex = "#7e57c2",
        material = Enum.Material.Slate,
        placeScore = 65,
        pickupScore = 45,
        description = "Blindaje volcánico denso.",
    },
    ancient = {
        kind = "ancient",
        name = "Ladrillo Ancestral",
        shortLabel = "Ancestral",
        maxHp = 1180,
        hotkey = "5",
        accentHex = "#f59e0b",
        material = Enum.Material.Brick,
        placeScore = 80,
        pickupScore = 55,
        description = "Reliquia dorada de máxima solidez.",
    },
    shock = {
        kind = "shock",
        name = "Electro-Trampa",
        shortLabel = "Trampa",
        maxHp = 240,
        hotkey = "6",
        accentHex = "#22d3ee",
        material = Enum.Material.Metal,
        placeScore = 60,
        pickupScore = 40,
        description = "Descarga eléctrica que aturde al Babuino 3.8 s.",
    },
    decoy = {
        kind = "decoy",
        name = "Trampa Señuelo Sónica",
        shortLabel = "Señuelo",
        maxHp = 260,
        hotkey = "7",
        accentHex = "#fb7185",
        material = Enum.Material.Metal,
        placeScore = 65,
        pickupScore = 45,
        description = "Distrae al Babuino durante 5.5 s en un radio de 9.5 m.",
    },
}

GameConfig.POWERUP_SPECS = {
    speed = {
        kind = "speed",
        name = "Impulso de Velocidad",
        shortLabel = "Velocidad",
        hotkey = "Z",
        durationSec = 7.0,
        accentHex = "#fbbf24",
        blockRecipe = { oak = 3, stone = 2 },
        recipeText = "3 Roble + 2 Piedra",
    },
    cloak = {
        kind = "cloak",
        name = "Manto Invisible",
        shortLabel = "Invisible",
        hotkey = "C",
        durationSec = 8.0,
        accentHex = "#a855f7",
        blockRecipe = { stone = 2, amethyst = 1 },
        recipeText = "2 Piedra + 1 Amatista",
    },
    net = {
        kind = "net",
        name = "Lanzarred Captora",
        shortLabel = "Lanzarred",
        hotkey = "Q",
        durationSec = 5.0,
        accentHex = "#34d399",
        blockRecipe = { oak = 2, shock = 1 },
        recipeText = "2 Roble + 1 Trampa",
    },
}

GameConfig.ANCIENT_RELICS = {
    {
        id = "relic_amber_compass",
        bit = 1,
        biome = "forest",
        name = "Brújula de Ámbar Secuoya",
        bonusSummary = "+8% Velocidad Base Permanente",
        accentHex = "#fbbf24",
    },
    {
        id = "relic_forest_heart",
        bit = 2,
        biome = "forest",
        name = "Corazón de Savia Ancestral",
        bonusSummary = "+20% Regeneración de Energía",
        accentHex = "#34d399",
    },
    {
        id = "relic_amethyst_prism",
        bit = 4,
        biome = "caverns",
        name = "Prisma de Amatista Pura",
        bonusSummary = "+30% Alcance de Linterna",
        accentHex = "#c084fc",
    },
    {
        id = "relic_abyssal_core",
        bit = 8,
        biome = "caverns",
        name = "Núcleo Tectónico Abisal",
        bonusSummary = "+2 Capacidad Máxima de Bloques",
        accentHex = "#38bdf8",
    },
    {
        id = "relic_sun_crown",
        bit = 16,
        biome = "ruins",
        name = "Corona Solar del Templo",
        bonusSummary = "+20% Resistencia en Barricadas",
        accentHex = "#f59e0b",
    },
    {
        id = "relic_baboon_totem",
        bit = 32,
        biome = "ruins",
        name = "Tótem del Primer Babuino",
        bonusSummary = "+1.5 s Aturdimiento de Trampas",
        accentHex = "#fb7185",
    },
}

GameConfig.ACHIEVEMENTS = {
    { id = "first_escape", title = "Fuga Cúbica", description = "Escapa por el Portal al menos 1 vez.", reqEscapes = 1 },
    { id = "builder_15", title = "Arquitecto de Bastión", description = "Coloca 15 bloques de barricada.", reqBlocks = 15 },
    { id = "trapper_3", title = "Ingeniero de Choque", description = "Aturde o atrapa al Babuino 3 veces.", reqStuns = 3 },
    { id = "score_2000", title = "Leyenda del Eclipse", description = "Alcanza 2,000 puntos totales.", reqScore = 2000 },
    { id = "veteran_5", title = "Sobreviviente Veterano", description = "Completa 5 escapes exitosos.", reqEscapes = 5 },
}

return GameConfig
