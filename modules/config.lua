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
    compactMinimap = true,
}

--- Initializes the configuration settings for ErzbaroneUI.
function ErzbaroneUI.Config:Initialize()
    -- Ensure ErzbaroneUISettings is initialized
    ErzbaroneUISettings = ErzbaroneUISettings or {}
    for key, value in pairs(defaults) do
        if ErzbaroneUISettings[key] == nil then
            ErzbaroneUISettings[key] = value
        end
    end

    -- Flag module was removed; drop its stale saved setting
    ErzbaroneUISettings.showErzbaroneUIFlag = nil

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

--- Sets the font for damage text in the game.
function ErzbaroneUI.Config:SetDamageFont()
    DAMAGE_TEXT_FONT = "Fonts\\skurri.TTF"
    COMBAT_TEXT_FONT = "Fonts\\skurri.TTF"
    SetCVar("WorldTextScale", tostring(0.75))
end

--- Creates a checkbox bound to a boolean entry in ErzbaroneUISettings.
--- The optional onChange callback is invoked with the new value after the setting was updated.
local function CreateSettingCheckbox(parent, anchor, key, label, tooltip, onChange)
    local checkbox = CreateFrame("CheckButton", "ErzbaroneUISetting_" .. key, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)

    local text = checkbox.Text or _G[checkbox:GetName() .. "Text"]
    text:SetText(label)
    text:SetFontObject("GameFontHighlight")

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
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("A World of Warcraft Forever Interface Improvement")

    local generalHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    generalHeader:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -24)
    generalHeader:SetText("General")

    local autoSell = CreateSettingCheckbox(panel, generalHeader, "autoSellGreyItems", "Auto Sell Grey Items",
        "Automatically sells all grey (poor quality) items when visiting a merchant.")
    local autoRepair = CreateSettingCheckbox(panel, autoSell, "autoRepair", "Auto Repair Items",
        "Automatically repairs all items when visiting a merchant that can repair.")

    local visualsHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    visualsHeader:SetPoint("TOPLEFT", autoRepair, "BOTTOMLEFT", 0, -16)
    visualsHeader:SetText("Visuals")

    local vignette = CreateSettingCheckbox(panel, visualsHeader, "vignette", "Show Vignette Effect",
        "Darkens the edges of the screen with a vignette overlay.",
        function() ErzbaroneUI.Effects:UpdateVignette() end)

    local unitFramesHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    unitFramesHeader:SetPoint("TOPLEFT", vignette, "BOTTOMLEFT", 0, -16)
    unitFramesHeader:SetText("Unit Frames")

    local fiveSecondRule = CreateSettingCheckbox(panel, unitFramesHeader, "fiveSecondRuleTimer", "Show Five Second Rule Timer",
        "Shows a spark moving across your mana bar for 5 seconds after casting a spell that costs mana. Mana regeneration from Spirit resumes once it has passed.",
        function() ErzbaroneUI.FiveSecondRule:Update() end)

    local actionBarsHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    actionBarsHeader:SetPoint("TOPLEFT", fiveSecondRule, "BOTTOMLEFT", 0, -16)
    actionBarsHeader:SetText("Action Bars")

    local castCount = CreateSettingCheckbox(panel, actionBarsHeader, "castCount", "Show Cast Count",
        "Shows how often each mana spell can be cast with your current mana in the bottom left corner of its action button.",
        function() ErzbaroneUI.CastCount:Update() end)
    local rangeTint = CreateSettingCheckbox(panel, castCount, "rangeTint", "Tint Buttons Out of Range",
        "Tints the whole action button red while your target is out of range of that action.",
        function() ErzbaroneUI.RangeTint:Update() end)
    local fadeRightBars = CreateSettingCheckbox(panel, rangeTint, "fadeRightBars", "Show Right Bars on Mouseover",
        "Hides the vertical action bars on the right side of the screen until you move your mouse over them.",
        function() ErzbaroneUI.BarFade:Update() end)

    local chatHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    chatHeader:SetPoint("TOPLEFT", fadeRightBars, "BOTTOMLEFT", 0, -16)
    chatHeader:SetText("Chat")

    local hideChat = CreateSettingCheckbox(panel, chatHeader, "hideChatButtons", "Hide Chat Buttons",
        "Hides the button column left of the chat window (chat menu, channels, voice, quick join and text to speech).",
        function() ErzbaroneUI.Chat:Update() end)

    local minimapHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    minimapHeader:SetPoint("TOPLEFT", hideChat, "BOTTOMLEFT", 0, -16)
    minimapHeader:SetText("Minimap")

    CreateSettingCheckbox(panel, minimapHeader, "compactMinimap", "Compact Minimap",
        "Removes the header above the minimap, moves the minimap up and places tracking, calendar, mail and addon buttons on its border. The server time is shown inside the minimap and the zone name appears while hovering it.",
        function() ErzbaroneUI.Minimap:Update() end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    self.Category = category
    self.Panel = panel
end

--- Opens the ErzbaroneUI panel in the game's Options screen.
function ErzbaroneUI.Config:OpenSettings()
    Settings.OpenToCategory(self.Category:GetID())
end

