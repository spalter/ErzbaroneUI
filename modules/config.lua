if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Config = {}

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
    configurationFrame:SetSize(320, 310)
    configurationFrame:SetPoint("CENTER")
    configurationFrame:SetMovable(true)
    configurationFrame:EnableMouse(true)
    configurationFrame:RegisterForDrag("LeftButton")
    configurationFrame:SetScript("OnDragStart", configurationFrame.StartMoving)
    configurationFrame:SetScript("OnDragStop", configurationFrame.StopMovingOrSizing)
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

    ErzbaroneUI.Config.Frame = configurationFrame
end

--- Creates the vertical bars settings section in the configuration frame.
function ErzbaroneUI.Config:VerticalBarsSettings(parentFrame)
    local verticalBarsToggle = CreateFrame("CheckButton", "ErzbaroneUIVerticalBarsToggle", parentFrame,
        "UICheckButtonTemplate")
    verticalBarsToggle:SetPoint("TOPLEFT", 15, -30)
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
    chatButtonToggle:SetPoint("TOPLEFT", 15, -60)
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
    improvedUnitFramesToggle:SetPoint("TOPLEFT", 15, -90)
    _G[improvedUnitFramesToggle:GetName() .. "Text"]:SetText("Improved Unit Frames (Requires UI Reload)")
    improvedUnitFramesToggle:SetChecked(ErzbaroneUISettings.improvedUnitFrames)
    improvedUnitFramesToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.improvedUnitFrames = self:GetChecked()
        if ErzbaroneUISettings.improvedUnitFrames then
            ErzbaroneUI.Frames.ActivateImprovedUnitFrames()
        else
            ErzbaroneUI.Frames.DeactivateImprovedUnitFrames()
        end
    end)
end

--- Creates the hide bag names settings section in the configuration frame.
function ErzbaroneUI.Config.HideBagNames(parentFrame)
    local hideBagNamesToggle = CreateFrame("CheckButton", "ErzbaroneUIHideBagNamesToggle", parentFrame,
        "UICheckButtonTemplate")
    hideBagNamesToggle:SetPoint("TOPLEFT", 15, -120)
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
    externalMinimapButtonsToggle:SetPoint("TOPLEFT", 15, -150)
    _G[externalMinimapButtonsToggle:GetName() .. "Text"]:SetText("Hide Minimap Buttons (Requires UI Reload)")
    externalMinimapButtonsToggle:SetChecked(ErzbaroneUISettings.hideExternalMinimapButtons)
    externalMinimapButtonsToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.hideExternalMinimapButtons = self:GetChecked()
        if ErzbaroneUISettings.hideExternalMinimapButtons then
            ReloadUI()
        else
            ReloadUI()
        end
    end)
end

--- Creates the Erzbarone UI flag settings section in the configuration frame.
function ErzbaroneUI.Config:ShowErzbaroneUIFlag(parentFrame)
    local showErzbaroneUIFlagToggle = CreateFrame("CheckButton", "ErzbaroneUIShowFlagToggle", parentFrame,
        "UICheckButtonTemplate")
    showErzbaroneUIFlagToggle:SetPoint("TOPLEFT", 15, -180)
    _G[showErzbaroneUIFlagToggle:GetName() .. "Text"]:SetText("Show Erzbarone UI Flag")
    showErzbaroneUIFlagToggle:SetChecked(ErzbaroneUISettings.showErzbaroneUIFlag)
    showErzbaroneUIFlagToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.showErzbaroneUIFlag = self:GetChecked()
        if ErzbaroneUISettings.showErzbaroneUIFlag then
            ErzbaroneUI.Flag:ShowFlag()
        else
            ErzbaroneUI.Flag:HideFlag()
        end
    end)
end

--- Creates the unit class colors settings section in the configuration frame.
function ErzbaroneUI.Config:ShowUnitClassColors(parentFrame)
    local unitClassColorsToggle = CreateFrame("CheckButton", "ErzbaroneUIUnitClassColorsToggle", parentFrame,
        "UICheckButtonTemplate")
    unitClassColorsToggle:SetPoint("TOPLEFT", 15, -210)
    _G[unitClassColorsToggle:GetName() .. "Text"]:SetText("Use Unit Class Colors")
    unitClassColorsToggle:SetChecked(ErzbaroneUISettings.unitClassColors)
    unitClassColorsToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.unitClassColors = self:GetChecked()
        if ErzbaroneUISettings.unitClassColors then
            ErzbaroneUI.Frames:UpdateBothHealthColors()
        else
            ErzbaroneUI.Frames:SetDefaultHealthBarColor()
        end
    end)
end

function ErzbaroneUI.Config:ShowFiveSecondRuleTimer(parentFrame)
    local fiveSecondRuleToggle = CreateFrame("CheckButton", "ErzbaroneUIFiveSecondRuleToggle", parentFrame,
        "UICheckButtonTemplate")
    fiveSecondRuleToggle:SetPoint("TOPLEFT", 15, -240)
    _G[fiveSecondRuleToggle:GetName() .. "Text"]:SetText("Show Five Second Rule Timer (Requires UI Reload)")
    fiveSecondRuleToggle:SetChecked(ErzbaroneUISettings.fiveSecondRuleTimer)
    fiveSecondRuleToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.fiveSecondRuleTimer = self:GetChecked()
        ReloadUI()
    end)
end

--- Creates the swing timer settings section in the configuration frame.
function ErzbaroneUI.Config:ShowSwingTimer(parentFrame)
    local swingTimerToggle = CreateFrame("CheckButton", "ErzbaroneUISwingTimerToggle", parentFrame,
        "UICheckButtonTemplate")
    swingTimerToggle:SetPoint("TOPLEFT", 15, -270)
    _G[swingTimerToggle:GetName() .. "Text"]:SetText("Show Swing Timer (Requires UI Reload)")
    swingTimerToggle:SetChecked(ErzbaroneUISettings.swingTimer)
    swingTimerToggle:SetScript("OnClick", function(self)
        ErzbaroneUISettings.swingTimer = self:GetChecked()
        ReloadUI()
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
