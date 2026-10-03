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
-- Pure utility planner: inputs are server observations, never client scores.
DayZSurvivorBrain={}
local personalities={
    {name="Cautious scavenger",maxEnemies=2,minHealth=45},
    {name="Balanced survivor",maxEnemies=3,minHealth=35},
    {name="Bold fighter",maxEnemies=4,minHealth=30},
}
function DayZSurvivorBrain.decide(view)
    if view.paused then return {state="paused",goal="Wait",reason="Owner is too far away or in another world",score=1000} end
    local goals={{state="patrol",goal="Explore",reason="Visit a less recently searched, safer waypoint",score=10}}
    local close=view.nearest and view.nearest<=18
    local risk=close and (view.enemies>=view.personality.maxEnemies or view.hp<view.personality.minHealth or view.ammo<math.max(4,view.enemies*4))
    if risk or view.fleeing then
        goals[#goals+1]={state="retreat",goal="Find safety",reason=risk and (view.ammo<4 and "Too little ammunition" or view.hp<view.personality.minHealth and "Injured; avoid another fight" or "Outnumbered for this personality") or "Keep retreating until safely clear",score=220}
    end
    if view.use and not close and not view.fleeing then
        goals[#goals+1]={state=view.use,goal="Recover",reason="Use carried supplies while threats are distant",score=180}
    end
    if view.nearest and view.nearest<=25 then
        goals[#goals+1]={state="combat",goal="Fight zombies",reason="Manageable threat with enough health and shells",score=close and 160 or 30}
    end
    if view.loot then
        goals[#goals+1]={state="loot",goal="Find supplies",reason=view.loot.reason,score=view.loot.score}
    end
    local chosen=goals[1]
    for _,goal in ipairs(goals) do if goal.score>chosen.score then chosen=goal end end
    return chosen
end
local function dangerPenalty(r,x,y,now)
    local penalty=0
    for key,memory in pairs(r.danger) do
        if now>memory.untilTime then r.danger[key]=nil
        elseif ((x-memory.x)^2+(y-memory.y)^2)^0.5<22 then penalty=penalty+35 end
    end
    return penalty
end
local function nextExplore(ped,r,now)
    local x,y=getElementPosition(ped);local chosen,best=nil,-math.huge
    for index,wp in ipairs(r.route) do
        if not r.blockedRoutes[index] or now>r.blockedRoutes[index] then
            local age=r.visited[index] and math.min(120,(now-r.visited[index])/1000) or 150
            local distance=((x-wp[1])^2+(y-wp[2])^2)^0.5
            local score=age-distance*0.4-dangerPenalty(r,wp[1],wp[2],now)
            if distance>3 and score>best then chosen=index;best=score end
        end
    end
    return chosen or r.index%#r.route+1
end
local function safeWaypoint(ped,r,zombies,now)
    local chosen,best=r.route[1],-math.huge
    local x,y=getElementPosition(ped)
    for _,wp in ipairs(r.route) do
        local clearance=60
        for _,zombie in ipairs(zombies) do
            local zx,zy=getElementPosition(zombie)
            clearance=math.min(clearance,((wp[1]-zx)^2+(wp[2]-zy)^2)^0.5)
        end
        local score=clearance-((x-wp[1])^2+(y-wp[2])^2)^0.5*0.25-dangerPenalty(r,wp[1],wp[2],now)
        if score>best then best=score;chosen=wp end
    end
    return chosen
end
local function rememberLoot(ped,r,now)
    local entries={}
    for col,seen in pairs(r.lootMemory) do
        if not isElement(col) or now-seen>180000 then r.lootMemory[col]=nil;r.ignored[col]=nil
        else entries[#entries+1]={col=col,seen=seen} end
    end
    table.sort(entries,function(a,b) return a.seen>b.seen end)
    for index=65,#entries do r.lootMemory[entries[index].col]=nil;r.ignored[entries[index].col]=nil end
end
local function lootGoal(ped,r,now)
    local chosen,best=nil,-math.huge
    for col in pairs(r.lootMemory) do
        if world(ped,col) and (not r.ignored[col] or now>r.ignored[col]) then
            local supply,_,priorityScore=wanted(r,col)
            local distance=range(ped,col)
            -- Return to remembered supplies only for a current shortage.
            if supply and distance<=(priorityScore>1 and 80 or 50) then
                local x,y=getElementPosition(col)
                local score=40+priorityScore*0.6-distance*0.3-dangerPenalty(r,x,y,now)
                if col==r.loot then score=score+8 end -- commitment prevents target thrashing
                if score>best then
                    best=score;chosen={col=col,score=score,reason=(priorityScore>1 and "Urgent: " or "Restock: ")..supply.name}
                end
            end
        end
    end
    return chosen
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
    survivors[ped]={owner=player,col=col,personality=personalities[count%#personalities+1],zombieSight={},lootMemory={},visited={[1]=getTickCount()},blockedRoutes={},danger={},fleeUntil=0,ignored={},lastLoot=0,food=65,water=65,bleeding=false,lastNeeds=getTickCount(),route=route,index=2,routeStarted=getTickCount(),ammo=40,hp=100,lastShot=0,lastMelee=0,progress=getTickCount(),px=x+4,py=y,pz=z}
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
    return ped,survivors[ped].personality.name.." spawned: shotgun, 40 shells, 20-slot inventory; searches nearby loot for shells, food, drinks, bandages and medic kits. Eats, drinks and heals automatically when safe. Expires in 15 minutes."
end
function DayZInspectTestSurvivors(player)
    local lines={}
    for ped,r in pairs(survivors) do
        if isElement(ped) and r.owner==player then
            lines[#lines+1]="Survivor: "..tostring(getElementData(ped,"survivor:state")).." | HP "..r.hp.." | shells "..r.ammo.." | distance "..math.floor(range(player,ped)).."m | inventory "..string.format("%.1f",getDayZSlots(r.col)).."/20 slots"
            lines[#lines+1]="  Personality: "..r.personality.name
            lines[#lines+1]="  Goal: "..(r.goal or "Explore").." | Reason: "..(r.reason or "Starting patrol").." | Score: "..math.floor(r.goalScore or 10)
            local memories=0;for _ in pairs(r.lootMemory) do memories=memories+1 end
            local blocked=0;for _,untilTime in pairs(r.blockedRoutes) do if untilTime>getTickCount() then blocked=blocked+1 end end
            lines[#lines+1]="  Loot senses: "..(r.sensedCount or 0).." visible sites | radius 50m | "..(r.lastSense and math.floor((getTickCount()-r.lastSense)/1000).."s since scan" or "waiting for first scan")
            lines[#lines+1]="  Memory: "..memories.." loot sites | "..blocked.." blocked routes | nearby threats "..(r.enemies or 0)
            lines[#lines+1]="  Patrol waypoint: "..r.index.."/"..#r.route.." | Movement: "..(r.navigation or "waiting for controller")
            lines[#lines+1]="  Food: "..math.floor(r.food).."/100 | Water: "..math.floor(r.water).."/100 | Bleeding: "..(r.bleeding and "yes" or "no")
            lines[#lines+1]="  Last used: "..tostring(getElementData(ped,"survivor:lastUse") or "Nothing yet")
            if isElement(r.loot) then
                lines[#lines+1]="  Loot target: "..string.format("%.1f",range(ped,r.loot)).."m | "..(r.lootStatus or "Approaching")
            else lines[#lines+1]="  No selected loot target: supplies may be absent, unnecessary, blocked or unsafe" end
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
            local now=getTickCount()
            local target,best=nil,30
            local zombies,closeCount={},0
            for zombie,seen in pairs(r.zombieSight) do
                if isElement(zombie) and now-seen<=4000 and getElementData(zombie,"zombie") and not isPedDead(zombie) and world(ped,zombie) then
                    local d=range(ped,zombie)
                    if d<30 then zombies[#zombies+1]=zombie end
                    if d<=18 then closeCount=closeCount+1 end
                    if d<best then target=zombie;best=d end
                end
            end
            r.target=target;r.enemies=closeCount
            local paused=not world(ped,r.owner) or range(ped,r.owner)>180
            if closeCount>=2 then
                local x,y=getElementPosition(ped)
                local key=math.floor(x/20)..":"..math.floor(y/20)
                r.danger[key]={x=x,y=y,untilTime=now+60000}
            end
            local dangerEntries={}
            for key,memory in pairs(r.danger) do
                if now>memory.untilTime then r.danger[key]=nil
                else dangerEntries[#dangerEntries+1]={key=key,untilTime=memory.untilTime} end
            end
            table.sort(dangerEntries,function(a,b) return a.untilTime>b.untilTime end)
            for index=33,#dangerEntries do r.danger[dangerEntries[index].key]=nil end
            if paused then r.lastNeeds=now;r.use=nil
            else
                local ticks=math.floor((now-r.lastNeeds)/10000)
                if ticks>0 then
                    r.lastNeeds=r.lastNeeds+ticks*10000
                    r.food=math.max(0,r.food-ticks);r.water=math.max(0,r.water-ticks*1.5)
                    local damage=(r.bleeding and 2 or 0)+(r.food<=0 and 3 or 0)+(r.water<=0 and 4 or 0)
                    r.hp=math.max(0,r.hp-damage*ticks);syncNeeds(ped,r)
                end
                if closeCount>0 or now<r.fleeUntil or r.hp<=0 then r.use=nil else consume(ped,r,now) end
                rememberLoot(ped,r,now)
            end
            if r.hp<=0 then killPed(ped);corpse(ped,r)
            else
                if r.loot and (not wanted(r,r.loot) or not world(ped,r.loot) or now-r.lootSince>45000 or r.navigation=="blocked" and now-r.lootSince>6000) then
                    if isElement(r.loot) then r.ignored[r.loot]=now+120000 end
                    r.loot=nil
                end
                local candidate=not paused and lootGoal(ped,r,now) or nil
                local decision=DayZSurvivorBrain.decide({paused=paused,hp=r.hp,ammo=r.ammo,personality=r.personality,
                    nearest=target and best or nil,enemies=closeCount,use=r.use and r.use.state,
                    fleeing=now<r.fleeUntil,loot=candidate})
                local state=decision.state
                local previousState=getElementData(ped,"survivor:state")
                if state~=previousState then
                    outputDebugString("[DayZ survivors] "..r.personality.name.." chose "..decision.goal..": "..decision.reason,3)
                    if state=="patrol" then r.progress=now;r.routeStarted=now end
                end
                r.goal=decision.goal;r.reason=decision.reason;r.goalScore=decision.score
                data(ped,"goal",r.goal);data(ped,"reason",r.reason)
                if state=="retreat" then
                    if closeCount>0 then r.fleeUntil=now+5000 end
                    data(ped,"waypoint",safeWaypoint(ped,r,zombies,now));r.use=nil;r.loot=nil
                elseif state=="loot" then
                    if r.loot~=candidate.col then r.lootSince=now;r.lootStatus="Approaching" end
                    r.loot=candidate.col
                    local x,y,z=getElementPosition(r.loot);data(ped,"waypoint",{x,y,z})
                elseif state=="patrol" then
                    r.loot=nil
                    local wp=r.route[r.index];local x,y,z=getElementPosition(ped)
                    local arrived=((x-wp[1])^2+(y-wp[2])^2)^0.5<2
                    local timedOut=now-r.routeStarted>45000
                    local stuck=now-r.progress>6000
                    if arrived or timedOut or stuck then
                        if arrived then r.visited[r.index]=now
                        else r.blockedRoutes[r.index]=now+120000 end
                        r.index=nextExplore(ped,r,now);r.progress=now;r.routeStarted=now
                    elseif getDistanceBetweenPoints3D(x,y,z,r.px,r.py,r.pz)>0.7 then
                        r.px=x;r.py=y;r.pz=z;r.progress=now
                    end
                    data(ped,"waypoint",r.route[r.index])
                else r.loot=nil end
                data(ped,"lootTarget",r.loot or false);data(ped,"state",state);data(ped,"target",target or false)
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

-- The owner's client supplies visibility observations; positions, container type
-- and distance are checked here. Reports never include item grants or coordinates.
addEvent("dayz:survivorSenseLoot",true)
addEventHandler("dayz:survivorSenseLoot",root,function(ped,observed,visibleZombies)
    local r=survivors[ped]
    if source~=client or not r or client~=r.owner or not isElement(ped) or isPedDead(ped)
        or not world(ped,client) or range(ped,client)>180 or type(observed)~="table" or #observed>8
        or type(visibleZombies)~="table" or #visibleZombies>16 then return end
    local now=getTickCount()
    if r.lastSense and now-r.lastSense<1000 then return end
    r.lastSense=now;r.sensedCount=0
    r.zombieSight={}
    for index=1,#visibleZombies do
        local zombie=visibleZombies[index]
        if isElement(zombie) and getElementType(zombie)=="ped" and getElementData(zombie,"zombie")
            and not isPedDead(zombie) and world(ped,zombie) and range(ped,zombie)<=30 then
            r.zombieSight[zombie]=now
        end
    end
    local unique={}
    for index=1,#observed do
        local col=observed[index]
        if lootable(col) and world(ped,col) and range(ped,col)<=50 and getDayZSlots(col)>0 and not unique[col] then
            unique[col]=true;r.lootMemory[col]=now;r.sensedCount=r.sensedCount+1
        end
    end
    data(ped,"sensedLoot",r.sensedCount)
    rememberLoot(ped,r,now)
end)
