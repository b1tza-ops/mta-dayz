-- Focused regressions for failures observed in the MTA client log.
local function read(path)
 local f=assert(io.open(path));local s=f:read('*a');f:close();return s
end
local compile=loadstring or load
local function run(source) assert(compile(source))() end
local count=0
local function check(name,fn) fn();count=count+1;print('PASS '..name) end
check('MTA cache-first order loads shared tables before consumers',function()
 for _,resource in ipairs({'dayzepoch','e_shop'}) do
  local cached,uncached={},{}
  for attrs in read(resource..'/meta.xml'):gmatch('<script%s+([^>]+)>') do
   local kind=attrs:match('type="([^"]+)"')
   if kind=='shared' or kind=='client' then
    local list=attrs:find('cache="false"',1,true) and uncached or cached
    list[#list+1]=attrs:match('src="([^"]+)"')
   end
  end
  for _,p in ipairs(cached) do uncached[#uncached+1]=p end
  local ready=false
  for _,p in ipairs(uncached) do
   if p=='scripts/shared/inventory_items.lua' or p=='catalog.lua' then ready=true end
   if p=='inventory.lua' or p=='shop_c.lua' then assert(ready,'consumer loaded before shared data') end
  end
 end
end)
check('remote inventory actions are loaded by the resource manifest',function()
 local manifest=read('dayzepoch/meta.xml')
 assert(manifest:find('<script src="scripts/inventory_s.lua" type="server" />',1,true))
 local handlers=read('dayzepoch/scripts/inventory_s.lua')
 for _,event in ipairs({'dayz:transferItem','dayz:dropItem','dayz:vehiclePart','dayz:refuel','dayz:fillCanister'}) do
  assert(handlers:find('addEvent("'..event..'",true)',1,true))
 end
end)
check('shop currency handler ignores other players and missing values',function()
 local handler=assert(read('e_shop/shop_c.lua'):match('addEventHandler%("onClientElementDataChange",root,function%(data%)(.-)\nend%)'))
 localPlayer={};source=localPlayer
 local values={logedin=true}
 getElementData=function(_,k) return values[k] or false end
 isElement=function(e) return type(e)=='table' end
 local writes=0;guiSetText=function(_,s) writes=writes+1;assert(s==' zKills: 0') end
 local setup='local shop_gui={label={{}}};local currency_item="currency1";local data="currency1";'
 run(setup..handler);assert(writes==1)
 source={};run(setup..handler);assert(writes==1)
 source=localPlayer;run('local shop_gui={label={}};local currency_item=nil;local data="currency1";'..handler);assert(writes==1)
end)
check('console-created account gets stats before fresh spawn',function()
 local s=read('dayzepoch/accounts.lua')
 local init=assert(s:match('%-%- Console%-created accounts(.-)\n\tlocal x,y,z ='))
 init=init:sub(assert(init:find('\n'))+1)
 local data={};local persisted={};local assigned={}
 getTimestamp=function() return 1800000000 end
 getAccountData=function(_,k) return data[k] or false end
 setAccountData=function(_,k,v) persisted[k]=v end
 setDayZData=function(_,k,v) assigned[k]=v end
 local setup='local account={};local player={};local playerData2Table={{"stats.playtime",0},{"stats.email",""},{"stats.joined",0}};'
 run(setup..init);assert(assigned['stats.playtime']==0 and persisted['stats.playtime']==0)
 assert(assigned['stats.joined']==1800000000)
 data['stats.playtime']=42;data['stats.joined']=1700000000;run(setup..init);assert(assigned['stats.playtime']==42 and assigned['stats.joined']==1700000000)
 data['stats.joined']='1700000000';run(setup..init);assert(assigned['stats.joined']==1700000000)
end)
check('unknown damage is ignored before arithmetic',function()
 local s=read('dayzepoch/core_client.lua');local hits=0
 for guard in s:gmatch('local damage = getWeaponDamage%(attacker, weapon%);(.-)return end;') do
  assert(guard:find('type(damage)',1,true));hits=hits+1
  run('local damage=nil;'..guard..'return end; error("nil damage passed")')
 end
 assert(hits==2)
end)
print(count..' client regression checks passed')
