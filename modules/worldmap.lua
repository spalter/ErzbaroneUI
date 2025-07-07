if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.WorldMap = {}

function ErzbaroneUI.WorldMap:Initialize()
    print("ErzbaroneUI WorldMap Module Initialized")
    ErzbaroneUI.WorldMap:MoveToCenter()
end

function ErzbaroneUI.WorldMap:MoveToCenter()
    if WorldMapScreenAnchor then
        WorldMapScreenAnchor:ClearAllPoints()
        WorldMapScreenAnchor:SetPoint("CENTER", UIParent, "CENTER", -306, 280)
    end
end
