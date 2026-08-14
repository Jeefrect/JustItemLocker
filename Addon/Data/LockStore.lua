local _, ns = ...

local LockStore = {}
ns.LockStore = LockStore

local SCHEMA_VERSION = 1
local FIRST_PLAYER_BAG = Enum.BagIndex.Backpack
local LAST_PLAYER_BAG = Enum.BagIndex.ReagentBag

local db
local suspensionCounts = {}

local function isSupportedLocation(itemLocation)
    if not itemLocation or not itemLocation:HasAnyLocation() or not itemLocation:IsValid() then
        return false
    end

    if itemLocation:IsEquipmentSlot() then
        return true
    end

    if itemLocation:IsBagAndSlot() then
        local bagID = itemLocation:GetBagAndSlot()
        return bagID >= FIRST_PLAYER_BAG and bagID <= LAST_PLAYER_BAG
    end

    return false
end

local function getDisplayLink(itemLocation, record)
    local itemLink = itemLocation and C_Item.GetItemLink(itemLocation)
    return itemLink or (record and record.itemLink) or UNKNOWN
end

local function getManagedLocation(itemGUID)
    local itemLocation = C_Item.GetItemLocation(itemGUID)
    if not isSupportedLocation(itemLocation) then
        return nil
    end

    return itemLocation
end

function LockStore:Initialize()
    if type(JustItemLockerDB) ~= "table" then
        JustItemLockerDB = {}
    end

    if JustItemLockerDB.schemaVersion ~= SCHEMA_VERSION then
        JustItemLockerDB.schemaVersion = SCHEMA_VERSION
    end

    if type(JustItemLockerDB.lockedItems) ~= "table" then
        JustItemLockerDB.lockedItems = {}
    end

    db = JustItemLockerDB
end

function LockStore:IsManaged(itemGUID)
    return itemGUID and db.lockedItems[itemGUID] ~= nil
end

function LockStore:Lock(itemLocation)
    if not isSupportedLocation(itemLocation) then
        ns.Print("ITEM_UNAVAILABLE")
        return false
    end

    local itemGUID = C_Item.GetItemGUID(itemLocation)
    if not itemGUID then
        ns.Print("ITEM_UNAVAILABLE")
        return false
    end

    local itemLink = getDisplayLink(itemLocation)
    db.lockedItems[itemGUID] = {
        itemLink = itemLink,
    }

    C_Item.LockItemByGUID(itemGUID)
    if not C_Item.IsLocked(itemLocation) then
        db.lockedItems[itemGUID] = nil
        ns.Print("LOCK_FAILED", itemLink)
        return false
    end

    ns.Print("ITEM_LOCKED", itemLink)
    return true
end

function LockStore:Unlock(itemLocation)
    if not isSupportedLocation(itemLocation) then
        ns.Print("ITEM_UNAVAILABLE")
        return false
    end

    local itemGUID = C_Item.GetItemGUID(itemLocation)
    local record = itemGUID and db.lockedItems[itemGUID]
    if not record then
        return false
    end

    local itemLink = getDisplayLink(itemLocation, record)

    db.lockedItems[itemGUID] = nil
    C_Item.UnlockItemByGUID(itemGUID)

    if C_Item.IsLocked(itemLocation) then
        db.lockedItems[itemGUID] = record
        ns.Print("UNLOCK_FAILED", itemLink)
        return false
    end

    ns.Print("ITEM_UNLOCKED", itemLink)
    return true
end

function LockStore:Toggle(itemLocation)
    if not isSupportedLocation(itemLocation) then
        ns.Print("ITEM_UNAVAILABLE")
        return false
    end

    local itemGUID = C_Item.GetItemGUID(itemLocation)
    if self:IsManaged(itemGUID) then
        return self:Unlock(itemLocation)
    end

    return self:Lock(itemLocation)
end

function LockStore:SuspendNativeLocks(predicate)
    local suspendedGUIDs = {}
    for itemGUID in pairs(db.lockedItems) do
        local itemLocation = getManagedLocation(itemGUID)
        if itemLocation and (not predicate or predicate(itemLocation, itemGUID)) then
            suspendedGUIDs[itemGUID] = true
            suspensionCounts[itemGUID] = (suspensionCounts[itemGUID] or 0) + 1
            if suspensionCounts[itemGUID] == 1 and C_Item.IsLocked(itemLocation) then
                C_Item.UnlockItemByGUID(itemGUID)
            end
        end
    end

    if not next(suspendedGUIDs) then
        return nil
    end

    return suspendedGUIDs
end

function LockStore:ResumeNativeLocks(suspendedGUIDs)
    if not suspendedGUIDs then
        return
    end

    for itemGUID in pairs(suspendedGUIDs) do
        local count = suspensionCounts[itemGUID]
        if count and count > 1 then
            suspensionCounts[itemGUID] = count - 1
        else
            suspensionCounts[itemGUID] = nil
        end
    end

    self:Reconcile()
end

function LockStore:Reconcile()
    if not db then
        return
    end

    for itemGUID in pairs(db.lockedItems) do
        local itemLocation = getManagedLocation(itemGUID)
        if itemLocation and not suspensionCounts[itemGUID] and not C_Item.IsLocked(itemLocation) then
            C_Item.LockItemByGUID(itemGUID)
        end
    end
end
