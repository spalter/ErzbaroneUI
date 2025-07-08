if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Chat = {}

-- Initializes the chat modifications.
function ErzbaroneUI.Chat:Initialize()
    ErzbaroneUI.Chat:Setup()
end

-- Sets up the chat frame buttons to be hidden by default and shown on mouseover.
function ErzbaroneUI.Chat:Setup()
    local buttonNames = {
        "ChatFrameChannelButton",
        "FriendsMicroButton",
        "ChatFrameMenuButton",
        "ChatFrame1ButtonFrameUpButton",
        "ChatFrame1ButtonFrameDownButton",
        "ChatFrame1ButtonFrameBottomButton",
    }

    for _, btn in ipairs(buttonNames) do
        local button = _G[btn]
        if button then button:SetAlpha(0) end
    end

    local anchor = ChatFrame1ButtonFrame
    anchor:EnableMouse(true)
    anchor:SetScript("OnEnter", function()
        for _, btn in ipairs(buttonNames) do
            local button = _G[btn]
            if button then
                button:SetAlpha(1)
            end
        end
    end)
    anchor:SetScript("OnLeave", function()
        for _, btn in ipairs(buttonNames) do
            local button = _G[btn]
            if button then
                button:SetAlpha(0)
            end
        end
    end)

    for _, btn in ipairs(buttonNames) do
        local button = _G[btn]
        if button then
            button:EnableMouse(true)
            button:SetScript("OnEnter", function()
                for _, b in ipairs(buttonNames) do
                    local button = _G[b]
                    if button then
                        button:SetAlpha(1)
                    end
                end
            end)
            button:SetScript("OnLeave", function()
                for _, b in ipairs(buttonNames) do
                    local button = _G[b]
                    if button then
                        button:SetAlpha(0)
                    end
                end
            end)
        end
    end
end
