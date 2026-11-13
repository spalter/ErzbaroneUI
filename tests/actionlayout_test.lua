local root = (... or ".") .. "\\"
unpack = unpack or table.unpack

local function Equal(actual, expected, message)
    assert(actual == expected, (message or "Unexpected value") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end

local function Forbidden()
    error("Addon accessed Edit Mode profiles or mutated native settings/grid fields")
end

local combat = false
local nativeSetup = false
local SecureAttribute
local timers, hooks, events, callbacks, createdFrames, messages
local editModeActive = false
local protectedFields = { numRows = true, numButtonsShowable = true, isHorizontal = true, noSpacers = true,
    systemInfo = true, snappedToFrame = true, oldGridSettings = true, bar = true,
    container = true, index = true, commandName = true }

local anchorOffsets = {
    BOTTOMLEFT = { 0, 0 }, BOTTOM = { 0.5, 0 }, BOTTOMRIGHT = { 1, 0 },
    LEFT = { 0, 0.5 }, CENTER = { 0.5, 0.5 }, RIGHT = { 1, 0.5 },
    TOPLEFT = { 0, 1 }, TOP = { 0.5, 1 }, TOPRIGHT = { 1, 1 },
}

local function FramePosition(frame, axis)
    if frame == UIParent then return 0 end
    local point = frame.points[1]
    if not point then return nil end
    local relative = point[2] or frame:GetParent() or UIParent
    local scale = relative:GetEffectiveScale() / frame:GetEffectiveScale()
    local origin = axis == 1 and relative:GetLeft() or relative:GetBottom()
    if not origin then return nil end
    local relativeSize = axis == 1 and relative:GetWidth() or relative:GetHeight()
    local size = axis == 1 and frame:GetWidth() or frame:GetHeight()
    return (origin + relativeSize * anchorOffsets[point[3]][axis]) * scale
        + (point[axis + 3] or 0) - size * anchorOffsets[point[1]][axis]
end

local function Frame(name)
    local data = { name = name, width = 36, height = 36, scale = 1, shown = true, alpha = 1,
        mouseEnabled = true, attributes = {}, points = { { "BOTTOM", UIParent, "BOTTOM", 20, 30 } } }
    local frame = setmetatable({}, {
        __index = data,
        __newindex = function(_, key, value)
            assert(nativeSetup or not protectedFields[key], "Addon tainted native field " .. key)
            data[key] = value
        end,
    })
    function frame:GetWidth() return self.width end
    function frame:GetHeight() return self.height end
    function frame:GetScale() return self.scale end
    function frame:GetEffectiveScale()
        return self.scale * (self.parent and self.parent:GetEffectiveScale() or 1)
    end
    function frame:GetLeft() return self.left or FramePosition(self, 1) end
    function frame:GetBottom() return FramePosition(self, 2) end
    function frame:GetRight()
        local left = self:GetLeft()
        return left and left + self.width
    end
    function frame:GetTop()
        local bottom = self:GetBottom()
        return bottom and bottom + self.height
    end
    function frame:GetCenter()
        local left, bottom = self:GetLeft(), self:GetBottom()
        if left and bottom then return left + self.width / 2, bottom + self.height / 2 end
    end
    function frame:GetAlpha() return self.alpha end
    function frame:GetParent() return self.parent end
    function frame:IsMouseOver() return self.hovered or false end
    function frame:IsMouseEnabled() return self.mouseEnabled end
    function frame:GetChildren() return unpack(self.children or {}) end
    function frame:IsShown() return self.shown end
    function frame:IsVisible()
        return self.shown and (not self.parent or self.parent:IsVisible())
    end
    function frame:IsInitialized() return self.initialized ~= false end
    function frame:IsProtected() return self.protected ~= false end
    function frame:GetNumPoints() return #self.points end
    function frame:GetPoint(index) return unpack(self.points[index]) end
    function frame:SetPoint(...)
        assert(not combat or not self:IsProtected(), "Protected anchor changed in combat")
        table.insert(self.points, { ... })
    end
    function frame:ClearAllPoints()
        assert(not combat or not self:IsProtected(), "Protected anchor cleared in combat")
        self.points = {}
    end
    function frame:SetWidth(width) self.width = width end
    function frame:SetSize(width, height) self.width, self.height = width, height end
    function frame:SetScale(scale) self.scale = scale end
    function frame:SetParent(parent)
        assert(not combat, "Protected parent changed in combat")
        self.parent = parent
    end
    function frame:SetAlpha(alpha)
        self.alpha = alpha
        self.alphaWrites = (self.alphaWrites or 0) + 1
    end
    function frame:EnableMouse(enabled)
        assert(not combat, "Protected mouse input changed in combat")
        self.mouseEnabled = enabled
    end
    function frame:SetShown(shown)
        assert(not combat or not self:IsProtected(), "Protected visibility changed in combat")
        local changed = self.shown ~= shown
        self.shown = shown
        if changed then
            local callback = self[shown and "OnShow" or "OnHide"]
            if callback then callback(self) end
        end
    end
    function frame:Show() self:SetShown(true) end
    function frame:Hide() self:SetShown(false) end
    function frame:SetID(id) self.id = id end
    function frame:GetID() return self.id end
    function frame:SetAttribute(name, value)
        assert(not combat, "Protected attribute changed in combat")
        assert(nativeSetup or not self.buttonType, "Addon changed native secure button attributes")
        self.attributes[name] = value
    end
    function frame:GetAttribute(name) return self.attributes[name] end
    function frame:GetShowGrid() return (self:GetAttribute("showgrid") or 0) > 0 end
    function frame:SetShowGrid() end
    function frame:HasAction() return self.hasAction end
    function frame:UpdateAction()
        if self.bar then self.bar:UpdateShownButtons() end
    end
    function frame:CalculateAction()
        return self:GetID() + ((SecureAttribute(self, "actionpage") - 1) * 12)
    end
    function frame:Click(button, down)
        assert(self.OnClick, "Native click script missing")
        self.OnClick(self, button, down)
    end
    function frame:UpdateHotkeys(buttonType)
        self.bindingAction = buttonType .. self:GetID()
        self.HotKey:SetText(self.bindingAction)
    end
    function frame:RegisterEvent(event) events[event] = self end
    function frame:SetScript(script, callback)
        assert(nativeSetup or not self.buttonType or script ~= "OnClick", "Addon replaced native secure click script")
        self[script] = callback
    end
    function frame:HookScript(script, callback)
        local original = self[script]
        self[script] = function(...)
            if original then original(...) end
            callback(...)
        end
    end
    function frame:SetAtlas(atlas) self.atlas = atlas end
    function frame:CreateTexture() return Frame("texture") end
    function frame:ResizeContainerBars()
        for _, bar in ipairs(self.bars) do
            bar:SetWidth(self:GetWidth() - 2)
            bar.StatusBar:SetWidth(self:GetWidth() - 2)
        end
    end
    function frame:GetExpectedSegments() return 20 end
    function frame:UpdateDividers(numSegments)
        self.dividers = self.dividers or {}
        for index = 1, numSegments - 1 do
            local divider = self.dividers[index] or Frame("statusDivider")
            self.dividers[index] = divider
            divider:ClearAllPoints()
            divider:SetPoint("LEFT", self, "LEFT", self:GetWidth() / numSegments * index, 0)
        end
    end
    function frame:UpdateBarTick()
        for _, bar in ipairs(self.bars) do
            bar:UpdateTick()
        end
    end
    function frame:SetText(text) self.text = text end
    function frame:GetText() return self.text end
    frame.ApplySystemAnchor = Forbidden
    frame.AnchorSelectionFrame = function() end
    frame.Layout = Forbidden
    frame.UpdateGridLayout = Forbidden
    frame.UpdateShownButtons = Forbidden
    frame.GetSettingValue = Forbidden
    return frame
end

SecureAttribute = function(frame, name)
    local value = frame:GetAttribute(name)
    if value == nil and frame:GetAttribute("useparent-" .. name) then
        local parent = frame.bar or frame:GetParent()
        if parent then return SecureAttribute(parent, name) end
    end
    return value
end

local function NativeClick(button, inputButton, down)
    button.lastClick = { action = button:CalculateAction(), button = inputButton, down = down,
        unit = SecureAttribute(button, "unit") }
end

function CreateFrame(frameType, name, parent, template, id)
    local frame = Frame(name or "anonymous")
    frame.parent, frame.template, frame.id = parent, template, id
    if frameType == "CheckButton" then
        assert(nativeSetup, "Addon must reuse native secure buttons, not create tainted copies")
        frame.attributes.type = "action"
        frame.attributes["useparent-actionpage"] = true
        frame.attributes["useparent-unit"] = true
        frame.hasAction = true
        frame.HotKey = Frame("hotkey")
        frame.SlotArt, frame.SlotBackground = Frame("slotArt"), Frame("slotBackground")
        frame.SlotArt.protected, frame.SlotBackground.protected = false, false
        frame.UpdateButtonArt = function(self)
            self.SlotArt:SetShown(self.buttonType == "ACTIONBUTTON")
            self.SlotBackground:SetShown(self.buttonType ~= "ACTIONBUTTON")
        end
        frame.UpdateUsable = function() end
        local buttonTypes = { MainBarActionBarButtonTemplate = "ACTIONBUTTON",
            MultiBar1ButtonTemplate = "MULTIACTIONBAR1BUTTON", MultiBar2ButtonTemplate = "MULTIACTIONBAR2BUTTON" }
        frame.buttonType = assert(buttonTypes[template], "Unexpected button template")
        frame:UpdateButtonArt()
        frame.OnClick = NativeClick
    end
    if name then _G[name] = frame end
    table.insert(createdFrames, frame)
    return frame
end

function InCombatLockdown() return combat end
function hooksecurefunc(frame, method, callback)
    hooks[frame] = hooks[frame] or {}
    hooks[frame][method] = callback
    local original = assert(frame[method], "Cannot hook missing method " .. method)
    frame[method] = function(...)
        original(...)
        callback(...)
    end
end
C_Timer = { After = function(_, callback) table.insert(timers, callback) end }
EventRegistry = { RegisterCallback = function(_, event, callback) callbacks[event] = callback end }
C_EditMode = setmetatable({}, { __index = Forbidden, __newindex = Forbidden })
local legacyState = setmetatable({}, { __index = Forbidden, __newindex = Forbidden })
ErzbaroneUILayout = legacyState

local function Flush()
    local iterations = 0
    while #timers > 0 do
        iterations = iterations + 1
        assert(iterations < 20, "Layout event/update loop")
        local batch = timers
        timers = {}
        for _, callback in ipairs(batch) do callback() end
    end
end

local function Notify()
    local frame = events.EDIT_MODE_LAYOUTS_UPDATED
    frame.OnEvent(frame, "EDIT_MODE_LAYOUTS_UPDATED")
    Flush()
end

local function Pool()
    return {
        active = {},
        EnumerateActive = function(self) return next, self.active end,
    }
end

local function Setup(deferInitialization)
    nativeSetup = true
    timers, hooks, events, callbacks, createdFrames, messages = {}, {}, {}, {}, {}, {}
    UIParent = Frame("UIParent")
    UIParent.width, UIParent.height, UIParent.scale = 1920, 1080, 0.8
    ErzbaroneUI = { Chat = { UpdatePosition = function() end } }
    MainActionBar, MultiBarBottomLeft, MultiBarBottomRight = Frame("MainActionBar"), Frame("MultiBarBottomLeft"), Frame("MultiBarBottomRight")
    local suffixes = { "Main", "BottomLeft", "BottomRight" }
    local templates = { "MainBarActionBarButtonTemplate", "MultiBar1ButtonTemplate", "MultiBar2ButtonTemplate" }
    local pages = { 1, 6, 5 }
    local prefixes = { "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton" }
    for barIndex, bar in ipairs({ MainActionBar, MultiBarBottomLeft, MultiBarBottomRight }) do
        _G["ErzbaroneUI" .. suffixes[barIndex] .. "SecureBar"] = nil
        bar.parent = UIParent
        bar.Selection = Frame("actionSelection")
        bar.Selection.parent = bar
        bar.Selection.points = {
            { "TOPLEFT", bar, "TOPLEFT", 0, 0 },
            { "BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0 },
        }
        bar.buttonTemplate, bar.actionButtons = templates[barIndex], {}
        bar.minButtonPadding, bar.buttonPadding = 2, 2
        bar:SetAttribute("actionpage", pages[barIndex])
        bar:SetAttribute("unit", "player")
        bar.UpdateShownButtons = function(self)
            for _, button in ipairs(self.actionButtons) do
                button:SetShown(not button:GetAttribute("statehidden") and (button:HasAction() or button:GetShowGrid()))
            end
        end
        for index = 1, 12 do
            local container = Frame("nativeContainer")
            container.parent = bar
            local button = CreateFrame("CheckButton", prefixes[barIndex] .. index, container, bar.buttonTemplate, index)
            button.container, button.index = container, index
            button.bar = bar
            button.commandName = button.buttonType .. index
            button:SetPoint("CENTER", container, "CENTER")
            button:UpdateHotkeys(button.buttonType)
            bar.actionButtons[index] = button
        end
    end
    MainActionBar.actionButtons[2]:SetAttribute("showgrid", 2)
    MainActionBar.BorderArt = Frame("mainBarArt")
    MainActionBar.HorizontalDividersPool, MainActionBar.VerticalDividersPool = Pool(), Pool()
    for _, pool in ipairs({ MainActionBar.HorizontalDividersPool, MainActionBar.VerticalDividersPool }) do
        local divider = Frame("actionDivider")
        pool.active[divider] = true
    end
    MainActionBar.UpdateDividers = function() end
    MainActionBar.EndCaps = Frame("endCaps")
    MainActionBar.EndCaps.parent = MainActionBar
    local caps = MainActionBar.EndCaps
    caps.LeftEndCap, caps.RightEndCap = Frame("leftCap"), Frame("rightCap")
    caps.LeftEndCap.width, caps.RightEndCap.width, caps.LeftEndCap.left = 100, 100, 600
    for _, cap in ipairs({ caps.LeftEndCap, caps.RightEndCap }) do
        cap.protected = false
        cap.ClearAllPointsBase, cap.SetPointBase = cap.ClearAllPoints, cap.SetPoint
        cap.ClearAllPoints, cap.SetPoint = Forbidden, Forbidden
    end
    MainActionBar.ActionBarPageNumber = Frame("pageNumber")
    MainActionBar.ActionBarPageNumber.parent = MainActionBar
    PlayerCastingBarFrame = Frame("playerCastBar")
    PlayerCastingBarFrame.protected = false
    PlayerCastingBarFrame.GetEffectiveScale = function(self)
        return self:GetScale() * UIParent:GetEffectiveScale()
    end
    StanceBar, PetActionBar = Frame("StanceBar"), Frame("PetActionBar")
    PossessActionBar, MainMenuBarVehicleLeaveButton = Frame("PossessActionBar"), Frame("vehicleLeave")
    for _, bar in ipairs({ StanceBar, PetActionBar, PossessActionBar, MainMenuBarVehicleLeaveButton }) do
        bar.parent = bar == MainMenuBarVehicleLeaveButton and MainActionBar or UIParent
        bar.height = 30
        bar.shown = bar == StanceBar or bar == PetActionBar
        bar.ClearAllPointsBase, bar.SetPointBase = bar.ClearAllPoints, bar.SetPoint
        bar.ClearAllPoints, bar.SetPoint = Forbidden, Forbidden
        bar.GetEffectiveScale = function(self)
            local parentScale = self.parent == MainActionBar and MainActionBar:GetScale() or 1
            return self:GetScale() * parentScale * UIParent:GetEffectiveScale()
        end
        bar.nativeClick = function(self) self.clicked = true end
        bar.OnClick = bar.nativeClick
        bar.OnShow = function(self) self.nativeShowCalled = true end
        if bar ~= MainMenuBarVehicleLeaveButton then
            bar.actionButtons = {}
            bar.width = 94
            bar.UpdateGridLayout = function() end
            for index = 1, 3 do
                local container = Frame("auxiliaryContainer")
                container.parent = bar
                container:SetSize(30, 30)
                container:ClearAllPoints()
                container:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", (index - 1) * 32, 0)
                local button = Frame("auxiliaryButton")
                button.parent, button.container, button.bar = container, container, bar
                button.OnClick = bar.nativeClick
                button:ClearAllPoints()
                button:SetPoint("CENTER", container, "CENTER", 0, 0)
                bar.actionButtons[index] = button
                if bar == StanceBar and index == 3 then
                    container:ClearAllPoints()
                    container.shown, button.shown = false, false
                end
            end
        end
    end
    MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer = Frame("mainStatus"), Frame("secondaryStatus")
    for _, bar in ipairs({ MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer }) do
        bar.protected = false
        bar.width, bar.height = 1000, 17
        bar.BarFrameTexture = Frame("statusTexture")
        bar.BarFrameTexture.width = 1000
        local experience = Frame("experience")
        experience.StatusBar = Frame("experienceFill")
        experience.ExhaustionTick = Frame("exhaustionTick")
        experience.UpdateTick = function(self)
            self.ExhaustionTick:ClearAllPoints()
            self.ExhaustionTick:SetPoint("CENTER", self, "LEFT", self:GetWidth() * 0.6, 0)
        end
        bar.bars = { experience }
        bar:ResizeContainerBars()
        bar:UpdateDividers(bar:GetExpectedSegments())
        bar:UpdateBarTick()
        bar.ClearAllPointsBase, bar.SetPointBase = bar.ClearAllPoints, bar.SetPoint
        bar.ClearAllPoints, bar.SetPoint = Forbidden, Forbidden
    end
    StatusTrackingBarManager = { GetExpectedWidth = Forbidden, UpdateBarsShown = function() end,
        CheckForLayoutChange = function() end }
    MicroMenuContainer, MicroMenu, BagsBar = Frame("MicroMenuContainer"), Frame("MicroMenu"), Frame("BagsBar")
    MicroMenuContainer.parent = UIParent
    MicroMenu.parent = MicroMenuContainer
    MicroMenuContainer.Selection = Frame("menuSelection")
    MicroMenuContainer.Selection.parent = MicroMenuContainer
    MicroMenuContainer.Selection.points = {
        { "TOPLEFT", MicroMenuContainer, "TOPLEFT", 0, 0 },
        { "BOTTOMRIGHT", MicroMenuContainer, "BOTTOMRIGHT", 0, 0 },
    }
    BagsBar.parent = UIParent
    BagsBar.SetScaleBase, BagsBar.SetScale = BagsBar.SetScale, Forbidden
    BagsBar.SetShownBase = BagsBar.SetShown
    BagsBar.OnUpdateEndCaps = function() end
    MainActionBar.initialized = not deferInitialization
    EditModeManagerFrame = nil
    nativeSetup = false
    dofile(root .. "modules\\utils.lua")
    dofile(root .. "modules\\rangetint.lua")
    dofile(root .. "modules\\actionlayout.lua")
    dofile(root .. "modules\\mainbar.lua")
    ErzbaroneUI.MainBar:Initialize()
    MainActionBar.initialized = true
    Flush()
end

local function AssertCustomShape()
    for barIndex, bar in ipairs({ ErzbaroneUIMainSecureBar, ErzbaroneUIBottomLeftSecureBar, ErzbaroneUIBottomRightSecureBar }) do
        Equal(bar:IsShown(), true, "Custom bar remains shown")
        Equal(#bar.actionButtons, 12)
        for index, button in ipairs(bar.actionButtons) do
            local point, parent, relativePoint, x, y = button.container:GetPoint(1)
            local columns = barIndex == 3 and 6 or 12
            Equal(point, "BOTTOMLEFT")
            Equal(parent, bar)
            Equal(relativePoint, "BOTTOMLEFT")
            Equal(x, ((index - 1) % columns) * 38, "Custom column survives Edit Mode changes")
            if barIndex == 3 and index > 6 then
                assert(y > 0, "Action Bar 3 retains its upper row")
            else
                Equal(y, 0)
            end
        end
    end
    Equal(MainActionBar.actionButtons[1]:IsMouseEnabled(), true, "Native secure buttons remain clickable")
    Equal(MainActionBar.BorderArt:IsShown(), false)
    for _, pool in ipairs({ MainActionBar.HorizontalDividersPool, MainActionBar.VerticalDividersPool }) do
        for divider in pool:EnumerateActive() do
            Equal(divider:GetAlpha(), 0, "Native dividers must not be left at old button anchors")
        end
    end
end

local nativePrint = print
print = function(message) table.insert(messages, message) end
ErzbaroneUISettings = { compactMainBar = false }
Setup()
Equal(ErzbaroneUIMainSecureBar, nil, "Disabled option does not create bars")
ErzbaroneUISettings.compactMainBar = true
ErzbaroneUI.MainBar:Update()
Flush()
AssertCustomShape()
Equal(ErzbaroneUILayout, legacyState, "Legacy profile state is ignored")
local customMainBar = ErzbaroneUIMainSecureBar
local customBar2, customBar3 = ErzbaroneUIBottomLeftSecureBar, ErzbaroneUIBottomRightSecureBar
local function AssertMainBarFrameFollowsCustomBar()
    Equal(MainActionBar:GetNumPoints(), customMainBar:GetNumPoints())
    for index = 1, customMainBar:GetNumPoints() do
        local nativePoint = { MainActionBar:GetPoint(index) }
        local customPoint = { customMainBar:GetPoint(index) }
        Equal(#nativePoint, #customPoint)
        for valueIndex, value in ipairs(customPoint) do
            Equal(nativePoint[valueIndex], value, "Native main bar frame follows its compact action row")
        end
    end
end
AssertMainBarFrameFollowsCustomBar()
local function AssertSelection(selection, target)
    Equal(selection:GetNumPoints(), 2)
    local system = selection:GetParent()
    local scale = target:GetEffectiveScale() / system:GetEffectiveScale()
    local point, relative, relativePoint, x, y = selection:GetPoint(1)
    Equal(point, "TOPLEFT")
    Equal(relative, system, "Selection offsets remain relative to the native system for Edit Mode snapping")
    Equal(relativePoint, "TOPLEFT")
    assert(math.abs(system:GetLeft() + x - target:GetLeft() * scale) < 0.0001)
    assert(math.abs(system:GetTop() + y - target:GetTop() * scale) < 0.0001)
    point, relative, relativePoint, x, y = selection:GetPoint(2)
    Equal(point, "BOTTOMRIGHT")
    Equal(relative, system)
    Equal(relativePoint, "BOTTOMRIGHT")
    assert(math.abs(system:GetRight() + x - target:GetRight() * scale) < 0.0001)
    assert(math.abs(system:GetBottom() + y - target:GetBottom() * scale) < 0.0001)
end
for index, bar in ipairs({ MainActionBar, MultiBarBottomLeft, MultiBarBottomRight }) do
    AssertSelection(bar.Selection, ({ customMainBar, customBar2, customBar3 })[index])
end
AssertSelection(MicroMenuContainer.Selection, MicroMenu:GetParent())
Equal(customMainBar.template, "SecureHandlerStateTemplate")
Equal(customMainBar.ignoreInLayout, true, "Custom containers do not participate in the native ResizeLayoutFrame")
Equal(customMainBar:GetParent(), MainActionBar, "Native visibility remains inherited")
Equal(customMainBar.actionButtons, MainActionBar.actionButtons, "Reuse the native secure buttons")
Equal(customMainBar.actionButtons[1].bar, MainActionBar, "Never overwrite the trusted native paging reference")
Equal(customMainBar.actionButtons[1].template, "MainBarActionBarButtonTemplate")
Equal(customBar2.actionButtons[1].template, "MultiBar1ButtonTemplate")
Equal(customBar3.actionButtons[1].template, "MultiBar2ButtonTemplate")
Equal(customMainBar.actionButtons[1].bindingAction, "ACTIONBUTTON1")
Equal(customBar2.actionButtons[1].bindingAction, "MULTIACTIONBAR1BUTTON1")
Equal(customBar3.actionButtons[1].bindingAction, "MULTIACTIONBAR2BUTTON1")
Equal(SecureAttribute(customMainBar.actionButtons[1], "actionpage"), 1)
Equal(SecureAttribute(customBar2.actionButtons[1], "actionpage"), 6)
Equal(SecureAttribute(customBar3.actionButtons[1], "actionpage"), 5)
Equal(customMainBar.actionButtons[2]:GetAttribute("showgrid"), 2)
Equal(customMainBar.background.atlas, "UI-HUD-ActionBar-Frame")
Equal(customBar3.background.atlas, "UI-HUD-ActionBar-Frame")

local function AssertEndCapsResistNativeAnchors()
    for _, cap in ipairs({ MainActionBar.EndCaps.LeftEndCap, MainActionBar.EndCaps.RightEndCap }) do
        local expected = { cap:GetPoint(1) }
        for attempt = 1, 3 do
            cap:ClearAllPointsBase()
            Equal(cap:GetNumPoints(), 1, "Native clearing cannot leave gryphons unanchored for a frame")
            cap:SetPointBase("BOTTOM", MainActionBar, "BOTTOM", 0, 0)
            Equal(cap:GetNumPoints(), 1, "Native updates cannot leave competing gryphon anchors")
            local actual = { cap:GetPoint(1) }
            for index, value in ipairs(expected) do
                Equal(actual[index], value, "Gryphon anchors are corrected before queued layout updates")
            end
        end
    end
end

AssertEndCapsResistNativeAnchors()
combat = true
AssertEndCapsResistNativeAnchors()
combat = false
for index, button in ipairs(customBar3.actionButtons) do
    Equal(button.SlotArt:IsShown(), index <= 6, "Only the lower six buttons receive main-bar slot art")
    Equal(button.SlotBackground:IsShown(), index > 6, "Upper row keeps its native backdrop")
    button:UpdateButtonArt()
    Equal(button.SlotArt:IsShown(), index <= 6, "Native art refresh preserves the lower-row backdrop")
end
Equal(customBar2.actionButtons[1].SlotArt:IsShown(), false, "Action Bar 2 artwork is unchanged")
local foundCustom = false
ErzbaroneUI.Utils:ForEachActionButton(function(button)
    if button == customMainBar.actionButtons[1] then foundCustom = true end
end)
assert(foundCustom, "Hosted native buttons remain included in shared addon features")
Equal(customMainBar.actionButtons[1].OnClick, NativeClick, "Native click script remains intact")
customMainBar.actionButtons[1]:Click("LeftButton", false)
Equal(customMainBar.actionButtons[1].lastClick.action, 1, "Left click executes the native action")
customBar2.actionButtons[12]:Click("RightButton", false)
Equal(customBar2.actionButtons[12].lastClick.action, 72, "Right click uses the native secondary page")
Equal(customBar2.actionButtons[12].lastClick.button, "RightButton")
Equal(customBar2.actionButtons[12].lastClick.unit, "player", "Unit inheritance stays on the native bar")
for _, bar in ipairs({ MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer }) do
    Equal(bar:GetWidth(), 684, "Status bars fit the custom action block")
    local point, parent, relativePoint, x, y = bar:GetPoint(1)
    Equal(point, "BOTTOMLEFT")
    Equal(parent, UIParent)
    Equal(relativePoint, "BOTTOM")
    Equal(x, -342)
    assert(y > 36, "Status bars sit between action rows")
    local xp = bar.bars[1]
    Equal(xp:GetWidth(), 682)
    Equal(xp.StatusBar:GetWidth(), 682, "XP fill is resized along with its container")
    local _, _, _, tickX = xp.ExhaustionTick:GetPoint(1)
    Equal(tickX, 682 * 0.6, "Exhaustion marker is recalculated at the new XP width")
    for index, divider in ipairs(bar.dividers) do
        local _, _, _, dividerX = divider:GetPoint(1)
        Equal(dividerX, 684 / 20 * index, "XP dividers remain inside the resized bar")
    end
    bar:SetSize(1000, bar:GetHeight())
    Equal(bar:GetWidth(), 684, "Late native startup sizing is corrected synchronously")
    bar:ResizeContainerBars()
    bar:UpdateDividers(20)
    Equal(bar:GetWidth(), 684, "Native XP updates cannot restore the old width")
    local expectedY = y
    for attempt = 1, 3 do
        bar:ClearAllPointsBase()
        bar:SetPointBase("BOTTOM", UIParent, "BOTTOMLEFT", 342, 43)
        Equal(bar:GetNumPoints(), 1, "Native repositioning must not leave competing XP anchors")
        local anchor, relativeTo, relativeAnchor, offsetX, offsetY = bar:GetPoint(1)
        Equal(anchor, "BOTTOMLEFT", "Direct native positioning cannot move the XP bar")
        Equal(relativeTo, UIParent)
        Equal(relativeAnchor, "BOTTOM")
        Equal(offsetX, -342)
        Equal(offsetY, expectedY)
    end
end
local menuAnchor = MicroMenu:GetParent()
local menuPoint, menuRelative, menuRelativePoint, menuX, menuY = menuAnchor:GetPoint(1)
Equal(menuPoint, "BOTTOMRIGHT")
Equal(menuRelative, BagsBar, "Menu follows the bag bar")
Equal(menuRelativePoint, "BOTTOMLEFT")
Equal(menuX, -8, "Menu leaves an eight-unit gap left of the bags")
Equal(menuY, 0, "Menu and bags share a bottom edge")
Equal(menuAnchor:GetLeft() + menuAnchor:GetWidth(),
    BagsBar:GetLeft() * BagsBar:GetEffectiveScale() / menuAnchor:GetEffectiveScale() - 8)
Equal(BagsBar:GetScale(), 1)
local originalBagWidth = BagsBar:GetWidth()
BagsBar:SetWidth(originalBagWidth + 40)
BagsBar:SetScaleBase(0.75)
hooks[BagsBar].SetScale(BagsBar, 0.75)
Flush()
AssertSelection(MicroMenuContainer.Selection, menuAnchor)
assert(math.abs(menuAnchor:GetLeft() + menuAnchor:GetWidth()
    - BagsBar:GetLeft() * BagsBar:GetEffectiveScale() / menuAnchor:GetEffectiveScale() + 8) < 0.0001,
    "Gap remains fixed when bags change width and scale")
assert(math.abs(menuAnchor:GetBottom()
    - BagsBar:GetBottom() * BagsBar:GetEffectiveScale() / menuAnchor:GetEffectiveScale()) < 0.0001,
    "Bottom edges remain aligned when bags change scale")
ErzbaroneUISettings.microMenuPosition = "aboveBags"
ErzbaroneUI.MainBar:Update()
Equal(menuAnchor:GetPoint(1), "BOTTOMRIGHT")
Equal(select(2, menuAnchor:GetPoint(1)), BagsBar)
Equal(select(3, menuAnchor:GetPoint(1)), "TOPRIGHT")
assert(math.abs(menuAnchor:GetRight()
    - BagsBar:GetRight() * BagsBar:GetEffectiveScale() / menuAnchor:GetEffectiveScale()) < 0.0001,
    "Above-bags preset aligns right edges with scaled bags")
assert(math.abs(menuAnchor:GetBottom()
    - BagsBar:GetTop() * BagsBar:GetEffectiveScale() / menuAnchor:GetEffectiveScale() - 8) < 0.0001,
    "Above-bags preset keeps an eight-unit vertical gap")
AssertSelection(MicroMenuContainer.Selection, menuAnchor)
combat = true
ErzbaroneUISettings.microMenuPosition = "bottomLeft"
ErzbaroneUI.MainBar:Update()
Equal(ErzbaroneUI.MainBar.PendingUpdate, true)
Equal(select(2, menuAnchor:GetPoint(1)), BagsBar, "Position changes wait until combat ends")
combat = false
events.PLAYER_REGEN_ENABLED.OnEvent(events.PLAYER_REGEN_ENABLED, "PLAYER_REGEN_ENABLED")
Flush()
menuPoint, menuRelative, menuRelativePoint, menuX, menuY = menuAnchor:GetPoint(1)
Equal(menuPoint, "BOTTOMRIGHT")
Equal(menuRelative, UIParent)
Equal(menuRelativePoint, "BOTTOMLEFT")
local leftCap = MainActionBar.EndCaps.LeftEndCap
Equal(menuX, leftCap:GetLeft() * leftCap:GetEffectiveScale() / UIParent:GetEffectiveScale() - 8)
Equal(menuY, 12)
AssertSelection(MicroMenuContainer.Selection, menuAnchor)
local originalCapLeft, originalCapScale = leftCap.left, leftCap:GetScale()
leftCap.left = nil
leftCap:SetScale(0.75)
ErzbaroneUI.MainBar:Update()
assert(math.abs(menuAnchor:GetRight()
    - leftCap:GetLeft() * leftCap:GetEffectiveScale() / menuAnchor:GetEffectiveScale() + 8) < 0.0001,
    "Gryphon preset keeps an eight-unit gap beside the actual scaled gryphon")
assert(menuAnchor:GetRight() <= MainActionBar:GetLeft(),
    "Left-of-gryphons menu no longer overlaps the native main action bar frame")
Equal(menuAnchor:GetBottom(), 12, "Gryphon preset stays near the screen bottom")
leftCap.left = originalCapLeft
leftCap:SetScale(originalCapScale)
ErzbaroneUISettings.microMenuPosition = "besideBags"
ErzbaroneUI.MainBar:Update()
Equal(select(3, menuAnchor:GetPoint(1)), "BOTTOMLEFT", "Switching back restores the existing preset")
BagsBar:SetWidth(originalBagWidth)
BagsBar:SetScaleBase(1)
hooks[BagsBar].SetScale(BagsBar, 1)
Flush()
MicroMenuContainer:ClearAllPoints()
MicroMenuContainer:SetPoint("BOTTOM", UIParent, "BOTTOM", 35, 40)
Flush()
AssertSelection(MicroMenuContainer.Selection, menuAnchor)
Equal(ErzbaroneUI.MainBar:GetChatBottomInset(), 0)

-- Only Edit Mode's UI visibility is available; all profile operations are forbidden.
EditModeManagerFrame = setmetatable({
    IsEditModeActive = function() return editModeActive end,
}, { __index = Forbidden, __newindex = Forbidden })
editModeActive = true
for _, bar in ipairs({ MainActionBar, MultiBarBottomLeft, MultiBarBottomRight, MicroMenuContainer }) do
    bar:AnchorSelectionFrame()
end
Flush()
MainActionBar.BorderArt:Show()
MainActionBar:ClearAllPoints()
MainActionBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 100)
hooks[MainActionBar].UpdateGridLayout()
Notify()
AssertCustomShape()
AssertMainBarFrameFollowsCustomBar()
for index, bar in ipairs({ MainActionBar, MultiBarBottomLeft, MultiBarBottomRight }) do
    AssertSelection(bar.Selection, ({ customMainBar, customBar2, customBar3 })[index])
end
AssertSelection(MicroMenuContainer.Selection, MicroMenu:GetParent())
local lateDivider = Frame("lateActionDivider")
MainActionBar.HorizontalDividersPool.active[lateDivider] = true
MainActionBar:UpdateDividers()
Equal(lateDivider:GetAlpha(), 0, "Newly acquired native dividers are suppressed immediately")
Equal(ErzbaroneUISettings.compactMainBar, true)
editModeActive = false
callbacks["EditMode.Exit"]()
Flush()
AssertCustomShape()
MultiBarBottomLeft:Hide()
Equal(customBar2:IsVisible(), false, "Disabled native bars hide their custom counterparts")
MultiBarBottomLeft:Show()
Equal(customBar2:IsVisible(), true)

local function AssertBlockWidth(width)
    local _, _, _, mainX = customMainBar:GetPoint(1)
    Equal(mainX, -width / 2, "Action block is centered at its active width")
    for _, bar in ipairs({ MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer }) do
        Equal(bar:GetWidth() * bar:GetScale(), width, "Status bars match the active action block")
        local _, _, _, x = bar:GetPoint(1)
        Equal(x * bar:GetScale(), -width / 2, "Status bars align with the active action block")
    end
    local _, _, _, leftX = MainActionBar.EndCaps.LeftEndCap:GetPoint(1)
    local _, _, _, rightX = MainActionBar.EndCaps.RightEndCap:GetPoint(1)
    Equal(leftX, 30, "Left gryphon follows the block's left edge")
    Equal(rightX, width - 30, "Right gryphon follows the block's right edge")
    AssertMainBarFrameFollowsCustomBar()
    AssertEndCapsResistNativeAnchors()
end

local function AssertAuxiliaryPosition(bar, left, bottom)
    local point, parent, relativePoint, x, y = bar:GetPoint(1)
    local scale = bar:GetEffectiveScale() / UIParent:GetEffectiveScale()
    Equal(bar:GetNumPoints(), 1, "Auxiliary bars retain a single runtime anchor")
    Equal(point, "BOTTOMLEFT")
    Equal(parent, UIParent)
    Equal(relativePoint, "BOTTOM")
    assert(math.abs(x * scale - left) < 0.000001, "Auxiliary controls align with the active block's left edge")
    assert(math.abs(y * scale - bottom) < 0.000001, "Auxiliary controls sit above the highest active row")
    Equal(bar.OnClick, bar.nativeClick, "Native auxiliary click handlers remain untouched")
end

local function AssertAuxiliaryStack(left, top)
    AssertAuxiliaryPosition(StanceBar, left, top + 4)
    AssertAuxiliaryPosition(PetActionBar, left, top + 38)
    AssertAuxiliaryPosition(PossessActionBar, left, top + 72)
    AssertAuxiliaryPosition(MainMenuBarVehicleLeaveButton, left, top + 72)
end

local function AssertCombatAuxiliaryButtons()
    local positions = {}
    for _, bar in ipairs({ StanceBar, PetActionBar, PossessActionBar }) do
        for _, button in ipairs(bar.actionButtons) do
            local x, y = button:GetCenter()
            if x and y then
                local scale = button:GetEffectiveScale() / UIParent:GetEffectiveScale()
                positions[button] = { x * scale, y * scale, button:IsVisible() }
            end
        end
    end
    combat = true
    for _, bar in ipairs({ StanceBar, PetActionBar, PossessActionBar }) do
        -- Model Blizzard's privileged anchor writes without allowing addon writes in combat.
        bar.points = { { "BOTTOMLEFT", UIParent, "BOTTOMLEFT", 5, 500 } }
        hooks[bar].SetPointBase(bar)
        bar:UpdateGridLayout()
    end
    Flush()
    for button, position in pairs(positions) do
        local x, y = button:GetCenter()
        local scale = button:GetEffectiveScale() / UIParent:GetEffectiveScale()
        assert(math.abs(x * scale - position[1]) < 0.000001,
            "Native combat layout must not shift auxiliary buttons horizontally")
        assert(math.abs(y * scale - position[2]) < 0.000001,
            "Native combat layout must not shift auxiliary buttons vertically")
        Equal(button:IsVisible(), position[3], "Stable anchors preserve native visibility")
        Equal(button:GetParent(), button.container, "Native auxiliary button parents remain intact")
        Equal(button.container:GetParent(), button.bar, "Native grid containers remain on their bar")
        button:Click()
        Equal(button.clicked, true, "Original auxiliary click handlers still work in combat")
    end
    Equal(ErzbaroneUI.MainBar.PendingUpdate, true)
    combat = false
    local regen = events.PLAYER_REGEN_ENABLED
    regen.OnEvent(regen, "PLAYER_REGEN_ENABLED")
    Flush()
end

local function AssertCastBar(top)
    local point, parent, relativePoint, x, y = PlayerCastingBarFrame:GetPoint(1)
    local scale = PlayerCastingBarFrame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    Equal(PlayerCastingBarFrame:GetNumPoints(), 1)
    Equal(point, "BOTTOM")
    Equal(parent, UIParent)
    Equal(relativePoint, "BOTTOM")
    Equal(x, 0)
    assert(math.abs(y * scale - (top + 32)) < 0.000001, "Cast bar clears the upper action row by 32 UI units")
end

local function AssertNativeCastBar()
    local _, _, _, x, y = PlayerCastingBarFrame:GetPoint(1)
    Equal(x, 20, "Single-row/disabled layout restores the original cast-bar position")
    Equal(y, 30)
end

Flush()
AssertAuxiliaryStack(-342, 115)
AssertCastBar(115)
MultiBarBottomLeft:Hide()
Flush()
AssertCastBar(115)
MultiBarBottomLeft:Show()
Flush()
PlayerCastingBarFrame:SetScale(1.5)
Flush()
AssertCastBar(115)
PlayerCastingBarFrame:ClearAllPoints()
PlayerCastingBarFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 100)
AssertCastBar(115)
PlayerCastingBarFrame:SetScale(1)
MultiBarBottomRight:Hide()
Flush()
AssertBlockWidth(454)
AssertAuxiliaryStack(-227, 115)
AssertCastBar(115)
Equal(customBar3:IsVisible(), false, "Disabled Action Bar 3 has no visible row or backdrop")
Equal(customBar2:IsVisible(), true, "Two-bar layout retains Action Bar 2")
local _, _, _, _, compactUpperY = customBar2:GetPoint(1)
Equal(compactUpperY, 79, "Two-bar layout keeps status bars between the action rows")

-- Disabled bars must not affect the remaining block's dimensions or spacing.
MultiBarBottomLeft:SetScale(1.5)
MultiBarBottomRight:SetScale(2)
MultiBarBottomLeft:Hide()
Flush()
AssertBlockWidth(454)
AssertAuxiliaryStack(-227, 76)
AssertNativeCastBar()
Equal(customBar2:IsVisible(), false, "Both optional bars disabled collapses to the main row")
local _, _, _, _, singleStatusY = SecondaryStatusTrackingBarContainer:GetPoint(1)
Equal(singleStatusY, 43, "Single-row layout places status bars immediately above the main row")
MultiBarBottomLeft:Show()
Flush()
AssertBlockWidth(681)
AssertAuxiliaryStack(-340.5, 133)
AssertCastBar(133)
MultiBarBottomLeft:SetScale(1)
MultiBarBottomRight:SetScale(1)
MultiBarBottomRight:Show()
Flush()
AssertBlockWidth(684)
AssertCustomShape()
AssertAuxiliaryStack(-342, 115)
AssertCastBar(115)

-- Stance/shapeshift, pet, possession and vehicle controls keep their native visibility.
PossessActionBar:Show()
MainMenuBarVehicleLeaveButton:Show()
Flush()
Equal(PossessActionBar.nativeShowCalled, true, "Existing native OnShow scripts still run")
AssertAuxiliaryPosition(PossessActionBar, -342, 187)
AssertAuxiliaryPosition(MainMenuBarVehicleLeaveButton, -342, 221)
StanceBar:Hide()
PetActionBar:Hide()
Flush()
AssertAuxiliaryPosition(PossessActionBar, -342, 119)
AssertAuxiliaryPosition(MainMenuBarVehicleLeaveButton, -342, 153)
PossessActionBar:Hide()
Flush()
AssertAuxiliaryPosition(MainMenuBarVehicleLeaveButton, -342, 119)
MultiBarBottomRight:Hide()
Flush()
AssertAuxiliaryPosition(MainMenuBarVehicleLeaveButton, -227, 119)
MultiBarBottomLeft:Hide()
Flush()
AssertAuxiliaryPosition(MainMenuBarVehicleLeaveButton, -227, 80)
MainStatusTrackingBarContainer:Hide()
SecondaryStatusTrackingBarContainer:Hide()
hooks[StatusTrackingBarManager].UpdateBarsShown()
Flush()
AssertAuxiliaryPosition(MainMenuBarVehicleLeaveButton, -227, 43)
MainStatusTrackingBarContainer:Show()
SecondaryStatusTrackingBarContainer:Show()
MultiBarBottomLeft:Show()
MultiBarBottomRight:Show()
Flush()
MainMenuBarVehicleLeaveButton:SetScale(1.5)
Flush()
AssertAuxiliaryPosition(MainMenuBarVehicleLeaveButton, -342, 119)
Equal(MainMenuBarVehicleLeaveButton:GetParent(), MainActionBar, "Vehicle control keeps its native parent")
MainActionBar:SetScale(1.25)
Notify()
AssertAuxiliaryPosition(MainMenuBarVehicleLeaveButton, -398.75, 128.75)
AssertCastBar(124.75)
PetActionBar:SetScale(1.5)
Flush()
AssertCombatAuxiliaryButtons()
PetActionBar:SetScale(1)
MainActionBar:SetScale(1)
MainMenuBarVehicleLeaveButton:SetScale(1)
MainMenuBarVehicleLeaveButton:Hide()
StanceBar:Show()
PetActionBar:Show()
Flush()
PetActionBar:SetSize(300, 45)
PetActionBar.OnSizeChanged(PetActionBar)
Flush()
AssertAuxiliaryPosition(MainMenuBarVehicleLeaveButton, -342, 202)
PetActionBar:SetSize(300, 30)
PetActionBar.OnSizeChanged(PetActionBar)
Flush()

for _, bar in ipairs({ StanceBar, PetActionBar, PossessActionBar, MainMenuBarVehicleLeaveButton }) do
    bar:ClearAllPointsBase()
    bar:SetPointBase("BOTTOM", UIParent, "BOTTOMLEFT", 5, 500)
end
AssertAuxiliaryStack(-342, 115)
AssertCombatAuxiliaryButtons()
AssertAuxiliaryStack(-342, 115)

-- A genuine native grid change is reflected without moving or replacing its containers.
local petContainer = PetActionBar.actionButtons[2].container
petContainer:ClearAllPoints()
petContainer:SetPoint("BOTTOMLEFT", PetActionBar, "BOTTOMLEFT", 64, 32)
PetActionBar:UpdateGridLayout()
Flush()
local petX, petY = PetActionBar.actionButtons[2]:GetCenter()
Equal(petX, UIParent:GetWidth() / 2 - 342 + 64 + 15)
Equal(petY, 153 + 32 + 15)
petContainer:ClearAllPoints()
petContainer:SetPoint("BOTTOMLEFT", PetActionBar, "BOTTOMLEFT", 32, 0)
PetActionBar:UpdateGridLayout()
Flush()

-- A secure/native visibility change in combat must defer the geometry update.
combat = true
PlayerCastingBarFrame:ClearAllPoints()
PlayerCastingBarFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 100)
AssertCastBar(115)
MultiBarBottomRight.shown = false
MultiBarBottomRight.OnHide(MultiBarBottomRight)
Flush()
Equal(ErzbaroneUI.MainBar.PendingUpdate, true)
AssertBlockWidth(684)
combat = false
local visibilityRegen = events.PLAYER_REGEN_ENABLED
visibilityRegen.OnEvent(visibilityRegen, "PLAYER_REGEN_ENABLED")
Flush()
AssertBlockWidth(454)
AssertAuxiliaryStack(-227, 115)
Equal(ErzbaroneUI.MainBar.PendingUpdate, false)
MultiBarBottomRight:Show()
Flush()
AssertBlockWidth(684)

-- Controls are pre-positioned while hidden, including when first shown in combat.
combat = true
MainMenuBarVehicleLeaveButton.shown = true
MainMenuBarVehicleLeaveButton.OnShow(MainMenuBarVehicleLeaveButton)
MainMenuBarVehicleLeaveButton:Click()
Flush()
AssertAuxiliaryPosition(MainMenuBarVehicleLeaveButton, -342, 187)
Equal(MainMenuBarVehicleLeaveButton.clicked, true, "Native vehicle/landing clicks still run in combat")
MainMenuBarVehicleLeaveButton.points = { { "BOTTOM", UIParent, "BOTTOMLEFT", 5, 500 } }
hooks[MainMenuBarVehicleLeaveButton].SetPointBase(MainMenuBarVehicleLeaveButton)
Equal(MainMenuBarVehicleLeaveButton:GetPoint(1), "BOTTOM", "Protected auxiliary anchors defer combat corrections")
Equal(ErzbaroneUI.MainBar.PendingUpdate, true)
combat = false
visibilityRegen.OnEvent(visibilityRegen, "PLAYER_REGEN_ENABLED")
Flush()
AssertAuxiliaryPosition(MainMenuBarVehicleLeaveButton, -342, 187)
MainMenuBarVehicleLeaveButton:Hide()
Flush()

local emptyButton = customMainBar.actionButtons[3]
emptyButton.hasAction = false
MainActionBar:UpdateShownButtons()
Equal(emptyButton:IsShown(), false, "Empty buttons respect the native grid setting")
MainActionBar.actionButtons[3].attributes.showgrid = 2
MainActionBar:SetShowGrid()
MainActionBar:UpdateShownButtons()
Flush()
Equal(emptyButton:IsShown(), true, "Native grid changes reach custom buttons")
SecondaryStatusTrackingBarContainer:SetScale(0.75)
SecondaryStatusTrackingBarContainer:Hide()
MainStatusTrackingBarContainer:SetScale(1.25)
hooks[MainStatusTrackingBarContainer].ApplySystemAnchor()
Flush()
for _, bar in ipairs({ SecondaryStatusTrackingBarContainer, MainStatusTrackingBarContainer }) do
    Equal(bar:GetWidth() * bar:GetScale(), 684, "Scaled status bars still fit the action block")
    local _, _, _, x, y = bar:GetPoint(1)
    Equal(x * bar:GetScale(), -342, "Scaled status anchors stay aligned")
    Equal(y * bar:GetScale(), 43, "Hidden status bars do not reserve row height")
    bar:ClearAllPointsBase()
    bar:SetPointBase("BOTTOM", UIParent, "BOTTOMLEFT", 0, 0)
    local _, _, _, anchoredX, anchoredY = bar:GetPoint(1)
    Equal(anchoredX * bar:GetScale(), -342, "Native anchor writes preserve scaled horizontal position")
    Equal(anchoredY * bar:GetScale(), 43, "Native anchor writes preserve scaled vertical position")
end
local _, _, _, _, topRowY = customBar2:GetPoint(1)
Equal(topRowY, 67.25, "Upper action row follows visible scaled status bars")
AssertCastBar(103.25)
SecondaryStatusTrackingBarContainer:SetScale(1)
SecondaryStatusTrackingBarContainer:Show()
MainStatusTrackingBarContainer:SetScale(1)
Notify()

local updater
for _, frame in ipairs(createdFrames) do
    if frame.OnUpdate then updater = frame end
end
assert(updater, "Mouseover updater missing")
updater.OnUpdate(updater, 1)
Equal(BagsBar:GetAlpha(), 0)
Equal(MicroMenu:GetAlpha(), 0)
local bagAlphaWrites, menuAlphaWrites = BagsBar.alphaWrites, MicroMenu.alphaWrites
for _ = 1, 600 do updater.OnUpdate(updater, 1 / 60) end
Equal(BagsBar.alphaWrites, bagAlphaWrites, "Idle bag fades must not write unchanged alpha")
Equal(MicroMenu.alphaWrites, menuAlphaWrites, "Idle menu fades must not write unchanged alpha")
BagsBar:SetAlpha(1)
MicroMenu:SetAlpha(1)
updater.OnUpdate(updater, 1)
Equal(BagsBar:GetAlpha(), 0, "Native alpha changes must not reveal idle bags")
Equal(MicroMenu:GetAlpha(), 0, "Native alpha changes must not reveal the idle menu")
local bagButton = Frame("bagButton")
bagButton.hovered = true
BagsBar.children = { bagButton }
combat = true
customBar3.actionButtons[1]:UpdateButtonArt()
Equal(customBar3.actionButtons[1].SlotArt:IsShown(), true, "Slot backdrop survives art refreshes in combat")
updater.OnUpdate(updater, 1)
Equal(BagsBar:GetAlpha(), 1, "Bag hover still works in combat")
Equal(MicroMenu:GetAlpha(), 0, "Bag hover does not reveal the menu")
MainActionBar.attributes.actionpage = 7
Equal(SecureAttribute(customMainBar.actionButtons[1], "actionpage"), 7, "Paging follows native secure state in combat")
customMainBar.actionButtons[1]:Click("LeftButton", true)
Equal(customMainBar.actionButtons[1].lastClick.action, 73, "Combat clicks follow native page changes")
Equal(customMainBar.actionButtons[1].lastClick.down, true, "Native key-down click handling is preserved")
customMainBar.actionButtons[1]:Click("LeftButton", false)
Equal(customMainBar.actionButtons[1].lastClick.down, false, "Native release handling is preserved")
for _, status in ipairs({ MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer }) do
    local _, _, _, _, expectedY = status:GetPoint(1)
    for attempt = 1, 3 do
        status:ClearAllPointsBase()
        status:SetPointBase("BOTTOM", UIParent, "BOTTOMLEFT", 342, 43)
        Equal(status:GetNumPoints(), 1, "Combat positioning retains a single XP anchor")
        local anchor, _, relativePoint, x, y = status:GetPoint(1)
        Equal(anchor, "BOTTOMLEFT", "Unprotected XP anchors are corrected immediately in combat")
        Equal(relativePoint, "BOTTOM")
        Equal(x, -342)
        Equal(y, expectedY)
    end
end
local status = MainStatusTrackingBarContainer
status.protected = true
status.points = { { "BOTTOM", UIParent, "BOTTOMLEFT", 342, 43 } }
hooks[status].SetPointBase(status)
Equal(status:GetPoint(1), "BOTTOM", "Protected status containers still defer combat anchor corrections")
Equal(ErzbaroneUI.MainBar.PendingUpdate, true)
combat = false
status.protected = false
local regen = events.PLAYER_REGEN_ENABLED
regen.OnEvent(regen, "PLAYER_REGEN_ENABLED")
Flush()
local recoveredAnchor, _, recoveredRelative, recoveredX = status:GetPoint(1)
Equal(recoveredAnchor, "BOTTOMLEFT", "XP anchor is restored after combat")
Equal(recoveredRelative, "BOTTOM")
Equal(recoveredX, -342)
combat = true
hooks[StatusTrackingBarManager].UpdateBarsShown()
Notify()
Equal(ErzbaroneUI.MainBar.PendingUpdate, true)
ErzbaroneUISettings.compactMainBar = false
ErzbaroneUI.MainBar:Update()
Equal(customMainBar:IsShown(), true, "Disabling waits until combat ends")
combat = false
regen = events.PLAYER_REGEN_ENABLED
regen.OnEvent(regen, "PLAYER_REGEN_ENABLED")
Flush()
Equal(ErzbaroneUI.MainBar.PendingUpdate, false)
Equal(customMainBar:IsShown(), false)
AssertNativeCastBar()
for _, bar in ipairs({ StanceBar, PetActionBar, PossessActionBar, MainMenuBarVehicleLeaveButton }) do
    for _, button in ipairs(bar.actionButtons or {}) do
        local point, parent, relativePoint, x, y = button:GetPoint(1)
        Equal(point, "CENTER", "Disabling restores native auxiliary button anchors")
        Equal(parent, button.container)
        Equal(relativePoint, "CENTER")
        Equal(x, 0)
        Equal(y, 0)
        Equal(button:GetParent(), button.container)
    end
    local _, _, _, x, y = bar:GetPoint(1)
    Equal(x, 20, "Disabling restores native auxiliary anchors")
    Equal(y, 30)
    bar:ClearAllPointsBase()
    bar:SetPointBase("BOTTOM", UIParent, "BOTTOM", 25, 35)
    Equal(bar:GetPoint(1), "BOTTOM", "Disabled layout leaves auxiliary positioning alone")
end
Equal(MainActionBar.actionButtons[1]:GetAlpha(), 1)
Equal(MainActionBar.actionButtons[1]:IsMouseEnabled(), true)
Equal(MainActionBar.actionButtons[1].container:GetParent(), MainActionBar, "Disabling restores native button parents")
local _, _, _, restoredX, restoredY = MainActionBar.actionButtons[1].container:GetPoint(1)
Equal(restoredX, 20, "Disabling restores native button anchors")
Equal(restoredY, 30)
local restoredMainPoint, restoredMainRelative, restoredMainRelativePoint, restoredMainX, restoredMainY =
    MainActionBar:GetPoint(1)
Equal(restoredMainPoint, "BOTTOM", "Disabling restores the native main action bar frame")
Equal(restoredMainRelative, UIParent)
Equal(restoredMainRelativePoint, "BOTTOM")
Equal(restoredMainX, 20)
Equal(restoredMainY, 30)
Equal(MainActionBar.BorderArt:IsShown(), true)
for _, cap in ipairs({ MainActionBar.EndCaps.LeftEndCap, MainActionBar.EndCaps.RightEndCap }) do
    local _, _, _, x, y = cap:GetPoint(1)
    Equal(x, 20, "Disabling restores native gryphon anchors")
    Equal(y, 30)
    cap:ClearAllPointsBase()
    Equal(cap:GetNumPoints(), 0, "Disabled layout no longer enforces gryphon anchors")
    cap:SetPointBase("BOTTOM", UIParent, "BOTTOM", 20, 30)
    Equal(cap:GetPoint(1), "BOTTOM")
end
for _, button in ipairs(customBar3.actionButtons) do
    Equal(button.SlotArt:IsShown(), false, "Disabling restores native slot artwork")
    Equal(button.SlotBackground:IsShown(), true, "Disabling restores native slot backgrounds")
    button:UpdateButtonArt()
    Equal(button.SlotArt:IsShown(), false, "Art hooks stop enforcing the backdrop when disabled")
end
Equal(lateDivider:GetAlpha(), 1, "Disabling restores divider alpha")
Equal(MainActionBar.ActionBarPageNumber:GetParent(), MainActionBar)
Equal(MicroMenu:GetParent(), MicroMenuContainer)
AssertSelection(MicroMenuContainer.Selection, MicroMenuContainer)
for _, position in ipairs({ "bottomLeft", "aboveBags", "besideBags" }) do
    ErzbaroneUISettings.microMenuPosition = position
    ErzbaroneUI.MainBar:Update()
    Equal(MicroMenu:GetParent(), MicroMenuContainer, "Presets do not reparent the native menu while disabled")
    local point, relative, relativePoint, x, y = MicroMenu:GetPoint(1)
    Equal(point, "BOTTOM", "Presets leave native anchors unchanged while disabled")
    Equal(relative, UIParent)
    Equal(relativePoint, "BOTTOM")
    Equal(x, 20)
    Equal(y, 30)
    AssertSelection(MicroMenuContainer.Selection, MicroMenuContainer)
end
for _, bar in ipairs({ MainActionBar, MultiBarBottomLeft, MultiBarBottomRight }) do
    AssertSelection(bar.Selection, bar)
end
Equal(BagsBar:GetAlpha(), 1)
for _, bar in ipairs({ MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer }) do
    Equal(bar:GetWidth(), 1000, "Native status width restored")
    Equal(bar.BarFrameTexture:GetWidth(), 1000)
    local _, _, _, x, y = bar:GetPoint(1)
    Equal(x, 20, "Native status anchor restored")
    Equal(y, 30)
    local _, _, _, tickX = bar.bars[1].ExhaustionTick:GetPoint(1)
    Equal(tickX, 998 * 0.6, "Disabling restores the exhaustion marker position")
    local _, _, _, dividerX = bar.dividers[19]:GetPoint(1)
    Equal(dividerX, 950, "Disabling restores native XP divider positions")
    bar:ClearAllPointsBase()
    Equal(bar:GetNumPoints(), 0, "Disabled layout no longer enforces XP anchors")
    bar:SetPointBase("BOTTOM", UIParent, "BOTTOM", 20, 30)
    Equal(bar:GetPoint(1), "BOTTOM", "Disabled layout leaves native repositioning alone")
end

-- Re-enabling captures the current native state instead of reusing stale snapshots.
MainActionBar.actionButtons[1]:SetAlpha(0.7)
MainStatusTrackingBarContainer:SetWidth(900)
ErzbaroneUISettings.compactMainBar = true
ErzbaroneUI.MainBar:Update()
Flush()
AssertCustomShape()
ErzbaroneUISettings.compactMainBar = false
ErzbaroneUI.MainBar:Update()
Equal(MainActionBar.actionButtons[1]:GetAlpha(), 0.7)
Equal(MainStatusTrackingBarContainer:GetWidth(), 900)
for _, bar in ipairs({ StanceBar, PetActionBar, PossessActionBar, MainMenuBarVehicleLeaveButton }) do
    local point, _, _, x, y = bar:GetPoint(1)
    Equal(point, "BOTTOM", "Re-enabling captures the current native auxiliary placement")
    Equal(x, 25)
    Equal(y, 35)
end

-- A real reload rebuilds frames; no Edit Mode manager or profile is needed at startup.
ErzbaroneUISettings.compactMainBar = true
ErzbaroneUISettings.microMenuPosition = "aboveBags"
Setup(true)
AssertCustomShape()
Equal(select(3, MicroMenu:GetParent():GetPoint(1)), "TOPRIGHT", "Reload reapplies the saved menu position")
Equal(ErzbaroneUILayout, legacyState)
Equal(#messages, 0, "Routine updates must not print errors")
ErzbaroneUISettings.compactMainBar = false
ErzbaroneUI.MainBar:Update()
Equal(MainActionBar.actionButtons[1]:GetAlpha(), 1)
Equal(MicroMenu:GetParent(), MicroMenuContainer, "Disabling the above-bags preset restores the native parent")
Equal(MicroMenu:GetPoint(1), "BOTTOM", "Disabling the above-bags preset restores native anchors")
ErzbaroneUISettings.microMenuPosition = "besideBags"

-- Enabling during combat does not create protected frames until regeneration.
Setup()
combat = true
ErzbaroneUISettings.compactMainBar = true
ErzbaroneUI.MainBar:Update()
Equal(ErzbaroneUIMainSecureBar, nil)
Equal(ErzbaroneUI.MainBar.PendingUpdate, true)
combat = false
regen = events.PLAYER_REGEN_ENABLED
regen.OnEvent(regen, "PLAYER_REGEN_ENABLED")
Flush()
AssertCustomShape()
Equal(ErzbaroneUI.MainBar.PendingUpdate, false)
ErzbaroneUISettings.compactMainBar = false
ErzbaroneUI.MainBar:Update()

-- A late bag bar moves the menu next to it after temporarily using the previous placement.
local lateBags = BagsBar
BagsBar = nil
ErzbaroneUISettings.compactMainBar = true
ErzbaroneUI.MainBar:Update()
Equal(select(2, MicroMenu:GetParent():GetPoint(1)), UIParent)
assert(messages[#messages]:find("could not find the Forever bag bar", 1, true))
BagsBar = lateBags
ErzbaroneUI.MainBar:Initialize()
Flush()
Equal(select(2, MicroMenu:GetParent():GetPoint(1)), BagsBar, "Menu follows bags after they load")
ErzbaroneUISettings.compactMainBar = false
ErzbaroneUI.MainBar:Update()

-- Missing native buttons produce an explicit error and leave original controls intact.
local nativeButtons = MainActionBar.actionButtons
MainActionBar.actionButtons = {}
dofile(root .. "modules\\actionlayout.lua")
ErzbaroneUISettings.compactMainBar = true
Equal(ErzbaroneUI.ActionLayout:Update(), false)
assert(messages[#messages]:find("templates are not ready", 1, true))
Equal(nativeButtons[1].container:GetParent(), MainActionBar)
Equal(nativeButtons[1]:IsMouseEnabled(), true)

local manifest = assert(io.open(root .. "ErzbaroneUI.toc", "r"))
local contents = manifest:read("*a")
manifest:close()
assert(not contents:find("ErzbaroneUILayout", 1, true), "Legacy profile state must not be persisted")
print = nativePrint
print("actionlayout_test.lua: all assertions passed")
