local ns = select(2, ...)

ns:RegisterLocale("esES", {
    ITEM_LOCKED = "%s ahora está bloqueado.",
    ITEM_UNLOCKED = "%s ahora está desbloqueado.",
    ITEM_UNAVAILABLE = "Ese objeto todavía no está disponible.",
    LOCK_FAILED = "No se ha podido bloquear %s.",
    UNLOCK_FAILED = "No se ha podido desbloquear %s.",
})
