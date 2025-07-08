if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Config = {}

-- Initializes the configuration settings for ErzbaroneUI.
function ErzbaroneUI.Config:Initialize()
    ErzbaroneUI.Config:Setup()
end

-- Sets up the initial configuration for ErzbaroneUI.
function ErzbaroneUI.Config:Setup()
    TARGET_FRAME_BUFFS_ON_TOP = true
    SetCVar("cameraDistanceMaxZoomFactor", "4.0")
end

-- Sets the font for damage text in the game.
function ErzbaroneUI.Config:SetDamageFont()
    DAMAGE_TEXT_FONT = "Fonts\\skurri.TTF"
    COMBAT_TEXT_FONT = "Fonts\\skurri.TTF"
    SetCVar("WorldTextScale", tostring(0.75))
end
