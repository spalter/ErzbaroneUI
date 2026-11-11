if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.BarFade = {}

-- The vertical bars on the right side of the screen ("Action Bar 4" and "Action Bar 5").
local BAR_NAMES = { "MultiBarRight", "MultiBarLeft" }

local FADE_SPEED = 6 -- alpha per second
local HIDDEN_ALPHA = 0

local updater = CreateFrame("Frame")
local currentAlpha = 1

--- Returns the right-side action bars that currently exist and are shown.
local function GetBars()
    local bars = {}
    for _, name in ipairs(BAR_NAMES) do
        local bar = _G[name]
        if bar and bar:IsShown() then
            table.insert(bars, bar)
        end
    end
    return bars
end

--- Sets the alpha of both right-side action bars.
local function SetBarsAlpha(alpha)
    for _, name in ipairs(BAR_NAMES) do
        local bar = _G[name]
        if bar then
            bar:SetAlpha(alpha)
        end
    end
end

--- The bars stay visible while hovered, while placing an action on them or while Edit Mode is open.
local function ShouldShow(bars)
    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
        return true
    end
    if GetCursorInfo() then
        return true
    end
    if SpellFlyout and SpellFlyout:IsShown() and SpellFlyout:IsMouseOver() then
        return true
    end
    for _, bar in ipairs(bars) do
        if bar:IsMouseOver() then
            return true
        end
    end
    return false
end

--- Fades the right-side bars toward their hover-dependent target alpha.
local function OnUpdate(_, elapsed)
    local bars = GetBars()
    if #bars == 0 then
        return
    end

    local target = ShouldShow(bars) and 1 or HIDDEN_ALPHA
    if currentAlpha == target then
        return
    end

    if currentAlpha < target then
        currentAlpha = math.min(target, currentAlpha + FADE_SPEED * elapsed)
    else
        currentAlpha = math.max(target, currentAlpha - FADE_SPEED * elapsed)
    end
    SetBarsAlpha(currentAlpha)
end

--- Enables or disables the mouseover fade based on the current setting.
function ErzbaroneUI.BarFade:Update()
    if ErzbaroneUISettings.fadeRightBars then
        currentAlpha = 1
        updater:SetScript("OnUpdate", OnUpdate)
    else
        updater:SetScript("OnUpdate", nil)
        currentAlpha = 1
        SetBarsAlpha(1)
    end
end

--- Applies the current right-bar fade setting.
function ErzbaroneUI.BarFade:Initialize()
    self:Update()
end
