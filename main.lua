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

-- Move unit frames to the bottom of the screen
local function moveUnitFrames()
    PlayerFrame:ClearAllPoints()
    PlayerFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", -250, 150)

    TargetFrame:ClearAllPoints()
    TargetFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 250, 150)
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

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, name)
    if name == "ErzbaroneUI" then
        setupChatButtonsMouseover()
        moveWorldMapToCenter()
        hideBagsName()
        setupMinimap()
        setupInterfaceConfig()
        setupVerticalBarsMouseover()
    end
    moveUnitFrames()
end)
