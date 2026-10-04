-- Own only these custom engine loops; never manipulate unrelated attached sounds.
local models={
 [487]='heli.mp3',[497]='heli.mp3',[528]='armoredtruck.mp3',[470]='hmmwv.mp3',
 [422]='pickuptruck.mp3',[468]='motorcycle.mp3',[433]='uralmilitary.mp3',
 [473]='pbx.mp3',[471]='atv.mp3',[463]='motorbike.mp3',[490]='suv.mp3',
 [531]='tractor.mp3',[579]='uaz.mp3',[421]='golfiw211.mp3',[456]='modernvan.mp3'
}
local loops,retry={},{}
local function remove(vehicle)
 local entry=loops[vehicle]
 if entry and isElement(entry.sound) then destroyElement(entry.sound) end
 loops[vehicle]=nil;retry[vehicle]=nil
end
local function clear()
 for vehicle in pairs(loops) do remove(vehicle) end
 retry={}
end
local function eligible(vehicle)
 return isElement(vehicle) and getElementType(vehicle)=='vehicle' and isElementStreamedIn(vehicle)
  and models[getElementModel(vehicle)] and not getElementData(vehicle,'helicrash')
  and not getElementData(vehicle,'isExploded') and getElementHealth(vehicle)>0
  and getElementDimension(vehicle)==getElementDimension(localPlayer)
  and getElementInterior(vehicle)==getElementInterior(localPlayer)
end
local function update()
 if not getElementData(localPlayer,'logedin') then clear();return end
 for vehicle,entry in pairs(loops) do
  if not eligible(vehicle) or entry.model~=getElementModel(vehicle) then remove(vehicle) end
 end
 for vehicle in pairs(retry) do if not eligible(vehicle) then retry[vehicle]=nil end end
 for _,vehicle in ipairs(getElementsByType('vehicle',root,true)) do
  if eligible(vehicle) then
   local model=getElementModel(vehicle)
   local heli=model==487 or model==497
   local rotor=heli and (tonumber(getVehicleRotorSpeed(vehicle)) or 0) or 0
   local running=getVehicleEngineState(vehicle) and (not heli or rotor>0.001)
   if not running then
    -- Removing stopped loops prevents stale paused audio and saves sound channels.
    remove(vehicle)
   else
    local entry=loops[vehicle]
    if entry and not isElement(entry.sound) then loops[vehicle]=nil;entry=nil end
    local now=getTickCount()
    if not entry and (not retry[vehicle] or now>=retry[vehicle]) then
     local x,y,z=getElementPosition(vehicle)
     local sound=playSound3D('sounds/vehicles/'..models[model],x,y,z,true)
     if isElement(sound) then
      entry={sound=sound,model=model};loops[vehicle]=entry;retry[vehicle]=nil
      setElementDimension(sound,getElementDimension(vehicle));setElementInterior(sound,getElementInterior(vehicle))
      attachElements(sound,vehicle);setSoundMinDistance(sound,10)
      setSoundMaxDistance(sound,heli and 300 or 150)
     else
      retry[vehicle]=now+5000
      outputDebugString('[DayZ vehicle audio] Could not create engine loop for model '..model..'; retrying in 5 seconds.',2)
     end
    end
    if entry then
     local speed
     if heli then speed=math.max(0.05,math.min(2,rotor*4.5))
     else
      local vx,vy,vz=getElementVelocity(vehicle)
      speed=math.max(0.05,math.min(2,((vx*vx+vy*vy+vz*vz)^0.5*180+20)/50))
     end
     setSoundSpeed(entry.sound,speed);setSoundPaused(entry.sound,false)
    end
   end
  end
 end
end
setTimer(update,250,0)
addEventHandler('onClientElementStreamOut',root,function() remove(source) end)
addEventHandler('onClientElementDestroy',root,function() remove(source) end)
addEventHandler('onClientRestore',root,clear)
addEventHandler('onClientResourceStop',resourceRoot,clear)
addCommandHandler('fixvehiclesounds',function()
 clear();update()
 outputChatBox('[DayZ] Custom vehicle engine sounds refreshed.',100,220,140)
 outputDebugString('[DayZ vehicle audio] Manual loop recovery completed.',3)
end)
outputDebugString('[DayZ vehicle audio] Engine loop checks enabled every 250 ms.',3)
