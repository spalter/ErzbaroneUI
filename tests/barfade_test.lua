local root = (... or ".") .. "\\"

local function Equal(actual, expected, message)
    assert(actual == expected, message .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end

local function Bar()
    local bar = { shown = true, alpha = 1, textures = {}, actionButtons = {} }
    local function Artwork(shown)
        local art = { shown = shown }
        function art:IsShown() return self.shown end
        function art:SetShown(value) self.shown = value end
        function art:Show() self:SetShown(true) end
        function art:Hide() self:SetShown(false) end
        return art
    end
    for index = 1, 12 do
        local button = { SlotArt = Artwork(false), SlotBackground = Artwork(true) }
        function button:UpdateButtonArt()
            self.SlotArt:Hide()
            self.SlotBackground:Show()
        end
        bar.actionButtons[index] = button
    end
    function bar:IsShown() return self.shown end
    function bar:IsMouseOver() return self.hovered end
    function bar:SetAlpha(alpha) self.alpha = alpha end
    function bar:CreateTexture(name, layer, template, sublevel)
        local texture = { parent = self, layer = layer, sublevel = sublevel, points = {} }
        function texture:SetAtlas(atlas) self.atlas = atlas end
        function texture:SetPoint(...) self.points[#self.points + 1] = { ... } end
        function texture:SetShown(shown) self.shown = shown end
        function texture:IsVisible() return self.shown and self.parent:IsShown() end
        function texture:GetEffectiveAlpha() return self.parent.alpha end
        self.textures[#self.textures + 1] = texture
        return texture
    end
    return bar
end

function hooksecurefunc(frame, method, callback)
    local original = frame[method]
    frame[method] = function(...)
        original(...)
        callback(...)
    end
end

local updater
function CreateFrame()
    updater = {}
    function updater:SetScript(script, callback) self[script] = callback end
    return updater
end

local cursor, editMode
function GetCursorInfo() return cursor end
EditModeManagerFrame = { IsEditModeActive = function() return editMode end }
MultiBarRight, MultiBarLeft = Bar(), Bar()
ErzbaroneUISettings = { fadeRightBars = false }
dofile(root .. "modules\\barfade.lua")

ErzbaroneUI.BarFade:Initialize()
Equal(#MultiBarRight.textures, 0, "Disabled option must not create a backdrop")
Equal(#MultiBarLeft.textures, 0, "Disabled option must not create a second backdrop")

ErzbaroneUISettings.fadeRightBars = true
ErzbaroneUI.BarFade:Update()
for _, bar in ipairs({ MultiBarRight, MultiBarLeft }) do
    for _, button in ipairs(bar.actionButtons) do
        Equal(button.SlotArt:IsShown(), true, "All vertical buttons must use textured slot art")
        Equal(button.SlotBackground:IsShown(), false, "Native flat slot backgrounds must be hidden")
        button:UpdateButtonArt()
        Equal(button.SlotArt:IsShown(), true, "Native artwork updates must preserve textured slots")
        Equal(button.SlotBackground:IsShown(), false, "Native artwork updates must not restore flat backgrounds")
    end
    Equal(#bar.textures, 1, "Each vertical bar needs one backdrop")
    local texture = bar.textures[1]
    Equal(texture.atlas, "UI-HUD-ActionBar-Frame", "Backdrop must match the main bar")
    Equal(texture.layer, "BACKGROUND", "Backdrop must draw behind buttons")
    Equal(texture.sublevel, -3, "Backdrop must use the main bar's draw order")
    Equal(texture.points[1][2], bar, "Backdrop must follow the native bar")
    Equal(texture.points[1][1], "TOPLEFT", "Backdrop must cover the top edge")
    Equal(texture.points[1][4], -6, "Backdrop must include the left border")
    Equal(texture.points[1][5], 6, "Backdrop must include the top border")
    Equal(texture.points[2][1], "BOTTOMRIGHT", "Backdrop must cover the bottom edge")
    Equal(texture.points[2][4], 4, "Backdrop must include the right border")
    Equal(texture.points[2][5], -5, "Backdrop must include the bottom border")
end

updater:OnUpdate(0.125)
Equal(MultiBarRight.alpha, 0.25, "Buttons must fade out gradually")
Equal(MultiBarRight.textures[1]:GetEffectiveAlpha(), 0.25, "Backdrop must fade with buttons")
updater:OnUpdate(1)
Equal(MultiBarLeft.textures[1]:GetEffectiveAlpha(), 0, "Backdrop must disappear when idle")
local artworkScans = 0
local nativeIpairs = ipairs
ipairs = function(list)
    if list == MultiBarRight.actionButtons or list == MultiBarLeft.actionButtons then
        artworkScans = artworkScans + 1
    end
    return nativeIpairs(list)
end
for _ = 1, 600 do
    updater:OnUpdate(1 / 60)
end
ipairs = nativeIpairs
Equal(artworkScans, 0, "Ready bars must not rescan button artwork during idle fade updates")
MultiBarLeft.hovered = true
updater:OnUpdate(1)
Equal(MultiBarRight.textures[1]:GetEffectiveAlpha(), 1, "Hover must reveal both backdrops")
MultiBarLeft.hovered = false
editMode = true
updater:OnUpdate(1)
Equal(MultiBarLeft.alpha, 1, "Edit Mode must keep the decorated bars visible")
editMode = false
cursor = "spell"
updater:OnUpdate(1)
Equal(MultiBarRight.alpha, 1, "Placing actions must keep the decorated bars visible")
cursor = nil

MultiBarLeft.shown = false
Equal(MultiBarLeft.textures[1]:IsVisible(), false, "Backdrop must not reveal a disabled native bar")
updater:OnUpdate(1)
ErzbaroneUI.BarFade:Update()
Equal(MultiBarRight.alpha, 1, "Refreshing the enabled option must synchronize fade alpha")
Equal(#MultiBarRight.textures, 1, "Refreshing must reuse the existing backdrop")

ErzbaroneUISettings.fadeRightBars = false
ErzbaroneUI.BarFade:Update()
Equal(updater.OnUpdate, nil, "Disabling must stop fading")
for _, bar in ipairs({ MultiBarRight, MultiBarLeft }) do
    for _, button in ipairs(bar.actionButtons) do
        Equal(button.SlotArt:IsShown(), false, "Disabling must restore native slot artwork")
        Equal(button.SlotBackground:IsShown(), true, "Disabling must restore native slot backgrounds")
        button:UpdateButtonArt()
        Equal(button.SlotArt:IsShown(), false, "Disabled hooks must not reapply textured slots")
    end
    Equal(bar.textures[1].shown, false, "Disabling must hide custom art on all bars")
    Equal(bar.alpha, 1, "Disabling must restore button alpha")
end
Equal(MultiBarLeft.shown, false, "Disabling must preserve native visibility")

MultiBarLeft = nil
ErzbaroneUISettings.fadeRightBars = true
ErzbaroneUI.BarFade:Update()
updater:OnUpdate(1)
MultiBarLeft = Bar()
updater:OnUpdate(1)
Equal(#MultiBarLeft.textures, 1, "Bars loaded later must receive a backdrop")
Equal(MultiBarLeft.actionButtons[12].SlotArt:IsShown(), true, "Late bars must receive textured slots")
Equal(MultiBarLeft.textures[1]:GetEffectiveAlpha(), 0, "Late backdrops must join the fade")
updater:OnUpdate(1)
Equal(#MultiBarLeft.textures, 1, "Fade updates must not duplicate backdrops")

ErzbaroneUISettings.fadeRightBars = false
ErzbaroneUI.BarFade:Update()
MultiBarLeft = Bar()
local delayedButton = MultiBarLeft.actionButtons[12]
local delayedArt = delayedButton.SlotArt
delayedButton.SlotArt = nil
ErzbaroneUISettings.fadeRightBars = true
ErzbaroneUI.BarFade:Update()
updater:OnUpdate(1)
Equal(MultiBarLeft.actionButtons[1].SlotArt:IsShown(), true, "Ready artwork must apply before all slots load")
delayedButton.SlotArt = delayedArt
updater:OnUpdate(1)
Equal(delayedArt:IsShown(), true, "Missing slot artwork must be retried after it loads")
delayedButton:UpdateButtonArt()
Equal(delayedArt:IsShown(), true, "Late artwork must retain the native update hook")

local delayedButtons = MultiBarLeft.actionButtons
MultiBarLeft.actionButtons = {}
updater:OnUpdate(1)
MultiBarLeft.actionButtons = { Bar().actionButtons[1] }
updater:OnUpdate(1)
Equal(MultiBarLeft.actionButtons[1].SlotArt:IsShown(), true, "Replaced button lists must receive artwork")
MultiBarLeft.actionButtons[2] = Bar().actionButtons[1]
updater:OnUpdate(1)
Equal(MultiBarLeft.actionButtons[2].SlotArt:IsShown(), true, "New buttons must receive artwork when a list grows")
MultiBarLeft.actionButtons = delayedButtons
updater:OnUpdate(1)

local lateButton = MultiBarLeft.actionButtons[1]
ErzbaroneUISettings.fadeRightBars = false
ErzbaroneUI.BarFade:Update()
lateButton.SlotArt:Show()
lateButton.SlotBackground:Hide()
ErzbaroneUISettings.fadeRightBars = true
ErzbaroneUI.BarFade:Update()
ErzbaroneUISettings.fadeRightBars = false
ErzbaroneUI.BarFade:Update()
Equal(lateButton.SlotArt:IsShown(), true, "Re-enabling must capture the current native art state")
Equal(lateButton.SlotBackground:IsShown(), false, "Restoration must preserve pre-existing native art")

print("barfade tests passed")
