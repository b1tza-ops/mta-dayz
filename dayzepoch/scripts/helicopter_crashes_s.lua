-- One public crash at a time. Guards activate when survivors approach.
local interval,lifetime=45*60000,25*60000
local locations={
 {name='Flint County',x=-1360.05,y=-1070.73,z=160.41},
 {name='Flint County farmland',x=-421.46,y=-1284.43,z=33.74},
 {name='Mount Chiliad',x=-2357.65,y=-1634.36,z=483.70},
 {name='Red County',x=979.08,y=160.59,z=28.94},
 {name='Tierra Robada',x=-2057.23,y=2781.74,z=163.13},
 {name='Bone County',x=826.90,y=2803.63,z=74.86},
 {name='Palomino Creek hills',x=2577.71,y=-650.54,z=136.37}
}
local site,lastLocation,nextCrash
local function announce(message)
 outputChatBox('#CC6655[CRASH SITE] #FFFFFF'..message,root,255,255,255,true)
 outputDebugString('[DayZ crash] '..message,3)
end
local function survivors()
 local list={}
 for _,p in ipairs(getElementsByType('player')) do
  if getElementData(p,'logedin') and getElementDimension(p)==0 and getElementInterior(p)==0 and not isPedDead(p) then list[#list+1]=p end
 end
 return list
end
local function cleanup()
 if not site then return end
 if isTimer(site.timer) then killTimer(site.timer) end
 for _,z in ipairs(site.guards) do if isElement(z) then Zomb_delete(z) end end
 for _,e in ipairs(site.elements) do if isElement(e) then destroyElement(e) end end
 site=nil
end
local function spawnCrash()
 if site then return false,'A crash site is already active.' end
 local choices={}
 for i=1,#locations do if i~=lastLocation then choices[#choices+1]=i end end
 local index=choices[math.random(#choices)];local loc=locations[index]
 local wreck=createVehicle(548,loc.x,loc.y,loc.z)
 local col=createColSphere(loc.x,loc.y,loc.z,6)
 local blip=createBlip(loc.x,loc.y,loc.z,0,3,200,50,50,255,0,65535)
 if not isElement(wreck) or not isElement(col) or not isElement(blip) then
  for _,e in pairs({wreck,col,blip}) do if isElement(e) then destroyElement(e) end end
  outputDebugString('[DayZ crash] Creation failed; partial elements removed.',2)
  return false,'Crash creation failed.'
 end
 lastLocation=index
 setDayZData(wreck,'helicrash',true) -- Exclude wreck from normal vehicle respawn.
 setElementHealth(wreck,0);setElementFrozen(wreck,true);setVehicleLocked(wreck,true)
 setDayZData(col,'parent',wreck);setDayZData(wreck,'parent',col)
 setDayZData(col,'helicrash',true);setDayZData(col,'MAX_Slots',0)
 local loot=DayZRollAirdropLoot()
 -- Crash sites always add one military weapon with matching ammo and premium gear.
 local weapons={{'weapon11','mag5',120},{'weapon12','mag6',150},{'weapon2','mag10',30},{'weapon5','mag8',30}}
 local weapon=weapons[math.random(#weapons)]
 loot[weapon[1]]=(loot[weapon[1]] or 0)+1;loot[weapon[2]]=(loot[weapon[2]] or 0)+weapon[3]
 local gear={'backpack1','vest2','toolbelt7','toolbelt6'}
 local item=gear[math.random(#gear)];loot[item]=(loot[item] or 0)+1
 for item,amount in pairs(loot) do setDayZData(col,item,amount) end
 local record={elements={wreck,col,blip},guards={},location=loc}
 site=record
 record.timer=setTimer(function() if site==record then cleanup();announce('The crash site has expired.') end end,lifetime,1)
 announce('Helicopter wreck reported in '..loc.name..'. Follow the red marker. Rare supplies; expires in 25 minutes!')
 return true
end
local function activateGuards(players)
 if not site or #site.guards>=5 then return end
 local loc=site.location;local nearby=false
 for _,p in ipairs(players) do
  local x,y,z=getElementPosition(p)
  if getDistanceBetweenPoints3D(x,y,z,loc.x,loc.y,loc.z)<70 then nearby=true;break end
 end
 if not nearby then return end
 -- Keep guards close to the recorded terrain height. Native zombie cap still applies.
 for i=#site.guards+1,5 do
  local angle=i*math.pi*2/5
  local zombie=createZombie(loc.x+math.cos(angle)*5,loc.y+math.sin(angle)*5,loc.z+0.5,0,22)
  if not isElement(zombie) then break end
  setDayZData(zombie,'blood',10000)
  site.guards[#site.guards+1]=zombie
 end
end
local function schedule() nextCrash=getTickCount()+interval end
schedule()
setTimer(function()
 local players=survivors()
 if #players==0 then schedule();return end
 activateGuards(players)
 if getTickCount()>=nextCrash then
  if not site then spawnCrash() end
  schedule()
 end
end,15000,0)
local function admin(p)
 if not isElement(p) or getElementType(p)~='player' then return false end
 local account=getPlayerAccount(p);local group=aclGetGroup('Admin')
 return account and not isGuestAccount(account) and group and isObjectInACLGroup('user.'..getAccountName(account),group)
end
addCommandHandler('crashnow',function(player)
 if player and not admin(player) then return end
 local ok,message=spawnCrash()
 if ok then schedule();activateGuards(survivors())
 elseif isElement(player) then outputChatBox(message,player,220,150,100)
 else outputDebugString('[DayZ crash] '..message,2) end
end)
addCommandHandler('crashsites',function(player)
 if not isElement(player) then return end
 local message=site and ('Active crash: '..site.location.name..'. Follow the red marker.') or ('Next crash in about '..math.max(1,math.ceil((nextCrash-getTickCount())/60000))..' minutes while survivors are online.')
 outputChatBox('[Crash site] '..message,player,230,140,120)
end)
addEventHandler('onResourceStop',resourceRoot,cleanup)
outputDebugString('[DayZ crash] Enabled: 45-minute interval, 25-minute lifetime, up to 5 guards.',3)
