local root = (... or ".") .. "\\"

local function Widget()
    local widget = { shown = false }
    function widget:SetPoint(...) end
    function widget:SetShadowColor(...) end
    function widget:SetShadowOffset(...) end
    function widget:SetText(text) self.text = text end
    function widget:Show() self.shown = true end
    function widget:Hide() self.shown = false end
    function widget:CreateFontString()
        local text = Widget()
        self.fontString = text
        return text
    end
    return widget
end

local eventFrame
function CreateFrame()
    eventFrame = Widget()
    function eventFrame:RegisterEvent(event)
        self.events = self.events or {}
        self.events[event] = true
    end
    function eventFrame:SetScript(script, handler)
        self.scripts = self.scripts or {}
        self.scripts[script] = handler
    end
    return eventFrame
end

local plates = {}
local platesByUnit = {}
C_NamePlate = {
    GetNamePlates = function() return plates end,
    GetNamePlateForUnit = function(unit) return platesByUnit[unit] end,
}

local attackable = { nameplate1 = true, nameplate2 = false }
local health = { nameplate1 = 15420, nameplate2 = 800 }
local secretHealth = {}
function UnitCanAttack(_, unit) return attackable[unit] end
function UnitHealth(unit) return health[unit] end
function AbbreviateLargeNumbers(value)
    if value == secretHealth then
        return "compact:secret"
    end
    return "compact:" .. value
end

local function AddPlate(unit)
    local healthBar = Widget()
    local plate = {
        UnitFrame = {
            unit = unit,
            HealthBarsContainer = { healthBar = healthBar },
        },
    }
    plates[#plates + 1] = plate
    platesByUnit[unit] = plate
    return plate
end

local enemyPlate = AddPlate("nameplate1")
local friendlyPlate = AddPlate("nameplate2")
ErzbaroneUI = {}
ErzbaroneUISettings = { nameplateHealth = true }
dofile(root .. "modules\\nameplates.lua")
ErzbaroneUI.Nameplates:Initialize()

local enemyText = enemyPlate.UnitFrame.HealthBarsContainer.healthBar.ErzbaroneUIHealthText
local friendlyText = friendlyPlate.UnitFrame.HealthBarsContainer.healthBar.ErzbaroneUIHealthText
assert(enemyText and enemyText.shown and enemyText.text == "compact:15420",
    "Visible enemy nameplates show the abbreviated current health")
assert(not friendlyText, "Friendly nameplates do not get a health label")
assert(eventFrame.events.UNIT_HEALTH and eventFrame.events.NAME_PLATE_UNIT_ADDED
    and eventFrame.events.NAME_PLATE_UNIT_REMOVED)

health.nameplate1 = secretHealth
eventFrame.scripts.OnEvent(eventFrame, "UNIT_HEALTH", "nameplate1")
assert(enemyText.text == "compact:secret", "Secret health values are passed directly to the Blizzard formatter")

health.nameplate1 = 9000
eventFrame.scripts.OnEvent(eventFrame, "UNIT_HEALTH", "nameplate1")
assert(enemyText.text == "compact:9000", "Health updates refresh the displayed number")

ErzbaroneUISettings.nameplateHealth = false
ErzbaroneUI.Nameplates:Update()
assert(not enemyText.shown and enemyText.text == "", "Disabling the setting clears and hides labels")

ErzbaroneUISettings.nameplateHealth = true
ErzbaroneUI.Nameplates:Update()
assert(enemyText.shown and enemyText.text == "compact:9000", "Enabling the setting refreshes visible plates")

platesByUnit.nameplate1 = nil
eventFrame.scripts.OnEvent(eventFrame, "NAME_PLATE_UNIT_REMOVED", "nameplate1")
assert(not enemyText.shown and enemyText.text == "", "Removed nameplates clear their labels")

print("nameplates_test.lua: all assertions passed")
