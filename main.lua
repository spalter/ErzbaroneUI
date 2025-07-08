-- Erzbarone main file
ErzbaroneUI = ErzbaroneUI or {}

-- Main event handling
local eventHooks = {
    "ADDON_LOADED",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_TARGET_CHANGED",
    "UNIT_HEALTH",
    "UNIT_HEALTH_FREQUENT",
    "UNIT_MAXHEALTH",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
}

local frame = CreateFrame("Frame")
for _, event in ipairs(eventHooks) do
    frame:RegisterEvent(event)
end

frame:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == "ErzbaroneUI" then
        ErzbaroneUI.Config:SetDamageFont()

        SLASH_ERZBARONEUI1 = "/eui"
        SlashCmdList["ERZBARONEUI"] = function(msg)
            ErzbaroneUI.Config:ToggleFrame()
        end
    end

    -- Handle one time setup for the addon
    if event == "PLAYER_ENTERING_WORLD" then
        ErzbaroneUI.Config:Initialize()
        ErzbaroneUI.Chat:Initialize()
        ErzbaroneUI.WorldMap:Initialize()
        ErzbaroneUI.Bags:Initialize()
        ErzbaroneUI.Frames:Initialize()
        ErzbaroneUI.Bars:Initialize()
        ErzbaroneUI.Minimap:Initialize()
        ErzbaroneUI.Flag:Initialize()
    end

    -- Handle player target changes
    if event == "PLAYER_TARGET_CHANGED" then
        if UnitExists("target") and ErzbaroneUISettings.improvedUnitFrames then
            ErzbaroneUI.Frames:ReplaceTargetFrame()
        end
    end

    -- Handle Player health changes, to keep the health bar color updated
    if event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" or event == "UNIT_MAXHEALTH" and ErzbaroneUISettings.improvedUnitFrames then
        local unit = name or "player"
        if unit == "player" then
            ErzbaroneUI.Frames:UpdatePlayerHealthColor()
        end

        if unit == "target" then
            ErzbaroneUI.Frames:UpdateTargetHealthColor()
        end
    end
end)
