-- Erzbarone main file
ErzbaroneUI = ErzbaroneUI or {}

-- WoW 1.15.8 / Modern UI Compatibility layer for other addons
if not _G.PlayerFrameHealthBar and _G.PlayerFrame and _G.PlayerFrame.healthbar then
    _G.PlayerFrameHealthBar = _G.PlayerFrame.healthbar
end
if not _G.TargetFrameHealthBar and _G.TargetFrame and _G.TargetFrame.healthbar then
    _G.TargetFrameHealthBar = _G.TargetFrame.healthbar
end
if not _G.PlayerFrameHealthBarText and _G.PlayerFrame and _G.PlayerFrame.healthbar then
    _G.PlayerFrameHealthBarText = _G.PlayerFrame.healthbar.LeftText or _G.PlayerFrame.healthbar.TextString or _G.PlayerFrame.healthbar.Text
end
if not _G.TargetFrameHealthBarText and _G.TargetFrame and _G.TargetFrame.healthbar then
    _G.TargetFrameHealthBarText = _G.TargetFrame.healthbar.LeftText or _G.TargetFrame.healthbar.TextString or _G.TargetFrame.healthbar.Text
end
if not _G.PlayerFrameTexture and _G.PlayerFrame and _G.PlayerFrame.PlayerFrameContainer then
    _G.PlayerFrameTexture = _G.PlayerFrame.PlayerFrameContainer.FrameTexture
end
if not _G.TargetFrameTextureFrameTexture and _G.TargetFrame and _G.TargetFrame.TargetFrameContainer then
    _G.TargetFrameTextureFrameTexture = _G.TargetFrame.TargetFrameContainer.FrameTexture
end

ErzbaroneUI.Static = {
    OpenSoundID = 850,
    CloseSoundID = 851,
    LightClickSoundID = 856,
}
ErzbaroneUI.isClassic = false

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
    "UNIT_EXITED_VEHICLE",
    "UNIT_ENTERED_VEHICLE",
    "DISPLAY_SIZE_CHANGED",
    "MERCHANT_SHOW",
    "CINEMATIC_STOP",
    "UNIT_FACTION"
}

local frame = CreateFrame("Frame")
for _, event in ipairs(eventHooks) do
    frame:RegisterEvent(event)
end

frame:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == "ErzbaroneUI" then
        local _, _, _, tocversion = GetBuildInfo()
        if tocversion < 20000 then -- TOC versions for Classic Era are in the 1xxxx range
            ErzbaroneUI.isClassic = true
        end

        ErzbaroneUI.Config:SetDamageFont()

        SLASH_ERZBARONEUI1 = "/eui"
        SlashCmdList["ERZBARONEUI"] = function(msg)
            ErzbaroneUI.Config:ToggleFrame()
        end
    end

    -- Handle one time setup for the addon
    if event == "PLAYER_ENTERING_WORLD" then
        ErzbaroneUI.Config:Initialize()
        ErzbaroneUI.Castbar:Initialize()
        ErzbaroneUI.Chat:Initialize()
        ErzbaroneUI.WorldMap:Initialize()
        ErzbaroneUI.Bags:Initialize()
        ErzbaroneUI.UnitFrames:Initialize()
        ErzbaroneUI.Bars:Initialize()
        ErzbaroneUI.Minimap:Initialize()
        ErzbaroneUI.Flag:Initialize()
        ErzbaroneUI.Effects:ActivateVignette()
    end

    -- Handle exiting vehicle
    if event == "UNIT_EXITED_VEHICLE" then
        if name == "player" then
            C_Timer.After(0.5, function() -- Delay to ensure the player frame is restored after exiting vehicle
                print("Exiting vehicle, restoring player frame")
                ErzbaroneUI.UnitFrames:CenterFrames()
                ErzbaroneUI.UnitFrames:ReplacePlayerFrame()
                ErzbaroneUI.Bars:ReplaceMicroButtonBar()
            end)
        end
    end

    -- Handle entering vehicle to reset the healthbar size
    if event == "UNIT_ENTERED_VEHICLE" then
        if name == "player" then
            ErzbaroneUI.UnitFrames:RestorePlayerFrame()
            ErzbaroneUI.Bars:ResetMicroButtonBar()
        end
    end

    -- Handle player target changes or faction changes to update the target frame
    if event == "PLAYER_TARGET_CHANGED" or event == "UNIT_FACTION" then
        if UnitExists("target") and ErzbaroneUISettings.improvedUnitFrames then
            ErzbaroneUI.UnitFrames:ReplaceTargetFrame()
        end
    end

    -- Handle Player health changes, to keep the health bar color updated
    if event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" or event == "UNIT_MAXHEALTH" and ErzbaroneUISettings.improvedUnitFrames then
        local unit = name or "player"
        if unit == "player" then
            ErzbaroneUI.UnitFrames:UpdatePlayerHealthColor()
        end

        if unit == "target" then
            ErzbaroneUI.UnitFrames:UpdateTargetHealthColor()
        end
    end

    -- Handle display size changes for the vignette effect
    if event == "DISPLAY_SIZE_CHANGED" then
        ErzbaroneUI.Effects:UpdateVignette()
    end

    -- Handle merchant show event to auto-sell grey items
    if event == "MERCHANT_SHOW" then
        ErzbaroneUI.Utils:AutoSellGreyItems()
        ErzbaroneUI.Utils:AutoRepair()
    end

    -- Handle cutscene end
    if event == "CINEMATIC_STOP" then
        ErzbaroneUI.Bars:ReplaceMicroButtonBar()
    end
end)
