if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Bars = {}

-- Initializes the bar modifications.
function ErzbaroneUI.Bars:Initialize()
    if ErzbaroneUISettings and ErzbaroneUISettings.hideVerticalBars then
        ErzbaroneUI.Bars:HideVerticalBars()
    else
        ErzbaroneUI.Bars:ShowVerticalBars()
    end
end

-- Sets up mouseover functionality for the vertical bars (MultiBarRight and MultiBarLeft).
-- This function hides the bars by default and shows them when the mouse hovers over them.
function ErzbaroneUI.Bars:HideVerticalBars()
    local bars = { MultiBarRight, MultiBarLeft }

    for _, bar in pairs(bars) do
        if bar then
            bar:SetAlpha(0)

            bar:SetScript("OnEnter", function(self)
                MultiBarRight:SetAlpha(1)
                MultiBarLeft:SetAlpha(1)
            end)

            bar:SetScript("OnLeave", function(self)
                MultiBarRight:SetAlpha(0)
                MultiBarLeft:SetAlpha(0)
            end)
        end
    end

    local barNames = { "MultiBarRight", "MultiBarLeft" }
    for _, barName in pairs(barNames) do
        for i = 1, 12 do
            local button = _G[barName .. "Button" .. i]
            if button then
                button:SetScript("OnEnter", function(self)
                    MultiBarRight:SetAlpha(1)
                    MultiBarLeft:SetAlpha(1)
                end)
                button:SetScript("OnLeave", function(self)
                    MultiBarRight:SetAlpha(0)
                    MultiBarLeft:SetAlpha(0)
                end)
            end
        end
    end
end

function ErzbaroneUI.Bars:ShowVerticalBars()
    local bars = { MultiBarRight, MultiBarLeft }

    for _, bar in pairs(bars) do
        if bar then
            bar:SetAlpha(1)
            bar:SetScript("OnEnter", nil)
            bar:SetScript("OnLeave", nil)
        end
    end

    local barNames = { "MultiBarRight", "MultiBarLeft" }
    for _, barName in pairs(barNames) do
        for i = 1, 12 do
            local button = _G[barName .. "Button" .. i]
            if button then
                button:SetScript("OnEnter", nil)
                button:SetScript("OnLeave", nil)
            end
        end
    end
end
