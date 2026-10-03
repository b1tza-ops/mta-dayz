-- Run from repository root using Lua 5.1+ or texlua tests/security.lua.
unpack = unpack or table.unpack
local handlers, elements, passed = {}, {}, 0
local now = 10000
local function E(kind,x,y,z)
    local e={kind=kind,alive=true,data={},policy={},x=x or 0,y=y or 0,z=z or 0,dim=0,int=0}
    elements[#elements+1]=e;return e
end
root=E("root");resourceRoot=E("resource")
function isElement(e) return type(e)=="table" and e.alive==true end
function getElementType(e) return e.kind end
function getElementData(e,k) if e and e.data[k]~=nil then return e.data[k] end;return false end
function setElementData(e,k,v,sync,policy) assert(isElement(e));e.data[k]=v;e.policy[k]=policy;return true end
function getElementPosition(e) return e.x,e.y,e.z end
function getElementRotation() return 0,0,0 end
function setElementPosition(e,x,y,z) e.x,e.y,e.z=x,y,z end
function getElementDimension(e) return e.dim end
function getElementInterior(e) return e.int end
function setElementDimension(e,v) e.dim=v end
function setElementInterior(e,v) e.int=v end
function getDistanceBetweenPoints3D(x,y,z,a,b,c) return ((x-a)^2+(y-b)^2+(z-c)^2)^0.5 end
function isElementWithinColShape(e,col) return isElement(col) and getDistanceBetweenPoints3D(e.x,e.y,e.z,col.x,col.y,col.z)<=(col.radius or 5) end
function getElementsByType(kind)
    local found={};for _,e in ipairs(elements) do if isElement(e) and e.kind==kind then found[#found+1]=e end end;return found
end
function getElementsWithinColShape(col,kind)
    local found={};for _,e in ipairs(getElementsByType(kind)) do if isElementWithinColShape(e,col) then found[#found+1]=e end end;return found
end
function isPedDead(e) return e.dead or false end
function getTickCount() return now end
function getPlayerName(e) return e.name or "tester" end
function outputDebugString() end
function outputChatBox() end
function triggerClientEvent(target,event,eventSource,...)
    target.messages=target.messages or {};target.messages[#target.messages+1]={event=event,args={...}}
end
function addEvent() end
function addEventHandler(name,attached,callback) handlers[name]=handlers[name] or {};table.insert(handlers[name],callback);return true end
function triggerEvent(name,s,...)
    local c,old=client,source;client=nil;source=s
    for _,fn in ipairs(handlers[name] or {}) do fn(...) end
    client,source=c,old
end
local function remote(name,who,s,...)
    now=now+6000;client=who;source=s or who
    for _,fn in ipairs(handlers[name] or {}) do fn(...) end
    client=nil;source=nil
end
function destroyElement(e) if isElement(e) then e.alive=false;return true end;return false end
function getVehicleEngineState(e) return e.engine or false end
function getPlayerAccount(e) return e.account or {guest=true,name="guest"} end
function isGuestAccount(a) return a.guest or false end
function getAccountName(a) return a.name end
function aclGetGroup(name) return {name=name} end
function isObjectInACLGroup(name) return name=="user.b1tza" end
function isElementFrozen(e) return e.frozen or false end
function setElementFrozen(e,v) e.frozen=v end
function fadeCamera() end
function setWeather(v) weather=v end
function setTimer(fn,ms,count,...) return {fn=fn,args={...}} end
function isTimer(t) return type(t)=="table" and t.fn~=nil end
function killTimer(t) t.fn=nil end
function fixVehicle(e) e.fixed=true end
function blowVehicle(e) e.blown=true end
function kickPlayer(e) e.kicked=true end
function banPlayer(e) e.banned=true end
function isPlayerMuted(e) return e.muted or false end
function setPlayerMuted(e,v) e.muted=v end
function getPlayerIP() return "test" end
function getPlayerSerial() return "test" end
function getPlayerVersion() return {} end
function getPlayerPing() return 50 end
function getMagazineSize(item) return ({mag1=15,mag2=7,mag3=30,mag4=30,mag5=20,mag6=100,mag7=7,mag8=5,mag9=1,mag10=5})[item] or 1 end
function getWeaponAmmoType(item) if item=="weapon11" then return "mag5",31 end;return false,false end
function refreshItemLoot() end
function getItemTablePosition(item) if isDayZItem(item) then return 1,"other" end;return false,false end
function createItemPickup(index,x,y,z,category,amount)
    local obj=E("object",x,y,z);local col=E("colshape",x,y,z);obj.data.parent=col;col.data.parent=obj;col.data.item2=amount;return obj
end
function createVehicle(id,x,y,z) if failVehicle then return false end;local v=E("vehicle",x,y,z);v.model=id;return v end
function createColSphere(x,y,z,radius) local col=E("colshape",x,y,z);col.radius=radius;return col end
function attachElements() end
function setVehicleDamageProof() end
function warpPedIntoVehicle() end
function getVehicleMaxFuel() return 80 end
function getElementModel(e) return e.model or 0 end
local function test(name,fn) fn();passed=passed+1;print("PASS "..name) end
local function P(x,y,z) local p=E("player",x,y,z);p.data.logedin=true;p.data.MAX_Slots=12;p.account={name="survivor"};return p end
local function L(x) local col=E("colshape",x);col.data.itemloot=true;col.data.MAX_Slots=12;return col end

dofile("dayzepoch/scripts/shared/inventory_items.lua")
dofile("dayzepoch/scripts/shared/inventory_rules.lua")
dofile("dayzepoch/scripts/security_s.lua")
dofile("dayzepoch/scripts/inventory_s.lua")
exports={dayzepoch={isDayZItem=function(self,...) return isDayZItem(...) end,canReceiveDayZItem=function(self,...) return canReceiveDayZItem(...) end}}
local a,b,col=P(),P(),L();col.data.fooditem4=2
test("transfer conserves inventory",function() assert(transferDayZItem(a,"take","fooditem4",col));assert(a.data.fooditem4==1 and col.data.fooditem4==1);assert(transferDayZItem(a,"put","fooditem4",col));assert(a.data.fooditem4==0 and col.data.fooditem4==2) end)
test("final item cannot be taken twice",function() col.data.fooditem4=1;assert(transferDayZItem(a,"take","fooditem4",col));assert(not transferDayZItem(b,"take","fooditem4",col));assert(col.data.fooditem4==0) end)
test("full backpack keeps loot intact",function() a.data.MAX_Slots=1;col.data.fooditem4=1;assert(not transferDayZItem(a,"take","fooditem4",col));assert(col.data.fooditem4==1);a.data.MAX_Slots=12 end)
test("fractional ammo slots enforce capacity",function() a.data.MAX_Slots=1;a.data.fooditem4=0;a.data.mag5=20;assert(not canReceiveDayZItem(a,"mag5",1));a.data.mag5=0;a.data.MAX_Slots=12 end)
test("distant loot rejected",function() assert(not transferDayZItem(a,"take","fooditem4",L(100))) end)
test("dimension and interior must match",function() col.dim=1;assert(not transferDayZItem(a,"take","fooditem4",col));col.dim=0;col.int=1;assert(not transferDayZItem(a,"take","fooditem4",col));col.int=0 end)
test("non-loot colshape rejected",function() assert(not transferDayZItem(a,"take","fooditem4",E("colshape"))) end)
test("safe requires recorded access",function() local s=E("colshape");s.data={safe=true,id="12345",["12345"]="1234",fooditem4=1,MAX_Slots=50};assert(not transferDayZItem(a,"take","fooditem4",s));setDayZData(a,"12345","1234");assert(transferDayZItem(a,"take","fooditem4",s));assert(a.policy["12345"]=="deny") end)
test("unknown item and action rejected",function() assert(not transferDayZItem(a,"take","admin",col));assert(not transferDayZItem(a,"invalid","fooditem4",col)) end)
test("spoofed inventory actor rejected",function() col.data.fooditem4=1;remote("dayz:transferItem",a,b,"take","fooditem4",col);assert(not b.data.fooditem4 and col.data.fooditem4==1) end)
test("ground pickup replay rejected",function() local g=E("colshape");g.data={item="fooditem4",parent=E("object"),item2=1};assert(takeGroundDayZItem(a,"fooditem4",g));assert(not takeGroundDayZItem(b,"fooditem4",g)) end)
test("ground pickup item must match",function() local g=E("colshape");g.data={item="fooditem4",parent=E("object"),item2=1};assert(not takeGroundDayZItem(a,"weapon11",g)) end)
test("drop amount comes from server",function() a.data.fooditem4=2;assert(dropDayZItem(a,"fooditem4"));assert(a.data.fooditem4==1);assert(not dropDayZItem(a,"admin")) end)
test("currency and inventory have deny policy",function() setDayZData(a,"zombieskilled",50);setDayZData(a,"fooditem4",1);assert(a.policy.zombieskilled=="deny" and a.policy.fooditem4=="deny") end)
test("vehicle parts require toolbox and stopped engine",function() local v=E("vehicle");local c=E("colshape");c.data={vehicle=true,parent=v,MAX_Slots=50,Engine_inVehicle=1,needengines=1};a.data.toolbelt4=0;assert(not transferDayZItem(a,"take","Engine_inVehicle",c));a.data.toolbelt4=1;v.engine=true;assert(not transferDayZItem(a,"take","Engine_inVehicle",c));v.engine=false;assert(transferDayZItem(a,"take","Engine_inVehicle",c));assert(a.data.vehiclepart1==1 and c.data.Engine_inVehicle==0);assert(transferDayZItem(a,"put","Engine_inVehicle",c));assert(a.data.vehiclepart1==0 and c.data.Engine_inVehicle==1) end)
test("refuel consumes canister and clamps fuel",function() local c=E("colshape");c.data={vehicle=true,parent=E("vehicle"),fuel=75,MAX_Slots=50};a.data.item9=1;a.data.item10=0;remote("dayz:refuel",a,a,c);assert(c.data.fuel==80 and a.data.item9==0 and a.data.item10==1) end)
test("firearm ammo decremented on server event",function() a.data.currentweapon_1="weapon11";a.data.mag5=10;triggerEvent("onPlayerWeaponFire",a,31);assert(a.data.mag5==9) end)
test("core spoofed actor rejected",function() source=b;client=a;assert(not dayZValidateAction("onPlayerEquipBackpack",{"backpack1",0}));client=nil;source=nil end)
test("unowned equipment rejected",function() source=a;client=a;assert(not dayZValidateAction("onPlayerEquipBackpack",{"backpack1",0}));client=nil;source=nil end)
test("currency cannot be used as food",function() source=a;client=a;assert(not dayZValidateAction("onPlayerRequestChangingStats",{"zombieskilled","ignored","food"}));client=nil;source=nil end)

dofile("e_admin/admin_s.lua");local admin=P();admin.account={name="b1tza"}
test("ACL admin accepted and forged flag rejected",function() a.data.admin=true;assert(not isDayZAdmin(a));assert(isDayZAdmin(admin)) end)
test("non-admin cannot grant or kill",function() remote("giveEvent",a,a,b,"fooditem4",10);remote("killPlayerEvent",a,a,b);assert(not b.data.fooditem4 and not b.data.blood) end)
test("admin source spoofing rejected",function() remote("killPlayerEvent",a,admin,b);assert(not b.data.blood) end)
test("admin can grant valid bounded item",function() remote("giveEvent",admin,admin,b,"fooditem4",3);assert(b.data.fooditem4==3 and b.policy.fooditem4=="deny") end)
test("negative and unknown admin grants rejected",function() remote("giveEvent",admin,admin,b,"fooditem4",-1);remote("giveEvent",admin,admin,b,"admin",1);assert(b.data.fooditem4==3 and not b.data.admin) end)
test("unauthorized player information request rejected",function() a.messages={};remote("getPlayerInfo",a,a,b);assert(#a.messages==0) end)
test("each vehicle admin action invokes correct function",function() local v=E("vehicle");remote("fixVehicleEvent",admin,admin,b,v);assert(v.fixed and not v.blown);remote("blowVehicleEvent",admin,admin,b,v);assert(v.blown);remote("destroyVehicleEvent",admin,admin,b,v);assert(not isElement(v)) end)
test("duty mode requires ACL",function() remote("dayz:adminDuty",a,a);assert(not a.data.dutyMode);remote("dayz:adminDuty",admin,admin);assert(admin.data.dutyMode and admin.policy.dutyMode=="deny") end)

dofile("e_shop/catalog.lua");dofile("e_shop/shop_s.lua")
local buyer=P(-2316.474,2342.978,5.816);buyer.data.zombieskilled=100
test("server catalogue determines quantity and price",function() remote("dayz:buyItem",buyer,buyer,"fooditem4",999,-500);assert(buyer.data.fooditem4==1 and buyer.data.zombieskilled==90) end)
test("unknown product cannot change admin flag",function() remote("dayz:buyItem",buyer,buyer,"admin");assert(not buyer.data.admin and buyer.data.zombieskilled==90) end)
test("spoofed shop actor rejected",function() remote("dayz:buyItem",a,buyer,"fooditem4");assert(buyer.data.fooditem4==1) end)
test("insufficient funds leave inventory untouched",function() buyer.data.zombieskilled=0;remote("dayz:buyItem",buyer,buyer,"fooditem4");assert(buyer.data.fooditem4==1 and buyer.data.zombieskilled==0) end)
test("full backpack does not pay",function() buyer.data.zombieskilled=100;buyer.data.MAX_Slots=1;remote("dayz:buyItem",buyer,buyer,"fooditem4");assert(buyer.data.zombieskilled==100 and buyer.data.fooditem4==1) end)
test("distant shop purchase rejected",function() buyer.x=0;remote("dayz:buyItem",buyer,buyer,"fooditem4");assert(buyer.data.zombieskilled==100) end)
test("failed vehicle creation does not charge",function() buyer.x,buyer.y,buyer.z=-2318.938,2342.724,5.816;failVehicle=true;remote("dayz:buyVehicle",buyer,buyer,509);assert(buyer.data.zombieskilled==100);failVehicle=false end)
test("vehicle has server spawn fuel capacity and price",function() remote("dayz:buyVehicle",buyer,buyer,422,1,0,0,0);assert(buyer.data.zombieskilled==20);local v=elements[#elements-1];local c=elements[#elements];assert(v.model==422 and v.x==-2323.510 and c.data.MAX_Slots==25 and c.data.fuel==80) end)
local account={name="newuser"};local loads=0
function getAccount(user,password) if user=="newuser" and password=="secret" then return account end;return false end
function addAccount() return account end
function logIn(player,a) if failLogin then return false end;player.account=a;return true end
function setAccountPassword() return true end
addEventHandler("onPlayerDayZLogin",root,function() loads=loads+1 end)
dofile("e_login/server.lua");local guest=P();guest.account={guest=true,name="guest"}
test("login cannot target another player",function() remote("submitLogin",guest,guest,b,"newuser","secret","en");assert(loads==0) end)
test("failed engine login cannot initialize character",function() failLogin=true;guest.messages={};remote("submitLogin",guest,guest,guest,"newuser","secret","en");assert(loads==0);for _,m in ipairs(guest.messages) do assert(m.event~="loginSuccess") end;failLogin=false end)
test("successful login initializes character once",function() remote("submitLogin",guest,guest,guest,"newuser","secret","en");assert(loads==1);remote("submitLogin",guest,guest,guest,"newuser","secret","en");assert(loads==1) end)
test("invalid login argument types rejected",function() local g=P();g.account={guest=true,name="guest"};remote("submitLogin",g,g,g,{},false,"bad");assert(loads==1) end)
local history={};local failSQL
function dbQuery(first,...)
    local callback,sql;if type(first)=="function" then callback=first;sql=select(2,...) else sql=select(1,...) end
    history[#history+1]=sql;local q={sql=sql};if callback then callback(q) end;return q
end
function dbPoll(q) if q.sql==failSQL then return false,1,"injected error" end;return {} end
dofile("dayzepoch/scripts/persistence_s.lua")
local db={};local rows={{sql="DELETE old",values={n=0}},{sql="INSERT new",values={n=1,1}}}
test("successful sync save commits",function() history={};assert(writeDayZSnapshotSync(db,rows));assert(history[1]=="BEGIN IMMEDIATE" and history[#history]=="COMMIT") end)
test("write failure rolls back without commit",function() history={};failSQL="INSERT new";assert(not writeDayZSnapshotSync(db,rows));assert(history[#history]=="ROLLBACK");failSQL=nil end)
test("commit failure rolls back",function() history={};failSQL="COMMIT";assert(not writeDayZSnapshotSync(db,rows));assert(history[#history]=="ROLLBACK");failSQL=nil end)
test("async failure reports after rollback",function() history={};failSQL="INSERT new";local result;writeDayZSnapshot(db,rows,function(ok) result=ok end);assert(result==false and history[#history]=="ROLLBACK");failSQL=nil end)
test("async success reports after commit",function() history={};local result;writeDayZSnapshot(db,rows,function(ok) result=ok end);assert(result==true and history[#history]=="COMMIT") end)
print("\n"..passed.." security behaviour tests passed")
