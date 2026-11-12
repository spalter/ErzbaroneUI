local root = (... or ".") .. "\\"

local function Equal(actual, expected, message)
    assert(actual == expected, message .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end

local frames = {}
local function Widget()
    local widget = { alpha = 1, alphaWrites = 0, shown = true }
    function widget:Hide() self.shown = false end
    function widget:IsShown() return self.shown end
    function widget:IsMouseOver() return self.hovered end
    function widget:IsMenuOpen() return self.menuOpen end
    function widget:GetAlpha() return self.alpha end
    function widget:SetAlpha(alpha)
        self.alpha = alpha
        self.alphaWrites = self.alphaWrites + 1
    end
    function widget:SetScript(script, callback) self[script] = callback end
    return widget
end
function CreateFrame()
    local frame = Widget()
    frames[#frames + 1] = frame
    return frame
end

MinimapCluster = { Tracking = Widget(), MinimapContainer = Widget() }
MinimapCluster.Tracking.Button = Widget()
GameTimeFrame, AddonCompartmentFrame = Widget(), Widget()
GameTimeCalendarInvitesTexture = Widget()
GameTimeCalendarInvitesTexture.shown = false
local editMode = false
EditModeManagerFrame = { IsEditModeActive = function() return editMode end }
ErzbaroneUISettings = { compactMinimap = false, fadeMinimapButtons = true }
dofile(root .. "modules\\minimap.lua")
ErzbaroneUI.Minimap:Update()
local fader = frames[2]
local function Tick(elapsed) fader:OnUpdate(elapsed or 1) end
local function Writes()
    return MinimapCluster.Tracking.alphaWrites + GameTimeFrame.alphaWrites + AddonCompartmentFrame.alphaWrites
end

Tick(0.125)
Equal(GameTimeFrame.alpha, 0.25, "Buttons must retain their fade speed")
Tick()
Equal(MinimapCluster.Tracking.alpha, 0, "Idle tracking must disappear")
Equal(GameTimeFrame.alpha, 0, "Idle calendar must disappear")
Equal(AddonCompartmentFrame.alpha, 0, "Idle addon menu must disappear")
local writes = Writes()
for _ = 1, 600 do Tick(1 / 60) end
Equal(Writes(), writes, "Settled fades must not write unchanged alpha")

GameTimeCalendarInvitesTexture.shown = true
Tick()
Equal(GameTimeFrame.alpha, 1, "New calendar invites must reveal the calendar while idle")
Equal(MinimapCluster.Tracking.alpha, 0, "Invites must not reveal other buttons")
writes = Writes()
Tick()
Equal(Writes(), writes, "Pending invites must not cause repeated alpha writes")
MinimapCluster.MinimapContainer.hovered = true
Tick(0.125)
Equal(MinimapCluster.Tracking.alpha, 0.75, "Hover must fade buttons in immediately")
Equal(GameTimeFrame.alpha, 1, "Invites must remain visible during a fade")
GameTimeCalendarInvitesTexture.shown = false
Tick(0)
Equal(GameTimeFrame.alpha, 0.75, "Cleared invites must rejoin the current fade")
Tick()
Equal(AddonCompartmentFrame.alpha, 1, "Hover must fully reveal buttons")
MinimapCluster.MinimapContainer.hovered = false
Tick()

for _, owner in ipairs({ MinimapCluster.Tracking.Button, AddonCompartmentFrame }) do
    owner.menuOpen = true
    Tick()
    Equal(GameTimeFrame.alpha, 1, "Open dropdowns must reveal buttons")
    owner.menuOpen = false
    Tick()
end
for _, button in ipairs({ MinimapCluster.Tracking, GameTimeFrame, AddonCompartmentFrame }) do
    button.hovered = true
    Tick()
    Equal(GameTimeFrame.alpha, 1, "Each button must retain hover detection")
    button.hovered = false
    Tick()
end
editMode = true
Tick()
Equal(GameTimeFrame.alpha, 1, "Edit Mode must reveal buttons")
editMode = false
Tick()
AddonCompartmentFrame = nil
Tick()
AddonCompartmentFrame = Widget()
Tick()
Equal(AddonCompartmentFrame.alpha, 0, "Late-loaded buttons must join a settled fade")
AddonCompartmentFrame:SetAlpha(1)
Tick()
Equal(AddonCompartmentFrame.alpha, 0, "Native alpha changes must be corrected")

ErzbaroneUISettings.fadeMinimapButtons = false
ErzbaroneUI.Minimap:Update()
Equal(fader.OnUpdate, nil, "Disabling must stop fade updates")
Equal(GameTimeFrame.alpha, 1, "Disabling must restore calendar visibility")
Equal(AddonCompartmentFrame.alpha, 1, "Disabling must restore addon-menu visibility")
ErzbaroneUISettings.fadeMinimapButtons = true
ErzbaroneUI.Minimap:Update()
Tick()
Equal(GameTimeFrame.alpha, 0, "Re-enabling must restart fading")

print("minimap_test.lua: all assertions passed")
