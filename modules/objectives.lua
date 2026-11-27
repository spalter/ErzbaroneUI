ErzbaroneUI = ErzbaroneUI or {}
ErzbaroneUI.Objectives = {}

local states = {}
local hooks = setmetatable({}, { __mode = "k" })
local popupButtons = setmetatable({}, { __mode = "k" })
local TITLE_COLOR = { 197 / 255, 192 / 255, 184 / 255 }
local OBJECTIVE_COLOR = { 169 / 255, 166 / 255, 159 / 255 }
local HOVER_TITLE_COLOR = { 229 / 255, 224 / 255, 216 / 255 }
local HOVER_OBJECTIVE_COLOR = { 205 / 255, 201 / 255, 192 / 255 }
local active = false
local changing = false
local eventFrame
local StyleBlock
local StyleWidgets

--- Defers changes to protected tracker frames until Blizzard's combat lockdown ends.
local function CanChange(frame)
    if InCombatLockdown() and frame.IsProtected and frame:IsProtected() then
        ErzbaroneUI.Objectives.PendingUpdate = true
        return false
    end
    return true
end

--- Gets the original-state record used to restore a tracker object.
local function Save(frame)
    if not states[frame] then
        states[frame] = {}
    end
    return states[frame]
end

--- Installs a secure hook once per tracker object and method.
local function Hook(frame, method, callback)
    if not frame[method] then
        return
    end
    hooks[frame] = hooks[frame] or {}
    if not hooks[frame][method] then
        hooks[frame][method] = true
        hooksecurefunc(frame, method, callback)
    end
end

--- Saves original anchors once before changing a tracker's layout.
local function SavePoints(frame)
    local state = Save(frame)
    if not state.points then
        state.points = {}
        for index = 1, frame:GetNumPoints() do
            state.points[index] = { frame:GetPoint(index) }
        end
    end
end

--- Saves an original tracker field before overriding it for the minimalist layout.
local function SetField(frame, key, value)
    local state = Save(frame)
    state.fields = state.fields or {}
    if not state.fields[key] then
        state.fields[key] = { frame[key] }
    end
    frame[key] = value
end

--- Suppresses a tracker element while tracking native visibility changes for restoration.
--- Hooks Blizzard visibility methods so hidden controls stay hidden while the style is active.
local function Hide(frame)
    if not frame or not CanChange(frame) then
        return
    end
    local state = Save(frame)
    if state.shown == nil then
        state.shown = frame:IsShown()
    end
    state.hidden = true
    --- Records native visibility requests and keeps suppressed artwork hidden.
    local function OnVisibility(self, shown)
        local saved = states[self]
        if active and saved and saved.hidden and not changing then
            saved.shown = shown
            if shown and CanChange(self) then
                changing = true
                self:Hide()
                changing = false
            end
        end
    end
    Hook(frame, "Show", function(self) OnVisibility(self, true) end)
    Hook(frame, "Hide", function(self) OnVisibility(self, false) end)
    Hook(frame, "SetShown", OnVisibility)
    changing = true
    frame:Hide()
    changing = false
end

--- Disables a frame's mouse handling while preserving native requests for restoration.
local function RemoveMouse(frame)
    if not CanChange(frame) then
        return
    end
    local state = Save(frame)
    if state.mouse == nil then
        state.mouse = frame:IsMouseEnabled()
    end
    changing = true
    frame:EnableMouse(false)
    changing = false
    Hook(frame, "EnableMouse", function(self, enabled)
        local saved = states[self]
        if active and saved and saved.mouse ~= nil and not changing then
            saved.mouse = enabled
            changing = true
            self:EnableMouse(false)
            changing = false
        end
    end)
end

--- Saves a frame script once before replacing its interaction handler.
local function SaveScript(frame, script)
    local state = Save(frame)
    state.scripts = state.scripts or {}
    if not state.scripts[script] then
        state.scripts[script] = { frame:GetScript(script) }
    end
end

--- Removes embedded color codes so tracker text can use the configured neutral colors.
local function PlainText(text)
    if type(text) == "string" then
        return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[%w_]+:", ""):gsub("|r", ""))
    end
    return text
end

--- Chooses title or objective color according to the containing block's hover state.
local function GetStyledColor(state)
    if state.block and state.block.isHighlighted then
        return state.title and HOVER_TITLE_COLOR or HOVER_OBJECTIVE_COLOR
    end
    return state.title and TITLE_COLOR or OBJECTIVE_COLOR
end

--- Applies neutral text styling while retaining Blizzard text, colors and title fonts for restoration.
--- Hooks native text updates so dynamic objectives keep the style.
local function StyleText(fontString, title, block)
    if not fontString then
        return
    end
    local state = Save(fontString)
    state.title = title == true
    state.block = block
    if not state.color then
        state.color = { fontString:GetTextColor() }
        state.text = fontString:GetText()
        Hook(fontString, "SetTextColor", function(self, ...)
            local saved = states[self]
            if active and saved and saved.color and not changing then
                saved.color = { ... }
                changing = true
                self:SetTextColor(unpack(GetStyledColor(saved)))
                changing = false
            end
        end)
        Hook(fontString, "SetText", function(self, text)
            local saved = states[self]
            if active and saved and saved.color and not changing then
                saved.text = text
                local display = saved.omit and "" or PlainText(text)
                changing = true
                self:SetText(display)
                changing = false
            end
        end)
    end
    changing = true
    fontString:SetTextColor(unpack(GetStyledColor(state)))
    fontString:SetText(state.omit and "" or PlainText(fontString:GetText()))
    if title then
        if not state.font then
            state.font = { fontString:GetFont() }
            state.fontObject = fontString:GetFontObject()
        end
        local font, size = ObjectiveTrackerLineFont:GetFont()
        fontString:SetFont(font, size + 2, "OUTLINE")
    end
    changing = false
end

--- Keeps a tracker container or module expanded and remembers its previous collapsed state.
local function Expand(frame)
    local state = Save(frame)
    if state.collapsed == nil then
        state.collapsed = frame:IsCollapsed()
    end
    if frame:IsCollapsed() then
        frame:SetCollapsed(false)
    end
    Hook(frame, "SetCollapsed", function(self)
        if active and states[self] and self:IsCollapsed() and not changing then
            changing = true
            self:SetCollapsed(false)
            changing = false
        end
    end)
end

--- Styles an objective line and removes decorative markers and tracker-only completion controls.
local function StyleLine(line)
    if not active or not line or not CanChange(line) then
        return
    end
    StyleText(line.Text, false, line.parentBlock)
    Hide(line.Dash)
    Hide(line.Icon)
    Hide(line.Glow)
    Hide(line.CheckGlow)
    SavePoints(line.Text)
    line.Text:ClearAllPoints()
    line.Text:SetPoint("TOPLEFT", line, "TOPLEFT", 6, 0)
    line.Text:SetPoint("RIGHT", line, "RIGHT", 0, 0)
    if line.objectiveKey == "ClickComplete" then
        Save(line).previousRegion = line.parentBlock.lastRegion
        Save(line.Text).omit = true
        Hide(line)
    end
end

--- Returns a valid quest ID only for blocks belonging to Blizzard quest tracker modules.
local function QuestID(block)
    local module = block.parentModule
    if module and (module == QuestObjectiveTracker or module == CampaignQuestObjectiveTracker
        or module == BonusObjectiveTracker or module == WorldQuestObjectiveTracker
        or module.MatchesTag and module:MatchesTag("quest")) then
        local id = block.id
        if type(id) == "number" and id > 0 then
            return id
        end
    end
end

--- Opens the map quest log or shift-click untracks a quest using Blizzard's quest APIs.
--- Reports when native tracking restrictions prevent removal.
local function HandleQuestClick(id, mouseButton)
    if mouseButton ~= "LeftButton" then
        return
    end
    if not IsShiftKeyDown() then
        if not QuestMapFrame_OpenToQuestDetails or not WorldMapFrame or not WorldMapFrame.QuestLog
            or C_GameRules.IsGameRuleActive(Enum.GameRule.WorldMapDisabled) then
            print("ErzbaroneUI: The world map quest log is unavailable.")
            return
        end
        QuestMapFrame_OpenToQuestDetails(id)
        if not WorldMapFrame:IsShown() or not WorldMapFrame.QuestLog:IsShown() then
            print("ErzbaroneUI: The world map quest log could not be opened.")
        end
    elseif not QuestUtil.CanRemoveQuestWatch() then
        print("ErzbaroneUI: Quest tracking cannot be changed right now.")
    elseif C_QuestLog.IsWorldQuest(id) then
        if C_QuestLog.IsThreatQuest(id) or not QuestUtils_IsQuestWatched(id) then
            print("ErzbaroneUI: This objective is shown automatically and cannot be untracked.")
            return
        end
        QuestUtil.UntrackWorldQuest(id)
        if QuestUtils_IsQuestWatched(id) then
            print("ErzbaroneUI: The quest could not be untracked.")
        end
    elseif not C_QuestLog.RemoveQuestWatch(id) then
        print("ErzbaroneUI: The quest could not be untracked.")
    end
end

--- Resolves a quest block from its header button before handling a click.
local function OnQuestClick(button, mouseButton)
    local id = QuestID(button:GetParent())
    if id then
        HandleQuestClick(id, mouseButton)
    end
end

--- Styles a block title and expands its click target across the quest entry.
--- Uses the quest log title when available and preserves the original script and layout.
local function StyleTitle(block)
    if not block.HeaderText then
        return
    end
    StyleText(block.HeaderText, true, block)
    local questID = QuestID(block)
    if questID then
        local title = C_QuestLog.GetTitleForQuestID(questID)
        if title then
            block.HeaderText:SetText(PlainText(title))
        end
    end
    if block.HeaderButton and CanChange(block.HeaderButton) then
        local button = block.HeaderButton
        SaveScript(button, "OnClick")
        button:SetScript("OnClick", OnQuestClick)
        if questID then
            SavePoints(button)
            local state = Save(button)
            if state.frameLevel == nil then state.frameLevel = button:GetFrameLevel() end
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", block, "TOPLEFT", 0, 0)
            button:SetPoint("BOTTOMRIGHT", block, "BOTTOMRIGHT", 0, 0)
            local level = block:GetFrameLevel()
            for _, line in pairs(block.usedLines or {}) do
                level = math.max(level, line:GetFrameLevel())
            end
            button:SetFrameLevel(level + 1)
        end
    end
end

--- Restyles quest popups and supplies a quest click target without retaining their action controls.
--- Preserves native state and marks the module dirty if the popup height changes.
local function StylePopup(block)
    local contents = block.Contents
    RemoveMouse(block)
    SavePoints(contents.QuestName)
    SavePoints(contents.TopText)
    StyleText(contents.QuestName, true, block)
    StyleText(contents.TopText, false, block)
    Save(block).popup = true
    local button = popupButtons[block]
    if not button then
        button = CreateFrame("Button", nil, block)
        button:SetPoint("TOPLEFT", contents.QuestName, "TOPLEFT")
        button:SetPoint("BOTTOMRIGHT", contents.TopText, "BOTTOMRIGHT")
        button:SetScript("OnClick", function(_, mouseButton)
            if mouseButton == "LeftButton" and block.questID
                and C_QuestLog.GetLogIndexForQuestID(block.questID) then
                HandleQuestClick(block.questID, mouseButton)
            end
        end)
        --- Refreshes popup text colors when its replacement click target is hovered.
        local function Highlight(highlighted)
            if active and not changing and states[block] then
                SetField(block, "isHighlighted", highlighted)
                StyleText(contents.QuestName, true, block)
                StyleText(contents.TopText, false, block)
            end
        end
        button:SetScript("OnEnter", function() Highlight(true) end)
        button:SetScript("OnLeave", function() Highlight(false) end)
        popupButtons[block] = button
    end
    button:SetShown(block.questID ~= nil and C_QuestLog.GetLogIndexForQuestID(block.questID) ~= nil)
    for _, region in ipairs({ contents:GetRegions() }) do
        if region ~= contents.QuestName and region ~= contents.TopText then
            Hide(region)
        end
    end
    Hide(contents.FlashFrame)
    contents.QuestName:ClearAllPoints()
    contents.QuestName:SetPoint("TOPLEFT", contents, "TOPLEFT", 0, 0)
    contents.QuestName:SetPoint("RIGHT", contents, "RIGHT", 0, 0)
    contents.TopText:ClearAllPoints()
    contents.TopText:SetPoint("TOPLEFT", contents.QuestName, "BOTTOMLEFT", 6, -4)
    contents.TopText:SetPoint("RIGHT", contents, "RIGHT", 0, 0)
    local state = Save(contents.QuestName)
    if state.height == nil then state.height = contents.QuestName:GetHeight() end
    contents.QuestName:SetHeight(0)
    contents.TopText:SetText(block.popUpType == "COMPLETE"
        and QUEST_WATCH_QUEST_COMPLETE or QUEST_WATCH_POPUP_QUEST_DISCOVERED)
    SetField(block, "offsetX", block.parentModule.blockOffsetX)
    local height = contents.QuestName:GetStringHeight() + contents.TopText:GetStringHeight() + 4
    if block.height ~= height then
        SetField(block, "height", height)
        block.parentModule:MarkDirty()
    end
end

--- Hides actionable controls inside tracker widget containers without stopping their updates.
StyleWidgets = function(root)
    if not root then
        return
    end
    -- Widget containers must keep running. Only actionable controls inside them are hidden.
    for _, child in ipairs({ root:GetChildren() }) do
        if child:GetScript("OnClick") or child:GetScript("OnMouseUp") then
            Hide(child)
        else
            StyleWidgets(child)
        end
    end
end

--- Styles an objective block and hooks its native layout updates to keep dynamic content styled.
--- Uses Blizzard's block APIs and preserves essential widget containers.
StyleBlock = function(block)
    if not active or not block or not CanChange(block) then
        return
    end
    if block.Contents and block.Contents.QuestName then
        StylePopup(block)
        Hook(block, "Update", StyleBlock)
        return
    end
    StyleTitle(block)
    if block:GetScript("OnMouseUp") or block:GetScript("OnClick") then
        RemoveMouse(block)
    end
    Hide(block.HeaderGlow)
    Hide(block.poiButton)
    Hide(block.findGroupButton)
    if block.addedRegions then
        for region in pairs(block.addedRegions) do
            if region.SpellButton then
                Hide(region.SpellButton)
                StyleText(region.SpellName)
            end
        end
    end
    if block.usedLines then
        for _, line in pairs(block.usedLines) do
            StyleLine(line)
        end
    end
    StyleWidgets(block.WidgetContainer)
    Hook(block, "GetLine", function(self, key) StyleLine(self:GetExistingLine(key)) end)
    Hook(block, "AddObjective", function(self, key)
        if active and key == "ClickComplete" then
            local line = self:GetExistingLine(key)
            if states[line] and states[line.Text] and states[line.Text].omit then
                self.height = self.height - line:GetHeight() - self.parentModule.lineSpacing
                self.lastRegion = states[line].previousRegion
            end
        end
    end)
    Hook(block, "SetHeader", function(self)
        if active and CanChange(self) then
            StyleTitle(self)
            self.height = self.HeaderText:GetHeight()
        end
    end)
    Hook(block, "UpdateHighlight", function(self)
        if active then
            StyleText(self.HeaderText, true, self)
            for _, line in pairs(self.usedLines) do StyleText(line.Text, false, self) end
        end
    end)
    Hook(block, "AdjustRightEdgeOffset", function(self)
        if active then self.rightEdgeOffset = 0 end
    end)
    Hook(block, "AddRightEdgeFrame", function(self)
        if active then
            for region in pairs(self.addedRegions or {}) do
                if region.SetUp then Hide(region) end
            end
        end
    end)
    Hook(block, "OnLayout", StyleBlock)
end

--- Styles scenario stage artwork, fixed blocks and pooled spell frames when present.
local function StyleScenario(module)
    local stage = module.StageBlock
    if stage then
        Hide(stage.NormalBG)
        Hide(stage.FinalBG)
        Hide(stage.ThemeOverlay)
        Hide(stage.GlowTexture)
        Hide(stage.findGroupButton)
        StyleText(stage.Stage)
        StyleText(stage.Name)
        StyleText(stage.CompleteLabel)
        Hook(stage, "UpdateStageBlock", function() if active then StyleScenario(module) end end)
    end
    if module.spellFramePool then
        for spell in module.spellFramePool:EnumerateActive() do
            Hide(spell.SpellButton)
            StyleText(spell.SpellName)
        end
    end
    for _, block in ipairs(module.FixedBlocks or {}) do
        StyleBlock(block)
    end
end

--- Styles a tracker module, keeps it expanded and hooks dynamically created blocks and widgets.
local function StyleModule(module)
    if not active or not CanChange(module) then
        return
    end
    Expand(module)
    local meaningfulHeader = module == ScenarioObjectiveTracker or module == UIWidgetObjectiveTracker
    Hide(module.Header.Background)
    Hide(module.Header.Glow)
    Hide(module.Header.Shine)
    Hide(module.Header.MinimizeButton)
    if meaningfulHeader then
        StyleText(module.Header.Text, true)
    else
        Hide(module.Header)
        local state = Save(module.Header)
        if state.height == nil then state.height = module.Header:GetHeight() end
        module.Header:SetHeight(0.01)
        SetField(module, "headerHeight", 0)
        SetField(module, "fromHeaderOffsetY", -4)
        SetField(module, "blockOffsetX", 0)
    end
    Hook(module, "GetBlock", function(self, id, template)
        if active then StyleBlock(self:GetExistingBlock(id, template)) end
    end)
    Hook(module, "LayoutBlock", function(_, block) StyleBlock(block) end)
    Hook(module, "EndLayout", function(self)
        if active then
            StyleScenario(self)
            if self == UIWidgetObjectiveTracker then
                StyleWidgets(ObjectiveTrackerUIWidgetContainer)
            end
        end
    end)
    if module.EnumerateActiveBlocks then
        module:EnumerateActiveBlocks(StyleBlock)
    end
    StyleScenario(module)
end

--- Restores saved tracker properties, scripts and layout when styling ends or a frame is released.
--- A released pooled frame keeps its current visibility under Blizzard's control.
local function Restore(frame, state, released)
    if state.fields then
        for key, value in pairs(state.fields) do frame[key] = value[1] end
    end
    if state.height then frame:SetHeight(state.height) end
    if state.frameLevel ~= nil then frame:SetFrameLevel(state.frameLevel) end
    if state.points then
        frame:ClearAllPoints()
        for _, point in ipairs(state.points) do frame:SetPoint(unpack(point)) end
    end
    if state.font then
        if state.fontObject then
            frame:SetFontObject(state.fontObject)
        else
            frame:SetFont(unpack(state.font))
        end
    end
    if state.color then frame:SetTextColor(unpack(state.color)) end
    if state.text ~= nil then frame:SetText(state.text) end
    if state.popup then
        frame.questID = nil
        popupButtons[frame]:Hide()
    end
    if state.mouse ~= nil then frame:EnableMouse(state.mouse) end
    if state.scripts then
        for script, value in pairs(state.scripts) do frame:SetScript(script, value[1]) end
    end
    if state.shown ~= nil and not released then frame:SetShown(state.shown) end
end

--- Restores a released pooled frame and its tracked descendants before Blizzard reuses them.
local function RestoreReleased(frame)
    if not active then
        return
    end
    changing = true
    for object, state in pairs(states) do
        local parent = object
        while parent and parent ~= frame do parent = parent:GetParent() end
        if parent == frame then
            Restore(object, state, object == frame)
            states[object] = nil
        end
    end
    changing = false
end

--- Styles a tracker container and its modules while preserving provider-driven top padding.
local function StyleContainer(container)
    if not active or not CanChange(container) then
        return
    end
    Expand(container)
    Hide(container.Header)
    Hide(container.NineSlice)
    --- Recalculates top padding from Blizzard's registered padding providers.
    local function UpdatePadding(self)
        if active then
            local padding = 0
            for provider in pairs(self.topPaddingProviders or {}) do
                padding = padding + provider:GetTopPadding()
            end
            self.topModulePadding = padding
        end
    end
    SetField(container, "topModulePadding", container.topModulePadding)
    UpdatePadding(container)
    Hook(container, "UpdateTopPadding", UpdatePadding)
    for _, module in ipairs(container.modules) do StyleModule(module) end
end

--- Applies or restores the minimalist tracker according to settings and Blizzard tracker readiness.
--- Defers changes in combat and refreshes the tracker after updating saved state.
function ErzbaroneUI.Objectives:Update()
    if not self.Initialized then
        self:Initialize()
        return
    end
    if InCombatLockdown() then
        self.PendingUpdate = true
        return
    end
    local enabled = ErzbaroneUISettings.minimalistObjectives
    if not ObjectiveTrackerManager or not ObjectiveTrackerFrame or not ObjectiveTrackerLineFont then
        return
    end
    if enabled and (not ObjectiveTrackerManager.containers or not ObjectiveTrackerFrame.UpdateTopPadding
        or not QuestUtil or not QuestUtil.OpenQuestDetails) then
        print("ErzbaroneUI: Minimalist Objective Tracker is unavailable with this tracker API.")
        return
    end
    if not enabled and not active then return end

    Hook(ObjectiveTrackerManager, "ReleaseFrame", function(_, frame) RestoreReleased(frame) end)
    Hook(ObjectiveTrackerManager, "SetModuleContainer", function(_, module, container)
        if active then StyleContainer(container) end
    end)
    Hook(ObjectiveTrackerManager, "SetTextSize", function()
        if active then ErzbaroneUI.Objectives:Update() end
    end)
    if enabled then
        active = true
        for container in pairs(ObjectiveTrackerManager.containers) do StyleContainer(container) end
    else
        active = false
        changing = true
        for frame, state in pairs(states) do Restore(frame, state) end
        for frame, state in pairs(states) do
            if state.collapsed ~= nil then frame:SetCollapsed(state.collapsed) end
        end
        states = {}
        changing = false
    end
    ObjectiveTrackerManager:UpdateAll()
end

--- Registers tracker loading and combat events, then applies the current setting.
function ErzbaroneUI.Objectives:Initialize()
    if not self.Initialized then
        self.Initialized = true
        eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("ADDON_LOADED")
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        eventFrame:SetScript("OnEvent", function(_, event, name)
            if event == "ADDON_LOADED" and name == "Blizzard_ObjectiveTracker"
                or event == "PLAYER_ENTERING_WORLD"
                or event == "PLAYER_REGEN_ENABLED" and self.PendingUpdate then
                self.PendingUpdate = false
                self:Update()
            end
        end)
    end
    self:Update()
end
