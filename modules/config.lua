if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Config = {}
ErzbaroneUI.Config.FrameSettings = { width = 320, height = 340, offsetX = 15 }

local defaults = {
    hideVerticalBars = true,
    hideChatButtons = true,
    improvedUnitFrames = true,
    hideBagNames = true,
    hideExternalMinimapButtons = true,
    showErzbaroneUIFlag = true,
    unitClassColors = true,
    fiveSecondRuleTimer = true,
    swingTimer = true,
    targetCastbar = true,
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
    configurationFrame.title:SetPoint("TOPLEFT", configurationFrame.TitleBg, "TOPLEFT", 5, -3)
    configurationFrame.title:SetText("Erzbarone UI")
    ErzbaroneUI.Config:VerticalBarsSettings(configurationFrame)
    ErzbaroneUI.Config:ChatButtonSettings(configurationFrame)
    ErzbaroneUI.Config:ImprovedUnitFrames(configurationFrame)
    ErzbaroneUI.Config.HideBagNames(configurationFrame)
    ErzbaroneUI.Config:HandleExternalMinimapButtons(configurationFrame)
    ErzbaroneUI.Config:ShowErzbaroneUIFlag(configurationFrame)
    ErzbaroneUI.Config:ShowUnitClassColors(configurationFrame)
    ErzbaroneUI.Config:ShowFiveSecondRuleTimer(configurationFrame)
    ErzbaroneUI.Config:ShowSwingTimer(configurationFrame)
    ErzbaroneUI.Config:ShowTargetCastbar(configurationFrame)

    ErzbaroneUI.Config.Frame = configurationFrame
end

--- Creates the vertical bars settings section in the configuration frame.
function ErzbaroneUI.Config:VerticalBarsSettings(parentFrame)
    local verticalBarsToggle = CreateFrame("CheckButton", "ErzbaroneUIVerticalBarsToggle", parentFrame,
        "UICheckButtonTemplate")
    verticalBarsToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -30)
    _G[verticalBarsToggle:GetName() .. "Text"]:SetText("Hide Vertical Bars")
    verticalBarsToggle:SetChecked(ErzbaroneUISettings.hideVerticalBars)
    verticalBarsToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.hideVerticalBars = self:GetChecked()
        if ErzbaroneUISettings.hideVerticalBars then
            ErzbaroneUI.Bars:HideVerticalBars()
        else
            ErzbaroneUI.Bars:ShowVerticalBars()
        end
    end)
end

--- Creates the chat button settings section in the configuration frame.
function ErzbaroneUI.Config:ChatButtonSettings(parentFrame)
    local chatButtonToggle = CreateFrame("CheckButton", "ErzbaroneUIChatButtonToggle", parentFrame,
        "UICheckButtonTemplate")
    chatButtonToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -60)
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
    improvedUnitFramesToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -90)
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
    hideBagNamesToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -120)
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
    externalMinimapButtonsToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -150)
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
    showErzbaroneUIFlagToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -180)
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
    unitClassColorsToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -210)
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
    fiveSecondRuleToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -240)
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
    swingTimerToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -270)
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
    targetCastbarToggle:SetPoint("TOPLEFT", ErzbaroneUI.Config.FrameSettings.offsetX, -300)
    _G[targetCastbarToggle:GetName() .. "Text"]:SetText("Show Target Castbar")
    targetCastbarToggle:SetChecked(ErzbaroneUISettings.targetCastbar)
    targetCastbarToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.targetCastbar = self:GetChecked()
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
