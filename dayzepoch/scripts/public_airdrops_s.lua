-- Public events: one drop every 30 occupied minutes, no accumulation on an empty server.
local interval=30*60000
local warningTime=2*60000
local lifetime=20*60000
local locations={
 {name='Los Santos airport',x=1685,y=-2334,z=12.55},
 {name='San Fierro airport',x=-1420,y=-290,z=13.15},
 {name='Las Venturas airport',x=1435,y=1464,z=9.82},
 {name='Area 69',x=214,y=1900,z=16.64}
}
local drop,lastLocation,nextDrop,warned
local function announce(message)
 outputChatBox('#CC6655[AIRDROP] #FFFFFF'..message,root,255,255,255,true)
 outputDebugString('[DayZ airdrops] '..message,3)
end
local function survivorsOnline()
 for _,p in ipairs(getElementsByType('player')) do
  if getElementData(p,'logedin') and getElementDimension(p)==0 and getElementInterior(p)==0 then return true end
 end
 return false
end
local function cleanup()
 if not drop then return end
 for _,timer in ipairs(drop.timers) do if isTimer(timer) then killTimer(timer) end end
 for _,element in ipairs(drop.elements) do if isElement(element) then destroyElement(element) end end
 drop=nil
end
local function spawnDrop()
 if drop then return false,'A public airdrop is already active.' end
 local choices={}
 for i=1,#locations do if i~=lastLocation then choices[#choices+1]=i end end
 local index=choices[math.random(1,#choices)];local location=locations[index]
 local crate=createObject(2975,location.x,location.y,location.z+45)
 local chute=createObject(2903,location.x,location.y,location.z+46)
 local col=createColSphere(location.x,location.y,location.z+1,4)
 local blip=createBlip(location.x,location.y,location.z,0,3,255,140,40,255,0,65535)
 if not isElement(crate) or not isElement(chute) or not isElement(col) or not isElement(blip) then
  for _,e in pairs({crate,chute,col,blip}) do if isElement(e) then destroyElement(e) end end
  outputDebugString('[DayZ airdrops] Creation failed; rolled back all partial elements.',2)
  return false,'Could not create the airdrop.'
 end
 lastLocation=index
 attachElements(chute,crate,0,0,1.5);setElementFrozen(crate,true)
 setDayZData(col,'parent',crate);setDayZData(crate,'parent',col);setDayZData(col,'MAX_Slots',100)
 local loot,rare=DayZRollAirdropLoot()
 for item,quantity in pairs(loot) do setDayZData(col,item,quantity) end
 local record={elements={crate,chute,col,blip},timers={}}
 drop=record
 moveObject(crate,10000,location.x,location.y,location.z)
 record.timers[#record.timers+1]=setTimer(function()
  if drop~=record then return end
  if not isElement(crate) or not isElement(col) then cleanup();return end
  if isElement(chute) then destroyElement(chute) end
  setDayZData(col,'airdrop',true)
  for _,p in ipairs(getElementsWithinColShape(col,'player')) do
   triggerClientEvent(p,'dayz:testDropLanded',resourceRoot,col,crate)
  end
  announce('Supplies landed at '..location.name..'. Orange map marker; available for 20 minutes!')
  record.timers[#record.timers+1]=setTimer(function()
   if drop==record then cleanup();announce('The public airdrop has expired.') end
  end,lifetime,1)
 end,10000,1)
 announce('Supply drop incoming at '..location.name..'! Follow the orange marker. Landing in 10 seconds.')
 outputDebugString('[DayZ airdrops] Loot tier: '..(rare and 'rare military' or 'standard supplies'),3)
 return true
end
local function schedule() nextDrop=getTickCount()+interval;warned=false end
schedule()
setTimer(function()
 if not survivorsOnline() then schedule();return end
 local remaining=nextDrop-getTickCount()
 if remaining<=0 then
  if not drop then spawnDrop() end
  schedule()
 elseif remaining<=warningTime and not warned then
  warned=true;announce('A supply drop is expected in 2 minutes. Get ready!')
 end
end,15000,0)
local function isAdmin(p)
 if not isElement(p) or getElementType(p)~='player' then return false end
 local account=getPlayerAccount(p);local group=aclGetGroup('Admin')
 return account and not isGuestAccount(account) and group and isObjectInACLGroup('user.'..getAccountName(account),group)
end
addCommandHandler('airdropnow',function(player)
 -- Server console is trusted; players require their real Admin ACL account.
 if player and not isAdmin(player) then return end
 local ok,message=spawnDrop()
 if ok then schedule()
 elseif isElement(player) then outputChatBox(message,player,220,150,100)
 else outputDebugString('[DayZ airdrops] '..message,2) end
end)
addCommandHandler('airdrops',function(player)
 if not isElement(player) then return end
 local minutes=math.max(1,math.ceil((nextDrop-getTickCount())/60000))
 outputChatBox('[Airdrop] '..(drop and 'A public drop is active: check the orange marker.' or 'Next drop in about '..minutes..' minutes while survivors are online.'),player,255,190,110)
end)
addEventHandler('onResourceStop',resourceRoot,cleanup)
outputDebugString('[DayZ airdrops] Public drops enabled: 30-minute interval, 20-minute landed lifetime.',3)
