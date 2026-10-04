local visible=true
local notices={}
local names={[3]='TORSO',[4]='BODY',[5]='ARM',[6]='ARM',[7]='LEG',[8]='LEG',[9]='HEAD'}
addEvent('dayz:combatFeedback',true)
addEventHandler('dayz:combatFeedback',resourceRoot,function(direction,damage,part,headshot)
 if not visible or (direction~='IN' and direction~='OUT') or type(damage)~='number' then return end
 notices[#notices+1]={direction=direction,damage=damage,part=part,headshot=headshot,tick=getTickCount()}
 while #notices>5 do table.remove(notices,1) end
end)
addCommandHandler('damage',function()
 visible=not visible;notices={}
 outputChatBox('[RedFear] Damage indicators '..(visible and 'enabled.' or 'disabled.'),180,210,155)
end)
addEventHandler('onClientRender',root,function()
 local sw,sh=guiGetScreenSize();local now=getTickCount()
 for i=#notices,1,-1 do if now-notices[i].tick>2500 then table.remove(notices,i) end end
 for i,notice in ipairs(notices) do
  local alpha=math.min(255,math.max(0,(2500-(now-notice.tick))*0.3))
  local y=sh*0.6+(i-1)*25
  local label=notice.direction..'  '..math.floor(notice.damage)..'  '..(names[notice.part] or 'HIT')..(notice.headshot and '  LETHAL HEADSHOT' or '')
  dxDrawText(label,sw*0.55+1,y+1,sw-20,y+22,tocolor(0,0,0,alpha),1,'default-bold')
  dxDrawText(label,sw*0.55,y,sw-20,y+22,notice.direction=='IN' and tocolor(235,100,85,alpha) or tocolor(171,218,145,alpha),1,'default-bold')
 end
end)
