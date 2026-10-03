-- Every remote admin action is authorized on the server, using the real caller.
local prefix = "#DF0101[MTAZ]#BDBDBD "
local requestTimes = {}
local muteTimers = {}

function isDayZAdmin(player)
    if not isElement(player) or getElementType(player) ~= "player" then return false end
    local account = getPlayerAccount(player)
    local group = aclGetGroup("Admin")
    return account and not isGuestAccount(account) and group
        and isObjectInACLGroup("user." .. getAccountName(account), group) or false
end

local function integer(value, low, high)
    value = tonumber(value)
    if not value or value ~= value or value % 1 ~= 0 or value < low or value > high then return false end
    return value
end
local function player(value)
    return isElement(value) and getElementType(value) == "player"
end
local function vehicle(value)
    return isElement(value) and getElementType(value) == "vehicle"
end
local function message(value)
    return type(value) == "string" and #value <= 250
end
local function notify(text)
    outputChatBox(prefix .. text, root, 200, 200, 200, true)
end
local function secure(event, validate, handler)
    addEvent(event, true)
    addEventHandler(event, root, function(...)
        local caller = client
        if source ~= caller or not isDayZAdmin(caller) then return end
        local now = getTickCount()
        if requestTimes[caller] and now - requestTimes[caller] < 200 then return end
        requestTimes[caller] = now
        if not validate(...) then
            outputDebugString("[DayZ admin] Invalid arguments for " .. event, 2)
            return
        end
        outputDebugString("[DayZ admin] " .. getPlayerName(caller) .. " requested " .. event, 3)
        handler(caller, ...)
    end)
end
local function setData(element, key, value)
    setElementData(element, key, value, "broadcast", "deny")
end
secure("hasPermissionEvent", function(key, state)
    return type(key) == "string" and #key < 30 and (state == "down" or state == "up")
end, function(caller, key, state) triggerClientEvent(caller, "openGui", caller, key, state) end)
secure("dayz:adminDuty", function() return true end, function(caller)
    local enabled = not getElementData(caller,"dutyMode")
    setData(caller,"dutyMode",enabled)
    setData(caller,"zombie",enabled)
    if not enabled then setData(caller,"superman:flying",false) end
    triggerClientEvent(caller,"dayz:adminDutyChanged",resourceRoot,enabled)
end)
secure("getPlayerInfo", player, function(caller, target)
    triggerClientEvent(caller, "getPlayerInfoCallBack", caller, getPlayerName(target),
        getPlayerSerial(target), getPlayerIP(target), getPlayerVersion(target),
        getAccountName(getPlayerAccount(target)), isPlayerMuted(target))
end)
secure("kickPlayerEvent", function(target, reason) return player(target) and message(reason) end,
    function(caller, target, reason) kickPlayer(target, caller, reason) end)
secure("banPlayerEvent", function(target, reason, ip, serial, duration)
    return player(target) and message(reason) and type(ip) == "boolean" and type(serial) == "boolean"
        and integer(duration, 0, 31536000)
end, function(caller, target, reason, ip, serial, duration)
    banPlayer(target, ip, true, serial, caller, reason, tonumber(duration))
end)
secure("mutePlayerEvent", function(target, reason, duration)
    return player(target) and message(reason) and integer(duration, 0, 86400000)
end, function(caller, target, reason, duration)
    if isTimer(muteTimers[target]) then killTimer(muteTimers[target]) end
    muteTimers[target] = nil
    local muted = not isPlayerMuted(target)
    setPlayerMuted(target, muted)
    if muted and tonumber(duration) > 0 then
        muteTimers[target] = setTimer(function()
            if isElement(target) then setPlayerMuted(target, false) end
            muteTimers[target] = nil
        end, tonumber(duration), 1)
    end
end)
secure("freezePlayerEvent", function(target, frozen) return player(target) and type(frozen) == "boolean" end,
    function(caller, target) setElementFrozen(target, not isElementFrozen(target)) end)
local function warp(moved, target)
    local x,y,z = getElementPosition(target)
    setElementInterior(moved, getElementInterior(target))
    setElementDimension(moved, getElementDimension(target))
    setElementPosition(moved, x,y,z)
    fadeCamera(moved, true)
end
secure("warpToPlayerEvent", player, function(caller, target) warp(caller, target) end)
secure("warpPlayerToPlayerEvent", function(a,b) return player(a) and player(b) end,
    function(caller, a,b) warp(a,b) end)
secure("setDayzStatsEvent", function(target, amount, key)
    return player(target) and (key == "humanity" or key == "zombieskilled" or key == "murders")
        and integer(amount, key == "humanity" and -1000000 or 0, 1000000)
end, function(caller, target, amount, key) setData(target, key, tonumber(amount)) end)
secure("changeWeatherEvent", function(value) return integer(value,1,3) end,
    function(caller, value) setWeather(({20,19,8})[tonumber(value)]) end)
secure("killPlayerEvent", player, function(caller, target) setElementData(target,"blood",-100) end)
local function validItem(item, quantity)
    return type(item) == "string" and exports.dayzepoch:isDayZItem(item) and integer(quantity,1,10000)
end
secure("giveEvent", function(target,item,quantity) return player(target) and validItem(item,quantity) end,
    function(caller,target,item,quantity)
        setData(target,item,(tonumber(getElementData(target,item)) or 0)+tonumber(quantity))
        triggerClientEvent(target,"refreshInventoryManual",target)
        triggerClientEvent(caller,"dayz:adminItemGranted",resourceRoot,item,tonumber(quantity),getPlayerName(target))
    end)
secure("giveAllEvent", validItem, function(caller,item,quantity)
    for _, target in ipairs(getElementsByType("player")) do
        if getElementData(target,"logedin") then
            setData(target,item,(tonumber(getElementData(target,item)) or 0)+tonumber(quantity))
        end
    end
end)
secure("vehicleEvent", function(target,id,engine,tire,tank,rotor,scrap,fuel,slots)
    return player(target) and integer(id,400,611) and integer(engine,0,10) and integer(tire,0,10)
        and integer(tank,0,10) and integer(rotor,0,10) and integer(scrap,0,10)
        and integer(fuel,0,1000) and integer(slots,0,1000)
end, function(caller,target,id,engine,tire,tank,rotor,scrap,fuel,slots)
    local x,y,z = getElementPosition(target)
    local rx,ry,rz = getElementRotation(target)
    local veh = createVehicle(tonumber(id),x+3,y,z,rx,ry,rz)
    local col = veh and createColSphere(x+3,y,z,2.5)
    if not col then if veh then destroyElement(veh) end; return end
    setElementDimension(veh,getElementDimension(target)); setElementInterior(veh,getElementInterior(target))
    setElementDimension(col,getElementDimension(target)); setElementInterior(col,getElementInterior(target))
    attachElements(col,veh)
    setData(col,"parent",veh); setData(veh,"parent",col)
    setData(col,"vehicle",true); setData(veh,"dayzvehicle",0)
    setData(col,"MAX_Slots",tonumber(slots)); setData(col,"fuel",tonumber(fuel))
    for _, info in ipairs({{"Engine_inVehicle","needengines",engine},{"Tire_inVehicle","needtires",tire},
        {"Parts_inVehicle","needparts",tank},{"Rotor_inVehicle","needrotor",rotor},{"Scrap_inVehicle","needscrap",scrap}}) do
        setData(col,info[1],tonumber(info[3])); setData(col,info[2],tonumber(info[3]))
    end
    setData(col,"spawn",{tonumber(id),x+3,y,z})
    warpPedIntoVehicle(target,veh)
end)
secure("globalMessageEvent", message, function(caller,text) notify("[Admin] " .. text) end)
for event, action in pairs({fixVehicleEvent=fixVehicle, destroyVehicleEvent=destroyElement, blowVehicleEvent=blowVehicle}) do
    local eventName, actionFunction = event, action
    secure(event, function(target,veh) return player(target) and vehicle(veh) end,
        function(caller,target,veh)
            local col = getElementData(veh,"parent")
            actionFunction(veh)
            if eventName == "destroyVehicleEvent" and isElement(col) then destroyElement(col) end
        end)
end
addEventHandler("onPlayerChangeNick",root,function(old,new)
    for _, caller in ipairs(getElementsByType("player")) do
        if isDayZAdmin(caller) then triggerClientEvent(caller,"updatePlayerList",caller,old,new) end
    end
end)
addEventHandler("onPlayerQuit",root,function()
    requestTimes[source] = nil
    if isTimer(muteTimers[source]) then killTimer(muteTimers[source]) end
    muteTimers[source] = nil
end)

-- Self-service test items: permissions come from the authenticated account.
local function commandAdmin(caller)
    if not isDayZAdmin(caller) or not getElementData(caller,"logedin") then
        if player(caller) then outputChatBox("[DayZ] Log in with an Admin account first.",caller,255,80,80) end
        return false
    end
    local now=getTickCount()
    if requestTimes[caller] and now-requestTimes[caller]<200 then return false end
    requestTimes[caller]=now
    return true
end
addCommandHandler("dayzgive",function(caller,command,item,quantity)
    if not commandAdmin(caller) then return end
    quantity=quantity or "1"
    if not validItem(item,quantity) then
        outputChatBox("[DayZ] Usage: /dayzgive ITEM_ID AMOUNT (1-10000). Search with /dayzitems NAME",caller,255,180,80)
        return
    end
    quantity=tonumber(quantity)
    local balance=tonumber(getElementData(caller,item)) or 0
    if balance~=balance or balance<0 or balance==math.huge then return end
    setData(caller,item,balance+quantity)
    triggerClientEvent(caller,"refreshInventoryManual",caller)
    outputChatBox("[DayZ] Added "..quantity.." x "..item.." to your inventory.",caller,100,255,100)
    outputDebugString("[DayZ admin] "..getAccountName(getPlayerAccount(caller)).." gave themselves "..quantity.." x "..item,3)
end)
addCommandHandler("dayzitems",function(caller,command,...)
    if not commandAdmin(caller) then return end
    local query=string.lower(table.concat({...}," "))
    local matches={}
    for _,category in pairs(items) do
        for _,id in ipairs(category) do
            local name=exports.dayzepoch:getLanguageTextServer(id,caller) or id
            if string.find(string.lower(id),query,1,true) or string.find(string.lower(name),query,1,true) then
                matches[#matches+1]={id,name}
            end
        end
    end
    table.sort(matches,function(a,b) return a[1]<b[1] end)
    for i=1,math.min(#matches,20) do
        outputChatBox("[DayZ] "..matches[i][1].." = "..matches[i][2],caller,200,230,200)
    end
    outputChatBox("[DayZ] "..#matches.." matches; showing up to 20. Narrow the search with /dayzitems NAME",caller,255,220,100)
end)

secure("dayz:requestItemPanel",function() return true end,function(caller)
    if getElementData(caller,"logedin") then
        triggerClientEvent(caller,"dayz:openItemPanel",resourceRoot)
    end
end)
