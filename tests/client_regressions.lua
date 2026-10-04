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
check('destroyed loot is rejected before any inventory data reads',function()
 local s=read('dayzepoch/inventory.lua')
 isElement=function(e) return type(e)=='table' and e.alive==true end
 local reads=0
 getElementData=function(e,k) assert(isElement(e),'invalid inventory element read');reads=reads+1;return e.data[k] end
 for _,name in ipairs({'refreshLoot','getElementMaxSlots','getElementCurrentSlots','isPlayerInLoot'}) do
  local fn=assert(s:match('(function '..name..'%([^\n]*.-\nend)'))
  run(fn)
 end
 local dead={alive=false};localPlayer={alive=true,data={loot=true,currentCol=dead}}
 assert(refreshLoot(dead)==false and getElementMaxSlots(dead)==0 and getElementCurrentSlots(dead)==0)
 assert(refreshLoot(false)==false and getElementMaxSlots(nil)==0 and getElementCurrentSlots(false)==0 and reads==0)
 assert(isPlayerInLoot()==false)
 local live={alive=true,data={MAX_Slots=20}};localPlayer.data.currentCol=live
 assert(isPlayerInLoot()==live and getElementMaxSlots(live)==20)
end)
check('world menu rejects absent destroyed and offscreen targets before drawing',function()
 local body=assert(read('dayzepoch/menu_client.lua'):match('addEventHandler%("onClientRender", root, function%(%)\n(.-)\nend%);'))
 local reads,draws,clears=0,0,0
 isElement=function(e) return type(e)=='table' and e.alive end
 getElementPosition=function(e) assert(isElement(e));reads=reads+1;return 1,2,3 end
 getScreenFromWorldPosition=function() return false,false end
 dxGetFontHeight=function() return 10 end
 getPedOccupiedVehicle=function() return false end
 disableMenu=function() clears=clears+1 end
 renderMenu=function() draws=draws+1 end
 dxGetTextWidth=function() error('offscreen target reached drawing') end
 for _,setup in ipairs({'local newbiePosition=false;local newbieShow=true;', 'local newbiePosition={alive=false};local newbieShow=false;'}) do run(setup..body) end
 assert(reads==0 and clears==2 and draws==0)
 run('local newbiePosition={alive=true};local newbieShow=false;'..body)
 run('local newbiePosition={alive=true};local newbieShow=true;'..body)
 assert(reads==2 and draws==0)
 getScreenFromWorldPosition=function() return 100,100,1 end
 run('local newbiePosition={alive=true};local newbieShow=false;'..body)
 assert(draws==1)
end)
check('scoreboard missing country flags fall back without image warnings',function()
 local source=read('e_scoreboard/dxscoreboard_client.lua')
 local body=assert(source:match('elseif column.name == "country" then(.-)\n\t\t\t\t\t\t\telse'))
 local images,labels=0,{}
 fileExists=function(p) return p==':admin/client/images/flags/RO.png' end
 dxDrawImage=function(_,__,___,____,p) assert(fileExists(p));images=images+1 end
 dxDrawText=function(t) labels[#labels+1]=t end
 dxGetFontHeight=function() return 10 end
 fontscale=function() return 1 end
 s=function(v) return v end
 local setup='local topX,theX,x,y=0,0,0,0;local column={width=15};'
 run(setup..'local content=":admin/client/images/flags/GB.png";'..body)
 run(setup..'local content=false;'..body)
 run(setup..'local content=":admin/client/images/flags/false.png";'..body)
 run(setup..'local content=":admin/client/images/flags/RO.png";'..body)
 assert(images==1 and labels[1]=='GB' and labels[2]=='--' and labels[3]=='--')
end)
print(count..' client regression checks passed')
