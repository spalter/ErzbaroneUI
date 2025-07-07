if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Frames = {}

function ErzbaroneUI.Frames:Initialize()
    print("ErzbaroneUI Frames Module Initialized")
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
    if PlayerFrameTexture then
        PlayerFrameTexture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame")
    end

    if PlayerFrameHealthBar then
        PlayerFrameHealthBar:ClearAllPoints()
        C_Timer.After(0.1, function()
            PlayerFrameHealthBar:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 106, -22)
            PlayerFrameHealthBar:SetHeight(30)
            PlayerFrameHealthBarText:ClearAllPoints()
            PlayerFrameHealthBarText:SetPoint("CENTER", PlayerFrameHealthBar, "CENTER", 0, -6)
            ErzbaroneUI.Frames:UpdatePlayerHealthColor()
        end)

        PlayerFrameHealthBar:HookScript("OnValueChanged", function(self, value)
            ErzbaroneUI.Frames:UpdatePlayerHealthColor()
        end)
    end


    if PlayerStatusTexture then
        PlayerStatusTexture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\UI-Player-Status")
    end
end

function ErzbaroneUI.Frames:ReplaceTargetFrame()
    if TargetFrame then
        local classification = UnitClassification("target")

        if classification == "elite" then
            TargetFrameTextureFrameTexture:SetTexture(
                "Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame-Elite")
        elseif classification == "rareelite" then
            TargetFrameTextureFrameTexture:SetTexture(
                "Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame-RareElite")
        elseif classification == "rare" then
            TargetFrameTextureFrameTexture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame-Rare")
        elseif classification == "worldboss" then
            TargetFrameTextureFrameTexture:SetTexture(
                "Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame-WorldBoss")
        else
            TargetFrameTextureFrameTexture:SetTexture("Interface\\AddOns\\ErzbaroneUI\\textures\\UI-TargetingFrame")
        end

        TargetFrameNameBackground:SetAlpha(0)

        if TargetFrameBackground then
            TargetFrameBackground:SetHeight(42)
        end

        if TargetFrameHealthBar then
            TargetFrameHealthBar:ClearAllPoints()
            TargetFrameHealthBar:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", 6, -22)
            TargetFrameHealthBar:SetHeight(30)
            if TargetFrameHealthBarText then
                TargetFrameHealthBarText:ClearAllPoints()
                TargetFrameHealthBarText:SetPoint("CENTER", TargetFrameHealthBar, "CENTER", 0, -6)
            end
            ErzbaroneUI.Frames:UpdateTargetHealthColor()

            TargetFrameHealthBar:HookScript("OnValueChanged", function(self, value)
                ErzbaroneUI.Frames:UpdateTargetHealthColor()
            end)
        end
    end
end

function ErzbaroneUI.Frames:UpdatePlayerHealthColor()
    local _, playerClass = UnitClass("player")
    local color = RAID_CLASS_COLORS[playerClass]

    if PlayerFrameHealthBar then
        PlayerFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b)
    end
end

function ErzbaroneUI.Frames:UpdateTargetHealthColor()
    local _, targetClass = UnitClass("target")
    local color = RAID_CLASS_COLORS[targetClass]

    if TargetFrameHealthBar then
        TargetFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b)
    end
end
