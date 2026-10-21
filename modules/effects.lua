if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Effects = {}

--- Creates the vignette frame which darkens the screen edges.
--- Anchored to UIParent so it follows resolution and UI scale changes automatically.
local function CreateVignetteFrame()
    local vignetteFrame = CreateFrame("Frame", "ErzbaroneUIVignette", UIParent)
    vignetteFrame:SetAllPoints(UIParent)
    vignetteFrame:SetFrameStrata("HIGH")
    vignetteFrame:SetFrameLevel(0)
    vignetteFrame:EnableMouse(false)

    vignetteFrame.texture = vignetteFrame:CreateTexture(nil, "BACKGROUND")
    vignetteFrame.texture:SetAllPoints(vignetteFrame)
    vignetteFrame.texture:SetBlendMode("BLEND")
    vignetteFrame.texture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\vignette")

    return vignetteFrame
end

--- Shows or hides the vignette based on the current setting.
function ErzbaroneUI.Effects:UpdateVignette()
    if ErzbaroneUISettings.vignette then
        self.Vignette = self.Vignette or CreateVignetteFrame()
        self.Vignette:Show()
    elseif self.Vignette then
        self.Vignette:Hide()
    end
end
