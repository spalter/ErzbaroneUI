local root = (... or ".") .. "\\"
unpack = unpack or table.unpack
local function AssertTextColor(text, title, hovered)
    local expected
    if hovered then
        expected = title and { 229 / 255, 224 / 255, 216 / 255 } or { 205 / 255, 201 / 255, 192 / 255 }
    else
        expected = title and { 197 / 255, 192 / 255, 184 / 255 } or { 169 / 255, 166 / 255, 159 / 255 }
    end
    assert(text.color[1] == expected[1] and text.color[2] == expected[2] and text.color[3] == expected[3],
        "Tracker text must retain its title or objective warm grey color")
end
local combat = false
function InCombatLockdown() return combat end

local events, hookCount = {}, 0
local function Widget(kind, parent)
    local frame = {
        kind = kind or "Frame", parent = parent, shown = true, mouse = kind == "Button",
        points = {}, scripts = {}, children = {}, regions = {}, width = 260, height = 0,
        frameLevel = parent and parent.frameLevel + 1 or 0,
        color = { 1, 0.82, 0, 1 },
    }
    if parent then
        local list = (kind == "FontString" or kind == "Texture") and parent.regions or parent.children
        list[#list + 1] = frame
    end
    function frame:GetParent() return self.parent end
    function frame:SetParent(value) self.parent = value end
    function frame:GetChildren() return unpack(self.children) end
    function frame:GetRegions() return unpack(self.regions) end
    function frame:IsProtected() return self.protected end
    function frame:GetFrameLevel() return self.frameLevel end
    function frame:SetFrameLevel(level) self.frameLevel = level end
    function frame:Show() self.shown = true end
    function frame:Hide() self.shown = false end
    function frame:SetShown(value) if value then self:Show() else self:Hide() end end
    function frame:IsShown() return self.shown end
    function frame:EnableMouse(value) self.mouse = value end
    function frame:IsMouseEnabled() return self.mouse end
    function frame:SetScript(script, callback) self.scripts[script] = callback end
    function frame:GetScript(script) return self.scripts[script] end
    function frame:RegisterEvent(event) self.events = self.events or {}; self.events[event] = true end
    function frame:GetNumPoints() return #self.points end
    function frame:GetPoint(index) return unpack(self.points[index]) end
    function frame:ClearAllPoints() self.points = {} end
    function frame:SetPoint(point, ...)
        for index, anchor in ipairs(self.points) do
            if anchor[1] == point then self.points[index] = { point, ... }; return end
        end
        self.points[#self.points + 1] = { point, ... }
    end
    function frame:GetFontObject() return self.fontObject end
    function frame:SetFontObject(object) self.fontObject = object; self.font = nil end
    function frame:GetFont()
        if self.font then return unpack(self.font) end
        if self.fontObject then return self.fontObject:GetFont() end
        return "Fonts\\FRIZQT__.TTF", 12, ""
    end
    function frame:SetFont(...) self.font = { ... }; return true end
    function frame:GetTextColor() return unpack(self.color) end
    function frame:SetTextColor(...) self.color = { ... } end
    function frame:SetText(text) self.text = text end
    function frame:GetText() return self.text end
    function frame:SetMaxLines(value) self.maxLines = value end
    function frame:GetWidth()
        for _, point in ipairs(self.points) do
            if point[1] == "RIGHT" and type(point[2]) == "table" then
                local indent = self.points[1][4] or 0
                return point[2]:GetWidth() - indent
            end
        end
        return self.width
    end
    function frame:GetStringHeight()
        if not self.text or self.text == "" then return 0 end
        local _, size = self:GetFont()
        local count = math.max(1, math.ceil(#self.text * size * 0.5 / self:GetWidth()))
        return math.min(count, self.maxLines and self.maxLines > 0 and self.maxLines or count) * size
    end
    function frame:GetHeight()
        if self.kind == "FontString" and self.height == 0 then return self:GetStringHeight() end
        return self.height
    end
    function frame:SetHeight(value)
        assert(not (combat and self.protected), "Protected size mutation in combat")
        self.height = value
    end
    return frame
end

function CreateFrame(kind, _, parent)
    local frame = Widget(kind, parent)
    events[#events + 1] = frame
    return frame
end
function hooksecurefunc(frame, method, callback)
    local native = frame[method]
    frame[method] = function(...)
        local result = { native(...) }
        callback(...)
        return unpack(result)
    end
    hookCount = hookCount + 1
end

local normal = { r = 1, g = 1, b = 1 }
local headerColor = { r = 0.2, g = 1, b = 0.2 }
local completed = { r = 0.6, g = 0.6, b = 0.6 }
normal.reverse, headerColor.reverse, completed.reverse = headerColor, normal, normal
ObjectiveTrackerLineFont = Widget("FontString")
local function Text(parent)
    local text = Widget("FontString", parent)
    text:SetFontObject(ObjectiveTrackerLineFont)
    return text
end
local function Header(parent)
    local header = Widget("Frame", parent)
    header.height = 26
    header.Text = Text(header)
    for _, key in ipairs({ "Background", "Glow", "Shine", "MinimizeButton" }) do
        header[key] = Widget(key == "MinimizeButton" and "Button" or "Texture", header)
    end
    return header
end

local opened, titles = {}, { [35] = "Clam Bait", [37] = "Catch of the Day", [80] = "A world objective" }
local shiftDown, canUntrack, worldUntrackFails = false, true, false
local mapDisabled, mapBlocked = false, false
Enum = { GameRule = { WorldMapDisabled = 1 } }
C_GameRules = { IsGameRuleActive = function(rule) return rule == Enum.GameRule.WorldMapDisabled and mapDisabled end }
WorldMapFrame = Widget("Frame")
WorldMapFrame.QuestLog = Widget("Frame", WorldMapFrame)
WorldMapFrame:Hide()
WorldMapFrame.QuestLog:Hide()
function QuestMapFrame_OpenToQuestDetails(id)
    opened[#opened + 1] = id
    if not mapBlocked then
        WorldMapFrame:Show()
        WorldMapFrame.QuestLog:Show()
        WorldMapFrame.QuestLog.selectedQuest = id
    end
end
local questWatches, worldWatches = { [35] = true, [37] = true }, { [80] = true }
local removedQuests, removedWorldQuests = {}, {}
function IsShiftKeyDown() return shiftDown end
function QuestUtils_IsQuestWatched(id) return worldWatches[id] == true end
C_QuestLog = {
    GetTitleForQuestID = function(id) return titles[id] end,
    GetLogIndexForQuestID = function(id) return titles[id] and id end,
    IsWorldQuest = function(id) return id == 80 end,
    IsThreatQuest = function() return false end,
    RemoveQuestWatch = function(id)
        if not questWatches[id] then return false end
        questWatches[id] = nil
        removedQuests[#removedQuests + 1] = id
        return true
    end,
}
QuestUtil = {
    OpenQuestDetails = function() error("Old quest details interface used") end,
    CanRemoveQuestWatch = function() return canUntrack end,
    UntrackWorldQuest = function(id)
        if not worldUntrackFails then
            worldWatches[id] = nil
            removedWorldQuests[#removedWorldQuests + 1] = id
        end
    end,
}
QUEST_WATCH_QUEST_COMPLETE = "Quest complete"
QUEST_WATCH_POPUP_QUEST_DISCOVERED = "Quest discovered"

local NewBlock
local function NewLine(block)
    local line = Widget("Frame", block)
    line.Text, line.Dash = Text(line), Text(line)
    line.Text:SetPoint("TOP")
    line.Text:SetPoint("LEFT", line.Dash, "RIGHT")
    line.Text:SetPoint("RIGHT")
    line.Icon, line.Glow, line.CheckGlow = Widget("Texture", line), Widget("Texture", line), Widget("Texture", line)
    function line:SetState() self.Icon:Show(); self.Glow:Show(); self.Text:SetTextColor(0.6, 0.6, 0.6) end
    return line
end
NewBlock = function(module)
    local block = Widget("Frame", module)
    block.usedLines = {}
    block.HeaderText, block.HeaderButton = Text(block), Widget("Button", block)
    block.HeaderButton:EnableMouse(true)
    block.HeaderButton:SetPoint("TOPLEFT", block.HeaderText, "TOPLEFT")
    block.HeaderButton:SetPoint("BOTTOMRIGHT", block.HeaderText, "BOTTOMRIGHT")
    block.HeaderText:SetPoint("TOPLEFT")
    block.HeaderText:SetPoint("RIGHT", block, "RIGHT", 0, 0)
    block.HeaderButton:SetScript("OnClick", function() error("Native quest map/action handler used") end)
    block.HeaderButton:SetScript("OnEnter", function()
        block.isHighlighted = true
        block:UpdateHighlight()
    end)
    block.HeaderButton:SetScript("OnLeave", function()
        block.isHighlighted = false
        block:UpdateHighlight()
    end)
    block.HeaderGlow = Widget("Texture", block)
    function block:GetLine(key)
        local line = self.usedLines[key]
        if not line then line = NewLine(self); self.usedLines[key] = line end
        line.objectiveKey, line.parentBlock = key, self
        return line
    end
    function block:GetExistingLine(key) return self.usedLines[key] end
    function block:SetStringText(text, value, full, color)
        text:SetMaxLines(full and 0 or 2)
        text:SetHeight(0)
        text:SetText(value)
        color = color or normal
        if text.colorStyle ~= color then
            text:SetTextColor(color.r, color.g, color.b)
            text.colorStyle = color
        end
        return text:GetHeight()
    end
    function block:SetHeader(value)
        self.height = self:SetStringText(self.HeaderText, value, false, headerColor)
    end
    function block:AddObjective(key, value, color)
        local line = self:GetLine(key)
        if line.dashStyle ~= "show" then line.Dash:Show(); line.dashStyle = "show" end
        line.Dash:SetText("- ")
        local height = self:SetStringText(line.Text, value, true, color)
        line:SetHeight(height)
        self.height = self.height + height + self.parentModule.lineSpacing
        self.lastRegion = line
        return line
    end
    function block:UpdateHighlight()
        self.HeaderText:SetTextColor(1, 0.8, 0)
        for _, line in pairs(self.usedLines) do line.Text:SetTextColor(0.8, 0.8, 0.8) end
    end
    function block:AdjustRightEdgeOffset(value) self.rightEdgeOffset = self.rightEdgeOffset + value end
    function block:AddRightEdgeFrame(button)
        button:SetParent(self)
        button.SetUp = function() end
        self:AdjustRightEdgeOffset(-26)
        self.addedRegions = self.addedRegions or {}
        self.addedRegions[button] = true
        button:Show()
    end
    function block:OnLayout()
        self.poiButton = self.poiButton or Widget("Button", self)
        self.poiButton:Show()
        self.HeaderGlow:Show()
    end
    return block
end

local function EntryButtonAt(block, offsetY)
    local button = block.HeaderButton
    local bottomAnchor = button.points[2][2]
    local height = bottomAnchor == block and block:GetHeight() or block.HeaderText:GetHeight()
    if not button:IsShown() or not button:IsMouseEnabled() or offsetY < 0 or offsetY > height then
        return nil
    end
    for _, line in pairs(block.usedLines) do
        if line:GetFrameLevel() >= button:GetFrameLevel() then return nil end
    end
    return button
end

local function Module(container)
    local module = Widget("Frame", container)
    module.Header = Header(module)
    module.usedBlocks = {}
    module.headerHeight, module.fromHeaderOffsetY, module.blockOffsetX, module.lineSpacing = 25, -10, 20, 4
    module.collapsed, module.dirty = false, false
    function module:IsCollapsed() return self.collapsed end
    function module:SetCollapsed(value) self.collapsed = value; self:MarkDirty() end
    function module:MarkDirty() self.dirty = true end
    function module:GetBlock(id)
        local block = self.usedBlocks[id]
        if not block then
            block = NewBlock(self)
            self.usedBlocks[id] = block
        end
        block.parentModule, block.id = self, id
        if not block.fixedHeight then block.height = 0 end
        block.lastRegion, block.rightEdgeOffset = nil, 0
        block:ClearAllPoints()
        block:SetPoint("LEFT", self, "LEFT", block.offsetX or self.blockOffsetX, 0)
        return block
    end
    function module:GetExistingBlock(id) return self.usedBlocks[id] end
    function module:EnumerateActiveBlocks(callback)
        for _, block in pairs(self.usedBlocks) do callback(block) end
    end
    function module:LayoutBlock(block)
        self.tried = self.tried + 1
        if self.collapsed or self.contentsHeight + block.height > self.availableHeight then return false end
        self.contentsHeight = self.contentsHeight + block.height
        block:Show()
        if block.OnLayout then block:OnLayout() end
        return true
    end
    function module:EndLayout()
        self.Header:Show()
        self.Header.Background:Show()
        self.Header.MinimizeButton:Show()
    end
    function module:Update(available)
        self.availableHeight, self.contentsHeight, self.tried = available, self.headerHeight, 0
        if self.render then self:render() end
        self:EndLayout()
        return self.contentsHeight
    end
    return module
end

ObjectiveTrackerFrame = Widget()
ObjectiveTrackerFrame.height = 500
ObjectiveTrackerFrame.Header, ObjectiveTrackerFrame.NineSlice = Header(ObjectiveTrackerFrame), Widget("Frame", ObjectiveTrackerFrame)
ObjectiveTrackerFrame.collapsed, ObjectiveTrackerFrame.topModulePadding = false, 38
ObjectiveTrackerFrame:SetPoint("TOPRIGHT", nil, "TOPRIGHT", -30, -300)
function ObjectiveTrackerFrame:IsCollapsed() return self.collapsed end
function ObjectiveTrackerFrame:SetCollapsed(value) self.collapsed = value end
function ObjectiveTrackerFrame:UpdateTopPadding() self.topModulePadding = 38 end
function ObjectiveTrackerFrame:Update()
    self:UpdateTopPadding()
    self.Header:Show()
    self.NineSlice:Show()
    local available = self.height - self.topModulePadding
    for _, module in ipairs(self.modules) do available = available - module:Update(available) end
end

QuestObjectiveTracker = Module(ObjectiveTrackerFrame)
ScenarioObjectiveTracker = Module(ObjectiveTrackerFrame)
WorldQuestObjectiveTracker = Module(ObjectiveTrackerFrame)
local other = Module(ObjectiveTrackerFrame)
ObjectiveTrackerFrame.modules = { ScenarioObjectiveTracker, QuestObjectiveTracker, WorldQuestObjectiveTracker, other }
local scenario = ScenarioObjectiveTracker
scenario.StageBlock = Widget("Frame", scenario)
scenario.StageBlock.Stage, scenario.StageBlock.Name = Text(scenario.StageBlock), Text(scenario.StageBlock)
scenario.StageBlock.Name:SetText("The current stage")
scenario.StageBlock.Stage:SetText("Stage 1")
scenario.StageBlock.height = 50
for _, key in ipairs({ "NormalBG", "FinalBG", "ThemeOverlay", "GlowTexture", "findGroupButton" }) do
    scenario.StageBlock[key] = Widget(key == "findGroupButton" and "Button" or "Texture", scenario.StageBlock)
end
function scenario.StageBlock:UpdateStageBlock()
    self.NormalBG:Show()
    self.Name:SetText("The next stage")
    self.Stage:SetTextColor(0.75, 1, 0)
    self.findGroupButton:Show()
end
scenario.ObjectivesBlock = NewBlock(scenario)
scenario.ObjectivesBlock.parentModule = scenario
scenario.FixedBlocks = { scenario.StageBlock, scenario.ObjectivesBlock }
local spell = Widget("Frame", scenario.ObjectivesBlock)
spell.SpellButton, spell.SpellName = Widget("Button", spell), Text(spell)
spell.SpellName:SetText("Scenario spell")
scenario.spellFramePool = {}
scenario.spellFramePool.EnumerateActive = function()
    local returned = false
    return function() if not returned then returned = true; return spell end end
end
local widgets = Widget("Frame", scenario.StageBlock)
scenario.StageBlock.WidgetContainer = widgets
local progress, timer, widgetAction = Widget("StatusBar", widgets), Widget("Frame", widgets), Widget("Button", widgets)
widgetAction:SetScript("OnClick", function() error("Hidden widget action used") end)
function scenario:render()
    self:LayoutBlock(self.StageBlock)
    local block = self.ObjectivesBlock
    block.height, block.lastRegion = 0, nil
    block:AddObjective(1, "1/3 Dynamic objective")
    self:LayoutBlock(block)
end

local item = Widget("Button")
local objectiveText, questTitle, complete = "0/10 Soft-shelled Clam Meat", "[35] |cff00ff00Clam Bait|r", false
function QuestObjectiveTracker:render()
    local block = self:GetBlock(35)
    block:AddRightEdgeFrame(item)
    block:SetHeader(questTitle)
    block:AddObjective(1, objectiveText, complete and completed or normal)
    if complete then block:AddObjective("ClickComplete", "Click to complete") end
    self:LayoutBlock(block)
end
function WorldQuestObjectiveTracker:render()
    local block = self:GetBlock(80)
    block:SetHeader("|cnNORMAL_FONT_COLOR:A world objective|r")
    block:AddObjective(1, "50% world progress")
    self:LayoutBlock(block)
end
function other:render()
    local block = self:GetBlock(35)
    block:SetHeader("An achievement, not quest 35")
    block:AddObjective(1, "1/2 Achievement")
    self:LayoutBlock(block)
end

local updates = 0
ObjectiveTrackerManager = { containers = { [ObjectiveTrackerFrame] = true } }
function ObjectiveTrackerManager:UpdateAll() updates = updates + 1; ObjectiveTrackerFrame:Update() end
function ObjectiveTrackerManager:ReleaseFrame(frame) frame:Hide() end
function ObjectiveTrackerManager:SetModuleContainer(module, container)
    container.modules[#container.modules + 1] = module
end
function ObjectiveTrackerManager:SetTextSize(size)
    ObjectiveTrackerLineFont:SetFont("Fonts\\FRIZQT__.TTF", size, "")
    self:UpdateAll()
end

ErzbaroneUISettings = { minimalistObjectives = false }
dofile(root .. "modules\\objectives.lua")
local feature = ErzbaroneUI.Objectives
feature:Initialize()
assert(updates == 0 and hookCount == 0, "Disabled initialization must leave Blizzard untouched")
ObjectiveTrackerManager:UpdateAll()
local quest = QuestObjectiveTracker.usedBlocks[35]
local originalClick, originalFontObject = quest.HeaderButton:GetScript("OnClick"), quest.HeaderText:GetFontObject()
local originalButtonLevel = quest.HeaderButton:GetFrameLevel()
local originalPoint = { ObjectiveTrackerFrame:GetPoint(1) }
local originalHeight = quest.height
ObjectiveTrackerFrame.collapsed, QuestObjectiveTracker.collapsed = true, true
ErzbaroneUISettings.minimalistObjectives = true
feature:Update()
assert(not ObjectiveTrackerFrame.Header:IsShown() and not QuestObjectiveTracker.Header:IsShown())
assert(ObjectiveTrackerFrame.topModulePadding == 0 and QuestObjectiveTracker.headerHeight == 0)
assert(QuestObjectiveTracker.blockOffsetX == 0 and quest.rightEdgeOffset == 0, "Removed controls must not reserve text space")
assert(not ObjectiveTrackerFrame.collapsed and not QuestObjectiveTracker.collapsed)
assert(quest.HeaderText:GetText() == "Clam Bait")
AssertTextColor(quest.HeaderText, true)
AssertTextColor(quest.usedLines[1].Text)
local _, titleSize, flags = quest.HeaderText:GetFont()
assert(titleSize == 14 and flags == "OUTLINE")
assert(quest.usedLines[1].Text:GetFontObject() == ObjectiveTrackerLineFont)
assert(quest.usedLines[1].Text:GetText() == objectiveText)
assert(not quest.usedLines[1].Dash:IsShown() and not quest.poiButton:IsShown() and not item:IsShown())
assert(quest.usedLines[1].Text.points[1][2] == quest.usedLines[1], "Objective text must not stay anchored to the dash")
assert(quest.height > originalHeight, "Larger titles must contribute to native layout measurements")
assert(select(4, ObjectiveTrackerFrame:GetPoint(1)) == originalPoint[4], "Tracker placement must not change")
assert(quest.HeaderButton.points[1][2] == quest and quest.HeaderButton.points[2][2] == quest,
    "The quest interaction surface must cover the entire block, not just the title")
assert(quest.HeaderButton:GetFrameLevel() > quest.usedLines[1]:GetFrameLevel(),
    "Objective line frames must not intercept the quest interaction surface")
quest.HeaderButton:GetScript("OnClick")(quest.HeaderButton, "RightButton")
assert(#opened == 0, "Right clicks must not perform quest actions")
quest.HeaderButton:GetScript("OnClick")(quest.HeaderButton, "LeftButton")
assert(opened[1] == 35 and WorldMapFrame:IsShown() and WorldMapFrame.QuestLog.selectedQuest == 35,
    "A quest click must open and select it in the world map quest log")
other.usedBlocks[35].HeaderButton:GetScript("OnClick")(other.usedBlocks[35].HeaderButton, "LeftButton")
assert(#opened == 1, "Numeric IDs from other modules must not be treated as quests")
assert(WorldQuestObjectiveTracker.usedBlocks[80].HeaderText:GetText() == titles[80])

local objectiveButton = assert(EntryButtonAt(quest, quest.HeaderText:GetHeight() + 4 + quest.usedLines[1]:GetHeight() / 2),
    "Hovering objective text must hit the quest-log button")
assert(objectiveButton == EntryButtonAt(quest, quest.HeaderText:GetHeight() / 2),
    "Moving between title and objectives must stay on the same hover surface")
objectiveButton:GetScript("OnClick")(objectiveButton, "LeftButton")
assert(opened[#opened] == 35 and WorldMapFrame:IsShown() and WorldMapFrame.QuestLog.selectedQuest == 35,
    "Clicking objective text with the map open must select the quest without closing the map")
local worldButton = WorldQuestObjectiveTracker.usedBlocks[80].HeaderButton
worldButton:GetScript("OnClick")(worldButton, "LeftButton")
assert(opened[#opened] == 80 and WorldMapFrame.QuestLog.selectedQuest == 80,
    "World quest clicks must select the current quest in the map")

local mapErrors, printBeforeMap = {}, print
print = function(message) mapErrors[#mapErrors + 1] = message end
local openMapQuest = QuestMapFrame_OpenToQuestDetails
local openedBeforeErrors = #opened
QuestMapFrame_OpenToQuestDetails = nil
objectiveButton:GetScript("OnClick")(objectiveButton, "LeftButton")
QuestMapFrame_OpenToQuestDetails, mapDisabled = openMapQuest, true
objectiveButton:GetScript("OnClick")(objectiveButton, "LeftButton")
assert(#opened == openedBeforeErrors, "An unavailable or disabled map must not invoke the map helper")
mapDisabled, mapBlocked = false, true
WorldMapFrame:Hide()
WorldMapFrame.QuestLog:Hide()
objectiveButton:GetScript("OnClick")(objectiveButton, "LeftButton")
mapBlocked = false
print = printBeforeMap
assert(#mapErrors == 3 and #opened == openedBeforeErrors + 1 and opened[#opened] == 35,
    "Missing, disabled, and blocked map interfaces must be reported without using the old quest interface")
local openedBeforeShift = #opened
shiftDown = true
objectiveButton:GetScript("OnClick")(objectiveButton, "RightButton")
other.usedBlocks[35].HeaderButton:GetScript("OnClick")(other.usedBlocks[35].HeaderButton, "LeftButton")
assert(#removedQuests == 0 and #removedWorldQuests == 0, "Shift-right-click and non-quest entries must not untrack quests")
objectiveButton:GetScript("OnClick")(objectiveButton, "LeftButton")
assert(removedQuests[1] == 35 and not questWatches[35] and #opened == openedBeforeShift,
    "Shift-clicking objective text must remove its quest watch without opening details")
worldButton:GetScript("OnClick")(worldButton, "LeftButton")
assert(removedWorldQuests[1] == 80 and not worldWatches[80] and #opened == openedBeforeShift,
    "World quests must use the native world-quest untracking helper")

local trackingErrors, printBeforeTracking = {}, print
print = function(message) trackingErrors[#trackingErrors + 1] = message end
questWatches[35], canUntrack = true, false
objectiveButton:GetScript("OnClick")(objectiveButton, "LeftButton")
assert(questWatches[35] and #removedQuests == 1, "Native quest-watch restrictions must be respected")
canUntrack, questWatches[35] = true, nil
objectiveButton:GetScript("OnClick")(objectiveButton, "LeftButton")
worldButton:GetScript("OnClick")(worldButton, "LeftButton")
worldWatches[80], worldUntrackFails = true, true
worldButton:GetScript("OnClick")(worldButton, "LeftButton")
print = printBeforeTracking
assert(#trackingErrors == 4 and #opened == openedBeforeShift,
    "Restricted, failed and automatically shown untracking attempts must be reported rather than opening details")
shiftDown, worldUntrackFails = false, false
questWatches[35] = true
objectiveButton:GetScript("OnClick")(objectiveButton, "LeftButton")
assert(#opened == openedBeforeShift + 1, "Ordinary clicks must continue to open quest-log details")
objectiveButton:GetScript("OnEnter")(objectiveButton)
AssertTextColor(quest.HeaderText, true, true)
AssertTextColor(quest.usedLines[1].Text, false, true)
AssertTextColor(WorldQuestObjectiveTracker.usedBlocks[80].HeaderText, true)
ObjectiveTrackerManager:UpdateAll()
quest.usedLines[1]:SetState()
AssertTextColor(quest.HeaderText, true, true)
AssertTextColor(quest.usedLines[1].Text, false, true)
quest.HeaderButton:GetScript("OnLeave")(quest.HeaderButton)
AssertTextColor(quest.HeaderText, true)
AssertTextColor(quest.usedLines[1].Text)

quest:UpdateHighlight()
quest.usedLines[1]:SetState()
item:Show()
AssertTextColor(quest.HeaderText, true)
AssertTextColor(quest.usedLines[1].Text)
assert(not quest.usedLines[1].Icon:IsShown() and not quest.usedLines[1].Glow:IsShown() and not item:IsShown())
scenario.StageBlock:UpdateStageBlock()
assert(scenario.StageBlock.Name:GetText() == "The next stage")
AssertTextColor(scenario.StageBlock.Stage)
AssertTextColor(scenario.StageBlock.Name)
assert(not scenario.StageBlock.NormalBG:IsShown() and not scenario.StageBlock.findGroupButton:IsShown())
assert(progress:IsShown() and timer:IsShown(), "Functional dynamic visuals must survive")
assert(not widgetAction:IsShown() and not spell.SpellButton:IsShown())
assert(spell.SpellName:GetText() == "Scenario spell")

complete = true
ObjectiveTrackerManager:UpdateAll()
AssertTextColor(quest.usedLines[1].Text)
assert(not quest.usedLines.ClickComplete:IsShown() and quest.usedLines.ClickComplete.Text:GetText() == "")
assert(quest.height == quest.HeaderText:GetHeight() + quest.usedLines[1]:GetHeight() + 4,
    "Hidden action instructions must not consume layout height")
local shortHeight = quest.height
titles[35], objectiveText = string.rep("A localized long title ", 8), string.rep("An objective ", 12)
ObjectiveTrackerManager:UpdateAll()
assert(quest.HeaderText:GetText() == titles[35] and quest.height > shortHeight, "Wrapped text must be measured before native fitting")
assert(quest.HeaderButton.points[2][2] == quest,
    "The interaction surface must follow the block when objectives wrap or its height changes")
ObjectiveTrackerFrame.height = 80
ObjectiveTrackerManager:UpdateAll()
assert(QuestObjectiveTracker.tried == 1 and QuestObjectiveTracker.contentsHeight == 0,
    "Native available-height fitting and module priority must stay authoritative")
ObjectiveTrackerFrame.height = 500
ObjectiveTrackerManager:SetTextSize(16)
assert(select(2, quest.HeaderText:GetFont()) == 18 and select(2, quest.usedLines[1].Text:GetFont()) == 16)

local reused = quest.usedLines[1]
quest.usedLines[1] = nil
ObjectiveTrackerManager:ReleaseFrame(reused)
assert(not reused:IsShown() and reused.Dash:IsShown(), "Release must restore local child visibility without showing the pooled root")
assert(reused.Text:GetFontObject() == ObjectiveTrackerLineFont and reused.Text.points[2][2] == reused.Dash)
quest.usedLines[1] = reused
ObjectiveTrackerManager:UpdateAll()
assert(not reused.Dash:IsShown(), "Reacquired lines must be restyled even when native dashStyle is cached")

local nativeRender = QuestObjectiveTracker.render
QuestObjectiveTracker.usedBlocks[35] = nil
ObjectiveTrackerManager:ReleaseFrame(quest)
QuestObjectiveTracker.usedBlocks[37] = quest
quest.poiQuestID = 35
function QuestObjectiveTracker:render()
    local block = self:GetBlock(37)
    block:SetHeader("[37] Catch of the Day")
    block:AddObjective(1, "0/2 Bloodbelly Fish")
    self:LayoutBlock(block)
end
ObjectiveTrackerManager:UpdateAll()
assert(quest.HeaderText:GetText() == titles[37], "A reused block must not retain a previous POI quest identity")
assert(quest.HeaderButton.points[2][2] == quest and quest.HeaderButton:GetFrameLevel() > quest.usedLines[1]:GetFrameLevel())
quest.HeaderButton:GetScript("OnClick")(quest.HeaderButton, "LeftButton")
assert(opened[#opened] == 37 and WorldMapFrame.QuestLog.selectedQuest == 37,
    "Reused title buttons must target the current quest in the map")
QuestObjectiveTracker.usedBlocks[37] = nil
ObjectiveTrackerManager:ReleaseFrame(quest)
QuestObjectiveTracker.usedBlocks[35], QuestObjectiveTracker.render = quest, nativeRender
ObjectiveTrackerManager:UpdateAll()

local count = hookCount
feature:Initialize()
assert(hookCount == count, "Repeated initialization must not accumulate hooks")

local popupModule = Module(ObjectiveTrackerFrame)
local popup = Widget("Frame", popupModule)
popup:EnableMouse(true)
popup.height, popup.fixedHeight, popup.offsetX = 68, true, -20
popup.parentModule = popupModule
popup:SetScript("OnMouseUp", function() error("Hidden popup action used") end)
popup.Contents = Widget("Frame", popup)
popup.Contents.QuestName, popup.Contents.TopText, popup.Contents.BottomText = Text(popup.Contents), Text(popup.Contents), Text(popup.Contents)
popup.Contents.QuestName:SetHeight(30)
popup.Contents.QuestName:SetPoint("LEFT", popup.Contents, "LEFT", 60, 0)
popup.Contents.TopText:SetPoint("TOP", popup.Contents, "TOP", 0, -15)
popup.Contents.FlashFrame, popup.Contents.Bg = Widget("Frame", popup.Contents), Widget("Texture", popup.Contents)
function popup:Update(title, id, popUpType)
    if self.questID ~= id then
        self.questID, self.popUpType = id, popUpType
        self.Contents.TopText:SetText("Click to complete this quest")
        self.Contents.QuestName:SetText(title)
        self.Contents.QuestName:SetPoint("TOP", self.Contents, "TOP", 0, -29)
    end
end
popupModule.usedBlocks["37COMPLETE"] = popup
function popupModule:render()
    local block = self:GetBlock("37COMPLETE", "popup")
    if self:LayoutBlock(block) then block:Update(titles[37], 37, "COMPLETE") end
end
ObjectiveTrackerManager:SetModuleContainer(popupModule, ObjectiveTrackerFrame)
ObjectiveTrackerManager:UpdateAll()
ObjectiveTrackerManager:UpdateAll()
assert(not popupModule.Header:IsShown() and not popup:IsMouseEnabled(), "Late modules and popup action surfaces must be styled")
assert(popup.Contents.TopText:GetText() == "Quest complete" and not popup.Contents.BottomText:IsShown())
assert(not popup.Contents.Bg:IsShown() and not popup.Contents.FlashFrame:IsShown())
assert(popup.height < 68, "Popup artwork must not leave its original blank space")
local titleButton
for _, frame in ipairs(events) do if frame:GetParent() == popup then titleButton = frame end end
assert(titleButton and titleButton:IsShown())
assert(titleButton.points[2][2] == popup.Contents.TopText, "Popup interaction must include the objective/status text")
titleButton:GetScript("OnEnter")(titleButton)
AssertTextColor(popup.Contents.QuestName, true, true)
AssertTextColor(popup.Contents.TopText, false, true)
titleButton:GetScript("OnLeave")(titleButton)
AssertTextColor(popup.Contents.QuestName, true)
AssertTextColor(popup.Contents.TopText)
titleButton:GetScript("OnClick")(titleButton, "LeftButton")
assert(opened[#opened] == 37 and WorldMapFrame.QuestLog.selectedQuest == 37,
    "Accepted popup quest titles must open map details rather than complete the quest")

local provider = { GetTopPadding = function() return 17 end }
ObjectiveTrackerFrame.topPaddingProviders = { [provider] = true }
ObjectiveTrackerManager:UpdateAll()
assert(ObjectiveTrackerFrame.topModulePadding == 17, "Functional top-padding providers must not be removed with the banner")
ObjectiveTrackerFrame.topPaddingProviders = nil
widgetAction:Hide()

combat = true
ErzbaroneUISettings.minimalistObjectives = false
feature:Update()
assert(feature.PendingUpdate and not item:IsShown(), "Toggle restoration must wait until combat ends")
combat = false
events[1]:GetScript("OnEvent")(events[1], "PLAYER_REGEN_ENABLED")
assert(not feature.PendingUpdate and ObjectiveTrackerFrame.Header:IsShown() and QuestObjectiveTracker.Header:IsShown())
assert(ObjectiveTrackerFrame.collapsed and QuestObjectiveTracker.collapsed, "Original collapsed states must return")
assert(QuestObjectiveTracker.headerHeight == 25 and QuestObjectiveTracker.blockOffsetX == 20)
assert(quest.HeaderButton:GetScript("OnClick") == originalClick and quest.HeaderText:GetFontObject() == originalFontObject)
assert(quest.HeaderButton.points[1][2] == quest.HeaderText and quest.HeaderButton.points[2][2] == quest.HeaderText
    and quest.HeaderButton:GetFrameLevel() == originalButtonLevel,
    "Disabling must restore the native title-only hit area and frame level")
assert(select(2, quest.HeaderText:GetFont()) == 16, "Restoration must retain native font-size changes made while enabled")
assert(item:IsShown() and not widgetAction:IsShown() and spell.SpellButton:IsShown(),
    "Restoration must honor native visibility changes made while controls were suppressed")
assert(quest.usedLines[1].Dash:IsShown() and quest.usedLines.ClickComplete.Text:GetText() == "Click to complete")
assert(popup:IsMouseEnabled() and not titleButton:IsShown(), "Popup mouse handling must be restored without leaving an extra click target")
assert(popup.Contents.TopText:GetText() == "Click to complete this quest",
    "Cached native popups must rebuild their instructions on disable")
local before = updates
feature:Update()
assert(updates == before, "Disabled updates must be idle")

-- Enabling before the native addon exists must retry after it loads.
local manager, container = ObjectiveTrackerManager, ObjectiveTrackerFrame
ObjectiveTrackerManager, ObjectiveTrackerFrame = nil, nil
ErzbaroneUISettings.minimalistObjectives = true
feature:Update()
ObjectiveTrackerManager, ObjectiveTrackerFrame = manager, container
events[1]:GetScript("OnEvent")(events[1], "ADDON_LOADED", "Blizzard_ObjectiveTracker")
assert(not container.Header:IsShown())
ErzbaroneUISettings.minimalistObjectives = false
feature:Update()
assert(container.Header:IsShown())

local nativePadding = container.UpdateTopPadding
container.UpdateTopPadding = nil
local messages, nativePrint = {}, print
print = function(message) messages[#messages + 1] = message end
ErzbaroneUISettings.minimalistObjectives = true
feature:Update()
print = nativePrint
assert(#messages == 1 and container.Header:IsShown(), "Unsupported integration must be reported without partially hiding native content")
container.UpdateTopPadding = nativePadding
ErzbaroneUISettings.minimalistObjectives = false

print("objectives_test.lua: all assertions passed")
