local addonName, LSaber = ...
LSaber = LSaber or {}
LSaber.AddonName = LSaber.AddonName or addonName or "LightsaberCrit"

local PROFILE_FIELDS = {
    "autoMute",
    "autoMuteDuration",
    "combatOnly",
    "learn",
    "swingEnabled",
    "soundTest",
    "soundVolume",
    "soundOverrides",
}

local function CopyValue(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, entry in pairs(value) do
        copy[key] = entry
    end
    return copy
end

local function SaveProfile(db, profile)
    for _, field in ipairs(PROFILE_FIELDS) do
        profile[field] = CopyValue(db[field])
    end
end

local function LoadProfile(profile, db, defaults)
    for _, field in ipairs(PROFILE_FIELDS) do
        local value = profile[field]
        if value == nil and defaults then
            value = defaults[field]
        end
        db[field] = CopyValue(value)
    end
    if type(db.soundOverrides) ~= "table" then
        db.soundOverrides = {}
    end
end

local function GetClassKey()
    local _, class = UnitClass("player")
    if not class or class == "" then
        class = "UNKNOWN"
    end
    return "class:"..class
end

local function GetSpecKey()
    if GetSpecialization and GetSpecializationInfo then
        local specIndex = GetSpecialization()
        if specIndex then
            local specID, specName = GetSpecializationInfo(specIndex)
            if specID then
                return "spec:"..tostring(specID)
            end
            if specName then
                return "spec:"..specName
            end
            return "spec:"..tostring(specIndex)
        end
    end
    return nil
end

local function GetRoleKey()
    if UnitGroupRolesAssigned then
        local role = UnitGroupRolesAssigned("player")
        if role and role ~= "NONE" then
            return "role:"..role
        end
    end
    return nil
end

local function ComputeProfileKey()
    if not LightsaberCritDB then return "global" end
    local mode = LightsaberCritDB.profileMode or "global"
    if mode == "manual" then
        local manual = LightsaberCritDB.manualProfileKey
        if manual and manual ~= "" then
            return manual
        end
        return "global"
    elseif mode == "spec" then
        return GetSpecKey() or GetClassKey() or "global"
    elseif mode == "role" then
        return GetRoleKey() or GetClassKey() or "global"
    elseif mode == "class" then
        return GetClassKey()
    end
    return "global"
end

function LSaber.ApplyProfile(force)
    if type(LightsaberCritDB) ~= "table" then return end
    LightsaberCritDB.profiles = LightsaberCritDB.profiles or {}
    local profiles = LightsaberCritDB.profiles
    local currentKey = LightsaberCritDB.activeProfile or "global"

    if not profiles[currentKey] then
        profiles[currentKey] = {}
        SaveProfile(LightsaberCritDB, profiles[currentKey])
    end

    local newKey = ComputeProfileKey()
    if newKey == "" then
        newKey = "global"
    end
    if not force and newKey == currentKey then
        return
    end

    SaveProfile(LightsaberCritDB, profiles[currentKey])

    if not profiles[newKey] then
        profiles[newKey] = {}
        SaveProfile(LightsaberCritDB, profiles[newKey])
    end

    LoadProfile(profiles[newKey], LightsaberCritDB, LSaber.Defaults)
    LightsaberCritDB.activeProfile = newKey

    if LSaber.RefreshOptionsControls then
        LSaber.RefreshOptionsControls()
    end
end

function LSaber.InitProfiles()
    if type(LightsaberCritDB) ~= "table" then return end
    LightsaberCritDB.profiles = LightsaberCritDB.profiles or {}
    LightsaberCritDB.profileMode = LightsaberCritDB.profileMode or "global"
    LightsaberCritDB.manualProfileKey = LightsaberCritDB.manualProfileKey or "global"
    LightsaberCritDB.activeProfile = LightsaberCritDB.activeProfile or "global"
    LSaber.ApplyProfile(true)
end

function LSaber.GetProfileMode()
    return (LightsaberCritDB and LightsaberCritDB.profileMode) or "global"
end

function LSaber.SetProfileMode(mode)
    if not LightsaberCritDB then return end
    LightsaberCritDB.profileMode = mode
    LSaber.ApplyProfile(true)
end

function LSaber.GetActiveProfileKey()
    return (LightsaberCritDB and LightsaberCritDB.activeProfile) or "global"
end

function LSaber.GetManualProfileKey()
    return (LightsaberCritDB and LightsaberCritDB.manualProfileKey) or "global"
end

function LSaber.SetManualProfileKey(key)
    if not LightsaberCritDB then return end
    key = tostring(key or "")
    key = key:gsub("^%s+", ""):gsub("%s+$", "")
    if key == "" then
        key = "global"
    end
    LightsaberCritDB.manualProfileKey = key
    LSaber.ApplyProfile(true)
end
