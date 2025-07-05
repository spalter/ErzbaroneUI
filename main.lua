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

    C_Timer.After(0.5, function()
        local LibDBIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
        if LibDBIcon then
            MoveMinimapButtons()
        end
    end)
end)
