if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Bags = {}

--- Initializes the bag modifications.
function ErzbaroneUI.Bags:Initialize()
    if ErzbaroneUISettings.hideBagNames then
        ErzbaroneUI.Bags:HideBagNames()
    else
        ErzbaroneUI.Bags:ShowBagNames()
    end
end

--- Shows the name text on all container frames.
function ErzbaroneUI.Bags:ShowBagNames()
    for i = 1, 11 do
        local frameName = _G["ContainerFrame" .. i .. "Name"]
        if frameName then
            frameName:Show()
        end
    end
end

--- Hides the name text on all container frames.
function ErzbaroneUI.Bags:HideBagNames()
    for i = 1, 11 do
        local frameName = _G["ContainerFrame" .. i .. "Name"]
        if frameName then
            frameName:Hide()
        end
    end
end
