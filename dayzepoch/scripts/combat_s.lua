-- Client reports no damage amounts. Reports can only injure their own victim.
local reports={}
local function number(p,k,default) return tonumber(getElementData(p,k)) or default or 0 end
local function valid(p)
 return isElement(p) and getElementType(p)=='player' and getElementData(p,'logedin')
  and not isPedDead(p) and not getElementData(p,'isDead')
end
addEvent('dayz:combatHit',true)
addEventHandler('dayz:combatHit',root,function(attacker,weapon,part)
 local victim=client
 if source~=victim or not valid(victim) or not valid(attacker) or attacker==victim then return end
 if type(weapon)~='number' or weapon%1~=0 or type(part)~='number' or part%1~=0 or part<3 or part>9 then return end
 if getElementDimension(victim)~=getElementDimension(attacker) or getElementInterior(victim)~=getElementInterior(attacker) then return end
 if getElementData(victim,'dutyMode') then return end
 local vehicle=getPedOccupiedVehicle(victim)
 if vehicle and getElementModel(vehicle)==528 then return end
 local slot=getSlotFromWeapon(weapon)
 local key=(slot==3 or slot==5 or slot==6 or slot==7) and 'currentweapon_1'
  or (slot==1 or slot==2 or slot==4) and 'currentweapon_2' or 'currentweapon_3'
 local item=getElementData(attacker,key);local spec=DayZCombatWeapons[item]
 if not spec or item=='weapon16' then return end
 local _,native=getWeaponAmmoType(item)
 if native~=weapon or getPedWeapon(attacker,slot)~=weapon then return end
 local now=getTickCount()
 reports[victim]=reports[victim] or {}
 if reports[victim][attacker] and now-reports[victim][attacker]<50 then return end
 reports[victim][attacker]=now
 local ax,ay,az=getElementPosition(attacker);local vx,vy,vz=getElementPosition(victim)
 local distance=getDistanceBetweenPoints3D(ax,ay,az,vx,vy,vz)
 local equipment=part==9 and 'helmet' or part==3 and 'vest' or nil
 local armorItem=equipment and getElementData(victim,equipment)
 local armor=part==9 and DayZCombatHelmets[armorItem] or part==3 and DayZCombatVests[armorItem] or nil
 local condition=armor and number(victim,'armorCondition.'..armorItem,100) or 0
 local tuning=spec
 if key=='currentweapon_2' and (item=='weapon21' or item=='weapon23' or item=='weapon25' or item=='weapon20' or item=='weapon18') then
  tuning={base=spec.base,near=spec.near,far=spec.far,head=spec.head}
  local humanity=number(attacker,'humanity')
  if humanity==5000 then tuning.base=tuning.base*1.3 elseif humanity<=0 then tuning.base=tuning.base*0.7 end
 end
 local damage,headshot,wear=DayZCalculateHit(tuning,distance,part,armor,condition)
 if damage<=0 then return end
 if wear>0 then
  local remaining=math.max(0,condition-wear)
  setDayZData(victim,'armorCondition.'..armorItem,remaining)
  if remaining==0 then
   -- Broken equipped armor is consumed. A replacement begins a new condition cycle.
   setDayZData(victim,equipment,'')
   setDayZData(victim,'armorCondition.'..armorItem,100)
   triggerClientEvent(victim,'displayClientInfo',victim,'Your '..equipment..' broke!',220,100,80)
  end
 end
 local blood=number(victim,'blood',12000)
 local applied=headshot and math.max(1,blood) or math.min(math.max(0,blood),damage)
 setDayZData(victim,'blood',headshot and 0 or blood-damage)
 if math.random(1,8)>=6 then setDayZData(victim,'bleeding',number(victim,'bleeding')+math.max(1,math.floor(damage/100))) end
 if math.random(1,7)==2 then setDayZData(victim,'pain',true) end
 if part==7 or part==8 then setDayZData(victim,'brokenbone',true) end
 triggerClientEvent(victim,'dayz:combatFeedback',resourceRoot,'IN',applied,part,headshot)
 triggerClientEvent(attacker,'dayz:combatFeedback',resourceRoot,'OUT',applied,part,headshot)
 if number(victim,'blood')<=0 then
  triggerEvent('kilLDayZPlayer',victim,attacker,headshot,getWeaponNameFromID(weapon))
 end
end)
addEventHandler('onPlayerQuit',root,function()
 reports[source]=nil
 for _,players in pairs(reports) do players[source]=nil end
end)
outputDebugString('[RedFear combat] Server PvP range, armor wear and headshot ranges enabled.',3)
