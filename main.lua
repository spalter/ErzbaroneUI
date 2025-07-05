-- Erzbarone main file

-- hide chat buttons
local function hideChatButtons()
    ChatFrameChannelButton:Hide()
    FriendsMicroButton:Hide()
    ChatFrameMenuButton:Hide()
    ChatFrame1ButtonFrameUpButton:Hide()
    ChatFrame1ButtonFrameDownButton:Hide()
    ChatFrame1ButtonFrameBottomButton:Hide()
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

-- Move unit frames to the bottom of the screen
local function moveUnitFrames()
    PlayerFrame:ClearAllPoints()
    PlayerFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", -250, 150)

    TargetFrame:ClearAllPoints()
    TargetFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 250, 150)
end

-- Setup minimap to hide zoom buttons and allow mouse wheel zoom
local function setupMinimap()
    MinimapZoomIn:Hide()
    MinimapZoomOut:Hide()
    GameTimeFrame:Hide()
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            Minimap_ZoomIn()
        else
            Minimap_ZoomOut()
        end
    end)
    MiniMapTracking:ClearAllPoints()
    MiniMapTracking:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 0, 0)
end

-- Setup interface configuration variables
local function setupInterfaceConfig()
    TARGET_FRAME_BUFFS_ON_TOP = true
    DAMAGE_TEXT_FONT = "Fonts\\MORPHEUS.TTF"
    SetCVar("cameraDistanceMaxZoomFactor", "4.0")
end

-- Setup mouseover for vertical bars (MultiBarRight and MultiBarLeft)
local function setupVerticalBarsMouseover()
    local bars = {MultiBarRight, MultiBarLeft}

    for _, bar in pairs(bars) do
        if bar then
            -- Hide each bar by default
            bar:SetAlpha(0)

            -- Show on mouseover of the bar itself
            bar:SetScript("OnEnter", function(self)
                -- Show both bars when hovering over either
                MultiBarRight:SetAlpha(1)
                MultiBarLeft:SetAlpha(1)
            end)

            -- Hide when mouse leaves
            bar:SetScript("OnLeave", function(self)
                MultiBarRight:SetAlpha(0)
                MultiBarLeft:SetAlpha(0)
            end)
        end
    end

    -- Handle individual buttons for both bars
    local barNames = {"MultiBarRight", "MultiBarLeft"}
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


-- Initialize the addon
local function initializeAddon()
    hideChatButtons()
    moveWorldMapToCenter()
    moveUnitFrames()
    hideBagsName()
    setupMinimap()
    setupInterfaceConfig()
    setupVerticalBarsMouseover()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", initializeAddon)
