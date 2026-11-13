local root = (... or ".") .. "\\"

local function Equal(actual, expected, message)
    assert(actual == expected, message .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end

local cursorX, cursorY = 800, 600
local frames = {}
local borders = {}
local function Widget()
    local widget = { shown = true, scripts = {}, textures = {}, labels = {} }
    function widget:SetSize(width, height) self.width, self.height = width, height end
    function widget:SetPoint(point, relative, relativePoint, x, y)
        self.point = { point, relative, relativePoint, x, y }
        if relative == UIParent then
            self.left, self.top = x, y
            if self.clamped then
                self.left = math.max(0, math.min(UIParent.width - self.width, x))
                self.top = math.max(self.height, math.min(UIParent.height, y))
            end
        end
    end
    function widget:ClearAllPoints() self.point = nil end
    function widget:SetAllPoints(relative) self.relative = relative end
    function widget:SetTexture(texture) self.texture = texture end
    function widget:SetBlendMode(mode) self.blendMode = mode end
    function widget:SetAlpha(alpha) self.alpha = alpha end
    function widget:SetVertexColor(...) self.color = { ... } end
    function widget:SetText(text) self.text = text end
    function widget:SetTextColor(...) self.textColor = { ... } end
    function widget:GetFont() return self.font or "Fonts\\FRIZQT__.TTF", self.fontSize or 12, "OUTLINE" end
    function widget:SetFont(font, size, flags)
        self.font, self.fontSize, self.fontFlags = font, size, flags
        return true
    end
    function widget:GetStringWidth() return #self.text * (self.fontSize or 12) / 2 end
    function widget:SetJustifyH(justify) self.justify = justify end
    function widget:SetShown(shown) self.shown = shown end
    function widget:Show() self:SetShown(true) end
    function widget:Hide() self:SetShown(false) end
    function widget:IsShown() return self.shown end
    function widget:SetFrameStrata(strata) self.strata = strata end
    function widget:SetClampedToScreen(clamped) self.clamped = clamped end
    function widget:EnableMouse(enabled) self.mouseEnabled = enabled end
    function widget:SetBackdrop(backdrop) self.backdrop = backdrop end
    function widget:SetBackdropColor(...) end
    function widget:SetBackdropBorderColor(...) end
    function widget:SetBorderColor(...) self.borderColor = { ... } end
    function widget:GetEffectiveScale() return UIParent.scale end
    function widget:GetLeft() return self.left end
    function widget:GetTop() return self.top end
    function widget:SetScript(script, callback) self.scripts[script] = callback end
    function widget:RegisterEvent(event) self.event = event end
    function widget:CreateTexture()
        local texture = Widget()
        self.textures[#self.textures + 1] = texture
        return texture
    end
    function widget:CreateFontString()
        local label = Widget()
        self.labels[#self.labels + 1] = label
        return label
    end
    return widget
end

UIParent = { scale = 1, width = 1920, height = 1080 }
UISpecialFrames = {}
ErzbaroneUISettings = { emoteFontSize = 12 }
function GetCursorPosition() return cursorX, cursorY end
function CreateFrame(kind, name, parent, template)
    Equal(kind, "Frame", "Selection must not create protected action buttons")
    local frame = Widget()
    frame.name = name
    if parent == UIParent then
        Equal(template, "BackdropTemplate", "Selection must use a classic backdrop")
        frames[#frames + 1] = frame
    else
        Equal(template, "NineSlicePanelTemplate", "Decorative border must use native nine-slice framing")
        Equal(parent, frames[1], "Border must follow the selection box")
        borders[#borders + 1] = frame
    end
    return frame
end
NineSliceUtil = {
    ApplyLayoutByName = function(frame, layout)
        Equal(layout, "Dialog", "Border must use the native DiamondMetal dialog artwork")
        frame.layout = layout
    end,
}
function SetBinding() error("Selection must not assign a key") end
function SetOverrideBinding() error("Selection must not override existing bindings") end
local performed = {}
C_ChatInfo = { PerformEmote = function(token) performed[#performed + 1] = token end }

dofile(root .. "modules\\emotes.lua")
ErzbaroneUI.Emotes:Initialize()
ErzbaroneUI.Emotes:Initialize()
Equal(#frames, 1, "Repeated initialization must reuse the box")
local box = frames[1]
Equal(#borders, 1, "Repeated initialization must reuse the decorative border")
Equal(borders[1].relative, box, "Border anchors must resize with the box")
Equal(borders[1].mouseEnabled, false, "Border must not intercept selection input")
Equal(box:IsShown(), false, "Box must start hidden")
Equal(#box.labels, 36, "Box must offer four columns of nine emote names")
local tokens = {
    "APOLOGIZE", "ATTACKTARGET", "BEG", "BLAME", "BOW", "BYE", "CHEER", "CLAP", "CRY",
    "BONK", "DRINK", "FLEX", "FLIRT", "FOLLOWME", "GOLFCLAP", "HELLO", "HUG", "KISS",
    "KNEEL", "LAUGH", "MERCY", "NO", "NOD", "OOM", "POINT", "ROAR", "RUDE",
    "SALUTE", "SCARED", "SHRUG", "SILLY", "SLEEP", "TAUNT", "THANK", "WAVE", "YAWN",
}
local columns = {}
for index, label in ipairs(box.labels) do
    assert(not label.text:find("/"), "Labels must contain only emote names, not slash commands")
    if index > 1 then assert(box.labels[index - 1].text < label.text, "Names must be alphabetically sorted") end
    local x = label.point[4]
    columns[x] = (columns[x] or 0) + 1
    assert(columns[x] <= 9, "Columns must not contain more than nine entries")
    assert(-label.point[5] > 0 and -label.point[5] < box.height, "Every name must fit inside the box")
end
local columnCount = 0
for _ in pairs(columns) do columnCount = columnCount + 1 end
Equal(columnCount, 4, "There must be exactly four columns")

local function Highlighted(selected)
    for index, highlight in ipairs(box.textures) do
        Equal(highlight:IsShown(), index == selected,
            "Only the hovered row must highlight (selected " .. tostring(selected) .. ", highlight " .. index .. ")")
    end
end

local function Open(x, y)
    ErzbaroneUI.Emotes:HandleBinding("up")
    cursorX, cursorY = x or 800, y or 600
    ErzbaroneUI.Emotes:HandleBinding("down")
    Equal(box:IsShown(), true, "Holding the key must open the box")
end

local function Hover(index)
    local highlight = box.textures[index]
    cursorX = (box.left + highlight.point[4] + highlight.width / 2) * UIParent.scale
    cursorY = (box.top + highlight.point[5] - highlight.height / 2) * UIParent.scale
end

local function Click(button)
    if box.scripts.OnMouseUp then box.scripts.OnMouseUp(box, button) end
end

Open()
Equal(box.left, 812, "Box must open beside the cursor")
Equal(box.top, 588, "Box must open below the cursor")
Highlighted(nil)
cursorX, cursorY = 900, 700
ErzbaroneUI.Emotes:HandleBinding("down")
Equal(box.left, 812, "Repeated key-down must not reposition the box")
cursorX, cursorY = 800, 600
ErzbaroneUI.Emotes:HandleBinding("up")
Equal(#performed, 0, "Releasing without hovering an entry must cancel")

for index, token in ipairs(tokens) do
    Open()
    Hover(index)
    box.scripts.OnUpdate(box, 0.016)
    Highlighted(index)
    Equal(#performed, index - 1, "Hovering must not perform an emote")
    Click("LeftButton")
    Click("RightButton")
    Equal(box:IsShown(), true, "Mouse clicks must not select, cancel or change pages")
    Equal(#performed, index - 1, "Mouse clicks must not perform an emote")
    ErzbaroneUI.Emotes:HandleBinding("up")
    Equal(performed[index], token, "Release must execute the hovered name")
    Equal(box:IsShown(), false, "Release must close the box")
    ErzbaroneUI.Emotes:HandleBinding("up")
    Equal(#performed, index, "Repeated release must not duplicate emotes")
end

local function CancelAt(x, y, message)
    Open()
    cursorX, cursorY = box.left + x, box.top - y
    box.scripts.OnUpdate(box, 0.016)
    Highlighted(nil)
    ErzbaroneUI.Emotes:HandleBinding("up")
    Equal(#performed, 36, message)
end
CancelAt(1, 1, "Borders must not select an emote")
CancelAt(-1, 30, "Outside the box must cancel")
local first, secondColumn = box.textures[1], box.textures[10]
CancelAt((first.point[4] + first.width + secondColumn.point[4]) / 2, 20,
    "Column gaps must not select an emote")
CancelAt(20, box.height - 1, "Bottom border must cancel")

UIParent.scale = 0.75
Open(600, 450)
Equal(box.left, 812, "Placement must account for UI scale")
Hover(35)
ErzbaroneUI.Emotes:HandleBinding("up")
Equal(performed[37], "WAVE", "Release must use current scaled cursor coordinates without a hover update")
Open(1920 * UIParent.scale, 0)
Equal(box.left, UIParent.width - box.width, "Box must stay visible at the right edge")
Equal(box.top, box.height, "Box must stay visible at the bottom edge")
Hover(1)
ErzbaroneUI.Emotes:HandleBinding("up")
Equal(performed[38], "APOLOGIZE", "Selection must follow the actual clamped box position")

Open()
Hover(2)
box.scripts.OnEvent(box, "PLAYER_LEAVING_WORLD")
ErzbaroneUI.Emotes:HandleBinding("up")
Equal(#performed, 38, "Leaving the world must not perform an emote")
Open()
ErzbaroneUI.Emotes:HandleBinding("up")

local bindings = assert(io.open(root .. "Bindings.xml", "r"))
local xml = bindings:read("*a")
bindings:close()
assert(xml:match('name="ERZBARONEUI_EMOTE_WHEEL"'), "Existing user keybindings must keep their identifier")
assert(xml:match('runOnUp="true"'), "Binding must receive key release events")
local bindingBody = assert(xml:match("<Binding%s[^>]*>(.-)</Binding>"))
local environment = setmetatable({ keystate = "down" }, { __index = _G })
local binding
if _VERSION == "Lua 5.1" then
    binding = assert(loadstring(bindingBody))
    setfenv(binding, environment)
else
    binding = assert(load(bindingBody, "emote binding", "t", environment))
end
binding()
Equal(box:IsShown(), true, "Existing XML binding must open the text selection")
Hover(10)
environment.keystate = "up"
binding()
Equal(performed[39], "BONK", "Existing XML binding must execute the hovered name on release")

UIParent.scale = 1
Open()
local originalWidth, originalHeight = box.width, box.height
ErzbaroneUISettings.emoteFontSize = 24
ErzbaroneUI.Emotes:Update()
Equal(#frames, 1, "Font updates must reuse the box")
assert(box.width > originalWidth and box.height > originalHeight, "Larger text must expand the box")
for index, label in ipairs(box.labels) do
    Equal(label.fontSize, 24, "Font update must resize every emote name")
    Equal(label.fontFlags, "OUTLINE", "Font update must preserve native font flags")
    assert(box.textures[index].width >= label:GetStringWidth() + 24, "Narrower columns must still fit the enlarged text")
    assert(box.textures[index].height >= label.fontSize + 10, "Hover rows must fit the enlarged text")
end
Hover(35)
ErzbaroneUI.Emotes:HandleBinding("up")
Equal(performed[40], "WAVE", "Release selection must follow the resized rows without a hover update")
ErzbaroneUISettings.emoteFontSize = 10
ErzbaroneUI.Emotes:Update()
Equal(box.labels[1].fontSize, 10, "Minimum font size must be supported")
Equal(box.height, originalHeight, "Small text must retain usable minimum row height")
ErzbaroneUISettings.emoteFontSize = "invalid"
local nativePrint, errors = print, {}
print = function(message) errors[#errors + 1] = message end
ErzbaroneUI.Emotes:Update()
print = nativePrint
Equal(#errors, 1, "Invalid saved font sizes must be reported")
Equal(ErzbaroneUISettings.emoteFontSize, 12, "Invalid saved font sizes must be repaired")
Equal(box.width, originalWidth, "Restoring default text must restore the original box width")

print("emotes_test.lua: all assertions passed")
