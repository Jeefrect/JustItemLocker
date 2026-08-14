local _, ns = ...

local EquipmentSets = {}
ns.EquipmentSets = EquipmentSets

local PREPARE_TIMEOUT_SECONDS = 0.25
local SWAP_TIMEOUT_SECONDS = 10

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

local function prepareSelectedSet(_, mouseButton)
    if mouseButton and mouseButton ~= "LeftButton" then
        return
    end

    if activeTransaction then
        return
    end

    local pane = PaperDollFrame and PaperDollFrame.EquipmentManagerPane
    local setID = pane and pane.selectedSetID
    if not setID then
        return
    end

    local managedGUIDs = getManagedSetGUIDs(setID)
    local suspendedGUIDs = managedGUIDs and ns.LockStore:SuspendNativeLocks(function(_, itemGUID)
        return managedGUIDs[itemGUID]
    end)
    if not suspendedGUIDs then
        return
    end

    nextToken = nextToken + 1
    local token = nextToken
    activeTransaction = {
        token = token,
        setID = setID,
        pending = false,
        suspendedGUIDs = suspendedGUIDs,
    }

    C_Timer.After(PREPARE_TIMEOUT_SECONDS, function()
        if activeTransaction and activeTransaction.token == token and not activeTransaction.pending then
            finishTransaction(token)
        end
    end)

    C_Timer.After(SWAP_TIMEOUT_SECONDS, function()
        finishTransaction(token)
    end)
end

function EquipmentSets:Initialize()
    local pane = PaperDollFrame and PaperDollFrame.EquipmentManagerPane
    local equipButton = pane and pane.EquipSet
    if not equipButton or self.initialized then
        return
    end

    self.initialized = true
    equipButton:HookScript("PreClick", prepareSelectedSet)
end

function EquipmentSets:OnSwapPending()
    if activeTransaction then
        activeTransaction.pending = true
    end
end

function EquipmentSets:OnSwapFinished(_, setID)
    if not activeTransaction then
        return
    end

    local token = activeTransaction.token
    if setID and activeTransaction.setID ~= setID then
        return
    end

    C_Timer.After(0, function()
        finishTransaction(token)
    end)
end
