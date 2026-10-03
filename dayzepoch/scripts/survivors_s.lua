-- Small, admin-owned prototype. Navigation/visibility uses the owner's client;
-- the server owns targets, ammunition, damage, health and lifetime.
local survivors={}
local function data(p,k,v) setDayZData(p,"survivor:"..k,v) end
-- Avoid Lua multiple-return truncation when passing two positions.
local function range(a,b)
    local x,y,z=getElementPosition(a);local tx,ty,tz=getElementPosition(b)
    return getDistanceBetweenPoints3D(x,y,z,tx,ty,tz)
end
function DayZSpawnTestSurvivor(player)
    local count=0
    for ped,record in pairs(survivors) do if isElement(ped) and record.owner==player then count=count+1 end end
    if count>=3 then return nil,"Three survivors are active. Clean up first." end
    local x,y,z=getElementPosition(player)
    local ped=createPed(287,x+4,y,z)
    if not isElement(ped) then return nil,"Survivor creation failed; check the server log." end
    local route={{x+4,y,z},{x+16,y,z},{x+16,y+12,z},{x+4,y+12,z}}
    survivors[ped]={owner=player,route=route,index=2,ammo=40,hp=100,lastShot=0,lastMelee=0,progress=getTickCount(),px=x+4,py=y,pz=z}
    if not setElementSyncer(ped,player,true) then
        survivors[ped]=nil;destroyElement(ped)
        outputDebugString("[DayZ survivors] Could not assign survivor controller",2)
        return nil,"Could not assign survivor controller; nothing spawned."
    end
    giveWeapon(ped,25,40,true)
    setElementHealth(ped,100)
    data(ped,"active",true);data(ped,"owner",player);data(ped,"ammo",40);data(ped,"health",100)
    data(ped,"state","patrol");data(ped,"waypoint",route[2])
    outputDebugString("[DayZ survivors] Spawned patrol survivor for "..getAccountName(getPlayerAccount(player)),3)
    return ped,"Survivor spawned: shotgun, 40 shells, short square patrol. Spawn test zombies nearby to test combat. Expires in 15 minutes."
end
function DayZInspectTestSurvivors(player)
    local lines={}
    for ped,r in pairs(survivors) do
        if isElement(ped) and r.owner==player then
            lines[#lines+1]="Survivor: "..tostring(getElementData(ped,"survivor:state")).." | HP "..r.hp.." | shells "..r.ammo.." | distance "..math.floor(range(player,ped)).."m"
        end
    end
    return #lines>0 and table.concat(lines,"\n") or "No active survivors belonging to you."
end
setTimer(function()
    for ped,r in pairs(survivors) do
        if not isElement(ped) then survivors[ped]=nil
        elseif not isElement(r.owner) then destroyElement(ped);survivors[ped]=nil
        elseif isPedDead(ped) then data(ped,"state","dead");data(ped,"target",false)
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
            local state=range(ped,r.owner)>180 and "paused" or target and ((r.ammo<=0 or r.hp<=30) and "retreat" or "combat") or "patrol"
            data(ped,"state",state);data(ped,"target",target or false)
            if state=="patrol" then
                local wp=r.route[r.index];local x,y,z=getElementPosition(ped)
                if getDistanceBetweenPoints3D(x,y,z,unpack(wp))<2 then
                    r.index=r.index%#r.route+1;r.progress=getTickCount()
                elseif getDistanceBetweenPoints3D(x,y,z,r.px,r.py,r.pz)>0.7 then
                    r.px=x;r.py=y;r.pz=z;r.progress=getTickCount()
                elseif getTickCount()-r.progress>6000 then
                    r.index=r.index%#r.route+1;r.progress=getTickCount()
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
        or not getElementData(target,"zombie") or range(ped,client)>180
        or getElementDimension(ped)~=getElementDimension(target) or getElementInterior(ped)~=getElementInterior(target) then return end
    local now=getTickCount();local d=range(ped,target)
    if d<1.8 and now-r.lastMelee>=1000 then
        r.lastMelee=now;r.hp=math.max(0,r.hp-15)
        data(ped,"health",r.hp);setElementHealth(ped,r.hp)
        if r.hp<=0 then killPed(ped,target);return end
    end
    if getElementData(ped,"survivor:state")~="combat" or d>25 or r.ammo<=0 or now-r.lastShot<900 then return end
    r.lastShot=now;r.ammo=r.ammo-1;data(ped,"ammo",r.ammo)
    triggerClientEvent(root,"dayz:survivorShot",resourceRoot,ped,target)
    local blood=(tonumber(getElementData(target,"blood")) or 10000)-2500
    setDayZData(target,"blood",blood)
    if blood<=0 then
        outputDebugString("[DayZ survivors] Survivor killed a zombie; shells remaining "..r.ammo,3)
        triggerEvent("onZombieGetsKilled",target,ped,false,25)
    end
end)
