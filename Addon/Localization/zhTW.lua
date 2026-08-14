local ns = select(2, ...)

ns:RegisterLocale("zhTW", {
    ITEM_LOCKED = "%s現已鎖定。",
    ITEM_UNLOCKED = "%s現已解除鎖定。",
    ITEM_UNAVAILABLE = "此物品目前無法使用。",
    LOCK_FAILED = "無法鎖定%s。",
    UNLOCK_FAILED = "無法解除鎖定%s。",
})
