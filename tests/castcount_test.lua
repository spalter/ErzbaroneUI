local root = (... or ".") .. "\\"

local frames = {}
function CreateFrame()
    local frame = { events = {}, shown = true }
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:RegisterUnitEvent(event, unit) self.events[event] = unit end
    function frame:UnregisterAllEvents() self.events = {} end
    function frame:SetScript(script, callback) self[script] = callback end
    function frame:Show() self.shown = true end
    function frame:Hide() self.shown = false end
    frames[#frames + 1] = frame
    return frame
end

local scans, actionReads, powerReads, costReads = 0, 0, 0, 0
local mana = 100
local button = { action = 1 }
function button:CalculateAction()
    actionReads = actionReads + 1
    return self.action
end
function button:CreateFontString()
    local label = {}
    function label:SetPoint() end
    function label:SetJustifyH() end
    function label:SetText(value) self.text = value end
    function label:SetTextColor() end
    function label:Show() self.shown = true end
    function label:Hide() self.shown = false end
    return label
end

local buttons = { button }
local spellCosts = { [123] = 25, [456] = 10, [789] = 0 }
local costReadsBySpell = {}
ErzbaroneUI = { Utils = {} }
function ErzbaroneUI.Utils:ForEachActionButton(callback)
    scans = scans + 1
    for _, actionButton in ipairs(buttons) do
        callback(actionButton)
    end
end
function UnitPowerMax()
    powerReads = powerReads + 1
    return 100
end
function UnitPower()
    powerReads = powerReads + 1
    return mana
end
function GetActionInfo(action)
    if action == 2 then return "macro", 42 end
    if action == 3 then return "spell", 456 end
    if action == 4 or action == 5 then return "spell", 789 end
    if action == 6 or action == 7 then return "spell", 999 end
    return "spell", 123
end
function GetMacroSpell() return 123 end
C_ActionBar = {
    HasAction = function() return true end,
    IsUsableAction = function() return true, false end,
}
C_Spell = { GetSpellPowerCost = function(spellID)
    costReads = costReads + 1
    costReadsBySpell[spellID] = (costReadsBySpell[spellID] or 0) + 1
    if spellCosts[spellID] == nil then return nil end
    return { { type = 0, cost = spellCosts[spellID] } }
end }

ErzbaroneUISettings = { castCount = false }
dofile(root .. "modules\\castcount.lua")
local castCount = ErzbaroneUI.CastCount
castCount:Initialize()
local frame = castCount.EventFrame
local function Tick()
    if frame.shown then frame:OnUpdate() end
end

assert(next(frame.events) == nil, "Disabled initialization must not subscribe to updates")
castCount:Initialize()
castCount:Update()
castCount:RequestUpdate()
Tick()
assert(#frames == 1 and not frame.shown, "Disabled initialization must reuse an idle frame")
assert(scans == 0 and powerReads == 0, "Disabled initialization must not scan buttons or read power")

ErzbaroneUISettings.castCount = true
castCount:Update()
local label = button.ErzbaroneUICastCount
assert(label and label.shown and label.text == 4, "Enabling must immediately refresh cast counts")
assert(frame.events.UNIT_POWER_UPDATE == "player" and frame.events.UNIT_MAXPOWER == "player"
    and frame.events.UNIT_DISPLAYPOWER == "player" and frame.events.UNIT_AURA == "player"
    and frame.events.ACTIONBAR_SLOT_CHANGED, "Enabling must register player and action updates")

local before = scans
frame:OnEvent("UNIT_POWER_UPDATE", "player", "ENERGY")
frame:OnEvent("UNIT_MAXPOWER", "player", "RAGE")
Tick()
assert(scans == before and not frame.shown, "Non-mana power events must not schedule button scans")

mana = 50
frame:OnEvent("UNIT_POWER_UPDATE", "player", "MANA")
frame:OnEvent("UNIT_MAXPOWER", "player", "MANA")
frame:OnEvent("UNIT_AURA", "player")
assert(scans == before and frame.shown, "Relevant events must defer until the next frame")
Tick()
assert(scans == before + 1 and label.text == 2, "Events in one frame must share one mana refresh")
Tick()
assert(scans == before + 1, "The updater must sleep after refreshing")

for _, event in ipairs({ "UNIT_DISPLAYPOWER", "ACTIONBAR_SLOT_CHANGED" }) do
    before = scans
    frame:OnEvent(event, "player")
    Tick()
    assert(scans == before + 1, event .. " must still refresh buttons")
end

frame:OnEvent("UNIT_POWER_UPDATE", "player", "MANA")
ErzbaroneUISettings.castCount = false
before = scans
local previousActions, previousPower, previousCosts = actionReads, powerReads, costReads
castCount:Update()
assert(not label.shown and scans == before + 1, "Disabling must hide existing labels with one cleanup scan")
assert(actionReads == previousActions and powerReads == previousPower and costReads == previousCosts,
    "Disabling must not calculate actions, read power or query costs")
assert(not frame.shown and next(frame.events) == nil, "Disabling must cancel queued work and unsubscribe")
before = scans
castCount:Initialize()
castCount:Update()
castCount:RequestUpdate()
frame:OnEvent("UNIT_AURA", "player")
Tick()
assert(scans == before and not frame.shown, "Disabled refresh requests must leave the updater idle")

mana = 75
ErzbaroneUISettings.castCount = true
castCount:Update()
assert(button.ErzbaroneUICastCount == label and label.shown and label.text == 3,
    "Re-enabling must reuse and refresh existing labels")
before = scans
castCount:Initialize()
castCount:Initialize()
Tick()
assert(#frames == 1 and scans == before + 1, "Repeated initialization must reuse and coalesce the updater")

for action = 2, 7 do
    buttons[#buttons + 1] = { action = action, CreateFontString = button.CreateFontString }
end
mana = 100
costReadsBySpell = {}
previousCosts = costReads
castCount:Update()
assert(costReads == previousCosts + 4, "Each distinct spell must have only one cost query per refresh")
assert(costReadsBySpell[123] == 1, "A macro and a direct spell must share the same cost query")
assert(label.text == 4 and buttons[2].ErzbaroneUICastCount.text == 4
    and buttons[3].ErzbaroneUICastCount.text == 10, "Shared costs must preserve each button's count")
assert(costReadsBySpell[789] == 1 and costReadsBySpell[999] == 1,
    "Zero-cost and unavailable cost results must also be reused")
assert(not buttons[4].ErzbaroneUICastCount and not buttons[6].ErzbaroneUICastCount,
    "Spells without mana costs must not create labels")

spellCosts[123] = 0
frame:OnEvent("UNIT_AURA", "player")
Tick()
assert(not label.shown and not buttons[2].ErzbaroneUICastCount.shown,
    "A spell becoming free must hide both direct and macro labels on the next refresh")
spellCosts[123] = 20
frame:OnEvent("UNIT_AURA", "player")
Tick()
assert(label.shown and label.text == 5 and buttons[2].ErzbaroneUICastCount.text == 5,
    "Costs must be queried afresh each refresh, including previously free spells")

print("castcount_test.lua: all assertions passed")
