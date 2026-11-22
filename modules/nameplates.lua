if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Nameplates = {}

local eventFrame
local activeUnits = {}
local healthTexts = {}

--- Finds or creates the health label on Blizzard's nameplate health bar for this unit.
local function GetHealthText(unit)
    if healthTexts[unit] then
        return healthTexts[unit]
    end

    local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
    local unitFrame = namePlate and namePlate.UnitFrame
    local healthBar = unitFrame and unitFrame.HealthBarsContainer and unitFrame.HealthBarsContainer.healthBar
    if not healthBar then
        return nil
    end

    local text = healthBar.ErzbaroneUIHealthText
    if not text then
        text = healthBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("CENTER", healthBar, "CENTER")
        text:SetShadowColor(0, 0, 0, 1)
        text:SetShadowOffset(1, -1)
        healthBar.ErzbaroneUIHealthText = text
    end

    healthTexts[unit] = text
    return text
end

--- Hides and uncaches a unit's label when its nameplate is removed or no longer eligible.
local function HideHealthText(unit)
    local text = healthTexts[unit]
    if text then
        text:SetText("")
        text:Hide()
        healthTexts[unit] = nil
    end
end

--- Displays abbreviated current health only for attackable units while the setting is enabled.
local function UpdateUnit(unit)
    if not ErzbaroneUISettings.nameplateHealth then
        HideHealthText(unit)
        return
    end

    if not UnitCanAttack("player", unit) then
        HideHealthText(unit)
        return
    end

    local text = GetHealthText(unit)
    if not text then
        return
    end

    text:SetText(AbbreviateLargeNumbers(UnitHealth(unit)))
    text:Show()
end

--- Tracks visible nameplate units and refreshes their labels on health or faction changes.
local function OnEvent(_, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        activeUnits[unit] = true
        UpdateUnit(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        activeUnits[unit] = nil
        HideHealthText(unit)
    elseif activeUnits[unit] then
        UpdateUnit(unit)
    end
end

--- Applies the current compact enemy-health setting to visible nameplates.
function ErzbaroneUI.Nameplates:Update()
    for unit in pairs(activeUnits) do
        UpdateUnit(unit)
    end
end

--- Hooks nameplate lifecycle and health updates, then initializes currently visible plates.
function ErzbaroneUI.Nameplates:Initialize()
    if not eventFrame then
        eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
        eventFrame:RegisterEvent("UNIT_HEALTH")
        eventFrame:RegisterEvent("UNIT_FACTION")
        eventFrame:SetScript("OnEvent", OnEvent)
    end

    for unit in pairs(activeUnits) do
        HideHealthText(unit)
    end
    activeUnits = {}
    for _, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
        local unit = namePlate.UnitFrame and namePlate.UnitFrame.unit
        if unit then
            activeUnits[unit] = true
            UpdateUnit(unit)
        end
    end
end
