if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.CastBars = {}

-- Classic cast bar colors, used if Blizzard's constants are missing.
local FALLBACK_FILL_COLOR = CreateColor(1, 0.7, 0)
local FALLBACK_FULL_COLOR = CreateColor(0, 1, 0)

local CAST_BAR_NAMES = {
    "PlayerCastingBarFrame",
    "PetCastingBarFrame",
    "TargetFrameSpellBar",
    "FocusFrameSpellBar",
}

local hookedBars = {}

--- Returns the configured cast-bar texture path, or nil for Blizzard's default.
local function GetTexturePath()
    return ErzbaroneUI.StatusBars:GetTexturePath(ErzbaroneUISettings and ErzbaroneUISettings.castBarTexture)
end

--- Replaces the atlas Blizzard just applied with the selected texture, colored like the classic cast bars.
local function ApplyTexture(bar, isFull)
    local path = GetTexturePath()
    if not path then
        return
    end

    -- Casts of other units can be secret; keep Blizzard's atlas then, so channel and uninterruptible casts stay recognizable
    local barType = bar.barType
    if not canaccessvalue(barType) or not canaccessvalue(isFull) then
        return
    end

    local info = CastingBarTypeInfo and CastingBarTypeInfo[barType or "standard"]
    local color
    if info then
        color = isFull and info.classicFullColor or info.classicFillColor
    end
    color = color or (isFull and FALLBACK_FULL_COLOR or FALLBACK_FILL_COLOR)

    bar:SetStatusBarTexture(path)
    bar:SetStatusBarColor(color:GetRGB())
end

--- Hooks each available cast bar so its fill texture can use the configured style.
local function HookBars()
    for _, name in ipairs(CAST_BAR_NAMES) do
        local bar = _G[name]
        if bar and not hookedBars[bar] and bar.UpdateBarFillTexture then
            hookedBars[bar] = true
            hooksecurefunc(bar, "UpdateBarFillTexture", ApplyTexture)
        end
    end
end

--- The new texture is applied with the next cast, so a running cast is never touched.
function ErzbaroneUI.CastBars:Update()
    HookBars()
end

--- Installs cast-bar texture hooks.
function ErzbaroneUI.CastBars:Initialize()
    HookBars()
end
