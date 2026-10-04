unpack=unpack or table.unpack
root={};resourceRoot={};local handlers={};local commands={};local objects={};local shapes={};local timers={};local now=10000
function isElement(e) return type(e)=='table' and not e.destroyed end
function getElementType(e) return e.kind end
function getElementData(e,k) return e.data and e.data[k] end
function setElementData(e,k,v) e.data=e.data or {};e.data[k]=v end
setDayZData=setElementData
function createObject(model,x,y,z,rx,ry,rz) local o={kind='object',model=model,x=x,y=y,z=z};objects[#objects+1]=o;return o end
function setElementFrozen(e,v) e.frozen=v end
function setElementCollisionsEnabled(e,v) e.collisions=v end
function setObjectScale(e,v) e.scale=v end
function createBlip() return {kind='blip'} end
function createColSphere(x,y,z,r) local c={kind='colshape',x=x,y=y,z=z,r=r,data={}};shapes[#shapes+1]=c;return c end
function addEventHandler(n,e,f) handlers[n]=handlers[n] or {};handlers[n][#handlers[n]+1]={element=e,fn=f} end
function addCommandHandler(n,f) commands[n]=f end
function outputChatBox() end
function outputDebugString() end
function getPlayerAccount(p) return p end
function isGuestAccount() return false end
function getAccountName(p) return p.name end
function aclGetGroup() return {} end
function isObjectInACLGroup(name) return name=='user.b1tza' end
function isPedDead(p) return p.dead end
function isPedInVehicle(p) return p.vehicle end
function getTickCount() return now end
function getElementPosition(e) return e.x,e.y,e.z end
function getElementDimension(e) return e.dim end
function getElementInterior(e) return e.int end
function setElementPosition(e,x,y,z) e.x=x;e.y=y;e.z=z end
function setElementDimension(e,v) e.dim=v end
function setElementInterior(e,v) e.int=v end
function setTimer(f,_,__,...) timers[#timers+1]={f=f,args={...}} end
function destroyElement(e) e.destroyed=true end
local map={name='redfear_world',state='running'};local dayz={name='dayzepoch',state='running'}
function getResourceFromName() return map end
function getResourceName(r) return r.name end
function getResourceState(r) return r.state end
function getThisResource() return dayz end
local function emit(n,res) for _,h in ipairs(handlers[n] or {}) do h.fn(res) end end
dofile('redfear_world/locations.lua');dofile('redfear_world/server.lua')
emit('onResourceStart',map)
assert(#objects>150 and #objects<350)
for _,o in ipairs(objects) do assert(o.frozen and o.collisions and o.model<18631) end
local sites=getRedFearLootSites(); assert(#sites==19)
local counts={};for _,s in ipairs(sites) do counts[s.site]=(counts[s.site] or 0)+1;assert(s.z>0 and math.abs(s.x)<3000 and math.abs(s.y)<3000) end
assert(counts.camp==7 and counts.military==5 and counts.quarantine==7)
local admin={kind='player',name='b1tza',x=10,y=20,z=30,dim=5,int=2}
local regular={kind='player',name='player',x=10,y=20,z=30,dim=5,int=2}
commands.rfmap(regular,'rfmap','camp');assert(regular.x==10)
commands.rfmap(admin,'rfmap','unknown');assert(admin.x==10)
commands.rfmap(admin,'rfmap','camp');assert(admin.x==415 and admin.dim==0 and admin.int==0)
now=now+3000;commands.rfmap(admin,'rfmap','back');assert(admin.x==10 and admin.dim==5 and admin.int==2)
now=now+3000;admin.vehicle=true;commands.rfmap(admin,'rfmap','military');assert(admin.x==10);admin.vehicle=false
itemTable={residential={},military={},supermarket={},industrial={},farm={}}
exports={redfear_world={getRedFearLootSites=function() return sites end}}
function isDayZItem() return true end
local created=0
function createItemLoot(kind,x,y,z)
 created=created+1;local c=createColSphere(x,y,z,1.25);c.data.objectsINloot={{kind='object'},{kind='object'}};return c
end
function refreshItemLoot() end
dofile('dayzepoch/scripts/world_expansion_s.lua')
local sync=timers[#timers].f
sync();assert(created==#sites)
sync();assert(created==#sites)
local first=shapes[4];assert(isElement(first));destroyElement(first);sync();assert(created==#sites+1)
map.state='stopped';sync()
for i=4,#shapes do assert(not isElement(shapes[i])) end
map.state='running';sync();assert(created==2*#sites+1)
lootrespawn=true;destroyElement(shapes[#shapes]);sync();assert(created==2*#sites+1)
lootrespawn=false;sync();assert(created==2*#sites+2)
emit('onResourceStop',map)
for i=4,#shapes do assert(not isElement(shapes[i])) end
print('PASS native collision objects, site loot, Admin teleport and return, vehicle rejection, loot deduplication, respawn recovery and stop cleanup')
