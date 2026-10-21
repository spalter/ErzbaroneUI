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
end

--- Applies the setting and catches chat windows and buttons created later on.
function ErzbaroneUI.Chat:Initialize()
    if not self.Initialized then
        self.Initialized = true

        if FCF_OpenTemporaryWindow then
            hooksecurefunc("FCF_OpenTemporaryWindow", function()
                ErzbaroneUI.Chat:Update()
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
end
