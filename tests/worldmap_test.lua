local root = (... or ".") .. "\\"

ErzbaroneUISettings = { worldMapLevels = false }
Enum = { UIMapType = { Continent = 2, Zone = 3, Micro = 5 } }
MAP_AREA_LABEL_TYPE = { AREA_NAME = 3, POI = 4 }
LEVEL, FISHING, ZONE = "Level", "Fishing", "Zone"

local frames = {}
function CreateFrame()
    local frame = {}
    function frame:RegisterEvent(event) self.event = event end
    function frame:SetScript(name, callback) self[name] = callback end
    frames[#frames + 1] = frame
    return frame
end

local function FontString()
    local text = { shown = true, writes = 0, font = "title-font", size = 30, flags = "OUTLINE", color = { 1, 1, 1, 1 } }
    function text:SetText(value) self.text = value; self.writes = self.writes + 1 end
    function text:GetText() return self.text end
    function text:SetShown(value) self.shown = value end
    function text:IsShown() return self.shown end
    function text:ClearAllPoints() self.point = nil end
    function text:SetPoint(...) self.point = { ... } end
    function text:SetJustifyH() end
    function text:GetFont() return self.font, self.size, self.flags end
    function text:SetFont(font, size, flags)
        self.font, self.size, self.flags = font, size, flags
        return true
    end
    function text:GetTextColor() return table.unpack(self.color) end
    function text:SetTextColor(r, g, b, a) self.color = { r, g, b, a } end
    return text
end

function hooksecurefunc(object, method, callback)
    local previous = object[method]
    object[method] = function(self, ...)
        previous(self, ...)
        callback(self, ...)
    end
end

local maps = {
    [1415] = { mapID = 1415, mapType = 2, parentMapID = 0, name = "Eastern Kingdoms" },
    [1429] = { mapID = 1429, mapType = 3, parentMapID = 1415, name = "Elwynn Forest" },
    [1434] = { mapID = 1434, mapType = 3, parentMapID = 1415, name = "Stranglethorn Vale" },
    [9000] = { mapID = 9000, mapType = 5, parentMapID = 1429, name = "Goldshire" },
    [9999] = { mapID = 9999, mapType = 3, parentMapID = 1415, name = "Unknown" },
}
local playerLevels = { [1429] = { 1, 10 }, [1434] = { 30, 45 }, [9999] = { 20, 20 } }
local positionID
local lastPosition
C_Map = {
    GetMapInfo = function(id) return maps[id] end,
    GetMapInfoAtPosition = function(id, x, y)
        lastPosition = { id, x, y }
        return maps[positionID]
    end,
    GetMapLevels = function(id)
        local levels = playerLevels[id]
        if levels then return levels[1], levels[2] end
    end,
}

local gamepad = false
InputUtil = { IsGamepadUIEnabled = function() return gamepad end }
local map = { mapID = 1415, focus = true, gamepad = false, pinFocus = true, dataProviders = {} }
function map:GetMapID() return self.mapID end
function map:IsCanvasMouseFocus() return self.focus end
function map:IsCanvasMouseFocusOrPinFocus() return self.pinFocus end
function map:HasGamepadCursorInput() return self.gamepad end
function map:GetNormalizedCursorPosition() return 0.1, 0.2 end
function map:GetNormalizedGamepadCursorPosition() return 0.7, 0.8 end

local function MakeLabel()
    local areaLabel = { labelInfoByType = {}, Name = FontString(), Description = FontString(), hooks = {} }
    function areaLabel:GetHighestPriorityLabelInfo()
        return self.labelInfoByType[MAP_AREA_LABEL_TYPE.POI] or self.labelInfoByType[MAP_AREA_LABEL_TYPE.AREA_NAME]
    end
    function areaLabel:EvaluateLabels()
        local info = self:GetHighestPriorityLabelInfo()
        self.Name:SetText(info and info.name or "")
        self.Description:SetText(info and info.description or "")
    end
    function areaLabel:CreateFontString(_, _, font)
        assert(font == "WorldMapTextFont", "Range lines must inherit the title font styling")
        self.created = (self.created or 0) + 1
        local text = FontString()
        if self.created == 1 then self.ranges = text else self.fishing = text end
        return text
    end
    function areaLabel:HookScript(name, callback) self.hooks[name] = callback end
    return areaLabel
end

local function AddProvider(areaLabel)
    local provider = { Label = areaLabel }
    function provider:GetMap() return map end
    areaLabel.dataProvider = provider
    map.dataProviders[provider] = true
    return provider
end

dofile(root .. "modules\\worldmap.lua")
ErzbaroneUI.WorldMap:Initialize()
assert(#frames == 1 and frames[1].event == "ADDON_LOADED", "Wait for a late-loaded world map")

local areaLabel = MakeLabel()
local provider = AddProvider(areaLabel)
WorldMapFrame = map
frames[1].OnEvent(frames[1], "ADDON_LOADED", "Blizzard_WorldMap")
assert(areaLabel.created == 2, "Attach two range labels to the world map")
ErzbaroneUI.WorldMap:Initialize()
assert(#frames == 1 and areaLabel.created == 2, "Repeated initialization must not duplicate hooks")

local area = { name = "Elwynn Forest|cffffff00 (1-10)|r", description = "" }
areaLabel.labelInfoByType[MAP_AREA_LABEL_TYPE.AREA_NAME] = area
positionID = 1429
areaLabel:EvaluateLabels()
assert(areaLabel.Name:GetText() == area.name and not areaLabel.ranges:IsShown() and not areaLabel.fishing:IsShown(),
    "Default-off preserves native title")

ErzbaroneUISettings.worldMapLevels = true
ErzbaroneUI.WorldMap:Update()
areaLabel.Name:SetTextColor(0.35, 0.5, 0.9, 1)
areaLabel:EvaluateLabels()
assert(areaLabel.Name:GetText() == "Elwynn Forest", "Move native level out of the title")
assert(areaLabel.ranges:GetText() == "Level: 4-10" and areaLabel.fishing:GetText() == "Fishing: 1-25",
    "The supplied quest range takes priority over Blizzard's different range")
local font, size, flags = areaLabel.ranges:GetFont()
local fishingFont, fishingSize, fishingFlags = areaLabel.fishing:GetFont()
assert(font == "title-font" and fishingFont == font and fishingSize < size and size < areaLabel.Name.size
    and flags == areaLabel.Name.flags and fishingFlags == flags, "Title, level and fishing use descending font sizes")
local r, g, b, a = areaLabel.ranges:GetTextColor()
local fr, fg, fb, fa = areaLabel.fishing:GetTextColor()
assert(r == 0.35 and g == 0.5 and b == 0.9 and a == 1, "Both lines match the title color, not the difficulty color")
assert(fr == r and fg == g and fb == b and fa == a, "Fishing has the same color as the title")
assert(areaLabel.ranges.point[2] == areaLabel.Name, "Anchor beneath the title")
assert(areaLabel.fishing.point[2] == areaLabel.ranges, "Anchor fishing beneath the level")
local writes = areaLabel.ranges.writes
local fishingWrites = areaLabel.fishing.writes
areaLabel:EvaluateLabels()
assert(areaLabel.ranges.writes == writes and areaLabel.fishing.writes == fishingWrites,
    "Unchanged hover does not rewrite range text")
areaLabel.Name:SetFont("changed-font", 40, "")
areaLabel.Name:SetTextColor(0.8, 0.3, 0.2, 1)
areaLabel:EvaluateLabels()
font, size, flags = areaLabel.ranges:GetFont()
fishingFont, fishingSize, fishingFlags = areaLabel.fishing:GetFont()
r, g, b, a = areaLabel.ranges:GetTextColor()
fr, fg, fb, fa = areaLabel.fishing:GetTextColor()
assert(font == "changed-font" and fishingFont == font and fishingSize < size and size < 40
    and flags == "" and fishingFlags == flags, "Follow subsequent title font changes")
assert(r == 0.8 and g == 0.3 and b == 0.2 and a == 1, "Follow subsequent title color changes")
assert(fr == r and fg == g and fb == b and fa == a, "Both lines follow title color changes")

local setFont, nativePrint = areaLabel.fishing.SetFont, print
local fontWarnings = {}
areaLabel.fishing.SetFont = function() return false end
print = function(message) fontWarnings[#fontWarnings + 1] = message end
areaLabel.Name:SetFont("another-font", 40, "")
areaLabel:EvaluateLabels()
areaLabel:EvaluateLabels()
print = nativePrint
assert(#fontWarnings == 1 and not areaLabel.ranges:IsShown() and not areaLabel.fishing:IsShown()
    and areaLabel.Name:GetText() == area.name,
    "A font failure is reported once and restores the native title")
areaLabel.fishing.SetFont = setFont
areaLabel:EvaluateLabels()
assert(areaLabel.ranges:IsShown() and areaLabel.fishing:IsShown() and areaLabel.Name:GetText() == "Elwynn Forest",
    "Recover when the font becomes available")

area.description = "Wild pets"
areaLabel:EvaluateLabels()
assert(areaLabel.Description:GetText() == "Wild pets" and areaLabel.ranges.point[2] == areaLabel.Description,
    "Keep native descriptions and put ranges below them")
ErzbaroneUISettings.worldMapLevels = false
ErzbaroneUI.WorldMap:Update()
assert(areaLabel.Name:GetText() == area.name and not areaLabel.ranges:IsShown() and not areaLabel.fishing:IsShown(),
    "Disable restores the title immediately")

ErzbaroneUISettings.worldMapLevels = true
map.mapID, positionID, area.name, area.description = 1429, 1429, "Goldshire", ""
areaLabel:EvaluateLabels()
assert(areaLabel.Name:GetText() == "Goldshire")
assert(areaLabel.ranges:GetText() == "Level: 4-10" and areaLabel.fishing:GetText() == "Fishing: 1-25 (Zone)",
    "Label inherited fishing levels")
positionID = 9000
areaLabel:EvaluateLabels()
assert(areaLabel.ranges:GetText() == "Level: 4-10" and areaLabel.fishing:GetText() == "Fishing: 1-25 (Zone)",
    "Resolve micro map to its parent zone")

gamepad, map.gamepad = true, true
areaLabel:EvaluateLabels()
assert(lastPosition[2] == 0.7 and lastPosition[3] == 0.8, "Use Blizzard's gamepad cursor path")
gamepad, map.gamepad = false, false

map.mapID, positionID, area.name = 1415, 1434, "Stranglethorn Vale"
areaLabel:EvaluateLabels()
assert(areaLabel.ranges:GetText() == "Level: 34-50" and not areaLabel.fishing:IsShown(),
    "Omit zones with known fishing exceptions")
positionID, area.name = 9999, "Unknown"
areaLabel:EvaluateLabels()
assert(areaLabel.ranges:GetText() == "Level: 20", "Fall back to Blizzard for unlisted zones")
playerLevels[9999] = nil
areaLabel:EvaluateLabels()
assert(not areaLabel.ranges:IsShown() and not areaLabel.fishing:IsShown(), "Omit unavailable levels")
maps[1453] = { mapID = 1453, mapType = 3, parentMapID = 1415, name = "Stormwind City" }
positionID, area.name = 1453, "Stormwind City"
areaLabel:EvaluateLabels()
assert(not areaLabel.ranges:IsShown() and areaLabel.fishing:GetText() == "Fishing: 1-75"
    and areaLabel.fishing.point[2] == areaLabel.Name, "Fishing alone sits directly beneath the title")
positionID, area.name = 1429, "Elwynn Forest|cffffff00 (1-10)|r"
areaLabel:EvaluateLabels()
assert(areaLabel.fishing.point[2] == areaLabel.ranges, "Restore the stacked layout when a level appears")

positionID, area.name = 1429, "Elwynn Forest|cffffff00 (1-10)|r"
areaLabel.labelInfoByType[MAP_AREA_LABEL_TYPE.POI] = { name = "A point of interest", description = "POI details" }
areaLabel:EvaluateLabels()
assert(areaLabel.Name:GetText() == "A point of interest" and not areaLabel.ranges:IsShown() and not areaLabel.fishing:IsShown(),
    "Higher priority labels must not receive zone ranges")
areaLabel.labelInfoByType[MAP_AREA_LABEL_TYPE.POI] = nil
areaLabel:EvaluateLabels()
map.focus = false
areaLabel:EvaluateLabels()
assert(not areaLabel.ranges:IsShown() and not areaLabel.fishing:IsShown(), "Mouse exit clears ranges")
map.focus = true
areaLabel:EvaluateLabels()
areaLabel.hooks.OnHide(areaLabel)
assert(not areaLabel.ranges:IsShown() and not areaLabel.fishing:IsShown(), "Hiding the map clears ranges")
positionID, area.name = nil, "Eastern Kingdoms"
areaLabel:EvaluateLabels()
assert(not areaLabel.ranges:IsShown() and not areaLabel.fishing:IsShown(),
    "A continent without a hovered zone must not keep stale ranges")
positionID, area.name = 1429, "Elwynn Forest|cffffff00 (1-10)|r"
playerLevels[1429] = { 0, 0 }
areaLabel:EvaluateLabels()
assert(areaLabel.ranges:GetText() == "Level: 4-10" and areaLabel.fishing:GetText() == "Fishing: 1-25",
    "A listed zone must use its quest range even when Blizzard has no level range")
playerLevels[1429] = { 1, 10 }

local suppliedZones = {
    { 1429, "Elwynn Forest", "4-10" }, { 1420, "Tirisfal Glades", "6-40" },
    { 1426, "Dun Morogh", "7-40" }, { 1436, "Westfall", "10-22" },
    { 1432, "Loch Modan", "11-20" }, { 1421, "Silverpine Forest", "11-22" },
    { 1433, "Redridge Mountains", "15-26" }, { 1437, "Wetlands", "21-33" },
    { 1431, "Duskwood", "24-35" }, { 1424, "Hillsbrad Foothills", "24-40" },
    { 1416, "Alterac Mountains", "33-40" }, { 1417, "Arathi Highlands", "34-42" },
    { 1434, "Stranglethorn Vale", "34-50" }, { 1435, "Swamp of Sorrows", "35-55" },
    { 1418, "Badlands", "37-50" }, { 2548, "Riverglades", "38-44" },
    { 1425, "The Hinterlands", "43-51" }, { 1427, "Searing Gorge", "47-52" },
    { 1419, "Blasted Lands", "50-60" }, { 1428, "Burning Steppes", "52-56" },
    { 1422, "Western Plaguelands", "53-60" }, { 1423, "Eastern Plaguelands", "55-60" },
    { 1438, "Teldrassil", "5-12" }, { 1412, "Mulgore", "6-30" },
    { 1411, "Durotar", "7-12" }, { 1413, "The Barrens", "11-26" },
    { 1439, "Darkshore", "12-21" }, { 1442, "Stonetalon Mountains", "18-28" },
    { 1440, "Ashenvale", "20-30" }, { 1441, "Thousand Needles", "28-41" },
    { 1443, "Desolace", "33-42" }, { 1445, "Dustwallow Marsh", "35-53" },
    { 2652, "Shen'dralas", "38-43" }, { 1444, "Feralas", "43-50" },
    { 1446, "Tanaris", "45-60" }, { 1447, "Azshara", "48-60" },
    { 1449, "Un'Goro Crater", "52-55" }, { 1448, "Felwood", "52-57" },
    { 1452, "Winterspring", "54-60" }, { 1450, "Moonglade", "55-60" },
    { 2482, "Mount Hyjal", "56-59" }, { 1451, "Silithus", "57-60" },
}
for _, zone in ipairs(suppliedZones) do
    local id, name, expected = zone[1], zone[2], zone[3]
    maps[id] = { mapID = id, mapType = 3, parentMapID = 1415, name = name }
    positionID, area.name = id, name
    areaLabel:EvaluateLabels()
    local actual = areaLabel.ranges:GetText():match("^Level: (.+)")
    assert(actual == expected, name .. " must show the supplied quest range")
end

map.dataProviders[provider] = nil
local nativePrint, warnings = print, {}
print = function(message) warnings[#warnings + 1] = message end
ErzbaroneUI.WorldMap:Update()
ErzbaroneUI.WorldMap:Update()
print = nativePrint
assert(#warnings == 1 and warnings[1]:find("unavailable", 1, true), "Report a missing map provider once")
assert(not areaLabel.ranges:IsShown() and not areaLabel.fishing:IsShown(), "A removed provider must not leave stale ranges")
local second = MakeLabel()
local secondProvider = AddProvider(second)
ErzbaroneUI.WorldMap:Update()
assert(second.created == 2 and not areaLabel.ranges:IsShown() and not areaLabel.fishing:IsShown())
map.dataProviders[secondProvider] = nil
map.dataProviders[provider] = true
ErzbaroneUI.WorldMap:Update()
assert(areaLabel.created == 2, "Returning to a previously attached label must not install another hook")

print("worldmap tests passed")
