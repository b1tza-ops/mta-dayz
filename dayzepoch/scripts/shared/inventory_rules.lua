local items = {}
for _, category in ipairs(DayZInventoryItems) do
    for _, entry in ipairs(category) do
        items[entry[1]] = {slots = entry[2]}
    end
end

function isDayZItem(item)
    return type(item) == "string" and items[item] ~= nil
end

function getDayZItemSlots(item)
    return items[item] and items[item].slots or false
end

function getDayZSlots(element)
    local slots = 0
    for key, info in pairs(items) do
        local count = tonumber(getElementData(element, key)) or 0
        if count > 0 then slots = slots + count * info.slots end
    end
    return slots
end

function canReceiveDayZItem(element, item, amount)
    local info = items[item]
    if not info or type(amount) ~= "number" or amount ~= amount or amount <= 0
        or amount == math.huge or amount % 1 ~= 0 then return false end
    local capacity = tonumber(getElementData(element, "MAX_Slots")) or 0
    -- Preserve legacy unlimited world-loot containers, but never player capacity zero.
    if getElementType(element) == "colshape" and capacity == 0 then return true end
    return getDayZSlots(element) + info.slots * amount <= capacity + 0.000001
end
