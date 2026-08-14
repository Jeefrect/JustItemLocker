local ns = select(2, ...)

ns:RegisterLocale("ptBR", {
    ITEM_LOCKED = "%s agora está bloqueado.",
    ITEM_UNLOCKED = "%s agora está desbloqueado.",
    ITEM_UNAVAILABLE = "Esse item ainda não está disponível.",
    LOCK_FAILED = "Não foi possível bloquear %s.",
    UNLOCK_FAILED = "Não foi possível desbloquear %s.",
})
