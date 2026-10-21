if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Bags = {}

local function GetBagFrames()
    local frames = {}
    if ContainerFrameContainer and ContainerFrameContainer.ContainerFrames then
        for _, frame in ipairs(ContainerFrameContainer.ContainerFrames) do
            table.insert(frames, frame)
        end
    end
    if ContainerFrameCombinedBags then
        table.insert(frames, ContainerFrameCombinedBags)
    end
    return frames
end

--- Only the title text is faded, so the title bar can still be dragged and opens the bag menu.
function ErzbaroneUI.Bags:Update()
    local alpha = ErzbaroneUISettings.hideBagNames and 0 or 1
    for _, frame in ipairs(GetBagFrames()) do
        local title = frame.TitleContainer and frame.TitleContainer.TitleText
        if title then
            title:SetAlpha(alpha)
        end
    end
end

function ErzbaroneUI.Bags:Initialize()
    self:Update()
end
