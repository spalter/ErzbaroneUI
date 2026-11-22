if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.NeutralPanels = {}

local panelNames = {
    "CharacterFrame", "AuctionHouseFrame", "CollectionsJournal", "FriendsFrame",
    "PlayerSpellsFrame", "MerchantFrame", "QuestFrame", "MailFrame", "OpenMailFrame",
    "EncounterJournal", "ProfessionsFrame", "BankFrame", "ContainerFrameCombinedBags",
    "ContainerFrame1", "ContainerFrame2", "ContainerFrame3", "ContainerFrame4",
    "ContainerFrame5", "ContainerFrame6", "ContainerFrame7",
}
local slicePieces = {
    "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
    "TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
}
local slices = {}
local hookedPanels = {}
local hookedButtons = {}
local buttonAtlases = {
    ["redbutton-exit"] = true,
    ["redbutton-exit-disabled"] = true,
    ["redbutton-exit-pressed"] = true,
    ["redbutton-expand"] = true,
    ["redbutton-expand-pressed"] = true,
    ["redbutton-expand-disabled"] = true,
    ["redbutton-condense"] = true,
    ["redbutton-condense-pressed"] = true,
    ["redbutton-condense-disabled"] = true,
    ["redbutton-highlight"] = true,
}
local buttonTextures = { "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture" }

--- Desaturates a decorative texture and applies the shared NeutralArt tint.
local function Desaturate(texture)
    if texture and texture.SetDesaturated then
        texture:SetDesaturated(true)
        ErzbaroneUI.NeutralArt:ApplyTint(texture)
    end
end

--- Themes and tracks a NineSlice border so Blizzard layout rebuilds can be retinted.
local function ApplySlice(slice)
    if not slice then
        return
    end
    slices[slice] = true
    for _, key in ipairs(slicePieces) do
        Desaturate(slice[key])
    end
end

--- Themes an inset's border and background when present.
local function ApplyInset(inset)
    if inset then
        ApplySlice(inset.NineSlice)
        Desaturate(inset.Bg)
    end
end

--- Themes supported close and resize button states, excluding unrelated replacement atlases.
--- Refreshes on show so newly assigned button textures are included.
local function ApplyButton(button)
    if not button then
        return
    end
    for _, getter in ipairs(buttonTextures) do
        if button[getter] then
            local texture = button[getter](button)
            local atlas = texture and texture.GetAtlas and texture:GetAtlas()
            if type(atlas) == "string" and buttonAtlases[atlas:lower()] then
                Desaturate(texture)
            end
        end
    end
    if not hookedButtons[button] then
        hookedButtons[button] = true
        button:HookScript("OnShow", ApplyButton)
    end
end

--- Themes the maximize and minimize buttons on a supported panel.
local function ApplyResizeButtons(frame)
    if frame then
        ApplyButton(frame.MaximizeButton)
        ApplyButton(frame.MinimizeButton)
    end
end

--- Tints regions matching the lowercase atlas name using the shared NeutralArt tint.
--- Blizzard leaves these decorations unnamed, so matching their atlas avoids changing icons or other artwork.
local function ApplyAtlas(frame, expected)
    if not frame or not frame.GetRegions then
        return
    end
    for _, region in ipairs({ frame:GetRegions() }) do
        local atlas = region.GetAtlas and region:GetAtlas()
        if type(atlas) == "string" and atlas:lower() == expected then
            Desaturate(region)
        end
    end
end

--- Tints the character pane divider and equipment-slot borders, which are outside the panel's NineSlice.
--- Uses Blizzard's RightPaneHost, PaperDollItemsFrame slot arrays and CharacterAmmoSlot when available.
--- Called during panel refresh and OnShow so late-loaded character artwork is included.
local function ApplyCharacterArtwork(panel)
    local host = panel.RightPaneHost
    if host and host.GetChildren then
        for _, child in ipairs({ host:GetChildren() }) do
            ApplyAtlas(child, "common-framedivider")
        end
    end
    if PaperDollItemsFrame then
        for _, key in ipairs({ "EquipmentSlots", "WeaponSlots" }) do
            for _, slot in ipairs(PaperDollItemsFrame[key] or {}) do
                ApplyAtlas(slot.BorderFrame, "ui-character-info-gearslot")
            end
        end
    end
    ApplyAtlas(CharacterAmmoSlot, "ui-character-info-gearslotsmall")
end

--- Themes a supported panel's decorative artwork and character-specific borders.
local function ApplyPanel(panel)
    if not panel then
        return
    end
    ApplySlice(panel.NineSlice)
    ApplyInset(panel.Inset)
    ApplyInset(panel.InsetRight)
    Desaturate(panel.Bg)
    Desaturate(panel.TopTileStreaks)
    Desaturate(panel.InsetBorderTop)
    ApplyButton(panel.CloseButton)
    ApplyResizeButtons(panel.MaximizeMinimizeFrame)
    ApplyResizeButtons(panel.MaxMinButtonFrame)
    if panel == CharacterFrame then
        ApplyCharacterArtwork(panel)
    end
end

--- Applies the theme and hooks panel shows once to refresh rebuilt artwork.
local function RegisterPanel(panel)
    if not panel then
        return
    end
    ApplyPanel(panel)
    if not hookedPanels[panel] then
        hookedPanels[panel] = true
        panel:HookScript("OnShow", ApplyPanel)
    end
end

--- Finds supported Blizzard panels after addon loading, including character and map artwork.
local function RefreshPanels()
    for _, name in ipairs(panelNames) do
        RegisterPanel(_G[name])
    end
    if CharacterFrame then
        Desaturate(CharacterFrame.Background)
    end
    if WorldMapFrame then
        RegisterPanel(WorldMapFrame.BorderFrame)
    end
end

--- Enables panel theming for the reload-latched setting and follows NineSlice and addon loading.
--- Depends on Blizzard's NineSliceUtil and the shared NeutralArt module.
function ErzbaroneUI.NeutralPanels:Initialize()
    if self.Initialized then
        return
    end
    self.Initialized = true
    if not ErzbaroneUISettings.neutralDecorations then
        return
    end

    hooksecurefunc(NineSliceUtil, "ApplyLayout", function(slice)
        if slices[slice] then
            ApplySlice(slice)
        end
    end)

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:SetScript("OnEvent", RefreshPanels)
    RefreshPanels()
end
