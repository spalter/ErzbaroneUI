if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.ThreatGlow = {}

--- The large threat glows covering the whole frame area. The smaller combat pulse on the player portrait
--- (StatusTexture) and the attack icon are separate textures and stay untouched.
local function GetThreatGlows()
    local glows = {}
    if PlayerFrame and PlayerFrame.PlayerFrameContainer then
        table.insert(glows, PlayerFrame.PlayerFrameContainer.FrameFlash)
    end
    for _, frame in ipairs({ TargetFrame, FocusFrame }) do
        if frame and frame.TargetFrameContainer then
            table.insert(glows, frame.TargetFrameContainer.Flash)
        end
    end
    return glows
end

--- Blizzard only shows/hides and colors the glows, so a zero alpha hides them without touching its logic.
function ErzbaroneUI.ThreatGlow:Update()
    local alpha = ErzbaroneUISettings.hideThreatGlow and 0 or 1
    for _, glow in ipairs(GetThreatGlows()) do
        glow:SetAlpha(alpha)
    end
end

--- Applies the current threat-glow visibility setting.
function ErzbaroneUI.ThreatGlow:Initialize()
    self:Update()
end
