-- Erzbarone main file
ErzbaroneUI = ErzbaroneUI or {}

-- Main event handling
local eventHooks = {
    "ADDON_LOADED",
    "PLAYER_ENTERING_WORLD",
    "MERCHANT_SHOW",
}

local frame = CreateFrame("Frame")
for _, event in ipairs(eventHooks) do
    frame:RegisterEvent(event)
end

-- Initializes modules on world entry and handles addon-load and merchant events.
frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == "ErzbaroneUI" then
        ErzbaroneUI.Config:Initialize()
        ErzbaroneUI.Effects:UpdateVignette()

        SLASH_ERZBARONEUI1 = "/eui"
        -- Opens the addon's settings from the /eui slash command.
        SlashCmdList["ERZBARONEUI"] = function()
            ErzbaroneUI.Config:OpenSettings()
        end
    end

    if event == "PLAYER_ENTERING_WORLD" then
        ErzbaroneUI.FiveSecondRule:Initialize()
        ErzbaroneUI.SwingTimer:Initialize()
        ErzbaroneUI.StatusBars:Initialize()
        ErzbaroneUI.CastBars:Initialize()
        ErzbaroneUI.ThreatGlow:Initialize()
        ErzbaroneUI.CastCount:Initialize()
        ErzbaroneUI.RangeTint:Initialize()
        ErzbaroneUI.BarFade:Initialize()
        ErzbaroneUI.Chat:Initialize()
        ErzbaroneUI.MainBar:Initialize()
        ErzbaroneUI.Minimap:Initialize()
        ErzbaroneUI.Bags:Initialize()
    end

    -- Handle merchant show event to auto-sell grey items
    if event == "MERCHANT_SHOW" then
        ErzbaroneUI.Utils:AutoSellGreyItems()
        ErzbaroneUI.Utils:AutoRepair()
    end
end)
