local addonName, LSaber = ...
LSaber = LSaber or {}
LSaber.AddonName = LSaber.AddonName or addonName or "LightsaberCrit"

local SOUND_CRIT = "Interface\\AddOns\\LightsaberCrit\\sounds\\lightsaber_crit.wav"
local SOUND_PROC = "Interface\\AddOns\\LightsaberCrit\\sounds\\lightsaber_proc.wav"
local SOUND_SWING1 = "Interface\\AddOns\\LightsaberCrit\\sounds\\lightsaber_swing1.wav"
local SOUND_SWING2 = "Interface\\AddOns\\LightsaberCrit\\sounds\\lightsaber_swing2.wav"

local swingFlip = false
local sfxMuteActive = false
local sfxMuteUntil = 0
local prevSFXEnabled = nil

local function debug(...)
    if LSaber.Debug then
        LSaber.Debug(...)
    end
end

function LSaber.PlayCrit()
    PlaySoundFile(SOUND_CRIT, "Master")
end

function LSaber.PlayProc()
    PlaySoundFile(SOUND_PROC, "Master")
end

function LSaber.PlaySwing1()
    PlaySoundFile(SOUND_SWING1, "Master")
end

function LSaber.PlaySwing2()
    PlaySoundFile(SOUND_SWING2, "Master")
end

function LSaber.PlaySwing(dualWield)
    if dualWield then
        swingFlip = not swingFlip
        PlaySoundFile(swingFlip and SOUND_SWING1 or SOUND_SWING2, "Master")
        debug("SWING alt:", swingFlip and "S1" or "S2")
    else
        PlaySoundFile(SOUND_SWING1, "Master")
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
