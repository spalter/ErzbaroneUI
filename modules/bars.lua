if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Bars = {}
ErzbaroneUI.Bars.Static = {
    mainBarTexture = "Interface\\AddOns\\ErzbaroneUI\\textures\\mainbar",
    bagbarTexture = "Interface\\AddOns\\ErzbaroneUI\\textures\\bagbar",
    actionBarButtonNames = {
        "ActionButton",
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
    },
}

-- Initializes the bar modifications.
function ErzbaroneUI.Bars:Initialize()
    if ErzbaroneUISettings and ErzbaroneUISettings.improvedActionBars then
        ErzbaroneUI.Bars:HideVerticalBars()
        ErzbaroneUI.Bars:ImproveActionBar()
    else
        ErzbaroneUI.Bars:ShowVerticalBars()
    end
end

-- Sets up mouseover functionality for the vertical bars (MultiBarRight and MultiBarLeft).
-- This function hides the bars by default and shows them when the mouse hovers over them.
function ErzbaroneUI.Bars:HideVerticalBars()
    local bars = { MultiBarRight, MultiBarLeft }

    for _, bar in pairs(bars) do
        if bar then
            bar:SetAlpha(0)

            bar:SetScript("OnEnter", function(self)
                MultiBarRight:SetAlpha(1)
                MultiBarLeft:SetAlpha(1)
            end)

            bar:SetScript("OnLeave", function(self)
                MultiBarRight:SetAlpha(0)
                MultiBarLeft:SetAlpha(0)
            end)
        end
    end

    local barNames = { "MultiBarRight", "MultiBarLeft" }
    for _, barName in pairs(barNames) do
        for i = 1, 12 do
            local button = _G[barName .. "Button" .. i]
            if button then
                button:SetScript("OnEnter", function(self)
                    MultiBarRight:SetAlpha(1)
                    MultiBarLeft:SetAlpha(1)
                end)
                button:SetScript("OnLeave", function(self)
                    MultiBarRight:SetAlpha(0)
                    MultiBarLeft:SetAlpha(0)
                end)
            end
        end
    end
end

-- Shows the vertical bars (MultiBarRight and MultiBarLeft) without mouseover functionality.
function ErzbaroneUI.Bars:ShowVerticalBars()
    local bars = { MultiBarRight, MultiBarLeft }

    for _, bar in pairs(bars) do
        if bar then
            bar:SetAlpha(1)
            bar:SetScript("OnEnter", nil)
            bar:SetScript("OnLeave", nil)
        end
    end

    local barNames = { "MultiBarRight", "MultiBarLeft" }
    for _, barName in pairs(barNames) do
        for i = 1, 12 do
            local button = _G[barName .. "Button" .. i]
            if button then
                button:SetScript("OnEnter", nil)
                button:SetScript("OnLeave", nil)
            end
        end
    end
end

-- Improves the main action bar layout and appearance.
function ErzbaroneUI.Bars:ImproveActionBar()
    local improvedActionBarFrame = CreateFrame("Frame", "ErzbaroneUIImprovedActionBar", UIParent,
        "SecureHandlerStateTemplate")
    improvedActionBarFrame:SetFrameStrata("BACKGROUND")
    improvedActionBarFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
    improvedActionBarFrame:SetSize(1024, 128)
    improvedActionBarFrame.texture = improvedActionBarFrame:CreateTexture(nil, "BACKGROUND")
    improvedActionBarFrame.texture:SetAllPoints()
    improvedActionBarFrame.texture:SetTexture(ErzbaroneUI.Bars.Static.mainBarTexture)

    local xpBar = _G["MainMenuExpBar"]
    if xpBar then
        xpBar:SetParent(improvedActionBarFrame)
        xpBar:ClearAllPoints()
        xpBar:SetFrameStrata("BACKGROUND")
        xpBar:SetFrameLevel(0)
        xpBar:SetPoint("CENTER", improvedActionBarFrame, "CENTER", 0, -16)
        xpBar:SetSize(800, 8)

        local barRegions = {
            xpBar:GetRegions()
        }
        for _, region in ipairs(barRegions) do
            if region:GetObjectType() == "Texture" then
                -- Hides the end caps and other border textures
                if region:GetName() ~= "ExhaustionLevelFillBar" and region:GetName() ~= nil then
                    region:SetTexture(nil)
                end
            end
        end

        xpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    end

    local mainBar = _G["MainMenuBar"]
    mainBar:ClearAllPoints()
    mainBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 110, 0)

    local bottomLeftBar = _G["MultiBarBottomLeft"]
    bottomLeftBar:ClearAllPoints()
    bottomLeftBar:SetPoint("BOTTOM", mainBar, "TOP", -254, 4)

    local bottomRightBar = _G["MultiBarBottomRight"]
    bottomRightBar:ClearAllPoints()
    bottomRightBar:SetPoint("LEFT", bottomLeftBar, "RIGHT", 44, -2)
    ErzbaroneUI.Bars:ArrangeBottomRightBar(bottomRightBar)

    local artFrame = _G["MainMenuBarArtFrame"]
    if artFrame then
        for _, region in ipairs({ artFrame:GetRegions() }) do
            if region:GetObjectType() == "Texture" then
                region:SetAlpha(0)
            end
        end
    end

    if _G["MainMenuBarPerformanceBarFrame"] then
        _G["MainMenuBarPerformanceBarFrame"]:Hide()
    end
    if _G["MainMenuBarLeftEndCap"] then
        _G["MainMenuBarLeftEndCap"]:Hide()
    end
    if _G["MainMenuBarRightEndCap"] then
        _G["MainMenuBarRightEndCap"]:Hide()
    end

    ErzbaroneUI.Bars:RepositionBagButtons()
    ErzbaroneUI.Bars:RepositionMicroButtons()
end

--- Repositions the bag and keyring buttons to the bottom right corner.
function ErzbaroneUI.Bars:RepositionBagButtons()
    local previousButton = nil

    local bagBarBackground = CreateFrame("Frame", "ErzbaroneUIBagBarBackground", UIParent)
    bagBarBackground:SetFrameStrata("BACKGROUND")
    bagBarBackground:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
    bagBarBackground:SetSize(256, 64)
    bagBarBackground.texture = bagBarBackground:CreateTexture(nil, "BACKGROUND")
    bagBarBackground.texture:SetAllPoints()
    bagBarBackground.texture:SetTexture(ErzbaroneUI.Bars.Static.bagbarTexture)

    local backpackButton = _G["MainMenuBarBackpackButton"]
    if backpackButton then
        backpackButton:SetParent(UIParent)
        backpackButton:ClearAllPoints()
        backpackButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -6, 5)
    end

    local otherButtons = {
        _G["CharacterBag0Slot"],
        _G["CharacterBag1Slot"],
        _G["CharacterBag2Slot"],
        _G["CharacterBag3Slot"],
        _G["KeyRingButton"],
    }

    local backpackButtonSpacing = 6

    for i, button in ipairs(otherButtons) do
        if button then
            button:SetParent(UIParent)
            button:ClearAllPoints()

            if i == 1 then
                button:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -66, 6)
            elseif previousButton then
                button:SetPoint("RIGHT", previousButton, "LEFT", -backpackButtonSpacing, 0)
            end

            button:SetScale(0.75)
            previousButton = button
        end
    end
end

--- Repositions and sets up mouseover for the micro buttons.
function ErzbaroneUI.Bars:RepositionMicroButtons()
    local microButtons = {
        _G["CharacterMicroButton"],
        _G["SpellbookMicroButton"],
        _G["TalentMicroButton"],
        _G["QuestLogMicroButton"],
        _G["SocialsMicroButton"],
        _G["WorldMapMicroButton"],
        _G["MainMenuMicroButton"],
        _G["HelpMicroButton"],
    }

    local container = CreateFrame("Frame", "ErzbaroneUIMicroButtonContainer", UIParent)
    container:SetSize(180, 40) -- Adjust size as needed
    container:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -190, 8)
    container:SetFrameStrata("MEDIUM")

    local previousButton = nil
    local buttonSpacing = -2

    for i, button in ipairs(microButtons) do
        if button then
            button:SetParent(container)
            button:ClearAllPoints()

            if i == 1 then
                button:SetPoint("LEFT", container, "LEFT", 0, 0)
            else
                button:SetPoint("LEFT", previousButton, "RIGHT", buttonSpacing, 0)
            end
            button:SetScale(0.8)
            previousButton = button

            button:SetScript("OnEnter", function(self)
                container:SetAlpha(1)
            end)
            button:SetScript("OnLeave", function(self)
                container:SetAlpha(0)
            end)
        end
    end

    container:SetAlpha(0)

    container:SetScript("OnEnter", function(self)
        self:SetAlpha(1)
    end)

    container:SetScript("OnLeave", function(self)
        self:SetAlpha(0)
    end)
end

--- Arranges the buttons of the bottom-right action bar into a 2x6 grid.
function ErzbaroneUI.Bars:ArrangeBottomRightBar(barFrame)
    if not barFrame then return end

    local buttonSpacing = 6 -- The space between buttons
    for i = 1, 12 do
        local button = _G["MultiBarBottomRightButton" .. i]
        if button then
            button:ClearAllPoints()

            if i <= 6 then
                if i == 1 then
                    button:SetPoint("TOPLEFT", barFrame, "TOPLEFT", 0, 0)
                else
                    local previousButton = _G["MultiBarBottomRightButton" .. (i - 1)]
                    button:SetPoint("LEFT", previousButton, "RIGHT", buttonSpacing, 0)
                end
            else
                local buttonAbove = _G["MultiBarBottomRightButton" .. (i - 6)]
                if i == 7 then
                    button:SetPoint("TOPLEFT", buttonAbove, "BOTTOMLEFT", 0, -18)
                else
                    local previousButton = _G["MultiBarBottomRightButton" .. (i - 1)]
                    button:SetPoint("LEFT", previousButton, "RIGHT", buttonSpacing, 0)
                end
            end
        end
    end
end
