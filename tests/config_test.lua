local root = (... or ".") .. "\\"

dofile(root .. "modules\\config.lua")

local toc = assert(io.open(root .. "ErzbaroneUI.toc", "r"))
local metadata = toc:read("*a")
toc:close()
local callbackName = assert(metadata:match("## AddonCompartmentFunc:%s*([%w_]+)"),
    "Missing AddOns menu callback metadata")
local callback = assert(_G[callbackName], "AddOns menu callback is not a global function")

local categoryID = 42
ErzbaroneUI.Config.Category = {
    GetID = function() return categoryID end,
}

local openedCategories = {}
Settings = {
    OpenToCategory = function(id)
        openedCategories[#openedCategories + 1] = id
    end,
}

callback("ErzbaroneUI", "LeftButton")
assert(#openedCategories == 1 and openedCategories[1] == categoryID,
    "Left-clicking the AddOns entry must open the registered settings category")

categoryID = 73
callback("ErzbaroneUI", "RightButton")
assert(#openedCategories == 2 and openedCategories[2] == categoryID,
    "Right-clicking the AddOns entry must open the current settings category")

local frames = {}
local dropdowns = {}
local function Widget(name)
    local widget = { name = name, scripts = {}, enabled = true, fontStrings = {} }
    function widget:GetName() return self.name end
    function widget:SetSize(width, height) self.width, self.height = width, height end
    function widget:SetWidth(width) self.width = width end
    function widget:SetHeight(height) self.height = height end
    function widget:GetHeight() return self.height or self.fontHeight or 0 end
    function widget:GetStringHeight() return self.fontHeight or 14 end
    function widget:SetPoint(...) self.point = { ... } end
    function widget:GetTop()
        if not self.point then return 0 end
        local relative, relativePoint, y = self.point[2], self.point[3], self.point[5]
        if type(relative) == "number" then return self.parent:GetTop() + relativePoint end
        local anchor = relativePoint == "BOTTOMLEFT" and relative:GetBottom() or relative:GetTop()
        return anchor + (y or 0)
    end
    function widget:GetBottom() return self:GetTop() - self:GetHeight() end
    function widget:ClearAllPoints() end
    function widget:SetHitRectInsets(...) end
    function widget:SetFontObject(...) end
    function widget:SetJustifyH(...) end
    function widget:SetWordWrap(...) end
    function widget:SetText(text) self.text = text end
    function widget:SetColorTexture(...) end
    function widget:SetChecked(value) self.checked = value and true or false end
    function widget:GetChecked() return self.checked end
    function widget:Enable() self.enabled = true end
    function widget:Disable() self.enabled = false end
    function widget:SetScript(script, handler) self.scripts[script] = handler end
    function widget:HookScript(script, handler) self.scripts[script] = handler end
    function widget:RegisterEvent(event) self.event = event end
    function widget:CreateFontString(_, _, font)
        local fontString = Widget()
        fontString.parent = self
        fontString.fontHeight = font == "GameFontNormalLarge" and 18
            or font == "GameFontHighlightSmall" and 12 or 14
        self.fontStrings[#self.fontStrings + 1] = fontString
        return fontString
    end
    function widget:CreateTexture() return Widget() end
    function widget:EnableMouseWheel(enabled) self.mouseWheelEnabled = enabled end
    function widget:SetScrollChild(child) self.scrollChild = child end
    function widget:GetVerticalScrollRange() return math.max(0, self.scrollChild.height - self.height) end
    function widget:SetVerticalScroll(value)
        self.scrollOffset = math.max(0, math.min(value, self:GetVerticalScrollRange()))
    end
    function widget:SetupMenu(callback) self.menu = callback end
    function widget:GenerateMenu() end
    function widget:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
    function widget:SetValueStep(step) self.step = step end
    function widget:SetObeyStepOnDrag(value) self.obeyStep = value end
    function widget:GetValue() return self.value end
    function widget:SetValue(value)
        local changed = self.value ~= value
        self.value = value
        if changed and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
    end
    return widget
end

function CreateFrame(kind, name, parent, template)
    local frame = Widget(name)
    frame.parent, frame.template = parent, template
    if kind == "DropdownButton" then dropdowns[#dropdowns + 1] = frame end
    if kind == "CheckButton" then frame.Text = Widget() end
    if name then
        frames[name] = frame
        _G[name] = frame
    end
    return frame
end
GameTooltip_Hide = function() end
ErzbaroneUISettings = {}
local cvars = { HDROutput = "0", HDRFactor = "2.0" }
local writes, failWrites = {}, false
local panel
C_CVar = {
    GetCVar = function(name) return cvars[name] end,
    SetCVar = function(name, value)
        writes[#writes + 1] = { name, value }
        if failWrites then return false end
        cvars[name] = value
        if panel then panel.scripts.OnEvent(panel, "CVAR_UPDATE", name, value) end
        return true
    end,
}
Settings.RegisterCanvasLayoutCategory = function() return { GetID = function() return 1 end } end
Settings.RegisterAddOnCategory = function() end
Settings.VarType = { Boolean = "boolean" }
Settings.CommitFlag = { Apply = "apply", UIReload = "reload" }
local registeredSetting
Settings.RegisterAddOnSetting = function(category, variable, key, values, variableType, name, default)
    assert(variable == "ERZBARONEUI_NEUTRAL_DECORATIONS" and key == "neutralDecorations")
    assert(variableType == Settings.VarType.Boolean and name == "Neutral Frame Artwork")
    if values[key] == nil then values[key] = default end
    local setting = { flags = {}, values = values, key = key }
    function setting:SetCommitFlags(...)
        for _, flag in ipairs({ ... }) do self.flags[flag] = true end
    end
    function setting:GetValue()
        if self.pending ~= nil then return self.pending end
        return self.values[self.key]
    end
    function setting:SetValue(value)
        assert(self.flags[Settings.CommitFlag.Apply], "Value must be staged until Apply")
        if value == self.values[self.key] then self.pending = nil else self.pending = value end
        if self.callback then self.callback() end
    end
    function setting:SetValueChangedCallback(callback) self.callback = callback end
    function setting:Discard()
        self.pending = nil
        if self.callback then self.callback() end
    end
    function setting:Apply()
        if self.pending == nil then return false end
        self.values[self.key] = self.pending
        self.pending = nil
        if self.callback then self.callback() end
        return self.flags[Settings.CommitFlag.UIReload]
    end
    registeredSetting = setting
    return setting
end
ErzbaroneUI.StatusBars = { GetTextureOptions = function() return {} end }
local emoteUpdates = 0
ErzbaroneUI.Emotes = {
    GetFontSizeOptions = function() return { { 12, "12" }, { 24, "24" } } end,
    Update = function() emoteUpdates = emoteUpdates + 1 end,
}
local nameplateUpdates = 0
ErzbaroneUI.Nameplates = {
    Update = function() nameplateUpdates = nameplateUpdates + 1 end,
}
local objectiveUpdates = 0
ErzbaroneUI.Objectives = {
    Update = function() objectiveUpdates = objectiveUpdates + 1 end,
}
local worldMapUpdates = 0
ErzbaroneUI.WorldMap = {
    Update = function() worldMapUpdates = worldMapUpdates + 1 end,
}
local mainBarUpdates = 0
dofile(root .. "modules\\mainbar.lua")
ErzbaroneUI.MainBar.Update = function() mainBarUpdates = mainBarUpdates + 1 end
local primaryKey, secondaryKey
function GetBindingKey(action)
    assert(action == "ERZBARONEUI_EMOTE_WHEEL", "Settings must use the existing binding identifier")
    return primaryKey, secondaryKey
end
function GetBindingText(key) return "display:" .. key end
Settings.KEYBINDINGS_CATEGORY_ID = 99
ErzbaroneUI.Config.Panel = nil
ErzbaroneUI.Config:RegisterSettingsPanel()
panel = ErzbaroneUI.Config.Panel
local checkbox = frames.ErzbaroneUISetting_HDROutput
local slider = frames.ErzbaroneUIHDRFactorSlider
local scroll = assert(frames.ErzbaroneUISettingsScrollFrame)
local content = assert(scroll.scrollChild)
assert(scroll.parent == panel and scroll.template == "ScrollFrameTemplate" and scroll.mouseWheelEnabled,
    "Settings must use the native mouse-wheel scroll frame inside the registered canvas")
assert(scroll.point[1] == "BOTTOMRIGHT" and scroll.point[2] == panel and scroll.point[5] == 0,
    "The scroll viewport must end at the canvas bottom, above the native settings buttons")
assert(slider.parent.parent == content, "The HDR slider must belong to the scrollable content")
assert(content.height >= -slider.parent:GetBottom() + 16,
    "Scrollable content must extend past the entire HDR slider")
local lastLeftControl = assert(frames.ErzbaroneUISetting_fadeChatTabs)
assert(lastLeftControl.parent == content and content.height >= -lastLeftControl:GetBottom() + 16,
    "Scrollable content must also extend past the last control in the other column")
scroll:SetSize(643, 350)
assert(scroll:GetVerticalScrollRange() > 0, "A shorter viewport must have a vertical scroll range")
scroll:SetVerticalScroll(scroll:GetVerticalScrollRange())
for _, control in ipairs({ slider.parent, lastLeftControl }) do
    assert(control:GetBottom() >= -scroll.scrollOffset - scroll.height
        and control:GetTop() <= -scroll.scrollOffset,
        "The last controls of both columns must be visible when scrolled to the bottom")
end
local nameplateHealth = frames.ErzbaroneUISetting_nameplateHealth
local neutralDecorations = assert(frames.ErzbaroneUISetting_neutralDecorations)
assert(not neutralDecorations.checked, "Neutral artwork must be opt-in")
assert(registeredSetting.flags[Settings.CommitFlag.Apply] and registeredSetting.flags[Settings.CommitFlag.UIReload],
    "Neutral artwork must use Blizzard's Apply and UI reload flags")
neutralDecorations:SetChecked(true)
neutralDecorations.scripts.OnClick(neutralDecorations)
assert(not ErzbaroneUISettings.neutralDecorations and registeredSetting.pending == true,
    "Selecting the theme must stage it without saving or reloading")
neutralDecorations:SetChecked(false)
neutralDecorations.scripts.OnClick(neutralDecorations)
assert(registeredSetting.pending == nil and not registeredSetting:Apply(),
    "Reverting the checkbox before Apply must not request a reload")
neutralDecorations:SetChecked(true)
neutralDecorations.scripts.OnClick(neutralDecorations)
registeredSetting:Discard()
assert(not neutralDecorations.checked and not ErzbaroneUISettings.neutralDecorations,
    "Discarding changes must restore the checkbox and saved setting")
neutralDecorations:SetChecked(true)
neutralDecorations.scripts.OnClick(neutralDecorations)
assert(registeredSetting:Apply() and ErzbaroneUISettings.neutralDecorations,
    "Applying the enabled theme must save it and request a UI reload")
neutralDecorations:SetChecked(false)
neutralDecorations.scripts.OnClick(neutralDecorations)
assert(registeredSetting:Apply() and not ErzbaroneUISettings.neutralDecorations,
    "Applying the disabled theme must save it and request a UI reload")
local minimalistObjectives = assert(frames.ErzbaroneUISetting_minimalistObjectives)
assert(not minimalistObjectives.checked, "Minimalist objectives must be opt-in")
minimalistObjectives:SetChecked(true)
minimalistObjectives.scripts.OnClick(minimalistObjectives)
assert(ErzbaroneUISettings.minimalistObjectives and objectiveUpdates == 1,
    "Enabling minimalist objectives must persist the setting and refresh the tracker")
minimalistObjectives:SetChecked(false)
minimalistObjectives.scripts.OnClick(minimalistObjectives)
assert(not ErzbaroneUISettings.minimalistObjectives and objectiveUpdates == 2,
    "Disabling minimalist objectives must request native tracker restoration")
local worldMapLevels = assert(frames.ErzbaroneUISetting_worldMapLevels)
assert(not worldMapLevels.checked, "World map levels must be opt-in")
worldMapLevels:SetChecked(true)
worldMapLevels.scripts.OnClick(worldMapLevels)
assert(ErzbaroneUISettings.worldMapLevels and worldMapUpdates == 1, "Enabling map levels must update immediately")
worldMapLevels:SetChecked(false)
worldMapLevels.scripts.OnClick(worldMapLevels)
assert(not ErzbaroneUISettings.worldMapLevels and worldMapUpdates == 2, "Disabling map levels must update immediately")
assert(panel.event == "CVAR_UPDATE")
assert(#writes == 0, "Opening settings must not change HDR CVars")
assert(not checkbox.checked and slider.value == 2)
assert(not nameplateHealth.checked, "Enemy nameplate health is disabled by default")
nameplateHealth:SetChecked(true)
nameplateHealth.scripts.OnClick(nameplateHealth)
assert(ErzbaroneUISettings.nameplateHealth and nameplateUpdates == 1,
    "Enabling enemy nameplate health saves the setting and refreshes the module")
nameplateHealth:SetChecked(false)
nameplateHealth.scripts.OnClick(nameplateHealth)
assert(not ErzbaroneUISettings.nameplateHealth and nameplateUpdates == 2,
    "Disabling enemy nameplate health saves the setting and refreshes the module")
assert(slider.minimum == 1 and slider.maximum == 2 and slider.step == 0.01 and slider.obeyStep)
checkbox:SetChecked(true)
checkbox.scripts.OnClick(checkbox)
assert(cvars.HDROutput == "1", "Checkbox enables HDR output")
slider:SetValue(1.37)
assert(cvars.HDRFactor == "1.37", "Slider writes the selected factor")
checkbox:SetChecked(false)
checkbox.scripts.OnClick(checkbox)
assert(cvars.HDROutput == "0", "Checkbox disables HDR output")

cvars.HDROutput, cvars.HDRFactor = "1", "3.25"
local previousWrites = #writes
panel.scripts.OnEvent(panel, "CVAR_UPDATE", "hdrOUTPUT")
panel.scripts.OnEvent(panel, "CVAR_UPDATE", "HDRFACTOR")
assert(checkbox.checked and slider.value == 2, "External changes refresh both controls")
assert(slider.parent.fontStrings[2].text == "3.25 (outside 1-2)", "The actual out-of-range factor is displayed")
assert(slider.parent.Refresh and cvars.HDRFactor == "3.25" and #writes == previousWrites,
    "Out-of-range values are not overwritten on refresh")
slider.parent.scripts.OnShow(slider.parent)
assert(cvars.HDRFactor == "3.25" and #writes == previousWrites)
slider.scripts.OnMouseUp(slider)
assert(cvars.HDRFactor == "2.00", "Selecting the clamped endpoint replaces an out-of-range value")
slider:SetValue(1.75)
assert(cvars.HDRFactor == "1.75", "A deliberate slider change replaces an out-of-range value")

failWrites = true
local errors = {}
local nativePrint = print
print = function(message) errors[#errors + 1] = message end
checkbox:SetChecked(false)
checkbox.scripts.OnClick(checkbox)
slider:SetValue(1.50)
print = nativePrint
assert(checkbox.checked and slider.value == 1.75, "Failed writes restore the actual CVar values")
assert(#errors == 2, "Failed CVar writes are reported")
cvars.HDROutput, cvars.HDRFactor = nil, nil
panel.scripts.OnEvent(panel, "CVAR_UPDATE", "HDROutput")
panel.scripts.OnEvent(panel, "CVAR_UPDATE", "HDRFactor")
assert(not checkbox.enabled and not slider.enabled, "Unavailable CVars disable their controls")
assert(checkbox.Text.text:find("unavailable", 1, true))
assert(ErzbaroneUISettings.HDROutput == nil and ErzbaroneUISettings.HDRFactor == nil,
    "HDR CVars are not duplicated in addon settings")

local bindingButton = assert(frames.ErzbaroneUIEmoteKeybinding, "Missing emote binding control")
assert(bindingButton.text == "Not bound", "Binding control must show when no key is assigned")
primaryKey, secondaryKey = "SHIFT-F", "CTRL-G"
bindingButton.parent.scripts.OnEvent(bindingButton.parent, "UPDATE_BINDINGS")
assert(bindingButton.text == "display:SHIFT-F / display:CTRL-G", "Binding changes must refresh both localized keys")
bindingButton.scripts.OnClick(bindingButton)
assert(openedCategories[#openedCategories] == 99, "Binding control must open native Keybindings settings")
primaryKey, secondaryKey = nil, nil
bindingButton.parent.scripts.OnShow(bindingButton.parent)
assert(bindingButton.text == "Not bound", "Reopening settings must refresh removed bindings")

local fontDropdown
for _, dropdown in ipairs(dropdowns) do
    if dropdown.parent.fontStrings[1].text == "Font Size" then fontDropdown = dropdown end
end
assert(fontDropdown, "Missing emote font-size dropdown")
local radios = {}
fontDropdown.menu(fontDropdown, {
    CreateRadio = function(_, label, isSelected, selectOption)
        radios[label] = { isSelected = isSelected, selectOption = selectOption }
    end,
})
radios["24"].selectOption()
assert(ErzbaroneUISettings.emoteFontSize == 24 and radios["24"].isSelected(),
    "Selecting font size must save a numeric preference")
assert(emoteUpdates == 1, "Selecting font size must immediately refresh the emote box")
local positionDropdown
for _, dropdown in ipairs(dropdowns) do
    if dropdown.parent.fontStrings[1].text == "Micro Menu Position" then positionDropdown = dropdown end
end
assert(positionDropdown, "Missing micro menu position dropdown")
local positions = {}
positionDropdown.menu(positionDropdown, {
    CreateRadio = function(_, label, isSelected, selectOption)
        positions[#positions + 1] = { label = label, isSelected = isSelected, selectOption = selectOption }
    end,
})
assert(#positions == 3, "Micro menu must offer exactly three position presets")
for index, value in ipairs({ "besideBags", "bottomLeft", "aboveBags" }) do
    positions[index].selectOption()
    assert(ErzbaroneUISettings.microMenuPosition == value and positions[index].isSelected(),
        "Selecting a micro menu position must save the preference")
end
assert(mainBarUpdates == 3, "Selecting a position must request a layout update")
local nativeSetup = ErzbaroneUI.Config.Setup
ErzbaroneUI.Config.Setup = function() end
ErzbaroneUI.Config:Initialize()
assert(ErzbaroneUISettings.emoteFontSize == 24, "Initialization must preserve a saved font size")
assert(ErzbaroneUISettings.microMenuPosition == "aboveBags", "Initialization must preserve a saved menu position")
ErzbaroneUISettings.emoteFontSize = nil
ErzbaroneUISettings.microMenuPosition = nil
ErzbaroneUISettings.nameplateHealth = nil
ErzbaroneUISettings.minimalistObjectives = nil
ErzbaroneUISettings.neutralDecorations = nil
ErzbaroneUI.Config:Initialize()
assert(ErzbaroneUISettings.emoteFontSize == 12, "Missing font size must default to the existing text size")
assert(ErzbaroneUISettings.microMenuPosition == "bottomLeft", "Missing menu position must default to left of gryphons")
assert(not ErzbaroneUISettings.nameplateHealth, "Missing enemy nameplate setting must default to disabled")
assert(ErzbaroneUISettings.minimalistObjectives == false, "Missing minimalist tracker setting must default to disabled")
assert(ErzbaroneUISettings.neutralDecorations == false, "Missing neutral artwork setting must default to disabled")
ErzbaroneUI.Config.Setup = nativeSetup

print("config_test.lua: all assertions passed")
