local window,summary,list
local function close()
 if window then destroyElement(window); window=nil; showCursor(false) end
end
addCommandHandler("progress",function()
 if window then return close() end
 if not getElementData(localPlayer,"logedin") or isCursorShowing() then return end
 local sw,sh=guiGetScreenSize()
 window=guiCreateWindow((sw-560)/2,(sh-430)/2,560,430,"RedFear | Survivor progression",false)
 local xp=tonumber(getElementData(localPlayer,"stats.xp")) or 0
 local level=DayZLevelFromXP(xp)
 summary=guiCreateLabel(20,30,520,50,"Level "..level.." | XP "..xp..(level<20 and " / "..DayZXPThreshold(level+1) or " | Maximum level").."\nZombie XP: civilian 10, military 25, fast 40. Headshot +5.",false,window)
 list=guiCreateGridList(20,90,520,260,false,window)
 guiGridListAddColumn(list,"Reward",0.48); guiGridListAddColumn(list,"Unlock",0.4)
 local entries={}
 for _,category in ipairs({"title","outfit","emote"}) do
  for id,reward in pairs(DayZCosmetics[category]) do entries[#entries+1]={category=category,id=id,reward=reward} end
 end
 table.sort(entries,function(a,b) if a.reward.level==b.reward.level then return a.category..a.id<b.category..b.id end return a.reward.level<b.reward.level end)
 for _,entry in ipairs(entries) do
  local row=guiGridListAddRow(list)
  guiGridListSetItemText(list,row,1,entry.category..": "..entry.reward.name,false,false)
  guiGridListSetItemText(list,row,2,"Level "..entry.reward.level..(level>=entry.reward.level and " - unlocked" or " - locked"),false,false)
  guiGridListSetItemData(list,row,1,entry.category..":"..entry.id)
 end
 local use=guiCreateButton(20,365,160,40,"Use selected",false,window)
 local reset=guiCreateButton(190,365,170,40,"Reset outfit / title",false,window)
 local exit=guiCreateButton(370,365,170,40,"Close",false,window)
 addEventHandler("onClientGUIClick",use,function()
  local row=guiGridListGetSelectedItem(list)
  if row<0 then return end
  local value=guiGridListGetItemData(list,row,1)
  local category,id=value:match("^(%w+):(%w+)$")
  triggerServerEvent("dayz:selectCosmetic",resourceRoot,category,id)
  close()
 end,false)
 addEventHandler("onClientGUIClick",reset,function()
  triggerServerEvent("dayz:selectCosmetic",resourceRoot,"outfit","none")
  -- Separate requests avoid the server's per-player cosmetic rate limit.
  setTimer(function() triggerServerEvent("dayz:selectCosmetic",resourceRoot,"title","none") end,1100,1)
  close()
 end,false)
 addEventHandler("onClientGUIClick",exit,close,false)
 showCursor(true)
end)
addEvent("dayz:xpNotice",true)
addEventHandler("dayz:xpNotice",resourceRoot,function(gain,level,leveled)
 outputChatBox("+"..gain.." XP"..(leveled and " | Level "..level.." reached! Open /progress for rewards." or ""),100,210,160)
end)
addEventHandler("onClientPlayerWasted",localPlayer,close)
addEventHandler("onClientResourceStop",resourceRoot,close)
