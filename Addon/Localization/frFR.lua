local ns = select(2, ...)

ns:RegisterLocale("frFR", {
    ITEM_LOCKED = "%s est maintenant verrouillé.",
    ITEM_UNLOCKED = "%s est maintenant déverrouillé.",
    ITEM_UNAVAILABLE = "Cet objet n’est pas encore disponible.",
    LOCK_FAILED = "Impossible de verrouiller %s.",
    UNLOCK_FAILED = "Impossible de déverrouiller %s.",
})
