if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Frames = {}
ErzbaroneUI.Frames.swingStartPosition = -8
ErzbaroneUI.Frames.swingEndPosition = 108

--- Initializes the frame modifications.
function ErzbaroneUI.Frames:Initialize()
    if ErzbaroneUISettings.improvedUnitFrames then
        ErzbaroneUI.Frames:CenterFrames()
        ErzbaroneUI.Frames:ReplacePlayerFrame()
        ErzbaroneUI.Frames:InitializeTargetFrameHooks()

        if ErzbaroneUISettings.swingTimer then
            ErzbaroneUI.Frames:ActivateSwingTimer()
        end

        if ErzbaroneUISettings.fiveSecondRuleTimer then
            ErzbaroneUI.Frames:ActivateFiveSecondRuleTimer()
            ErzbaroneUI.Frames:ActivateManaTickTimer()
        end
    end
end

--- Activates the improved unit frames by centering the frames,
function ErzbaroneUI.Frames.ActivateImprovedUnitFrames()
    ReloadUI()
end

--- Deactivates the improved unit frames by reloading the UI.
function ErzbaroneUI.Frames.DeactivateImprovedUnitFrames()
    ReloadUI()
end

--- Repositions the Player and Target frames to the bottom center of the screen.
function ErzbaroneUI.Frames:CenterFrames()
    PlayerFrame:ClearAllPoints()
    PlayerFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", -300, 150)

    TargetFrame:ClearAllPoints()
    TargetFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 300, 150)
end

--- Customizes the appearance of the Player frame.
--- Replaces textures, repositions the health bar, and updates colors.
function ErzbaroneUI.Frames:ReplacePlayerFrame()
    local playerFrameTexture = _G["PlayerFrameTexture"]
    if playerFrameTexture then
        playerFrameTexture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame")
    end

    local playerFrameHealthBar = _G["PlayerFrameHealthBar"]
    local playerFrameHealthBarText = _G["PlayerFrameHealthBarText"]
    if playerFrameHealthBar then
        playerFrameHealthBar:ClearAllPoints()
        C_Timer.After(0.1, function()
            playerFrameHealthBar:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 106, -22)
            playerFrameHealthBar:SetHeight(30)
            playerFrameHealthBarText:ClearAllPoints()
            playerFrameHealthBarText:SetPoint("CENTER", playerFrameHealthBar, "CENTER", 0, -6)
            ErzbaroneUI.Frames:UpdatePlayerHealthColor()
        end)

        playerFrameHealthBar:HookScript("OnValueChanged", function(self, value)
            ErzbaroneUI.Frames:UpdatePlayerHealthColor()
        end)
    end

    local playerStatusTexture = _G["PlayerStatusTexture"]
    if playerStatusTexture then
        playerStatusTexture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\UI-Player-Status")
    end
end

--- Initializes hooks for the Target frame.
--- Specifically, it hooks the health bar to update its color on value change.
function ErzbaroneUI.Frames:InitializeTargetFrameHooks()
    C_Timer.After(0.1, function()
        local targetFrameHealthBar = _G["TargetFrameHealthBar"]
        if targetFrameHealthBar then
            targetFrameHealthBar:HookScript("OnValueChanged", function(self, value)
                ErzbaroneUI.Frames:UpdateTargetHealthColor()
            end)
        end
    end)
end

--- Customizes the appearance of the Target frame.
--- Replaces textures based on classification, repositions the health bar, and updates colors.
function ErzbaroneUI.Frames:ReplaceTargetFrame()
    if TargetFrame then
        local classification = UnitClassification("target")
        local targetFrameTexture = _G["TargetFrameTextureFrameTexture"]

        if classification == "elite" then
            targetFrameTexture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame-Elite")
        elseif classification == "rareelite" then
            targetFrameTexture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame-RareElite")
        elseif classification == "rare" then
            targetFrameTexture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame-Rare")
        elseif classification == "worldboss" then
            targetFrameTexture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame-WorldBoss")
        else
            targetFrameTexture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame")
        end

        local targetFrameNameBackground = _G["TargetFrameNameBackground"]
        targetFrameNameBackground:SetAlpha(0)

        local targetFrameBackground = _G["TargetFrameBackground"]
        if targetFrameBackground then
            targetFrameBackground:SetHeight(42)
        end

        local targetFrameHealthBar = _G["TargetFrameHealthBar"]
        local targetFrameHealthBarText = _G["TargetFrameHealthBarText"]
        if targetFrameHealthBar then
            targetFrameHealthBar:ClearAllPoints()
            targetFrameHealthBar:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", 6, -22)
            targetFrameHealthBar:SetHeight(30)
            if targetFrameHealthBarText then
                targetFrameHealthBarText:ClearAllPoints()
                targetFrameHealthBarText:SetPoint("CENTER", targetFrameHealthBar, "CENTER", 0, -6)
            end
            ErzbaroneUI.Frames:UpdateTargetHealthColor()
        end
    end
end

--- Updates the Player's health bar color to match their class color.
function ErzbaroneUI.Frames:UpdatePlayerHealthColor()
    if not ErzbaroneUISettings.unitClassColors then return end

    local _, playerClass = UnitClass("player")
    local color = RAID_CLASS_COLORS[playerClass]

    local playerFrameHealthBar = _G["PlayerFrameHealthBar"]
    if playerFrameHealthBar and color ~= nil then
        playerFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b)
    end
end

--- Updates the Target's health bar color to match their class color.
function ErzbaroneUI.Frames:UpdateTargetHealthColor()
    if not ErzbaroneUISettings.unitClassColors then return end

    local _, targetClass = UnitClass("target")
    local color = RAID_CLASS_COLORS[targetClass]

    local targetFrameHealthBar = _G["TargetFrameHealthBar"]
    if targetFrameHealthBar and color ~= nil then
        targetFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b)
    end
end

--- Updates both Player and Target health bar colors to match their respective class colors.
function ErzbaroneUI.Frames:UpdateBothHealthColors()
    ErzbaroneUI.Frames:UpdatePlayerHealthColor()
    ErzbaroneUI.Frames:UpdateTargetHealthColor()
end

--- Resets the Player and Target frames to their default health bar colors.
function ErzbaroneUI.Frames:SetDefaultHealthBarColor()
    local playerFrameHealthBar = _G["PlayerFrameHealthBar"]
    if playerFrameHealthBar then
        playerFrameHealthBar:SetStatusBarColor(0, 1, 0) -- Default to green
    end

    local targetFrameHealthBar = _G["TargetFrameHealthBar"]
    if targetFrameHealthBar then
        targetFrameHealthBar:SetStatusBarColor(0, 1, 0) -- Default to green
    end
end

--- Activates the swing timer for the player.
--- This timer shows a visual indicator for the player's swing timer.
function ErzbaroneUI.Frames:ActivateSwingTimer()
    local playerFrame = _G["PlayerFrame"]
    local swingTimerSparkFrame = CreateFrame("Frame", "ErzbaroneUISwingTimer", playerFrame)
    swingTimerSparkFrame:SetPoint("BOTTOM", playerFrame, "BOTTOM", -8, -4)
    swingTimerSparkFrame:SetFrameStrata("DIALOG")
    swingTimerSparkFrame:SetFrameLevel(0)
    swingTimerSparkFrame.texture = swingTimerSparkFrame:CreateTexture(nil, "BACKGROUND")
    swingTimerSparkFrame:SetSize(70, 70)
    swingTimerSparkFrame.texture:SetAllPoints()
    swingTimerSparkFrame.texture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\SwingTimerSpark")
    swingTimerSparkFrame.texture:SetVertexColor(1.0, 0.8, 0.4) -- Orange color

    swingTimerSparkFrame.startTime = 0
    swingTimerSparkFrame.swingDuration = 0
    swingTimerSparkFrame:Hide()

    -- Swing Timer Movement
    swingTimerSparkFrame:SetScript("OnUpdate", function(self, elapsed)
        if self.startTime == 0 then return end

        local timePassed = GetTime() - self.startTime
        local progress = timePassed / self.swingDuration

        if progress >= 1 then
            self.startTime = 0
            self:Hide()
            return
        end

        local newX = ErzbaroneUI.Frames.swingStartPosition +
            (ErzbaroneUI.Frames.swingEndPosition - ErzbaroneUI.Frames.swingStartPosition) * progress
        self:ClearAllPoints()
        self:SetPoint("BOTTOM", playerFrame, "BOTTOM", newX, -4)
    end)

    local swingTimerEventFrame = CreateFrame("Frame")
    swingTimerEventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    swingTimerEventFrame:SetScript("OnEvent", function(self, event, ...)
        local _, subevent, _, sourceGUID = CombatLogGetCurrentEventInfo()

        -- Melee Attacks
        if sourceGUID == UnitGUID("player") and (subevent == "SWING_DAMAGE" or subevent == "SWING_MISSED") then
            local mainHandSpeed = UnitAttackSpeed("player")
            if mainHandSpeed then
                swingTimerSparkFrame.startTime = GetTime()
                swingTimerSparkFrame.swingDuration = mainHandSpeed
                swingTimerSparkFrame:Show()
            end
        end

        -- Ranged Attacks
        if sourceGUID == UnitGUID("player") and (subevent == "RANGE_DAMAGE" or subevent == "RANGE_MISSED") then
            local rangedSpeed = UnitRangedDamage("player")

            if rangedSpeed then
                swingTimerSparkFrame.startTime = GetTime()
                swingTimerSparkFrame.swingDuration = rangedSpeed
                swingTimerSparkFrame:Show()
            end
        end
    end)
end

--- Activates the Five Second Rule timer for the player.
--- This timer shows a visual indicator for the Five Second Rule.
function ErzbaroneUI.Frames:ActivateFiveSecondRuleTimer()
    local playerFrame = _G["PlayerFrame"]

    if UnitPowerType("player") ~= 0 then return end
    local playerClass = select(2, UnitClass("player"))
    if playerClass ~= "MAGE" and playerClass ~= "PRIEST" and playerClass ~= "WARLOCK" then
        return
    end

    local fiveSecondRuleFrame = CreateFrame("Frame", "ErzbaroneUIFiveSecondRule", playerFrame)
    fiveSecondRuleFrame:SetPoint("BOTTOM", playerFrame, "BOTTOM", -8, -4)
    fiveSecondRuleFrame:SetSize(70, 70)
    fiveSecondRuleFrame:SetFrameStrata("DIALOG")
    fiveSecondRuleFrame.texture = fiveSecondRuleFrame:CreateTexture(nil, "BACKGROUND")
    fiveSecondRuleFrame.texture:SetAllPoints()
    fiveSecondRuleFrame.texture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\SwingTimerSpark")

    fiveSecondRuleFrame.startTime = 0
    fiveSecondRuleFrame:Hide()

    fiveSecondRuleFrame:SetScript("OnUpdate", function(self, elapsed)
        if self.startTime == 0 then return end

        local timePassed = GetTime() - self.startTime
        if timePassed >= 5 then
            self.startTime = 0
            self:Hide()
            return
        end

        local progress = timePassed / 5
        local newX = ErzbaroneUI.Frames.swingStartPosition +
            (ErzbaroneUI.Frames.swingEndPosition - ErzbaroneUI.Frames.swingStartPosition) * progress
        self:ClearAllPoints()
        self:SetPoint("BOTTOM", playerFrame, "BOTTOM", newX, -4)
    end)

    local fivesecondruleEventFrame = CreateFrame("Frame")
    fivesecondruleEventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    fivesecondruleEventFrame:SetScript("OnEvent", function(self, event, unit, spellName, spellID)
        print("Five Second Rule Event:", event, unit, spellName, spellID)
        if unit == "player" and spellID ~= 5019 then
            fiveSecondRuleFrame.startTime = GetTime()
            fiveSecondRuleFrame:Show()
        end
    end)
end

--- Activates the mana tick timer for the player.
--- This timer shows a visual indicator for mana regeneration ticks.
--- Based on the 5-second rule, it updates the position of the indicator
function ErzbaroneUI.Frames:ActivateManaTickTimer()
    local playerFrame = _G["PlayerFrame"]
    if UnitPowerType("player") ~= 0 then return end
    local playerClass = select(2, UnitClass("player"))
    if playerClass ~= "MAGE" and playerClass ~= "PRIEST" and playerClass ~= "WARLOCK" then
        return
    end

    local manaTickFrame = CreateFrame("Frame", "ErzbaroneUIManaTickTimer", playerFrame)
    manaTickFrame:SetPoint("BOTTOM", playerFrame, "BOTTOM", ErzbaroneUI.Frames.swingEndPosition, -4)
    manaTickFrame:SetSize(70, 70)
    manaTickFrame:SetFrameStrata("DIALOG")
    manaTickFrame.texture = manaTickFrame:CreateTexture(nil, "BACKGROUND")
    manaTickFrame.texture:SetAllPoints()
    manaTickFrame.texture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\SwingTimerSpark")
    manaTickFrame.texture:SetVertexColor(0.5, 0.8, 1.0)

    manaTickFrame.startTime = 0
    manaTickFrame:Hide()

    manaTickFrame:SetScript("OnUpdate", function(self, elapsed)
        if self.startTime == 0 then return end

        local timePassed = GetTime() - self.startTime
        if timePassed >= 2 then
            self.startTime = GetTime()
            timePassed = 0
        end

        local progress = timePassed / 2
        local newX = ErzbaroneUI.Frames.swingEndPosition -
            (ErzbaroneUI.Frames.swingEndPosition - ErzbaroneUI.Frames.swingStartPosition) * progress
        self:ClearAllPoints()
        self:SetPoint("BOTTOM", playerFrame, "BOTTOM", newX, -4)
    end)

    local manaEventFrame = CreateFrame("Frame")
    manaEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    manaEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    manaEventFrame:RegisterEvent("UNIT_POWER_UPDATE")
    manaEventFrame:SetScript("OnEvent", function(self, event, unit)
        local fiveSecondRuleFrame = _G["ErzbaroneUIFiveSecondRule"]
        if not fiveSecondRuleFrame then return end

        local inFiveSecondRule = fiveSecondRuleFrame:IsShown()
        if inFiveSecondRule then
            manaTickFrame.startTime = 0
            manaTickFrame:Hide()
            return
        end

        if event == "PLAYER_REGEN_ENABLED" then
            local currentMana = UnitPower("player")
            local maxMana = UnitPowerMax("player")
            if currentMana < maxMana then
                manaTickFrame.startTime = GetTime()
                manaTickFrame:Show()
            end
        elseif event == "PLAYER_REGEN_DISABLED" then
            manaTickFrame.startTime = 0
            manaTickFrame:Hide()
        elseif event == "UNIT_POWER_UPDATE" and unit == "player" then
            local currentMana = UnitPower("player")
            local maxMana = UnitPowerMax("player")
            if currentMana < maxMana then
                manaTickFrame.startTime = GetTime()
                manaTickFrame:Show()
            else
                manaTickFrame.startTime = 0
                manaTickFrame:Hide()
            end
        end
    end)
end
