if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.CastCount = {}

local MANA = (Enum and Enum.PowerType and Enum.PowerType.Mana) or 0

--- Returns the action slot currently shown by the given action button.
local function GetButtonAction(button)
    if button.CalculateAction then
        return button:CalculateAction()
    end
    return button.action
end

--- Returns the spell ID behind an action slot (spells and macros).
local function GetActionSpellID(action)
    if not action or not C_ActionBar.HasAction(action) then
        return nil
    end

    local actionType, id = GetActionInfo(action)
    if actionType == "spell" then
        return id
    elseif actionType == "macro" then
        return GetMacroSpell(id)
    end
    return nil
end

--- Returns the mana cost of a spell or nil if it doesn't cost mana.
local function GetManaCost(spellID)
    local costs = C_Spell.GetSpellPowerCost(spellID)
    if not costs then
        return nil
    end

    for _, cost in ipairs(costs) do
        if cost.type == MANA then
            local amount = cost.cost or cost.minCost or 0
            if amount > 0 then
                return amount
            end
        end
    end
    return nil
end

--- Returns the cast count label of a button, creating it on first use.
local function GetLabel(button)
    if not button.ErzbaroneUICastCount then
        local label = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        label:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, 2)
        label:SetJustifyH("LEFT")
        button.ErzbaroneUICastCount = label
    end
    return button.ErzbaroneUICastCount
end

--- Returns true if the value is a secret this addon is not allowed to operate on (e.g. mana in combat).
local function IsSecret(value)
    if canaccessvalue then
        return not canaccessvalue(value)
    end
    return issecretvalue and issecretvalue(value) or false
end

-- Max mana and step curves are cached so counts still work while values are secret.
local MAX_CURVE_STEPS = 500
local cachedMaxMana = nil
local curves = {}

--- Refreshes the cached max mana when it is accessible and drops outdated curves.
local function RefreshMaxMana()
    local maxMana = UnitPowerMax("player", MANA)
    if IsSecret(maxMana) or maxMana == cachedMaxMana then
        return
    end
    cachedMaxMana = maxMana
    curves = {}
end

--- Builds a staircase curve which maps the mana percentage (0..1) to the number of possible casts.
--- Every step is flat and only jumps between two integer mana values, so the result is always a whole number.
local function GetCastCountCurve(cost)
    if curves[cost] then
        return curves[cost]
    end
    if not cachedMaxMana or cachedMaxMana <= 0 or not (C_CurveUtil and C_CurveUtil.CreateCurve) then
        return nil
    end

    local curve = C_CurveUtil.CreateCurve()
    curve:SetType(Enum.LuaCurveType.Linear)
    local steps = math.min(math.floor(cachedMaxMana / cost), MAX_CURVE_STEPS)
    for k = 0, steps do
        curve:AddPoint(k * cost / cachedMaxMana, k)
        if k < steps then
            curve:AddPoint(((k + 1) * cost - 0.5) / cachedMaxMana, k)
        end
    end

    curves[cost] = curve
    return curve
end

--- Returns how often a spell with the given cost can be cast. The result may be a secret number,
--- which can still be displayed through FontString:SetText.
local function GetCastCount(mana, cost)
    if not IsSecret(mana) then
        return math.floor(mana / cost)
    end

    local curve = GetCastCountCurve(cost)
    if curve and UnitPowerPercent then
        return UnitPowerPercent("player", MANA, false, curve)
    end
    return nil
end

--- Updates the cast count label of a single action button.
local function UpdateButton(button, mana)
    local label = button.ErzbaroneUICastCount
    local action = GetButtonAction(button)
    local spellID = ErzbaroneUISettings.castCount and GetActionSpellID(action)
    local cost = spellID and GetManaCost(spellID)
    local count = cost and GetCastCount(mana, cost)

    if not count then
        if label then
            label:Hide()
        end
        return
    end

    label = GetLabel(button)
    label:SetText(count)
    local _, notEnoughMana = C_ActionBar.IsUsableAction(action)
    if notEnoughMana then
        label:SetTextColor(1, 0.1, 0.1)
    else
        label:SetTextColor(0.6, 0.8, 1)
    end
    label:Show()
end

--- Updates the cast count labels on all action buttons.
function ErzbaroneUI.CastCount:Update()
    RefreshMaxMana()
    local mana = UnitPower("player", MANA)
    ErzbaroneUI.Utils:ForEachActionButton(function(button)
        UpdateButton(button, mana)
    end)
end

--- Schedules an update on the next frame so Blizzard can refresh the buttons first.
function ErzbaroneUI.CastCount:RequestUpdate()
    if self.EventFrame then
        self.EventFrame:Show()
    end
end

--- Registers the events which can change mana, spell costs or button contents.
function ErzbaroneUI.CastCount:Initialize()
    if self.EventFrame then
        self:RequestUpdate()
        return
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:Hide()
    eventFrame:SetScript("OnUpdate", function(frame)
        frame:Hide()
        ErzbaroneUI.CastCount:Update()
    end)
    eventFrame:SetScript("OnEvent", function()
        ErzbaroneUI.CastCount:RequestUpdate()
    end)

    eventFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    eventFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    eventFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
    eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
    for _, event in ipairs({
        "ACTIONBAR_SLOT_CHANGED",
        "ACTIONBAR_PAGE_CHANGED",
        "UPDATE_BONUS_ACTIONBAR",
        "UPDATE_SHAPESHIFT_FORM",
        "SPELLS_CHANGED",
        "UPDATE_MACROS",
        "PLAYER_EQUIPMENT_CHANGED",
    }) do
        pcall(eventFrame.RegisterEvent, eventFrame, event)
    end

    self.EventFrame = eventFrame
    self:RequestUpdate()
end
