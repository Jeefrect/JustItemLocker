local _, ns = ...

local BagSorting = {}
ns.BagSorting = BagSorting

local activeTransaction
local clickSuspendedGUIDs

local function isBagItem(itemLocation)
    return itemLocation:IsBagAndSlot()
end

local function isEquippedItem(itemLocation)
    return itemLocation:IsEquipmentSlot()
end

local function reconcileManagedLocks()
    ns.LockStore:Reconcile()
end

local function finishTransaction(transaction)
    if activeTransaction ~= transaction then
        return
    end

    activeTransaction = nil
    ns.LockStore:ResumeNativeLocks(transaction.suspendedGUIDs)

    C_Timer.After(0, reconcileManagedLocks)
    C_Timer.After(0.25, reconcileManagedLocks)
    C_Timer.After(1, reconcileManagedLocks)
end

local function beginTransaction()
    if not activeTransaction then
        local suspendedGUIDs = ns.LockStore:SuspendNativeLocks(isBagItem)
        if suspendedGUIDs then
            local transaction = {
                suspendedGUIDs = suspendedGUIDs,
                sawBagUpdate = false,
            }
            activeTransaction = transaction

            C_Timer.After(0.25, function()
                if activeTransaction == transaction and not transaction.sawBagUpdate then
                    finishTransaction(transaction)
                end
            end)

            C_Timer.After(10, function()
                finishTransaction(transaction)
            end)
        end
    end

    clickSuspendedGUIDs = ns.LockStore:SuspendNativeLocks(isEquippedItem)
    local suspendedGUIDs = clickSuspendedGUIDs
    if suspendedGUIDs then
        C_Timer.After(0, function()
            if clickSuspendedGUIDs == suspendedGUIDs then
                clickSuspendedGUIDs = nil
                ns.LockStore:ResumeNativeLocks(suspendedGUIDs)
            end
        end)
    end
end

local function endClick()
    local suspendedGUIDs = clickSuspendedGUIDs
    if not suspendedGUIDs then
        return
    end

    clickSuspendedGUIDs = nil
    ns.LockStore:ResumeNativeLocks(suspendedGUIDs)
end

function BagSorting:OnBagChanged()
    if activeTransaction then
        activeTransaction.sawBagUpdate = true
    end
end

function BagSorting:OnBagUpdateDelayed()
    if activeTransaction then
        finishTransaction(activeTransaction)
    end
end

function BagSorting:Initialize()
    if self.initialized or not BagItemAutoSortButton then
        return self.initialized or false
    end

    self.initialized = true
    BagItemAutoSortButton:HookScript("PreClick", beginTransaction)
    BagItemAutoSortButton:HookScript("PostClick", endClick)
    return true
end
