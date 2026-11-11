if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Utils = {}

local ACTION_BUTTON_PREFIXES = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
    "MultiBar5Button",
    "MultiBar6Button",
    "MultiBar7Button",
    "BonusActionButton",
}

--- Calls the given function for every existing default action bar button.
function ErzbaroneUI.Utils:ForEachActionButton(callback)
    for _, prefix in ipairs(ACTION_BUTTON_PREFIXES) do
        for i = 1, NUM_ACTIONBAR_BUTTONS or 12 do
            local button = _G[prefix .. i]
            if button then
                callback(button)
            end
        end
    end
end

--- Sells poor-quality items from every bag when automatic selling is enabled.
function ErzbaroneUI.Utils:AutoSellGreyItems()
    if not ErzbaroneUISettings.autoSellGreyItems then
        return
    end

    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if itemLink and select(3, C_Item.GetItemInfo(itemLink)) == 0 then -- Check if the item is grey quality
                C_Container.UseContainerItem(bag, slot)
            end
        end
    end
end

--- Repairs all equipped items when automatic repair is enabled and available.
function ErzbaroneUI.Utils:AutoRepair()
    if not ErzbaroneUISettings.autoRepair then
        return
    end

    local canRepair = CanMerchantRepair()
    if not canRepair then
        return
    end

    local _, requiresRepair = GetRepairAllCost()
    if requiresRepair then
        RepairAllItems()
    end
end
