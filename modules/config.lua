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
    damageFont = "blizzard",
    damageTextScale = "blizzard",
}

--- Saved settings of removed features
local OBSOLETE_SETTINGS = {
    "showErzbaroneUIFlag",
    "raidStylePartyFrames",
    "editModeLayout",
    "layoutVersions",
    "classicDamageFont",
}

--- Initializes the configuration settings for ErzbaroneUI.
function ErzbaroneUI.Config:Initialize()
    -- Ensure ErzbaroneUISettings is initialized
    ErzbaroneUISettings = ErzbaroneUISettings or {}

    -- The classic damage font checkbox became a font dropdown
    if ErzbaroneUISettings.classicDamageFont == false and ErzbaroneUISettings.damageFont == nil then
        ErzbaroneUISettings.damageFont = "blizzard"
    end

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
    ErzbaroneUI.Config:SetDamageFont()
    if ErzbaroneUISettings.damageTextScale ~= "blizzard" then
        ErzbaroneUI.Config:UpdateDamageTextScale()
    end
end

local DAMAGE_FONTS = {
    { "blizzard", "Blizzard" },
    { "classic", "Classic (Skurri)", "Fonts\\skurri.ttf" },
    { "morpheus", "Morpheus", "Fonts\\MORPHEUS.ttf" },
    { "friz", "Friz Quadrata", "Fonts\\FRIZQT__.TTF" },
    { "arial", "Arial Narrow", "Fonts\\ARIALN.TTF" },
    { "custom", "Custom (fonts\\damage.ttf)", "Interface\\AddOns\\ErzbaroneUI\\fonts\\damage.ttf" },
}

local DAMAGE_TEXT_SCALES = {
    { "blizzard", "Blizzard" },
    { "0.65", "65%" },
    { "0.75", "75%" },
    { "0.85", "85%" },
    { "1", "100%" },
}

local WORLD_TEXT_SCALE_CVAR = "WorldTextScale"

function ErzbaroneUI.Config:GetDamageFontOptions()
    return DAMAGE_FONTS
end

function ErzbaroneUI.Config:GetDamageTextScaleOptions()
    return DAMAGE_TEXT_SCALES
end

--- Uses the selected font for the damage numbers above units.
--- The game only reads the font while logging in, so it has to be set while the addon loads.
function ErzbaroneUI.Config:SetDamageFont()
    for _, option in ipairs(DAMAGE_FONTS) do
        if option[1] == ErzbaroneUISettings.damageFont and option[3] then
            DAMAGE_TEXT_FONT = option[3]
        end
    end
end

--- Applies the damage number scale. Blizzard restores the game's default scale.
function ErzbaroneUI.Config:UpdateDamageTextScale()
    if not C_CVar or C_CVar.GetCVar(WORLD_TEXT_SCALE_CVAR) == nil then
        return
    end

    local scale = ErzbaroneUISettings.damageTextScale
    if scale == "blizzard" then
        scale = C_CVar.GetCVarDefault(WORLD_TEXT_SCALE_CVAR)
    end
    if scale and C_CVar.GetCVar(WORLD_TEXT_SCALE_CVAR) ~= scale then
        C_CVar.SetCVar(WORLD_TEXT_SCALE_CVAR, scale)
    end
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
            { "damageFont", "Damage Font",
                "Font of the damage numbers above your target. Takes effect after logging out to the character selection and back in. Custom uses fonts\\damage.ttf inside the addon folder.",
                function()
                    print("|cffffd100ErzbaroneUI:|r The damage font changes after logging out to the character selection and back in.")
                end,
                function() return ErzbaroneUI.Config:GetDamageFontOptions() end },
            { "damageTextScale", "Damage Text Scale",
                "Size of the damage numbers above your target. Smaller sizes keep fonts like Skurri sharper. Blizzard restores the game's default size.",
                function() ErzbaroneUI.Config:UpdateDamageTextScale() end,
                function() return ErzbaroneUI.Config:GetDamageTextScaleOptions() end },
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
}

--- Creates a compact checkbox bound to a boolean entry in ErzbaroneUISettings.
--- The optional onChange callback is invoked with the new value after the setting was updated.
local function CreateSettingCheckbox(parent, key, label, tooltip, onChange)
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

    checkbox:SetScript("OnShow", function(self)
        self:SetChecked(ErzbaroneUISettings[key])
    end)
    checkbox:SetScript("OnClick", function(self)
        ErzbaroneUISettings[key] = self:GetChecked() and true or false
        if onChange then
            onChange(ErzbaroneUISettings[key])
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

    checkbox:SetChecked(ErzbaroneUISettings[key])
    return checkbox
end

--- Creates a labeled dropdown bound to a string entry in ErzbaroneUISettings.
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

    for _, section in ipairs(SECTIONS) do
        local column = columnAnchors[section.column]
        local isFirst = column.frame == subtitle
        local anchor = CreateSectionHeader(panel, column.frame, isFirst and column.x or 0,
            isFirst and -18 or -SECTION_GAP, section.title)

        local previous = anchor
        for index, setting in ipairs(section.settings) do
            local control
            if setting[5] then
                control = CreateSettingDropdown(panel, setting[1], setting[2], setting[3], setting[4], setting[5])
            else
                control = CreateSettingCheckbox(panel, setting[1], setting[2], setting[3], setting[4])
            end
            control:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, index == 1 and -4 or 0)
            previous = control
        end

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

