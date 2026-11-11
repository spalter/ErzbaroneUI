if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.MainBar = {}

local CORNER_X = 16
local CORNER_Y = 12
local FADE_SPEED = 6
local MENU_GAP = 8

local updater = CreateFrame("Frame")
local updateQueued = false
local menuAnchor = CreateFrame("Frame", nil, UIParent)
local applied = false
local updating = false
local originalAlpha
local originalParent
local originalMenuPoints
local originalMenuSelectionPoints
local currentAlpha = 1
local currentBagsAlpha = 1
local warnedMissingMenu = false
local bagsApplied = false
local originalBagsAlpha
local originalBagsShown
local originalBagsScale
local originalBagsPoints
local warnedMissingBags = false
local warnedSelection = false

--- Copies a frame's anchor points so they can be restored after relayout.
local function GetPoints(frame)
    local points = {}
    for index = 1, frame:GetNumPoints() do
        table.insert(points, { frame:GetPoint(index) })
    end
    return points
end

--- Replaces a frame's current anchors with a saved set.
local function RestorePoints(frame, points)
    local clear = frame.ClearAllPointsBase or frame.ClearAllPoints
    local setPoint = frame.SetPointBase or frame.SetPoint
    clear(frame)
    for _, point in ipairs(points) do
        setPoint(frame, unpack(point))
    end
end

--- Moves the bag bar to the screen corner and restores it when compact mode ends.
local function UpdateBags()
    if ErzbaroneUISettings.compactMainBar then
        if not BagsBar or not BagsBar.ApplySystemAnchor then
            if not warnedMissingBags then
                warnedMissingBags = true
                print("ErzbaroneUI: Main bar redesign could not find the Forever bag bar. Its layout was not changed.")
            end
            return
        end
        if not bagsApplied then
            originalBagsAlpha = BagsBar:GetAlpha()
            originalBagsShown = BagsBar:IsShown()
            originalBagsScale = BagsBar:GetScale()
            originalBagsPoints = GetPoints(BagsBar)
            currentBagsAlpha = 1
            bagsApplied = true
        end
        local setScale = BagsBar.SetScaleBase or BagsBar.SetScale
        setScale(BagsBar, originalBagsScale)

        -- Bypass Edit Mode's point overrides without changing its saved layout.
        local clear = BagsBar.ClearAllPointsBase or BagsBar.ClearAllPoints
        local setPoint = BagsBar.SetPointBase or BagsBar.SetPoint
        clear(BagsBar)
        local scale = BagsBar:GetScale()
        setPoint(BagsBar, "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -CORNER_X / scale, CORNER_Y / scale)
        BagsBar:SetAlpha(currentBagsAlpha)
        BagsBar:Show()
    elseif bagsApplied then
        bagsApplied = false
        local setScale = BagsBar.SetScaleBase or BagsBar.SetScale
        setScale(BagsBar, originalBagsScale)
        BagsBar:SetAlpha(originalBagsAlpha)
        local setShown = BagsBar.SetShownBase or BagsBar.SetShown
        setShown(BagsBar, originalBagsShown)
        RestorePoints(BagsBar, originalBagsPoints)
    end
end

--- Returns whether Blizzard's Edit Mode is currently open.
local function IsEditModeActive()
    return EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()
end

--- Checks whether a frame or any of its visible children is under the cursor.
local function IsHovered(frame)
    if frame:IsMouseOver() then
        return true
    end
    for _, button in ipairs({ frame:GetChildren() }) do
        if button:IsShown() and button:IsMouseOver() then
            return true
        end
    end
    return false
end

--- Moves a frame's alpha toward visible or hidden according to hover and Edit Mode.
local function Fade(frame, alpha, hovered, elapsed)
    local target = (hovered or IsEditModeActive()) and 1 or 0
    if alpha < target then
        alpha = math.min(target, alpha + FADE_SPEED * elapsed)
    else
        alpha = math.max(target, alpha - FADE_SPEED * elapsed)
    end
    frame:SetAlpha(alpha)
    return alpha
end

--- Updates the micro menu and bag-bar fades each frame.
local function OnUpdate(_, elapsed)
    currentAlpha = Fade(MicroMenu, currentAlpha, menuAnchor:IsMouseOver() or IsHovered(MicroMenu), elapsed)
    if bagsApplied then
        currentBagsAlpha = Fade(BagsBar, currentBagsAlpha, IsHovered(BagsBar), elapsed)
    end
end

--- Returns the extra bottom inset the chat layout should reserve.
function ErzbaroneUI.MainBar:GetChatBottomInset()
    return 0
end

--- Queues one layout refresh for the next timer tick.
function ErzbaroneUI.MainBar:RequestUpdate()
    if updating or updateQueued then
        return
    end
    updateQueued = true
    C_Timer.After(0, function()
        updateQueued = false
        self:Update()
    end)
end

--- Applies or restores the compact main-bar layout when it is safe to do so.
function ErzbaroneUI.MainBar:Update()
    if updating then
        return
    end
    if not ErzbaroneUISettings.compactMainBar and not applied and not bagsApplied then
        self.PendingUpdate = false
        return
    end
    if not MicroMenuContainer or not MicroMenu or not MicroMenuContainer.ApplySystemAnchor then
        if not warnedMissingMenu then
            warnedMissingMenu = true
            print("ErzbaroneUI: Main bar redesign could not find the Forever micro menu. The layout was not changed.")
        end
        return
    end
    if InCombatLockdown() then
        self.PendingUpdate = true
        return
    end

    self.PendingUpdate = false
    updating = true

    local layoutReady = ErzbaroneUI.ActionLayout:Update()
    if ErzbaroneUISettings.compactMainBar and not layoutReady then
        updating = false
        return
    end

    UpdateBags()

    if ErzbaroneUISettings.compactMainBar then
        if not applied then
            originalAlpha = MicroMenu:GetAlpha()
            originalParent = MicroMenu:GetParent()
            originalMenuPoints = GetPoints(MicroMenu)
            currentAlpha = 1
            MicroMenu:SetAlpha(currentAlpha)
            applied = true
        end

        menuAnchor:ClearAllPoints()
        if bagsApplied then
            menuAnchor:SetPoint("BOTTOMRIGHT", BagsBar, "BOTTOMLEFT", -MENU_GAP, 0)
        else
            local cap = MainActionBar.EndCaps.LeftEndCap
            local capLeft = cap:GetLeft() * cap:GetEffectiveScale() / UIParent:GetEffectiveScale()
            menuAnchor:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", capLeft - MENU_GAP, CORNER_Y)
        end
        MicroMenu:SetParent(menuAnchor)
        MicroMenu:ClearAllPoints()
        MicroMenu:SetPoint("BOTTOMLEFT", menuAnchor, "BOTTOMLEFT", 0, 0)
        local scale = MicroMenu:GetScale()
        menuAnchor:SetSize(MicroMenu:GetWidth() * scale, MicroMenu:GetHeight() * scale)
        if MicroMenuContainer.Selection then
            if not originalMenuSelectionPoints then
                originalMenuSelectionPoints = GetPoints(MicroMenuContainer.Selection)
            end
            if not ErzbaroneUI.Utils:AlignSelection(MicroMenuContainer, menuAnchor) and not warnedSelection then
                warnedSelection = true
                print("ErzbaroneUI: Menu Edit Mode selection is not ready. Its position will be retried on the next layout update.")
            end
        end
        updater:SetScript("OnUpdate", OnUpdate)
    elseif applied then
        applied = false
        updater:SetScript("OnUpdate", nil)
        MicroMenu:SetAlpha(originalAlpha)
        MicroMenu:SetParent(originalParent)
        RestorePoints(MicroMenu, originalMenuPoints)
        if originalMenuSelectionPoints then
            RestorePoints(MicroMenuContainer.Selection, originalMenuSelectionPoints)
            originalMenuSelectionPoints = nil
        end
    end

    updating = false
    ErzbaroneUI.Chat:UpdatePosition()
end

--- Hooks load, combat and bar-layout events, then initializes the main-bar layout.
function ErzbaroneUI.MainBar:Initialize()
    if not self.Initialized then
        self.Initialized = true

        local eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("ADDON_LOADED")
        eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        -- Reinitializes after required Blizzard frames load and retries deferred combat updates.
        eventFrame:SetScript("OnEvent", function(_, event, name)
            if event == "ADDON_LOADED" and (name == "Blizzard_MicroMenu" or name == "Blizzard_MainMenuBarBagButtons"
                or name == "Blizzard_ActionBar" or name == "Blizzard_StatusTrackingBar") then
                self:Initialize()
            elseif event == "PLAYER_REGEN_ENABLED" and self.PendingUpdate then
                self:RequestUpdate()
            end
        end)
    end

    if MicroMenuContainer and MicroMenu and not self.Hooked then
        self.Hooked = true
        -- Requests relayout after the micro menu changes its native placement.
        local function Reapply()
            if ErzbaroneUISettings.compactMainBar or applied then
                self:RequestUpdate()
            end
        end
        hooksecurefunc(MicroMenu, "Layout", Reapply)
        hooksecurefunc(MicroMenuContainer, "ApplySystemAnchor", Reapply)
        hooksecurefunc(MicroMenuContainer, "AnchorSelectionFrame", Reapply)
        hooksecurefunc(MicroMenuContainer, MicroMenuContainer.SetPointBase and "SetPointBase" or "SetPoint", Reapply)
        MicroMenuContainer:HookScript("OnSizeChanged", Reapply)
    end

    if BagsBar and not self.BagsHooked then
        self.BagsHooked = true
        -- Requests relayout after the bag bar changes its native placement.
        local function Reapply()
            if ErzbaroneUISettings.compactMainBar or bagsApplied then
                self:RequestUpdate()
            end
        end
        hooksecurefunc(BagsBar, "SetPoint", Reapply)
        hooksecurefunc(BagsBar, "ApplySystemAnchor", Reapply)
        hooksecurefunc(BagsBar, "Layout", Reapply)
        hooksecurefunc(BagsBar, "SetScale", function(_, scale)
            if bagsApplied and not updating then
                originalBagsScale = scale
                Reapply()
            end
        end)
        hooksecurefunc(BagsBar, "OnUpdateEndCaps", function(_, show)
            if bagsApplied then
                originalBagsShown = show
            end
            Reapply()
        end)
    end

    ErzbaroneUI.ActionLayout:Initialize()
    self:Update()
    self:RequestUpdate()
end
