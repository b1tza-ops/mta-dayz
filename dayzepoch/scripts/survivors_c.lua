local previous={}
local function stop(ped)
    for _,control in ipairs({"forwards","backwards","sprint","aim_weapon","fire","jump"}) do setPedControlState(ped,control,false) end
end
local function face(ped,x,y)
    local px,py=getElementPosition(ped)
    setPedRotation(ped,math.deg(math.atan2(-(x-px),y-py)))
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
                setPedControlState(ped,"backwards",state=="retreat")
            elseif not isPedDead(ped) and (state=="patrol" or state=="loot") then
                local wp=getElementData(ped,"survivor:waypoint")
                if type(wp)=="table" then
                    local x,y,z=getElementPosition(ped)
                    local d=getDistanceBetweenPoints3D(x,y,z,wp[1],wp[2],wp[3])
                    face(ped,wp[1],wp[2]);setPedControlState(ped,"forwards",d>1.2)
                    local col=getElementData(ped,"survivor:lootTarget")
                    if state=="loot" and d<=2 and isElement(col) and getElementData(ped,"survivor:owner")==localPlayer
                        and isLineOfSightClear(x,y,z+0.5,wp[1],wp[2],wp[3]+0.5,true,true,false,true,false,false,false,ped) then
                        triggerServerEvent("dayz:survivorLoot",localPlayer,ped,col)
                    end
                    local old=previous[ped]
                    if not old or getDistanceBetweenPoints3D(x,y,z,old.x,old.y,old.z)>0.7 then previous[ped]={x=x,y=y,z=z,time=getTickCount()}
                    elseif getTickCount()-old.time>2500 then setPedControlState(ped,"jump",true) end
                end
            end
        end
    end
    for ped in pairs(previous) do if not isElement(ped) then previous[ped]=nil end end
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
