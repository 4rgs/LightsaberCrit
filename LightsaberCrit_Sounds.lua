local addonName, LSaber = ...
LSaber = LSaber or {}
LSaber.AddonName = LSaber.AddonName or addonName or "LightsaberCrit"

local SOUND_CRIT = "Interface\\AddOns\\LightsaberCrit\\sounds\\lightsaber_crit.wav"
local SOUND_PROC = "Interface\\AddOns\\LightsaberCrit\\sounds\\lightsaber_proc.wav"
local SOUND_SWING1 = "Interface\\AddOns\\LightsaberCrit\\sounds\\lightsaber_swing1.wav"
local SOUND_SWING2 = "Interface\\AddOns\\LightsaberCrit\\sounds\\lightsaber_swing2.wav"

local DEFAULT_SOUNDS = {
    crit = SOUND_CRIT,
    proc = SOUND_PROC,
    swing1 = SOUND_SWING1,
    swing2 = SOUND_SWING2,
}

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
if LSM then
    LSM:Register("sound", "LightsaberCrit - Crit", SOUND_CRIT)
    LSM:Register("sound", "LightsaberCrit - Proc", SOUND_PROC)
    LSM:Register("sound", "LightsaberCrit - Swing 1", SOUND_SWING1)
    LSM:Register("sound", "LightsaberCrit - Swing 2", SOUND_SWING2)
end

local swingFlip = false
local sfxMuteActive = false
local sfxMuteUntil = 0
local prevSFXEnabled = nil
local soundVolumeActive = false
local soundVolumeUntil = 0
local prevMasterVolume = nil

local function restoreSoundVolume()
    if not soundVolumeActive then return end
    if prevMasterVolume ~= nil then
        SetCVar("Sound_MasterVolume", prevMasterVolume)
    end
    soundVolumeActive = false
    prevMasterVolume = nil
end

local function ensureSoundVolumeWindow()
    if not soundVolumeActive then return end
    local now = GetTime()
    if now < soundVolumeUntil then
        local remaining = soundVolumeUntil - now
        if remaining < 0 then remaining = 0 end
        if LSaber.After then
            LSaber.After(remaining, ensureSoundVolumeWindow)
        elseif C_Timer and C_Timer.After then
            C_Timer.After(remaining, ensureSoundVolumeWindow)
        end
        return
    end
    restoreSoundVolume()
end

local function applySoundVolume(duration)
    if not LightsaberCritDB then return end
    local volume = tonumber(LightsaberCritDB.soundVolume)
    if not volume or volume >= 0.99 then return end
    if volume < 0 then volume = 0 end
    if volume > 1 then volume = 1 end

    local now = GetTime()
    soundVolumeUntil = math.max(soundVolumeUntil, now + (duration or 0))
    if not soundVolumeActive then
        prevMasterVolume = GetCVar("Sound_MasterVolume")
        local prev = tonumber(prevMasterVolume) or 1
        local newVolume = prev * volume
        SetCVar("Sound_MasterVolume", tostring(newVolume))
        soundVolumeActive = true
        if LSaber.After then
            LSaber.After(duration or 0, ensureSoundVolumeWindow)
        elseif C_Timer and C_Timer.After then
            C_Timer.After(duration or 0, ensureSoundVolumeWindow)
        end
    end
end

local function resolveSound(kind)
    local sound = DEFAULT_SOUNDS[kind]
    local overrides = LightsaberCritDB and LightsaberCritDB.soundOverrides
    local override = overrides and overrides[kind]
    if override and override ~= "" then
        if LSM and LSM.Fetch then
            local fetched = LSM:Fetch("sound", override, true)
            if fetched then
                sound = fetched
            elseif override:find("\\") then
                sound = override
            end
        elseif override:find("\\") then
            sound = override
        end
    end
    return sound
end

function LSaber.GetLSMSoundList()
    if not LSM or not LSM.List then return nil end
    local list = LSM:List("sound")
    table.sort(list)
    return list
end

local function debug(...)
    if LSaber.Debug then
        LSaber.Debug(...)
    end
end

function LSaber.PlayCrit()
    applySoundVolume(0.35)
    PlaySoundFile(resolveSound("crit"), "Master")
end

function LSaber.PlayProc()
    applySoundVolume(0.35)
    PlaySoundFile(resolveSound("proc"), "Master")
end

function LSaber.PlaySwing1()
    applySoundVolume(0.25)
    PlaySoundFile(resolveSound("swing1"), "Master")
end

function LSaber.PlaySwing2()
    applySoundVolume(0.25)
    PlaySoundFile(resolveSound("swing2"), "Master")
end

function LSaber.PlaySwing(dualWield)
    if dualWield then
        swingFlip = not swingFlip
        applySoundVolume(0.25)
        PlaySoundFile(resolveSound(swingFlip and "swing1" or "swing2"), "Master")
        debug("SWING alt:", swingFlip and "S1" or "S2")
    else
        applySoundVolume(0.25)
        PlaySoundFile(resolveSound("swing1"), "Master")
        debug("SWING single")
    end
end

local function restoreSFXMute()
    if not sfxMuteActive then return end
    if prevSFXEnabled ~= nil then
        SetCVar("Sound_EnableSFX", prevSFXEnabled)
    end
    sfxMuteActive = false
    prevSFXEnabled = nil
end

local function ensureSFXMuteWindow()
    if not sfxMuteActive then return end
    local now = GetTime()
    if now < sfxMuteUntil then
        local remaining = sfxMuteUntil - now
        if remaining < 0 then remaining = 0 end
        if LSaber.After then
            LSaber.After(remaining, ensureSFXMuteWindow)
        elseif C_Timer and C_Timer.After then
            C_Timer.After(remaining, ensureSFXMuteWindow)
        end
        return
    end
    restoreSFXMute()
end

function LSaber.MuteSFXFor(duration)
    if not LightsaberCritDB or not LightsaberCritDB.autoMute then return end
    local now = GetTime()
    sfxMuteUntil = math.max(sfxMuteUntil, now + duration)
    if not sfxMuteActive then
        prevSFXEnabled = GetCVar("Sound_EnableSFX")
        SetCVar("Sound_EnableSFX", "0")
        sfxMuteActive = true
        if LightsaberCritDB.learn then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Auto-mute SFX for "..tostring(duration).."s")
        end
        if LSaber.After then
            LSaber.After(duration, ensureSFXMuteWindow)
        elseif C_Timer and C_Timer.After then
            C_Timer.After(duration, ensureSFXMuteWindow)
        end
    end
end

function LSaber.RestoreSFXMute()
    restoreSFXMute()
end

function LSaber.RestoreSoundVolume()
    restoreSoundVolume()
end
