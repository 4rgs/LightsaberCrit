local addonName = "LightsaberCrit"
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
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
        angle = 220,
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

LightsaberCritDB = LightsaberCritDB or {}
ApplyDefaults(LightsaberCritDB, DEFAULT_DB)

-- === Config ===
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

local function p(...)
    if DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r "..table.concat({tostringall(...)}, " "))
    end
end

-- === UI (options + minimap icon) ===
local minimapButton = nil
local optionsPanel = nil
local optionsControls = nil
local OpenConfig = nil

local function UpdateMinimapButtonPosition()
    if not minimapButton then return end
    local angle = LightsaberCritDB.minimap.angle or 220
    local radius = (Minimap:GetWidth() / 2) + 6
    local angleRad = math.rad(angle)
    local x = math.cos(angleRad) * radius
    local y = math.sin(angleRad) * radius
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function SetMinimapButtonVisible(visible)
    if not minimapButton then return end
    if visible then
        minimapButton:Show()
    else
        minimapButton:Hide()
    end
end

local function CreateMinimapButton()
    if minimapButton then return minimapButton end

    local button = CreateFrame("Button", "LightsaberCritMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Sword_04")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetSize(18, 18)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT", button, "TOPLEFT", -6, 6)
    border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 6, -6)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("LightsaberCrit")
        GameTooltip:AddLine("Click: abrir opciones", 1, 1, 1)
        GameTooltip:AddLine("Arrastrar: mover icono", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" then
            OpenConfig()
        end
    end)

    button:SetScript("OnDragStart", function(self)
        self.isMoving = true
        self:SetScript("OnUpdate", function()
            local cursorX, cursorY = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cursorX = cursorX / scale
            cursorY = cursorY / scale
            local minimapX, minimapY = Minimap:GetCenter()
            local angle = math.deg(math.atan(cursorY - minimapY, cursorX - minimapX))
            if angle < 0 then angle = angle + 360 end
            LightsaberCritDB.minimap.angle = angle
            UpdateMinimapButtonPosition()
        end)
    end)

    button:SetScript("OnDragStop", function(self)
        self.isMoving = false
        self:SetScript("OnUpdate", nil)
    end)

    minimapButton = button
    UpdateMinimapButtonPosition()
    SetMinimapButtonVisible(not LightsaberCritDB.minimap.hide)
    return minimapButton
end

local function CreateCheckbox(parent, label, tooltip)
    local check = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    if check.Text then
        check.Text:SetText(label)
    end
    if tooltip then
        check.tooltipText = tooltip
    end
    return check
end

local function RefreshOptionsControls()
    if not optionsControls then return end
    optionsControls.swing:SetChecked(LightsaberCritDB.swingEnabled)
    optionsControls.autoMute:SetChecked(LightsaberCritDB.autoMute)
    optionsControls.learn:SetChecked(LightsaberCritDB.learn)
    optionsControls.minimap:SetChecked(not LightsaberCritDB.minimap.hide)
end

local function RegisterOptionsPanel(panel)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, addonName)
        Settings.RegisterAddOnCategory(category)
        panel.category = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

local function EnsureOptionsPanel()
    if optionsPanel then return optionsPanel end
    optionsPanel = CreateFrame("Frame", "LightsaberCritOptionsPanel")
    optionsPanel.name = addonName

    local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("LightsaberCrit")

    local subtitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetText("Configuracion de sonidos y minimapa.")

    local swingCheck = CreateCheckbox(optionsPanel, "Reproducir swings", "Sonidos de swing en golpes no crit.")
    swingCheck:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -12)
    swingCheck:SetScript("OnClick", function(self)
        LightsaberCritDB.swingEnabled = self:GetChecked() and true or false
    end)

    local autoMuteCheck = CreateCheckbox(optionsPanel, "Auto-mute SFX melee", "Silencia SFX melee por defecto alrededor de tus golpes.")
    autoMuteCheck:SetPoint("TOPLEFT", swingCheck, "BOTTOMLEFT", 0, -8)
    autoMuteCheck:SetScript("OnClick", function(self)
        LightsaberCritDB.autoMute = self:GetChecked() and true or false
    end)

    local learnCheck = CreateCheckbox(optionsPanel, "Learn mode (mensaje en chat)", "Muestra un mensaje cuando el auto-mute se activa.")
    learnCheck:SetPoint("TOPLEFT", autoMuteCheck, "BOTTOMLEFT", 0, -8)
    learnCheck:SetScript("OnClick", function(self)
        LightsaberCritDB.learn = self:GetChecked() and true or false
    end)

    local minimapCheck = CreateCheckbox(optionsPanel, "Mostrar icono en minimapa", "Activa o desactiva el boton del minimapa.")
    minimapCheck:SetPoint("TOPLEFT", learnCheck, "BOTTOMLEFT", 0, -12)
    minimapCheck:SetScript("OnClick", function(self)
        local show = self:GetChecked() and true or false
        LightsaberCritDB.minimap.hide = not show
        SetMinimapButtonVisible(show)
    end)

    local hint = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", minimapCheck, "BOTTOMLEFT", 0, -6)
    hint:SetText("Arrastra el icono para moverlo.")

    optionsControls = {
        swing = swingCheck,
        autoMute = autoMuteCheck,
        learn = learnCheck,
        minimap = minimapCheck,
    }

    optionsPanel:SetScript("OnShow", RefreshOptionsControls)
    RegisterOptionsPanel(optionsPanel)
    return optionsPanel
end

OpenConfig = function()
    local panel = EnsureOptionsPanel()
    if Settings and Settings.OpenToCategory and panel.category then
        Settings.OpenToCategory(panel.category)
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
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
-- Avoid taint by not overriding PlaySound/PlaySoundFile. We temporarily mute the SFX channel.
local sfxMuteActive = false
local sfxMuteUntil = 0
local prevSFXEnabled = nil

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
        C_Timer.After(remaining, ensureSFXMuteWindow)
        return
    end
    restoreSFXMute()
end

local function muteSFXFor(duration)
    if not LightsaberCritDB.autoMute then return end
    local now = GetTime()
    sfxMuteUntil = math.max(sfxMuteUntil, now + duration)
    if not sfxMuteActive then
        prevSFXEnabled = GetCVar("Sound_EnableSFX")
        SetCVar("Sound_EnableSFX", "0")
        sfxMuteActive = true
        if LightsaberCritDB.learn then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Auto-mute SFX for "..tostring(duration).."s")
        end
        C_Timer.After(duration, ensureSFXMuteWindow)
    end
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
    elseif cmd == "config" or cmd == "options" or cmd == "gui" then
        OpenConfig()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r /lsaber crit | proc | s1 | s2 | swingon | swingoff | debug | muteauto on|off | learn on|off | config")
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

    -- Auto-attack swings
    if subEvent == "SWING_DAMAGE" then
        local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing =
            arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20

        if critical then
            muteSFXFor(0.35)
            PlaySoundFile(SOUND_CRIT, "Master")
            p("SWING_DAMAGE crit", amount)
        else
            muteSFXFor(0.25)
            if LightsaberCritDB.swingEnabled then
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
            muteSFXFor(0.35)
            PlaySoundFile(SOUND_CRIT, "Master")
            p("SPELL_DAMAGE crit:", spellName, amount)
        elseif LightsaberCritDB.swingEnabled and (spellSchool == 1 or spellName == "Attack") then
            muteSFXFor(0.25)
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
        EnsureOptionsPanel()
        CreateMinimapButton()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff88[LSaber]|r Loaded. /lsaber config para opciones. Auto-mute default melee SFX is "..(LightsaberCritDB.autoMute and "ON" or "OFF"))
    elseif event == "PLAYER_LOGOUT" then
        restoreSFXMute()
    elseif event == "UNIT_INVENTORY_CHANGED" then
        local unit = ...
        if unit == "player" then
            UpdateDualWieldState()
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        handleCombatLog()
    end
end)
