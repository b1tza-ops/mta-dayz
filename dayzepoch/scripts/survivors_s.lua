-- Small, admin-owned prototype. Navigation/visibility uses the owner's client;
-- the server owns targets, ammunition, damage, health and lifetime.
local survivors={}
local function data(p,k,v) setDayZData(p,"survivor:"..k,v) end
-- Avoid Lua multiple-return truncation when passing two positions.
local function range(a,b)
    local x,y,z=getElementPosition(a);local tx,ty,tz=getElementPosition(b)
    return getDistanceBetweenPoints3D(x,y,z,tx,ty,tz)
end
local supplies={
    {item="mag7",name="Shotgun shells",limit=70,batch=7},
    {item="medicine5",name="Bandages",limit=2,batch=1},
    {item="fooditem4",name="Beans",limit=2,batch=1},
    {item="fooditem7",name="Soda",limit=2,batch=1},
    {item="medicine3",name="Small medic kits",limit=2,batch=1},
    {item="medicine2",name="Medic kits",limit=1,batch=1},
    {item="medicine1",name="Large medic kits",limit=1,batch=1},
}
local function count(e,k)
    local n=tonumber(getElementData(e,k)) or 0
    return n==n and n>=0 and n<math.huge and math.floor(n) or 0
end
local function world(a,b)
    return getElementDimension(a)==getElementDimension(b) and getElementInterior(a)==getElementInterior(b)
end
local function lootable(col)
    return isElement(col) and getElementType(col)=="colshape"
        and (getElementData(col,"itemloot") or getElementData(col,"airdrop") or getElementData(col,"deadman"))
        and not getElementData(col,"safe") and not getElementData(col,"vehicle") and not getElementData(col,"tent")
end
local function priority(r,item)
    if item=="medicine5" and r.bleeding then return 100 end
    if item:match("^medicine[123]$") and r.hp<=70 then return 90 end
    if item=="fooditem7" and r.water<=50 then return 80 end
    if item=="fooditem4" and r.food<=50 then return 75 end
    if item=="mag7" and r.ammo<14 then return 85 end
    return 1
end
local function wanted(r,col)
    if not lootable(col) then return end
    local chosen,quantity,best=nil,0,-1
    for _,supply in ipairs(supplies) do
        local amount=math.min(count(col,supply.item),supply.batch,supply.limit-count(r.col,supply.item))
        while amount>0 and not canReceiveDayZItem(r.col,supply.item,amount) do amount=amount-1 end
        local score=priority(r,supply.item)
        if amount>0 and score>best then chosen=supply;quantity=amount;best=score end
    end
    return chosen,quantity,best
end
local function syncNeeds(ped,r)
    data(ped,"food",r.food);data(ped,"water",r.water);data(ped,"bleeding",r.bleeding)
    data(ped,"health",r.hp);setElementHealth(ped,r.hp)
end
local function consume(ped,r,now)
    if r.use then
        if now<r.use.untilTime then return end
        local use=r.use;r.use=nil
        if count(r.col,use.item)<=0 then return end
        setDayZData(r.col,use.item,count(r.col,use.item)-1)
        if use.state=="eating" then r.food=math.min(100,r.food+45)
        elseif use.state=="drinking" then r.water=math.min(100,r.water+50)
        elseif use.state=="bandaging" then r.bleeding=false
        else r.hp=math.min(100,r.hp+use.heal) end
        syncNeeds(ped,r);data(ped,"lastUse",use.state.." ("..use.item..")")
        outputDebugString("[DayZ survivors] Finished "..use.state.."; consumed "..use.item,3)
        return
    end
    local use
    if r.bleeding and count(r.col,"medicine5")>0 then use={item="medicine5",state="bandaging"}
    elseif r.hp<=70 then
        for _,kit in ipairs({{"medicine3",25},{"medicine2",40},{"medicine1",60}}) do
            if count(r.col,kit[1])>0 then use={item=kit[1],heal=kit[2],state="healing"};break end
        end
    end
    if not use and r.water<=50 and count(r.col,"fooditem7")>0 then use={item="fooditem7",state="drinking"} end
    if not use and r.food<=50 and count(r.col,"fooditem4")>0 then use={item="fooditem4",state="eating"} end
    if use then use.untilTime=now+3000;r.use=use end
end
local function corpse(ped,r)
    if r.corpse or not isElement(r.col) then return end
    r.corpse=true;data(ped,"state","dead");data(ped,"target",false)
    setDayZData(r.col,"deadman",true);setDayZData(r.col,"playername","AI survivor")
    local t=getRealTime()
    setDayZData(r.col,"deadreason",{"other","deadzombietext",t.hour,t.minute,"clocktext"})
    for _,player in ipairs(getElementsWithinColShape(r.col,"player")) do
        triggerClientEvent(player,"dayz:testDropLanded",resourceRoot,r.col,ped)
    end
    outputDebugString("[DayZ survivors] Survivor died; carried inventory is lootable",3)
end
function DayZSpawnTestSurvivor(player)
    local count=0
    for ped,record in pairs(survivors) do if isElement(ped) and record.owner==player then count=count+1 end end
    if count>=3 then return nil,"Three survivors are active. Clean up first." end
    local x,y,z=getElementPosition(player)
    local ped=createPed(287,x+4,y,z)
    if not isElement(ped) then return nil,"Survivor creation failed; check the server log." end
    local col=createColSphere(x+4,y,z,1.5)
    if not isElement(col) then destroyElement(ped);return nil,"Survivor inventory creation failed." end
    attachElements(col,ped)
    setDayZData(col,"parent",ped);setDayZData(ped,"parent",col)
    setDayZData(col,"MAX_Slots",20);setDayZData(col,"weapon7",1);setDayZData(col,"mag7",40)
    -- Eight waypoints around an 80-by-80-metre patrol area.
    local route={{x+4,y,z},{x+40,y,z},{x+40,y+40,z},{x,y+40,z},
        {x-40,y+40,z},{x-40,y,z},{x-40,y-40,z},{x,y-40,z}}
    survivors[ped]={owner=player,col=col,ignored={},lastLoot=0,food=65,water=65,bleeding=false,lastNeeds=getTickCount(),route=route,index=2,routeStarted=getTickCount(),ammo=40,hp=100,lastShot=0,lastMelee=0,progress=getTickCount(),px=x+4,py=y,pz=z}
    if not setElementSyncer(ped,player,true) then
        survivors[ped]=nil;destroyElement(col);destroyElement(ped)
        outputDebugString("[DayZ survivors] Could not assign survivor controller",2)
        return nil,"Could not assign survivor controller; nothing spawned."
    end
    giveWeapon(ped,25,40,true)
    setElementHealth(ped,100)
    data(ped,"active",true);data(ped,"owner",player);data(ped,"ammo",40);data(ped,"health",100)
    syncNeeds(ped,survivors[ped])
    data(ped,"state","patrol");data(ped,"waypoint",route[2])
    outputDebugString("[DayZ survivors] Spawned patrol survivor for "..getAccountName(getPlayerAccount(player)),3)
    return ped,"Survivor spawned: shotgun, 40 shells, 20-slot inventory; searches nearby loot for shells, food, drinks, bandages and medic kits. Eats, drinks and heals automatically when safe. Expires in 15 minutes."
end
function DayZInspectTestSurvivors(player)
    local lines={}
    for ped,r in pairs(survivors) do
        if isElement(ped) and r.owner==player then
            lines[#lines+1]="Survivor: "..tostring(getElementData(ped,"survivor:state")).." | HP "..r.hp.." | shells "..r.ammo.." | distance "..math.floor(range(player,ped)).."m | inventory "..string.format("%.1f",getDayZSlots(r.col)).."/20 slots"
            lines[#lines+1]="  Patrol waypoint: "..r.index.."/"..#r.route.." | Movement: "..(r.navigation or "waiting for controller")
            lines[#lines+1]="  Food: "..math.floor(r.food).."/100 | Water: "..math.floor(r.water).."/100 | Bleeding: "..(r.bleeding and "yes" or "no")
            lines[#lines+1]="  Last used: "..tostring(getElementData(ped,"survivor:lastUse") or "Nothing yet")
            if isElement(r.loot) then
                lines[#lines+1]="  Loot target: "..string.format("%.1f",range(ped,r.loot)).."m | "..(r.lootStatus or "Approaching")
            else lines[#lines+1]="  No loot target: needs supplies within 35m, no nearby zombie threat" end
            lines[#lines+1]="  Last collected: "..tostring(getElementData(ped,"survivor:lastLoot") or "Nothing yet")
            for _,supply in ipairs(supplies) do lines[#lines+1]="  "..supply.name..": "..count(r.col,supply.item) end
        end
    end
    return #lines>0 and table.concat(lines,"\n") or "No active survivors belonging to you."
end
function DayZTestSurvivorNeeds(player)
    local total=0
    for ped,r in pairs(survivors) do
        if isElement(ped) and not isPedDead(ped) and r.owner==player then
            r.food=35;r.water=30;r.hp=55;r.bleeding=true;r.use=nil;r.lastNeeds=getTickCount()
            syncNeeds(ped,r);total=total+1
        end
    end
    return total>0 and "Set "..total.." survivors to hungry, thirsty and injured. They need food, soda, bandages and medic kits; test airdrops contain these. Remove nearby zombies so they can recover." or "No living survivors belonging to you."
end
setTimer(function()
    for ped,r in pairs(survivors) do
        if not isElement(ped) then if isElement(r.col) then destroyElement(r.col) end;survivors[ped]=nil
        elseif not isElement(r.owner) then if isElement(r.col) then destroyElement(r.col) end;destroyElement(ped);survivors[ped]=nil
        elseif isPedDead(ped) then corpse(ped,r)
        else
            local target,best=nil,30
            for _,zombie in ipairs(getElementsByType("ped")) do
                if getElementData(zombie,"zombie") and not isPedDead(zombie)
                    and getElementDimension(zombie)==getElementDimension(ped) and getElementInterior(zombie)==getElementInterior(ped) then
                    local d=range(ped,zombie)
                    if d<best then target=zombie;best=d end
                end
            end
            r.target=target
            local now=getTickCount()
            local paused=not world(ped,r.owner) or range(ped,r.owner)>180
            if paused then r.lastNeeds=now;r.use=nil
            else
                local ticks=math.floor((now-r.lastNeeds)/10000)
                if ticks>0 then
                    r.lastNeeds=r.lastNeeds+ticks*10000
                    r.food=math.max(0,r.food-ticks);r.water=math.max(0,r.water-ticks*1.5)
                    local damage=(r.bleeding and 2 or 0)+(r.food<=0 and 3 or 0)+(r.water<=0 and 4 or 0)
                    r.hp=math.max(0,r.hp-damage*ticks)
                    syncNeeds(ped,r)
                end
                if target or r.hp<=0 then r.use=nil else consume(ped,r,now) end
            end
            if r.hp<=0 then killPed(ped);corpse(ped,r) end
            local state=r.hp<=0 and "dead" or paused and "paused" or target and ((r.ammo<=0 or r.hp<=30) and "retreat" or "combat") or r.use and r.use.state or "patrol"
            if state=="patrol" then
                if r.loot and (not wanted(r,r.loot) or not world(ped,r.loot) or getTickCount()-r.lootSince>45000) then
                    if isElement(r.loot) then r.ignored[r.loot]=getTickCount()+30000 end
                    r.loot=nil
                end
                if not r.loot then
                    local nearest=35;local bestPriority=-1
                    for _,col in ipairs(getElementsByType("colshape")) do
                        if world(ped,col) and (not r.ignored[col] or getTickCount()>r.ignored[col]) and wanted(r,col) then
                            local d=range(ped,col)
                            local _,_,score=wanted(r,col)
                            if d<35 and (score>bestPriority or score==bestPriority and d<nearest) then
                                r.loot=col;nearest=d;bestPriority=score
                            end
                        end
                    end
                    if r.loot then r.lootSince=getTickCount();r.lootStatus="Approaching" end
                end
                if r.loot then
                    state="loot"
                    local x,y,z=getElementPosition(r.loot);data(ped,"waypoint",{x,y,z})
                end
            else r.loot=nil end
            data(ped,"lootTarget",r.loot or false)
            data(ped,"state",state);data(ped,"target",target or false)
            if state=="patrol" then
                local wp=r.route[r.index];local x,y,z=getElementPosition(ped)
                if ((x-wp[1])^2+(y-wp[2])^2)^0.5<2 or getTickCount()-r.routeStarted>45000 then
                    r.index=r.index%#r.route+1;r.progress=getTickCount();r.routeStarted=getTickCount()
                elseif getDistanceBetweenPoints3D(x,y,z,r.px,r.py,r.pz)>0.7 then
                    r.px=x;r.py=y;r.pz=z;r.progress=getTickCount()
                elseif getTickCount()-r.progress>6000 then
                    r.index=r.index%#r.route+1;r.progress=getTickCount();r.routeStarted=getTickCount()
                    outputDebugString("[DayZ survivors] Patrol blocked; trying next waypoint",3)
                end
                data(ped,"waypoint",r.route[r.index])
            end
        end
    end
end,500,0)
-- Only the designated controller can report visibility; arbitrary targets and
-- damage values are never accepted. This is a prototype visibility boundary.
addEvent("dayz:survivorSight",true)
addEventHandler("dayz:survivorSight",root,function(ped,target)
    local r=survivors[ped]
    if source~=client or not r or client~=r.owner or not isElement(ped) or isPedDead(ped)
        or not isElement(target) or target~=r.target or isPedDead(target)
        or not getElementData(target,"zombie") or not world(ped,client) or range(ped,client)>180
        or getElementDimension(ped)~=getElementDimension(target) or getElementInterior(ped)~=getElementInterior(target) then return end
    local now=getTickCount();local d=range(ped,target)
    if d<1.8 and now-r.lastMelee>=1000 then
        r.lastMelee=now;r.hp=math.max(0,r.hp-15);r.bleeding=true;data(ped,"bleeding",true)
        data(ped,"health",r.hp);setElementHealth(ped,r.hp)
        if r.hp<=0 then killPed(ped,target);corpse(ped,r);return end
    end
    if getElementData(ped,"survivor:state")~="combat" or d>25 or r.ammo<=0 or now-r.lastShot<900 then return end
    r.lastShot=now;r.ammo=r.ammo-1;setDayZData(r.col,"mag7",r.ammo);data(ped,"ammo",r.ammo)
    triggerClientEvent(root,"dayz:survivorShot",resourceRoot,ped,target)
    local blood=(tonumber(getElementData(target,"blood")) or 10000)-2500
    setDayZData(target,"blood",blood)
    if blood<=0 then
        outputDebugString("[DayZ survivors] Survivor killed a zombie; shells remaining "..r.ammo,3)
        triggerEvent("onZombieGetsKilled",target,ped,false,25)
    end
end)

addEvent("dayz:survivorLoot",true)
addEventHandler("dayz:survivorLoot",root,function(ped,col,visible)
    local r=survivors[ped]
    if source~=client or not r or client~=r.owner or not isElement(ped) or isPedDead(ped)
        or col~=r.loot or not lootable(col) or not world(ped,col) or range(ped,col)>4 or not isElementWithinColShape(ped,col)
        or not world(ped,client) or range(ped,client)>180 or getElementData(ped,"survivor:state")~="loot"
        or getTickCount()-r.lastLoot<1500 then return end
    if visible~=true then
        r.lootStatus="At loot, but visibility blocked"
        return
    end
    r.lootStatus="Collecting supplies"
    local supply,amount=wanted(r,col)
    if not supply then r.loot=nil;return end
    -- Both balances are read and changed in the same event; no delayed transfers.
    r.lastLoot=getTickCount()
    setDayZData(col,supply.item,count(col,supply.item)-amount)
    setDayZData(r.col,supply.item,count(r.col,supply.item)+amount)
    if supply.item=="mag7" then
        r.ammo=count(r.col,"mag7");data(ped,"ammo",r.ammo)
        setWeaponAmmo(ped,25,r.ammo)
    end
    dayZRefreshInventory(r.owner,col)
    data(ped,"lastLoot",supply.name.." x"..amount)
    outputDebugString("[DayZ survivors] Looted "..supply.item.." x"..amount,3)
end)

-- Diagnostic reports do not let clients change routes or positions.
addEvent("dayz:survivorNavigation",true)
addEventHandler("dayz:survivorNavigation",root,function(ped,status)
    local r=survivors[ped]
    local allowed={walking=true,detouring=true,blocked=true,waiting=true}
    if source~=client or not r or client~=r.owner or not isElement(ped) or not world(ped,client)
        or range(ped,client)>180 or type(status)~="string" or not allowed[status] then return end
    local now=getTickCount()
    if r.lastNav and now-r.lastNav<1000 then return end
    r.lastNav=now
    if status=="blocked" and r.navigation~=status then outputDebugString("[DayZ survivors] Movement blocked; trying alternate directions",3) end
    r.navigation=status
end)
