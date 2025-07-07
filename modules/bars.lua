if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Bars = {}

function ErzbaroneUI.Bars:Initialize()
    ErzbaroneUI.Bars:SetupVerticalBarsMouseover()
end

function ErzbaroneUI.Bars:SetupVerticalBarsMouseover()
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
