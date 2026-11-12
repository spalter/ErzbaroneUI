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
local backgrounds = {}
local originalSlotArt = {}
local hookedButtons = {}
local warnedSlotArt = {}

--- Keeps textured slots visible after native artwork updates while mouseover fading is enabled.
local function ApplySlotArt(button)
    if ErzbaroneUISettings.fadeRightBars and originalSlotArt[button] then
        button.SlotArt:Show()
        button.SlotBackground:Hide()
    end
end

--- Saves native slot visibility and hooks ready buttons, retrying artwork that loads later.
local function UpdateSlotArt(bar)
    local ready = bar.actionButtons and #bar.actionButtons > 0
    for _, button in ipairs(bar.actionButtons or {}) do
        if not button.SlotArt or not button.SlotBackground then
            ready = false
        elseif not originalSlotArt[button] then
            originalSlotArt[button] = {
                artShown = button.SlotArt:IsShown(),
                backgroundShown = button.SlotBackground:IsShown(),
            }
            if not hookedButtons[button] then
                hookedButtons[button] = true
                hooksecurefunc(button, "UpdateButtonArt", ApplySlotArt)
            end
            ApplySlotArt(button)
        end
    end
    if not ready and not warnedSlotArt[bar] then
        warnedSlotArt[bar] = true
        print("ErzbaroneUI: Vertical action-button slot artwork is not ready. It will be retried on the next fade update.")
    end
end

--- Reuses the main-bar backdrop as a child texture so it inherits the vertical bar's fade.
local function UpdateBackground(bar, enabled)
    local background = backgrounds[bar]
    if enabled and not background then
        background = bar:CreateTexture(nil, "BACKGROUND", nil, -3)
        background:SetAtlas("UI-HUD-ActionBar-Frame")
        background:SetPoint("TOPLEFT", bar, "TOPLEFT", -6, 6)
        background:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 4, -5)
        backgrounds[bar] = background
        bar:SetAlpha(currentAlpha)
    end
    if background then
        background:SetShown(enabled)
    end
end

--- Returns the right-side action bars that currently exist and are shown.
local function GetBars()
    local bars = {}
    for _, name in ipairs(BAR_NAMES) do
        local bar = _G[name]
        if bar then
            UpdateSlotArt(bar)
            if not backgrounds[bar] then
                UpdateBackground(bar, true)
            end
            if bar:IsShown() then
                table.insert(bars, bar)
            end
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
    currentAlpha = 1
    if not ErzbaroneUISettings.fadeRightBars then
        for button, state in pairs(originalSlotArt) do
            button.SlotArt:SetShown(state.artShown)
            button.SlotBackground:SetShown(state.backgroundShown)
        end
        originalSlotArt = {}
    end
    for _, name in ipairs(BAR_NAMES) do
        local bar = _G[name]
        if bar then
            UpdateBackground(bar, ErzbaroneUISettings.fadeRightBars)
            if ErzbaroneUISettings.fadeRightBars then
                UpdateSlotArt(bar)
            end
        end
    end
    SetBarsAlpha(1)
    if ErzbaroneUISettings.fadeRightBars then
        updater:SetScript("OnUpdate", OnUpdate)
    else
        updater:SetScript("OnUpdate", nil)
    end
end

--- Applies the current right-bar fade setting.
function ErzbaroneUI.BarFade:Initialize()
    self:Update()
end
