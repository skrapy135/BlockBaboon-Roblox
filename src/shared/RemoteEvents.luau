-- RemoteEvents.luau: Centraliza los RemoteEvents y RemoteFunctions entre Servidor y Cliente

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = {}

local REMOTE_NAMES = {
    "StateSync",       -- Servidor -> Cliente: Snapshot del estado de la partida
    "PlayerAction",    -- Cliente -> Servidor: Colocar bloque, craftear, powerup, linterna, ping, etc.
    "ProfileSync",     -- Servidor -> Cliente: Perfil persistente, logros, rango, clan
    "LobbyAction",     -- Cliente -> Servidor: Iniciar partida (Survival/Training), cambiar apariencia, clan
    "SoundCue",        -- Servidor -> Cliente: Disparar efectos de sonido 3D/2D
    "GameBanner",      -- Servidor -> Cliente: Alertas de Eclipse, Horda, Escape, Muerte
}

function RemoteEvents.getFolder()
    local folder = ReplicatedStorage:FindFirstChild("Remotes")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "Remotes"
        folder.Parent = ReplicatedStorage
    end
    return folder
end

function RemoteEvents.initServer()
    local folder = RemoteEvents.getFolder()
    local map = {}
    for _, name in ipairs(REMOTE_NAMES) do
        local ev = folder:FindFirstChild(name)
        if not ev then
            ev = Instance.new("RemoteEvent")
            ev.Name = name
            ev.Parent = folder
        end
        map[name] = ev
    end
    return map
end

function RemoteEvents.getClient()
    local folder = ReplicatedStorage:WaitForChild("Remotes")
    local map = {}
    for _, name in ipairs(REMOTE_NAMES) do
        map[name] = folder:WaitForChild(name)
    end
    return map
end

return RemoteEvents
