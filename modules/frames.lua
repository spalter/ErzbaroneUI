if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Frames = {}
ErzbaroneUI.Frames.Windows = {
    { "CharacterFrame",    375 },
    { "TradeSkillFrame",   375 },
    { "CraftFrame",        375 },
    { "SpellBookFrame",    375 },
    { "PlayerTalentFrame", 375 },
    { "QuestLogFrame",     700 },
}

ErzbaroneUI.Frames.ElapsedUpdate = 0

--- Initializes the frame modifications.
function ErzbaroneUI.Frames:Initialize()
    if ErzbaroneUISettings.narrowUI then
        ErzbaroneUI.Frames:CreateViewportFrame()
        ErzbaroneUI.Frames:MoveFrame("MinimapCluster", 0)
        -- ErzbaroneUI.Frames:MoveFrame("CharacterFrame", 0)
        -- ErzbaroneUI.Frames:SetupLazyFrameMover()
    end
end

function ErzbaroneUI.Frames:CreateViewportFrame()
    ErzbaroneUI.viewportFrame = CreateFrame("Frame", "ErzbaroneViewportFrame", UIParent)
    ErzbaroneUI.viewportFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", GetScreenWidth() / 4, 0)
    ErzbaroneUI.viewportFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -GetScreenWidth() / 4, 0)
    ErzbaroneUI.viewportFrame:SetFrameStrata("BACKGROUND")
    ErzbaroneUI.viewportFrame:SetFrameLevel(0)
    ErzbaroneUI.viewportFrame:SetScript("OnUpdate", function(self, elapsed)
        ErzbaroneUI.Frames.ElapsedUpdate = ErzbaroneUI.Frames.ElapsedUpdate + elapsed
        if ErzbaroneUI.Frames.ElapsedUpdate < 0.05 then
            return
        end
        ErzbaroneUI.Frames:UpdateWindowPositions()
        ErzbaroneUI.Frames.ElapsedUpdate = 0
    end)
end

function ErzbaroneUI.Frames:UpdateWindowPositions()
    local openWindows = 0
    for _, frame in ipairs(ErzbaroneUI.Frames.Windows) do
        local frameHandle = _G[frame[1]]
        local frameSpacing = frame[2]

        if not frameHandle then
            return
        end

        if frameHandle:IsShown() or frameHandle:IsVisible() then
            ErzbaroneUI.Frames:MoveFrame(frame[1], frameSpacing * openWindows)
            openWindows = openWindows + 1
        end
    end
end

function ErzbaroneUI.Frames:MoveFrame(frameName, offset)
    local frame = _G[frameName]
    if frame then
        local point, _, relativePoint, _, yOfs = frame:GetPoint()
        frame:ClearAllPoints()
        frame:SetParent(ErzbaroneUI.viewportFrame)
        frame:SetPoint(point, ErzbaroneUI.viewportFrame, relativePoint, offset, yOfs)

        frame:HookScript("OnShow", function(self)
            self:ClearAllPoints()
            frame:SetParent(ErzbaroneUI.viewportFrame)
            self:SetPoint(point, ErzbaroneUI.viewportFrame, relativePoint, offset, yOfs)
        end)
    end
end

--- Creates an event handler to move frames when they appear.
function ErzbaroneUI.Frames:SetupLazyFrameMover()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterAllEvents()

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        ErzbaroneUI.Frames:UpdateWindowPositions()
    end)
end
