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

local SOUND_TEST_OPTIONS = {
    { value = "crit", label = "Crit" },
    { value = "proc", label = "Proc" },
    { value = "swing1", label = "Swing 1" },
    { value = "swing2", label = "Swing 2" },
}

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

local function AddSoundTestControls(parent, anchor)
    if type(LightsaberCritDB) ~= "table" then
        LightsaberCritDB = {}
    end
    if LightsaberCritDB.soundTest == nil then
        LightsaberCritDB.soundTest = "crit"
    end

    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -16, -8)
    UIDropDownMenu_SetWidth(dropdown, 120)
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        for _, option in ipairs(SOUND_TEST_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.value = option.value
            info.func = function()
                LightsaberCritDB.soundTest = option.value
                UpdateSoundDropdown(dropdown)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UpdateSoundDropdown(dropdown)

    local playButton = CreateButton(parent, "Reproducir", 90, 22)
    playButton:SetPoint("LEFT", dropdown, "RIGHT", -6, 2)
    playButton:SetScript("OnClick", PlaySelectedSound)

    return {
        dropdown = dropdown,
        playButton = playButton,
    }
end

local function RefreshOptionsControls()
    if not LightsaberCritDB then return end
    if optionsControls then
        optionsControls.swing:SetChecked(LightsaberCritDB.swingEnabled)
        optionsControls.autoMute:SetChecked(LightsaberCritDB.autoMute)
        optionsControls.learn:SetChecked(LightsaberCritDB.learn)
        optionsControls.minimap:SetChecked(not LightsaberCritDB.minimap.hide)
        UpdateSoundDropdown(optionsControls.soundDropdown)
    end
    if configControls then
        configControls.swing:SetChecked(LightsaberCritDB.swingEnabled)
        configControls.autoMute:SetChecked(LightsaberCritDB.autoMute)
        configControls.learn:SetChecked(LightsaberCritDB.learn)
        configControls.minimap:SetChecked(not LightsaberCritDB.minimap.hide)
        UpdateSoundDropdown(configControls.soundDropdown)
    end
end

local function BuildOptionsControls(parent, anchor)
    local swingCheck = CreateCheckbox(parent, "Reproducir swings", "Sonidos de swing en golpes no crit.")
    swingCheck:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -12)
    swingCheck:SetScript("OnClick", function(self)
        LightsaberCritDB.swingEnabled = self:GetChecked() and true or false
        RefreshOptionsControls()
    end)

    local autoMuteCheck = CreateCheckbox(parent, "Auto-mute SFX melee", "Silencia SFX melee por defecto alrededor de tus golpes.")
    autoMuteCheck:SetPoint("TOPLEFT", swingCheck, "BOTTOMLEFT", 0, -8)
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

    local soundControls = AddSoundTestControls(parent, minimapCheck)

    return {
        swing = swingCheck,
        autoMute = autoMuteCheck,
        learn = learnCheck,
        minimap = minimapCheck,
        soundDropdown = soundControls.dropdown,
    }, (soundControls and soundControls.playButton) or minimapCheck
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
    configFrame:SetSize(320, 240)
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
