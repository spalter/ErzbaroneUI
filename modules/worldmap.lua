if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.WorldMap = {}

function ErzbaroneUI.WorldMap:Initialize()
    ErzbaroneUI.WorldMap:MoveToCenter()
end

function ErzbaroneUI.WorldMap:MoveToCenter(self)
    local worldMapAnchor = _G["WorldMapScreenAnchor"]
    if worldMapAnchor then
        worldMapAnchor:ClearAllPoints()
        worldMapAnchor:SetPoint("CENTER", UIParent, "CENTER", -306, 280)
    end
end
