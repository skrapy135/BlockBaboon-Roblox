-- DataStoreManager.luau: Persistencia en DataStoreService con respaldo local en memoria para Roblox Studio

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local GameUtils = require(Shared:WaitForChild("GameUtils"))

local DataStoreManager = {}

local profileStore = nil
local clanStore = nil
local apiAvailable = false

local ok, err = pcall(function()
    profileStore = DataStoreService:GetDataStore("BlockBaboon_Profiles_v1")
    clanStore = DataStoreService:GetDataStore("BlockBaboon_Clans_v1")
    apiAvailable = true
end)

if not ok then
    warn("[DataStoreManager] DataStoreService no disponible (modo Studio local): " .. tostring(err))
end

local memoryProfiles = {}
local memoryClans = {
    ["CUBIC"] = {
        id = "CUBIC",
        tag = "CUBIC",
        name = "Escuadrón Cúbico",
        motto = "Ningún babuino rompe nuestro bastión.",
        bannerHex = "#38bdf8",
        totalScore = 1200,
        totalEscapes = 3,
        members = {},
    },
}

local function createDefaultProfile(userId, displayName)
    local arch = GameConfig.CHARACTER_ARCHETYPES[1]
    return {
        userId = userId,
        displayName = displayName or "Sobreviviente",
        totalScore = 0,
        escapesCompleted = 0,
        blocksPlaced = 0,
        baboonsStunned = 0,
        unlockedAchievements = {},
        unlockedBaboonsMask = 1,
        unlockedBiomesMask = 1,
        unlockedRelicsMask = 0,
        clanId = "CUBIC",
        appearance = {
            characterId = arch.id,
            outfitId = arch.defaultOutfit,
            jacketColor = arch.presetColors.jacketColor,
            pantsColor = arch.presetColors.pantsColor,
            accentColor = arch.presetColors.accentColor,
        },
    }
end

function DataStoreManager.evaluateAchievements(profile)
    local unlocked = profile.unlockedAchievements or {}
    local newlyUnlocked = {}
    for _, ach in ipairs(GameConfig.ACHIEVEMENTS) do
        if not unlocked[ach.id] then
            local pass = false
            if ach.reqEscapes and (profile.escapesCompleted or 0) >= ach.reqEscapes then
                pass = true
            elseif ach.reqBlocks and (profile.blocksPlaced or 0) >= ach.reqBlocks then
                pass = true
            elseif ach.reqStuns and (profile.baboonsStunned or 0) >= ach.reqStuns then
                pass = true
            elseif ach.reqScore and (profile.totalScore or 0) >= ach.reqScore then
                pass = true
            end
            if pass then
                unlocked[ach.id] = true
                table.insert(newlyUnlocked, ach.title)
            end
        end
    end
    profile.unlockedAchievements = unlocked
    return newlyUnlocked
end

function DataStoreManager.loadProfile(player)
    local key = "player_" .. tostring(player.UserId)
    local data = nil

    if apiAvailable and profileStore then
        local success, res = pcall(function()
            return profileStore:GetAsync(key)
        end)
        if success and type(res) == "table" then
            data = res
        end
    end

    if not data then
        data = memoryProfiles[key] or createDefaultProfile(player.UserId, player.DisplayName)
    end

    data.displayName = player.DisplayName
    if not data.appearance then
        data.appearance = createDefaultProfile(player.UserId, player.DisplayName).appearance
    end
    if not data.unlockedAchievements then
        data.unlockedAchievements = {}
    end

    DataStoreManager.evaluateAchievements(data)
    memoryProfiles[key] = data
    return data
end

function DataStoreManager.saveProfile(player, profile)
    if not profile then return end
    local key = "player_" .. tostring(player.UserId)
    memoryProfiles[key] = profile

    if apiAvailable and profileStore then
        pcall(function()
            profileStore:SetAsync(key, profile)
        end)
    end
end

function DataStoreManager.getProfile(player)
    local key = "player_" .. tostring(player.UserId)
    return memoryProfiles[key]
end

function DataStoreManager.getRankInfo(profile)
    return GameUtils.getPlayerRank(profile.totalScore or 0, profile.escapesCompleted or 0)
end

function DataStoreManager.getClan(clanId)
    local id = string.upper(tostring(clanId or "CUBIC"))
    if memoryClans[id] then
        return memoryClans[id]
    end
    if apiAvailable and clanStore then
        local okGet, res = pcall(function()
            return clanStore:GetAsync("clan_" .. id)
        end)
        if okGet and type(res) == "table" then
            memoryClans[id] = res
            return res
        end
    end
    return memoryClans["CUBIC"]
end

function DataStoreManager.createOrJoinClan(player, profile, tag, name, motto)
    local cleanTag = string.upper(string.gsub(tostring(tag or "CUBIC"), "[^%w]", ""))
    if #cleanTag < 2 then cleanTag = "CUBIC" end
    if #cleanTag > 6 then cleanTag = string.sub(cleanTag, 1, 6) end

    local clan = memoryClans[cleanTag]
    if not clan then
        clan = {
            id = cleanTag,
            tag = cleanTag,
            name = (name and #name > 0) and name or ("Clan " .. cleanTag),
            motto = (motto and #motto > 0) and motto or "Supervivencia cooperativa.",
            bannerHex = "#38bdf8",
            totalScore = profile.totalScore or 0,
            totalEscapes = profile.escapesCompleted or 0,
            members = { player.DisplayName },
        }
        memoryClans[cleanTag] = clan
    else
        local found = false
        for _, m in ipairs(clan.members) do
            if m == player.DisplayName then
                found = true
                break
            end
        end
        if not found then
            table.insert(clan.members, player.DisplayName)
        end
    end

    profile.clanId = cleanTag
    DataStoreManager.saveProfile(player, profile)

    if apiAvailable and clanStore then
        pcall(function()
            clanStore:SetAsync("clan_" .. cleanTag, clan)
        end)
    end
    return clan
end

return DataStoreManager
