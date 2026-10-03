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
function createColSphere(x,y,z,radius) local e=E('colshape',x,y,z);e.radius=radius or 1.25;return e end
function isElementWithinColShape(e,col) return getDistanceBetweenPoints3D(e.x,e.y,e.z,col.x,col.y,col.z)<=col.radius end
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
local failVehicle=false
function createVehicle(model,x,y,z) if failVehicle then return false end;local e=E('vehicle',x,y,z);e.model=model;return e end
function getVehicleAddonInfos(id) if id==487 then return 0,1,1,1,1,20 end;return 4,1,1,1,0,25 end
function getVehicleMaxFuel() return 80 end
function fixVehicle(e) e.fixed=true end
function setElementHealth(e,v) e.health=v end
function setVehicleLocked(e,v) e.locked=v end
function setVehicleEngineState(e,v) e.engine=v end
dofile('dayzepoch/scripts/shared/admin_testing_locations.lua')
function createPed(model,x,y,z) local e=E('ped',x,y,z);e.model=model;return e end
function setElementSyncer(e,p,persist) assert(persist==true);e.syncer=p;return true end
function giveWeapon(e,w,a) e.weapon=w;e.ammo=a end
function setElementHealth(e,h) e.health=h end
function killPed(e) e.dead=true end
local killedTarget
function triggerEvent(name,target) if name=='onZombieGetsKilled' then killedTarget=target;destroyElement(target) end end
function getRealTime() return {hour=12,minute=0} end
function dayZRefreshInventory() end
function setWeaponAmmo(e,w,a) e.ammo=a end
dofile('dayzepoch/scripts/shared/inventory_items.lua')
dofile('dayzepoch/scripts/shared/inventory_rules.lua')
dofile('dayzepoch/scripts/survivors_s.lua')
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
test('admin batch of ten works with normal player cap five',function()
 configVar.maxzombies=5
 action(admin,'zombies',10)
 assert(active('ped')==13 and admin.data.spawnedzombies==13)
end)
test('twenty test zombie cap still blocks oversized total',function()
 action(admin,'zombies',10);assert(active('ped')==13 and admin.last.message:find('20-test-zombie',1,true))
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
test('vehicle spawning validates callers, catalogue and world',function()
 local n=active('vehicle');action(ordinary,'vehicle',1);action(admin,'vehicle',999);action(admin,'vehicle',1,ordinary)
 admin.dim=2;action(admin,'vehicle',1);admin.dim=0;assert(active('vehicle')==n)
end)
test('fully fitted helicopter uses native DayZ requirements and cleanup',function()
 action(admin,'vehicle',7)
 local list=getElementsByType('vehicle');local v=list[#list];local col=v.data.parent
 assert(v.model==487 and v.fixed and v.health==1000 and v.locked==false and v.data.adminTestVehicle)
 assert(col.data.vehicle and col.data.parent==v and col.data.fuel==80 and col.data.MAX_Slots==20)
 assert(col.data.Rotor_inVehicle==1 and col.data.Engine_inVehicle==1 and col.data.Tire_inVehicle==0)
 action(admin,'cleanup');assert(not isElement(v) and not isElement(col))
end)
test('vehicle cap and failed creation leave no orphan colshape',function()
 action(admin,'vehicle',1);action(admin,'vehicle',1);action(admin,'vehicle',1)
 local n=active('vehicle');action(admin,'vehicle',1);assert(active('vehicle')==n)
 action(admin,'cleanup');n=active('colshape');failVehicle=true;action(admin,'vehicle',1);failVehicle=false;assert(active('colshape')==n)
end)
test('survivors require authenticated admin and outdoor placement',function()
 local n=active('ped');action(ordinary,'survivor');admin.dim=5;action(admin,'survivor');admin.dim=0;assert(active('ped')==n)
end)
local survivor,zombie
local function tickSurvivors()
 for _,t in ipairs(timers) do if t.ms==500 and t.fn then t.fn();return end end
 error('Missing survivor timer')
end
local function sight(who,ped,target)
 client=who;source=who;handlers['dayz:survivorSight'][1](ped,target);client=nil;source=nil
end
test('survivor spawn initializes route weapon health and inspection',function()
 action(admin,'survivor')
 for _,p in ipairs(getElementsByType('ped')) do if p.data['survivor:active'] then survivor=p end end
 assert(survivor and survivor.syncer==admin and survivor.weapon==25 and survivor.data['survivor:ammo']==40)
 assert(type(survivor.data['survivor:waypoint'])=='table')
 action(admin,'survivorinspect');assert(admin.last.message:find('shells 40',1,true))
end)
test('server restricts target controller shot rate and ammunition',function()
 zombie=createZombie(survivor.x+5,survivor.y,survivor.z);zombie.data.blood=10000
 tickSurvivors();assert(survivor.data['survivor:state']=='combat')
 sight(ordinary,survivor,zombie);assert(zombie.data.blood==10000)
 sight(admin,survivor,ordinary);assert(zombie.data.blood==10000)
 sight(admin,survivor,zombie);assert(zombie.data.blood==7500 and survivor.data['survivor:ammo']==39)
 sight(admin,survivor,zombie);assert(zombie.data.blood==7500)
 for i=1,3 do now=now+1000;sight(admin,survivor,zombie) end
 assert(killedTarget==zombie and not isElement(zombie) and survivor.data['survivor:ammo']==36)
end)
test('close zombie attacks reduce health and cause retreat then death',function()
 zombie=createZombie(survivor.x+1,survivor.y,survivor.z);zombie.data.blood=100000
 tickSurvivors()
 for i=1,5 do now=now+1000;sight(admin,survivor,zombie) end
 tickSurvivors();assert(survivor.data['survivor:state']=='retreat' and survivor.data['survivor:health']>0 and survivor.data['survivor:health']<=30)
 for i=1,2 do now=now+1000;sight(admin,survivor,zombie) end
 assert(survivor.dead)
 action(admin,'cleanup');assert(not isElement(survivor))
 destroyElement(zombie)
end)
test('survivor limit and cleanup are bounded',function()
 action(admin,'survivor');action(admin,'survivor');action(admin,'survivor')
 local n=active('ped');action(admin,'survivor');assert(active('ped')==n)
 action(admin,'cleanup')
 for _,p in ipairs(getElementsByType('ped')) do assert(not p.data['survivor:active']) end
end)
local loot
local function lootRequest(who,ped,col)
 client=who;source=who;handlers['dayz:survivorLoot'][1](ped,col,true);client=nil;source=nil
end
test('survivor seeks real supplies and transfers only within reach',function()
 action(admin,'survivor')
 for _,p in ipairs(getElementsByType('ped')) do if p.data['survivor:active'] then survivor=p end end
 loot=createColSphere(survivor.x+5,survivor.y,survivor.z);loot.data.itemloot=true;loot.data.mag7=14
 tickSurvivors();assert(survivor.data['survivor:state']=='loot' and survivor.data['survivor:lootTarget']==loot)
 lootRequest(admin,survivor,loot);assert(loot.data.mag7==14)
 survivor.x=loot.x;survivor.y=loot.y;survivor.z=loot.z
 lootRequest(ordinary,survivor,loot);assert(loot.data.mag7==14)
 lootRequest(admin,survivor,loot);assert(loot.data.mag7==7 and survivor.data.parent.data.mag7==47 and survivor.data['survivor:ammo']==47)
 lootRequest(admin,survivor,loot);assert(loot.data.mag7==7)
 now=now+1600;lootRequest(admin,survivor,loot);assert(loot.data.mag7==0 and survivor.data.parent.data.mag7==54)
end)
test('crate edge interaction succeeds without entering solid crate centre',function()
 loot.radius=4;survivor.x=loot.x+3;loot.data.fooditem4=2
 now=now+1600;lootRequest(admin,survivor,loot)
 assert(loot.data.fooditem4==1 and survivor.data.parent.data.fooditem4==1)
end)
test('loot requests reject different worlds and private containers',function()
 loot.data.mag7=7;loot.dim=7;now=now+1600;lootRequest(admin,survivor,loot);assert(loot.data.mag7==7);loot.dim=0
 loot.data.safe=true;lootRequest(admin,survivor,loot);assert(loot.data.mag7==7);loot.data.safe=false
end)
test('inventory capacity prevents item creation or overfilling',function()
 survivor.data.parent.data.weapon12=3
 now=now+1600;lootRequest(admin,survivor,loot);assert(loot.data.mag7==7 and survivor.data.parent.data.mag7==54)
 survivor.data.parent.data.weapon12=0
end)
test('dead survivor exposes exactly its carried items and cleanup removes body',function()
 local col=survivor.data.parent;assert(not col.data.deadman and col.data.weapon7==1 and col.data.mag7==54)
 survivor.dead=true;tickSurvivors();assert(col.data.deadman and col.data.playername=='AI survivor' and col.data.mag7==54)
 action(admin,'cleanup');assert(not isElement(col) and not isElement(survivor));destroyElement(loot)
end)
test('needs testing action requires actual Admin and only edits owned survivors',function()
 action(admin,'survivor')
 for _,p in ipairs(getElementsByType('ped')) do if p.data['survivor:active'] then survivor=p end end
 action(ordinary,'survivorneeds');assert(survivor.data['survivor:food']==65)
 action(admin,'survivorneeds');assert(survivor.data['survivor:food']==35 and survivor.data['survivor:water']==30 and survivor.data['survivor:health']==55)
end)
test('bandages kits drinks and food consume real inventory after each action',function()
 local col=survivor.data.parent
 col.data.medicine5=1;col.data.medicine3=1;col.data.fooditem7=1;col.data.fooditem4=1
 local expected={{'bandaging','medicine5'},{'healing','medicine3'},{'drinking','fooditem7'},{'eating','fooditem4'}}
 for _,pair in ipairs(expected) do
  tickSurvivors();assert(survivor.data['survivor:state']==pair[1] and col.data[pair[2]]==1)
  now=now+3001;tickSurvivors();assert(col.data[pair[2]]==0)
 end
 assert(not survivor.data['survivor:bleeding'] and survivor.data['survivor:health']>=78)
 assert(survivor.data['survivor:food']>70 and survivor.data['survivor:water']>70)
 action(admin,'survivorinspect');assert(admin.last.message:find('Last used:',1,true))
end)
test('threat interruption preserves unused supplies and blocks consumption',function()
 local col=survivor.data.parent;col.data.medicine5=1
 action(admin,'survivorneeds');tickSurvivors();assert(survivor.data['survivor:state']=='bandaging')
 zombie=createZombie(survivor.x+5,survivor.y,survivor.z);zombie.data.blood=100000
 now=now+3100;tickSurvivors();assert(col.data.medicine5==1 and survivor.data['survivor:state']=='combat')
 destroyElement(zombie)
end)
test('missing supplies cannot restore needs and distant simulation pauses decay',function()
 local col=survivor.data.parent;col.data.medicine5=0
 action(admin,'survivorneeds');now=now+20000;tickSurvivors()
 assert(survivor.data['survivor:food']==33 and survivor.data['survivor:water']==27 and survivor.data['survivor:health']==51)
 local x=admin.x;admin.x=survivor.x+200;now=now+60000;tickSurvivors()
 assert(survivor.data['survivor:food']==33 and survivor.data['survivor:state']=='paused');admin.x=x
end)
test('starvation and bleeding can kill without consuming imaginary items',function()
 now=now+1200000;tickSurvivors()
 assert(survivor.dead and survivor.data.parent.data.deadman)
 action(admin,'cleanup')
end)
test('expanded patrol and navigation diagnostics restrict the controller',function()
 action(admin,'survivor')
 for _,p in ipairs(getElementsByType('ped')) do if p.data['survivor:active'] then survivor=p end end
 assert(survivor.data['survivor:waypoint'][1]==admin.x+40)
 local function nav(who,status)
  client=who;source=who;handlers['dayz:survivorNavigation'][1](survivor,status);client=nil;source=nil
 end
 nav(ordinary,'blocked');nav(admin,'arbitrary-route')
 action(admin,'survivorinspect');assert(not admin.last.message:find('Movement: blocked',1,true))
 nav(admin,'detouring');action(admin,'survivorinspect');assert(admin.last.message:find('Movement: detouring',1,true) and admin.last.message:find('/8',1,true))
 action(admin,'cleanup')
end)
print(passed..' admin testing behaviour checks passed')
