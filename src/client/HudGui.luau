-- HudGui.luau: Interfaz gráfica completa (Menú, HUD, Hotbar, Personalización, Inventario, Logros y Clanes)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local GameUtils = require(Shared:WaitForChild("GameUtils"))

local HudGui = {}

local localPlayer = Players.LocalPlayer
local screenGui
local lobbyFrame
local hudFrame
local modalFrame
local modalContent
local modalTitle
local bannerLabel

-- Referencias HUD
local topBiomeLabel, topPhaseLabel, topPortalLabel, topScoreLabel
local hpFill, hpText, staminaFill, staminaText, eclipseAlertLabel
local logTextLabel
local blockButtons = {}
local powerupButtons = {}

local currentProfile = nil
local currentClan = nil
local remotesRef = nil

local function styleCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function styleStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(51, 65, 85)
    s.Thickness = thickness or 1.5
    s.Parent = parent
    return s
end

local function makeButton(parent, text, size, pos, bgHex, textHex)
    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromHex(bgHex or "#1e293b")
    btn.TextColor3 = Color3.fromHex(textHex or "#f8fafc")
    btn.Font = Enum.Font.GothamBold
    btn.TextScaled = true
    btn.Text = text
    btn.AutoButtonColor = true
    btn.Parent = parent
    styleCorner(btn, 8)
    return btn
end

local function makeLabel(parent, text, size, pos, textHex, align)
    local lbl = Instance.new("TextLabel")
    lbl.Size = size
    lbl.Position = pos
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromHex(textHex or "#f8fafc")
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextScaled = true
    lbl.Text = text
    lbl.TextXAlignment = align or Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

local function clearModal()
    for _, ch in ipairs(modalContent:GetChildren()) do
        if not ch:IsA("UIListLayout") then
            ch:Destroy()
        end
    end
end

local function openCustomizerModal()
    if not currentProfile then return end
    clearModal()
    modalTitle.Text = "PERSONALIZAR PERSONAJE"
    modalFrame.Visible = true

    local app = currentProfile.appearance
    local selectedChar = app.characterId
    local selectedOutfit = app.outfitId
    local selectedJacket = app.jacketColor
    local selectedPants = app.pantsColor

    makeLabel(modalContent, "1. Arquetipo de Superviviente:", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), "#38bdf8")
    local archRow = Instance.new("Frame")
    archRow.Size = UDim2.new(1, 0, 0, 44)
    archRow.BackgroundTransparency = 1
    archRow.Parent = modalContent
    for i, arch in ipairs(GameConfig.CHARACTER_ARCHETYPES) do
        local b = makeButton(archRow, arch.name, UDim2.new(0.24, -4, 1, 0), UDim2.new((i - 1) * 0.25, 0, 0, 0),
            (selectedChar == arch.id) and "#0284c7" or "#1e293b")
        b.MouseButton1Click:Connect(function()
            selectedChar = arch.id
            selectedOutfit = arch.defaultOutfit
            selectedJacket = arch.presetColors.jacketColor
            selectedPants = arch.presetColors.pantsColor
            remotesRef.LobbyAction:FireServer("update_appearance", {
                characterId = selectedChar,
                outfitId = selectedOutfit,
                jacketColor = selectedJacket,
                pantsColor = selectedPants,
                accentColor = arch.presetColors.accentColor,
            })
            openCustomizerModal()
        end)
    end

    makeLabel(modalContent, "2. Color de Chaqueta:", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), "#38bdf8")
    local swatchRow = Instance.new("Frame")
    swatchRow.Size = UDim2.new(1, 0, 0, 38)
    swatchRow.BackgroundTransparency = 1
    swatchRow.Parent = modalContent
    for i, hex in ipairs(GameConfig.AVATAR_JACKET_SWATCHES) do
        local b = makeButton(swatchRow, "", UDim2.new(0, 38, 0, 38), UDim2.new(0, (i - 1) * 44, 0, 0), hex)
        if selectedJacket == hex then
            styleStroke(b, Color3.fromRGB(255, 255, 255), 3)
        end
        b.MouseButton1Click:Connect(function()
            remotesRef.LobbyAction:FireServer("update_appearance", {
                characterId = selectedChar,
                outfitId = selectedOutfit,
                jacketColor = hex,
                pantsColor = selectedPants,
                accentColor = app.accentColor,
            })
        end)
    end
end

local function openBestiaryModal()
    clearModal()
    modalTitle.Text = "BESTIARIO Y RELIQUIAS ANCESTRALES"
    modalFrame.Visible = true

    makeLabel(modalContent, "Especímenes de Scary Baboon:", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), "#fb7185")
    for _, v in ipairs(GameConfig.BABOON_VARIANTS) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 56)
        card.BackgroundColor3 = Color3.fromHex("#1e293b")
        card.Parent = modalContent
        styleCorner(card, 6)
        styleStroke(card, Color3.fromHex(v.accentHex), 1.5)
        makeLabel(card, string.format("%s (%s) · Peligro %d/5", v.name, v.codeName, v.dangerRating),
            UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 0, 4), v.accentHex)
        makeLabel(card, v.summary, UDim2.new(1, -16, 0, 24), UDim2.new(0, 8, 0, 26), "#cbd5e1")
    end

    makeLabel(modalContent, "Reliquias Ancestrales:", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), "#fbbf24")
    for _, r in ipairs(GameConfig.ANCIENT_RELICS) do
        local unlocked = currentProfile and (bit32.band(currentProfile.unlockedRelicsMask or 0, r.bit) ~= 0)
        local txt = string.format("[%s] %s — %s", unlocked and "OBTENIDA" or "BLOQUEADA", r.name, r.bonusSummary)
        makeLabel(modalContent, txt, UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), unlocked and "#34d399" or "#94a3b8")
    end
end

local function openAchievementsModal()
    clearModal()
    modalTitle.Text = "RANGO Y LOGROS"
    modalFrame.Visible = true

    if currentProfile then
        local rank = GameUtils.getPlayerRank(currentProfile.totalScore or 0, currentProfile.escapesCompleted or 0)
        makeLabel(modalContent, string.format("Rango Actual: %s (Nivel %d) | Puntos: %d | Escapes: %d",
            rank.title, rank.tier, currentProfile.totalScore or 0, currentProfile.escapesCompleted or 0),
            UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), "#fbbf24")
    end

    for _, ach in ipairs(GameConfig.ACHIEVEMENTS) do
        local done = currentProfile and currentProfile.unlockedAchievements and currentProfile.unlockedAchievements[ach.id]
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 44)
        card.BackgroundColor3 = Color3.fromHex(done and "#064e3b" or "#1e293b")
        card.Parent = modalContent
        styleCorner(card, 6)
        makeLabel(card, string.format("%s %s — %s", done and "[OK]" or "[ ]", ach.title, ach.description),
            UDim2.new(1, -16, 1, -8), UDim2.new(0, 8, 0, 4), done and "#34d399" or "#cbd5e1")
    end
end

local function openClanModal()
    clearModal()
    modalTitle.Text = "CLAN DEL ESCUADRÓN"
    modalFrame.Visible = true

    if currentClan then
        makeLabel(modalContent, string.format("[%s] %s — %s", currentClan.tag, currentClan.name, currentClan.motto),
            UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 0), "#38bdf8")
        makeLabel(modalContent, string.format("Puntos del Clan: %d | Escapes: %d",
            currentClan.totalScore or 0, currentClan.totalEscapes or 0),
            UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), "#cbd5e1")
    end

    local tagBox = Instance.new("TextBox")
    tagBox.Size = UDim2.new(1, 0, 0, 36)
    tagBox.BackgroundColor3 = Color3.fromHex("#0f172a")
    tagBox.TextColor3 = Color3.fromHex("#f8fafc")
    tagBox.PlaceholderText = "Etiqueta del Clan (ej. APEX)"
    tagBox.Text = ""
    tagBox.Font = Enum.Font.GothamBold
    tagBox.TextScaled = true
    tagBox.Parent = modalContent
    styleCorner(tagBox, 6)

    local joinBtn = makeButton(modalContent, "Crear o Unirse al Clan", UDim2.new(0.5, 0, 0, 40), UDim2.new(0, 0, 0, 0), "#0284c7")
    joinBtn.MouseButton1Click:Connect(function()
        if #tagBox.Text >= 2 then
            remotesRef.LobbyAction:FireServer("join_clan", { tag = tagBox.Text })
        end
    end)
end

function HudGui.init(remotes)
    remotesRef = remotes
    local playerGui = localPlayer:WaitForChild("PlayerGui")

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BlockBaboonHud"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- Banner de notificaciones
    bannerLabel = Instance.new("TextLabel")
    bannerLabel.Size = UDim2.new(0.6, 0, 0, 42)
    bannerLabel.Position = UDim2.new(0.2, 0, 0.11, 0)
    bannerLabel.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
    bannerLabel.BackgroundTransparency = 0.2
    bannerLabel.TextColor3 = Color3.fromHex("#38bdf8")
    bannerLabel.Font = Enum.Font.GothamBlack
    bannerLabel.TextScaled = true
    bannerLabel.Visible = false
    bannerLabel.Parent = screenGui
    styleCorner(bannerLabel, 10)

    -- LOBBY MENU
    lobbyFrame = Instance.new("Frame")
    lobbyFrame.Size = UDim2.new(0.62, 0, 0.68, 0)
    lobbyFrame.Position = UDim2.new(0.19, 0, 0.16, 0)
    lobbyFrame.BackgroundColor3 = Color3.fromHex("#0f172a")
    lobbyFrame.BackgroundTransparency = 0.08
    lobbyFrame.Parent = screenGui
    styleCorner(lobbyFrame, 14)
    styleStroke(lobbyFrame, Color3.fromHex("#38bdf8"), 2)

    makeLabel(lobbyFrame, "BLOCK BABOON: FUGA CÚBICA", UDim2.new(1, -32, 0, 46), UDim2.new(0, 16, 0, 18), "#38bdf8", Enum.TextXAlignment.Center)
    makeLabel(lobbyFrame, "Supervivencia cooperativa 3D · Construye barricadas, activa el Portal y escapa.",
        UDim2.new(1, -32, 0, 26), UDim2.new(0, 16, 0, 66), "#94a3b8", Enum.TextXAlignment.Center)

    local playSurv = makeButton(lobbyFrame, "JUGAR SUPERVIVENCIA", UDim2.new(0.44, 0, 0, 56), UDim2.new(0.05, 0, 0.28, 0), "#059669")
    playSurv.MouseButton1Click:Connect(function()
        remotes.LobbyAction:FireServer("start_match", { mode = "survival" })
    end)

    local playTrain = makeButton(lobbyFrame, "MODO ENTRENAMIENTO", UDim2.new(0.44, 0, 0, 56), UDim2.new(0.51, 0, 0.28, 0), "#0284c7")
    playTrain.MouseButton1Click:Connect(function()
        remotes.LobbyAction:FireServer("start_match", { mode = "training" })
    end)

    local btnCust = makeButton(lobbyFrame, "Personaje", UDim2.new(0.21, 0, 0, 44), UDim2.new(0.05, 0, 0.52, 0), "#1e293b")
    btnCust.MouseButton1Click:Connect(openCustomizerModal)

    local btnBest = makeButton(lobbyFrame, "Bestiario / Reliquias", UDim2.new(0.22, 0, 0, 44), UDim2.new(0.28, 0, 0.52, 0), "#1e293b")
    btnBest.MouseButton1Click:Connect(openBestiaryModal)

    local btnAch = makeButton(lobbyFrame, "Rango y Logros", UDim2.new(0.22, 0, 0, 44), UDim2.new(0.52, 0, 0.52, 0), "#1e293b")
    btnAch.MouseButton1Click:Connect(openAchievementsModal)

    local btnClan = makeButton(lobbyFrame, "Clan", UDim2.new(0.20, 0, 0, 44), UDim2.new(0.76, 0, 0.52, 0), "#1e293b")
    btnClan.MouseButton1Click:Connect(openClanModal)

    makeLabel(lobbyFrame, "Controles: [1-7] Elegir Bloque · [F] Colocar · [X] Recuperar · [Z/C/Q] Power-Ups · [L] Linterna · [Shift] Correr · [G] Ping",
        UDim2.new(1, -32, 0, 40), UDim2.new(0, 16, 0.80, 0), "#cbd5e1", Enum.TextXAlignment.Center)

    -- HUD EN PARTIDA
    hudFrame = Instance.new("Frame")
    hudFrame.Size = UDim2.new(1, 0, 1, 0)
    hudFrame.BackgroundTransparency = 1
    hudFrame.Visible = false
    hudFrame.Parent = screenGui

    -- Barra superior
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(0.76, 0, 0, 44)
    topBar.Position = UDim2.new(0.12, 0, 0.02, 0)
    topBar.BackgroundColor3 = Color3.fromHex("#0f172a")
    topBar.BackgroundTransparency = 0.2
    topBar.Parent = hudFrame
    styleCorner(topBar, 10)
    styleStroke(topBar, Color3.fromHex("#334155"), 1.5)

    topBiomeLabel = makeLabel(topBar, "Nivel 1 · Bosque Denso", UDim2.new(0.28, 0, 1, -8), UDim2.new(0.02, 0, 0, 4), "#34d399")
    topPhaseLabel = makeLabel(topBar, "Día Cúbico · Despejado", UDim2.new(0.28, 0, 1, -8), UDim2.new(0.31, 0, 0, 4), "#fbbf24")
    topPortalLabel = makeLabel(topBar, "Núcleos: 0 / 4", UDim2.new(0.22, 0, 1, -8), UDim2.new(0.60, 0, 0, 4), "#38bdf8")
    topScoreLabel = makeLabel(topBar, "Pts: 0", UDim2.new(0.15, 0, 1, -8), UDim2.new(0.83, 0, 0, 4), "#f8fafc", Enum.TextXAlignment.Right)

    -- Barras de Vida y Estamina (abajo izquierda)
    local statsBox = Instance.new("Frame")
    statsBox.Size = UDim2.new(0, 240, 0, 96)
    statsBox.Position = UDim2.new(0, 16, 1, -112)
    statsBox.BackgroundColor3 = Color3.fromHex("#0f172a")
    statsBox.BackgroundTransparency = 0.25
    statsBox.Parent = hudFrame
    styleCorner(statsBox, 10)

    local hpBg = Instance.new("Frame")
    hpBg.Size = UDim2.new(1, -20, 0, 22)
    hpBg.Position = UDim2.new(0, 10, 0, 12)
    hpBg.BackgroundColor3 = Color3.fromHex("#1e293b")
    hpBg.Parent = statsBox
    styleCorner(hpBg, 6)
    hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Color3.fromHex("#ef4444")
    hpFill.Parent = hpBg
    styleCorner(hpFill, 6)
    hpText = makeLabel(hpBg, "HP 100/100", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), "#ffffff", Enum.TextXAlignment.Center)

    local stBg = Instance.new("Frame")
    stBg.Size = UDim2.new(1, -20, 0, 18)
    stBg.Position = UDim2.new(0, 10, 0, 42)
    stBg.BackgroundColor3 = Color3.fromHex("#1e293b")
    stBg.Parent = statsBox
    styleCorner(stBg, 6)
    staminaFill = Instance.new("Frame")
    staminaFill.Size = UDim2.new(1, 0, 1, 0)
    staminaFill.BackgroundColor3 = Color3.fromHex("#fbbf24")
    staminaFill.Parent = stBg
    styleCorner(staminaFill, 6)
    staminaText = makeLabel(stBg, "Energía 100%", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), "#0f172a", Enum.TextXAlignment.Center)

    eclipseAlertLabel = makeLabel(statsBox, "Luz Segura", UDim2.new(1, -20, 0, 22), UDim2.new(0, 10, 0, 68), "#34d399")

    -- Hotbar inferior central (7 Bloques + 3 Powerups + Craft rápido)
    local hotbar = Instance.new("Frame")
    hotbar.Size = UDim2.new(0, 620, 0, 64)
    hotbar.Position = UDim2.new(0.5, -310, 1, -76)
    hotbar.BackgroundColor3 = Color3.fromHex("#0f172a")
    hotbar.BackgroundTransparency = 0.2
    hotbar.Parent = hudFrame
    styleCorner(hotbar, 10)

    for i, kind in ipairs(GameConfig.BLOCK_ORDER) do
        local spec = GameConfig.BLOCK_SPECS[kind]
        local b = makeButton(hotbar, string.format("[%s]\n%s\n0", spec.hotkey, spec.shortLabel),
            UDim2.new(0, 56, 0, 52), UDim2.new(0, 8 + (i - 1) * 60, 0, 6), "#1e293b", spec.accentHex)
        b.MouseButton1Click:Connect(function()
            remotes.PlayerAction:FireServer("select_block", { kind = kind })
        end)
        blockButtons[kind] = b
    end

    local pOrder = { "speed", "cloak", "net" }
    for i, pKind in ipairs(pOrder) do
        local pSpec = GameConfig.POWERUP_SPECS[pKind]
        local b = makeButton(hotbar, string.format("[%s]\n%s\n0", pSpec.hotkey, pSpec.shortLabel),
            UDim2.new(0, 56, 0, 52), UDim2.new(0, 434 + (i - 1) * 60, 0, 6), "#312e81", pSpec.accentHex)
        b.MouseButton1Click:Connect(function()
            remotes.PlayerAction:FireServer("use_powerup", { kind = pKind })
        end)
        powerupButtons[pKind] = b
    end

    -- Botones de fabricación rápida
    local craftShock = makeButton(hudFrame, "Fabricar Trampa [6]", UDim2.new(0, 150, 0, 30), UDim2.new(0.5, -160, 1, -112), "#0e7490")
    craftShock.MouseButton1Click:Connect(function()
        remotes.PlayerAction:FireServer("craft_block", { kind = "shock" })
    end)
    local craftDecoy = makeButton(hudFrame, "Fabricar Señuelo [7]", UDim2.new(0, 150, 0, 30), UDim2.new(0.5, 10, 1, -112), "#be123c")
    craftDecoy.MouseButton1Click:Connect(function()
        remotes.PlayerAction:FireServer("craft_block", { kind = "decoy" })
    end)

    -- Registro de eventos (derecha)
    local logBox = Instance.new("Frame")
    logBox.Size = UDim2.new(0, 260, 0, 150)
    logBox.Position = UDim2.new(1, -276, 1, -166)
    logBox.BackgroundColor3 = Color3.fromHex("#0f172a")
    logBox.BackgroundTransparency = 0.3
    logBox.Parent = hudFrame
    styleCorner(logBox, 10)
    logTextLabel = makeLabel(logBox, "", UDim2.new(1, -16, 1, -16), UDim2.new(0, 8, 0, 8), "#cbd5e1")
    logTextLabel.TextYAlignment = Enum.TextYAlignment.Top

    -- MODAL REUTILIZABLE
    modalFrame = Instance.new("Frame")
    modalFrame.Size = UDim2.new(0.58, 0, 0.66, 0)
    modalFrame.Position = UDim2.new(0.21, 0, 0.17, 0)
    modalFrame.BackgroundColor3 = Color3.fromHex("#0f172a")
    modalFrame.Visible = false
    modalFrame.ZIndex = 10
    modalFrame.Parent = screenGui
    styleCorner(modalFrame, 12)
    styleStroke(modalFrame, Color3.fromHex("#38bdf8"), 2)

    modalTitle = makeLabel(modalFrame, "MODAL", UDim2.new(1, -90, 0, 36), UDim2.new(0, 16, 0, 10), "#f8fafc")
    local closeBtn = makeButton(modalFrame, "X", UDim2.new(0, 36, 0, 36), UDim2.new(1, -46, 0, 10), "#ef4444")
    closeBtn.MouseButton1Click:Connect(function()
        modalFrame.Visible = false
    end)

    modalContent = Instance.new("ScrollingFrame")
    modalContent.Size = UDim2.new(1, -32, 1, -64)
    modalContent.Position = UDim2.new(0, 16, 0, 54)
    modalContent.BackgroundTransparency = 1
    modalContent.ScrollBarThickness = 6
    modalContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
    modalContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    modalContent.Parent = modalFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = modalContent
end

function HudGui.setProfile(profile, clan)
    currentProfile = profile
    if clan then
        currentClan = clan
    end
end

function HudGui.showBanner(text, hexColor)
    if not bannerLabel then return end
    bannerLabel.Text = text
    bannerLabel.TextColor3 = Color3.fromHex(hexColor or "#38bdf8")
    bannerLabel.Visible = true
    task.delay(4.0, function()
        if bannerLabel and bannerLabel.Text == text then
            bannerLabel.Visible = false
        end
    end)
end

function HudGui.updateSnapshot(snapshot, myState)
    if not snapshot then return end
    local isPlaying = (snapshot.phase == "playing")
    lobbyFrame.Visible = not isPlaying
    hudFrame.Visible = isPlaying
    if not isPlaying then return end

    local biomeSpec = GameUtils.getBiomeForLevel(snapshot.level)
    local weatherMods = GameUtils.getWeatherModifiers(snapshot.weather, snapshot.biome)
    topBiomeLabel.Text = string.format("Nv.%d · %s", snapshot.level, biomeSpec.name)
    topPhaseLabel.Text = string.format("%s · %s", snapshot.dayPhase or "Día", weatherMods.label)
    topPortalLabel.Text = snapshot.portalUnlocked and "¡PORTAL ACTIVO!" or string.format("Núcleos: %d / %d", snapshot.beaconsDeposited, snapshot.beaconsRequired)
    topScoreLabel.Text = string.format("Pts: %d", snapshot.score or 0)

    if myState then
        hpFill.Size = UDim2.new(math.clamp(myState.hp / myState.maxHp, 0, 1), 0, 1, 0)
        hpText.Text = string.format("HP %d/%d", math.floor(myState.hp), myState.maxHp)
        staminaFill.Size = UDim2.new(math.clamp(myState.stamina / myState.maxStamina, 0, 1), 0, 1, 0)
        staminaText.Text = string.format("Energía %d%%", math.floor(myState.stamina))

        if snapshot.eclipse and snapshot.eclipse.active then
            eclipseAlertLabel.Text = myState.inEclipseLight and "ECLIPSE: En Luz Segura" or "¡ECLIPSE: BUSCA LUZ!"
            eclipseAlertLabel.TextColor3 = Color3.fromHex(myState.inEclipseLight and "#34d399" or "#ef4444")
        else
            eclipseAlertLabel.Text = string.format("Núcleos en mano: %d", myState.carryingBeacons or 0)
            eclipseAlertLabel.TextColor3 = Color3.fromHex("#38bdf8")
        end

        for kind, btn in pairs(blockButtons) do
            local spec = GameConfig.BLOCK_SPECS[kind]
            local count = myState.blocks[kind] or 0
            btn.Text = string.format("[%s]\n%s\n%d", spec.hotkey, spec.shortLabel, count)
            btn.BackgroundColor3 = Color3.fromHex((myState.selectedBlock == kind) and "#0284c7" or "#1e293b")
        end

        for pKind, btn in pairs(powerupButtons) do
            local pSpec = GameConfig.POWERUP_SPECS[pKind]
            local count = myState.powerups[pKind] or 0
            btn.Text = string.format("[%s]\n%s\n%d", pSpec.hotkey, pSpec.shortLabel, count)
        end
    end

    if snapshot.logs then
        logTextLabel.Text = table.concat(snapshot.logs, "\n")
    end
end

return HudGui
