if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.SwingTimer = {}

local function IsMainHandSwing(swingType)
    return swingType == ((Enum.PlayerSwingType and Enum.PlayerSwingType.MainHand) or 0)
end

--- Starts the spark for a main hand swing of the given duration.
function ErzbaroneUI.SwingTimer:Start(duration)
    if not duration or (canaccessvalue and not canaccessvalue(duration)) or duration <= 0 then
        return
    end

    self.Spark = self.Spark or ErzbaroneUI.CreatePowerBarSpark("ErzbaroneUISwingTimerTrack")
    if self.Spark then
        self.Spark:Start(duration)
    end
end

function ErzbaroneUI.SwingTimer:Stop()
    if self.Spark then
        self.Spark:Stop()
    end
end

--- Registers for the player's swings while the setting is enabled.
function ErzbaroneUI.SwingTimer:Update()
    if not self.EventFrame then
        self.EventFrame = CreateFrame("Frame")
        self.EventFrame:SetScript("OnEvent", function(_, event, swingDuration, swingType)
            if event == "PLAYER_SWING" then
                if IsMainHandSwing(swingType) then
                    ErzbaroneUI.SwingTimer:Start(swingDuration)
                end
            else
                -- A new weapon or leaving combat makes a running swing meaningless
                ErzbaroneUI.SwingTimer:Stop()
            end
        end)
    end

    if ErzbaroneUISettings.swingTimer then
        self.EventFrame:RegisterEvent("PLAYER_SWING")
        self.EventFrame:RegisterEvent("WEAPON_SLOT_CHANGED")
        self.EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        self.EventFrame:UnregisterAllEvents()
        self:Stop()
    end
end

function ErzbaroneUI.SwingTimer:Initialize()
    self:Update()
end
