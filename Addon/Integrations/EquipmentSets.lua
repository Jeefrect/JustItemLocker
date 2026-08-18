local _, ns = ...

local EquipmentSets = {}
ns.EquipmentSets = EquipmentSets

local UNLOCK_WATCHDOG_SECONDS = 1
local SWAP_TIMEOUT_SECONDS = 30

local activeTransaction
local nextToken = 0

local function getItemGUID(itemLocation)
    if not itemLocation or not itemLocation:IsValid() then
        return nil
    end

    return C_Item.GetItemGUID(itemLocation)
end

local function addManagedGUID(managedGUIDs, itemGUID)
    if ns.LockStore:IsManaged(itemGUID) then
        managedGUIDs[itemGUID] = true
    end
end

local function getManagedSetGUIDs(setID)
    if type(EquipmentManager_GetLocationData) ~= "function" then
        return nil
    end

    local locations = C_EquipmentSet.GetItemLocations(setID)
    if not locations then
        return nil
    end

    local managedGUIDs = {}
    for equipmentSlot, encodedLocation in pairs(locations) do
        local equippedGUID = getItemGUID(ItemLocation:CreateFromEquipmentSlot(equipmentSlot))
        local locationData = EquipmentManager_GetLocationData(encodedLocation)
        local targetLocation
        if locationData.isBags and not locationData.isBank then
            targetLocation = ItemLocation:CreateFromBagAndSlot(locationData.bag, locationData.slot)
        elseif locationData.isPlayer and not locationData.isBank then
            targetLocation = ItemLocation:CreateFromEquipmentSlot(locationData.slot)
        end

        local targetGUID = getItemGUID(targetLocation)
        if equippedGUID ~= targetGUID then
            addManagedGUID(managedGUIDs, equippedGUID)
            addManagedGUID(managedGUIDs, targetGUID)
        end
    end

    return managedGUIDs
end

local function finishTransaction(token)
    if not activeTransaction or activeTransaction.token ~= token then
        return
    end

    local transaction = activeTransaction
    activeTransaction = nil
    ns.LockStore:ResumeNativeLocks(transaction.suspendedGUIDs)
end

local function advancePreparation(token)
    if not activeTransaction or activeTransaction.token ~= token then
        return
    end

    if activeTransaction.unlockInFlight then
        return
    end

    local itemGUID = activeTransaction.unlockQueue[activeTransaction.unlockIndex]
    if itemGUID then
        activeTransaction.ready = false
        activeTransaction.unlockInFlight = true
        activeTransaction.unlockGUID = itemGUID
        ns.LockStore:UnlockSuspendedNativeLock(activeTransaction.suspendedGUIDs, itemGUID)

        C_Timer.After(UNLOCK_WATCHDOG_SECONDS, function()
            if not activeTransaction
                or activeTransaction.token ~= token
                or not activeTransaction.unlockInFlight
                or activeTransaction.unlockGUID ~= itemGUID then
                return
            end

            activeTransaction.unlockInFlight = false
            if not ns.LockStore:IsNativeLocked(itemGUID) then
                activeTransaction.unlockIndex = activeTransaction.unlockIndex + 1
            end
            advancePreparation(token)
        end)
        return
    end

    activeTransaction.ready = true
    if activeTransaction.pending or activeTransaction.equipRequested then
        return
    end

    activeTransaction.equipRequested = true
    EquipmentManager_EquipSet(activeTransaction.setID)
end

local function prepareSelectedSet(mouseButton)
    if mouseButton and mouseButton ~= "LeftButton" then
        return false
    end

    if activeTransaction then
        return true
    end

    local pane = PaperDollFrame and PaperDollFrame.EquipmentManagerPane
    local setID = pane and pane.selectedSetID
    if not setID then
        return false
    end

    local managedGUIDs = getManagedSetGUIDs(setID)
    local suspendedGUIDs = managedGUIDs and ns.LockStore:BeginNativeLockSuspension(function(itemLocation, itemGUID)
        return itemLocation:IsEquipmentSlot() or managedGUIDs[itemGUID]
    end)
    if not suspendedGUIDs then
        return false
    end

    nextToken = nextToken + 1
    local token = nextToken
    local unlockQueue = {}
    for itemGUID in pairs(suspendedGUIDs) do
        unlockQueue[#unlockQueue + 1] = itemGUID
    end

    activeTransaction = {
        token = token,
        setID = setID,
        pending = false,
        ready = false,
        equipRequested = false,
        suspendedGUIDs = suspendedGUIDs,
        unlockQueue = unlockQueue,
        unlockIndex = 1,
        unlockInFlight = false,
    }

    C_Timer.After(0, function()
        advancePreparation(token)
    end)

    C_Timer.After(SWAP_TIMEOUT_SECONDS, function()
        finishTransaction(token)
    end)

    return true
end

function EquipmentSets:Initialize()
    local pane = PaperDollFrame and PaperDollFrame.EquipmentManagerPane
    local equipButton = pane and pane.EquipSet
    if not equipButton or self.initialized then
        return
    end

    local originalOnClick = equipButton:GetScript("OnClick")
    if type(originalOnClick) ~= "function" then
        return
    end

    self.initialized = true
    equipButton:SetScript("OnClick", function(button, mouseButton, down)
        if not prepareSelectedSet(mouseButton) then
            originalOnClick(button, mouseButton, down)
        end
    end)
end

function EquipmentSets:OnSwapPending()
    if activeTransaction then
        activeTransaction.pending = true
    end
end

function EquipmentSets:OnItemUnlocked(bagOrSlotIndex, slotIndex)
    if not activeTransaction or not activeTransaction.unlockInFlight or bagOrSlotIndex == nil then
        return
    end

    local itemGUID = activeTransaction.unlockGUID
    local itemLocation
    if slotIndex then
        itemLocation = ItemLocation:CreateFromBagAndSlot(bagOrSlotIndex, slotIndex)
    else
        itemLocation = ItemLocation:CreateFromEquipmentSlot(bagOrSlotIndex)
    end

    if getItemGUID(itemLocation) ~= itemGUID then
        return
    end

    if ns.LockStore:IsNativeLocked(itemGUID) then
        return
    end

    local token = activeTransaction.token
    activeTransaction.unlockInFlight = false
    activeTransaction.unlockIndex = activeTransaction.unlockIndex + 1
    C_Timer.After(0, function()
        advancePreparation(token)
    end)
end

function EquipmentSets:OnSwapFinished(result, setID)
    if not activeTransaction then
        return
    end

    local token = activeTransaction.token
    if setID and activeTransaction.setID ~= setID then
        return
    end

    if not activeTransaction.ready then
        activeTransaction.pending = false
        activeTransaction.equipRequested = false
        return
    end

    C_Timer.After(0, function()
        finishTransaction(token)
    end)
end
