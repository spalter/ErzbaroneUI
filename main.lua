-- Erzbarone main file

-- Wrapper to set the World Text Scale
local function setWorldTextScale(value)
    SetCVar("WorldTextScale", tostring(value))
end

-- Setup chat buttons mouseover
local function setupChatButtonsMouseover()
    local buttons = {
        ChatFrameChannelButton,
        FriendsMicroButton,
        ChatFrameMenuButton,
        ChatFrame1ButtonFrameUpButton,
        ChatFrame1ButtonFrameDownButton,
        ChatFrame1ButtonFrameBottomButton,
    }

    for _, btn in ipairs(buttons) do
        if btn then btn:SetAlpha(0) end
    end

    local anchor = ChatFrame1ButtonFrame
    anchor:EnableMouse(true)
    anchor:SetScript("OnEnter", function()
        for _, btn in ipairs(buttons) do if btn then btn:SetAlpha(1) end end
    end)
    anchor:SetScript("OnLeave", function()
        for _, btn in ipairs(buttons) do if btn then btn:SetAlpha(0) end end
    end)

    for _, btn in ipairs(buttons) do
        if btn then
            btn:EnableMouse(true)
            btn:SetScript("OnEnter", function()
                for _, b in ipairs(buttons) do if b then b:SetAlpha(1) end end
            end)
            btn:SetScript("OnLeave", function()
                for _, b in ipairs(buttons) do if b then b:SetAlpha(0) end end
            end)
        end
    end
end

-- move world map to center
local function moveWorldMapToCenter()
    if WorldMapScreenAnchor then
        WorldMapScreenAnchor:ClearAllPoints()
        WorldMapScreenAnchor:SetPoint("CENTER", UIParent, "CENTER", -306, 280)
    end
end

-- Hide the names of the bags
local function hideBagsName()
    ContainerFrame1Name:Hide()
    ContainerFrame2Name:Hide()
    ContainerFrame3Name:Hide()
    ContainerFrame4Name:Hide()
    ContainerFrame5Name:Hide()
    ContainerFrame6Name:Hide()
    ContainerFrame7Name:Hide()
    ContainerFrame8Name:Hide()
    ContainerFrame9Name:Hide()
    ContainerFrame10Name:Hide()
    ContainerFrame11Name:Hide()
end

-- Update the player frame health bar color based on the player's class
local function updatePlayerFrameHealthBarColor()
    local _, playerClass = UnitClass("player")
    local color = RAID_CLASS_COLORS[playerClass]

    if PlayerFrameHealthBar then
        PlayerFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b)
    end
end

-- Update the target frame health bar color based on the target's class
local function updateTargetFrameHealthBarColor()
    local _, targetClass = UnitClass("target")
    local color = RAID_CLASS_COLORS[targetClass]

    if TargetFrameHealthBar then
        TargetFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b)
    end
end

-- Replace default PlayerFrame with a custom player frame texture
local function replacePlayerFrameWithTexture()
    if PlayerFrameTexture then
        PlayerFrameTexture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame")
    end

    if PlayerFrameHealthBar then
        PlayerFrameHealthBar:ClearAllPoints()
        C_Timer.After(0.1, function()
            PlayerFrameHealthBar:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 106, -22)
            PlayerFrameHealthBar:SetHeight(30)
            PlayerFrameHealthBarText:ClearAllPoints()
            PlayerFrameHealthBarText:SetPoint("CENTER", PlayerFrameHealthBar, "CENTER", 0, -6)
            updatePlayerFrameHealthBarColor()
        end)

        PlayerFrameHealthBar:HookScript("OnValueChanged", function(self, value)
            updatePlayerFrameHealthBarColor()
        end)
    end


    if PlayerStatusTexture then
        PlayerStatusTexture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\UI-Player-Status")
    end
end

-- Replace default TargetFrame with a custom target frame texture
local function replaceTargetFrameWithTexture()
    if TargetFrame then
        local classification = UnitClassification("target")

        if classification == "elite" then
            TargetFrameTextureFrameTexture:SetTexture(
            "Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame-Elite")
        elseif classification == "rareelite" then
            TargetFrameTextureFrameTexture:SetTexture(
            "Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame-RareElite")
        elseif classification == "rare" then
            TargetFrameTextureFrameTexture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame-Rare")
        elseif classification == "worldboss" then
            TargetFrameTextureFrameTexture:SetTexture(
            "Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame-WorldBoss")
        else
            TargetFrameTextureFrameTexture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame")
        end

        TargetFrameNameBackground:SetAlpha(0)

        if TargetFrameBackground then
            TargetFrameBackground:SetHeight(42)
        end

        if TargetFrameHealthBar then
            TargetFrameHealthBar:ClearAllPoints()
            TargetFrameHealthBar:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", 6, -22)
            TargetFrameHealthBar:SetHeight(30)
            if TargetFrameHealthBarText then
                TargetFrameHealthBarText:ClearAllPoints()
                TargetFrameHealthBarText:SetPoint("CENTER", TargetFrameHealthBar, "CENTER", 0, -6)
            end
            updateTargetFrameHealthBarColor()

            TargetFrameHealthBar:HookScript("OnValueChanged", function(self, value)
                updateTargetFrameHealthBarColor()
            end)
        end
    end
end

-- Move unit frames to the bottom of the screen
local function moveUnitFrames()
    PlayerFrame:ClearAllPoints()
    PlayerFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", -300, 150)

    TargetFrame:ClearAllPoints()
    TargetFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 300, 150)
end

-- Setup minimap to hide zoom buttons and allow mouse wheel zoom
local function setupMinimap()
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            Minimap_ZoomIn()
        else
            Minimap_ZoomOut()
        end
    end)

    MinimapZoomIn:Hide()
    MinimapZoomOut:Hide()
    GameTimeFrame:Hide()
    MiniMapTracking:ClearAllPoints()
    MiniMapTracking:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 0, 0)
end

-- Move minimap buttons to the bottom-right of the minimap (mostly for LibDBIcon buttons from other addons)
local function MoveMinimapButtons()
    local function RepositionButtons()
        local foundButtons = {}

        local LibDBIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
        if LibDBIcon then
            for name, button in pairs(LibDBIcon.objects) do
                if button and button:IsVisible() then
                    table.insert(foundButtons, button)
                end
            end
        end

        local commonNames = {
            "LibDBIcon10_",
            "MinimapButton",
            "DeathLogMinimapButton",
            "NovaWorldBuffsMinimapButton",
            "NWBMinimapButton"
        }

        for _, child in pairs({ Minimap:GetChildren() }) do
            if child and child:GetObjectType() == "Button" and child:IsVisible() then
                local name = child:GetName()
                if name then
                    -- Check if it's a LibDBIcon button
                    for _, pattern in pairs(commonNames) do
                        if string.find(name, pattern) then
                            local alreadyFound = false
                            for _, existing in pairs(foundButtons) do
                                if existing == child then
                                    alreadyFound = true
                                    break
                                end
                            end
                            if not alreadyFound then
                                table.insert(foundButtons, child)
                            end
                            break
                        end
                    end
                end
            end
        end

        if #foundButtons > 0 then
            local radius = 80
            local startAngle = -math.pi / 6
            local angleSpacing = math.pi / 7

            for i, button in ipairs(foundButtons) do
                button:ClearAllPoints()
                local angle = startAngle - ((i - 1) * angleSpacing)
                local x = radius * math.cos(angle)
                local y = radius * math.sin(angle)
                button:SetPoint("CENTER", Minimap, "CENTER", x, y)
            end
        end
    end

    -- Multiple attempts to catch all buttons
    C_Timer.After(1, RepositionButtons)
    C_Timer.After(3, RepositionButtons)
    C_Timer.After(5, RepositionButtons)
end

-- Setup interface configuration variables
local function setupInterfaceConfig()
    TARGET_FRAME_BUFFS_ON_TOP = true
    DAMAGE_TEXT_FONT = "Fonts\\skurri.TTF"
    COMBAT_TEXT_FONT = "Fonts\\skurri.TTF"
    setWorldTextScale(0.75)
    SetCVar("cameraDistanceMaxZoomFactor", "4.0")
end

-- Setup mouseover for vertical bars (MultiBarRight and MultiBarLeft)
local function setupVerticalBarsMouseover()
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

-- Main event handling
local eventHooks = {
    "ADDON_LOADED",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_TARGET_CHANGED",
    "UNIT_HEALTH",
    "UNIT_HEALTH_FREQUENT",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
}

local frame = CreateFrame("Frame")
for _, event in ipairs(eventHooks) do
    frame:RegisterEvent(event)
end

frame:SetScript("OnEvent", function(self, event, name)
    -- Handle one time setup for the addon
    if event == "PLAYER_ENTERING_WORLD" then
        setupChatButtonsMouseover()
        moveWorldMapToCenter()
        hideBagsName()
        setupMinimap()
        setupInterfaceConfig()
        setupVerticalBarsMouseover()
        replacePlayerFrameWithTexture()
        moveUnitFrames()

        C_Timer.After(0.5, function()
            local LibDBIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
            if LibDBIcon then
                MoveMinimapButtons()
            end
        end)
    end

    -- Handle player target changes
    if event == "PLAYER_TARGET_CHANGED" then
        if UnitExists("target") then
            replaceTargetFrameWithTexture()
        end
    end

    -- Handle Player health changes, to keep the health bar color updated
    if event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" then
        local unit = name or "player"
        if unit == "player" then
            updatePlayerFrameHealthBarColor()
        end
    end
end)
