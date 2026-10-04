local lootSites={}
local previous={}
local lastTeleport={}
local objectCount=0
local failed=0
local function object(site,model,x,y,z,rz,rx,ry,scale)
 local e=createObject(model,site.x+x,site.y+y,site.groundZ+z,rx or 0,ry or 0,rz or 0)
 if not e then failed=failed+1; outputDebugString("[RedFear World] Failed object model "..model.." at "..site.id,1); return end
 setElementFrozen(e,true)
 setElementCollisionsEnabled(e,true)
 if scale then setObjectScale(e,scale) end
 objectCount=objectCount+1
 return e
end
local function loot(site,kind,x,y,medical)
 lootSites[#lootSites+1]={site=site.id,kind=kind,x=site.x+x,y=site.y+y,z=site.groundZ+1,medical=medical or false}
end
-- Native 3095 panels form open-front shelters. Open entrances face south (-Y).
local function shelter(site,x,y,medical)
 object(site,3095,x,y,0.02,0,0,0,0.8) -- 7.2m square floor
 object(site,3095,x,y,3.7,0,0,0,0.8) -- roof
 -- Two 3.6m panels per side, leaving the entire front open.
 for _,offset in ipairs({-1.8,1.8}) do
  object(site,3095,x+offset,y+3.6,1.85,0,90,0,0.4)
  object(site,3095,x-3.6,y+offset,1.85,90,90,0,0.4)
  object(site,3095,x+3.6,y+offset,1.85,90,90,0,0.4)
 end
 object(site,2302,x-1.5,y+1.2,0.45,90) -- bed
 object(site,2302,x+1.5,y+1.2,0.45,90)
 object(site,1432,x,y-0.7,0.55,0) -- communal table
 loot(site,"residential",x,y-2,medical)
end
local function perimeter(site)
 -- Fence origins are at one end of each native 12m panel.
 -- South edge deliberately leaves a 12m entrance; north leaves a secondary exit.
 for _,x in ipairs({-30,-18,6,18}) do object(site,987,x,-30,0,0) end
 for _,x in ipairs({-30,-18,6,18}) do object(site,987,x,30,0,0) end
 for y=-30,18,12 do
  object(site,987,-30,y,0,90)
  object(site,987,30,y,0,90)
 end
 object(site,978,-10,-31,0.65,0)
 object(site,979,10,-31,0.65,0)
end
local function supplies(site,x,y,kind)
 for i=0,2 do object(site,3798,x+i*2.2,y,1,0) end
 loot(site,kind,x+2,y-3)
end
local function build(site)
 perimeter(site)
 object(site,3279,-24,23,0,180)
 object(site,1215,-8,-28,0.7)
 object(site,1215,8,-28,0.7)
 if site.kind=="camp" then
  shelter(site,-16,12,false); shelter(site,0,12,false); shelter(site,16,12,false)
  shelter(site,-16,-8,false)
  supplies(site,12,-10,"supermarket")
  supplies(site,12,-20,"industrial")
  object(site,1432,0,-2,0.55)
  object(site,1463,0,1,0.5)
  loot(site,"farm",-3,-2)
 elseif site.kind=="military" then
  -- Accessible native Area 69 hangar, not a decorative closed building.
  object(site,3268,8,9,0,90)
  supplies(site,4,14,"military")
  supplies(site,12,14,"military")
  supplies(site,4,2,"industrial")
  shelter(site,-18,-5,false)
  loot(site,"military",-18,-7)
  for _,x in ipairs({-12,0,12}) do object(site,978,x,-19,0.65,0) end
  object(site,3593,18,-20,0.5,35)
 else
  for _,x in ipairs({-16,0,16}) do shelter(site,x,12,true) end
  shelter(site,-16,-8,true)
  supplies(site,12,-10,"industrial")
  supplies(site,12,-20,"supermarket")
  object(site,3593,0,-18,0.5,155)
  object(site,1432,0,-4,0.55)
  loot(site,"residential",0,-6,true)
 end
 local blip=createBlip(site.x,site.y,site.groundZ,0,2,site.color[1],site.color[2],site.color[3],220,0,300)
 if blip then setElementData(blip,"redfear:location",site.name) end
 local zone=createColSphere(site.x,site.y,site.groundZ,42)
 if zone then
  addEventHandler("onColShapeHit",zone,function(player,matching)
   if matching and getElementType(player)=="player" then
    outputChatBox("[RedFear] "..site.name.." | "..site.description,player,site.color[1],site.color[2],site.color[3])
   end
  end)
 end
end
function getRedFearLootSites() return lootSites end
local function admin(p)
 if not isElement(p) or getElementType(p)~="player" then return false end
 local a=getPlayerAccount(p); local group=aclGetGroup("Admin")
 return a and not isGuestAccount(a) and group and isObjectInACLGroup("user."..getAccountName(a),group)
end
addCommandHandler("rfmap",function(p,_,id)
 if not admin(p) then return end
 if isPedDead(p) or isPedInVehicle(p) then return outputChatBox("Leave your vehicle and stay alive before teleporting.",p,255,160,100) end
 if lastTeleport[p] and getTickCount()-lastTeleport[p]<2000 then return end
 local destination
 if id=="back" then destination=previous[p] else
  for _,site in ipairs(RedFearLocations) do
   if site.id==id then destination={site.x,site.y-36,site.groundZ+2,0,0}; break end
  end
 end
 if not destination then return outputChatBox("/rfmap camp | military | quarantine | back",p,200,200,200) end
 if id~="back" then
  local x,y,z=getElementPosition(p)
  previous[p]={x,y,z,getElementDimension(p),getElementInterior(p)}
 else previous[p]=nil end
 lastTeleport[p]=getTickCount()
 setElementDimension(p,destination[4]);setElementInterior(p,destination[5])
 setElementPosition(p,destination[1],destination[2],destination[3])
end)
addEventHandler("onPlayerQuit",root,function() previous[source]=nil;lastTeleport[source]=nil end)
addEventHandler("onResourceStart",resourceRoot,function()
 for _,site in ipairs(RedFearLocations) do build(site) end
 outputDebugString("[RedFear World] Loaded "..#RedFearLocations.." locations, "..objectCount.." objects, "..#lootSites.." loot points. Failed objects: "..failed,failed>0 and 1 or 3)
end)
