local ns = select(2, ...)

ns:RegisterLocale("enGB", {
    ITEM_LOCKED = "%s is now locked.",
    ITEM_UNLOCKED = "%s is now unlocked.",
    ITEM_UNAVAILABLE = "That item is not available yet.",
    LOCK_FAILED = "Could not lock %s.",
    UNLOCK_FAILED = "Could not unlock %s.",
})
