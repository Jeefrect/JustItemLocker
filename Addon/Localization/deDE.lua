local ns = select(2, ...)

ns:RegisterLocale("deDE", {
    ITEM_LOCKED = "%s ist jetzt gesperrt.",
    ITEM_UNLOCKED = "%s ist jetzt entsperrt.",
    ITEM_UNAVAILABLE = "Dieser Gegenstand ist noch nicht verfügbar.",
    LOCK_FAILED = "%s konnte nicht gesperrt werden.",
    UNLOCK_FAILED = "%s konnte nicht entsperrt werden.",
})
