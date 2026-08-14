local ns = select(2, ...)

ns:RegisterLocale("ruRU", {
    ITEM_LOCKED = "%s теперь заблокирован.",
    ITEM_UNLOCKED = "%s теперь разблокирован.",
    ITEM_UNAVAILABLE = "Предмет пока недоступен.",
    LOCK_FAILED = "Не удалось заблокировать %s.",
    UNLOCK_FAILED = "Не удалось разблокировать %s.",
})
