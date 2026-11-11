if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Chat = {}

-- Buttons Blizzard places in the column left of the chat frame.
local CHAT_BUTTONS = {
    "ChatFrameMenuButton",
    "ChatFrameChannelButton",
    "ChatFrameToggleVoiceDeafenButton",
    "ChatFrameToggleVoiceMuteButton",
    "QuickJoinToastButton",
    "TextToSpeechButtonFrame",
}

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

local originalParents = {}

--- Moves a frame into the hidden container, so Blizzard showing it again has no visible effect.
local function HideFrame(frame)
    if not frame or originalParents[frame] then
        return
    end
    originalParents[frame] = frame:GetParent()
    frame:SetParent(hiddenParent)
end

--- Returns all chat button frames including the button column background of every chat window.
local function GetChatButtonFrames()
    local frames = {}
    for _, name in ipairs(CHAT_BUTTONS) do
        if _G[name] then
            table.insert(frames, _G[name])
        end
    end
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local buttonFrame = _G["ChatFrame" .. i .. "ButtonFrame"]
        if buttonFrame then
            table.insert(frames, buttonFrame)
        end
    end
    return frames
end

--- Hides or restores the chat buttons based on the current setting.
function ErzbaroneUI.Chat:Update()
    if ErzbaroneUISettings.hideChatButtons then
        for _, frame in ipairs(GetChatButtonFrames()) do
            HideFrame(frame)
        end
    else
        for frame, parent in pairs(originalParents) do
            frame:SetParent(parent)
        end
        originalParents = {}
    end

    ErzbaroneUI.Chat:UpdatePosition()
end

-- Distance of the chat window to the screen corner. The bottom gap leaves room for the input box below the chat.
local CORNER_OFFSET_X = 8
local CORNER_OFFSET_X_WITH_BUTTONS = 35
local CORNER_OFFSET_Y = 34

local movedToCorner = false

function ErzbaroneUI.Chat:GetCornerOffsets()
    local x = ErzbaroneUISettings.hideChatButtons and CORNER_OFFSET_X or CORNER_OFFSET_X_WITH_BUTTONS
    local bottomInset = ErzbaroneUI.MainBar and ErzbaroneUI.MainBar:GetChatBottomInset() or 0
    return x, CORNER_OFFSET_Y + bottomInset
end

-- Edit Mode replaces SetPoint/ClearAllPoints with versions that notify Edit Mode; the base versions only move the frame.
local function SetChatPoint(chatFrame, point, relativeTo, relativePoint, x, y)
    local clear = chatFrame.ClearAllPointsBase or chatFrame.ClearAllPoints
    local setPoint = chatFrame.SetPointBase or chatFrame.SetPoint
    clear(chatFrame)
    setPoint(chatFrame, point, relativeTo, relativePoint, x, y)
end

--- Moves the main chat window into the lower left corner while it is in its default Edit Mode position.
function ErzbaroneUI.Chat:UpdatePosition()
    local chatFrame = ChatFrame1
    if not chatFrame or not chatFrame.IsInDefaultPosition then
        return
    end

    local isDefault = chatFrame:IsInDefaultPosition()
    if ErzbaroneUISettings.chatToCorner and isDefault then
        local scale = chatFrame:GetScale()
        local x, y = self:GetCornerOffsets()
        SetChatPoint(chatFrame, "BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
        movedToCorner = true
    elseif movedToCorner then
        movedToCorner = false
        local anchor = isDefault and chatFrame.systemInfo and chatFrame.systemInfo.anchorInfo
        if anchor then
            local scale = chatFrame:GetScale()
            SetChatPoint(chatFrame, anchor.point, anchor.relativeTo, anchor.relativePoint,
                anchor.offsetX / scale, anchor.offsetY / scale)
        end
    end
end

--- Lowers the resting alpha of a chat tab to zero, so it only shows while the mouse is over the chat.
--- Tabs with unread whispers keep Blizzard's alerting alpha.
local function FadeChatTab(chatFrame)
    if not ErzbaroneUISettings.fadeChatTabs or not ChatFrameUtil or not ChatFrameUtil.SetTabAlphas then
        return
    end
    local chatTab = _G[chatFrame:GetName() .. "Tab"]
    if not chatTab or (ChatFrameUtil.IsTabAlerting and ChatFrameUtil.IsTabAlerting(chatTab)) then
        return
    end
    local mouseOverAlpha = ChatFrameUtil.GetTabAlphas(chatTab)
    ChatFrameUtil.SetTabAlphas(chatTab, mouseOverAlpha, 0)
    if not chatFrame.hasBeenFaded then
        chatTab:SetAlpha(0)
    end
end

--- Applies or restores the tab alphas of all chat windows.
function ErzbaroneUI.Chat:UpdateTabs()
    if not FCFTab_UpdateAlpha then
        return
    end
    for _, name in ipairs(CHAT_FRAMES or {}) do
        local chatFrame = _G[name]
        if chatFrame then
            -- Blizzard recalculates its own alphas, the hook then applies ours if enabled
            FCFTab_UpdateAlpha(chatFrame)
        end
    end
end

--- Applies the setting and catches chat windows and buttons created later on.
function ErzbaroneUI.Chat:Initialize()
    if not self.Initialized then
        self.Initialized = true

        if FCFTab_UpdateAlpha then
            hooksecurefunc("FCFTab_UpdateAlpha", FadeChatTab)
        end

        if FCF_OpenTemporaryWindow then
            hooksecurefunc("FCF_OpenTemporaryWindow", function()
                ErzbaroneUI.Chat:Update()
            end)
        end

        -- Edit Mode re-anchors the chat window whenever a layout is applied or the chat is resized
        if ChatFrame1 and ChatFrame1.ApplySystemAnchor then
            hooksecurefunc(ChatFrame1, "ApplySystemAnchor", function()
                ErzbaroneUI.Chat:UpdatePosition()
            end)
        end

        -- Some buttons live in load on demand addons (e.g. Blizzard_QuickJoin)
        local eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("ADDON_LOADED")
        eventFrame:SetScript("OnEvent", function()
            ErzbaroneUI.Chat:Update()
        end)
    end

    self:Update()
    self:UpdateTabs()
end
