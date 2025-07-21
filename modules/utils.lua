if not ErzbaroneUI then
    ErzbaroneUI = {}
end

ErzbaroneUI.Utils = {}

-- function to auto sell grey items
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

-- function to auto repair items
function ErzbaroneUI.Utils:AutoRepair()
    if not ErzbaroneUISettings.autoRepair then
        return
    end

    local canRepair = CanMerchantRepair()
    if not canRepair then
        return
    end

    local cost, requiresRepair = GetRepairAllCost()
    if requiresRepair then
        RepairAllItems()
    end
end
