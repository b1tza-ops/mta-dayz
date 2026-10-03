local handlers,timers,reports={}, {},{}
root={};resourceRoot={};localPlayer={}
local ped={data={['survivor:active']=true,['survivor:owner']=localPlayer,['survivor:state']='patrol',['survivor:waypoint']={10,0,0}},controls={},x=0,y=0,z=0}
local target={data={},x=5,y=0,z=0}
local clear=true
function isElement(e) return type(e)=='table' end
function getElementData(e,k) return e.data and e.data[k] end
function getElementsByType() return {ped} end
function isElementSyncer() return true end
function isPedDead() return false end
function getElementPosition(e) return e.x,e.y,e.z end
function setPedControlState(e,k,v) e.controls[k]=v end
function setPedRotation(e,r) e.rotation=r end
function setPedAimTarget(e,x,y,z) e.aim={x,y,z} end
function isLineOfSightClear() return clear end
function getTickCount() return 10000 end
function getDistanceBetweenPoints3D(x,y,z,a,b,c) return ((x-a)^2+(y-b)^2+(z-c)^2)^0.5 end
function triggerServerEvent(...) reports[#reports+1]={...} end
function setTimer(fn,ms) timers[#timers+1]={fn=fn,ms=ms} end
function addEvent() end
function addEventHandler(name,_,fn) handlers[name]=fn end
function cancelEvent() end
dofile('dayzepoch/scripts/survivors_c.lua')
timers[1].fn();assert(ped.controls.forwards and ped.rotation)
ped.data['survivor:state']='combat';ped.data['survivor:target']=target
clear=false;timers[1].fn();assert(#reports==0 and not ped.controls.forwards and ped.controls.aim_weapon)
clear=true;timers[1].fn();assert(#reports==1 and reports[1][1]=='dayz:survivorSight' and reports[1][3]==ped and reports[1][4]==target)
handlers['dayz:survivorShot'](ped,target);assert(ped.controls.fire)
timers[#timers].fn();assert(not ped.controls.fire)
ped.data['survivor:state']='retreat';timers[1].fn();assert(ped.controls.backwards and not ped.controls.aim_weapon)
ped.data['survivor:state']='paused';timers[1].fn();assert(not ped.controls.backwards and not ped.controls.forwards)
print('PASS survivor patrol, visibility, shot pulse, retreat and pause controls')
