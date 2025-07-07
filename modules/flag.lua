if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Flag = {}

function ErzbaroneUI.Flag:Initialize()
    ErzbaroneUI.Flag:SetupFlag()
end

function ErzbaroneUI.Flag:SetupFlag()
    local minimap = _G["TimeManagerClockButton"]
    local flagFrame = CreateFrame("Frame", "ErzbaroneUIFlagFrame", UIParent)
    flagFrame:SetFrameStrata("BACKGROUND")
    flagFrame:SetFrameLevel(0)
    flagFrame:SetSize(48, 48)
    flagFrame:SetPoint("BOTTOM", minimap, "BOTTOM", 0, -38)
    flagFrame.texture = flagFrame:CreateTexture(nil, "BACKGROUND")
    flagFrame.texture:SetDrawLayer("BACKGROUND", -8)
    flagFrame.texture:SetAllPoints()
    flagFrame.texture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\erzbarone_flag")
end