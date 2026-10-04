local lastPurchase = {}
local function respond(player, ok, text)
    triggerClientEvent(player,"dayz:purchaseResult",resourceRoot,ok,text)
end
local function buyer(kind)
    local player = client
    if not isElement(player) or source ~= player or not getElementData(player,"logedin")
        or isPedDead(player) or getElementData(player,"isDead")
        or getElementInterior(player) ~= 0 or getElementDimension(player) ~= 0 then return false end
    local now = getTickCount()
    if lastPurchase[player] and now-lastPurchase[player] < 700 then return false end
    lastPurchase[player] = now
    local x,y,z = getElementPosition(player)
    for _, shop in pairs(DayZShops) do
        local marker = shop.normal[kind .. "_dealer_marker"]
        if marker and getDistanceBetweenPoints3D(x,y,z,marker[1],marker[2],marker[3]) <= 3 then
            return player, marker
        end
    end
    respond(player,false,"Move closer to the trader.")
    return false
end
local function balance(player)
    local value = tonumber(getElementData(player,DayZShopCurrency))
    if not value or value ~= value or value == math.huge or value < 0 then return 0 end
    return value
end
local function setData(element,key,value)
    return setElementData(element,key,value,"broadcast","deny")
end
addEvent("dayz:buyItem",true)
addEventHandler("dayz:buyItem",root,function(item)
    local player = buyer("supply")
    if not player or type(item) ~= "string" then return end
    local product
    for _, category in pairs(DayZShopItems.normal.supply) do
        for _, entry in ipairs(category) do if entry[1] == item then product = entry; break end end
    end
    if not product then respond(player,false,"Unknown product."); return end
    local amount, price = product[2],product[3]
    if balance(player) < price then respond(player,false,"You don't have enough zKills."); return end
    if not exports.dayzepoch:canReceiveDayZItem(player,item,amount) then
        respond(player,false,"Your backpack is full."); return
    end
    setData(player,item,(tonumber(getElementData(player,item)) or 0)+amount)
    setData(player,DayZShopCurrency,balance(player)-price)
    triggerClientEvent(player,"refreshInventoryManual",player)
    respond(player,true,"Purchase complete.")
end)
addEvent("dayz:buyVehicle",true)
addEventHandler("dayz:buyVehicle",root,function(id)
    local player, marker = buyer("vehicle")
    if not player or type(id) ~= "number" then return end
    local product
    for _, entry in ipairs(DayZShopItems.normal.vehicle.Vehicles) do
        if entry[2] == id then product = entry; break end
    end
    if not product then respond(player,false,"Unknown vehicle."); return end
    local price = product[10]
    if balance(player) < price then respond(player,false,"You don't have enough zKills."); return end
    local x,y,z,rx,ry,rz = unpack(marker,4)
    for _, veh in ipairs(getElementsByType("vehicle")) do
        if getElementDimension(veh) == 0 and getElementInterior(veh) == 0 then
            local vx,vy,vz = getElementPosition(veh)
            if getDistanceBetweenPoints3D(x,y,z,vx,vy,vz) < 5 then
                respond(player,false,"Clear the vehicle spawn area first."); return
            end
        end
    end
    local veh = createVehicle(id,x,y,z,rx,ry,rz)
    local col = veh and createColSphere(x,y,z,2.5)
    if not col then
        if veh then destroyElement(veh) end
        respond(player,false,"Vehicle could not be created. You were not charged."); return
    end
    if id == 528 then setVehicleDamageProof(veh,true) end
    attachElements(col,veh)
    setData(col,"parent",veh); setData(veh,"parent",col)
    setData(col,"vehicle",true); setData(veh,"dayzvehicle",0)
    setData(col,"MAX_Slots",product[8]); setData(col,"fuel",product[9])
    for _, info in ipairs({{"Engine_inVehicle","needengines",3},{"Rotor_inVehicle","needrotor",4},
        {"Tire_inVehicle","needtires",5},{"Parts_inVehicle","needparts",6},{"Scrap_inVehicle","needscrap",7}}) do
        setData(col,info[1],product[info[3]]); setData(col,info[2],product[info[3]])
    end
    setData(col,"spawn",{id,x,y,z})
    setData(player,DayZShopCurrency,balance(player)-price)
    respond(player,true,"You bought " .. product[1] .. ".")
end)
addEventHandler("onPlayerLogin",root,function() triggerClientEvent(source,"load_shop",source) end)
addEventHandler("onPlayerQuit",root,function() lastPurchase[source] = nil end)
