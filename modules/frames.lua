if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Frames = {}

function ErzbaroneUI.Frames:Initialize()
    ErzbaroneUI.Frames:CenterFrames()
    ErzbaroneUI.Frames:ReplacePlayerFrame()
end

function ErzbaroneUI.Frames:CenterFrames()
    PlayerFrame:ClearAllPoints()
    PlayerFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", -300, 150)

    TargetFrame:ClearAllPoints()
    TargetFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 300, 150)
end

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

            targetFrameHealthBar:HookScript("OnValueChanged", function(self, value)
                ErzbaroneUI.Frames:UpdateTargetHealthColor()
            end)
        end
    end
end

function ErzbaroneUI.Frames:UpdatePlayerHealthColor()
    local _, playerClass = UnitClass("player")
    local color = RAID_CLASS_COLORS[playerClass]

    local playerFrameHealthBar = _G["PlayerFrameHealthBar"]
    if playerFrameHealthBar then
        playerFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b)
    end
end

function ErzbaroneUI.Frames:UpdateTargetHealthColor()
    local _, targetClass = UnitClass("target")
    local color = RAID_CLASS_COLORS[targetClass]

    local targetFrameHealthBar = _G["TargetFrameHealthBar"]
    if targetFrameHealthBar then
        targetFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b)
    end
end
