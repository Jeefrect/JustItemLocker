local addonName, ns = ...

local PREFIX_COLOR = "|cff33ff99"
local RESET_COLOR = "|r"

function ns.Print(key, ...)
    local template = ns.L[key] or key
    local message = select("#", ...) > 0 and string.format(template, ...) or template
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX_COLOR .. addonName .. ": " .. RESET_COLOR .. message)
end
