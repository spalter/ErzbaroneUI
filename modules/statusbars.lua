if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.StatusBars = {}

-- Textures shipped with the game client, plus a slot for a texture placed inside the addon folder.
local TEXTURES = {
    { "blizzard", "Blizzard (default)" },
    { "classic", "Classic", "Interface\\TargetingFrame\\UI-StatusBar" },
    { "smooth", "Smooth", "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" },
    { "skills", "Skills", "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar" },
    { "custom", "Custom (textures\\statusbar)", "Interface\\AddOns\\ErzbaroneUI\\textures\\statusbar" },
}

local HEALTH_COLOR = { 0, 1, 0 }
local DISCONNECTED_COLOR = { 0.5, 0.5, 0.5 }
local TAPPED_COLOR = { 0.5, 0.5, 0.5 }
local DEFAULT_POWER_COLOR = { 0, 0, 1 }

-- Blizzard atlas and color of each bar before it was replaced, used to restore the default look.
local originals = {}

-- Health bars whose Blizzard atlas was desaturated to show a class color.
local tinted = {}

--- Returns the currently configured unit-frame bar texture path.
local function GetTexturePath()
    return ErzbaroneUI.StatusBars:GetTexturePath(ErzbaroneUISettings and ErzbaroneUISettings.unitFrameTexture)
end

--- Returns the file path of a texture option, or nil for Blizzard's default textures.
function ErzbaroneUI.StatusBars:GetTexturePath(selected)
    for _, texture in ipairs(TEXTURES) do
        if texture[1] == selected then
            return texture[3]
        end
    end
    return nil
end

--- Returns the dropdown options as { value, label } pairs.
function ErzbaroneUI.StatusBars:GetTextureOptions()
    return TEXTURES
end

--- Only the classic unit frames are changed; raid frames and nameplates keep their own textures.
local function IsManagedFrame(frame)
    if not frame then
        return false
    end
    if frame == PlayerFrame or frame == PetFrame or frame == TargetFrame or frame == FocusFrame then
        return true
    end
    if (TargetFrame and frame == TargetFrame.totFrame) or (FocusFrame and frame == FocusFrame.totFrame) then
        return true
    end
    return PartyFrame ~= nil and frame:GetParent() == PartyFrame
end

--- Remembers the atlas Blizzard just applied, so it can be restored later.
local function SaveOriginal(bar)
    local texture = bar:GetStatusBarTexture()
    local atlas = texture and texture:GetAtlas()
    if atlas then
        local r, g, b = bar:GetStatusBarColor()
        originals[bar] = { atlas = atlas, r = r, g = g, b = b }
    end
end

--- Accepts both { r, g, b } arrays and class color objects with r/g/b fields.
local function SetBarColor(bar, color)
    bar:SetStatusBarColor(color.r or color[1], color.g or color[2], color.b or color[3])
end

--- Returns the value only if it is not a secret value hidden from addons.
local function Readable(value)
    if canaccessvalue and not canaccessvalue(value) then
        return nil
    end
    return value
end

--- Returns the class color for players, grey for creatures tapped by someone else, or nil for the default color.
local function GetUnitHealthColor(bar)
    if not ErzbaroneUISettings.unitClassColors or bar.disconnected then
        return nil
    end
    local unit = bar.unit or (bar.unitFrame and bar.unitFrame.unit)
    if not unit or not UnitExists(unit) then
        return nil
    end

    if Readable(UnitIsPlayer(unit)) then
        local _, class = UnitClass(unit)
        class = Readable(class)
        return class and RAID_CLASS_COLORS[class] or nil
    end
    if not Readable(UnitPlayerControlled(unit)) and Readable(UnitIsTapDenied(unit)) then
        return TAPPED_COLOR
    end
    return nil
end

--- Applies the selected texture and configured health color to a health bar.
local function ApplyHealth(bar)
    if not bar then
        return
    end
    local path = GetTexturePath()
    local classColor = GetUnitHealthColor(bar)
    local texture = bar:GetStatusBarTexture()

    if path then
        SaveOriginal(bar)
        bar:SetStatusBarTexture(path)
        if tinted[bar] and texture then
            texture:SetDesaturated(false)
            tinted[bar] = nil
        end
        SetBarColor(bar, classColor or (bar.disconnected and DISCONNECTED_COLOR) or HEALTH_COLOR)
    elseif classColor and texture then
        -- Blizzard's health atlas is green itself, so it has to lose its color before it can be tinted
        texture:SetDesaturated(true)
        tinted[bar] = true
        SetBarColor(bar, classColor)
    elseif tinted[bar] then
        if texture then
            texture:SetDesaturated(false)
        end
        tinted[bar] = nil
        SetBarColor(bar, bar.disconnected and DISCONNECTED_COLOR or HEALTH_COLOR)
    end
end

--- Applies the selected texture and power-type color to a unit power bar.
local function ApplyPower(bar)
    local path = GetTexturePath()
    if not bar or not path or not bar.unit then
        return
    end
    SaveOriginal(bar)
    bar:SetStatusBarTexture(path)

    if bar.disconnected then
        bar:SetStatusBarColor(DISCONNECTED_COLOR[1], DISCONNECTED_COLOR[2], DISCONNECTED_COLOR[3])
        return
    end

    local _, powerToken, altR, altG, altB = UnitPowerType(bar.unit)
    local info = powerToken and PowerBarColor[powerToken]
    if info then
        bar:SetStatusBarColor(info.r, info.g, info.b)
    elseif altR then
        bar:SetStatusBarColor(altR, altG, altB)
    else
        bar:SetStatusBarColor(DEFAULT_POWER_COLOR[1], DEFAULT_POWER_COLOR[2], DEFAULT_POWER_COLOR[3])
    end
end

--- Updates the health and power bars of a managed unit frame.
local function ApplyFrame(frame)
    if not IsManagedFrame(frame) then
        return
    end
    ApplyHealth(frame.healthbar)
    ApplyPower(frame.manabar)
end

--- Collects the supported player, pet, target, focus and party frames.
local function GetManagedFrames()
    local frames = { PlayerFrame, PetFrame, TargetFrame, FocusFrame }
    if TargetFrame and TargetFrame.totFrame then
        table.insert(frames, TargetFrame.totFrame)
    end
    if FocusFrame and FocusFrame.totFrame then
        table.insert(frames, FocusFrame.totFrame)
    end
    if PartyFrame and PartyFrame.PartyMemberFramePool then
        for memberFrame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
            table.insert(frames, memberFrame)
        end
    end
    return frames
end

--- Restores each tracked bar's original atlas and color.
local function RestoreAll()
    for bar, original in pairs(originals) do
        bar:SetStatusBarTexture(original.atlas)
        bar:SetStatusBarColor(original.r, original.g, original.b)
    end
    originals = {}
end

--- Applies the selected texture and health colors to all unit frame bars, or restores Blizzard's textures.
function ErzbaroneUI.StatusBars:Update()
    if not GetTexturePath() then
        RestoreAll()
    end
    for _, frame in ipairs(GetManagedFrames()) do
        ApplyFrame(frame)
    end
end

--- Hooks Blizzard unit-frame updates and applies the configured bar style.
function ErzbaroneUI.StatusBars:Initialize()
    if not self.Initialized then
        self.Initialized = true

        -- Blizzard re-applies its atlases whenever a frame updates, its power type or its classification changes
        hooksecurefunc("UnitFrame_Update", ApplyFrame)
        hooksecurefunc("UnitFrameHealthBar_Update", function(bar)
            if bar and IsManagedFrame(bar.unitFrame) then
                ApplyHealth(bar)
            end
        end)
        hooksecurefunc("UnitFrameManaBar_UpdateType", function(bar)
            if bar and IsManagedFrame(bar.unitFrame) then
                ApplyPower(bar)
            end
        end)
        for _, frame in ipairs({ TargetFrame, FocusFrame }) do
            if frame and frame.UpdateHealthBarVisuals then
                hooksecurefunc(frame, "UpdateHealthBarVisuals", function(unitFrame)
                    ApplyHealth(unitFrame.healthbar)
                end)
            end
            -- Fires when the target gets tapped by someone else
            if frame and frame.CheckFaction then
                hooksecurefunc(frame, "CheckFaction", function(unitFrame)
                    ApplyHealth(unitFrame.healthbar)
                end)
            end
        end
    end

    self:Update()
end
