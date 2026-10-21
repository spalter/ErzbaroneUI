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
local DEFAULT_POWER_COLOR = { 0, 0, 1 }

-- Blizzard atlas and color of each bar before it was replaced, used to restore the default look.
local originals = {}

local function GetTexturePath()
    local selected = ErzbaroneUISettings and ErzbaroneUISettings.unitFrameTexture
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

local function ApplyHealth(bar)
    local path = GetTexturePath()
    if not bar or not path then
        return
    end
    SaveOriginal(bar)
    bar:SetStatusBarTexture(path)
    local color = bar.disconnected and DISCONNECTED_COLOR or HEALTH_COLOR
    bar:SetStatusBarColor(color[1], color[2], color[3])
end

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

local function ApplyFrame(frame)
    if not IsManagedFrame(frame) then
        return
    end
    ApplyHealth(frame.healthbar)
    ApplyPower(frame.manabar)
end

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

local function RestoreAll()
    for bar, original in pairs(originals) do
        bar:SetStatusBarTexture(original.atlas)
        bar:SetStatusBarColor(original.r, original.g, original.b)
    end
    originals = {}
end

--- Applies the selected texture to all unit frame bars, or restores Blizzard's textures.
function ErzbaroneUI.StatusBars:Update()
    if GetTexturePath() then
        for _, frame in ipairs(GetManagedFrames()) do
            ApplyFrame(frame)
        end
    else
        RestoreAll()
    end
end

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
        end
    end

    self:Update()
end
