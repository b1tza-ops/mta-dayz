-- Inventory, currency and access decisions belong to the server.
local nativeSetElementData = setElementData
local fixedProtected = {
    admin=true, dutyMode=true, ["superman:flying"]=true, logedin=true, zombie=true,
    MAX_Slots=true, helmet=true, vest=true, skin=true, playerCol=true, spawn=true, dayzvehicle=true, adminTestVehicle=true, spawnedzombies=true,
    zombieskilled=true, headshots=true, murders=true, banditskilled=true,
    fuel=true, Engine_inVehicle=true, Rotor_inVehicle=true,
    Tire_inVehicle=true, Parts_inVehicle=true, Scrap_inVehicle=true,
    parent=true, id=true, safe=true, tent=true, vehicle=true, deadman=true,
    itemloot=true, hospitalbox=true, helicrash=true, airdrop=true, patrolstation=true,
    wirefence=true, mine=true, mineCol=true, detonateCol=true,
    needengines=true, needrotor=true, needtires=true, needparts=true,
    needscrap=true, ["item"]=true, objectsINloot=true,
}

function isDayZProtectedKey(key)
    return type(key) == "string" and (fixedProtected[key] or isDayZItem(key)
        or key:match("^zombie:") or key:match("^armorCondition%.") or key:match("^currentweapon_%d+$") or key:match("^%d+$")
        or key:match("^stats%.") and key ~= "stats.playtime") and true or false
end

function setDayZData(element, key, value, synchronize)
    return nativeSetElementData(element, key, value,
        synchronize == false and "local" or "broadcast",
        isDayZProtectedKey(key) and "deny" or "default")
end

local rejectionLog = {}
function dayZReject(player, action)
    if not isElement(player) then return false end
    local now = getTickCount()
    if not rejectionLog[player] or now - rejectionLog[player] >= 5000 then
        outputDebugString("[DayZ security] Rejected " .. tostring(action) .. " from " .. getPlayerName(player), 2)
        rejectionLog[player] = now
    end
    return false
end

-- Also handle attempts to introduce a previously unset protected key.
addEventHandler("onElementDataChange", root, function(key, oldValue)
    if client and (isDayZProtectedKey(key) or getElementType(source) == "player" and client ~= source) then
        setDayZData(source, key, oldValue)
        dayZReject(client, "element data write: " .. key)
    end
end, true, "high+100")

addEventHandler("onPlayerChangesProtectedData", root, function(element, key)
    dayZReject(source, "protected data write: " .. tostring(key))
end)

local requestTimes = {}
function dayZRequest(player, action, interval)
    if not isElement(player) or getElementType(player) ~= "player"
        or not getElementData(player, "logedin") or isPedDead(player)
        or getElementData(player, "isDead") then return false end
    local now = getTickCount()
    local times = requestTimes[player] or {}
    requestTimes[player] = times
    if action ~= "gameplay" and times.gameplay and now - times.gameplay < 5000 then return false end
    if times[action] and now - times[action] < (interval or 700) then return false end
    times[action] = now
    return true
end

function dayZNearby(player, element, distance)
    if not isElement(player) or not isElement(element)
        or getElementDimension(player) ~= getElementDimension(element)
        or getElementInterior(player) ~= getElementInterior(element) then return false end
    local x,y,z = getElementPosition(player)
    local ex,ey,ez = getElementPosition(element)
    return getDistanceBetweenPoints3D(x,y,z,ex,ey,ez) <= (distance or 5)
end

function dayZCanAccessLoot(player, col)
    if not dayZNearby(player, col, 6) or getElementType(col) ~= "colshape"
        or not isElementWithinColShape(player, col) then return false end
    if getElementData(col, "safe") then
        local id = getElementData(col, "id")
        local code = id and getElementData(col, id)
        return type(id) == "string" and (code == "raided" or getElementData(player, id) == code)
    end
    return getElementData(col, "itemloot") or getElementData(col, "deadman")
        or getElementData(col, "vehicle") or getElementData(col, "tent")
        or getElementData(col, "hospitalbox") or getElementData(col, "helicrash")
        or getElementData(col, "airdrop")
end

function dayZRefreshInventory(player, col)
    triggerClientEvent(player, "refreshInventoryManual", player)
    if isElement(col) then
        for _, nearby in ipairs(getElementsWithinColShape(col, "player")) do
            triggerClientEvent(nearby, "refreshLootManual", nearby, col)
        end
        if getElementData(col, "itemloot") then refreshItemLoot(col, getElementData(col, "parent")) end
    end
end

local function protectPlayer(player)
    for _, category in ipairs(DayZInventoryItems) do
        for _, entry in ipairs(category) do
            setDayZData(player, entry[1], getElementData(player, entry[1]) or 0)
        end
    end
    for _, key in ipairs({"zombieskilled", "headshots", "murders", "banditskilled"}) do
        setDayZData(player, key, getElementData(player, key) or 0)
    end
    setDayZData(player, "admin", false)
    setDayZData(player, "dutyMode", false)
    setDayZData(player, "superman:flying", false)
    setDayZData(player, "logedin", false)
end
addEventHandler("onPlayerJoin", root, function() protectPlayer(source) end)
addEventHandler("onPlayerQuit", root, function()
    requestTimes[source] = nil
    rejectionLog[source] = nil
end)
addEventHandler("onResourceStart", resourceRoot, function()
    for _, player in ipairs(getElementsByType("player")) do
        local loggedIn = getElementData(player, "logedin")
        protectPlayer(player)
        setDayZData(player, "logedin", loggedIn or false)
    end
    outputDebugString("[DayZ security] Server inventory protection enabled", 3)
end)

local requiredItems = {
    onPlayerPitchATent="item3", onPlayerBuildASafe="item4", onPlayerBuildAWireFence="item2",
    onPlayerMakeAFire="item1", onPlayerPlaceMine="item13", onPlayerCallAirdrop="item8",
    addPlayerCookMeat="fooditem11", onPlayerRefillWaterBottle="fooditem2",
}
local function owns(player,item)
    return isDayZItem(item) and (tonumber(getElementData(player,item)) or 0) >= 1
end
function dayZValidateAction(event,args)
    if not client then return true end -- trusted server-to-server events
    if not isElement(client) or getElementType(client) ~= "player" or not getElementData(client,"logedin") then return false end
    if event == "createDeadAnimal" then
        return isElement(source) and getElementType(source) == "ped" and getElementData(source,"animal")
            and dayZNearby(client,source,100) and (tonumber(getElementData(source,"blood")) or 1) <= 0
    end
    if event == "relWep" then return source == resourceRoot end
    if source ~= client then return dayZReject(client,event .. " actor") end
    if event == "kilLDayZPlayer" then
        return not args[1] or isElement(args[1]) and getElementType(args[1]) == "player"
    end
    if event == "onCreateWeaponSound" then
        return type(args[1]) == "string" and args[1]:match("^[%w_]+%.wav$")
            and type(args[2]) == "number" and args[2] >= 0 and args[2] <= 1000
            and type(args[3]) == "number" and type(args[4]) == "number" and type(args[5]) == "number"
    end
    if event == "kickPlayerOnHighPing" then return getPlayerPing(client) > 450 end
    if event == "setPlayerUseAnimation" then return dayZRequest(client,"animation",700) end
    local item = requiredItems[event]
    if item and (not owns(client,item) or args[1] and event ~= "addPlayerCookMeat" and args[1] ~= item) then return false end
    if event == "onPlayerRequestChangingStats" then
        local food = {fooditem3=true,fooditem4=true,fooditem5=true,fooditem9=true,fooditem10=true}
        local drink = {fooditem1=true,fooditem6=true,fooditem7=true}
        if not owns(client,args[1]) or not (args[3] == "food" and food[args[1]] or args[3] == "thirst" and drink[args[1]]) then return false end
    elseif event == "onPlayerUseMedicObject" then
        if not owns(client,args[1]) or not args[1]:match("^medicine[1-8]$") then return false end
    elseif event == "onPlayerGiveMedicObject" then
        local medicine = ({givebandage="medicine5",giveblood="medicine7"})[args[1]]
        if not medicine or not owns(client,medicine) or not dayZNearby(client,args[2],3)
            or getElementType(args[2]) ~= "player" then return false end
    elseif event == "onPlayerChangeSkin" or event == "onPlayerEquipBackpack"
        or event == "onPlayerEquipHelmet" or event == "onPlayerEquipVest" then
        local prefix = ({onPlayerChangeSkin="clothing",onPlayerEquipBackpack="backpack",
            onPlayerEquipHelmet="helmet",onPlayerEquipVest="vest"})[event]
        if not owns(client,args[1]) or not args[1]:match("^" .. prefix .. "%d+$") then return false end
    elseif event == "onPlayerRearmWeapon" or event == "onPlayerUnequipWeapon" then
        if not owns(client,args[1]) or not args[1]:match("^weapon%d+$")
            or type(args[2]) ~= "number" or args[2] % 1 ~= 0 or args[2] < 1 or args[2] > 3 then return false end
        if event == "onPlayerRearmWeapon" then
            local expected
            for category=1,3 do
                for _, entry in ipairs(DayZInventoryItems[category]) do
                    if entry[1] == args[1] then expected = category end
                end
            end
            if expected ~= args[2] then return false end
        end
    elseif event == "removeBackWeaponOnDrop" then
        return type(args[1]) == "boolean" and type(args[2]) == "number" and args[2] % 1 == 0 and args[2] >= 1 and args[2] <= 3
    elseif event == "onPlayerPlaceRoadflare" then
        if not ({item5=true,item11=true,item12=true})[args[1]] or not owns(client,args[1]) then return false end
        for i=2,4 do if type(args[i]) ~= "number" or args[i] % 1 ~= 0 or args[i] < 0 or args[i] > 255 then return false end end
    elseif event == "onPlayerPlaceC4" then
        if args[1] ~= client or not owns(client,"item7") or not dayZNearby(client,args[2],5)
            or not getElementData(args[2],"safe") then return false end
    elseif event == "onPlayerEnterSafeCode" or event == "onPlayerChangeSafeCode" then
        if type(args[1]) ~= "string" or not args[1]:match("^%d%d%d%d$") or not dayZNearby(client,args[2],5)
            or not getElementData(args[2],"safe") then return false end
        if event == "onPlayerChangeSafeCode" and not dayZCanAccessLoot(client,args[2]) then return false end
    elseif event == "removeTent" or event == "removeSafe" or event == "removeWirefence" then
        if not isElement(args[1]) then return false end
        local col = getElementData(args[1],"parent")
        local flag = ({removeTent="tent",removeSafe="safe",removeWirefence="wirefence"})[event]
        if not dayZNearby(client,col,6) or not getElementData(col,flag) then return false end
        if event == "removeSafe" and not dayZCanAccessLoot(client,col) then return false end
        if event ~= "removeWirefence" and args[2] ~= client then return false end
    elseif event == "removeMine" then
        if not dayZNearby(client,args[1],3) or not getElementData(args[1],"mine") then return false end
    elseif event == "onPlayerBuryBody" then
        local col = getElementData(client,"currentCol")
        if not owns(client,"weapon27") or not dayZCanAccessLoot(client,col) or not getElementData(col,"deadman") then return false end
    end
    if event == "onPlayerBuildASafe" and (type(args[2]) ~= "string" or not args[2]:match("^%d%d%d%d$")) then return false end
    return dayZRequest(client,"gameplay",5000)
end
