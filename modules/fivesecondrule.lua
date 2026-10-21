if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.FiveSecondRule = {
    Duration = 5,
    SparkTexture = "Interface\\CastingBar\\UI-CastingBar-Spark",
}

local MANA = (Enum and Enum.PowerType and Enum.PowerType.Mana) or 0

--- Returns true if the given spell costs mana.
local function SpellCostsMana(spellID)
    local costs = spellID and C_Spell.GetSpellPowerCost(spellID)
    if not costs then
        return false
    end

    for _, cost in ipairs(costs) do
        if cost.type == MANA and ((cost.cost or 0) > 0 or (cost.minCost or 0) > 0) then
            return true
        end
    end
    return false
end

--- Creates the spark which travels over the player's mana bar.
--- The spark is anchored to the fill edge of an invisible status bar on top of the mana bar, so its position never
--- needs the mana bar's size, which becomes a secret value in combat.
function ErzbaroneUI.FiveSecondRule:CreateSpark()
    local manaBar = PlayerFrame_GetManaBar()
    if not manaBar then
        return nil
    end

    local track = CreateFrame("StatusBar", "ErzbaroneUIFiveSecondRuleTrack", manaBar)
    track:SetAllPoints(manaBar)
    track:SetFrameLevel(manaBar:GetFrameLevel() + 5)
    track:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    track:GetStatusBarTexture():SetAlpha(0)
    track:SetMinMaxValues(0, self.Duration)
    track:EnableMouse(false)
    track:Hide()

    local sparkHeight = 24
    local manaBarHeight = manaBar:GetHeight()
    if not canaccessvalue or canaccessvalue(manaBarHeight) then
        sparkHeight = math.max(manaBarHeight * 2.5, sparkHeight)
    end

    track.spark = track:CreateTexture(nil, "OVERLAY")
    track.spark:SetSize(32, sparkHeight)
    track.spark:SetPoint("CENTER", track:GetStatusBarTexture(), "RIGHT", 0, 0)
    track.spark:SetTexture(self.SparkTexture)
    track.spark:SetBlendMode("ADD")

    track:SetScript("OnUpdate", function(frame)
        local elapsed = GetTime() - frame.startTime
        if elapsed >= ErzbaroneUI.FiveSecondRule.Duration then
            frame:Hide()
            return
        end

        frame:SetValue(elapsed)
    end)

    return track
end

--- Starts (or restarts) the five second rule timer.
function ErzbaroneUI.FiveSecondRule:Start()
    -- Druids in bear/cat form don't show a mana bar
    if UnitPowerType("player") ~= MANA then
        return
    end

    self.Spark = self.Spark or self:CreateSpark()
    if not self.Spark then
        return
    end

    self.Spark.startTime = GetTime()
    self.Spark:SetValue(0)
    self.Spark:Show()
end

--- Stops the timer and hides the spark.
function ErzbaroneUI.FiveSecondRule:Stop()
    if self.Spark then
        self.Spark:Hide()
    end
end

--- Applies the current setting; hides the spark when the feature gets disabled.
function ErzbaroneUI.FiveSecondRule:Update()
    if not ErzbaroneUISettings.fiveSecondRuleTimer then
        self:Stop()
    end
end

--- Registers the events needed to detect mana spending casts.
function ErzbaroneUI.FiveSecondRule:Initialize()
    if self.EventFrame then
        return
    end

    -- Max mana may be secret (e.g. when zoning in combat); only skip classes we know have no mana
    local maxMana = UnitPowerMax("player", MANA)
    local isAccessible = not canaccessvalue or canaccessvalue(maxMana)
    if isAccessible and (maxMana or 0) <= 0 then
        return
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    eventFrame:SetScript("OnEvent", function(_, _, _, _, spellID)
        if ErzbaroneUISettings.fiveSecondRuleTimer and SpellCostsMana(spellID) then
            ErzbaroneUI.FiveSecondRule:Start()
        end
    end)

    self.EventFrame = eventFrame
end
