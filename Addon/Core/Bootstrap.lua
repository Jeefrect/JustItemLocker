local addonName, ns = ...

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

local reconcilePending = false

local function reconcileNextFrame()
    if reconcilePending then
        return
    end

    reconcilePending = true
    C_Timer.After(0, function()
        reconcilePending = false
        ns.LockStore:Reconcile()
    end)
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedName = ...
        if loadedName == addonName then
            ns.LockStore:Initialize()
            ns.BlizzardUI:Initialize()
            if ns.BlizzardUI:InitializeAuctionHouse() then
                self:UnregisterEvent("ADDON_LOADED")
            end

            self:RegisterEvent("PLAYER_LOGIN")
            self:RegisterEvent("BAG_UPDATE")
            self:RegisterEvent("BAG_UPDATE_DELAYED")
            self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
            self:RegisterEvent("ITEM_UNLOCKED")
            self:RegisterEvent("EQUIPMENT_SWAP_PENDING")
            self:RegisterEvent("EQUIPMENT_SWAP_FINISHED")
        elseif loadedName == "Blizzard_AuctionHouseUI" then
            if ns.BlizzardUI:InitializeAuctionHouse() then
                self:UnregisterEvent("ADDON_LOADED")
            end
        end
    elseif event == "EQUIPMENT_SWAP_PENDING" then
        ns.EquipmentSets:OnSwapPending()
    elseif event == "EQUIPMENT_SWAP_FINISHED" then
        ns.EquipmentSets:OnSwapFinished(...)
    elseif event == "ITEM_UNLOCKED" then
        ns.LockStore:Reconcile()
    elseif event == "BAG_UPDATE" then
        ns.BagSorting:OnBagChanged()
    elseif event == "BAG_UPDATE_DELAYED" then
        ns.BagSorting:OnBagUpdateDelayed()
        reconcileNextFrame()
    elseif event == "PLAYER_LOGIN" then
        ns.BlizzardUI:Initialize()
        reconcileNextFrame()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        reconcileNextFrame()
    end
end)
