-- Account-backed cosmetic progression; no client event can grant XP.
local function ready(p)
 return isElement(p) and getElementType(p)=="player" and getElementData(p,"logedin") and not isPedDead(p)
end
local function persist(p,key,value)
 setDayZData(p,key,value)
 local account=getPlayerAccount(p)
 if account and not isGuestAccount(account) then setAccountData(account,key,value) end
end
function DayZAwardZombieXP(p,zombie,headshot)
 if not ready(p) or getElementData(zombie,"zombie:noXP") or getElementData(zombie,"zombie:rewarded") then return false end
 setDayZData(zombie,"zombie:rewarded",true)
 local kind=DayZZombieTypes[getElementData(zombie,"zombie:type")] or DayZZombieTypes.civilian
 local gain=kind.xp+(headshot==true and 5 or 0)
 local xp=math.max(0,tonumber(getElementData(p,"stats.xp")) or 0)+gain
 local old=DayZLevelFromXP(xp-gain)
 local level=DayZLevelFromXP(xp)
 persist(p,"stats.xp",xp); persist(p,"stats.level",level)
 triggerClientEvent(p,"dayz:xpNotice",resourceRoot,gain,level,level>old)
 return true
end
local function applyOutfit(p)
 if not ready(p) then return end
 local selected=DayZCosmetics.outfit[getElementData(p,"stats.cosmeticSkin")]
 local level=DayZLevelFromXP(tonumber(getElementData(p,"stats.xp")) or 0)
 if selected and level>=selected.level then setElementModel(p,selected.skin) end
end
local function delayedOutfit(p) setTimer(applyOutfit,1000,1,p) end
addEventHandler("onPlayerDayZLogin",root,delayedOutfit)
addEventHandler("onPlayerSpawn",root,function() delayedOutfit(source) end)
addEventHandler("onElementDataChange",root,function(key)
 if key=="skin" and getElementType(source)=="player" then delayedOutfit(source) end
end)
local function selectCosmetic(p,category,id)
 if not ready(p) or not dayZRequest(p,"cosmetic",1000) then return end
 local list=DayZCosmetics[category]
 if not list or type(id)~="string" then return end
 local level=DayZLevelFromXP(tonumber(getElementData(p,"stats.xp")) or 0)
 local reward=list[id]
 if id~="none" and (not reward or level<reward.level) then return outputChatBox("That cosmetic is locked.",p,255,100,100) end
 if category=="outfit" then
  persist(p,"stats.cosmeticSkin",id)
  if id=="none" then setElementModel(p,tonumber(getElementData(p,"skin")) or 73) else applyOutfit(p) end
 elseif category=="title" then persist(p,"stats.title",id)
 elseif category=="emote" and reward then
  if isPedInVehicle(p) or getElementData(p,"superman:flying") or getElementData(p,"inAction") then return end
  if not dayZRequest(p,"emote",5000) then return end
  setPedAnimation(p,reward.block,reward.anim,2000,false,false,true,false)
 end
end
addEvent("dayz:selectCosmetic",true)
addEventHandler("dayz:selectCosmetic",resourceRoot,function(category,id)
 if source~=resourceRoot or not client then return end
 selectCosmetic(client,category,id)
end)
for _,category in ipairs({"outfit","title","emote"}) do
 local name=category
 addCommandHandler(name,function(p,_,id) selectCosmetic(p,name,id or "none") end)
end
