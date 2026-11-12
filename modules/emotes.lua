ErzbaroneUI = ErzbaroneUI or {}
ErzbaroneUI.Emotes = {}

local ROWS = 8
local COLUMN_GAP = 8
local PADDING = 20
local CURSOR_GAP = 12
local EMOTES = {
    { name = "Apologize", token = "APOLOGIZE" },
    { name = "Beg", token = "BEG" },
    { name = "Bow", token = "BOW" },
    { name = "Bye", token = "BYE" },
    { name = "Cheer", token = "CHEER" },
    { name = "Clap", token = "CLAP" },
    { name = "Cry", token = "CRY" },
    { name = "Doh", token = "BONK" },
    { name = "Drink", token = "DRINK" },
    { name = "Flex", token = "FLEX" },
    { name = "Golfclap", token = "GOLFCLAP" },
    { name = "Hi", token = "HELLO" },
    { name = "Hug", token = "HUG" },
    { name = "Kiss", token = "KISS" },
    { name = "Kneel", token = "KNEEL" },
    { name = "Laugh", token = "LAUGH" },
    { name = "Point", token = "POINT" },
    { name = "Roar", token = "ROAR" },
    { name = "Rude", token = "RUDE" },
    { name = "Salute", token = "SALUTE" },
    { name = "Shrug", token = "SHRUG" },
    { name = "Sleep", token = "SLEEP" },
    { name = "Thanks", token = "THANK" },
    { name = "Wave", token = "WAVE" },
}

local box
local held = false
local entries = {}
local columnWidth
local rowHeight = 22

--- Finds the text row under the cursor, leaving borders and column gaps inactive.
local function GetSelection()
    local x, y = GetCursorPosition()
    local scale = box:GetEffectiveScale()
    local dx, dy = x / scale - box:GetLeft(), box:GetTop() - y / scale
    for index, entry in ipairs(entries) do
        if dx >= entry.x and dx < entry.x + columnWidth
            and dy >= entry.y and dy < entry.y + rowHeight then
            return index
        end
    end
end

--- Highlights only the emote name currently under the cursor.
local function UpdateSelection()
    local selected = GetSelection()
    for index, entry in ipairs(entries) do
        entry.highlight:SetShown(index == selected)
    end
end

--- Returns the font sizes available in the addon's Emotes settings.
function ErzbaroneUI.Emotes:GetFontSizeOptions()
    local options = {}
    for size = 10, 24, 2 do
        options[#options + 1] = { size, tostring(size) }
    end
    return options
end

--- Resizes the text, columns and hover rows without recreating the selection box.
function ErzbaroneUI.Emotes:Update()
    if not box then
        return
    end
    local size = ErzbaroneUISettings.emoteFontSize
    if type(size) ~= "number" or size < 10 or size > 24 or size % 2 ~= 0 then
        print("ErzbaroneUI: Invalid emote font size; resetting it to 12.")
        size = 12
        ErzbaroneUISettings.emoteFontSize = size
    end
    rowHeight = math.max(22, size + 10)
    columnWidth = 80
    for _, entry in ipairs(entries) do
        local font, _, flags = entry.label:GetFont()
        if not entry.label:SetFont(font, size, flags) then
            print("ErzbaroneUI: Could not apply the emote font size.")
            return
        end
        columnWidth = math.max(columnWidth, entry.label:GetStringWidth() + PADDING * 2)
    end
    local columns = math.ceil(#EMOTES / ROWS)
    box:SetSize(PADDING * 2 + columns * columnWidth + (columns - 1) * COLUMN_GAP,
        PADDING * 2 + math.min(ROWS, #EMOTES) * rowHeight)
    for index, entry in ipairs(entries) do
        entry.x = PADDING + math.floor((index - 1) / ROWS) * (columnWidth + COLUMN_GAP)
        entry.y = PADDING + ((index - 1) % ROWS) * rowHeight
        entry.label:ClearAllPoints()
        entry.label:SetPoint("LEFT", box, "TOPLEFT", entry.x + PADDING, -entry.y - rowHeight / 2)
        entry.highlight:SetSize(columnWidth, rowHeight)
        entry.highlight:ClearAllPoints()
        entry.highlight:SetPoint("TOPLEFT", box, "TOPLEFT", entry.x, -entry.y)
    end
    if box:IsShown() then
        UpdateSelection()
    end
end

--- Creates a bronze-styled text selection box with at most eight entries per column.
function ErzbaroneUI.Emotes:Initialize()
    if box then
        return
    end
    box = CreateFrame("Frame", "ErzbaroneUIEmoteSelection", UIParent, "BackdropTemplate")
    box:Hide()
    box:SetFrameStrata("DIALOG")
    box:SetClampedToScreen(true)
    box:EnableMouse(true)
    box:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        tile = true, tileSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    box:SetBackdropColor(0.32, 0.22, 0.14, 0.97)
    local border = CreateFrame("Frame", nil, box, "NineSlicePanelTemplate")
    border:SetAllPoints(box)
    border:EnableMouse(false)
    NineSliceUtil.ApplyLayoutByName(border, "Dialog")
    border:SetBorderColor(0.95, 0.68, 0.38, 1)
    box:SetScript("OnUpdate", UpdateSelection)
    box:RegisterEvent("PLAYER_LEAVING_WORLD")
    box:SetScript("OnEvent", function()
        held = false
        box:Hide()
    end)

    for index, emote in ipairs(EMOTES) do
        local label = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetText(emote.name)
        label:SetTextColor(0.95, 0.83, 0.62)
        label:SetJustifyH("LEFT")
        entries[index] = { label = label }
        local entry = entries[index]
        entry.highlight = box:CreateTexture(nil, "HIGHLIGHT")
        entry.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        entry.highlight:SetVertexColor(1, 0.65, 0.3)
        entry.highlight:SetBlendMode("ADD")
        entry.highlight:SetAlpha(0.4)
        entry.highlight:Hide()
    end
    self:Update()
end

--- Opens beside the cursor on key-down and performs the hovered name on key release.
function ErzbaroneUI.Emotes:HandleBinding(keystate)
    self:Initialize()
    if keystate == "down" then
        if held then
            return
        end
        held = true
        local x, y = GetCursorPosition()
        local scale = box:GetEffectiveScale()
        box:ClearAllPoints()
        box:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale + CURSOR_GAP, y / scale - CURSOR_GAP)
        box:Show()
        UpdateSelection()
    else
        local selected = held and box:IsShown() and GetSelection()
        held = false
        box:Hide()
        if selected then
            C_ChatInfo.PerformEmote(EMOTES[selected].token)
        end
    end
end

BINDING_HEADER_ERZBARONEUI = "ErzbaroneUI"
BINDING_NAME_ERZBARONEUI_EMOTE_WHEEL = "Emote Quick Selection (Hold)"
