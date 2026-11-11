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
local currentAlpha = 1
local currentBagsAlpha = 1
local warnedMissingMenu = false
local bagsApplied = false
local originalBagsAlpha
local originalBagsShown
local originalBagsScale
local originalBagsPoints
local warnedMissingBags = false

local function GetPoints(frame)
    local points = {}
    for index = 1, frame:GetNumPoints() do
        table.insert(points, { frame:GetPoint(index) })
    end
    return points
end

local function RestorePoints(frame, points)
    local clear = frame.ClearAllPointsBase or frame.ClearAllPoints
    local setPoint = frame.SetPointBase or frame.SetPoint
    clear(frame)
    for _, point in ipairs(points) do
        setPoint(frame, unpack(point))
    end
end

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

local function IsEditModeActive()
    return EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()
end

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

local function OnUpdate(_, elapsed)
    currentAlpha = Fade(MicroMenu, currentAlpha, menuAnchor:IsMouseOver() or IsHovered(MicroMenu), elapsed)
    if bagsApplied then
        currentBagsAlpha = Fade(BagsBar, currentBagsAlpha, IsHovered(BagsBar), elapsed)
    end
end

function ErzbaroneUI.MainBar:GetChatBottomInset()
    return 0
end

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
        local cap = MainActionBar.EndCaps.LeftEndCap
        local capLeft = cap:GetLeft() * cap:GetEffectiveScale() / UIParent:GetEffectiveScale()
        menuAnchor:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", capLeft - MENU_GAP, CORNER_Y)
        MicroMenu:SetParent(menuAnchor)
        MicroMenu:ClearAllPoints()
        MicroMenu:SetPoint("BOTTOMLEFT", menuAnchor, "BOTTOMLEFT", 0, 0)
        local scale = MicroMenu:GetScale()
        menuAnchor:SetSize(MicroMenu:GetWidth() * scale, MicroMenu:GetHeight() * scale)
        updater:SetScript("OnUpdate", OnUpdate)
    elseif applied then
        applied = false
        updater:SetScript("OnUpdate", nil)
        MicroMenu:SetAlpha(originalAlpha)
        MicroMenu:SetParent(originalParent)
        RestorePoints(MicroMenu, originalMenuPoints)
    end

    UpdateBags()
    updating = false
    ErzbaroneUI.Chat:UpdatePosition()
end

function ErzbaroneUI.MainBar:Initialize()
    if not self.Initialized then
        self.Initialized = true

        local eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("ADDON_LOADED")
        eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
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
        local function Reapply()
            if ErzbaroneUISettings.compactMainBar or applied then
                self:RequestUpdate()
            end
        end
        hooksecurefunc(MicroMenu, "Layout", Reapply)
    end

    if BagsBar and not self.BagsHooked then
        self.BagsHooked = true
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
