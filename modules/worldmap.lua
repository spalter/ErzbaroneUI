if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.WorldMap = {}

-- Initializes the world map modifications.
function ErzbaroneUI.WorldMap:Initialize()
    ErzbaroneUI.WorldMap:MoveToCenter()
end

-- Moves the world map to the center of the screen.
function ErzbaroneUI.WorldMap:MoveToCenter(self)
    local worldMapAnchor = _G["WorldMapScreenAnchor"]
    if worldMapAnchor then
        worldMapAnchor:ClearAllPoints()
        worldMapAnchor:SetPoint("CENTER", UIParent, "CENTER", -306, 280)
    end
end
