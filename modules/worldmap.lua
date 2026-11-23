if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.WorldMap = {}

-- Integrates with Blizzard_WorldMap's AreaLabelDataProvider and MapCanvas rather
-- than replacing their hover handling. C_Map supplies map identity and fallback
-- player levels; the local tables supply quest and fishing ranges by UI map ID.
-- InputUtil selects Blizzard's mouse or gamepad cursor path, and the area's
-- label priority prevents the extra text from appearing on unrelated POIs.
-- Config initializes the saved setting before main.lua initializes this module.

-- Minimum to fish and skill for a 100% catch rate in open water.
-- https://www.wowhead.com/forever/guide/professions/fishing/overview-leveling
-- Zones with documented exceptions are omitted until those areas can be resolved.
local fishingLevels = {
    [1411] = { 1, 25 },   -- Durotar
    [1412] = { 1, 25 },   -- Mulgore
    [1420] = { 1, 25 },   -- Tirisfal Glades
    [1426] = { 1, 25 },   -- Dun Morogh
    [1429] = { 1, 25 },   -- Elwynn Forest
    [1438] = { 1, 25 },   -- Teldrassil
    [1413] = { 1, 75 },   -- The Barrens
    [1421] = { 1, 75 },   -- Silverpine Forest
    [1432] = { 1, 75 },   -- Loch Modan
    [1436] = { 1, 75 },   -- Westfall
    [1439] = { 1, 75 },   -- Darkshore
    [1453] = { 1, 75 },   -- Stormwind City
    [1454] = { 1, 75 },   -- Orgrimmar
    [1455] = { 1, 75 },   -- Ironforge
    [1456] = { 1, 75 },   -- Thunder Bluff
    [1457] = { 1, 75 },   -- Darnassus
    [1458] = { 1, 75 },   -- Undercity
    [1424] = { 55, 150 }, -- Hillsbrad Foothills
    [1431] = { 55, 150 }, -- Duskwood
    [1433] = { 55, 150 }, -- Redridge Mountains
    [1437] = { 55, 150 }, -- Wetlands
    [1440] = { 55, 150 }, -- Ashenvale
    [1442] = { 55, 150 }, -- Stonetalon Mountains
    [1416] = { 130, 225 }, -- Alterac Mountains
    [1417] = { 130, 225 }, -- Arathi Highlands
    [1435] = { 130, 225 }, -- Swamp of Sorrows
    [1441] = { 130, 225 }, -- Thousand Needles
    [1443] = { 130, 225 }, -- Desolace
    [1445] = { 130, 225 }, -- Dustwallow Marsh
    [1422] = { 205, 300 }, -- Western Plaguelands
    [1425] = { 205, 300 }, -- The Hinterlands
    [1446] = { 205, 300 }, -- Tanaris
    [1448] = { 205, 300 }, -- Felwood
    [1449] = { 205, 300 }, -- Un'Goro Crater
    [1450] = { 205, 300 }, -- Moonglade
    [1423] = { 330, 425 }, -- Eastern Plaguelands
    [1428] = { 330, 425 }, -- Burning Steppes
    [1430] = { 330, 425 }, -- Deadwind Pass
    [1451] = { 330, 425 }, -- Silithus
    [1452] = { 330, 425 }, -- Winterspring
}

-- The middle 80% of quest levels, as provided by https://wispxp.com/zones.
local questLevels = {
    [1429] = { 4, 10 },  -- Elwynn Forest
    [1420] = { 6, 40 },  -- Tirisfal Glades
    [1426] = { 7, 40 },  -- Dun Morogh
    [1436] = { 10, 22 }, -- Westfall
    [1432] = { 11, 20 }, -- Loch Modan
    [1421] = { 11, 22 }, -- Silverpine Forest
    [1433] = { 15, 26 }, -- Redridge Mountains
    [1437] = { 21, 33 }, -- Wetlands
    [1431] = { 24, 35 }, -- Duskwood
    [1424] = { 24, 40 }, -- Hillsbrad Foothills
    [1416] = { 33, 40 }, -- Alterac Mountains
    [1417] = { 34, 42 }, -- Arathi Highlands
    [1434] = { 34, 50 }, -- Stranglethorn Vale
    [1435] = { 35, 55 }, -- Swamp of Sorrows
    [1418] = { 37, 50 }, -- Badlands
    [2548] = { 38, 44 }, -- Riverglades
    [1425] = { 43, 51 }, -- The Hinterlands
    [1427] = { 47, 52 }, -- Searing Gorge
    [1419] = { 50, 60 }, -- Blasted Lands
    [1428] = { 52, 56 }, -- Burning Steppes
    [1422] = { 53, 60 }, -- Western Plaguelands
    [1423] = { 55, 60 }, -- Eastern Plaguelands
    [1438] = { 5, 12 },  -- Teldrassil
    [1412] = { 6, 30 },  -- Mulgore
    [1411] = { 7, 12 },  -- Durotar
    [1413] = { 11, 26 }, -- The Barrens
    [1439] = { 12, 21 }, -- Darkshore
    [1442] = { 18, 28 }, -- Stonetalon Mountains
    [1440] = { 20, 30 }, -- Ashenvale
    [1441] = { 28, 41 }, -- Thousand Needles
    [1443] = { 33, 42 }, -- Desolace
    [1445] = { 35, 53 }, -- Dustwallow Marsh
    [2652] = { 38, 43 }, -- Shen'dralas
    [1444] = { 43, 50 }, -- Feralas
    [1446] = { 45, 60 }, -- Tanaris
    [1447] = { 48, 60 }, -- Azshara
    [1449] = { 52, 55 }, -- Un'Goro Crater
    [1448] = { 52, 57 }, -- Felwood
    [1452] = { 54, 60 }, -- Winterspring
    [1450] = { 55, 60 }, -- Moonglade
    [2482] = { 56, 59 }, -- Mount Hyjal
    [1451] = { 57, 60 }, -- Silithus
}

local label
local rangeTexts
local eventFrame
local replacedTitle
local anchorDescription
local anchorLevel
-- Providers can be reattached; retain their text and hooks to avoid duplicates.
local attachedLabels = {}
local reportedMissingProvider = false
local reportedFontError = false

--- Formats equal endpoints as a single level and other endpoints as a range.
local function FormatRange(minimum, maximum)
    if minimum == maximum then
        return tostring(minimum)
    end
    return minimum .. "-" .. maximum
end

--- Resolves micro maps and dungeon maps to their nearest zone, if any.
local function GetZoneInfo(mapInfo)
    while mapInfo and mapInfo.mapType > Enum.UIMapType.Zone and mapInfo.parentMapID ~= 0 do
        mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
    end
    if mapInfo and mapInfo.mapType == Enum.UIMapType.Zone then
        return mapInfo
    end
end

--- Updates or hides the two addon-owned labels without rewriting unchanged text.
local function SetText(level, fishing)
    if rangeTexts then
        -- False placeholders keep ipairs from stopping when the first line is absent.
        for index, text in ipairs({ level or false, fishing or false }) do
            local fontString = rangeTexts[index]
            text = text or nil
            if fontString:GetText() ~= text then
                fontString:SetText(text)
            end
            local shown = text ~= nil and text ~= ""
            if fontString:IsShown() ~= shown then
                fontString:SetShown(shown)
            end
        end
    end
end

--- Matches the title font and color at the requested smaller scale.
local function StyleText(fontString, font, size, flags, scale, r, g, b, a)
    local oldFont, oldSize, oldFlags = fontString:GetFont()
    local newSize = math.max(1, math.floor(size * scale + 0.5))
    if (font ~= oldFont or newSize ~= oldSize or flags ~= oldFlags)
        and not fontString:SetFont(font, newSize, flags) then
        return false
    end
    local oldR, oldG, oldB, oldA = fontString:GetTextColor()
    if r ~= oldR or g ~= oldG or b ~= oldB or a ~= oldA then
        fontString:SetTextColor(r, g, b, a)
    end
    return true
end

--- Creates separate labels so level and fishing can use different font sizes.
local function CreateRangeTexts(parent)
    local texts = {}
    for index = 1, 2 do
        local text = parent:CreateFontString(nil, "OVERLAY", "WorldMapTextFont")
        text:SetJustifyH("CENTER")
        texts[index] = text
    end
    return texts
end

--- Keeps Blizzard's description visible and closes the gap when level is absent.
local function AnchorRangeTexts(self, hasDescription, hasLevel)
    if anchorDescription ~= hasDescription or anchorLevel ~= hasLevel then
        local firstAnchor = hasDescription and self.Description or self.Name
        local firstOffset = hasDescription and -4 or -10
        rangeTexts[1]:ClearAllPoints()
        rangeTexts[1]:SetPoint("TOP", firstAnchor, "BOTTOM", 0, firstOffset)
        rangeTexts[2]:ClearAllPoints()
        if hasLevel then
            rangeTexts[2]:SetPoint("TOP", rangeTexts[1], "BOTTOM", 0, -4)
        else
            rangeTexts[2]:SetPoint("TOP", firstAnchor, "BOTTOM", 0, firstOffset)
        end
        anchorDescription, anchorLevel = hasDescription, hasLevel
    end
end

--- Enhances only the active world map's currently selected area-name label.
local function UpdateLabel(self)
    if self ~= label then
        return
    end
    replacedTitle = nil
    if not ErzbaroneUISettings.worldMapLevels or not self.dataProvider then
        SetText(nil)
        return
    end

    -- POIs and other higher-priority labels must retain Blizzard's presentation.
    local area = self.labelInfoByType[MAP_AREA_LABEL_TYPE.AREA_NAME]
    if not area or not area.name or self:GetHighestPriorityLabelInfo() ~= area then
        SetText(nil)
        return
    end

    local map = self.dataProvider:GetMap()
    if map ~= WorldMapFrame or not map:IsCanvasMouseFocus() then
        SetText(nil)
        return
    end

    local mapID = map:GetMapID()
    if not mapID then
        SetText(nil)
        return
    end
    -- Follow the same cursor selection as Blizzard's area-label provider.
    local x, y
    if InputUtil.IsGamepadUIEnabled() and (map:HasGamepadCursorInput() or not map:IsCanvasMouseFocusOrPinFocus()) then
        x, y = map:GetNormalizedGamepadCursorPosition()
    else
        x, y = map:GetNormalizedCursorPosition()
    end
    if not x or not y then
        SetText(nil)
        return
    end

    -- A zone map may report only an area name, so fall back to the current zone.
    local positionInfo = C_Map.GetMapInfoAtPosition(mapID, x, y)
    local currentInfo = C_Map.GetMapInfo(mapID)
    local zoneInfo = GetZoneInfo(positionInfo) or GetZoneInfo(currentInfo)
    if not zoneInfo then
        SetText(nil)
        return
    end

    local levelText, fishingText
    -- Curated quest ranges take precedence; unlisted zones use Blizzard's levels.
    local nativeMinimum, nativeMaximum = C_Map.GetMapLevels(zoneInfo.mapID)
    local questRange = questLevels[zoneInfo.mapID]
    local minimum = questRange and questRange[1] or nativeMinimum
    local maximum = questRange and questRange[2] or nativeMaximum
    if minimum and maximum and minimum > 0 and maximum > 0 then
        local levels = FormatRange(minimum, maximum)
        if positionInfo and positionInfo.mapID ~= mapID and positionInfo.name then
            if positionInfo.mapID ~= zoneInfo.mapID then
                nativeMinimum, nativeMaximum = C_Map.GetMapLevels(positionInfo.mapID)
            end
            -- Remove only Blizzard's exact native suffix, which can differ from
            -- the curated range, and leave all other title content unchanged.
            local plainName = area.name:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            if nativeMinimum and nativeMaximum and nativeMinimum > 0 and nativeMaximum > 0
                and plainName == positionInfo.name .. " (" .. FormatRange(nativeMinimum, nativeMaximum) .. ")" then
                self.Name:SetText(positionInfo.name)
                replacedTitle = positionInfo.name
            end
        end
        levelText = (LEVEL or "Level") .. ": " .. levels
    end

    local fishing = fishingLevels[zoneInfo.mapID]
    if fishing then
        local isSubzone = zoneInfo.mapID == mapID or not positionInfo or positionInfo.mapID ~= zoneInfo.mapID
        fishingText = (FISHING or "Fishing") .. ": " .. FormatRange(fishing[1], fishing[2])
        -- The table describes the parent zone, not every individual water body.
        if isSubzone then
            fishingText = fishingText .. " (" .. (ZONE or "Zone") .. ")"
        end
    end

    if levelText or fishingText then
        local font, size, flags = self.Name:GetFont()
        local r, g, b, a = self.Name:GetTextColor()
        if not font or not size
            or (levelText and not StyleText(rangeTexts[1], font, size, flags, 0.7, r, g, b, a))
            or (fishingText and not StyleText(rangeTexts[2], font, size, flags, 0.5, r, g, b, a)) then
            if not reportedFontError then
                print("ErzbaroneUI: Could not apply the world map range font.")
                reportedFontError = true
            end
            -- Do not lose Blizzard's original range if the replacement cannot render.
            if replacedTitle then self.Name:SetText(area.name) end
            replacedTitle = nil
            SetText(nil)
            return
        end
        reportedFontError = false
        local hasDescription = self.Description:GetText() and self.Description:GetText() ~= "" or false
        AnchorRangeTexts(self, hasDescription, levelText ~= nil)
        SetText(levelText, fishingText)
    else
        SetText(nil)
    end
end

--- Finds the world map's area-label provider and hooks each label at most once.
local function Attach()
    if not WorldMapFrame or not WorldMapFrame.dataProviders then
        return
    end
    for provider in pairs(WorldMapFrame.dataProviders) do
        local candidate = provider.Label
        if candidate and candidate.dataProvider == provider and candidate.labelInfoByType
            and candidate.GetHighestPriorityLabelInfo and candidate.EvaluateLabels then
            reportedMissingProvider = false
            if candidate == label then
                return
            end
            SetText(nil)
            label = candidate
            rangeTexts = attachedLabels[label]
            anchorDescription = nil
            anchorLevel = nil
            replacedTitle = nil
            if not rangeTexts then
                rangeTexts = CreateRangeTexts(label)
                attachedLabels[label] = rangeTexts
                -- Post-hook after Blizzard chooses and renders the highest-priority label.
                hooksecurefunc(label, "EvaluateLabels", UpdateLabel)
                label:HookScript("OnHide", function(self)
                    if self == label then SetText(nil) end
                end)
            end
            return
        end
    end
    SetText(nil)
    label = nil
    rangeTexts = nil
    replacedTitle = nil
    anchorDescription = nil
    anchorLevel = nil
    if ErzbaroneUISettings.worldMapLevels and not reportedMissingProvider then
        print("ErzbaroneUI: World map area labels are unavailable; zone and fishing levels cannot be shown.")
        reportedMissingProvider = true
    end
end

--- Applies the setting and restores the native title immediately when disabled.
function ErzbaroneUI.WorldMap:Update()
    Attach()
    if label and not ErzbaroneUISettings.worldMapLevels then
        SetText(nil)
        local area = label.labelInfoByType[MAP_AREA_LABEL_TYPE.AREA_NAME]
        if replacedTitle and label.Name:GetText() == replacedTitle
            and area and label:GetHighestPriorityLabelInfo() == area then
            label.Name:SetText(area.name or "")
        end
        replacedTitle = nil
    end
end

--- Attaches on world entry or when Blizzard_WorldMap becomes available later.
function ErzbaroneUI.WorldMap:Initialize()
    if not eventFrame then
        eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("ADDON_LOADED")
        eventFrame:SetScript("OnEvent", function(_, _, name)
            if name == "Blizzard_WorldMap" then
                Attach()
            end
        end)
    end
    self:Update()
end
