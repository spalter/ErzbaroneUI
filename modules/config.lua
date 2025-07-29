if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Config = {}
ErzbaroneUI.Config.FrameSettings = { width = 340, height = 300, offsetX = 15 }

local defaults = {
    improvedActionBars = true,
    hideChatButtons = true,
    improvedUnitFrames = true,
    hideBagNames = true,
    hideExternalMinimapButtons = true,
    showErzbaroneUIFlag = true,
    unitClassColors = true,
    fiveSecondRuleTimer = true,
    swingTimer = true,
    targetCastbar = true,
    vignette = false,
    autoSellGreyItems = true,
    autoRepair = true,
    hideVerticalBars = true,
    rangeCheckBars = true,
}

--- Initializes the configuration settings for ErzbaroneUI.
function ErzbaroneUI.Config:Initialize()
    -- Ensure ErzbaroneUISettings is initialized
    ErzbaroneUISettings = ErzbaroneUISettings or {}
    for key, value in pairs(defaults) do
        if ErzbaroneUISettings[key] == nil then
            ErzbaroneUISettings[key] = value
        end
    end

    ErzbaroneUI.Config:Setup()
end

--- Reloads the UI to apply changes made in the configuration.
function ErzbaroneUI.Config:Reload()
    ReloadUI()
end

--- Sets up the initial configuration for ErzbaroneUI.
function ErzbaroneUI.Config:Setup()
    TARGET_FRAME_BUFFS_ON_TOP = true
    SetCVar("cameraDistanceMaxZoomFactor", "4.0")
end

--- Sets the font for damage text in the game.
function ErzbaroneUI.Config:SetDamageFont()
    DAMAGE_TEXT_FONT = "Fonts\\skurri.TTF"
    COMBAT_TEXT_FONT = "Fonts\\skurri.TTF"
    SetCVar("WorldTextScale", tostring(0.75))
end

--- Creates the configuration frame for ErzbaroneUI.
--- This function creates a frame that will be used to toggle various module settings.
function ErzbaroneUI.Config:CreateFrame()
    local configurationFrame = CreateFrame("Frame", "ErzbaroneUIConfigFrame", UIParent, "BasicFrameTemplate")
    configurationFrame:SetSize(ErzbaroneUI.Config.FrameSettings.width, ErzbaroneUI.Config.FrameSettings.height)
    configurationFrame:SetPoint("CENTER")
    configurationFrame:SetMovable(true)
    configurationFrame:EnableMouse(true)
    configurationFrame:RegisterForDrag("LeftButton")
    configurationFrame:SetScript("OnDragStart", configurationFrame.StartMoving)
    configurationFrame:SetScript("OnDragStop", configurationFrame.StopMovingOrSizing)
    configurationFrame:SetScript("OnKeyDown", function(self, key) if key == "ESCAPE" then self:Hide() end end)
    configurationFrame:SetScript("OnShow", function() PlaySound(ErzbaroneUI.Static.OpenSoundID) end)
    configurationFrame:SetScript("OnHide", function() PlaySound(ErzbaroneUI.Static.CloseSoundID) end)
    configurationFrame:SetToplevel(true)
    configurationFrame:Hide()

    configurationFrame.title = configurationFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    configurationFrame.title:SetPoint("TOP", 0, -6)
    configurationFrame.title:SetText("Erzbarone UI")

    local generalSettings = CreateFrame("Frame", nil, configurationFrame)
    generalSettings:SetAllPoints()
    local unitFramesSettings = CreateFrame("Frame", nil, configurationFrame)
    unitFramesSettings:SetAllPoints()
    local actionBarsSettings = CreateFrame("Frame", nil, configurationFrame)
    actionBarsSettings:SetAllPoints()

    configurationFrame.tab_content = { generalSettings, unitFramesSettings, actionBarsSettings }

    local tabs = {}
    local tabNames = { "General", "Unit Frames", "Action Bars" }

    local function SelectTab(tabIndex)
        PlaySound(ErzbaroneUI.Static.LightClickSoundID)
        for i, contentFrame in ipairs(configurationFrame.tab_content) do
            if i == tabIndex then
                contentFrame:Show()
                tabs[i]:Disable()
            else
                contentFrame:Hide()
                tabs[i]:Enable()
            end
        end
    end

    for i, name in ipairs(tabNames) do
        local tab = CreateFrame("Button", "ErzbaroneUIConfigTab" .. i, configurationFrame, "UIPanelButtonTemplate")
        tab:SetText(name)
        tab:SetWidth(100)
        tab:SetHeight(22)
        if i == 1 then
            tab:SetPoint("TOPLEFT", 12, -38)
        else
            tab:SetPoint("LEFT", tabs[i - 1], "RIGHT", 4, 0)
        end
        tab:SetScript("OnClick", function() SelectTab(i) end)
        table.insert(tabs, tab)
    end

    ErzbaroneUI.Config:ChatButtonSettings(generalSettings)
    ErzbaroneUI.Config.HideBagNames(generalSettings)
    ErzbaroneUI.Config:HandleExternalMinimapButtons(generalSettings)
    ErzbaroneUI.Config:ShowErzbaroneUIFlag(generalSettings)
    ErzbaroneUI.Config:ShowVignette(generalSettings)
    ErzbaroneUI.Config:ShowAutoSellItems(generalSettings)
    ErzbaroneUI.Config:ShowAutoRepair(generalSettings)

    ErzbaroneUI.Config:ImprovedUnitFrames(unitFramesSettings)
    ErzbaroneUI.Config:ShowUnitClassColors(unitFramesSettings)
    ErzbaroneUI.Config:ShowFiveSecondRuleTimer(unitFramesSettings)
    ErzbaroneUI.Config:ShowTargetCastbar(unitFramesSettings)
    ErzbaroneUI.Config:ShowSwingTimer(unitFramesSettings)

    ErzbaroneUI.Config:VerticalBarsSettings(actionBarsSettings)
    ErzbaroneUI.Config:ShowVerticalBarsSettings(actionBarsSettings)
    ErzbaroneUI.Config:ShowRangeCheckBarsSettings(actionBarsSettings)

    SelectTab(1)

    ErzbaroneUI.Config.Frame = configurationFrame
end

--- Creates the vertical bars settings section in the configuration frame.
function ErzbaroneUI.Config:VerticalBarsSettings(parentFrame)
    local verticalBarsToggle = CreateFrame("CheckButton", "ErzbaroneUIVerticalBarsToggle", parentFrame,
        "UICheckButtonTemplate")
    verticalBarsToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -70)
    _G[verticalBarsToggle:GetName() .. "Text"]:SetText("Improved Action Bars")
    verticalBarsToggle:SetChecked(ErzbaroneUISettings.improvedActionBars)
    verticalBarsToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.improvedActionBars = self:GetChecked()
        ErzbaroneUI.Config:Reload()
    end)
end

--- Creates the chat button settings section in the configuration frame.
function ErzbaroneUI.Config:ChatButtonSettings(parentFrame)
    local chatButtonToggle = CreateFrame("CheckButton", "ErzbaroneUIChatButtonToggle", parentFrame,
        "UICheckButtonTemplate")
    chatButtonToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -70)
    _G[chatButtonToggle:GetName() .. "Text"]:SetText("Hide Chat Buttons")
    chatButtonToggle:SetChecked(ErzbaroneUISettings.hideChatButtons)
    chatButtonToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.hideChatButtons = self:GetChecked()
        if ErzbaroneUISettings.hideChatButtons then
            ErzbaroneUI.Chat:HideChatButtons()
        else
            ErzbaroneUI.Chat:ShowChatButtons()
        end
    end)
end

--- Creates the improved unit frames settings section in the configuration frame.
function ErzbaroneUI.Config:ImprovedUnitFrames(parentFrame)
    local improvedUnitFramesToggle = CreateFrame("CheckButton", "ErzbaroneUIImprovedUnitFramesToggle", parentFrame,
        "UICheckButtonTemplate")
    improvedUnitFramesToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -70)
    _G[improvedUnitFramesToggle:GetName() .. "Text"]:SetText("Improved Unit Frames")
    improvedUnitFramesToggle:SetChecked(ErzbaroneUISettings.improvedUnitFrames)
    improvedUnitFramesToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.improvedUnitFrames = self:GetChecked()
        if ErzbaroneUISettings.improvedUnitFrames then
            ErzbaroneUI.UnitFrames.ActivateImprovedUnitFrames()
        else
            ErzbaroneUI.UnitFrames.DeactivateImprovedUnitFrames()
        end
    end)
end

--- Creates the hide bag names settings section in the configuration frame.
function ErzbaroneUI.Config.HideBagNames(parentFrame)
    local hideBagNamesToggle = CreateFrame("CheckButton", "ErzbaroneUIHideBagNamesToggle", parentFrame,
        "UICheckButtonTemplate")
    hideBagNamesToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -100)
    _G[hideBagNamesToggle:GetName() .. "Text"]:SetText("Hide Bag Names")
    hideBagNamesToggle:SetChecked(ErzbaroneUISettings.hideBagNames)
    hideBagNamesToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.hideBagNames = self:GetChecked()
        if ErzbaroneUISettings.hideBagNames then
            ErzbaroneUI.Bags:HideBagNames()
        else
            ErzbaroneUI.Bags:ShowBagNames()
        end
    end)
end

--- Creates the external minimap buttons settings section in the configuration frame.
function ErzbaroneUI.Config:HandleExternalMinimapButtons(parentFrame)
    local externalMinimapButtonsToggle = CreateFrame("CheckButton", "ErzbaroneUIExternalMinimapButtonsToggle",
        parentFrame,
        "UICheckButtonTemplate")
    externalMinimapButtonsToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -130)
    _G[externalMinimapButtonsToggle:GetName() .. "Text"]:SetText("Hide Minimap Buttons")
    externalMinimapButtonsToggle:SetChecked(ErzbaroneUISettings.hideExternalMinimapButtons)
    externalMinimapButtonsToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.hideExternalMinimapButtons = self:GetChecked()
        ErzbaroneUI.Config:Reload()
    end)
end

--- Creates the Erzbarone UI flag settings section in the configuration frame.
function ErzbaroneUI.Config:ShowErzbaroneUIFlag(parentFrame)
    local showErzbaroneUIFlagToggle = CreateFrame("CheckButton", "ErzbaroneUIShowFlagToggle", parentFrame,
        "UICheckButtonTemplate")
    showErzbaroneUIFlagToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -160)
    _G[showErzbaroneUIFlagToggle:GetName() .. "Text"]:SetText("Show Erzbarone UI Flag")
    showErzbaroneUIFlagToggle:SetChecked(ErzbaroneUISettings.showErzbaroneUIFlag)
    showErzbaroneUIFlagToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.showErzbaroneUIFlag = self:GetChecked()
        ErzbaroneUI.Config:Reload()
    end)
end

--- Creates the unit class colors settings section in the configuration frame.
function ErzbaroneUI.Config:ShowUnitClassColors(parentFrame)
    local unitClassColorsToggle = CreateFrame("CheckButton", "ErzbaroneUIUnitClassColorsToggle", parentFrame,
        "UICheckButtonTemplate")
    unitClassColorsToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -100)
    _G[unitClassColorsToggle:GetName() .. "Text"]:SetText("Use Unit Class Colors")
    unitClassColorsToggle:SetChecked(ErzbaroneUISettings.unitClassColors)
    unitClassColorsToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.unitClassColors = self:GetChecked()
        if ErzbaroneUISettings.unitClassColors then
            ErzbaroneUI.UnitFrames:UpdateBothHealthColors()
        else
            ErzbaroneUI.UnitFrames:SetDefaultHealthBarColor()
        end
    end)
end

--- Creates the five second rule timer settings section in the configuration frame.
function ErzbaroneUI.Config:ShowFiveSecondRuleTimer(parentFrame)
    local fiveSecondRuleToggle = CreateFrame("CheckButton", "ErzbaroneUIFiveSecondRuleToggle", parentFrame,
        "UICheckButtonTemplate")
    fiveSecondRuleToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -130)
    _G[fiveSecondRuleToggle:GetName() .. "Text"]:SetText("Show Five Second Rule Timer")
    fiveSecondRuleToggle:SetChecked(ErzbaroneUISettings.fiveSecondRuleTimer)
    fiveSecondRuleToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.fiveSecondRuleTimer = self:GetChecked()
        ErzbaroneUI.Config:Reload()
    end)
end

--- Creates the swing timer settings section in the configuration frame.
function ErzbaroneUI.Config:ShowSwingTimer(parentFrame)
    local swingTimerToggle = CreateFrame("CheckButton", "ErzbaroneUISwingTimerToggle", parentFrame,
        "UICheckButtonTemplate")
    swingTimerToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -190)
    _G[swingTimerToggle:GetName() .. "Text"]:SetText("Show Swing Timer")
    swingTimerToggle:SetChecked(ErzbaroneUISettings.swingTimer)
    swingTimerToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.swingTimer = self:GetChecked()
        ErzbaroneUI.Config:Reload()
    end)
end

--- Creates the target castbar settings section in the configuration frame.
function ErzbaroneUI.Config:ShowTargetCastbar(parentFrame)
    local targetCastbarToggle = CreateFrame("CheckButton", "ErzbaroneUITargetCastbarToggle", parentFrame,
        "UICheckButtonTemplate")
    targetCastbarToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -160)
    _G[targetCastbarToggle:GetName() .. "Text"]:SetText("Show Target Castbar")
    targetCastbarToggle:SetChecked(ErzbaroneUISettings.targetCastbar)
    targetCastbarToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.targetCastbar = self:GetChecked()
        ErzbaroneUI.Config:Reload()
    end)
end

--- Creates the vignette effect toggle in the configuration frame.
function ErzbaroneUI.Config:ShowVignette(parentFrame)
    local vignetteToggle = CreateFrame("CheckButton", "ErzbaroneUIVignetteToggle", parentFrame,
        "UICheckButtonTemplate")
    vignetteToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -190)
    _G[vignetteToggle:GetName() .. "Text"]:SetText("Show Vignette Effect")
    vignetteToggle:SetChecked(ErzbaroneUISettings.vignette)
    vignetteToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.vignette = self:GetChecked()
        if ErzbaroneUISettings.vignette then
            ErzbaroneUI.Effects:ActivateVignette()
        else
            ErzbaroneUI.Effects:DeactivateVignette()
        end
    end)
end

--- Creates the auto sell grey items settings section in the configuration frame.
function ErzbaroneUI.Config:ShowAutoSellItems(parentFrame)
    local autoSellToggle = CreateFrame("CheckButton", "ErzbaroneUIAutoSellToggle", parentFrame,
        "UICheckButtonTemplate")
    autoSellToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -220)
    _G[autoSellToggle:GetName() .. "Text"]:SetText("Auto Sell Grey Items")
    autoSellToggle:SetChecked(ErzbaroneUISettings.autoSellGreyItems)
    autoSellToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.autoSellGreyItems = self:GetChecked()
    end)
end

--- Creates the auto repair settings section in the configuration frame.
function ErzbaroneUI.Config:ShowAutoRepair(parentFrame)
    local autoRepairToggle = CreateFrame("CheckButton", "ErzbaroneUIAutoRepairToggle", parentFrame,
        "UICheckButtonTemplate")
    autoRepairToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -250)
    _G[autoRepairToggle:GetName() .. "Text"]:SetText("Auto Repair Items")
    autoRepairToggle:SetChecked(ErzbaroneUISettings.autoRepair)
    autoRepairToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.autoRepair = self:GetChecked()
    end)
end

-- Creates the vertical bars settings section in the configuration frame.
function ErzbaroneUI.Config:ShowVerticalBarsSettings(parentFrame)
    local hideVerticalBarsToggle = CreateFrame("CheckButton", "ErzbaroneUIHideVerticalBarsToggle", parentFrame,
        "UICheckButtonTemplate")
    hideVerticalBarsToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -100)
    _G[hideVerticalBarsToggle:GetName() .. "Text"]:SetText("Hide Vertical Bars")
    hideVerticalBarsToggle:SetChecked(ErzbaroneUISettings.hideVerticalBars)
    hideVerticalBarsToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.hideVerticalBars = self:GetChecked()
        ErzbaroneUI.Config:Reload()
    end)
end

-- Creates the range check bars settings section in the configuration frame.
function ErzbaroneUI.Config:ShowRangeCheckBarsSettings(parentFrame)
    local rangeCheckBarsToggle = CreateFrame("CheckButton", "ErzbaroneUIRangeCheckBarsToggle", parentFrame,
        "UICheckButtonTemplate")
    rangeCheckBarsToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -130)
    _G[rangeCheckBarsToggle:GetName() .. "Text"]:SetText("Enable Range Check on Action Bars")
    rangeCheckBarsToggle:SetChecked(ErzbaroneUISettings.rangeCheckBars)
    rangeCheckBarsToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.rangeCheckBars = self:GetChecked()
        ErzbaroneUI.Config:Reload()
    end)
end

--- Toggles the visibility of the configuration frame.
function ErzbaroneUI.Config:ToggleFrame()
    if not ErzbaroneUI.Config.Frame then
        ErzbaroneUI.Config:CreateFrame()
    end

    if ErzbaroneUI.Config.Frame:IsShown() then
        ErzbaroneUI.Config.Frame:Hide()
    else
        ErzbaroneUI.Config.Frame:Show()
    end
end
