if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Flag = {}

--- Initializes the flag module.
function ErzbaroneUI.Flag:Initialize()
    if ErzbaroneUISettings.showErzbaroneUIFlag then
        ErzbaroneUI.Flag:ShowFlag()
    else
        ErzbaroneUI.Flag:HideFlag()
    end
end

--- Sets up the flag frame and its texture.
--- This function creates a frame that displays a flag texture below the minimap.
--- The flag is positioned at the bottom center of the minimap
function ErzbaroneUI.Flag:ShowFlag()
    local minimap = _G["TimeManagerClockButton"]
    local flagFrame = CreateFrame("Button", "ErzbaroneUIFlagFrame", UIParent)
    flagFrame:SetFrameStrata("BACKGROUND")
    flagFrame:SetFrameLevel(0)
    flagFrame:SetSize(48, 48)
    flagFrame:SetPoint("BOTTOM", minimap, "BOTTOM", 0, -38)

    flagFrame:SetScript("OnClick", function()
        ErzbaroneUI.Config:ToggleFrame()
    end)

    flagFrame.texture = flagFrame:CreateTexture(nil, "BACKGROUND")
    flagFrame.texture:SetDrawLayer("BACKGROUND", -8)
    flagFrame.texture:SetAllPoints()
    flagFrame.texture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\erzbarone_flag")
end

--- Hides the flag frame.
function ErzbaroneUI.Flag:HideFlag()
    local flagFrame = _G["ErzbaroneUIFlagFrame"]
    if flagFrame then
        flagFrame:Hide()
    end
end