-- Client-only survivor guide. Does not grant items or change gameplay state.
local pages={
 {title='Start here',text='WELCOME TO REDFEAR ROMANIA DAYZ\n\nFind food, water and bandages first. Search buildings and loot containers, then look for a backpack and a weapon with matching ammunition.\n\nPress J to open your inventory. Approach loot and use E or the middle mouse button to interact. Right-click an inventory item for its available actions.\n\nKeep an eye on hunger, thirst, blood and bleeding. Carry supplies before travelling far. Other survivors may be friendly or dangerous.\n\nThis guide opens automatically once on this device. Use /help or /dayzhelp whenever you need it.'},
 {title='Controls',text='EVERYDAY CONTROLS\n\nJ  - Inventory and nearby loot\nE / middle mouse  - World interaction menu\nMouse wheel / Page Up / Page Down  - Select interaction\nT  - Local chat and /commands\nX  - Global chat\nU  - Radio chat (requires a radio)\nY  - Group chat\nM / F11  - Map (requires a map item)\nF1  - Group panel\nK  - Vehicle engine\n\nSome keys depend on your equipment or current situation. Inventory item actions are available with right-click.\n\nUseful commands: /airdrops and /crashsites show public event status. /fixchat restores chat if a menu restart leaves it hidden.'},
 {title='Survival',text='STAY ALIVE\n\nFood and drink\nCarry both. Use their inventory actions to eat or drink. Watch your status indicators during long journeys.\n\nBleeding and healing\nBandages stop bleeding. Medical items have different uses; read their descriptions and available actions. Avoid using valuable medicine when you do not need it.\n\nWeapons\nA weapon needs compatible ammunition. Read the item description before keeping or discarding magazines.\n\nStorage\nBackpacks increase capacity. The inventory footer shows your used slots. A nearly full capacity bar turns red.\n\nZombies\nKeep supplies ready before entering dangerous areas. Crash sites can have infected guards.'},
 {title='Vehicles',text='GET A VEHICLE RUNNING\n\nCheck the vehicle and its inventory before setting off. DayZ vehicles need fuel and their required parts; different models need different parts. Helicopters also require a rotor.\n\nUse the vehicle interaction menu to view available actions. A toolbox is required to install vehicle parts. Stop the engine before working on it.\n\nCarry repair supplies and fuel for the journey. Press K to toggle the engine once the vehicle is ready.\n\nA helicopter crash-site wreck is an event loot container, not a driveable vehicle.'},
 {title='Events & chat',text='EXPLORE TOGETHER\n\nLocal chat: T\nMessages reach survivors within 15 metres in the same interior and dimension. Slash commands work here too.\n\nGlobal chat: X\nUse it to talk across the server. Radio chat needs a radio and the same frequency. Group chat reaches your DayZ group.\n\nPublic airdrops\nA drop is scheduled every 30 minutes while survivors are online. A two-minute warning announces it. Follow the orange marker; loot expires 20 minutes after landing.\n\nHelicopter crash sites\nScheduled every 45 minutes while living survivors are online. Follow the red marker for military loot. Up to five zombies activate nearby; the site lasts 25 minutes.\n\nExisting missions run separately. Use /airdrops or /crashsites for public event status.'},
 {title='Fair play',text='PLAY FAIR\n\nDo not use cheats, exploit bugs or duplicate items. Report problems to an Admin instead of repeating them.\n\nKeep chat respectful. Do not spam messages or impersonate staff. Chat role labels do not grant permissions.\n\nAdmin tools and Superman flight are restricted to authorized accounts.\n\nAsk staff for the current server rules before assuming restrictions on PvP, raiding or safe zones. This guide does not define those policies.'}
}
local panel,memo,heading,closeButton
local ownedCursor=false
local seen=false
local preference='redfear-welcome.xml'
local saved=xmlLoadFile(preference)
if saved then seen=xmlNodeGetAttribute(saved,'seen')=='true';xmlUnloadFile(saved) end
local function remember()
 seen=true
 local file=xmlLoadFile(preference) or xmlCreateFile(preference,'welcome')
 if file then xmlNodeSetAttribute(file,'seen','true');xmlSaveFile(file);xmlUnloadFile(file)
 else outputDebugString('[RedFear guide] Could not save welcome preference.',2) end
end
local function close()
 if not isElement(panel) then return end
 guiSetVisible(panel,false)
 if ownedCursor then showCursor(false);ownedCursor=false end
 remember()
end
local function build()
 local sw,sh=guiGetScreenSize()
 local w,h=math.min(720,sw-30),math.min(540,sh-30)
 panel=guiCreateStaticImage((sw-w)/2,(sh-h)/2,w,h,'images/empty.png',false)
 local nav=math.min(165,math.floor(w*0.25))
 heading=guiCreateLabel(nav+28,64,w-nav-48,26,'',false,panel)
 guiSetFont(heading,'default-bold-small');guiLabelSetColor(heading,211,117,99)
 memo=guiCreateMemo(nav+25,98,w-nav-45,h-155,'',false,panel)
 guiMemoSetReadOnly(memo,true)
 for index,page in ipairs(pages) do
  local button=guiCreateButton(15,68+(index-1)*45,nav-10,35,page.title,false,panel)
  addEventHandler('onClientGUIClick',button,function()
   guiSetText(heading,string.upper(page.title));guiSetText(memo,page.text)
  end,false)
 end
 closeButton=guiCreateButton(w-150,h-43,130,28,'Ready to survive',false,panel)
 addEventHandler('onClientGUIClick',closeButton,close,false)
 guiSetText(heading,string.upper(pages[1].title));guiSetText(memo,pages[1].text)
 guiSetVisible(panel,false)
end
local function open()
 if not getElementData(localPlayer,'logedin') then return end
 if not isElement(panel) then build() end
 if guiGetVisible(panel) then return end
 ownedCursor=not isCursorShowing()
 guiSetVisible(panel,true);guiBringToFront(panel);showCursor(true)
end
addCommandHandler('help',open)
addCommandHandler('dayzhelp',open)
addEventHandler('onClientRender',root,function()
 if not isElement(panel) or not guiGetVisible(panel) then return end
 local x,y=guiGetPosition(panel,false);local w,h=guiGetSize(panel,false)
 dxSetBlendMode('blend')
 dxDrawRectangle(x,y,w,h,tocolor(23,28,27,248))
 dxDrawRectangle(x,y,w,3,tocolor(174,62,49,255))
 dxDrawRectangle(x,y+3,w,47,tocolor(16,20,18,255))
 dxDrawText('REDFEAR  /  SURVIVOR GUIDE',x+20,y+12,x+w-20,y+42,tocolor(220,225,208),1.15,'default-bold','left','center')
 dxDrawText('/help to reopen',x+20,y+h-42,x+w-170,y+h-12,tocolor(155,171,145),0.9,'default','left','center')
end)
local welcomeTimer
welcomeTimer=setTimer(function()
 if seen then if isTimer(welcomeTimer) then killTimer(welcomeTimer) end;return end
 if getElementData(localPlayer,'logedin') and not isCursorShowing() then
  open();if isTimer(welcomeTimer) then killTimer(welcomeTimer) end
 end
end,2000,0)
addEventHandler('onClientElementDataChange',localPlayer,function(key)
 if key=='logedin' and not getElementData(localPlayer,key) then
  if isElement(panel) and guiGetVisible(panel) then close() end
 end
end)
addEventHandler('onClientResourceStop',resourceRoot,function()
 if ownedCursor then showCursor(false) end
end)
outputDebugString('[RedFear guide] Welcome panel ready. Commands: /help, /dayzhelp.',3)
