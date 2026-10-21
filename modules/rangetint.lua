if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.RangeTint = {
    Color = { 1.0, 0.2, 0.2 },
}

--- Restores the icon colour Blizzard would show (mirrors ActionBarActionButtonMixin:UpdateUsable).
local function RestoreIconColor(button)
    local isUsable, notEnoughMana = C_ActionBar.IsUsableAction(button.action)
    if isUsable then
        button.icon:SetVertexColor(1.0, 1.0, 1.0)
    elseif notEnoughMana then
        button.icon:SetVertexColor(0.5, 0.5, 1.0)
    else
        button.icon:SetVertexColor(0.4, 0.4, 0.4)
    end
end

--- Applies or removes the red out of range tint on a single button.
local function ApplyTint(button)
    if not button.icon or not button.action then
        return
    end

    -- The range state belongs to the action it was reported for; drop it once the button shows another action
    if button.ErzbaroneUIRangeAction ~= button.action then
        button.ErzbaroneUIOutOfRange = nil
    end

    if ErzbaroneUISettings.rangeTint and button.ErzbaroneUIOutOfRange then
        button.icon:SetVertexColor(unpack(ErzbaroneUI.RangeTint.Color))
        button.ErzbaroneUITinted = true
    elseif button.ErzbaroneUITinted then
        button.ErzbaroneUITinted = nil
        RestoreIconColor(button)
    end
end

--- Re-applies the tint on all action buttons, e.g. after toggling the setting.
function ErzbaroneUI.RangeTint:Update()
    ErzbaroneUI.Utils:ForEachActionButton(ApplyTint)
end

--- Hooks Blizzard's range indicator and usable updates to tint the whole button icon.
function ErzbaroneUI.RangeTint:Initialize()
    if self.Initialized or not ActionButton_UpdateRangeIndicator then
        return
    end
    self.Initialized = true

    hooksecurefunc("ActionButton_UpdateRangeIndicator", function(button, checksRange, inRange)
        -- Shared with the pet bar, which manages its icon colours differently
        if not button.UpdateUsable then
            return
        end

        button.ErzbaroneUIOutOfRange = checksRange and not inRange
        button.ErzbaroneUIRangeAction = button.action
        ApplyTint(button)
    end)

    -- Blizzard resets the icon colour whenever usability changes, so re-apply the tint afterwards
    ErzbaroneUI.Utils:ForEachActionButton(function(button)
        if button.UpdateUsable then
            hooksecurefunc(button, "UpdateUsable", ApplyTint)
        end
    end)
end
