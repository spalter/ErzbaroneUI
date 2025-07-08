if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Bags = {}

--- Initializes the bag modifications.
function ErzbaroneUI.Bags:Initialize()
    ErzbaroneUI.Bags:HideNames()
end

--- Hides the name text on all container frames.
function ErzbaroneUI.Bags:HideNames()
    for i = 1, 11 do
        local frameName = _G["ContainerFrame" .. i .. "Name"]
        if frameName then
            frameName:Hide()
        end
    end
end
