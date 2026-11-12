if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Config = {}

local defaults = {
    autoSellGreyItems = true,
    autoRepair = true,
    vignette = false,
    fiveSecondRuleTimer = true,
    castCount = true,
    rangeTint = true,
    fadeRightBars = true,
    compactMainBar = false,
    microMenuPosition = "bottomLeft",
    hideChatButtons = true,
    chatToCorner = true,
    fadeChatTabs = true,
    compactMinimap = true,
    fadeMinimapButtons = true,
    unitFrameTexture = "classic",
    castBarTexture = "classic",
    swingTimer = false,
    unitClassColors = true,
    hideBagNames = true,
    hideThreatGlow = false,
    emoteFontSize = 12,
}

--- Saved settings of removed features
local OBSOLETE_SETTINGS = {
    "showErzbaroneUIFlag",
    "raidStylePartyFrames",
    "editModeLayout",
    "layoutVersions",
    "classicDamageFont",
    "damageFont",
    "damageTextScale",
}

local WORLD_TEXT_SCALE_CVAR = "WorldTextScale"

--- The removed damage text scale option changed a game setting that outlives the addon, so it is reset once.
local function ResetDamageTextScale()
    local scale = ErzbaroneUISettings.damageTextScale
    if scale == nil or scale == "blizzard" or not C_CVar or C_CVar.GetCVar(WORLD_TEXT_SCALE_CVAR) == nil then
        return
    end
    local default = C_CVar.GetCVarDefault(WORLD_TEXT_SCALE_CVAR)
    if default then
        C_CVar.SetCVar(WORLD_TEXT_SCALE_CVAR, default)
    end
end

--- Initializes the configuration settings for ErzbaroneUI.
function ErzbaroneUI.Config:Initialize()
    -- Ensure ErzbaroneUISettings is initialized
    ErzbaroneUISettings = ErzbaroneUISettings or {}

    ResetDamageTextScale()

    for key, value in pairs(defaults) do
        if ErzbaroneUISettings[key] == nil then
            ErzbaroneUISettings[key] = value
        end
    end

    for _, key in ipairs(OBSOLETE_SETTINGS) do
        ErzbaroneUISettings[key] = nil
    end

    ErzbaroneUI.Config:Setup()
    ErzbaroneUI.Config:RegisterSettingsPanel()
end

--- Reloads the UI to apply changes made in the configuration.
function ErzbaroneUI.Config:Reload()
    ReloadUI()
end

--- Sets up the initial configuration for ErzbaroneUI.
function ErzbaroneUI.Config:Setup()
    TARGET_FRAME_BUFFS_ON_TOP = true
    SetCVar("cameraDistanceMaxZoomFactor", "4.0")
end

local COLUMN_WIDTH = 300
local COLUMN_GAP = 20
local ROW_HEIGHT = 26
local SECTION_GAP = 14

--- Settings grouped into sections, each placed in one of two columns.
local SECTIONS = {
    {
        column = 1,
        title = "General",
        settings = {
            { "autoSellGreyItems", "Auto Sell Grey Items",
                "Automatically sells all grey (poor quality) items when visiting a merchant." },
            { "autoRepair", "Auto Repair Items",
                "Automatically repairs all items when visiting a merchant that can repair." },
        },
    },
    {
        column = 1,
        title = "Visuals",
        settings = {
            { "vignette", "Show Vignette Effect",
                "Darkens the edges of the screen with a vignette overlay.",
                function() ErzbaroneUI.Effects:UpdateVignette() end },
        },
    },
    {
        column = 1,
        title = "Unit Frames",
        settings = {
            { "fiveSecondRuleTimer", "Five Second Rule Timer",
                "Shows a spark moving across your mana bar for 5 seconds after casting a spell that costs mana. Mana regeneration from Spirit resumes once it has passed.",
                function() ErzbaroneUI.FiveSecondRule:Update() end },
            { "swingTimer", "Swing Timer",
                "Shows a spark moving across your power bar for the duration of each main hand or ranged swing (Auto Shot, wands), like the five second rule timer. Meant for melee and ranged fighters.",
                function() ErzbaroneUI.SwingTimer:Update() end },
            { "unitClassColors", "Class Colored Health Bars",
                "Colors the health bars of players in the player, target, focus and party frames by their class. Creatures tapped by someone else get a grey health bar.",
                function() ErzbaroneUI.StatusBars:Update() end },
            { "hideThreatGlow", "Hide Threat Glow",
                "Hides the large red glow around the player, target and focus frames that shows while a creature is attacking you. The combat pulse on the player portrait and the attack icon stay visible.",
                function() ErzbaroneUI.ThreatGlow:Update() end },
            { "unitFrameTexture", "Bar Texture",
                "Replaces the flat health and power bar textures of the player, target, focus, pet and party frames. Custom uses textures\\statusbar.tga or .blp inside the addon folder.",
                function() ErzbaroneUI.StatusBars:Update() end,
                function() return ErzbaroneUI.StatusBars:GetTextureOptions() end },
            { "castBarTexture", "Cast Bar Texture",
                "Replaces the texture of the player, pet, target and focus cast bars and colors them like the classic cast bars. Applies from the next cast on. Casts of other units that the game keeps hidden from addons keep Blizzard's look.",
                function() ErzbaroneUI.CastBars:Update() end,
                function() return ErzbaroneUI.StatusBars:GetTextureOptions() end },
        },
    },
    {
        column = 1,
        title = "Chat",
        settings = {
            { "hideChatButtons", "Hide Chat Buttons",
                "Hides the button column left of the chat window (chat menu, channels, voice, quick join and text to speech).",
                function() ErzbaroneUI.Chat:Update() end },
            { "chatToCorner", "Move Chat to Corner",
                "Moves the chat window into the lower left corner of the screen. Only applies while the chat is in its default Edit Mode position, so a position you set in Edit Mode is kept.",
                function() ErzbaroneUI.Chat:UpdatePosition() end },
            { "fadeChatTabs", "Fade Chat Tabs",
                "Hides the chat tabs until the mouse is over the chat window. Tabs with new messages stay visible. To show the input box only while typing, set Options > Social > Chat Style to Classic.",
                function() ErzbaroneUI.Chat:UpdateTabs() end },
        },
    },
    {
        column = 2,
        title = "Action Bars",
        settings = {
            { "compactMainBar", "Improved Layout (Experimental)",
                "Disabled by default. Uses custom secure action bars, arranges the status bars and positions the menu at runtime. Does not create, select or save Edit Mode profiles, or change chat, buffs or unit-frame settings. Disabling restores the native bars. Changes wait until combat ends.",
                function() ErzbaroneUI.MainBar:Update() end },
            { "microMenuPosition", "Micro Menu Position",
                "Places the micro menu left of the bags (the previous experimental layout position), left of the gryphons to leave the screen corner available for chat, or above the bags. Only applies while Improved Layout (Experimental) is enabled. Changes wait until combat ends.",
                function() ErzbaroneUI.MainBar:Update() end,
                function() return ErzbaroneUI.MainBar:GetMicroMenuPositionOptions() end },
            { "castCount", "Show Cast Count",
                "Shows how often each mana spell can be cast with your current mana in the bottom left corner of its action button.",
                function() ErzbaroneUI.CastCount:Update() end },
            { "rangeTint", "Tint Buttons Out of Range",
                "Tints the whole action button red while your target is out of range of that action.",
                function() ErzbaroneUI.RangeTint:Update() end },
            { "fadeRightBars", "Show Right Bars on Mouseover",
                "Hides the vertical action bars on the right side of the screen until you move your mouse over them.",
                function() ErzbaroneUI.BarFade:Update() end },
        },
    },
    {
        column = 2,
        title = "Emotes",
        settings = {
            { "emoteKeybinding", "Keybinding",
                "Shows the current Emote Quick Selection binding. Click to open WoW's Keybindings settings, then find ErzbaroneUI under AddOns.",
                kind = "emoteBinding" },
            { "emoteFontSize", "Font Size",
                "Changes the emote names' font size. The box and hover rows resize immediately to fit.",
                function() ErzbaroneUI.Emotes:Update() end,
                function() return ErzbaroneUI.Emotes:GetFontSizeOptions() end },
        },
    },
    {
        column = 2,
        title = "Bags",
        settings = {
            { "hideBagNames", "Hide Bag Names",
                "Hides the bag name in the title bar of each bag window.",
                function() ErzbaroneUI.Bags:Update() end },
        },
    },
    {
        column = 2,
        title = "Minimap",
        settings = {
            { "compactMinimap", "Compact Minimap",
                "Removes the header above the minimap, moves the minimap up and places tracking, calendar, mail and addon buttons on its border. The server time is shown inside the minimap and the zone name appears while hovering it.",
                function() ErzbaroneUI.Minimap:Update() end },
            { "fadeMinimapButtons", "Show Buttons on Mouseover",
                "Hides the tracking, calendar and addon buttons until you move your mouse over the minimap. The calendar stays visible while you have pending invites.",
                function() ErzbaroneUI.Minimap:Update() end },
        },
    },
    {
        column = 2,
        title = "HDR",
        settings = {
            { "HDROutput", "Enable HDR Output",
                "Off by default in WoW. Enables HDR output when supported by the monitor and render settings. The addon cannot detect whether HDR is available on your system.",
                kind = "hdrCheckbox" },
            { "HDRFactor", "HDR Factor",
                "Adjusts how far HDR lighting can exceed SDR lighting. The slider covers 1.0 to 2.0; the game also clamps brightness to the monitor's peak.",
                kind = "hdrSlider" },
        },
    },
}

--- Creates a compact checkbox bound to a boolean entry in ErzbaroneUISettings.
--- The optional onChange callback is invoked with the new value after the setting was updated.
local function CreateSettingCheckbox(parent, key, label, tooltip, onChange, readValue, writeValue)
    local checkbox = CreateFrame("CheckButton", "ErzbaroneUISetting_" .. key, parent, "UICheckButtonTemplate")
    checkbox:SetSize(ROW_HEIGHT, ROW_HEIGHT)
    checkbox:SetHitRectInsets(0, -(COLUMN_WIDTH - ROW_HEIGHT), 0, 0)

    local text = checkbox.Text or _G[checkbox:GetName() .. "Text"]
    text:SetFontObject("GameFontHighlight")
    text:ClearAllPoints()
    text:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
    text:SetWidth(COLUMN_WIDTH - ROW_HEIGHT - 4)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    text:SetText(label)

    local function Refresh(self)
        local value
        if readValue then
            value = readValue()
        else
            value = ErzbaroneUISettings[key]
        end
        self:SetChecked(value)
        if readValue then
            if value == nil then
                text:SetText(label .. " (unavailable)")
                self:Disable()
            else
                text:SetText(label)
                self:Enable()
            end
        end
    end
    checkbox.Refresh = Refresh
    checkbox:SetScript("OnShow", Refresh)
    checkbox:SetScript("OnClick", function(self)
        local value = self:GetChecked() and true or false
        if writeValue then
            writeValue(value)
            Refresh(self)
        else
            ErzbaroneUISettings[key] = value
            if onChange then
                onChange(value)
            end
        end
    end)

    if tooltip then
        checkbox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine(tooltip, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        checkbox:SetScript("OnLeave", GameTooltip_Hide)
    end

    Refresh(checkbox)
    return checkbox
end

local function SetHDRCVar(name, value)
    if not C_CVar.SetCVar(name, value) then
        print("ErzbaroneUI: Could not change " .. name .. ".")
    end
end

local function ReadHDROutput()
    local value = C_CVar.GetCVar("HDROutput")
    if value == "1" then return true end
    if value == "0" then return false end
    return nil
end

--- Creates a slider that displays the actual CVar even when it is outside the slider range.
local function CreateHDRSlider(parent, label, tooltip)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(COLUMN_WIDTH, 44)
    local text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOPLEFT", row, "TOPLEFT", 4, 0)
    text:SetText(label)
    local valueText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    valueText:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, 0)

    local slider = CreateFrame("Slider", "ErzbaroneUIHDRFactorSlider", row, "UISliderTemplate")
    slider:SetSize(COLUMN_WIDTH - 18, 17)
    slider:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 9, 2)
    slider:SetMinMaxValues(1, 2)
    slider:SetValueStep(0.01)
    slider:SetObeyStepOnDrag(true)

    local refreshing = false
    local function Refresh()
        local value = tonumber(C_CVar.GetCVar("HDRFactor"))
        if not value then
            slider:Disable()
            valueText:SetText("Unavailable")
            return
        end
        slider:Enable()
        valueText:SetText(string.format("%g%s", value, (value < 1 or value > 2) and " (outside 1-2)" or ""))
        refreshing = true
        slider:SetValue(math.max(1, math.min(2, value)))
        refreshing = false
    end
    row.Refresh = Refresh
    row:SetScript("OnShow", Refresh)
    slider:SetScript("OnValueChanged", function(_, value)
        if not refreshing then
            SetHDRCVar("HDRFactor", string.format("%.2f", value))
            Refresh()
        end
    end)
    slider:SetScript("OnMouseUp", function(self)
        local value = tonumber(C_CVar.GetCVar("HDRFactor"))
        if value and (value < 1 or value > 2) then
            SetHDRCVar("HDRFactor", string.format("%.2f", self:GetValue()))
            Refresh()
        end
    end)
    slider:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(label, 1, 1, 1)
        GameTooltip:AddLine(tooltip, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    slider:SetScript("OnLeave", GameTooltip_Hide)
    Refresh()
    return row
end

--- Creates a labeled dropdown bound to a string or numeric entry in ErzbaroneUISettings.
--- getOptions returns a list of { value, label } pairs.
local function CreateSettingDropdown(parent, key, label, tooltip, onChange, getOptions)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(COLUMN_WIDTH, ROW_HEIGHT + 4)

    local text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("LEFT", row, "LEFT", 4, 0)
    text:SetText(label)

    local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    dropdown:SetWidth(170)
    dropdown:SetupMenu(function(_, rootDescription)
        for _, option in ipairs(getOptions()) do
            local value = option[1]
            rootDescription:CreateRadio(option[2], function()
                return ErzbaroneUISettings[key] == value
            end, function()
                ErzbaroneUISettings[key] = value
                if onChange then
                    onChange(value)
                end
            end)
        end
    end)

    if tooltip then
        --- Displays this setting's label and explanatory tooltip.
        local function ShowTooltip(owner)
            GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine(tooltip, nil, nil, nil, true)
            GameTooltip:Show()
        end
        row:SetScript("OnEnter", ShowTooltip)
        row:SetScript("OnLeave", GameTooltip_Hide)
        dropdown:HookScript("OnEnter", ShowTooltip)
        dropdown:HookScript("OnLeave", GameTooltip_Hide)
    end

    row:SetScript("OnShow", function()
        dropdown:GenerateMenu()
    end)
    return row
end

--- Shows the current emote binding and opens the game's native keybinding settings.
local function CreateEmoteBindingButton(parent, label, tooltip)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(COLUMN_WIDTH, ROW_HEIGHT + 4)
    local text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("LEFT", row, "LEFT", 4, 0)
    text:SetText(label)

    local button = CreateFrame("Button", "ErzbaroneUIEmoteKeybinding", row, "UIPanelButtonTemplate")
    button:SetSize(170, 22)
    button:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    local function Refresh()
        local labels = {}
        for _, key in ipairs({ GetBindingKey("ERZBARONEUI_EMOTE_WHEEL") }) do
            labels[#labels + 1] = GetBindingText(key)
        end
        button:SetText(#labels > 0 and table.concat(labels, " / ") or "Not bound")
    end
    row:RegisterEvent("UPDATE_BINDINGS")
    row:SetScript("OnEvent", Refresh)
    row:SetScript("OnShow", Refresh)
    button:SetScript("OnClick", function()
        if not Settings.KEYBINDINGS_CATEGORY_ID then
            print("ErzbaroneUI: WoW's Keybindings settings are not ready.")
            return
        end
        Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(label, 1, 1, 1)
        GameTooltip:AddLine(tooltip, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    Refresh()
    return row
end

--- Creates a section header with a divider line below it and returns the divider as anchor.
local function CreateSectionHeader(parent, anchor, offsetX, offsetY, title)
    local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", offsetX, offsetY)
    header:SetText(title)

    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(1, 1, 1, 0.15)
    divider:SetSize(COLUMN_WIDTH, 1)
    divider:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    return divider
end

--- Registers the ErzbaroneUI panel in the game's Options -> AddOns screen.
function ErzbaroneUI.Config:RegisterSettingsPanel()
    if self.Panel then
        return
    end

    local panel = CreateFrame("Frame", "ErzbaroneUISettingsPanel")
    panel.name = "ErzbaroneUI"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Erzbarone UI")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetText("A World of Warcraft Forever Interface Improvement. Hover a setting for details.")

    -- Each column starts below the subtitle and stacks its sections downwards
    local columnAnchors = {
        { frame = subtitle, x = 0 },
        { frame = subtitle, x = COLUMN_WIDTH + COLUMN_GAP },
    }
    local hdrControls = {}

    for _, section in ipairs(SECTIONS) do
        local column = columnAnchors[section.column]
        local isFirst = column.frame == subtitle
        local anchor = CreateSectionHeader(panel, column.frame, isFirst and column.x or 0,
            isFirst and -18 or -SECTION_GAP, section.title)

        local previous = anchor
        for index, setting in ipairs(section.settings) do
            local control
            if setting.kind == "hdrCheckbox" then
                control = CreateSettingCheckbox(panel, setting[1], setting[2], setting[3], nil,
                    ReadHDROutput, function(value) SetHDRCVar("HDROutput", value and "1" or "0") end)
                hdrControls.hdroutput = control
            elseif setting.kind == "hdrSlider" then
                control = CreateHDRSlider(panel, setting[2], setting[3])
                hdrControls.hdrfactor = control
            elseif setting.kind == "emoteBinding" then
                control = CreateEmoteBindingButton(panel, setting[2], setting[3])
            elseif setting[5] then
                control = CreateSettingDropdown(panel, setting[1], setting[2], setting[3], setting[4], setting[5])
            else
                control = CreateSettingCheckbox(panel, setting[1], setting[2], setting[3], setting[4])
            end
            control:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, index == 1 and -4 or 0)
            previous = control
        end

        panel:RegisterEvent("CVAR_UPDATE")
        panel:SetScript("OnEvent", function(_, _, name)
            local control = name and hdrControls[name:lower()]
            if control then
                control:Refresh()
            end
        end)

        column.frame = previous
        column.x = 0
    end

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    self.Category = category
    self.Panel = panel
end

--- Opens the ErzbaroneUI panel in the game's Options screen.
function ErzbaroneUI.Config:OpenSettings()
    Settings.OpenToCategory(self.Category:GetID())
end

function ErzbaroneUI_OnAddonCompartmentClick()
    ErzbaroneUI.Config:OpenSettings()
end
