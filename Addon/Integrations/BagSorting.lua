local _, ns = ...

local BagSorting = {}
ns.BagSorting = BagSorting

local activeTransaction

local function isBagItem(itemLocation)
    return itemLocation:IsBagAndSlot()
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
    if activeTransaction then
        return
    end

    local suspendedGUIDs = ns.LockStore:SuspendNativeLocks(isBagItem)
    if not suspendedGUIDs then
        return
    end

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
    return true
end
