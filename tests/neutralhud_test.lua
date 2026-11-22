local root = (... or ".") .. "\\"
local function Equal(actual, expected, message)
    local equal = actual == expected or (type(actual) == "number" and type(expected) == "number"
        and math.abs(actual - expected) < 0.00001)
    assert(equal, message .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end

local combat = false
function InCombatLockdown() return combat end
local frames, hookCount = {}, 0
function CreateFrame()
    local frame = { events = {} }
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:SetScript(name, callback) self[name] = callback end
    frames[#frames + 1] = frame
    return frame
end
function hooksecurefunc(owner, name, callback)
    assert(not combat, "Hooks must not be installed in combat")
    hookCount = hookCount + 1
    local original = owner[name]
    owner[name] = function(...)
        local result = original(...)
        callback(...)
        return result
    end
end
local function Texture(atlas, desaturated)
    local t = { atlas = atlas, desaturated = desaturated or false, writes = 0, color = { 1, 1, 1, 1 } }
    function t:GetAtlas() return self.atlas end
    function t:GetTexture() return self.file end
    function t:GetVertexColor() return self.color[1], self.color[2], self.color[3], self.color[4] end
    function t:SetVertexColor(r, g, b, a)
        assert(not combat or self.nativeWrite, "Module must not tint in combat")
        self.color = { r, g, b, a or 1 }
    end
    function t:IsDesaturated() return self.desaturated end
    function t:SetAtlas(value) self.atlas = value end
    function t:SetTexture(value) self.atlas = nil; self.file = value end
    function t:SetDesaturated(value)
        assert(not combat or self.nativeWrite, "Module must not write in combat")
        self.desaturated = value
        self.writes = self.writes + 1
    end
    return t
end
local function Fire(event, ...)
    local f = frames[#frames]
    assert(f.events[event], "Missing event " .. event)
    f:OnEvent(event, ...)
end

ErzbaroneUISettings = { neutralDecorations = false }
ErzbaroneUI = {}
dofile(root .. "modules\\neutralart.lua")
ErzbaroneUI.NeutralArt.Tint = { 0.5, 0.75, 1 }
dofile(root .. "modules\\neutralhud.lua")
local disabledBackground = Texture("UI-HUD-ActionBar-Frame")
ErzbaroneUI.NeutralHUD:RegisterActionBarBackground(disabledBackground)
Equal(hookCount, 0, "Registration before initialization is inert")
ErzbaroneUI.NeutralHUD:Initialize()
ErzbaroneUISettings.neutralDecorations = true
ErzbaroneUI.NeutralHUD:Initialize()
ErzbaroneUI.NeutralHUD:RegisterActionBarBackground(disabledBackground)
Equal(disabledBackground.desaturated, false, "Registration respects the disabled reload latch")
Equal(#frames, 0, "Disabled setting is captured until reload")
Equal(hookCount, 0, "Disabled setting installs no hooks")

local playerBorder = Texture("UI-HUD-UnitFrame-Player-PortraitOn")
playerBorder:SetVertexColor(0.8, 0.8, 0.4, 0.7)
local portrait = Texture("UI-HUD-UnitFrame-Player-PortraitOn")
PlayerFrame = { PlayerFrameContainer = { FrameTexture = playerBorder, Portrait = portrait } }
local targetBorder = Texture("UI-HUD-UnitFrame-Target-PortraitOn")
local bossBorder = Texture("UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold")
TargetFrame = { TargetFrameContainer = { FrameTexture = targetBorder, BossPortraitFrameTexture = bossBorder } }
function TargetFrame:CreateTargetofTarget()
    self.totFrame = { FrameTexture = Texture("UI-HUD-UnitFrame-TargetofTarget-PortraitOn") }
end
local cap = Texture("ui-hud-actionbar-gryphon-left")
local hordeCap = Texture("ui-hud-actionbar-wyvern-right")
local nativeBackground = Texture("UI-HUD-ActionBar-Frame", true)
MainActionBar = {
    BorderArt = nativeBackground,
    EndCaps = { LeftEndCap = { Texture = cap }, RightEndCap = { Texture = hordeCap } },
}
MinimapCompassTexture = Texture("UI-HUD-Minimap-Frame")
MinimapCompassTextureUnderlay = Texture(nil)
local ignored = Texture("UI-HUD-ActionBar-Frame")
MainActionBar.SlotBackground = ignored
local function Button(normal, pushed)
    local button = { normal = Texture(normal), pushed = Texture(pushed) }
    function button:GetNormalTexture() return self.normal end
    function button:GetPushedTexture() return self.pushed end
    return button
end
MicroMenu = { BorderArt = Texture("UI-HUD-ActionBar-Frame"),
    BackgroundArt = Texture("UI-HUD-ActionBar-IconFrame-Background") }
ProfessionMicroButton = Button("UI-HUD-MicroMenu-Professions-Up", "UI-HUD-MicroMenu-Professions-Down")
ProfessionMicroButton.Background = Texture("UI-HUD-MicroMenu-ButtonBG-Up")
ProfessionMicroButton.PushedBackground = Texture("UI-HUD-MicroMenu-ButtonBG-Down")
ProfessionMicroButton.FlashContent = Texture("UI-HUD-MicroMenu-Professions-Mouseover")
function ProfessionMicroButton:UpdateMicroButton()
    self.normal:SetAtlas("UI-HUD-MicroMenu-Professions-Disabled")
end
BagsBar = { BorderArt = Texture("UI-HUD-ActionBar-Frame") }
MainMenuBarBackpackButton = Button("UI-HUD-ActionBar-IconFrame-Bags", "UI-HUD-ActionBar-IconFrame-Bags")
MainMenuBarBackpackButton.bagIcon = "Interface\\Icons\\ui-hud-actionbar-bag"
MainMenuBarBackpackButton.icon = Texture(nil)
MainMenuBarBackpackButton.icon.file = 12345
function GetFileIDFromPath(path)
    assert(path == "Interface\\Icons\\ui-hud-actionbar-bag.blp")
    return 12345
end
CharacterBag0Slot = Button("UI-HUD-ActionBar-IconFrame-Bags", "UI-HUD-ActionBar-IconFrame-Bags")
CharacterBag0Slot.icon = Texture(nil)
CharacterBag0Slot.icon.file = 98765
function CharacterBag0Slot:UpdateTextures()
    self.normal:SetAtlas("UI-HUD-ActionBar-IconFrame")
end
PartyFrame = {}
function PartyFrame:InitializePartyMemberFrames()
    local member = { Texture = Texture("UI-HUD-UnitFrame-Party-PortraitOn"),
        PetFrame = { Texture = Texture("ui-hud-unitframe-party-portraiton") },
        Icon = Texture("UI-HUD-UnitFrame-Party-PortraitOn") }
    self.PartyMemberFramePool = {
        EnumerateActive = function()
            local done = false
            return function()
                if not done then done = true; return member end
            end
        end,
    }
    return member
end
ErzbaroneUI.ActionLayout = {}
function ErzbaroneUI.ActionLayout:Update()
    ErzbaroneUIMainSecureBar = { background = Texture("UI-HUD-ActionBar-Frame") }
end
dofile(root .. "modules\\neutralhud.lua")
local hud = ErzbaroneUI.NeutralHUD
hud:Initialize()
Equal(playerBorder.desaturated, true, "Player border is neutral")
Equal(playerBorder.color[1], 0.4, "Shared tint multiplies the original red channel")
Equal(playerBorder.color[2], 0.6, "Shared tint multiplies the original green channel")
Equal(playerBorder.color[3], 0.4, "Shared tint preserves original shading")
Equal(playerBorder.color[4], 0.7, "Shared tint preserves alpha")
Equal(MicroMenu.BorderArt.desaturated, true, "Micro-menu backdrop is neutral")
Equal(MicroMenu.BackgroundArt.desaturated, true, "Micro-menu inner backdrop is neutral")
Equal(ProfessionMicroButton.Background.desaturated, true, "Micro button background is neutral")
Equal(ProfessionMicroButton.PushedBackground.desaturated, true, "Pushed micro button background is neutral")
Equal(ProfessionMicroButton.normal.desaturated, true, "Micro button artwork is neutral")
Equal(ProfessionMicroButton.pushed.desaturated, true, "Pushed micro button artwork is neutral")
Equal(ProfessionMicroButton.FlashContent.desaturated, false, "Micro button alerts retain their colors")
Equal(BagsBar.BorderArt.desaturated, true, "Bag bar backdrop is neutral")
Equal(MainMenuBarBackpackButton.normal.desaturated, true, "Backpack border is neutral")
Equal(MainMenuBarBackpackButton.icon.desaturated, true, "Static backpack icon is neutral")
Equal(CharacterBag0Slot.normal.desaturated, true, "Bag slot border is neutral")
Equal(CharacterBag0Slot.pushed.desaturated, true, "Pushed bag slot border is neutral")
Equal(CharacterBag0Slot.icon.desaturated, false, "Equipped bag icon retains its color")
Equal(targetBorder.desaturated, true, "Target border is neutral")
Equal(bossBorder.desaturated, true, "Boss decoration is neutral")
Equal(cap.desaturated, true, "Gryphon is neutral")
Equal(hordeCap.desaturated, true, "Horde wyvern is neutral")
Equal(nativeBackground.desaturated, true, "Native background remains neutral")
Equal(MinimapCompassTexture.desaturated, true, "Fixed minimap ring is neutral")
Equal(portrait.desaturated, false, "Portrait is untouched")
Equal(ignored.desaturated, false, "Action button art is untouched")
local hooks = hookCount
hud:Initialize()
Fire("PLAYER_ENTERING_WORLD")
Equal(hookCount, hooks, "Repeated initialization and scans do not duplicate hooks")
Equal(playerBorder.color[1], 0.4, "Repeated scans do not compound the shared tint")
ProfessionMicroButton:UpdateMicroButton()
Equal(ProfessionMicroButton.normal.desaturated, true, "Updated micro-button art stays neutral")
CharacterBag0Slot:UpdateTextures()
Equal(CharacterBag0Slot.normal.desaturated, true, "Updated bag-slot borders stay neutral")
MainMenuBarBackpackButton.icon:SetTexture(54321)
Equal(MainMenuBarBackpackButton.icon.desaturated, false, "A replacement backpack icon retains its color")
MainMenuBarBackpackButton.icon:SetTexture(12345)
Equal(MainMenuBarBackpackButton.icon.desaturated, true, "The native backpack icon is themed again")
playerBorder:SetVertexColor(0.4, 0.8, 0.5, 0.2)
Equal(playerBorder.color[1], 0.2, "Native vertex color changes are retinted")
Equal(playerBorder.color[2], 0.6, "Native green changes are retinted")
Equal(playerBorder.color[4], 0.2, "Native alpha changes are preserved")
playerBorder:SetAtlas("Other-Player-Border")
Equal(playerBorder.color[1], 0.4, "Replacement artwork restores the latest native vertex color")
Equal(playerBorder.color[2], 0.8, "Replacement artwork restores the native green channel")
playerBorder:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn")
Equal(playerBorder.color[1], 0.2, "Returning to the native border reapplies the shared tint")

targetBorder:SetAtlas("UI-HUD-UnitFrame-Target-Rare-PortraitOn")
Equal(targetBorder.desaturated, true, "Classification changes stay neutral")
targetBorder:SetAtlas("Some-Other-Addon-Atlas")
Equal(targetBorder.desaturated, false, "Unrecognized replacement restores prior saturation")
targetBorder:SetAtlas("UI-HUD-ActionBar-Frame")
Equal(targetBorder.desaturated, false, "An unrelated known atlas is not treated as a target border")
targetBorder:SetAtlas("UI-HUD-UnitFrame-Target-MinusMob-PortraitOn")
Equal(targetBorder.desaturated, true, "Returning to native art is neutral")
targetBorder:SetTexture("Interface\\Other\\Art")
Equal(targetBorder.desaturated, false, "Replacement file remains untouched")
nativeBackground:SetAtlas("Other-Background")
Equal(nativeBackground.desaturated, true, "Originally desaturated art retains its state")
cap:SetDesaturated(false)
Equal(cap.desaturated, true, "Native saturation changes are corrected")
cap:SetAtlas("ui-hud-actionbar-wyvern-left")
Equal(cap.desaturated, true, "Switching to the Horde left wyvern stays neutral")
hordeCap:SetAtlas("ui-hud-actionbar-gryphon-right")
Equal(hordeCap.desaturated, true, "Switching to the Alliance right gryphon stays neutral")
cap:SetAtlas("Other-Cap")
Equal(cap.desaturated, false, "Replacement uses the latest native saturation")

local dialBackground = Texture("UI-HUD-Minimap-DayCycle")
local dialBorder = Texture("UI-HUD-Minimap-Frame-Cycle")
local otherDialArt = Texture("Other-Dial-Art")
MinimapCluster = { DielFrame = { Background = dialBackground } }
function MinimapCluster.DielFrame:GetRegions()
    return dialBackground, dialBorder, otherDialArt
end
Fire("ADDON_LOADED", "Blizzard_Minimap")
Equal(dialBackground.desaturated, true, "Late-loaded day dial is neutral")
Equal(dialBorder.desaturated, true, "Day/night dial border is neutral")
Equal(otherDialArt.desaturated, false, "Unrelated minimap dial artwork stays colored")
dialBackground:SetAtlas("UI-HUD-Minimap-NightCycle")
Equal(dialBackground.desaturated, true, "Night dial stays neutral after a cycle change")
dialBackground:SetAtlas("Other-Dial")
Equal(dialBackground.desaturated, false, "Replacement dial artwork keeps its original saturation")
dialBackground:SetAtlas("UI-HUD-Minimap-DayCycle")
Equal(dialBackground.desaturated, true, "Returning to the day dial restores the neutral theme")

MinimapCompassTexture:SetAtlas("UI-HUD-Minimap-Frame-Pointer")
MinimapCompassTextureUnderlay:SetAtlas("UI-HUD-Minimap-Frame-Circle")
Equal(MinimapCompassTexture.desaturated, false, "Rotating directional pointer is not recolored")
Equal(MinimapCompassTextureUnderlay.desaturated, true, "Rotated minimap ring is neutral")
TargetFrame:CreateTargetofTarget()
Equal(TargetFrame.totFrame.FrameTexture.desaturated, true, "Late target-of-target border is neutral")
local member = PartyFrame:InitializePartyMemberFrames()
Equal(member.Texture.desaturated, true, "Pooled party border is neutral")
Equal(member.PetFrame.Texture.desaturated, true, "Party pet border is neutral")
Equal(member.Icon.desaturated, false, "Party icons are untouched")
ErzbaroneUI.ActionLayout:Update()
Equal(ErzbaroneUIMainSecureBar.background.desaturated, true, "Late custom background is neutral")

ErzbaroneUISettings.neutralDecorations = false
local privateBackground = Texture("UI-HUD-ActionBar-Frame")
hud:RegisterActionBarBackground(privateBackground)
Equal(privateBackground.desaturated, true, "Private backgrounds respect the enabled reload latch")
hooks = hookCount
hud:RegisterActionBarBackground(privateBackground)
hud:RegisterActionBarBackground(nil)
Equal(hookCount, hooks, "Repeated or nil background registration does not add hooks")
privateBackground:SetTexture("Interface\\Other\\Background")
Equal(privateBackground.desaturated, false, "Registered replacement artwork retains original saturation")
privateBackground:SetAtlas("UI-HUD-ActionBar-Frame")
Equal(privateBackground.desaturated, true, "Registered background atlas changes remain neutral")

combat = true
local combatBackground = Texture("UI-HUD-ActionBar-Frame")
hooks = hookCount
hud:RegisterActionBarBackground(combatBackground)
hud:RegisterActionBarBackground(combatBackground)
Equal(combatBackground.desaturated, false, "Private background registration is deferred in combat")
Equal(hookCount, hooks, "Combat registration installs no hooks")
local late = Texture("UI-HUD-UnitFrame-Player-PortraitOn-Vehicle")
PlayerFrame.PlayerFrameContainer.VehicleFrameTexture = late
QuestLogMicroButton = Button("UI-HUD-MicroMenu-Questlog-Up", "UI-HUD-MicroMenu-Questlog-Down")
MinimapCompassTextureUnderlay:SetAtlas("Other-Ring")
dialBackground:SetAtlas("UI-HUD-Minimap-NightCycle")
playerBorder.nativeWrite = true
playerBorder:SetDesaturated(false)
playerBorder:SetVertexColor(0.6, 0.4, 0.2, 0.3)
playerBorder.nativeWrite = false
Fire("ADDON_LOADED", "Blizzard_UnitFrame")
Equal(late.desaturated, false, "Late art is deferred during combat")
Equal(QuestLogMicroButton.normal.desaturated, false, "Late micro buttons are deferred during combat")
Equal(MinimapCompassTextureUnderlay.desaturated, true, "Replacement restoration is deferred during combat")
Equal(playerBorder.desaturated, false, "Native combat saturation is not changed immediately")
Equal(playerBorder.color[1], 0.6, "Native combat vertex colors are not changed immediately")
combat = false
Fire("PLAYER_REGEN_ENABLED")
Equal(combatBackground.desaturated, true, "Queued private background is neutral after combat")
hooks = hookCount
hud:RegisterActionBarBackground(combatBackground)
Equal(hookCount, hooks, "Queued registration is deduplicated")
Equal(late.desaturated, true, "Late art is processed after combat")
Equal(QuestLogMicroButton.normal.desaturated, true, "Late micro buttons are themed after combat")
Equal(MinimapCompassTextureUnderlay.desaturated, false, "Replacement is restored after combat")
Equal(playerBorder.desaturated, true, "Combat saturation changes are corrected afterwards")
Equal(playerBorder.color[1], 0.3, "Native combat vertex colors are tinted after combat")
Equal(playerBorder.color[4], 0.3, "Native combat alpha is preserved")
Equal(dialBackground.desaturated, true, "Day/night cycle changes during combat stay neutral after combat")

print("neutralhud_test.lua: all assertions passed")
