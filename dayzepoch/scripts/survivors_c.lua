local previous,avoidance,navigation,sensingCursor={},{},{},{}
local function stop(ped)
    for _,control in ipairs({"forwards","backwards","sprint","aim_weapon","fire","jump"}) do setPedControlState(ped,control,false) end
end
local function face(ped,x,y)
    local px,py=getElementPosition(ped)
    setPedRotation(ped,math.deg(math.atan2(-(x-px),y-py)))
end
local function reportNavigation(ped,status)
    if getElementData(ped,"survivor:owner")~=localPlayer then return end
    local old=navigation[ped];local now=getTickCount()
    if not old or now-old.time>=1500 and old.status~=status then
        navigation[ped]={status=status,time=now}
        triggerServerEvent("dayz:survivorNavigation",localPlayer,ped,status)
    end
end
local function safeDirection(ped,heading)
    local x,y,z=getElementPosition(ped)
    local radians=math.rad(heading)
    local dx,dy=-math.sin(radians),math.cos(radians)
    local tx,ty=x+dx*2.5,y+dy*2.5
    local ground=getGroundPosition(x,y,z+1)
    local ahead=getGroundPosition(tx,ty,z+1)
    if type(ground)~="number" or type(ahead)~="number" or ahead-ground>1.2 or ground-ahead>1.8 then return false end
    for _,width in ipairs({-0.35,0.35}) do
        for _,height in ipairs({0.4,1.2}) do
            local sx,sy=x+dy*width,y-dx*width
            if not isLineOfSightClear(sx,sy,ground+height,sx+dx*2.5,sy+dy*2.5,ground+height,true,true,false,true,false,false,false,ped) then return false end
        end
    end
    return true
end
local function walkTowards(ped,tx,ty)
    local x,y=getElementPosition(ped)
    local heading=math.deg(math.atan2(-(tx-x),ty-y))
    local memory=avoidance[ped];local now=getTickCount()
    if memory and now<memory.untilTime and safeDirection(ped,memory.heading) then
        setPedRotation(ped,memory.heading);setPedControlState(ped,"forwards",true)
        reportNavigation(ped,"detouring");return true
    end
    if safeDirection(ped,heading) then
        avoidance[ped]=nil;setPedRotation(ped,heading);setPedControlState(ped,"forwards",true)
        reportNavigation(ped,"walking");return true
    end
    local sign=memory and memory.sign or 1
    for _,offset in ipairs({35,70,110,150}) do
        for _,side in ipairs({sign,-sign}) do
            local alternative=heading+offset*side
            if safeDirection(ped,alternative) then
                avoidance[ped]={heading=alternative,sign=side,untilTime=now+1500}
                setPedRotation(ped,alternative);setPedControlState(ped,"forwards",true)
                reportNavigation(ped,"detouring");return true
            end
        end
    end
    setPedControlState(ped,"forwards",false);reportNavigation(ped,"blocked");return false
end
setTimer(function()
    for _,ped in ipairs(getElementsByType("ped",root,true)) do
        if getElementData(ped,"survivor:active") and isElementSyncer(ped) then
            stop(ped)
            local state=getElementData(ped,"survivor:state")
            local target=getElementData(ped,"survivor:target")
            if not isPedDead(ped) and (state=="combat" or state=="retreat") and isElement(target) and not isPedDead(target) then
                local x,y,z=getElementPosition(target);local px,py,pz=getElementPosition(ped)
                face(ped,x,y);setPedAimTarget(ped,x,y,z+0.5)
                local clear=isLineOfSightClear(px,py,pz+0.7,x,y,z+0.5,true,true,false,true,false,false,false,ped)
                if clear and getElementData(ped,"survivor:owner")==localPlayer then triggerServerEvent("dayz:survivorSight",localPlayer,ped,target) end
                setPedControlState(ped,"aim_weapon",state=="combat")
                if state=="retreat" then
                    local wp=getElementData(ped,"survivor:waypoint")
                    if type(wp)=="table" then walkTowards(ped,wp[1],wp[2]) else walkTowards(ped,px+(px-x),py+(py-y)) end
                else reportNavigation(ped,"waiting") end
            elseif not isPedDead(ped) and (state=="patrol" or state=="loot" or state=="retreat") then
                local wp=getElementData(ped,"survivor:waypoint")
                if type(wp)=="table" then
                    local x,y,z=getElementPosition(ped)
                    local d=getDistanceBetweenPoints3D(x,y,z,wp[1],wp[2],wp[3])
                    local horizontal=((x-wp[1])^2+(y-wp[2])^2)^0.5
                    local col=getElementData(ped,"survivor:lootTarget")
                    local inReach=state=="loot" and isElement(col) and d<=4 and isElementWithinColShape(ped,col)
                    if not inReach and horizontal>1.2 then walkTowards(ped,wp[1],wp[2])
                    else face(ped,wp[1],wp[2]);reportNavigation(ped,"waiting") end
                    if inReach and getElementData(ped,"survivor:owner")==localPlayer then
                        -- The crate itself is the interaction target, not an obstacle.
                        local parent=getElementData(col,"parent")
                        local ignored=isElement(parent) and getElementType(parent)=="object" and parent or ped
                        local clear=isLineOfSightClear(x,y,z+0.7,wp[1],wp[2],wp[3]+0.7,true,true,false,true,false,false,false,ignored)
                        triggerServerEvent("dayz:survivorLoot",localPlayer,ped,col,clear)
                    end
                    local old=previous[ped]
                    if not old or getDistanceBetweenPoints3D(x,y,z,old.x,old.y,old.z)>0.7 then previous[ped]={x=x,y=y,z=z,time=getTickCount()}
                    elseif not inReach and getTickCount()-old.time>2500 then
                        -- Jump only when the forward corridor is actually clear.
                        local heading=math.deg(math.atan2(-(wp[1]-x),wp[2]-y))
                        if safeDirection(ped,heading) then setPedControlState(ped,"jump",true) end
                    end
                end
            else reportNavigation(ped,"waiting") end
        end
    end
    for ped in pairs(previous) do if not isElement(ped) then previous[ped]=nil;avoidance[ped]=nil;navigation[ped]=nil;sensingCursor[ped]=nil end end
end,250,0)
addEvent("dayz:survivorShot",true)
addEventHandler("dayz:survivorShot",resourceRoot,function(ped,target)
    if not isElement(ped) or not isElement(target) or not getElementData(ped,"survivor:active") or not isElementSyncer(ped) then return end
    local x,y,z=getElementPosition(target);setPedAimTarget(ped,x,y,z+0.5)
    setPedControlState(ped,"aim_weapon",true);setPedControlState(ped,"fire",true)
    setTimer(function() if isElement(ped) then setPedControlState(ped,"fire",false) end end,100,1)
end)
-- Native bullet/melee damage is not added on top of the server's prototype combat.
addEventHandler("onClientPedDamage",root,function(attacker)
    if getElementData(source,"survivor:active") or isElement(attacker) and getElementData(attacker,"survivor:active") then cancelEvent() end
end)
addEventHandler("onClientResourceStop",resourceRoot,function()
    for _,ped in ipairs(getElementsByType("ped")) do if getElementData(ped,"survivor:active") then stop(ped) end end
end)

-- A 360-degree local awareness scan, with walls blocking actual observations.
setTimer(function()
    for _,ped in ipairs(getElementsByType("ped",root,true)) do
        if getElementData(ped,"survivor:active") and getElementData(ped,"survivor:owner")==localPlayer
            and isElementSyncer(ped) and not isPedDead(ped) and getElementData(ped,"survivor:state")~="paused" then
            local x,y,z=getElementPosition(ped)
            local seen={}
            for _,col in ipairs(getElementsByType("colshape")) do
                if (getElementData(col,"itemloot") or getElementData(col,"airdrop") or getElementData(col,"deadman"))
                    and not getElementData(col,"safe") and not getElementData(col,"vehicle") and not getElementData(col,"tent")
                    and getElementDimension(col)==getElementDimension(ped) and getElementInterior(col)==getElementInterior(ped)
                    and getDayZSlots(col)>0 then
                    local cx,cy,cz=getElementPosition(col)
                    local d=getDistanceBetweenPoints3D(x,y,z,cx,cy,cz)
                    if d<=50 then
                        local parent=getElementData(col,"parent")
                        local ignored=isElement(parent) and getElementType(parent)=="object" and parent or ped
                        if isLineOfSightClear(x,y,z+0.7,cx,cy,cz+0.7,true,true,false,true,false,false,false,ignored) then
                            seen[#seen+1]={col=col,distance=d}
                        end
                    end
                end
            end
            table.sort(seen,function(a,b) return a.distance<b.distance end)
            local batch={}
            if #seen>0 then
                local offset=sensingCursor[ped] or 0
                for index=1,math.min(8,#seen) do batch[index]=seen[(offset+index-1)%#seen+1].col end
                sensingCursor[ped]=(offset+#batch)%#seen
            end
            local threats={}
            for _,zombie in ipairs(getElementsByType("ped",root,true)) do
                if getElementData(zombie,"zombie") and not isPedDead(zombie)
                    and getElementDimension(zombie)==getElementDimension(ped) and getElementInterior(zombie)==getElementInterior(ped) then
                    local zx,zy,zz=getElementPosition(zombie)
                    local d=getDistanceBetweenPoints3D(x,y,z,zx,zy,zz)
                    if d<=30 and isLineOfSightClear(x,y,z+0.7,zx,zy,zz+0.7,true,true,false,true,false,false,false,ped) then
                        threats[#threats+1]={ped=zombie,distance=d}
                    end
                end
            end
            table.sort(threats,function(a,b) return a.distance<b.distance end)
            local visibleZombies={}
            for index=1,math.min(16,#threats) do visibleZombies[index]=threats[index].ped end
            triggerServerEvent("dayz:survivorSenseLoot",localPlayer,ped,batch,visibleZombies)
        end
    end
end,1500,0)
