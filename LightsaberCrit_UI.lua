local addonName, LSaber = ...
LSaber = LSaber or {}
LSaber.AddonName = LSaber.AddonName or addonName or "LightsaberCrit"

local minimapButton = nil
local ldbObject = nil
local ldbIcon = nil
local optionsPanel = nil
local optionsControls = nil
local configFrame = nil
local configControls = nil

local function EnsureLDBMinimapIcon()
    if ldbIcon then
        return true
    end
    if not LibStub then
        return false
    end
    local LDB = LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LibStub("LibDBIcon-1.0", true)
    if not LDB or not LDBIcon then
        return false
    end

    ldbIcon = LDBIcon
    ldbObject = LDB:NewDataObject(LSaber.AddonName, {
        type = "launcher",
        text = LSaber.AddonName,
        icon = "Interface\\Icons\\INV_Sword_04",
        OnClick = function(_, button)
            if button == "LeftButton" and LSaber.OpenConfig then
                LSaber.OpenConfig()
            end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip then return end
            tooltip:AddLine("LightsaberCrit")
            tooltip:AddLine("Click: abrir opciones", 1, 1, 1)
            tooltip:AddLine("Arrastrar: mover icono", 1, 1, 1)
        end,
    })

    LightsaberCritDB.minimap = LightsaberCritDB.minimap or {}
    if LightsaberCritDB.minimap.minimapPos == nil then
        local angle = tonumber(LightsaberCritDB.minimap.angle)
        if angle then
            LightsaberCritDB.minimap.minimapPos = angle
        end
    end
    LDBIcon:Register(LSaber.AddonName, ldbObject, LightsaberCritDB.minimap)
    return true
end

local function UpdateMinimapButtonPosition()
    if not minimapButton then return end
    local angle = tonumber(LightsaberCritDB.minimap.minimapPos)
        or tonumber(LightsaberCritDB.minimap.angle)
        or 220
    local width = Minimap:GetWidth()
    local radius = ((width and width > 0) and (width / 2) or 70) + 6
    local angleRad = math.rad(angle)
    local x = math.cos(angleRad) * radius
    local y = math.sin(angleRad) * radius
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function SetMinimapButtonVisible(visible)
    if ldbIcon then
        if visible then
            ldbIcon:Show(LSaber.AddonName)
        else
            ldbIcon:Hide(LSaber.AddonName)
        end
        return
    end
    if not minimapButton then return end
    if visible then
        minimapButton:Show()
    else
        minimapButton:Hide()
    end
end

local function ApplyMinimapButtonLayout()
    if not minimapButton then return end
    local iconSize = 14
    local borderSize = iconSize + 20
    if minimapButton.icon then
        minimapButton.icon:ClearAllPoints()
        minimapButton.icon:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
        minimapButton.icon:SetSize(iconSize, iconSize)
    end
    if minimapButton.background then
        minimapButton.background:ClearAllPoints()
        minimapButton.background:SetPoint("CENTER", minimapButton.icon or minimapButton, "CENTER", 0, 0)
        minimapButton.background:SetSize(iconSize + 4, iconSize + 4)
    end
    if minimapButton.border then
        minimapButton.border:ClearAllPoints()
        minimapButton.border:SetPoint("CENTER", minimapButton.icon or minimapButton, "CENTER", 0, 0)
        minimapButton.border:SetSize(borderSize, borderSize)
    end
    local highlight = minimapButton:GetHighlightTexture()
    if highlight then
        highlight:ClearAllPoints()
        highlight:SetPoint("CENTER", minimapButton.icon or minimapButton, "CENTER", 0, 0)
        highlight:SetSize(borderSize, borderSize)
        highlight:SetBlendMode("ADD")
    end
end

local function RefreshMinimapIcon()
    if ldbIcon and ldbIcon.Refresh then
        ldbIcon:Refresh(LSaber.AddonName, LightsaberCritDB.minimap)
    end
end

local function ForceShowMinimapButton()
    if not minimapButton or LightsaberCritDB.minimap.hide then return end
    minimapButton:SetParent(Minimap)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    minimapButton:SetAlpha(1)
    minimapButton:Show()
    ApplyMinimapButtonLayout()
    UpdateMinimapButtonPosition()
end

local function CreateMinimapButton()
    if minimapButton or ldbIcon then return minimapButton end
    if type(LightsaberCritDB) ~= "table" then
        LightsaberCritDB = {}
    end
    LightsaberCritDB.minimap = LightsaberCritDB.minimap or {}
    if LightsaberCritDB.minimap.hide == nil then
        LightsaberCritDB.minimap.hide = false
    end
    if LightsaberCritDB.minimap.angle == nil then
        LightsaberCritDB.minimap.angle = 220
    end
    if LightsaberCritDB.minimap.minimapPos == nil then
        LightsaberCritDB.minimap.minimapPos = LightsaberCritDB.minimap.angle
    end
    if EnsureLDBMinimapIcon() then
        SetMinimapButtonVisible(not LightsaberCritDB.minimap.hide)
        return nil
    end

    local button = CreateFrame("Button", "LightsaberCritMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetPoint("CENTER", button, "CENTER", 0, 0)
    background:SetSize(20, 20)
    button.background = background

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Sword_04")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetSize(14, 14)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT", button, "TOPLEFT", -6, 6)
    border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 6, -6)
    button.border = border

    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:SetBlendMode("ADD")
    end

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

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" and LSaber.OpenConfig then
            LSaber.OpenConfig()
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
            local atan2 = LSaber.Atan2 or math.atan
            local angle = math.deg(atan2(cursorY - minimapY, cursorX - minimapX))
            if angle < 0 then angle = angle + 360 end
            LightsaberCritDB.minimap.angle = angle
            LightsaberCritDB.minimap.minimapPos = angle
            UpdateMinimapButtonPosition()
        end)
    end)

    button:SetScript("OnDragStop", function(self)
        self.isMoving = false
        self:SetScript("OnUpdate", nil)
    end)

    minimapButton = button
    ApplyMinimapButtonLayout()
    UpdateMinimapButtonPosition()
    SetMinimapButtonVisible(not LightsaberCritDB.minimap.hide)
    ForceShowMinimapButton()
    if LSaber.After then
        LSaber.After(0.5, ForceShowMinimapButton)
    end
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

local function CreateButton(parent, label, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 90, height or 22)
    button:SetText(label)
    return button
end

local function CreateSlider(parent, label, minValue, maxValue, step)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(180)
    slider:SetHeight(16)
    slider.Text:SetText(label)
    slider.Low:SetText(string.format("%.2f", minValue))
    slider.High:SetText(string.format("%.2f", maxValue))
    slider:SetThumbTexture("Interface\\OptionsFrame\\UI-OptionsSlider-Thumb")
    local thumb = slider:GetThumbTexture()
    if thumb then
        thumb:SetSize(16, 16)
    end
    if not slider.barBackground then
        slider.barBackground = slider:CreateTexture(nil, "ARTWORK")
    end
    slider.barBackground:SetTexture("Interface\\OptionsFrame\\UI-OptionsSlider-Background")
    slider.barBackground:SetPoint("LEFT", slider, "LEFT", 6, 0)
    slider.barBackground:SetPoint("RIGHT", slider, "RIGHT", -6, 0)
    slider.barBackground:SetHeight(8)
    if not slider.barBorder then
        slider.barBorder = slider:CreateTexture(nil, "BORDER")
    end
    slider.barBorder:SetTexture("Interface\\OptionsFrame\\UI-OptionsSlider-Border")
    slider.barBorder:SetAllPoints(slider.barBackground)
    return slider
end

local function UpdateSoundVolumeSliderText(slider, value)
    if not slider or not slider.Text then return end
    slider.Text:SetText(string.format("Volumen de sonidos: %d%%", math.floor((value or 1) * 100 + 0.5)))
end

local SOUND_TEST_OPTIONS = {
    { value = "crit", label = "Crit" },
    { value = "proc", label = "Proc" },
    { value = "swing1", label = "Swing 1" },
    { value = "swing2", label = "Swing 2" },
}

local PROFILE_MODE_OPTIONS = {
    { value = "global", label = "Global" },
    { value = "class", label = "Clase" },
    { value = "spec", label = "Especializacion" },
    { value = "role", label = "Rol" },
    { value = "manual", label = "Manual" },
}

local function GetProfileModeLabel(value)
    for _, option in ipairs(PROFILE_MODE_OPTIONS) do
        if option.value == value then
            return option.label
        end
    end
    return PROFILE_MODE_OPTIONS[1].label
end

local function GetSoundOverride(kind)
    if not LightsaberCritDB or not LightsaberCritDB.soundOverrides then return nil end
    return LightsaberCritDB.soundOverrides[kind]
end

local function SetSoundOverride(kind, value)
    if not LightsaberCritDB then return end
    LightsaberCritDB.soundOverrides = LightsaberCritDB.soundOverrides or {}
    if value == nil or value == "" then
        LightsaberCritDB.soundOverrides[kind] = nil
    else
        LightsaberCritDB.soundOverrides[kind] = value
    end
end

local function GetLSMSoundList()
    if LSaber.GetLSMSoundList then
        return LSaber.GetLSMSoundList()
    end
    return nil
end

local function GetSoundTestLabel(value)
    for _, option in ipairs(SOUND_TEST_OPTIONS) do
        if option.value == value then
            return option.label
        end
    end
    return SOUND_TEST_OPTIONS[1].label
end

local function PlaySelectedSound()
    local value = LightsaberCritDB and LightsaberCritDB.soundTest or "crit"
    if value == "crit" then
        if LSaber.PlayCrit then LSaber.PlayCrit() end
    elseif value == "proc" then
        if LSaber.PlayProc then LSaber.PlayProc() end
    elseif value == "swing1" then
        if LSaber.PlaySwing1 then
            LSaber.PlaySwing1()
        elseif LSaber.PlaySwing then
            LSaber.PlaySwing(false)
        end
    elseif value == "swing2" then
        if LSaber.PlaySwing2 then
            LSaber.PlaySwing2()
        elseif LSaber.PlaySwing then
            LSaber.PlaySwing(true)
        end
    end
end

local function UpdateSoundDropdown(dropdown)
    if not dropdown or not LightsaberCritDB then return end
    local value = LightsaberCritDB.soundTest or "crit"
    if UIDropDownMenu_SetSelectedValue then
        UIDropDownMenu_SetSelectedValue(dropdown, value)
    end
    UIDropDownMenu_SetText(dropdown, GetSoundTestLabel(value))
end

local function UpdateProfileControls(controls)
    if not controls or not LightsaberCritDB then return end
    local mode = (LSaber.GetProfileMode and LSaber.GetProfileMode()) or (LightsaberCritDB.profileMode or "global")
    if UIDropDownMenu_SetSelectedValue then
        UIDropDownMenu_SetSelectedValue(controls.profileModeDropdown, mode)
    end
    UIDropDownMenu_SetText(controls.profileModeDropdown, GetProfileModeLabel(mode))
    if controls.profileManualEdit then
        controls.profileManualEdit:SetText((LSaber.GetManualProfileKey and LSaber.GetManualProfileKey()) or (LightsaberCritDB.manualProfileKey or "global"))
    end
    if controls.profileActiveText then
        controls.profileActiveText:SetText("Perfil activo: "..((LSaber.GetActiveProfileKey and LSaber.GetActiveProfileKey()) or (LightsaberCritDB.activeProfile or "global")))
    end
    local showManual = (mode == "manual")
    if controls.profileManualLabel then
        controls.profileManualLabel:SetShown(showManual)
    end
    if controls.profileManualEdit then
        controls.profileManualEdit:SetShown(showManual)
    end
    if controls.profileManualButton then
        controls.profileManualButton:SetShown(showManual)
    end
end

local function UpdateSoundListDropdown(dropdown)
    if not dropdown or not LightsaberCritDB then return end
    local kind = LightsaberCritDB.soundTest or "crit"
    local override = GetSoundOverride(kind)
    if UIDropDownMenu_SetSelectedValue then
        UIDropDownMenu_SetSelectedValue(dropdown, override or "")
    end
    UIDropDownMenu_SetText(dropdown, override or "Por defecto (LightsaberCrit)")
end

local function AddSoundTestControls(parent, anchor)
    if type(LightsaberCritDB) ~= "table" then
        LightsaberCritDB = {}
    end
    if LightsaberCritDB.soundTest == nil then
        LightsaberCritDB.soundTest = "crit"
    end
    if LightsaberCritDB.soundOverrides == nil then
        LightsaberCritDB.soundOverrides = {}
    end

    local typeDropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    local soundListDropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    typeDropdown:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -16, -8)
    UIDropDownMenu_SetWidth(typeDropdown, 120)
    soundListDropdown:SetPoint("TOPLEFT", typeDropdown, "BOTTOMLEFT", 0, -6)
    UIDropDownMenu_SetWidth(soundListDropdown, 180)

    UIDropDownMenu_Initialize(typeDropdown, function(_, level)
        for _, option in ipairs(SOUND_TEST_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.value = option.value
            info.func = function()
                LightsaberCritDB.soundTest = option.value
                UpdateSoundDropdown(typeDropdown)
                UpdateSoundListDropdown(soundListDropdown)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_Initialize(soundListDropdown, function(_, level)
        local info = UIDropDownMenu_CreateInfo()
        info.text = "Por defecto (LightsaberCrit)"
        info.value = ""
        info.func = function()
            local kind = LightsaberCritDB.soundTest or "crit"
            SetSoundOverride(kind, nil)
            UpdateSoundListDropdown(soundListDropdown)
        end
        UIDropDownMenu_AddButton(info, level)

        local list = GetLSMSoundList()
        if list then
            for _, name in ipairs(list) do
                local entry = UIDropDownMenu_CreateInfo()
                entry.text = name
                entry.value = name
                entry.func = function()
                    local kind = LightsaberCritDB.soundTest or "crit"
                    SetSoundOverride(kind, name)
                    UpdateSoundListDropdown(soundListDropdown)
                end
                UIDropDownMenu_AddButton(entry, level)
            end
        else
            local warn = UIDropDownMenu_CreateInfo()
            warn.text = "LibSharedMedia no disponible"
            warn.disabled = true
            UIDropDownMenu_AddButton(warn, level)
        end
    end)

    UpdateSoundDropdown(typeDropdown)
    UpdateSoundListDropdown(soundListDropdown)

    local playButton = CreateButton(parent, "Reproducir", 90, 22)
    playButton:SetPoint("LEFT", typeDropdown, "RIGHT", -6, 2)
    playButton:SetScript("OnClick", PlaySelectedSound)

    return {
        dropdown = typeDropdown,
        soundListDropdown = soundListDropdown,
        playButton = playButton,
    }
end

local function AddProfileControls(parent, anchor)
    local profileControls = nil
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    title:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 16, -8)
    title:SetText("Perfiles:")

    local modeDropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    modeDropdown:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    UIDropDownMenu_SetWidth(modeDropdown, 160)
    UIDropDownMenu_Initialize(modeDropdown, function(_, level)
        for _, option in ipairs(PROFILE_MODE_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.value = option.value
            info.func = function()
                if LSaber.SetProfileMode then
                    LSaber.SetProfileMode(option.value)
                else
                    LightsaberCritDB.profileMode = option.value
                end
                UpdateProfileControls(profileControls)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local manualLabel = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    manualLabel:SetPoint("TOPLEFT", modeDropdown, "BOTTOMLEFT", 0, -4)
    manualLabel:SetText("Perfil manual:")

    local manualEdit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    manualEdit:SetAutoFocus(false)
    manualEdit:SetSize(120, 20)
    manualEdit:SetPoint("LEFT", manualLabel, "RIGHT", 6, 0)
    manualEdit:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if LSaber.SetManualProfileKey then
            LSaber.SetManualProfileKey(self:GetText())
        else
            LightsaberCritDB.manualProfileKey = self:GetText()
        end
        UpdateProfileControls(profileControls)
    end)
    manualEdit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    local manualButton = CreateButton(parent, "Usar", 60, 20)
    manualButton:SetPoint("LEFT", manualEdit, "RIGHT", 6, 0)
    manualButton:SetScript("OnClick", function()
        if LSaber.SetManualProfileKey then
            LSaber.SetManualProfileKey(manualEdit:GetText())
        else
            LightsaberCritDB.manualProfileKey = manualEdit:GetText()
        end
        UpdateProfileControls(profileControls)
    end)

    local activeText = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    activeText:SetPoint("TOPLEFT", manualLabel, "BOTTOMLEFT", 0, -4)
    activeText:SetText("Perfil activo: "..((LSaber.GetActiveProfileKey and LSaber.GetActiveProfileKey()) or (LightsaberCritDB.activeProfile or "global")))

    local spacer = CreateFrame("Frame", nil, parent)
    spacer:SetSize(1, 1)
    spacer:SetPoint("TOPLEFT", activeText, "BOTTOMLEFT", 0, -6)

    profileControls = {
        profileModeDropdown = modeDropdown,
        profileManualLabel = manualLabel,
        profileManualEdit = manualEdit,
        profileManualButton = manualButton,
        profileActiveText = activeText,
    }
    UpdateProfileControls(profileControls)
    return profileControls, spacer
end

local function RefreshOptionsControls()
    if not LightsaberCritDB then return end
    if optionsControls then
        optionsControls.swing:SetChecked(LightsaberCritDB.swingEnabled)
        optionsControls.combatOnly:SetChecked(LightsaberCritDB.combatOnly)
        optionsControls.autoMute:SetChecked(LightsaberCritDB.autoMute)
        optionsControls.learn:SetChecked(LightsaberCritDB.learn)
        optionsControls.minimap:SetChecked(not LightsaberCritDB.minimap.hide)
        optionsControls.soundVolume:SetValue(LightsaberCritDB.soundVolume or 1.0)
        UpdateSoundVolumeSliderText(optionsControls.soundVolume, optionsControls.soundVolume:GetValue())
        UpdateSoundDropdown(optionsControls.soundDropdown)
        UpdateSoundListDropdown(optionsControls.soundListDropdown)
        UpdateProfileControls(optionsControls.profileControls)
    end
    if configControls then
        configControls.swing:SetChecked(LightsaberCritDB.swingEnabled)
        configControls.combatOnly:SetChecked(LightsaberCritDB.combatOnly)
        configControls.autoMute:SetChecked(LightsaberCritDB.autoMute)
        configControls.learn:SetChecked(LightsaberCritDB.learn)
        configControls.minimap:SetChecked(not LightsaberCritDB.minimap.hide)
        configControls.soundVolume:SetValue(LightsaberCritDB.soundVolume or 1.0)
        UpdateSoundVolumeSliderText(configControls.soundVolume, configControls.soundVolume:GetValue())
        UpdateSoundDropdown(configControls.soundDropdown)
        UpdateSoundListDropdown(configControls.soundListDropdown)
        UpdateProfileControls(configControls.profileControls)
    end
end

local function BuildOptionsControls(parent, anchor)
    local swingCheck = CreateCheckbox(parent, "Reproducir swings", "Sonidos de swing en golpes no crit.")
    swingCheck:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -12)
    swingCheck:SetScript("OnClick", function(self)
        LightsaberCritDB.swingEnabled = self:GetChecked() and true or false
        RefreshOptionsControls()
    end)

    local combatOnlyCheck = CreateCheckbox(parent, "Solo en combate", "Reproduce sonidos solo cuando estas en combate.")
    combatOnlyCheck:SetPoint("TOPLEFT", swingCheck, "BOTTOMLEFT", 0, -8)
    combatOnlyCheck:SetScript("OnClick", function(self)
        LightsaberCritDB.combatOnly = self:GetChecked() and true or false
        RefreshOptionsControls()
    end)

    local autoMuteCheck = CreateCheckbox(parent, "Auto-mute SFX melee", "Silencia SFX melee por defecto alrededor de tus golpes.")
    autoMuteCheck:SetPoint("TOPLEFT", combatOnlyCheck, "BOTTOMLEFT", 0, -8)
    autoMuteCheck:SetScript("OnClick", function(self)
        LightsaberCritDB.autoMute = self:GetChecked() and true or false
        RefreshOptionsControls()
    end)

    local learnCheck = CreateCheckbox(parent, "Learn mode (mensaje en chat)", "Muestra un mensaje cuando el auto-mute se activa.")
    learnCheck:SetPoint("TOPLEFT", autoMuteCheck, "BOTTOMLEFT", 0, -8)
    learnCheck:SetScript("OnClick", function(self)
        LightsaberCritDB.learn = self:GetChecked() and true or false
        RefreshOptionsControls()
    end)

    local minimapCheck = CreateCheckbox(parent, "Mostrar icono en minimapa", "Activa o desactiva el boton del minimapa.")
    minimapCheck:SetPoint("TOPLEFT", learnCheck, "BOTTOMLEFT", 0, -12)
    minimapCheck:SetScript("OnClick", function(self)
        local show = self:GetChecked() and true or false
        LightsaberCritDB.minimap.hide = not show
        SetMinimapButtonVisible(show)
        RefreshMinimapIcon()
        RefreshOptionsControls()
    end)

    local volumeSlider = CreateSlider(parent, "Volumen de sonidos:", 0.10, 1.00, 0.05)
    volumeSlider:SetPoint("TOPLEFT", minimapCheck, "BOTTOMLEFT", 0, -16)
    volumeSlider:SetScript("OnValueChanged", function(self, value)
        local step = 0.05
        local rounded = math.floor((value / step) + 0.5) * step
        LightsaberCritDB.soundVolume = rounded
        UpdateSoundVolumeSliderText(self, rounded)
    end)

    local soundControls = AddSoundTestControls(parent, volumeSlider)
    local profileControls, profileAnchor = AddProfileControls(parent, soundControls.soundListDropdown or soundControls.playButton)

    return {
        swing = swingCheck,
        combatOnly = combatOnlyCheck,
        autoMute = autoMuteCheck,
        learn = learnCheck,
        minimap = minimapCheck,
        soundVolume = volumeSlider,
        soundDropdown = soundControls.dropdown,
        soundListDropdown = soundControls.soundListDropdown,
        profileControls = profileControls,
    }, profileAnchor or soundControls.playButton or minimapCheck
end

local function RegisterOptionsPanel(panel)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, LSaber.AddonName)
        Settings.RegisterAddOnCategory(category)
        panel.category = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

local function EnsureOptionsPanel()
    if optionsPanel then return optionsPanel end
    optionsPanel = CreateFrame("Frame", "LightsaberCritOptionsPanel")
    optionsPanel.name = LSaber.AddonName

    local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("LightsaberCrit")

    local subtitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetText("Configuracion de sonidos y minimapa.")

    local controls, bottomAnchor = BuildOptionsControls(optionsPanel, subtitle)
    optionsControls = controls

    local hint = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", bottomAnchor, "BOTTOMLEFT", 0, -6)
    hint:SetText("Arrastra el icono para moverlo.")

    optionsPanel:SetScript("OnShow", RefreshOptionsControls)
    RegisterOptionsPanel(optionsPanel)
    return optionsPanel
end

local function EnsureConfigFrame()
    if configFrame then return configFrame end

    configFrame = CreateFrame("Frame", "LightsaberCritConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    configFrame:SetSize(320, 480)
    configFrame:SetPoint("CENTER")
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    configFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    if configFrame.TitleText then
        configFrame.TitleText:SetText("LightsaberCrit")
    else
        local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 16, -8)
        title:SetText("LightsaberCrit")
    end

    local close = configFrame.CloseButton
    if not close then
        close = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
        configFrame.CloseButton = close
    end
    close:ClearAllPoints()
    local inset = -4
    close:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -inset, -inset)

    local subtitle = configFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 16, -32)
    subtitle:SetText("Configuracion de sonidos y minimapa.")

    local controls, bottomAnchor = BuildOptionsControls(configFrame, subtitle)
    configControls = controls

    local hint = configFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", bottomAnchor, "BOTTOMLEFT", 0, -6)
    hint:SetText("Arrastra el icono para moverlo.")

    configFrame:SetScript("OnShow", RefreshOptionsControls)
    configFrame:Hide()

    if UISpecialFrames then
        UISpecialFrames[#UISpecialFrames + 1] = "LightsaberCritConfigFrame"
    end

    return configFrame
end

local function OpenConfig()
    local frame = EnsureConfigFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        frame:Raise()
    end
end

LSaber.CreateMinimapButton = CreateMinimapButton
LSaber.SetMinimapButtonVisible = SetMinimapButtonVisible
LSaber.ForceShowMinimapButton = ForceShowMinimapButton
LSaber.RefreshMinimapIcon = RefreshMinimapIcon
LSaber.RefreshOptionsControls = RefreshOptionsControls
LSaber.EnsureOptionsPanel = EnsureOptionsPanel
LSaber.OpenConfig = OpenConfig
