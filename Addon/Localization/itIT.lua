local ns = select(2, ...)

ns:RegisterLocale("itIT", {
    ITEM_LOCKED = "%s è ora bloccato.",
    ITEM_UNLOCKED = "%s è ora sbloccato.",
    ITEM_UNAVAILABLE = "Questo oggetto non è ancora disponibile.",
    LOCK_FAILED = "Impossibile bloccare %s.",
    UNLOCK_FAILED = "Impossibile sbloccare %s.",
})
