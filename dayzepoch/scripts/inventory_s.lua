-- Clients request actions; the server reads both balances and commits the transfer.
local partItems = {
    Engine_inVehicle="vehiclepart1", Rotor_inVehicle="vehiclepart2",
    Tire_inVehicle="vehiclepart3", Parts_inVehicle="vehiclepart4", Scrap_inVehicle="vehiclepart5",
}
local partNeeds = {
    Engine_inVehicle="needengines", Rotor_inVehicle="needrotor",
    Tire_inVehicle="needtires", Parts_inVehicle="needparts", Scrap_inVehicle="needscrap",
}
local function count(element, key)
    local value = tonumber(getElementData(element, key)) or 0
    if value ~= value or value == math.huge or value < 0 then return 0 end
    return math.floor(value)
end
local function actor()
    if client ~= source or not dayZRequest(client,"inventory",700) then return false end
    return client
end
local function unequipDropped(player, item)
    if count(player,item) > 0 then return end
    for slot=1,3 do
        if getElementData(player,"currentweapon_" .. slot) == item then
            triggerEvent("removeBackWeaponOnDrop",player,true,slot)
        end
    end
end
function transferDayZItem(player, direction, item, col)
    if direction ~= "take" and direction ~= "put" then return false end
    if not dayZCanAccessLoot(player,col) then return false end
    local inventoryItem = partItems[item] or item
    if not isDayZItem(inventoryItem) then return false end
    local vehicle = getElementData(col,"parent")
    if partItems[item] and (not getElementData(col,"vehicle") or not isElement(vehicle)
        or getVehicleEngineState(vehicle) or count(player,"toolbelt4") < 1) then return false end
    local from, to, fromKey, toKey
    if direction == "take" then from,to,fromKey,toKey=col,player,item,inventoryItem
    else from,to,fromKey,toKey=player,col,inventoryItem,item end
    local amount = math.min(count(from,fromKey),partItems[item] and 1 or getMagazineSize(inventoryItem))
    if amount <= 0 then return false end
    if not (partItems[item] and direction == "put") and not canReceiveDayZItem(to,inventoryItem,amount) then return false end
    if partItems[item] and direction == "put"
        and count(col,item)+amount > count(col,partNeeds[item]) then return false end
    -- No timers or yields between the authoritative reads and both writes.
    setDayZData(from,fromKey,count(from,fromKey)-amount)
    setDayZData(to,toKey,count(to,toKey)+amount)
    if direction == "put" then unequipDropped(player,inventoryItem) end
    dayZRefreshInventory(player,col)
    return true
end
addEvent("dayz:transferItem",true)
addEventHandler("dayz:transferItem",root,function(direction,item,col)
    local player = actor()
    if not player then return end
    if not transferDayZItem(player,direction,item,col) then dayZReject(player,"inventory transfer") end
end)

local function consumeShot(weapon)
    if not getElementData(source,"logedin") then return end
    for slot=1,3 do
        local item = getElementData(source,"currentweapon_" .. slot)
        local ammo, id = getWeaponAmmoType(item)
        if id == weapon and isDayZItem(ammo) and item ~= "weapon28" then
            if count(source,ammo) > 0 then setDayZData(source,ammo,count(source,ammo)-1) end
            return
        end
    end
end
addEventHandler("onPlayerWeaponFire",root,consumeShot)
addEventHandler("onPlayerProjectileCreation",root,function(weapon)
    if weapon == 16 then consumeShot(weapon) end
end)

function dropDayZItem(player,item)
    if not isDayZItem(item) then return false end
    local amount = math.min(count(player,item),getMagazineSize(item))
    local index, category = getItemTablePosition(item)
    if amount <= 0 or not index then return false end
    local x,y,z = getElementPosition(player)
    local object = createItemPickup(index,x,y,z,category,amount)
    if not isElement(object) then return false end
    local col = getElementData(object,"parent")
    if not isElement(col) then destroyElement(object); return false end
    setElementDimension(object,getElementDimension(player)); setElementInterior(object,getElementInterior(player))
    setElementDimension(col,getElementDimension(player)); setElementInterior(col,getElementInterior(player))
    setDayZData(player,item,count(player,item)-amount)
    unequipDropped(player,item)
    dayZRefreshInventory(player)
    return true
end
addEvent("dayz:dropItem",true)
addEventHandler("dayz:dropItem",root,function(item)
    local player = actor()
    if player and not dropDayZItem(player,item) then dayZReject(player,"item drop") end
end)

function takeGroundDayZItem(player,item,col)
    if not isDayZItem(item) or not dayZNearby(player,col,3) or getElementType(col) ~= "colshape"
        or not isElementWithinColShape(player,col) or getElementData(col,"item") ~= item then return false end
    local object = getElementData(col,"parent")
    if not isElement(object) or getElementType(object) ~= "object" then return false end
    local amount = tonumber(getElementData(col,"item2")) or getMagazineSize(item)
    amount = math.min(amount,getMagazineSize(item))
    if amount <= 0 or amount % 1 ~= 0 or not canReceiveDayZItem(player,item,amount) then return false end
    -- Remove the pickup before another player can take it.
    destroyElement(col); destroyElement(object)
    setDayZData(player,item,count(player,item)+amount)
    dayZRefreshInventory(player)
    return true
end
addEventHandler("onPlayerTakeItemFromGround",root,function(item,col)
    local player = actor()
    if player and not takeGroundDayZItem(player,item,col) then dayZReject(player,"ground pickup") end
end)

addEvent("dayz:vehiclePart",true)
addEventHandler("dayz:vehiclePart",root,function(direction,key,col)
    local player = actor()
    if not player or not partItems[key] then return end
    if not transferDayZItem(player,direction,key,col) then dayZReject(player,"vehicle part transfer") end
end)
addEvent("dayz:refuel",true)
addEventHandler("dayz:refuel",root,function(col)
    local player = actor()
    if not player or not dayZCanAccessLoot(player,col) or not getElementData(col,"vehicle")
        or count(player,"item9") < 1 then return end
    local vehicle = getElementData(col,"parent")
    if not isElement(vehicle) or getElementType(vehicle) ~= "vehicle" then return end
    local maxFuel = getVehicleMaxFuel(getElementModel(vehicle))
    local fuel = tonumber(getElementData(col,"fuel")) or 0
    if not maxFuel or fuel ~= fuel or fuel < 0 or fuel >= maxFuel then return end
    setDayZData(player,"item9",count(player,"item9")-1)
    setDayZData(player,"item10",count(player,"item10")+1)
    setDayZData(col,"fuel",math.min(maxFuel,fuel+20))
    dayZRefreshInventory(player,col)
end)
addEvent("dayz:fillCanister",true)
addEventHandler("dayz:fillCanister",root,function(col)
    local player = actor()
    if not player or not dayZNearby(player,col,5) or not isElementWithinColShape(player,col)
        or not getElementData(col,"patrolstation") or count(player,"item10") < 1 then return end
    setDayZData(player,"item10",count(player,"item10")-1)
    setDayZData(player,"item9",count(player,"item9")+1)
    dayZRefreshInventory(player)
end)

-- Protect against clients rewriting metadata to turn arbitrary elements into loot.
addEventHandler("onResourceStart",resourceRoot,function()
    for _, element in ipairs(getElementsByType("colshape",resourceRoot)) do
        for _, category in ipairs(DayZInventoryItems) do
            for _, entry in ipairs(category) do
                local existing = getElementData(element,entry[1])
                if existing ~= false then setDayZData(element,entry[1],existing) end
            end
        end
    end
end)
