-- Server behaviour tests for the admin testing panel; run with texlua.
unpack=unpack or table.unpack
local handlers,elements,timers={}, {},{}
local now,passed=10000,0
local function E(kind,x,y,z)
 local e={kind=kind,data={},alive=true,x=x or 0,y=y or 0,z=z or 0,dim=0,int=0};elements[#elements+1]=e;return e
end
root=E('root');resourceRoot=E('resource');configVar={maxzombies=40}
function isElement(e) return type(e)=='table' and e.alive end
function getElementType(e) return e.kind end
function getPlayerAccount(e) return e.account end
function isGuestAccount(a) return a.guest end
function aclGetGroup() return {} end
function getAccountName(a) return a.name end
function isObjectInACLGroup(name) return name=='user.b1tza' end
function getElementData(e,k) assert(isElement(e));return e.data[k] or false end
function setDayZData(e,k,v) assert(isElement(e));e.data[k]=v end
function getElementPosition(e) return e.x,e.y,e.z end
function setElementPosition(e,x,y,z) e.x=x;e.y=y;e.z=z end
function getElementRotation() return 0,0,0 end
function getElementDimension(e) return e.dim end
function getElementInterior(e) return e.int end
function setElementDimension(e,d) e.dim=d end
function setElementInterior(e,i) e.int=i end
function getPedOccupiedVehicle(e) return e.vehicle end
function isPedDead(e) return e.dead or false end
function getTickCount() return now end
function addEvent() end
function addEventHandler(name,target,fn) handlers[name]=handlers[name] or {};handlers[name][#handlers[name]+1]=fn end
function outputDebugString() end
function triggerClientEvent(target,event,origin,message) target.last={event=event,message=message} end
function setTimer(fn,ms,n,...) local t={fn=fn,ms=ms,args={...}};timers[#timers+1]=t;return t end
function isTimer(t) return t and t.fn~=nil end
function killTimer(t) t.fn=nil end
function destroyElement(e) e.alive=false end
function getElementsByType(kind) local found={};for _,e in ipairs(elements) do if isElement(e) and e.kind==kind then found[#found+1]=e end end;return found end
function getElementsWithinColShape() return {} end
function createZombie(x,y,z) local e=E('ped',x,y,z);e.data.zombie=true;return e end
local failObject=false
function createObject(model,x,y,z) if failObject then return false end;local e=E('object',x,y,z);e.model=model;return e end
function createColSphere(x,y,z) return E('colshape',x,y,z) end
function createBlip(x,y,z) return E('blip',x,y,z) end
function attachElements() end
function setElementFrozen() end
function moveObject() end
function getDistanceBetweenPoints3D(x,y,z,a,b,c) return ((x-a)^2+(y-b)^2+(z-c)^2)^0.5 end
function getVehicleName() return 'Test vehicle' end
function getElementModel(e) return e.model or 422 end
function getElementHealth() return 900 end
function getVehicleEngineState() return false end
function getDayZSlots() return 2 end
local function P(name) local e=E('player');e.account={name=name};e.data.logedin=true;return e end
local admin=P('b1tza');local ordinary=P('other')
dofile('dayzepoch/scripts/shared/admin_testing_locations.lua')
dofile('dayzepoch/scripts/admin_testing_s.lua')
local function action(who,name,value,origin)
 now=now+6000;client=who;source=origin or who;handlers['dayz:testAction'][1](name,value);client=nil;source=nil
end
local function test(name,fn) fn();passed=passed+1;print('PASS '..name) end
local function active(kind) return #getElementsByType(kind) end
local function runTimer(ms)
 for i=#timers,1,-1 do local t=timers[i];if t.ms==ms and t.fn then local fn=t.fn;t.fn=nil;fn(unpack(t.args));return end end
 error('Missing timer '..ms)
end
test('non-admin and spoofed callers cannot open or spawn',function()
 action(ordinary,'open');assert(not ordinary.last)
 action(admin,'zombies',3,ordinary);assert(active('ped')==0)
 action(ordinary,'airdrop');assert(active('object')==0)
end)
test('teleport uses preset and restores dimension/interior/position',function()
 admin.x=20;admin.y=30;admin.z=40;admin.dim=2;admin.int=3
 action(admin,'teleport',1);assert(admin.x==DayZAdminTestLocations[1].x and admin.dim==0 and admin.int==0)
 action(admin,'back');assert(admin.x==20 and admin.y==30 and admin.z==40 and admin.dim==2 and admin.int==3)
end)
test('invalid locations and occupied vehicles do not teleport',function()
 local x=admin.x;action(admin,'teleport',999);assert(admin.x==x)
 admin.vehicle={};action(admin,'teleport',1);assert(admin.x==x);admin.vehicle=nil
end)
test('zombie spawning enforces world, count and ownership',function()
 action(admin,'zombies',3);assert(active('ped')==0)
 admin.dim=0;admin.int=0
 action(admin,'zombies',11);assert(active('ped')==0)
 action(admin,'zombies',3);assert(active('ped')==3 and admin.data.spawnedzombies==3)
 for _,ped in ipairs(getElementsByType('ped')) do assert(ped.data.owner==admin and ped.data.blood==10000) end
end)
test('cleanup removes only callers test spawns and restores counters',function()
 local unrelated=E('ped');action(admin,'cleanup');assert(active('ped')==1 and isElement(unrelated) and admin.data.spawnedzombies==0)
end)
test('airdrop is populated and cannot be looted until landing',function()
 action(admin,'airdrop');local col=getElementsByType('colshape')[1]
 assert(col.data.weapon11==1 and col.data.mag5==120 and not col.data.airdrop)
 runTimer(10000);assert(col.data.airdrop and active('object')==1)
end)
test('airdrop cap and cleanup include landing timer and markers',function()
 action(admin,'airdrop');local count=active('object');action(admin,'airdrop');assert(active('object')==count)
 action(admin,'cleanup');assert(active('object')==0 and active('blip')==0 and active('colshape')==0)
 for _,t in ipairs(timers) do if t.ms==10000 then assert(not t.fn) end end
end)
test('failed creation rolls back partial airdrop elements',function()
 failObject=true;action(admin,'airdrop');assert(active('colshape')==0 and active('blip')==0);failObject=false
end)
test('inspect respects proximity/world and preserves vehicle state',function()
 local v=E('vehicle',admin.x+2,admin.y,admin.z);local col=E('colshape');v.data.parent=col;v.data.maxfuel=80;col.data.fuel=10;col.data.MAX_Slots=20;col.data.needengines=1
 action(admin,'inspect');assert(admin.last.message:find('Fuel: 10 / 80',1,true) and admin.last.message:find('Engines: 0 / 1',1,true));assert(col.data.fuel==10)
 v.dim=99;action(admin,'inspect');assert(admin.last.message:find('No vehicle',1,true))
end)
test('cooldown prevents rapid repeat mutations',function()
 action(admin,'zombies',1);local count=active('ped');client=admin;source=admin;handlers['dayz:testAction'][1]('zombies',1);client=nil;source=nil;assert(active('ped')==count)
end)
test('quit cleans active assets',function()
 source=admin;handlers.onPlayerQuit[1]();source=nil;assert(admin.data.spawnedzombies==0)
end)
print(passed..' admin testing behaviour checks passed')
