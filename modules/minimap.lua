if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Minimap = {}

-- Height of the removed header; the minimap moves up (or down when the header is underneath) by this amount.
local HEADER_OFFSET = 24
-- Distance of the buttons from the minimap center, places them on the minimap border ring.
local BUTTON_RADIUS = 104

-- Angles in degrees (0 = right, 90 = top). The day/night indicator sits top right (~57°),
-- the zoom buttons bottom right and the event/landing page buttons on the left side.
-- The square buttons follow the day/night indicator clockwise.
local BUTTON_ANGLES = {
    Indicator = 115,
    Tracking = 34,
    Calendar = 17,
    AddonCompartment = 0,
}

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

local originalStates = {}
local applied = false
local zoneLabel

--- Returns whether compact minimap mode is enabled.
local function IsEnabled()
    return ErzbaroneUISettings and ErzbaroneUISettings.compactMinimap
end

--- Returns the current Edit Mode setting for the minimap header position.
local function IsHeaderUnderneath()
    if MinimapCluster.GetSettingValueBool and Enum.EditModeMinimapSetting then
        return MinimapCluster:GetSettingValueBool(Enum.EditModeMinimapSetting.HeaderUnderneath) and true or false
    end
    return false
end

--- Stores parent, frame level and anchors of a frame once, so it can be restored later.
local function SaveState(frame)
    if not frame or originalStates[frame] then
        return
    end
    local points = {}
    for i = 1, frame:GetNumPoints() do
        points[i] = { frame:GetPoint(i) }
    end
    originalStates[frame] = {
        parent = frame:GetParent(),
        level = frame:GetFrameLevel(),
        points = points,
    }
end

--- Restores the saved parent, frame level and anchors of every moved minimap frame.
local function RestoreStates()
    for frame, state in pairs(originalStates) do
        frame:SetParent(state.parent)
        frame:SetFrameLevel(state.level)
        frame:ClearAllPoints()
        for _, point in ipairs(state.points) do
            frame:SetPoint(unpack(point))
        end
    end
    originalStates = {}
end

--- Moves a frame into the minimap container and places it on the border ring at the given angle.
local function PlaceOnRing(frame, angle)
    if not frame then
        return
    end
    SaveState(frame)

    local container = MinimapCluster.MinimapContainer
    local radians = math.rad(angle)
    frame:SetParent(container)
    frame:SetFrameLevel(container:GetFrameLevel() + 10)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", Minimap, "CENTER", BUTTON_RADIUS * math.cos(radians), BUTTON_RADIUS * math.sin(radians))
end

--- Moves the server clock into the minimap container below the map.
local function PlaceClock()
    local clock = TimeManagerClockButton
    if not clock then
        return
    end
    SaveState(clock)

    local container = MinimapCluster.MinimapContainer
    clock:SetParent(container)
    clock:SetFrameLevel(container:GetFrameLevel() + 10)
    clock:ClearAllPoints()
    clock:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 8)
end

--- Repositions the minimap container to account for the removed header.
local function PlaceMinimap()
    local container = MinimapCluster.MinimapContainer
    local scale = container:GetScale()
    container:ClearAllPoints()
    if IsHeaderUnderneath() then
        container:SetPoint("BOTTOM", MinimapCluster, "BOTTOM", 10 / scale, (30 - HEADER_OFFSET) / scale)
    else
        container:SetPoint("TOP", MinimapCluster, "TOP", 10 / scale, (-30 + HEADER_OFFSET) / scale)
    end
end

--- Shows the zone name at the top of the minimap while it is hovered, since the header is gone.
local function SetupZoneLabel()
    if zoneLabel then
        return
    end
    zoneLabel = Minimap:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zoneLabel:SetPoint("TOP", Minimap, "TOP", 0, -14)
    zoneLabel:SetWidth(150)
    zoneLabel:SetShadowOffset(1, -1)
    zoneLabel:Hide()

    Minimap:HookScript("OnEnter", function()
        if applied and MinimapZoneText then
            zoneLabel:SetText(MinimapZoneText:GetText())
            zoneLabel:SetTextColor(MinimapZoneText:GetTextColor())
            zoneLabel:Show()
        end
    end)
    Minimap:HookScript("OnLeave", function()
        zoneLabel:Hide()
    end)
end

--- Removes the header and places all its buttons on the minimap.
local function Apply()
    if InCombatLockdown() then
        ErzbaroneUI.Minimap.PendingUpdate = true
        return
    end

    local cluster = MinimapCluster
    SaveState(cluster.ZoneTextButton)
    cluster.ZoneTextButton:SetParent(hiddenParent)

    PlaceMinimap()
    PlaceOnRing(cluster.Tracking, BUTTON_ANGLES.Tracking)
    PlaceOnRing(cluster.IndicatorFrame, BUTTON_ANGLES.Indicator)
    PlaceOnRing(GameTimeFrame, BUTTON_ANGLES.Calendar)
    PlaceOnRing(AddonCompartmentFrame, BUTTON_ANGLES.AddonCompartment)
    PlaceClock()
    SetupZoneLabel()

    applied = true
end

--- Puts every frame back to where Blizzard had it.
local function Restore()
    if InCombatLockdown() then
        ErzbaroneUI.Minimap.PendingUpdate = true
        return
    end

    RestoreStates()
    applied = false
    if zoneLabel then
        zoneLabel:Hide()
    end
    -- Lets Blizzard re-anchor the minimap container and header for the current Edit Mode layout
    MinimapCluster:SetHeaderUnderneath(IsHeaderUnderneath())
end

--- Applies or restores the compact minimap based on the current setting.
local FADE_SPEED = 6 -- alpha per second
local fader = CreateFrame("Frame")
local fadeAlpha = 1

local function SetButtonAlpha(button, alpha)
    if button and button:GetAlpha() ~= alpha then
        button:SetAlpha(alpha)
    end
end

--- Sets the alpha of each minimap button controlled by the fade feature.
local function SetButtonsAlpha(alpha, hasInvites)
    SetButtonAlpha(MinimapCluster.Tracking, alpha)
    SetButtonAlpha(GameTimeFrame, hasInvites and 1 or alpha)
    SetButtonAlpha(AddonCompartmentFrame, alpha)
end

--- Returns whether a button currently has its dropdown menu open.
local function IsMenuOpen(button)
    return button and button.IsMenuOpen and button:IsMenuOpen()
end

--- Buttons stay visible while the minimap or a button is hovered, a dropdown is open or Edit Mode is active.
local function ShouldShowButtons()
    if MinimapCluster.MinimapContainer:IsMouseOver() then
        return true
    end
    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
        return true
    end
    if IsMenuOpen(MinimapCluster.Tracking.Button) or IsMenuOpen(AddonCompartmentFrame) then
        return true
    end
    return MinimapCluster.Tracking:IsMouseOver()
        or (GameTimeFrame and GameTimeFrame:IsMouseOver())
        or (AddonCompartmentFrame and AddonCompartmentFrame:IsMouseOver())
end

--- Updates minimap button alpha while preserving visibility for pending invites.
local function OnFadeUpdate(_, elapsed)
    -- Pending calendar invites should never be hidden
    local hasInvites = GameTimeCalendarInvitesTexture and GameTimeCalendarInvitesTexture:IsShown()

    local target = ShouldShowButtons() and 1 or 0
    if fadeAlpha < target then
        fadeAlpha = math.min(target, fadeAlpha + FADE_SPEED * elapsed)
    else
        fadeAlpha = math.max(target, fadeAlpha - FADE_SPEED * elapsed)
    end
    SetButtonsAlpha(fadeAlpha, hasInvites)
end

--- Resets button visibility and enables or disables the minimap fade updater.
local function UpdateButtonFade()
    fadeAlpha = 1
    SetButtonsAlpha(1)
    if ErzbaroneUISettings.fadeMinimapButtons then
        fader:SetScript("OnUpdate", OnFadeUpdate)
    else
        fader:SetScript("OnUpdate", nil)
    end
end

--- Applies the compact minimap and button-fade settings.
function ErzbaroneUI.Minimap:Update()
    if IsEnabled() then
        Apply()
    elseif applied then
        Restore()
    end
    UpdateButtonFade()
end

--- Re-applies the layout after Blizzard re-anchored parts of the minimap.
local function Reapply()
    if applied and IsEnabled() then
        Apply()
    end
end

--- Hooks minimap layout changes and initializes deferred updates.
function ErzbaroneUI.Minimap:Initialize()
    if not MinimapCluster or not MinimapCluster.MinimapContainer then
        return
    end

    if not self.Initialized then
        self.Initialized = true

        -- Edit Mode re-anchors the container, header, mail indicator and addon compartment
        hooksecurefunc(MinimapCluster, "SetHeaderUnderneath", Reapply)
        hooksecurefunc(MinimapCluster, "SetEditModeScale", Reapply)
        if MiniMapIndicatorFrame_UpdatePosition then
            hooksecurefunc("MiniMapIndicatorFrame_UpdatePosition", Reapply)
        end

        local eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("ADDON_LOADED")
        eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        eventFrame:SetScript("OnEvent", function(_, event, name)
            if event == "ADDON_LOADED" and name == "Blizzard_TimeManager" then
                Reapply()
            elseif event == "PLAYER_REGEN_ENABLED" and self.PendingUpdate then
                self.PendingUpdate = false
                self:Update()
            end
        end)
    end

    self:Update()
end
