if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Castbar = {}
ErzbaroneUI.Castbar.frame = nil
ErzbaroneUI.Castbar.statusBar = nil
ErzbaroneUI.Castbar.text = nil
ErzbaroneUI.Castbar.spark = nil

--- Initializes the castbar for the target frame.
function ErzbaroneUI.Castbar.Initialize()
    if ErzbaroneUISettings.targetCastbar then
        local targetFrame = _G["TargetFrame"]
        if not targetFrame then return end

        local frame = CreateFrame("Frame", "ErzbaroneUITargetCastbarFrame", targetFrame)
        frame:SetSize(200, 50)
        frame:SetPoint("LEFT", targetFrame, "LEFT", 8, -8)
        frame.texture = frame:CreateTexture(nil, "BACKGROUND")
        ErzbaroneUI.Castbar.frame = frame

        local sb = CreateFrame("StatusBar", nil, ErzbaroneUI.Castbar.frame)
        sb:SetFrameStrata("LOW")
        sb:SetFrameLevel(5)
        sb:SetSize(114, 8)
        sb:SetPoint("LEFT", ErzbaroneUI.Castbar.frame, "LEFT", 0, 0)
        sb:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
        sb:SetStatusBarColor(0.9, 0.7, 0.1)
        sb:SetMinMaxValues(0, 100)
        sb:SetValue(0)

        local sbSpark = sb:CreateTexture(nil, "OVERLAY")
        sbSpark:SetSize(16, 16)
        sbSpark:SetPoint("CENTER", sb:GetStatusBarTexture(), "RIGHT", 0, 0)
        sbSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        sbSpark:SetBlendMode("ADD")
        sbSpark:SetAlpha(0.8)
        ErzbaroneUI.Castbar.spark = sbSpark

        local sbText = sb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sbText:SetPoint("CENTER", sb, "CENTER", 0, 0)
        sbText:SetTextColor(1, 1, 1)
        sbText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        sbText:SetText("")
        ErzbaroneUI.Castbar.text = sbText

        ErzbaroneUI.Castbar.statusBar = sb
        ErzbaroneUI.Castbar:Hide()

        targetFrame:SetScript("OnShow", function()
            if ErzbaroneUISettings.targetCastbar then
                ErzbaroneUI.Castbar:Show()
            end
        end)
        targetFrame:SetScript("OnHide", function()
            ErzbaroneUI.Castbar:Hide()
        end)
    end
end

--- Shows the castbar and starts updating it.
function ErzbaroneUI.Castbar:Show()
    if ErzbaroneUI.Castbar.frame then
        ErzbaroneUI.Castbar.frame:Show()
        ErzbaroneUI.Castbar.frame:SetScript("OnUpdate", function()
            ErzbaroneUI.Castbar:Update()
        end)
    end
end

--- Hides the castbar and stops updating it.
function ErzbaroneUI.Castbar:Hide()
    if ErzbaroneUI.Castbar.frame then
        ErzbaroneUI.Castbar.frame:Hide()
        ErzbaroneUI.Castbar.frame:SetScript("OnUpdate", nil)
    end
end

--- Updates the castbar with the current spell being cast by the target.
--- If no spell is being cast, it resets the castbar.
function ErzbaroneUI.Castbar:Update()
    local spell, text, _, startTimeMs, endTimeMS = UnitCastingInfo("target")
    local sb = ErzbaroneUI.Castbar.statusBar
    local sbText = ErzbaroneUI.Castbar.text
    if spell then
        local timeToFinish = endTimeMS / 1000 - GetTime()
        local duration = (endTimeMS - startTimeMs) / 1000
        sb:SetMinMaxValues(0, duration)
        sb:SetValue(duration - timeToFinish)
        sbText:SetText(text)
        ErzbaroneUI.Castbar.spark:Show()
    else
        sb:SetValue(0)
        sbText:SetText("")
        ErzbaroneUI.Castbar.spark:Hide()
        return
    end
end
