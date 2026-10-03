-- Test actions are authenticated and resolved entirely on the server.
local cooldowns, returns, assets = {}, {}, {}
local function admin(player)
    if not isElement(player) or getElementType(player)~="player" then return false end
    local account=getPlayerAccount(player)
    local group=aclGetGroup("Admin")
    return account and not isGuestAccount(account) and group
        and isObjectInACLGroup("user."..getAccountName(account),group)
        and getElementData(player,"logedin") and not isPedDead(player)
        and not getElementData(player,"isDead")
end
local function reply(player,message)
    triggerClientEvent(player,"dayz:testResult",resourceRoot,message)
end
local function number(element,key)
    return tonumber(getElementData(element,key)) or 0
end
local function tracked(player)
    assets[player]=assets[player] or {}
    return assets[player]
end
local function dispose(record)
    if record.cleaned then return end
    record.cleaned=true
    if record.timer and isTimer(record.timer) then killTimer(record.timer) end
    if record.landing and isTimer(record.landing) then killTimer(record.landing) end
    for _,element in ipairs(record.elements) do
        if isElement(element) then
            if getElementType(element)=="ped" and getElementData(element,"zombie") and not isPedDead(element) then
                local owner=getElementData(element,"owner")
                if isElement(owner) then setDayZData(owner,"spawnedzombies",math.max(0,number(owner,"spawnedzombies")-1)) end
            end
            destroyElement(element)
        end
    end
end
local function cleanup(player)
    for _,record in ipairs(assets[player] or {}) do dispose(record) end
    assets[player]=nil
end
local function remember(player,record,lifetime)
    local list=tracked(player)
    for i=#list,1,-1 do if list[i].cleaned then table.remove(list,i) end end
    list[#list+1]=record
    record.timer=setTimer(function() dispose(record) end,lifetime,1)
end
local function countAssets(player,kind)
    local total=0
    for _,record in ipairs(tracked(player)) do
        if not record.cleaned and record.kind==kind and isElement(record.elements[1]) then total=total+1 end
    end
    return total
end
local function positionPlayer(player,x,y,z,dimension,interior)
    setElementInterior(player,interior);setElementDimension(player,dimension)
    local col=getElementData(player,"playerCol")
    if isElement(col) then setElementInterior(col,interior);setElementDimension(col,dimension) end
    setElementPosition(player,x,y,z)
end
local function outdoor(player)
    return getElementDimension(player)==0 and getElementInterior(player)==0 and not getPedOccupiedVehicle(player)
end
local function spawnZombies(player,amount)
    amount=tonumber(amount)
    if not amount or amount%1~=0 or amount<1 or amount>10 then return reply(player,"Choose 1 to 10 zombies.") end
    if not outdoor(player) then return reply(player,"Spawn zombies on foot, outdoors in dimension 0.") end
    -- The ordinary player limit is 5, but this admin tool offers batches up to 10.
    -- Use its own bounded test allowance; createZombie still enforces the global cap.
    if countAssets(player,"zombie")+amount>20 then
        return reply(player,"Your 20-test-zombie limit is reached. Clean up your test spawns first.")
    end
    local x,y,z=getElementPosition(player)
    local spawned=0
    for i=1,amount do
        local angle=i*math.pi*2/amount
        local zombie=createZombie(x+math.cos(angle)*8,y+math.sin(angle)*8,z,0,22)
        if isElement(zombie) then
            setDayZData(zombie,"blood",10000)
            setDayZData(zombie,"owner",player)
            setDayZData(player,"spawnedzombies",number(player,"spawnedzombies")+1)
            remember(player,{kind="zombie",elements={zombie}},5*60000)
            spawned=spawned+1
        end
    end
    if spawned==0 then
        reply(player,"No zombies spawned: the global zombie limit may be full, or ped creation failed. Check the server log.")
        outputDebugString("[DayZ testing] Zombie batch failed for "..getAccountName(getPlayerAccount(player)).."; requested "..amount,2)
    else
        reply(player,"Spawned "..spawned.." of "..amount.." zombies. They expire after 5 minutes. Use flat ground.")
    end
end
local function airdrop(player)
    if not outdoor(player) then return reply(player,"Create an airdrop on foot, outdoors in dimension 0.") end
    if countAssets(player,"airdrop")>=2 then return reply(player,"Two test airdrops are already active. Clean up first.") end
    local x,y,z=getElementPosition(player)
    local _,_,rotation=getElementRotation(player)
    local angle=math.rad(rotation)
    x=x-math.sin(angle)*7;y=y+math.cos(angle)*7
    local crate=createObject(2975,x,y,z+25)
    local chute=createObject(2903,x,y,z+26)
    local col=createColSphere(x,y,z,4)
    local blip=createBlip(x,y,z,0,2,255,170,0,255,0,300)
    if not isElement(crate) or not isElement(chute) or not isElement(col) or not isElement(blip) then
        for _,e in pairs({crate,chute,col,blip}) do if isElement(e) then destroyElement(e) end end
        return reply(player,"Could not create the test airdrop. No loot was granted.")
    end
    attachElements(chute,crate,0,0,1.5)
    setElementFrozen(crate,true)
    setDayZData(col,"parent",crate);setDayZData(crate,"parent",col)
    -- Enable looting only after the crate lands.
    setDayZData(col,"MAX_Slots",100)
    for item,quantity in pairs({weapon11=1,mag5=120,fooditem4=4,medicine5=4,vehiclepart1=1}) do
        setDayZData(col,item,quantity)
    end
    local record={kind="airdrop",elements={crate,chute,col,blip}}
    remember(player,record,15*60000)
    moveObject(crate,10000,x,y,z-1)
    record.landing=setTimer(function()
        if record.cleaned or not isElement(crate) or not isElement(col) then return end
        if isElement(chute) then destroyElement(chute) end
        setDayZData(col,"airdrop",true)
        for _,nearby in ipairs(getElementsWithinColShape(col,"player")) do
            triggerClientEvent(nearby,"dayz:testDropLanded",resourceRoot,col,crate)
        end
        if isElement(player) then reply(player,"Test airdrop landed. Approach the crate and use the loot menu. Expires in 15 minutes.") end
    end,10000,1)
    reply(player,"Test airdrop incoming 7 metres ahead: orange map marker, landing in 10 seconds. Use flat ground.")
end
local function spawnTestVehicle(player,value)
    local index=tonumber(value)
    local entry=index and index%1==0 and DayZAdminTestVehicles[index]
    if not entry then return reply(player,"Choose a listed DayZ vehicle.") end
    if not outdoor(player) then return reply(player,"Spawn vehicles on foot, outdoors in dimension 0.") end
    if countAssets(player,"vehicle")>=3 then return reply(player,"Three test vehicles are active. Clean up first.") end
    local tires,engines,parts,scrap,rotor,slots=getVehicleAddonInfos(entry.model)
    local fuel=getVehicleMaxFuel(entry.model)
    if not slots or fuel==false or fuel==nil then return reply(player,"Vehicle configuration is missing; nothing spawned.") end
    local x,y,z=getElementPosition(player)
    local _,_,rotation=getElementRotation(player)
    local angle=math.rad(rotation)
    x=x-math.sin(angle)*10;y=y+math.cos(angle)*10
    local vehicle=createVehicle(entry.model,x,y,z+1,0,0,rotation)
    local col=createColSphere(x,y,z,4)
    if not isElement(vehicle) or not isElement(col) then
        if isElement(vehicle) then destroyElement(vehicle) end
        if isElement(col) then destroyElement(col) end
        outputDebugString("[DayZ testing] Vehicle creation failed for model "..entry.model,2)
        return reply(player,"Could not create the vehicle. Check the server log.")
    end
    attachElements(col,vehicle)
    setDayZData(vehicle,"parent",col);setDayZData(col,"parent",vehicle)
    setDayZData(col,"vehicle",true)
    setDayZData(vehicle,"dayzvehicle",0)
    setDayZData(vehicle,"adminTestVehicle",true)
    setDayZData(col,"spawn",{entry.model,x,y,z})
    setDayZData(col,"MAX_Slots",slots)
    setDayZData(col,"fuel",fuel);setDayZData(vehicle,"maxfuel",fuel)
    for _,part in ipairs({{"Tire_inVehicle","needtires",tires},{"Engine_inVehicle","needengines",engines},
        {"Parts_inVehicle","needparts",parts},{"Scrap_inVehicle","needscrap",scrap},{"Rotor_inVehicle","needrotor",rotor}}) do
        setDayZData(col,part[1],part[3]);setDayZData(col,part[2],part[3]);setDayZData(vehicle,part[2],part[3])
    end
    setDayZData(vehicle,"fplus",5)
    fixVehicle(vehicle);setElementHealth(vehicle,1000)
    setVehicleLocked(vehicle,false);setVehicleEngineState(vehicle,false)
    remember(player,{kind="vehicle",elements={vehicle,col}},30*60000)
    reply(player,"Spawned "..entry.name.." 10 metres ahead: repaired, full fuel and all required parts. Enter to drive. Expires after 30 minutes or cleanup. Boats need water; use open, flat ground for other vehicles.")
end
local function inspect(player)
    local candidate,distance=nil,12
    local px,py,pz=getElementPosition(player)
    for _,vehicle in ipairs(getElementsByType("vehicle")) do
        if getElementDimension(vehicle)==getElementDimension(player) and getElementInterior(vehicle)==getElementInterior(player) then
            local x,y,z=getElementPosition(vehicle)
            local d=getDistanceBetweenPoints3D(px,py,pz,x,y,z)
            if d<=distance then candidate=vehicle;distance=d end
        end
    end
    if not candidate then return reply(player,"No vehicle within 12 metres in your dimension/interior.") end
    local col=getElementData(candidate,"parent")
    local report={"Vehicle: "..getVehicleName(candidate).." ("..getElementModel(candidate)..")",
        "Distance: "..string.format("%.1f m",distance),"Health: "..math.floor(getElementHealth(candidate)),
        "Engine: "..(getVehicleEngineState(candidate) and "running" or "off")}
    if not isElement(col) or getElementType(col)~="colshape" then
        report[#report+1]="No DayZ inventory colshape attached."
    else
        report[#report+1]="Fuel: "..number(col,"fuel").." / "..number(candidate,"maxfuel")
        report[#report+1]="Inventory slots: "..getDayZSlots(col).." / "..number(col,"MAX_Slots")
        for _,part in ipairs({{"Engine_inVehicle","needengines","Engines"},{"Tire_inVehicle","needtires","Tyres"},{"Parts_inVehicle","needparts","Parts"},{"Rotor_inVehicle","needrotor","Rotors"},{"Scrap_inVehicle","needscrap","Scrap"}}) do
            report[#report+1]=part[3]..": "..number(col,part[1]).." / "..(tonumber(getElementData(candidate,part[2])) or number(col,part[2]))
        end
    end
    reply(player,table.concat(report,"\n"))
end
addEvent("dayz:testAction",true)
addEventHandler("dayz:testAction",root,function(action,value)
    local player=client
    if source~=player or not admin(player) or type(action)~="string" then return end
    local allowed={open=true,teleport=true,back=true,zombies=true,airdrop=true,inspect=true,cleanup=true,vehicle=true,survivor=true,survivorinspect=true}
    if not allowed[action] then return end
    local now=getTickCount();cooldowns[player]=cooldowns[player] or {}
    local times=cooldowns[player]
    if times.any and now-times.any<300 then return end
    if (action=="zombies" or action=="airdrop" or action=="vehicle" or action=="survivor") and times[action] and now-times[action]<5000 then
        return reply(player,"Wait 5 seconds between test spawns.")
    end
    times.any=now;times[action]=now
    outputDebugString("[DayZ testing] "..getAccountName(getPlayerAccount(player)).." requested "..action,3)
    if action=="open" then return triggerClientEvent(player,"dayz:openTesting",resourceRoot) end
    if action=="survivorinspect" then return reply(player,DayZInspectTestSurvivors(player)) end
    if action=="survivor" then
        if not outdoor(player) then return reply(player,"Spawn survivors on foot outdoors in dimension 0.") end
        local ped,message=DayZSpawnTestSurvivor(player)
        if isElement(ped) then remember(player,{kind="survivor",elements={ped}},15*60000) end
        return reply(player,message)
    end
    if action=="inspect" then return inspect(player) end
    if action=="cleanup" then cleanup(player);return reply(player,"Removed your active test zombies, airdrops, vehicles and survivors.") end
    if action=="zombies" then return spawnZombies(player,value) end
    if action=="airdrop" then return airdrop(player) end
    if action=="vehicle" then return spawnTestVehicle(player,value) end
    if getPedOccupiedVehicle(player) then return reply(player,"Exit your vehicle before teleporting.") end
    if action=="teleport" then
        local index=tonumber(value)
        local location=index and index%1==0 and DayZAdminTestLocations[index]
        if not location then return reply(player,"Choose a listed location.") end
        local x,y,z=getElementPosition(player)
        returns[player]={x=x,y=y,z=z,dimension=getElementDimension(player),interior=getElementInterior(player)}
        positionPlayer(player,location.x,location.y,location.z+1,0,0)
        return reply(player,"Teleported to "..location.name..". Return restores your previous position.")
    end
    local previous=returns[player]
    if not previous then return reply(player,"No saved return position.") end
    positionPlayer(player,previous.x,previous.y,previous.z,previous.dimension,previous.interior);returns[player]=nil
    reply(player,"Returned to your previous position.")
end)
addEventHandler("onPlayerQuit",root,function() cleanup(source);cooldowns[source]=nil;returns[source]=nil end)
addEventHandler("onResourceStop",resourceRoot,function() for player in pairs(assets) do cleanup(player) end end)
