local ns = select(2, ...)

ns:RegisterLocale("zhCN", {
    ITEM_LOCKED = "%s现已锁定。",
    ITEM_UNLOCKED = "%s现已解锁。",
    ITEM_UNAVAILABLE = "该物品暂不可用。",
    LOCK_FAILED = "无法锁定%s。",
    UNLOCK_FAILED = "无法解锁%s。",
})
