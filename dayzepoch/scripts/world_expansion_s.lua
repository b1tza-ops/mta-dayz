-- Loot is created inside DayZ so its inventory checks, respawn and deny policies apply.
local active={}
local function cleanup()
 for _,col in pairs(active) do
  if isElement(col) then
   local objects=getElementData(col,"objectsINloot")
   if type(objects)=="table" then for _,e in ipairs(objects) do if isElement(e) then destroyElement(e) end end end
   destroyElement(col)
  end
 end
 active={}
end
local function sync()
 local map=getResourceFromName("redfear_world")
 if not map or getResourceState(map)~="running" then cleanup();return end
 if lootrespawn then return end
 local ok,sites=pcall(function() return exports.redfear_world:getRedFearLootSites() end)
 if not ok or type(sites)~="table" then return end
 for i,site in ipairs(sites) do
  if isElement(active[i]) then
   local x,y,z=getElementPosition(active[i])
   local delta=site.z-z
   if math.abs(delta)>0.001 then
    setElementPosition(active[i],site.x,site.y,site.z)
    local objects=getElementData(active[i],"objectsINloot")
    if type(objects)=="table" then for _,e in ipairs(objects) do
     if isElement(e) then local ox,oy,oz=getElementPosition(e);setElementPosition(e,ox,oy,oz+delta) end
    end end
   end
  end
  if not isElement(active[i]) and itemTable[site.kind] then
   local col=createItemLoot(site.kind,site.x,site.y,site.z)
   if isElement(col) then
    active[i]=col
    if site.medical then
     -- Modest random medical supplements, using the real DayZ item catalogue.
     for _,key in ipairs({"medicine4","medicine6","medicine8"}) do
      if isDayZItem(key) then setDayZData(col,key,math.random(0,2)) end
     end
     refreshItemLoot(col,site.kind)
    end
   end
  end
 end
end
addEventHandler("onResourceStart",root,function(resource)
 if resource==getThisResource() or getResourceName(resource)=="redfear_world" then setTimer(sync,2000,1) end
end)
addEventHandler("onResourceStop",root,function(resource)
 if resource==getThisResource() or getResourceName(resource)=="redfear_world" then cleanup() end
end)
setTimer(sync,60000,0)

addEvent("redfear:groundChanged",false)
addEventHandler("redfear:groundChanged",root,function()
 local map=getResourceFromName("redfear_world")
 if map and source==getResourceRootElement(map) then sync() end
end)
