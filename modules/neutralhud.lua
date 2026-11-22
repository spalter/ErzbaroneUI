ErzbaroneUI = ErzbaroneUI or {}
ErzbaroneUI.NeutralHUD = {}

-- Only atlases used by Forever's decorative textures are eligible; in particular,
-- a replacement texture supplied by another addon must not inherit the effect.
local atlases = {}
--- Builds a case-insensitive allowlist for a specific category of Blizzard artwork.
local function AddAtlases(group, names)
    local allowed = {}
    atlases[group] = allowed
    for _, name in ipairs(names) do
        allowed[name:lower()] = true
    end
end
AddAtlases("player", {
    "UI-HUD-UnitFrame-Player-PortraitOn",
    "UI-HUD-UnitFrame-Player-PortraitOn-Vehicle",
    "UI-HUD-UnitFrame-Player-PortraitOn-ClassResource",
})
AddAtlases("target", {
    "UI-HUD-UnitFrame-Target-PortraitOn",
    "UI-HUD-UnitFrame-Target-Rare-PortraitOn",
    "UI-HUD-UnitFrame-Target-MinusMob-PortraitOn",
    "UI-HUD-UnitFrame-Target-Boss-Small-PortraitOff",
})
AddAtlases("boss", {
    "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold",
    "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold-Winged",
    "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver-Winged",
})
AddAtlases("small", { "UI-HUD-UnitFrame-TargetofTarget-PortraitOn" })
AddAtlases("party", {
    "UI-HUD-UnitFrame-Party-PortraitOn",
    "UI-HUD-UnitFrame-Party-PortraitOn-Vehicle",
    "UI-HUD-UnitFrame-CharacterFrameOnParty-PortraitOn",
})
AddAtlases("actionbar", { "UI-HUD-ActionBar-Frame", "UI-HUD-ActionBar-IconFrame-Background" })
AddAtlases("leftcap", { "UI-HUD-ActionBar-Gryphon-Left", "UI-HUD-ActionBar-Wyvern-Left" })
AddAtlases("rightcap", { "UI-HUD-ActionBar-Gryphon-Right", "UI-HUD-ActionBar-Wyvern-Right" })
AddAtlases("minimap", { "UI-HUD-Minimap-Frame" })
AddAtlases("minimapUnderlay", { "UI-HUD-Minimap-Frame-Circle" })
AddAtlases("dielBackground", { "UI-HUD-Minimap-DayCycle", "UI-HUD-Minimap-NightCycle" })
AddAtlases("dielBorder", { "UI-HUD-Minimap-Frame-Cycle" })
AddAtlases("microBackground", { "UI-HUD-MicroMenu-ButtonBG-Up", "UI-HUD-MicroMenu-ButtonBG-Down" })
local microAtlases = {}
for _, name in ipairs({
    "Professions", "SpellbookAbilities", "SpecTalents", "Achievements", "Legacy", "Questlog",
    "Housing", "GuildCommunities", "GuildCommunities-GuildColor", "Groupfinder", "Collections",
    "AdventureGuide", "Shop", "GameMenu",
}) do
    for _, suffix in ipairs({ "Up", "Down", "Disabled", "Mouseover" }) do
        microAtlases[#microAtlases + 1] = "UI-HUD-MicroMenu-" .. name .. "-" .. suffix
    end
end
AddAtlases("microIcon", microAtlases)
AddAtlases("bagBorder", {
    "UI-HUD-ActionBar-IconFrame-Bags", "UI-HUD-ActionBar-IconFrame",
    "UI-HUD-ActionBar-IconFrame-Small", "bag-border", "bag-border-empty",
    "bag-main", "bag-reagent-border", "bag-reagent-border-empty",
})
AddAtlases("backpackIcon", {})
local BACKPACK_ICON = "Interface\\Icons\\ui-hud-actionbar-bag"
local backpackIconID
local warnedBackpackIcon = false
local microButtons = {
    "CharacterMicroButton", "ProfessionMicroButton", "PlayerSpellsMicroButton", "SpellbookMicroButton",
    "TalentMicroButton", "AchievementMicroButton", "LegacyMicroButton", "QuestLogMicroButton",
    "HousingMicroButton", "GuildMicroButton", "LFDMicroButton", "CollectionsMicroButton",
    "EJMicroButton", "HelpMicroButton", "StoreMicroButton", "MainMenuMicroButton",
}
local bagButtons = {
    "MainMenuBarBackpackButton", "CharacterBag0Slot", "CharacterBag1Slot",
    "CharacterBag2Slot", "CharacterBag3Slot", "CharacterReagentBag0Slot", "KeyRingButton",
}

local textures = setmetatable({}, { __mode = "k" })
local hookedOwners = setmetatable({}, { __mode = "k" })
local pendingBackgrounds = {}
local enabled = false
local pending = false
local scanning = false

--- Checks Blizzard's combat lockdown before installing hooks or changing HUD artwork.
local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

--- Applies the shared neutral tint to eligible artwork and restores replaced artwork.
--- Defers writes during combat and uses the saved native saturation and NeutralArt color state.
local function RefreshTexture(texture, state)
    if InCombat() then
        pending = true
        return
    end
    local atlas = texture:GetAtlas()
    local eligible = type(atlas) == "string" and state.allowed[atlas:lower()]
    if state.fileID then
        local file = texture:GetTexture()
        eligible = file == state.fileID or (type(file) == "string" and file:lower() == BACKPACK_ICON:lower())
    end
    if eligible then
        if not state.active then
            state.original = texture:IsDesaturated()
            state.active = true
        end
        if not texture:IsDesaturated() then
            state.writing = true
            texture:SetDesaturated(true)
            state.writing = false
        end
        state.writing = true
        ErzbaroneUI.NeutralArt:ApplyTint(texture)
        state.writing = false
    elseif state.active then
        state.active = false
        state.writing = true
        ErzbaroneUI.NeutralArt:RestoreTint(texture)
        state.writing = false
        if texture:IsDesaturated() ~= state.original then
            state.writing = true
            texture:SetDesaturated(state.original)
            state.writing = false
        end
    end
end

--- Watches a texture's native artwork and color changes so its group remains correctly themed.
--- The write guard prevents hooks from re-entering while RefreshTexture applies the theme.
local function WatchTexture(texture, group)
    if not texture or not texture.GetAtlas or not texture.IsDesaturated or not texture.SetDesaturated then
        return
    end
    local state = textures[texture]
    if not state then
        state = { allowed = atlases[group], fileID = group == "backpackIcon" and backpackIconID or nil }
        textures[texture] = state
        --- Re-evaluates artwork changed outside this module.
        local function Changed()
            if not state.writing then
                RefreshTexture(texture, state)
            end
        end
        if texture.SetAtlas then
            hooksecurefunc(texture, "SetAtlas", Changed)
        end
        if texture.SetTexture then
            hooksecurefunc(texture, "SetTexture", Changed)
        end
        hooksecurefunc(texture, "SetDesaturated", function(_, value)
            if not state.writing then
                if state.active then
                    state.original = not not value
                end
                RefreshTexture(texture, state)
            end
        end)
        hooksecurefunc(texture, "SetVertexColor", Changed)
    end
    RefreshTexture(texture, state)
end

local Scan
--- Hooks an owner's update method once, refreshing its artwork or rescanning the HUD.
local function WatchOwner(owner, method, callback)
    if not owner or type(owner[method]) ~= "function" then
        return
    end
    local methods = hookedOwners[owner]
    if not methods then
        methods = {}
        hookedOwners[owner] = methods
    end
    if not methods[method] then
        methods[method] = true
        hooksecurefunc(owner, method, function()
            if callback then
                callback(owner)
            else
                Scan()
            end
        end)
    end
end

--- Registers an available button-state texture with its artwork allowlist.
local function WatchButtonTexture(button, getter, group)
    if type(button[getter]) == "function" then
        WatchTexture(button[getter](button), group)
    end
end

--- Tracks micro-button backgrounds and state textures without recoloring alert overlays.
local function WatchMicroButton(button)
    if InCombat() then
        pending = true
        return
    end
    WatchTexture(button.Background, "microBackground")
    WatchTexture(button.PushedBackground, "microBackground")
    for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture" }) do
        WatchButtonTexture(button, getter, "microIcon")
    end
    WatchOwner(button, "UpdateMicroButton", WatchMicroButton)
end

--- Tracks bag-slot borders and the native backpack icon without recoloring equipped bag icons.
--- Resolves the backpack file ID through Blizzard's API and retries if it is unavailable.
local function WatchBagButton(button)
    if InCombat() then
        pending = true
        return
    end
    WatchButtonTexture(button, "GetNormalTexture", "bagBorder")
    WatchButtonTexture(button, "GetPushedTexture", "bagBorder")
    if button == MainMenuBarBackpackButton and button.bagIcon == BACKPACK_ICON and button.icon then
        if not backpackIconID then
            backpackIconID = GetFileIDFromPath and GetFileIDFromPath(BACKPACK_ICON .. ".blp")
            if not backpackIconID or backpackIconID == 0 then
                if not warnedBackpackIcon then
                    warnedBackpackIcon = true
                    print("ErzbaroneUI: Could not identify the backpack artwork for the neutral theme.")
                end
                backpackIconID = nil
            end
        end
        if backpackIconID then WatchTexture(button.icon, "backpackIcon") end
    end
    WatchOwner(button, "UpdateTextures", WatchBagButton)
end

--- Tracks target-style borders and rescans when Blizzard creates a target-of-target frame.
local function WatchTarget(frame)
    if not frame then return end
    local container = frame.TargetFrameContainer
    if container then
        WatchTexture(container.FrameTexture, "target")
        WatchTexture(container.BossPortraitFrameTexture, "boss")
    end
    if frame.totFrame then
        WatchTexture(frame.totFrame.FrameTexture, "small")
    end
    WatchOwner(frame, "CreateTargetofTarget")
end

--- Tracks a party member's frame, vehicle and pet borders without touching its icons.
local function WatchPartyMember(member)
    if not member then return end
    WatchTexture(member.Texture, "party")
    WatchTexture(member.VehicleTexture, "party")
    WatchTexture(member.PetFrame and member.PetFrame.Texture, "party")
end

--- Finds supported HUD artwork, including late-created frames, and refreshes tracked textures.
--- Defers the scan during combat and prevents recursive scans from owner hooks.
Scan = function()
    if InCombat() then
        pending = true
        return
    end
    if scanning then return end
    scanning = true
    pending = false
    for texture in pairs(pendingBackgrounds) do
        WatchTexture(texture, "actionbar")
        pendingBackgrounds[texture] = nil
    end

    local player = PlayerFrame and PlayerFrame.PlayerFrameContainer
    if player then
        WatchTexture(player.FrameTexture, "player")
        WatchTexture(player.VehicleFrameTexture, "player")
        WatchTexture(player.AlternatePowerFrameTexture, "player")
    end
    WatchTexture(PetFrameTexture, "small")
    WatchTarget(TargetFrame)
    WatchTarget(FocusFrame)
    for i = 1, 5 do
        WatchTarget(_G["Boss" .. i .. "TargetFrame"])
    end

    if PartyFrame then
        WatchOwner(PartyFrame, "InitializePartyMemberFrames")
        for i = 1, 4 do
            WatchPartyMember(PartyFrame["MemberFrame" .. i])
        end
        local pool = PartyFrame.PartyMemberFramePool
        if pool and pool.EnumerateActive then
            for member in pool:EnumerateActive() do
                WatchPartyMember(member)
            end
        end
    end

    if MainActionBar then
        WatchTexture(MainActionBar.BorderArt, "actionbar")
        local caps = MainActionBar.EndCaps
        if caps then
            WatchTexture(caps.LeftEndCap and caps.LeftEndCap.Texture, "leftcap")
            WatchTexture(caps.RightEndCap and caps.RightEndCap.Texture, "rightcap")
        end
        if MicroMenu then
            WatchTexture(MicroMenu.BorderArt, "actionbar")
            WatchTexture(MicroMenu.BackgroundArt, "actionbar")
        end
        if BagsBar then
            WatchTexture(BagsBar.BorderArt, "actionbar")
        end
        for _, name in ipairs(microButtons) do
            if _G[name] then WatchMicroButton(_G[name]) end
        end
        for _, name in ipairs(bagButtons) do
            if _G[name] then WatchBagButton(_G[name]) end
        end
    end
    for _, suffix in ipairs({ "Main", "BottomLeft", "BottomRight" }) do
        local bar = _G["ErzbaroneUI" .. suffix .. "SecureBar"]
        if bar then WatchTexture(bar.background, "actionbar") end
    end
    WatchOwner(ErzbaroneUI.ActionLayout, "Update")
    WatchTexture(MinimapCompassTexture, "minimap")
    WatchTexture(MinimapCompassTextureUnderlay, "minimapUnderlay")
    local diel = MinimapCluster and MinimapCluster.DielFrame
    if diel then
        WatchTexture(diel.Background, "dielBackground")
        for _, region in ipairs({ diel:GetRegions() }) do
            local atlas = region.GetAtlas and region:GetAtlas()
            if type(atlas) == "string" and atlases.dielBorder[atlas:lower()] then
                WatchTexture(region, "dielBorder")
            end
        end
    end

    for texture, state in pairs(textures) do
        RefreshTexture(texture, state)
    end
    scanning = false
end

--- Registers an addon action-bar background without scanning unrelated private textures.
--- Queues registration until combat ends when necessary.
function ErzbaroneUI.NeutralHUD:RegisterActionBarBackground(texture)
    if not enabled or not texture then return end
    if InCombat() then
        pendingBackgrounds[texture] = true
        pending = true
        return
    end
    WatchTexture(texture, "actionbar")
end

--- Enables HUD theming for the reload-latched setting and watches Blizzard lifecycle events.
--- Requires NeutralArt and retries deferred scans after combat.
function ErzbaroneUI.NeutralHUD:Initialize()
    if self.Initialized then return end
    self.Initialized = true
    if not ErzbaroneUISettings or not ErzbaroneUISettings.neutralDecorations then return end
    enabled = true

    local events = CreateFrame("Frame")
    for _, event in ipairs({
        "PLAYER_ENTERING_WORLD", "ADDON_LOADED", "GROUP_ROSTER_UPDATE",
        "EDIT_MODE_LAYOUTS_UPDATED", "PLAYER_REGEN_ENABLED",
    }) do
        events:RegisterEvent(event)
    end
    events:SetScript("OnEvent", function(_, event)
        if event ~= "PLAYER_REGEN_ENABLED" or pending then
            Scan()
        end
    end)
    Scan()
end
