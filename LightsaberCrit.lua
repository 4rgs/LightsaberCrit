local addonName, LSaber = ...
LSaber = LSaber or {}
LSaber.AddonName = LSaber.AddonName or addonName or "LightsaberCrit"

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("UNIT_INVENTORY_CHANGED")
f:RegisterEvent("PLAYER_LOGOUT")

-- === Saved Variables ===
local DEFAULT_DB = {
    hookEnabled = false,
    autoMute = true,      -- targeted block of default melee SFX around our swings/crits
    learn = false,        -- if true, print when auto-mute triggers
    swingEnabled = true,
    minimap = {
        hide = false,
        angle = 90,
        minimapPos = 90,
    },
}

local function ApplyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            ApplyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

-- === Config ===
local DEBUG = false

LSaber.Debug = function(...)
    if DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r "..table.concat({tostringall(...)}, " "))
    end
end

-- Extra-attack procs (SpellIDs)
local EXTRA_ATTACK_SPELLS = {
    [16459] = true,  -- Sword Specialization
    [15600] = true,  -- Hand of Justice
    [21919] = true,  -- Thrash Blade
    -- Windfury ranks
    [8232]  = true,
    [8235]  = true,
    [10486] = true,
    [25505] = true,
}

-- State
local dualWield = false

local function debug(...)
    if LSaber.Debug then
        LSaber.Debug(...)
    end
end

-- Helper: check if offhand is a weapon
local function UpdateDualWieldState()
    local offhandItemID = GetInventoryItemID("player", 17) -- Offhand slot
    if not offhandItemID then
        dualWield = false
        return
    end
    local itemName, _, _, _, _, itemType = GetItemInfo(offhandItemID)
    dualWield = (itemType == GetItemClassInfo(2))  -- "Weapon"
    debug("Dual wield:", dualWield and "ON" or "OFF", "(", itemName or "?", ")")
end

local function isPlayerGUID(guid)
    return guid == UnitGUID("player")
end

local function handleCombatLog(...)
    local timestamp, subEvent, hideCaster,
          srcGUID, srcName, srcFlags, srcRaidFlags,
          dstGUID, dstName, dstFlags, dstRaidFlags,
          arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23

    if CombatLogGetCurrentEventInfo then
        timestamp, subEvent, hideCaster,
            srcGUID, srcName, srcFlags, srcRaidFlags,
            dstGUID, dstName, dstFlags, dstRaidFlags,
            arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23
            = CombatLogGetCurrentEventInfo()
    else
        timestamp, subEvent, hideCaster,
            srcGUID, srcName, srcFlags, srcRaidFlags,
            dstGUID, dstName, dstFlags, dstRaidFlags,
            arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23
            = ...
    end

    if not subEvent or not LightsaberCritDB then return end
    if not isPlayerGUID(srcGUID) then return end

    -- Auto-attack swings
    if subEvent == "SWING_DAMAGE" then
        local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing =
            arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20

        if critical then
            if LSaber.MuteSFXFor then
                LSaber.MuteSFXFor(0.35)
            end
            if LSaber.PlayCrit then
                LSaber.PlayCrit()
            end
            debug("SWING_DAMAGE crit", amount)
        else
            if LSaber.MuteSFXFor then
                LSaber.MuteSFXFor(0.25)
            end
            if LightsaberCritDB.swingEnabled and LSaber.PlaySwing then
                LSaber.PlaySwing(dualWield)
            end
        end
        return
    end

    -- Melee ability damage (e.g., Sinister Strike, Heroic Strike)
    if subEvent == "SPELL_DAMAGE" then
        local spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing =
            arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23
        if critical then
            if LSaber.MuteSFXFor then
                LSaber.MuteSFXFor(0.35)
            end
            if LSaber.PlayCrit then
                LSaber.PlayCrit()
            end
            debug("SPELL_DAMAGE crit:", spellName, amount)
        elseif LightsaberCritDB.swingEnabled and (spellSchool == 1 or spellName == "Attack") then
            if LSaber.MuteSFXFor then
                LSaber.MuteSFXFor(0.25)
            end
            if LSaber.PlaySwing then
                LSaber.PlaySwing(dualWield)
            end
        end
        return
    end

    -- Extra attacks
    if subEvent == "SPELL_EXTRA_ATTACKS" then
        local spellId, spellName, amount = arg12, arg13, arg14
        if LSaber.PlayProc then
            LSaber.PlayProc()
        end
        debug("EXTRA_ATTACKS:", spellName, "x"..tostring(amount or "?"))
        return
    end

    -- Some servers show an aura when granting extra swings
    if subEvent == "SPELL_AURA_APPLIED" then
        local spellId, spellName, spellSchool, auraType, amount = arg12, arg13, arg14, arg15, arg16
        if EXTRA_ATTACK_SPELLS[spellId] or (spellName and spellName:find("Thrash")) then
            if LSaber.PlayProc then
                LSaber.PlayProc()
            end
            debug("AURA_APPLIED:", spellName, "(", auraType or "aura", ")")
        end
        return
    end
end

local function RefreshOptionsControls()
    if LSaber.RefreshOptionsControls then
        LSaber.RefreshOptionsControls()
    end
end

local function ShowMinimapIcon(show)
    if LSaber.SetMinimapButtonVisible then
        LSaber.SetMinimapButtonVisible(show)
    end
    if show and LSaber.ForceShowMinimapButton then
        LSaber.ForceShowMinimapButton()
    end
end

-- Slash: /lsaber
SLASH_LIGHTSABER1 = "/lsaber"
SlashCmdList["LIGHTSABER"] = function(msg)
    msg = (msg or ""):lower()
    local cmd, rest = msg:match("^(%S+)%s*(.*)$")
    if cmd == "crit" then
        if LSaber.PlayCrit then
            LSaber.PlayCrit()
        end
        debug("Test: CRIT")
    elseif cmd == "proc" then
        if LSaber.PlayProc then
            LSaber.PlayProc()
        end
        debug("Test: PROC")
    elseif cmd == "s1" then
        if LSaber.PlaySwing1 then
            LSaber.PlaySwing1()
        elseif LSaber.PlaySwing then
            LSaber.PlaySwing(false)
        end
        debug("Test: SWING1")
    elseif cmd == "s2" then
        if LSaber.PlaySwing2 then
            LSaber.PlaySwing2()
        elseif LSaber.PlaySwing then
            LSaber.PlaySwing(true)
        end
        debug("Test: SWING2")
    elseif cmd == "debug" then
        DEBUG = not DEBUG
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Debug "..(DEBUG and "ON" or "OFF"))
    elseif cmd == "swingon" then
        LightsaberCritDB.swingEnabled = true
        RefreshOptionsControls()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Swing sound: ON")
    elseif cmd == "swingoff" then
        LightsaberCritDB.swingEnabled = false
        RefreshOptionsControls()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Swing sound: OFF")
    elseif cmd == "muteauto" and (rest == "on" or rest == "off") then
        LightsaberCritDB.autoMute = (rest == "on")
        RefreshOptionsControls()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Auto-mute "..(LightsaberCritDB.autoMute and "ON" or "OFF"))
    elseif cmd == "learn" and (rest == "on" or rest == "off") then
        LightsaberCritDB.learn = (rest == "on")
        RefreshOptionsControls()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Learn mode "..(LightsaberCritDB.learn and "ON" or "OFF"))
    elseif cmd == "minimap" then
        if LSaber.CreateMinimapButton then
            LSaber.CreateMinimapButton()
        end
        local sub = (rest or ""):lower()
        if sub == "show" then
            LightsaberCritDB.minimap.hide = false
            ShowMinimapIcon(true)
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Minimap icon: ON")
        elseif sub == "hide" then
            LightsaberCritDB.minimap.hide = true
            ShowMinimapIcon(false)
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Minimap icon: OFF")
        elseif sub == "reset" then
            LightsaberCritDB.minimap.hide = false
            LightsaberCritDB.minimap.angle = 220
            LightsaberCritDB.minimap.minimapPos = 220
            ShowMinimapIcon(true)
            if LSaber.RefreshMinimapIcon then
                LSaber.RefreshMinimapIcon()
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Minimap icon: reset position")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r /lsaber minimap show | hide | reset")
        end
    elseif cmd == "config" or cmd == "options" or cmd == "gui" then
        if LSaber.OpenConfig then
            LSaber.OpenConfig()
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r /lsaber crit | proc | s1 | s2 | swingon | swingoff | debug | muteauto on|off | learn on|off | minimap show|hide|reset | config")
    end
end

f:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == LSaber.AddonName then
            if type(LightsaberCritDB) ~= "table" then
                LightsaberCritDB = {}
            end
            ApplyDefaults(LightsaberCritDB, DEFAULT_DB)
            LSaber.DB = LightsaberCritDB
        end
    elseif event == "PLAYER_LOGIN" then
        if type(LightsaberCritDB) ~= "table" then
            LightsaberCritDB = {}
        end
        ApplyDefaults(LightsaberCritDB, DEFAULT_DB)
        LSaber.DB = LightsaberCritDB
        UpdateDualWieldState()
        if LSaber.EnsureOptionsPanel then
            LSaber.EnsureOptionsPanel()
        end
        if LSaber.CreateMinimapButton then
            LSaber.CreateMinimapButton()
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Loaded. /lsaber config para opciones. Auto-mute default melee SFX is "..(LightsaberCritDB.autoMute and "ON" or "OFF"))
    elseif event == "PLAYER_LOGOUT" then
        if LSaber.RestoreSFXMute then
            LSaber.RestoreSFXMute()
        end
    elseif event == "UNIT_INVENTORY_CHANGED" then
        local unit = ...
        if unit == "player" then
            UpdateDualWieldState()
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        handleCombatLog(...)
    end
end)
