if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.ActionLayout = {}

local GAP = 4
local BACKGROUND_BOTTOM_OVERHANG = 5
local CAST_BAR_GAP = 32
local customBarsApplied = false
local hookedFrames = {}
local customBars = {}
local originalContainers = {}
local originalSelections = {}
local originalDividers = {}
local originalStatusBars = {}
local originalAuxiliaryBars = {}
local auxiliaryAnchors = {}
local originalCastBar
local originalMainBar
local originalSlotArt = {}
local originalBorderArtShown
local originalEndCaps = {}
local originalPageNumberParent
local originalPageNumberPoints
local resizingStatusBar = false
local positioningFrame = false
local lastError
local warnedSelection = false

--- Prints a layout error only when its message changes and reports failure.
local function ReportError(message)
    if lastError ~= message then
        lastError = message
        print("ErzbaroneUI: " .. message)
    end
    return false
end

--- Returns the three native action bars used by the compact layout.
local function GetBars()
    return { MainActionBar, MultiBarBottomLeft, MultiBarBottomRight }
end

--- Returns the primary and secondary status tracking bars.
local function GetStatusBars()
    return { SecondaryStatusTrackingBarContainer, MainStatusTrackingBarContainer }
end

--- Returns the stance, pet, possession and vehicle-exit bars.
local function GetAuxiliaryBars()
    return { StanceBar, PetActionBar, PossessActionBar, MainMenuBarVehicleLeaveButton }
end

--- Copies every anchor point from a frame so its layout can be restored.
local function GetPoints(frame)
    local points = {}
    for index = 1, frame:GetNumPoints() do
        table.insert(points, { frame:GetPoint(index) })
    end
    return points
end

--- Replaces a frame's anchor points with a previously saved set.
local function SetPoints(frame, points)
    local clear = frame.ClearAllPointsBase or frame.ClearAllPoints
    local setPoint = frame.SetPointBase or frame.SetPoint
    clear(frame)
    for _, point in ipairs(points) do
        setPoint(frame, unpack(point))
    end
end

--- Calculates the scaled width and height of an action-bar row.
local function GetRowSize(bar, columns)
    local button = bar.actionButtons[1].container
    local scale = bar:GetScale()
    local width = button:GetWidth() * button:GetScale()
    local height = button:GetHeight() * button:GetScale()
    local padding = math.max(bar.minButtonPadding, bar.buttonPadding)
    return (columns * width + (columns - 1) * padding) * scale, height * scale
end

--- Resizes a status bar and refreshes its containers, dividers and tick.
local function ResizeStatusBar(bar, width)
    if resizingStatusBar then
        return
    end
    resizingStatusBar = true
    bar:SetWidth(width)
    bar.BarFrameTexture:SetWidth(width)
    bar:ResizeContainerBars()
    bar:UpdateDividers(bar:GetExpectedSegments())
    bar:UpdateBarTick()
    resizingStatusBar = false
end

--- Hides native action-bar dividers while retaining their original alpha.
local function HideNativeDividers()
    for _, pool in pairs({ MainActionBar.HorizontalDividersPool, MainActionBar.VerticalDividersPool }) do
        for divider in pool:EnumerateActive() do
            if originalDividers[divider] == nil then
                originalDividers[divider] = divider:GetAlpha()
            end
            divider:SetAlpha(0)
        end
    end
end

--- Keeps an already-customized status bar at its calculated width.
local function MaintainStatusBarSize(bar)
    local state = originalStatusBars[bar]
    if resizingStatusBar or not customBarsApplied or not state then
        return
    end
    if InCombatLockdown() then
        ErzbaroneUI.MainBar.PendingUpdate = true
        return
    end
    ResizeStatusBar(bar, state.customWidth)
end

--- Restores a custom anchor unless combat prevents moving a protected frame.
local function MaintainPosition(bar, state)
    if positioningFrame or not customBarsApplied or not state or not state.customPoints then
        return
    end
    -- XP/reputation containers are normally unprotected and can retain their anchors in combat.
    if InCombatLockdown() and bar:IsProtected() then
        ErzbaroneUI.MainBar.PendingUpdate = true
        return
    end
    positioningFrame = true
    SetPoints(bar, state.customPoints)
    positioningFrame = false
end

--- Reapplies the compact-layout anchor for a status bar.
local function MaintainStatusBarPosition(bar)
    MaintainPosition(bar, originalStatusBars[bar])
end

--- Reapplies the compact-layout anchor for an auxiliary action bar.
local function MaintainAuxiliaryBarPosition(bar)
    MaintainPosition(bar, originalAuxiliaryBars[bar])
end

--- Reapplies the compact-layout anchor for the player cast bar.
local function MaintainCastBarPosition(bar)
    MaintainPosition(bar, originalCastBar)
end

--- Reapplies the compact-layout anchor for a main action-bar end cap.
local function MaintainEndCapPosition(cap)
    MaintainPosition(cap, originalEndCaps[cap])
end

--- Restores the player cast bar's original anchors.
local function RestoreCastBar()
    if originalCastBar then
        local points = originalCastBar.points
        originalCastBar = nil
        SetPoints(PlayerCastingBarFrame, points)
    end
end

--- Places the player cast bar above the compact action and status bars.
local function ApplyCastBar(top)
    if not MultiBarBottomLeft:IsShown() and not MultiBarBottomRight:IsShown() then
        RestoreCastBar()
        return
    end
    if not originalCastBar then
        originalCastBar = { points = GetPoints(PlayerCastingBarFrame) }
    end
    local scale = PlayerCastingBarFrame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    originalCastBar.customPoints = {
        { "BOTTOM", UIParent, "BOTTOM", 0, (top + CAST_BAR_GAP) / scale },
    }
    MaintainCastBarPosition(PlayerCastingBarFrame)
end

--- Shows the slot art and hides the background for a customized button.
local function ApplySlotArt(button)
    if customBarsApplied and originalSlotArt[button] then
        button.SlotArt:Show()
        button.SlotBackground:Hide()
    end
end

--- Returns custom action bars, button containers and related art to native state.
local function RestoreCustomBars()
    if not customBarsApplied then
        return
    end
    for container, state in pairs(originalContainers) do
        container:SetParent(state.parent)
        SetPoints(container, state.points)
    end
    for selection, points in pairs(originalSelections) do
        SetPoints(selection, points)
    end
    originalSelections = {}
    for divider, alpha in pairs(originalDividers) do
        divider:SetAlpha(alpha)
    end
    originalContainers = {}
    originalDividers = {}
    for button, state in pairs(originalSlotArt) do
        button.SlotArt:SetShown(state.artShown)
        button.SlotBackground:SetShown(state.backgroundShown)
    end
    originalSlotArt = {}
    if MainActionBar.BorderArt then
        MainActionBar.BorderArt:SetShown(originalBorderArtShown)
    end
    local endCaps = originalEndCaps
    originalEndCaps = {}
    for cap, state in pairs(endCaps) do
        SetPoints(cap, state.points)
    end
    if MainActionBar.ActionBarPageNumber then
        MainActionBar.ActionBarPageNumber:SetParent(originalPageNumberParent)
        SetPoints(MainActionBar.ActionBarPageNumber, originalPageNumberPoints)
    end
    if originalMainBar then
        local points = originalMainBar.points
        originalMainBar = nil
        SetPoints(MainActionBar, points)
    end
    for _, bar in ipairs(customBars) do
        bar:Hide()
    end
    customBarsApplied = false
end

--- Restores all action, status, auxiliary and cast bar visuals and anchors.
local function RestoreVisuals()
    RestoreCustomBars()
    RestoreCastBar()
    for bar, state in pairs(originalAuxiliaryBars) do
        for button, points in pairs(state.buttonPoints or {}) do
            SetPoints(button, points)
        end
        if auxiliaryAnchors[bar] then
            auxiliaryAnchors[bar]:Hide()
        end
        SetPoints(bar, state.points)
    end
    originalAuxiliaryBars = {}
    for bar, state in pairs(originalStatusBars) do
        ResizeStatusBar(bar, state.width)
        bar.BarFrameTexture:SetWidth(state.textureWidth)
        SetPoints(bar, state.points)
    end
    originalStatusBars = {}
end

--- Creates secure custom bar frames that reuse Blizzard's action buttons.
local function CreateCustomBars()
    if #customBars > 0 then
        return true
    end
    local bars = GetBars()
    local suffixes = { "Main", "BottomLeft", "BottomRight" }
    for _, nativeBar in ipairs(bars) do
        if not nativeBar.actionButtons then
            return ReportError("The Forever action-button templates are not ready. The layout was not changed.")
        end
    end
    for barIndex, nativeBar in ipairs(bars) do
        local suffix = suffixes[barIndex]
        local customBarName = "ErzbaroneUI" .. suffix .. "SecureBar"
        local customBar = _G[customBarName]
        if not customBar then
            customBar = CreateFrame("Frame", customBarName, nativeBar, "SecureHandlerStateTemplate")
        else
            customBar:SetParent(nativeBar)
        end
        customBar:Hide()
        customBar.ignoreInLayout = true
        -- Keep Blizzard's secure button fields and scripts intact; only move their containers.
        customBar.actionButtons = nativeBar.actionButtons
        table.insert(customBars, customBar)
    end

    return true
end

--- Reparents and arranges native action-button containers in the compact layout.
local function ApplyCustomBars(width, rowY, left, bottom, leftWidth, mainHeight, rightHeight)
    if not CreateCustomBars() then
        return false
    end
    if not customBarsApplied then
        for _, nativeBar in ipairs(GetBars()) do
            for _, button in ipairs(nativeBar.actionButtons) do
                originalContainers[button.container] = {
                    parent = button.container:GetParent(),
                    points = GetPoints(button.container),
                }
            end
        end
        originalMainBar = { points = GetPoints(MainActionBar) }
        originalBorderArtShown = MainActionBar.BorderArt and MainActionBar.BorderArt:IsShown()
        for _, cap in ipairs({ MainActionBar.EndCaps.LeftEndCap, MainActionBar.EndCaps.RightEndCap }) do
            originalEndCaps[cap] = { points = GetPoints(cap) }
        end
        originalPageNumberParent = MainActionBar.ActionBarPageNumber:GetParent()
        originalPageNumberPoints = GetPoints(MainActionBar.ActionBarPageNumber)
        for index = 1, 6 do
            local button = MultiBarBottomRight.actionButtons[index]
            originalSlotArt[button] = {
                artShown = button.SlotArt:IsShown(),
                backgroundShown = button.SlotBackground:IsShown(),
            }
            if not hookedFrames[button] then
                hookedFrames[button] = true
                hooksecurefunc(button, "UpdateButtonArt", ApplySlotArt)
            end
        end
    end
    local bars = GetBars()
    local mainScale = bars[1]:GetScale()
    local bar2Scale = bars[2]:GetScale()
    local bar3Scale = bars[3]:GetScale()
    local mainWidth = GetRowSize(bars[1], 12)
    local bar2Width, bar2Height = GetRowSize(bars[2], 12)
    local rightWidth = GetRowSize(bars[3], 6)
    local bar3RowY = rowY
    local positions = {
        { left, bottom, mainWidth, mainHeight, mainScale },
        { left, bottom + rowY, bar2Width, bar2Height, bar2Scale },
        { left + leftWidth + GAP, bottom, rightWidth, rightHeight + rowY, bar3Scale },
    }

    for barIndex, customBar in ipairs(customBars) do
        local position = positions[barIndex]
        local x, y, barWidth, barHeight, scale = unpack(position)
        customBar:ClearAllPoints()
        customBar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", x, y)
        customBar:SetSize(barWidth / scale, barHeight / scale)
        customBar:Show()
        if barIndex == 1 then
            SetPoints(MainActionBar, GetPoints(customBar))
        end
        local nativeBar = bars[barIndex]
        if nativeBar.Selection then
            if not originalSelections[nativeBar.Selection] then
                originalSelections[nativeBar.Selection] = GetPoints(nativeBar.Selection)
            end
            if not ErzbaroneUI.Utils:AlignSelection(nativeBar, customBar) and not warnedSelection then
                warnedSelection = true
                print("ErzbaroneUI: Action bar Edit Mode selections are not ready. Their positions will be retried on the next layout update.")
            end
        end
        local padding = math.max(nativeBar.minButtonPadding, nativeBar.buttonPadding)
        local rowX = 0
        for index, button in ipairs(customBar.actionButtons) do
            if barIndex == 3 and index == 7 then
                rowX = 0
            end
            local container = button.container
            container:SetParent(customBar)
            button.container:ClearAllPoints()
            button.container:SetPoint("BOTTOMLEFT", customBar, "BOTTOMLEFT", rowX,
                barIndex == 3 and index > 6 and bar3RowY / scale or 0)
            rowX = rowX + container:GetWidth() * container:GetScale() + padding
        end
    end

    if MainActionBar.BorderArt then
        MainActionBar.BorderArt:Hide()
    end
    local mainBar = customBars[1]
    if not mainBar.background then
        mainBar.background = mainBar:CreateTexture(nil, "BACKGROUND", nil, -3)
        mainBar.background:SetAtlas("UI-HUD-ActionBar-Frame")
    end
    mainBar.background:ClearAllPoints()
    mainBar.background:SetPoint("TOPLEFT", mainBar, "TOPLEFT", -6, 6)
    mainBar.background:SetPoint("BOTTOMRIGHT", mainBar, "BOTTOMRIGHT", 4, -BACKGROUND_BOTTOM_OVERHANG)
    mainBar.background:Show()

    originalEndCaps[MainActionBar.EndCaps.LeftEndCap].customPoints = {
        { "RIGHT", mainBar, "BOTTOMLEFT",
            30 / mainScale,
            (5 + mainHeight / 2) / mainScale },
    }
    originalEndCaps[MainActionBar.EndCaps.RightEndCap].customPoints = {
        { "LEFT", mainBar, "BOTTOMLEFT",
            (width - 30) / mainScale, (5 + mainHeight / 2) / mainScale },
    }
    MainActionBar.ActionBarPageNumber:SetParent(mainBar)
    SetPoints(MainActionBar.ActionBarPageNumber, {
        { "BOTTOMRIGHT", mainBar, "BOTTOMLEFT", -4 / mainScale, 9 / mainScale },
    })
    local rightBar = customBars[3]
    if not rightBar.background then
        rightBar.background = rightBar:CreateTexture(nil, "BACKGROUND", nil, -3)
        rightBar.background:SetAtlas("UI-HUD-ActionBar-Frame")
    end
    rightBar.background:ClearAllPoints()
    rightBar.background:SetPoint("TOPLEFT", rightBar.actionButtons[1].container, "TOPLEFT", -6, 6)
    rightBar.background:SetPoint("BOTTOMRIGHT", rightBar.actionButtons[6].container, "BOTTOMRIGHT", 4, -BACKGROUND_BOTTOM_OVERHANG)
    rightBar.background:Show()

    HideNativeDividers()
    customBarsApplied = true
    for cap in pairs(originalEndCaps) do
        MaintainEndCapPosition(cap)
    end
    for button in pairs(originalSlotArt) do
        ApplySlotArt(button)
    end
    return true
end

--- Sizes and stacks status bars below the action bars, returning their top edge.
local function ApplyStatusBars(width, left, bottom, rowY)
    local top = bottom
    for _, bar in ipairs(GetStatusBars()) do
        if not originalStatusBars[bar] then
            originalStatusBars[bar] = {
                width = bar:GetWidth(),
                textureWidth = bar.BarFrameTexture:GetWidth(),
                points = GetPoints(bar),
            }
        end
        originalStatusBars[bar].customWidth = width / bar:GetScale()
        ResizeStatusBar(bar, originalStatusBars[bar].customWidth)
        originalStatusBars[bar].customPoints = {
            { "BOTTOMLEFT", UIParent, "BOTTOM", left / bar:GetScale(), (bottom + rowY) / bar:GetScale() },
        }
        MaintainStatusBarPosition(bar)
        if bar:IsShown() then
            top = bottom + rowY + bar:GetHeight() * bar:GetScale()
            rowY = rowY + bar:GetHeight() * bar:GetScale() - 1
        end
    end
    return top
end

--- Pins auxiliary buttons to a secure anchor independent of native bar movement.
local function AnchorAuxiliaryButtons(bar, state)
    if not bar.actionButtons then
        return
    end
    local anchor = auxiliaryAnchors[bar]
    if not anchor then
        anchor = CreateFrame("Frame", nil, bar, "SecureHandlerStateTemplate")
        anchor.ignoreInLayout = true
        auxiliaryAnchors[bar] = anchor
    end
    SetPoints(anchor, state.customPoints)
    anchor:SetSize(bar:GetWidth(), bar:GetHeight())
    anchor:Show()
    state.buttonPoints = state.buttonPoints or {}
    local barScale = bar:GetEffectiveScale()
    local left, bottom = bar:GetLeft() * barScale, bar:GetBottom() * barScale
    for _, button in ipairs(bar.actionButtons) do
        local x, y = button.container:GetCenter()
        -- Unused stance containers may not have been laid out yet.
        if x and y then
            if not state.buttonPoints[button] then
                state.buttonPoints[button] = GetPoints(button)
            end
            local containerScale = button.container:GetEffectiveScale()
            local buttonScale = button:GetEffectiveScale()
            -- Native containers still drive sizing/visibility, but their combat movement must not move the buttons.
            SetPoints(button, {
                { "CENTER", anchor, "BOTTOMLEFT",
                    (x * containerScale - left) / buttonScale,
                    (y * containerScale - bottom) / buttonScale },
            })
        end
    end
end

--- Stacks auxiliary bars above the action bars and anchors their buttons.
local function ApplyAuxiliaryBars(left, top)
    -- Pre-anchor hidden controls above the visible stack so they can appear in combat.
    for _, shown in ipairs({ true, false }) do
        local y = top + GAP
        for _, bar in ipairs(GetAuxiliaryBars()) do
            if bar:IsShown() == shown then
                if not originalAuxiliaryBars[bar] then
                    originalAuxiliaryBars[bar] = { points = GetPoints(bar) }
                end
                local scale = bar:GetEffectiveScale() / UIParent:GetEffectiveScale()
                originalAuxiliaryBars[bar].customPoints = {
                    { "BOTTOMLEFT", UIParent, "BOTTOM", left / scale, y / scale },
                }
                MaintainAuxiliaryBarPosition(bar)
                AnchorAuxiliaryButtons(bar, originalAuxiliaryBars[bar])
                if shown then
                    top = y + bar:GetHeight() * scale
                    y = top + GAP
                end
            end
        end
    end
end

--- Calculates the compact layout's dimensions and offsets from native bar sizes.
local function GetBarGeometry()
    local mainWidth, mainHeight = GetRowSize(MainActionBar, 12)
    local bar2Width = GetRowSize(MultiBarBottomLeft, 12)
    local rightWidth, rightHeight = GetRowSize(MultiBarBottomRight, 6)
    local bar3Shown = MultiBarBottomRight:IsShown()
    local leftWidth = MultiBarBottomLeft:IsShown() and math.max(mainWidth, bar2Width) or mainWidth
    local width = leftWidth
    if bar3Shown then
        width = width + GAP + rightWidth
    else
        rightHeight = 0
    end
    local caps = MainActionBar.EndCaps
    local leftOverhang = caps.LeftEndCap:GetWidth() * caps.LeftEndCap:GetScale() - 30
    local rightOverhang = caps.RightEndCap:GetWidth() * caps.RightEndCap:GetScale() - 30
    local left = -width / 2 + (leftOverhang - rightOverhang) / 2
    local bottom = (BACKGROUND_BOTTOM_OVERHANG - 2)
        * math.max(MainActionBar:GetScale(), bar3Shown and MultiBarBottomRight:GetScale() or 0)
    local rowY = math.max(mainHeight, rightHeight) + GAP
    for _, bar in ipairs(GetStatusBars()) do
        if bar:IsShown() then
            rowY = rowY + bar:GetHeight() * bar:GetScale() - 1
        end
    end
    return width, rowY + GAP, left, bottom, leftWidth, mainHeight, rightHeight
end

--- Applies the compact action-bar layout or restores native visuals when disabled.
function ErzbaroneUI.ActionLayout:Update()
    if InCombatLockdown() then
        ErzbaroneUI.MainBar.PendingUpdate = true
        return false
    end
    if not ErzbaroneUISettings.compactMainBar then
        RestoreVisuals()
        return true
    end
    if not MainActionBar or not MultiBarBottomLeft or not MultiBarBottomRight
        or not MainStatusTrackingBarContainer or not SecondaryStatusTrackingBarContainer
        or not MainActionBar.EndCaps or not MainActionBar.EndCaps.LeftEndCap or not MainActionBar.EndCaps.RightEndCap
        or not MainActionBar.ActionBarPageNumber then
        return ReportError("The Forever action/status bars are missing. The layout was not changed.")
    end
    if not StanceBar or not PetActionBar or not PossessActionBar or not MainMenuBarVehicleLeaveButton then
        return ReportError("The Forever auxiliary action bars are missing. The layout was not changed.")
    end
    for _, bar in ipairs({ StanceBar, PetActionBar, PossessActionBar }) do
        if not bar.actionButtons or #bar.actionButtons == 0 then
            return ReportError("The Forever auxiliary action-button templates are not ready. The layout was not changed.")
        end
    end
    if not PlayerCastingBarFrame then
        return ReportError("The Forever player cast bar is missing. The layout was not changed.")
    end
    for _, bar in ipairs(GetBars()) do
        if not bar:IsInitialized() then
            ErzbaroneUI.MainBar.PendingUpdate = true
            return false
        end
        if not bar.actionButtons or #bar.actionButtons ~= 12 then
            return ReportError("The Forever action-button templates are not ready. The layout was not changed.")
        end
    end
    for index = 1, 6 do
        local button = MultiBarBottomRight.actionButtons[index]
        if not button.SlotArt or not button.SlotBackground then
            return ReportError("The Forever action-button slot artwork is not ready. The layout was not changed.")
        end
    end
    for _, bar in ipairs({ SecondaryStatusTrackingBarContainer, MainStatusTrackingBarContainer }) do
        if not bar:IsInitialized() then
            ErzbaroneUI.MainBar.PendingUpdate = true
            return false
        end
        if not bar.BarFrameTexture then
            return ReportError("The Forever status bars are not ready. The layout was not changed.")
        end
    end
    local width, rowY, left, bottom, leftWidth, mainHeight, rightHeight = GetBarGeometry()
    if not ApplyCustomBars(width, rowY, left, bottom, leftWidth, mainHeight, rightHeight) then
        return false
    end
    local statusTop = ApplyStatusBars(width, left, bottom, math.max(mainHeight, rightHeight) + GAP)
    local top = math.max(bottom + mainHeight, statusTop)
    if MultiBarBottomLeft:IsShown() then
        local _, bar2Height = GetRowSize(MultiBarBottomLeft, 12)
        top = math.max(top, bottom + rowY + bar2Height)
    end
    if MultiBarBottomRight:IsShown() then
        top = math.max(top, bottom + rowY + rightHeight)
    end
    ApplyAuxiliaryBars(left, top)
    ApplyCastBar(top)
    lastError = nil
    return true
end

--- Hooks bar layout and position changes so the compact arrangement stays applied.
function ErzbaroneUI.ActionLayout:Initialize()
    -- Requests a fresh layout after Blizzard changes a hooked frame.
    local function Reapply()
        if ErzbaroneUISettings.compactMainBar or customBarsApplied then
            ErzbaroneUI.MainBar:RequestUpdate()
        end
    end
    for _, bar in pairs(GetBars()) do
        if not hookedFrames[bar] then
            hookedFrames[bar] = true
            hooksecurefunc(bar, "UpdateGridLayout", function()
                Reapply()
            end)
            hooksecurefunc(bar, "SetShowGrid", Reapply)
            hooksecurefunc(bar, "ApplySystemAnchor", Reapply)
            hooksecurefunc(bar, "AnchorSelectionFrame", Reapply)
            hooksecurefunc(bar, bar.SetPointBase and "SetPointBase" or "SetPoint", Reapply)
            bar:HookScript("OnShow", Reapply)
            bar:HookScript("OnHide", Reapply)
            bar:HookScript("OnSizeChanged", Reapply)
            if bar == MainActionBar then
                hooksecurefunc(bar, "UpdateDividers", function()
                    if customBarsApplied then
                        HideNativeDividers()
                    end
                end)
            end
        end
    end
    for _, bar in pairs(GetStatusBars()) do
        if not hookedFrames[bar] then
            hookedFrames[bar] = true
            hooksecurefunc(bar, "ApplySystemAnchor", Reapply)
            hooksecurefunc(bar, "SetSize", MaintainStatusBarSize)
            hooksecurefunc(bar, "ResizeContainerBars", MaintainStatusBarSize)
            hooksecurefunc(bar, "UpdateDividers", MaintainStatusBarSize)
            hooksecurefunc(bar, bar.SetPointBase and "SetPointBase" or "SetPoint", MaintainStatusBarPosition)
            hooksecurefunc(bar, bar.ClearAllPointsBase and "ClearAllPointsBase" or "ClearAllPoints", MaintainStatusBarPosition)
        end
    end
    if MainActionBar and MainActionBar.EndCaps then
        for _, cap in pairs({ MainActionBar.EndCaps.LeftEndCap, MainActionBar.EndCaps.RightEndCap }) do
            if not hookedFrames[cap] then
                hookedFrames[cap] = true
                hooksecurefunc(cap, cap.SetPointBase and "SetPointBase" or "SetPoint", MaintainEndCapPosition)
                hooksecurefunc(cap, cap.ClearAllPointsBase and "ClearAllPointsBase" or "ClearAllPoints", MaintainEndCapPosition)
            end
        end
    end
    for _, bar in pairs(GetAuxiliaryBars()) do
        if not hookedFrames[bar] then
            hookedFrames[bar] = true
            hooksecurefunc(bar, "ApplySystemAnchor", Reapply)
            if bar.actionButtons then
                hooksecurefunc(bar, "UpdateGridLayout", Reapply)
            end
            hooksecurefunc(bar, bar.SetPointBase and "SetPointBase" or "SetPoint", MaintainAuxiliaryBarPosition)
            hooksecurefunc(bar, bar.ClearAllPointsBase and "ClearAllPointsBase" or "ClearAllPoints", MaintainAuxiliaryBarPosition)
            hooksecurefunc(bar, bar.SetScaleBase and "SetScaleBase" or "SetScale", Reapply)
            bar:HookScript("OnShow", Reapply)
            bar:HookScript("OnHide", Reapply)
            bar:HookScript("OnSizeChanged", Reapply)
        end
    end
    local castBar = PlayerCastingBarFrame
    if castBar and not hookedFrames[castBar] then
        hookedFrames[castBar] = true
        hooksecurefunc(castBar, castBar.SetPointBase and "SetPointBase" or "SetPoint", MaintainCastBarPosition)
        hooksecurefunc(castBar, castBar.ClearAllPointsBase and "ClearAllPointsBase" or "ClearAllPoints", MaintainCastBarPosition)
        hooksecurefunc(castBar, castBar.SetScaleBase and "SetScaleBase" or "SetScale", Reapply)
        castBar:HookScript("OnShow", Reapply)
    end
    if not self.Initialized then
        self.Initialized = true
        local events = CreateFrame("Frame")
        for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "EDIT_MODE_LAYOUTS_UPDATED", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED" }) do
            events:RegisterEvent(event)
        end
        events:SetScript("OnEvent", Reapply)
        EventRegistry:RegisterCallback("EditMode.Exit", Reapply, self)
    end
    if StatusTrackingBarManager and not hookedFrames[StatusTrackingBarManager] then
        hookedFrames[StatusTrackingBarManager] = true
        hooksecurefunc(StatusTrackingBarManager, "UpdateBarsShown", Reapply)
        hooksecurefunc(StatusTrackingBarManager, "CheckForLayoutChange", Reapply)
    end
end
