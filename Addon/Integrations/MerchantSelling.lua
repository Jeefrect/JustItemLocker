local _, ns = ...

local MerchantSelling = {}
ns.MerchantSelling = MerchantSelling

local FIRST_PLAYER_BAG = Enum.BagIndex.Backpack
local LAST_PLAYER_BAG = Enum.BagIndex.ReagentBag
local JUNK_QUALITY = Enum.ItemQuality.Poor

local function forEachBagItem(callback)
    for bagID = FIRST_PLAYER_BAG, LAST_PLAYER_BAG do
        for slotIndex = 1, C_Container.GetContainerNumSlots(bagID) do
            local itemInfo = C_Container.GetContainerItemInfo(bagID, slotIndex)
            if itemInfo then
                local itemLocation = ItemLocation:CreateFromBagAndSlot(bagID, slotIndex)
                callback(itemLocation, itemInfo, bagID, slotIndex)
            end
        end
    end
end

local function isSellableJunk(itemInfo)
    return itemInfo.quality == JUNK_QUALITY and not itemInfo.hasNoValue
end

local function hasManagedJunk()
    local found = false
    forEachBagItem(function(itemLocation, itemInfo)
        if found or not isSellableJunk(itemInfo) then
            return
        end

        found = ns.LockStore:IsManaged(C_Item.GetItemGUID(itemLocation))
    end)
    return found
end

local function sellUnmanagedJunk()
    forEachBagItem(function(itemLocation, itemInfo, bagID, slotIndex)
        if not isSellableJunk(itemInfo) then
            return
        end

        local itemGUID = C_Item.GetItemGUID(itemLocation)
        if not ns.LockStore:IsManaged(itemGUID) and not itemInfo.isLocked then
            C_Container.UseContainerItem(bagID, slotIndex)
        end
    end)
end

local function replaceSellAllConfirmation()
    if not hasManagedJunk() then
        return
    end

    local _, dialog = StaticPopup_Visible("GENERIC_CONFIRMATION")
    if not dialog or not dialog.data or dialog.data.text ~= SELL_ALL_JUNK_ITEMS_POPUP then
        return
    end

    StaticPopup_Hide("GENERIC_CONFIRMATION")
    StaticPopup_ShowCustomGenericConfirmation({
        text = SELL_ALL_JUNK_ITEMS_POPUP,
        callback = sellUnmanagedJunk,
    })
end

function MerchantSelling:Initialize()
    if self.initialized or not MerchantSellAllJunkButton then
        return self.initialized or false
    end

    self.initialized = true
    MerchantSellAllJunkButton:HookScript("OnClick", replaceSellAllConfirmation)
    return true
end
