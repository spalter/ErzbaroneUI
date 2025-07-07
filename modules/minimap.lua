if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Minimap = {}

function ErzbaroneUI.Minimap:Initialize()
    ErzbaroneUI.Minimap:Setup()
end

function ErzbaroneUI.Minimap:Setup()
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            Minimap_ZoomIn()
        else
            Minimap_ZoomOut()
        end
    end)

    local minimapMailFrame = _G["MiniMapMailFrame"]
    if minimapMailFrame then
        minimapMailFrame:ClearAllPoints()
        minimapMailFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 20, -30)
    end

    local minimapZoomIn = _G["MinimapZoomIn"]
    local minimapZoomOut = _G["MinimapZoomOut"]
    local minimapTracking = _G["MiniMapTracking"]
    minimapZoomIn:Hide()
    minimapZoomOut:Hide()
    GameTimeFrame:Hide()
    minimapTracking:ClearAllPoints()
    minimapTracking:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 0, 0)
end

function ErzbaroneUI.Minimap:MoveButtons()
    local foundButtons = {}

    local function RepositionButtons()
        foundButtons = {}

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
                button:SetAlpha(0)
            end
        end
    end


    -- Setup minimap hover functionality
    local function SetupMinimapHover()
        -- Hook individual button events to keep them visible
        for _, button in ipairs(foundButtons) do
            if button then
                button:HookScript("OnEnter", function()
                    for _, btn in ipairs(foundButtons) do
                        if btn then
                            btn:SetAlpha(1)
                        end
                    end
                end)

                button:HookScript("OnLeave", function()
                    C_Timer.After(0.1, function()
                        local mouseOver = false

                        -- Check if mouse is over any button or minimap area
                        for _, btn in ipairs(foundButtons) do
                            if btn and btn:IsMouseOver() then
                                mouseOver = true
                                break
                            end
                        end

                        if not mouseOver then
                            for _, btn in ipairs(foundButtons) do
                                if btn then
                                    btn:SetAlpha(0)
                                end
                            end
                        end
                    end)
                end)
            end
        end
    end

    -- Multiple attempts to catch all buttons and setup hover
    C_Timer.After(1, function()
        RepositionButtons()
        SetupMinimapHover()
    end)
    C_Timer.After(3, function()
        RepositionButtons()
        SetupMinimapHover()
    end)
    C_Timer.After(5, function()
        RepositionButtons()
        SetupMinimapHover()
    end)
end
