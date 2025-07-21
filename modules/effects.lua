if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Effects = {}

-- Create a vignette effect that darkens the screen edges
function ErzbaroneUI.Effects:ActivateVignette()
    if not ErzbaroneUISettings.vignette then
        return
    end

    local vignetteFrame = _G["ErzbaroneUIVignette"]
    if vignetteFrame then
        vignetteFrame:Show()
        return
    end

    local vignetteFrame = CreateFrame("Frame", "ErzbaroneUIVignette", UIParent)
    local screenSize = { UIParent:GetWidth(), UIParent:GetHeight() }
    vignetteFrame:SetSize(screenSize[1], screenSize[2])
    vignetteFrame:SetPoint("CENTER", UIParent, "CENTER")
    vignetteFrame:SetFrameStrata("HIGH")
    vignetteFrame:SetFrameLevel(0)
    vignetteFrame:EnableMouse(false)

    vignetteFrame.texture = vignetteFrame:CreateTexture(nil, "BACKGROUND")
    vignetteFrame.texture:SetAllPoints(vignetteFrame)
    vignetteFrame.texture:SetBlendMode("BLEND")
    vignetteFrame.texture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\Textures\\vignette")
end

-- Update the vignette effect size when the display size changes
function ErzbaroneUI.Effects:UpdateVignette()
    local vignetteFrame = _G["ErzbaroneUIVignette"]
    if vignetteFrame then
        vignetteFrame.texture:SetAllPoints(vignetteFrame)
        vignetteFrame:SetSize(UIParent:GetWidth(), UIParent:GetHeight())
    end
end

-- Deactivate the vignette effect
function ErzbaroneUI.Effects:DeactivateVignette()
    local vignetteFrame = _G["ErzbaroneUIVignette"]
    if vignetteFrame then
        vignetteFrame:Hide()
    end
end
