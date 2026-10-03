local handlers,timers,reports,navReports={}, {},{},{}
local clock=10000
root={};resourceRoot={};localPlayer={}
local ped={data={['survivor:active']=true,['survivor:owner']=localPlayer,['survivor:state']='patrol',['survivor:waypoint']={10,0,0}},controls={},x=0,y=0,z=0}
local target={data={},x=5,y=0,z=0}
local clear=true
function isElement(e) return type(e)=='table' end
function getElementType(e) return e.kind or "colshape" end
function isElementWithinColShape() return true end
function getElementData(e,k) return e.data and e.data[k] end
function getElementsByType() return {ped} end
function isElementSyncer() return true end
function isPedDead() return false end
function getElementPosition(e) return e.x,e.y,e.z end
function setPedControlState(e,k,v) e.controls[k]=v end
function setPedRotation(e,r) e.rotation=r end
function setPedAimTarget(e,x,y,z) e.aim={x,y,z} end
function isLineOfSightClear() return clear end
function getTickCount() return clock end
function getGroundPosition() return 0 end
function getDistanceBetweenPoints3D(x,y,z,a,b,c) return ((x-a)^2+(y-b)^2+(z-c)^2)^0.5 end
function triggerServerEvent(...) local args={...};if args[1]=="dayz:survivorNavigation" then navReports[#navReports+1]=args else reports[#reports+1]=args end end
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
ped.data['survivor:state']='retreat';timers[1].fn();assert(ped.controls.forwards and not ped.controls.aim_weapon)
ped.data['survivor:state']='paused';timers[1].fn();assert(not ped.controls.backwards and not ped.controls.forwards)
print('PASS survivor patrol, visibility, shot pulse, retreat and pause controls')

ped.data['survivor:state']='loot';ped.data['survivor:waypoint']={1,0,0};ped.data['survivor:lootTarget']=target
local n=#reports;clear=false;timers[1].fn();assert(#reports==n+1 and reports[#reports][5]==false)
clear=true;timers[1].fn();assert(reports[#reports][1]=='dayz:survivorLoot' and reports[#reports][4]==target and reports[#reports][5]==true)
print('PASS survivor loot approach checks visibility before requesting transfer')

local crate={kind='object',data={}};target.data.parent=crate
ped.data['survivor:waypoint']={3,0,0}
local ignored
function isLineOfSightClear(...) local args={...};ignored=args[14];return ignored==crate end
timers[1].fn();assert(ignored==crate and reports[#reports][5]==true and not ped.controls.forwards)
print('PASS crate edge looting ignores target crate collision and stops walking')

-- Rays directly east hit a wall; side routes remain open.
ped.data['survivor:state']='patrol';ped.data['survivor:waypoint']={10,0,0};clock=clock+2000
function isLineOfSightClear(sx,sy,sz,tx,ty) return math.abs(ty-sy)>0.5 end
timers[1].fn();assert(ped.controls.forwards and math.abs(ped.rotation+90)>10)
assert(navReports[#navReports][4]=='detouring')
print('PASS blocked forward route selects a clear side corridor')
clock=clock+2000
function isLineOfSightClear() return false end
timers[1].fn();assert(not ped.controls.forwards and not ped.controls.jump)
assert(navReports[#navReports][4]=='blocked')
print('PASS fully blocked routes stop instead of walking into a wall')
clock=clock+2000
function isLineOfSightClear() return true end
function getGroundPosition(x,y) if x*x+y*y>1 then return -10 end;return 0 end
timers[1].fn();assert(not ped.controls.forwards)
print('PASS steep drops reject walking directions')
clock=clock+2000
function getGroundPosition() return 0 end
timers[1].fn();assert(ped.controls.forwards and math.abs(ped.rotation+90)<0.01)
print('PASS clear route resumes direct movement')
