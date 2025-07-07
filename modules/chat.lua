if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Chat = {}

function ErzbaroneUI.Chat:Initialize()
    print("ErzbaroneUI Chat Module Initialized")
    ErzbaroneUI.Chat:Setup()
end

function ErzbaroneUI.Chat:Setup()
    local buttons = {
        ChatFrameChannelButton,
        FriendsMicroButton,
        ChatFrameMenuButton,
        ChatFrame1ButtonFrameUpButton,
        ChatFrame1ButtonFrameDownButton,
        ChatFrame1ButtonFrameBottomButton,
    }

    for _, btn in ipairs(buttons) do
        if btn then btn:SetAlpha(0) end
    end

    local anchor = ChatFrame1ButtonFrame
    anchor:EnableMouse(true)
    anchor:SetScript("OnEnter", function()
        for _, btn in ipairs(buttons) do if btn then btn:SetAlpha(1) end end
    end)
    anchor:SetScript("OnLeave", function()
        for _, btn in ipairs(buttons) do if btn then btn:SetAlpha(0) end end
    end)

    for _, btn in ipairs(buttons) do
        if btn then
            btn:EnableMouse(true)
            btn:SetScript("OnEnter", function()
                for _, b in ipairs(buttons) do if b then b:SetAlpha(1) end end
            end)
            btn:SetScript("OnLeave", function()
                for _, b in ipairs(buttons) do if b then b:SetAlpha(0) end end
            end)
        end
    end
end
