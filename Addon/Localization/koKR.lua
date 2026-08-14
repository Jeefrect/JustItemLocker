local ns = select(2, ...)

ns:RegisterLocale("koKR", {
    ITEM_LOCKED = "%s 아이템을 잠갔습니다.",
    ITEM_UNLOCKED = "%s 아이템의 잠금을 해제했습니다.",
    ITEM_UNAVAILABLE = "아직 사용할 수 없는 아이템입니다.",
    LOCK_FAILED = "%s 아이템을 잠글 수 없습니다.",
    UNLOCK_FAILED = "%s 아이템의 잠금을 해제할 수 없습니다.",
})
