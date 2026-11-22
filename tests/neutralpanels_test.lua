local root = (... or ".") .. "\\"

local events, layoutHook
function CreateFrame()
    local frame = {}
    function frame:RegisterEvent(event) self.event = event end
    function frame:SetScript(_, handler) self.handler = handler end
    events = frame
    return frame
end
function hooksecurefunc(object, method, handler)
    assert(object == NineSliceUtil and method == "ApplyLayout")
    layoutHook = handler
end
NineSliceUtil = { ApplyLayout = function() end }

local function Texture(atlas)
    return {
        color = { 0.8, 0.8, 0.4, 0.6 },
        GetAtlas = function() return atlas end,
        GetVertexColor = function(self) return self.color[1], self.color[2], self.color[3], self.color[4] end,
        SetVertexColor = function(self, r, g, b, a) self.color = { r, g, b, a } end,
        SetDesaturated = function(self, value) self.desaturated = value end,
    }
end
local function Button(normal, pushed, disabled, highlight)
    local button = {
        normal = Texture(normal), pushed = Texture(pushed),
        disabled = Texture(disabled), highlight = Texture(highlight),
    }
    function button:GetNormalTexture() return self.normal end
    function button:GetPushedTexture() return self.pushed end
    function button:GetDisabledTexture() return self.disabled end
    function button:GetHighlightTexture() return self.highlight end
    function button:HookScript(script, handler)
        assert(script == "OnShow")
        self.onShow = handler
    end
    return button
end
local function Panel()
    local panel = {
        NineSlice = { TopLeftCorner = Texture(), TopEdge = Texture(), Center = Texture() },
        Inset = { NineSlice = { LeftEdge = Texture() }, Bg = Texture() },
        Bg = Texture(),
        TopTileStreaks = Texture(),
        PortraitContainer = { portrait = Texture() },
        CloseButton = Button("RedButton-Exit", "RedButton-Exit-Pressed",
            "RedButton-Exit-Disabled", "RedButton-Highlight"),
    }
    function panel:HookScript(script, handler)
        assert(script == "OnShow")
        self.onShow = handler
    end
    return panel
end

ErzbaroneUISettings = { neutralDecorations = false }
dofile(root .. "modules\\neutralart.lua")
ErzbaroneUI.NeutralArt.Tint = { 0.5, 0.75, 1 }
dofile(root .. "modules\\neutralpanels.lua")
CharacterFrame = Panel()
local unpack = unpack or table.unpack
local function Regions(...)
    local regions = { ... }
    return { GetRegions = function() return unpack(regions) end }
end
local divider = Texture("common-framedivider")
local otherHostArt = Texture("other-atlas")
CharacterFrame.RightPaneHost = {
    GetChildren = function() return Regions(divider, otherHostArt) end,
}
local gearBorder = Texture("UI-Character-Info-GearSlot")
local weaponBorder = Texture("UI-Character-Info-GearSlot")
local ammoBorder = Texture("UI-Character-Info-GearSlotSmall")
local itemIcon, qualityBorder = Texture(), Texture("item-quality-border")
PaperDollItemsFrame = {
    EquipmentSlots = { { BorderFrame = Regions(gearBorder, qualityBorder), icon = itemIcon } },
    WeaponSlots = { { BorderFrame = Regions(weaponBorder) } },
}
CharacterAmmoSlot = Regions(ammoBorder)
ErzbaroneUI.NeutralPanels:Initialize()
assert(not CharacterFrame.NineSlice.TopEdge.desaturated and not events,
    "Disabled theme must not alter or hook panels")
assert(not divider.desaturated and not gearBorder.desaturated, "Disabled theme must leave character artwork unchanged")
assert(not CharacterFrame.CloseButton.normal.desaturated, "Disabled theme must leave close buttons unchanged")
ErzbaroneUISettings.neutralDecorations = true
ErzbaroneUI.NeutralPanels:Initialize()
assert(not events, "Changing the setting must not apply until reload")

dofile(root .. "modules\\neutralpanels.lua")
CharacterFrame.Background = Texture()
WorldMapFrame = { BorderFrame = Panel(), mapTexture = Texture() }
WorldMapFrame.BorderFrame.InsetBorderTop = Texture()
local maximize = Button("RedButton-Expand", "RedButton-Expand-Pressed",
    "RedButton-Expand-Disabled", "RedButton-Highlight")
local minimize = Button("RedButton-Condense", "RedButton-Condense-Pressed",
    "RedButton-Condense-Disabled", "RedButton-Highlight")
WorldMapFrame.BorderFrame.MaximizeMinimizeFrame = { MaximizeButton = maximize, MinimizeButton = minimize }
ErzbaroneUI.NeutralPanels:Initialize()
assert(CharacterFrame.NineSlice.TopEdge.desaturated and CharacterFrame.Inset.NineSlice.LeftEdge.desaturated)
assert(CharacterFrame.NineSlice.TopEdge.color[1] == 0.4 and math.abs(CharacterFrame.NineSlice.TopEdge.color[2] - 0.6) < 0.00001
    and CharacterFrame.NineSlice.TopEdge.color[3] == 0.4 and CharacterFrame.NineSlice.TopEdge.color[4] == 0.6,
    "Panels must use the same tint while preserving original vertex color and alpha")
assert(CharacterFrame.Background.desaturated and WorldMapFrame.BorderFrame.InsetBorderTop.desaturated)
assert(divider.desaturated and gearBorder.desaturated and weaponBorder.desaturated and ammoBorder.desaturated,
    "Character equipment borders and the pane divider must be neutral")
assert(gearBorder.color[1] == 0.4 and divider.color[1] == 0.4 and ammoBorder.color[4] == 0.6,
    "Character artwork must use the shared tint and preserve alpha")
assert(not itemIcon.desaturated and not qualityBorder.desaturated and not otherHostArt.desaturated,
    "Equipment icons, quality indicators and unrelated artwork must stay colored")
assert(not CharacterFrame.PortraitContainer.portrait.desaturated and not WorldMapFrame.mapTexture.desaturated)
assert(not CharacterFrame.NineSlice.Center.desaturated, "Only border pieces should be desaturated")
for _, button in ipairs({ CharacterFrame.CloseButton, WorldMapFrame.BorderFrame.CloseButton, maximize, minimize }) do
    assert(button.normal.desaturated and button.pushed.desaturated
        and button.disabled.desaturated and button.highlight.desaturated,
        "Each state of the close and resize buttons must be neutral")
end
maximize.normal = Texture("RedButton-Expand")
maximize.onShow(maximize)
assert(maximize.normal.desaturated, "A newly shown resize button must refresh its artwork")
CharacterFrame.CloseButton.normal = Texture("Some-Other-Addon-Atlas")
CharacterFrame.CloseButton.onShow(CharacterFrame.CloseButton)
assert(not CharacterFrame.CloseButton.normal.desaturated, "Replacement close-button artwork must remain colored")

local oldSlice = CharacterFrame.NineSlice
layoutHook(oldSlice)
assert(oldSlice.TopEdge.color[1] == 0.4, "Reapplying a panel must not compound the tint")
CharacterFrame.onShow(CharacterFrame)
assert(gearBorder.color[1] == 0.4 and divider.color[1] == 0.4,
    "Showing the character frame must not compound the tint")
local lateBorder = Texture("UI-Character-Info-GearSlot")
PaperDollItemsFrame.EquipmentSlots[2] = { BorderFrame = Regions(lateBorder) }
CharacterFrame.onShow(CharacterFrame)
assert(lateBorder.desaturated and lateBorder.color[1] == 0.4,
    "Showing the character frame must theme newly loaded equipment slots")
oldSlice.TopEdge = Texture()
layoutHook(oldSlice)
assert(oldSlice.TopEdge.desaturated, "Rebuilt known border pieces must be themed")
local unrelated = { TopEdge = Texture() }
layoutHook(unrelated)
assert(not unrelated.TopEdge.desaturated, "Layouts belonging to other frames must be left alone")

AuctionHouseFrame = Panel()
events.handler(events, "ADDON_LOADED", "Blizzard_AuctionHouseUI")
assert(AuctionHouseFrame.NineSlice.TopEdge.desaturated, "Late-loaded panels must be themed")
AuctionHouseFrame.NineSlice.TopLeftCorner = Texture()
AuctionHouseFrame.onShow(AuctionHouseFrame)
assert(AuctionHouseFrame.NineSlice.TopLeftCorner.desaturated, "Showing a panel reapplies its theme")
MerchantFrame = Panel()
events.handler(events, "ADDON_LOADED", "Blizzard_UIPanels_Game")
assert(MerchantFrame.NineSlice.TopEdge.desaturated, "Other supported Blizzard panels must be themed when loaded")
ContainerFrame1 = Panel()
events.handler(events, "ADDON_LOADED", "Blizzard_UIPanels_Game")
assert(ContainerFrame1.NineSlice.TopEdge.desaturated, "Bag borders must be themed without touching their contents")

print("neutralpanels_test.lua: all assertions passed")
