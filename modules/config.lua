if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Config = {}

function ErzbaroneUI.Config:Initialize()
    ErzbaroneUI.Config:Setup()
end

function ErzbaroneUI.Config:Setup()
    TARGET_FRAME_BUFFS_ON_TOP = true
    SetCVar("cameraDistanceMaxZoomFactor", "4.0")
end

function ErzbaroneUI.Config:SetDamageFont()
    DAMAGE_TEXT_FONT = "Fonts\\skurri.TTF"
    COMBAT_TEXT_FONT = "Fonts\\skurri.TTF"
    SetCVar("WorldTextScale", tostring(0.75))
end
