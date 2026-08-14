local addonName, ns = ...

local BlizzardUI = {}
ns.BlizzardUI = BlizzardUI

local LOCK_ICON_TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\Assets\\LockIcon.png"
local LOCK_ICON_SIZE = 24
local DELETE_ITEM_POPUPS = {
    "DELETE_ITEM",
    "DELETE_QUEST_ITEM",
    "DELETE_GOOD_ITEM",
    "DELETE_GOOD_QUEST_ITEM",
}

local function isPendingDelete(itemGUID)
    local cursorItem = C_Cursor.GetCursorItem()
    if not cursorItem or C_Item.GetItemGUID(cursorItem) ~= itemGUID then
        return false
    end

    for _, popupName in ipairs(DELETE_ITEM_POPUPS) do
        if StaticPopup_Visible(popupName) then
            return true
        end
    end

    return false
end

local function cancelPendingDelete()
    ClearCursor()
    for _, popupName in ipairs(DELETE_ITEM_POPUPS) do
        StaticPopup_Hide(popupName)
    end
end

local function getLockIcon(button)
    if button.JustItemLockerLockIcon then
        return button.JustItemLockerLockIcon
    end

    local icon = button:CreateTexture(nil, "OVERLAY", nil, 7)
    icon:SetTexture(LOCK_ICON_TEXTURE)
    icon:SetSize(LOCK_ICON_SIZE, LOCK_ICON_SIZE)
    icon:SetPoint("TOPRIGHT", button, "TOPRIGHT", -1, -1)
    icon:Hide()

    button.JustItemLockerLockIcon = icon
    return icon
end

local function updateLockIcon(button, itemLocation)
    local itemGUID = itemLocation and itemLocation:IsValid()
        and C_Item.GetItemGUID(itemLocation)
    getLockIcon(button):SetShown(ns.LockStore:IsManaged(itemGUID))
end

local function updateBagItemLockIcon(button)
    local itemLocation = ItemLocation:CreateFromBagAndSlot(button:GetBagID(), button:GetID())
    updateLockIcon(button, itemLocation)
end

local function updateEquippedItemLockIcon(button)
    local itemLocation = ItemLocation:CreateFromEquipmentSlot(button:GetID())
    updateLockIcon(button, itemLocation)
end

local function isLockClick(button)
    return button == "LeftButton"
        and IsAltKeyDown()
        and not IsControlKeyDown()
        and not IsShiftKeyDown()
end

local function toggleBagItem(button, mouseButton)
    if not isLockClick(mouseButton) then
        return
    end

    local itemLocation = ItemLocation:CreateFromBagAndSlot(button:GetBagID(), button:GetID())
    if itemLocation:IsValid() then
        local itemGUID = C_Item.GetItemGUID(itemLocation)
        local wasManaged = ns.LockStore:IsManaged(itemGUID)
        local shouldCancelDelete = not wasManaged and isPendingDelete(itemGUID)

        if ns.LockStore:Toggle(itemLocation) and shouldCancelDelete then
            cancelPendingDelete()
        end

        updateLockIcon(button, itemLocation)
    end
end

local function toggleEquippedItem(button, mouseButton)
    if not isLockClick(mouseButton) then
        return
    end

    local itemLocation = ItemLocation:CreateFromEquipmentSlot(button:GetID())
    if itemLocation:IsValid() then
        ns.LockStore:Toggle(itemLocation)
        updateLockIcon(button, itemLocation)
    end
end

local function clearManagedAuctionItem(frame, itemLocation)
    local itemGUID = itemLocation and itemLocation:IsValid()
        and C_Item.GetItemGUID(itemLocation)
    if ns.LockStore:IsManaged(itemGUID) then
        frame:ClearPostItem()
    end
end

function BlizzardUI:InitializeAuctionHouse()
    if self.auctionHouseInitialized then
        return true
    end

    local frame = _G.AuctionHouseFrame
    if not frame
        or type(frame.SetPostItem) ~= "function"
        or type(frame.ClearPostItem) ~= "function" then
        return false
    end

    self.auctionHouseInitialized = true
    hooksecurefunc(frame, "SetPostItem", clearManagedAuctionItem)
    return true
end

function BlizzardUI:Initialize()
    ns.EquipmentSets:Initialize()
    ns.BagSorting:Initialize()
    ns.MerchantSelling:Initialize()
    self:InitializeAuctionHouse()

    if self.initialized then
        return true
    end

    if type(ContainerFrameItemButtonMixin) ~= "table"
        or type(ContainerFrameItemButtonMixin.OnModifiedClick) ~= "function"
        or type(PaperDollItemSlotButton_OnModifiedClick) ~= "function" then
        return false
    end

    self.initialized = true

    hooksecurefunc(ContainerFrameItemButtonMixin, "OnModifiedClick", toggleBagItem)
    hooksecurefunc(ContainerFrameItemButtonMixin, "UpdateCooldown", updateBagItemLockIcon)
    hooksecurefunc("PaperDollItemSlotButton_OnModifiedClick", toggleEquippedItem)
    hooksecurefunc("PaperDollItemSlotButton_Update", updateEquippedItemLockIcon)
    return true
end
