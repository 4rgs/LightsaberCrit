local addonName = "LightsaberCrit"
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("UNIT_INVENTORY_CHANGED")

-- === Saved Variables ===
LightsaberCritDB = LightsaberCritDB or {
    prevSFXVolume = nil,
    hookEnabled = false,
    autoMute = true,      -- targeted block of default melee SFX around our swings/crits
    learn = false,        -- if true, print observed SFX during windows
}

-- === Config ===
local USE_SWING = true       -- Enable swing sounds on non-crit SWING_DAMAGE
local DEBUG = false          -- Print debug to chat

-- === Sounds ===
local SOUND_CRIT   = "Interface\\AddOns\\LightsaberCrit\\sounds\\lightsaber_crit.wav"
local SOUND_PROC   = "Interface\\AddOns\\LightsaberCrit\\sounds\\lightsaber_proc.wav"
local SOUND_SWING1 = "Interface\\AddOns\\LightsaberCrit\\sounds\\lightsaber_swing1.wav"
local SOUND_SWING2 = "Interface\\AddOns\\LightsaberCrit\\sounds\\lightsaber_swing2.wav"

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
local swingFlip = false  -- toggles between swing1 and swing2

-- Time windows (seconds since GetTime())
local swingWindowUntil = 0
local critWindowUntil  = 0

local function p(...)
    if DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r "..table.concat({tostringall(...)}, " "))
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
    p("Dual wield:", dualWield and "ON" or "OFF", "(", itemName or "?", ")")
end

-- ============ Targeted blocking of default SFX ============
-- We override PlaySound and PlaySoundFile. If we're within a swing/crit window,
-- and the channel is "SFX", we skip calling the original (so the Blizzard swing/crit won't play).
local origPlaySound = PlaySound
local origPlaySoundFile = PlaySoundFile

local function shouldBlock(channel)
    if not LightsaberCritDB.autoMute then return false end
    local now = GetTime()
    -- Only block SFX channel (our sabers use "Master")
    if channel and channel ~= "SFX" then return false end
    return now < swingWindowUntil or now < critWindowUntil
end

PlaySound = function(soundKitID, channel, ...)
    if shouldBlock(channel) then
        if LightsaberCritDB.learn then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Blocked PlaySound kitID="..tostring(soundKitID).." ch="..tostring(channel))
        end
        return -- swallow
    end
    return origPlaySound(soundKitID, channel, ...)
end

PlaySoundFile = function(soundFile, channel, ...)
    if shouldBlock(channel) then
        if LightsaberCritDB.learn then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Blocked PlaySoundFile file="..tostring(soundFile).." ch="..tostring(channel))
        end
        return -- swallow
    end
    return origPlaySoundFile(soundFile, channel, ...)
end

-- Slash: /lsaber
SLASH_LIGHTSABER1 = "/lsaber"
SlashCmdList["LIGHTSABER"] = function(msg)
    msg = (msg or ""):lower()
    local cmd, rest = msg:match("^(%S+)%s*(.*)$")
    if cmd == "crit" then
        PlaySoundFile(SOUND_CRIT, "Master")
        p("Test: CRIT")
    elseif cmd == "proc" then
        PlaySoundFile(SOUND_PROC, "Master")
        p("Test: PROC")
    elseif cmd == "s1" then
        PlaySoundFile(SOUND_SWING1, "Master")
        p("Test: SWING1")
    elseif cmd == "s2" then
        PlaySoundFile(SOUND_SWING2, "Master")
        p("Test: SWING2")
    elseif cmd == "debug" then
        DEBUG = not DEBUG
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Debug "..(DEBUG and "ON" or "OFF"))
    elseif cmd == "swingon" then
        USE_SWING = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Swing sound: ON")
    elseif cmd == "swingoff" then
        USE_SWING = false
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Swing sound: OFF")
    elseif cmd == "muteauto" and (rest == "on" or rest == "off") then
        LightsaberCritDB.autoMute = (rest == "on")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Auto-mute "..(LightsaberCritDB.autoMute and "ON" or "OFF"))
    elseif cmd == "learn" and (rest == "on" or rest == "off") then
        LightsaberCritDB.learn = (rest == "on")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Learn mode "..(LightsaberCritDB.learn and "ON" or "OFF"))
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r /lsaber crit | proc | s1 | s2 | swingon | swingoff | debug | muteauto on|off | learn on|off")
    end
end

local function isPlayerGUID(guid)
    return guid == UnitGUID("player")
end

local function playSwingSound()
    if dualWield then
        swingFlip = not swingFlip
        PlaySoundFile(swingFlip and SOUND_SWING1 or SOUND_SWING2, "Master")
        p("SWING alt:", swingFlip and "S1" or "S2")
    else
        PlaySoundFile(SOUND_SWING1, "Master")
        p("SWING single")
    end
end

local function handleCombatLog()
    local timestamp, subEvent, hideCaster,
          srcGUID, srcName, srcFlags, srcRaidFlags,
          dstGUID, dstName, dstFlags, dstRaidFlags,
          arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23
        = CombatLogGetCurrentEventInfo()

    if not isPlayerGUID(srcGUID) then return end

    local now = GetTime()

    -- Auto-attack swings
    if subEvent == "SWING_DAMAGE" then
        local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing =
            arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20

        if critical then
            -- Open a slightly longer crit window to block Blizzard crit SFX
            critWindowUntil = now + 0.35
            PlaySoundFile(SOUND_CRIT, "Master")
            p("SWING_DAMAGE crit", amount)
        else
            swingWindowUntil = now + 0.25
            if USE_SWING then
                playSwingSound()
            end
        end
        return
    end

    -- Melee ability damage (e.g., Sinister Strike, Heroic Strike)
    if subEvent == "SPELL_DAMAGE" then
        local spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing =
            arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23
        if critical then
            critWindowUntil = now + 0.35
            PlaySoundFile(SOUND_CRIT, "Master")
            p("SPELL_DAMAGE crit:", spellName, amount)
        elseif USE_SWING and (spellSchool == 1 or spellName == "Attack") then
            swingWindowUntil = now + 0.25
            playSwingSound()
        end
        return
    end

    -- Extra attacks
    if subEvent == "SPELL_EXTRA_ATTACKS" then
        local spellId, spellName, amount = arg12, arg13, arg14
        PlaySoundFile(SOUND_PROC, "Master")
        p("EXTRA_ATTACKS:", spellName, "x"..tostring(amount or "?"))
        return
    end

    -- Some servers show an aura when granting extra swings
    if subEvent == "SPELL_AURA_APPLIED" then
        local spellId, spellName, spellSchool, auraType, amount = arg12, arg13, arg14, arg15, arg16
        if EXTRA_ATTACK_SPELLS[spellId] or (spellName and spellName:find("Thrash")) then
            PlaySoundFile(SOUND_PROC, "Master")
            p("AURA_APPLIED:", spellName, "(", auraType or "aura", ")")
        end
        return
    end
end

f:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        UpdateDualWieldState()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Loaded. /lsaber for help. Auto-mute default melee SFX is "..(LightsaberCritDB.autoMute and "ON" or "OFF"))
    elseif event == "UNIT_INVENTORY_CHANGED" then
        local unit = ...
        if unit == "player" then
            UpdateDualWieldState()
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        handleCombatLog()
    end
end)
