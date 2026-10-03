-- Exercise the real panel with lightweight GUI stubs.
local handlers,controls,requests={}, {},{}
root={};resourceRoot={};localPlayer={}
items={Weapons={'weapon11'},Ammo={'mag5'},Food={'fooditem4'}}
exports={dayzepoch={getLanguageTextClient=function(_,id) return ({weapon11='M4A1 Holo',mag5='STANAG ammo',fooditem4='Baked beans'})[id] end}}
local function control(kind,text)
 local e={kind=kind,text=text or '',rows={},selected=-1,visible=false};controls[#controls+1]=e;return e
end
function guiGetScreenSize() return 1280,720 end
function guiCreateWindow(x,y,w,h,text) return control('window',text) end
function guiCreateLabel(x,y,w,h,text) return control('label',text) end
function guiCreateEdit(x,y,w,h,text) return control('edit',text) end
function guiCreateButton(x,y,w,h,text) return control('button',text) end
function guiCreateComboBox(x,y,w,h,text) return control('combo',text) end
function guiCreateGridList() return control('grid') end
function guiWindowSetSizable() end
function guiSetProperty() end
function guiSetVisible(e,v) e.visible=v end
function guiGetVisible(e) return e.visible end
function guiEditSetMaxLength() end
function guiComboBoxAddItem() end
function guiComboBoxSetSelected(e,v) e.selected=v end
function guiComboBoxGetSelected(e) return e.selected end
function guiGridListSetSortingEnabled() end
function guiGridListAddColumn() end
function guiGridListClear(e) e.rows={};e.selected=-1 end
function guiGridListAddRow(e) e.rows[#e.rows+1]={};return #e.rows-1 end
function guiGridListSetItemText(e,r,c,v) e.rows[r+1][c]=v end
function guiGridListSetItemData(e,r,c,v) e.rows[r+1].id=v end
function guiGridListGetItemData(e,r,c) return e.rows[r+1].id end
function guiGridListGetSelectedItem(e) return e.selected end
function guiGetText(e) return e.text end
function guiSetText(e,v) e.text=v end
function isElement(e) return type(e)=='table' end
function addEvent() end
function addCommandHandler() end
function addEventHandler(event,target,fn) handlers[event]=handlers[event] or {};handlers[event][target]=fn end
function triggerServerEvent(...) requests[#requests+1]={...} end
function setElementData() end
function showCursor() end
buttonItems={};gridlistPlayers1=control('grid');give=function() end
assert(loadfile('e_admin/gui/give_gui.lua'))()
giveGui();openGiveGui();assert(giveWindow.visible)
local search,selfButton
for _,e in ipairs(controls) do
 if e.kind=='edit' and e.text=='' then search=e end
 if e.text=='Give to myself' then selfButton=e end
end
assert(#giveWindowGridlist.rows==3)
search.text='m4a1';refreshGiveItems()
assert(#giveWindowGridlist.rows==1 and giveWindowGridlist.rows[1][1]=='M4A1 Holo' and giveWindowGridlist.rows[1].id=='weapon11')
giveWindowGridlist.selected=0;giveWindowEditboxQuant.text='2'
handlers.onClientGUIClick[selfButton]()
assert(#requests==1 and requests[1][1]=='giveEvent' and requests[1][3]==localPlayer and requests[1][4]=='weapon11' and requests[1][5]==2)
giveWindowEditboxQuant.text='0';handlers.onClientGUIClick[selfButton]();assert(#requests==1)
search.text='MAG5';refreshGiveItems();assert(#giveWindowGridlist.rows==1 and giveWindowGridlist.rows[1][1]=='STANAG ammo')
guiComboBoxSetSelected(giveWindowCombobox,2);search.text='';refreshGiveItems();assert(#giveWindowGridlist.rows==1 and giveWindowGridlist.rows[1].id=='fooditem4')
print('PASS item panel names, search, categories, item IDs, self-give and quantity validation')
-- Also exercise the real admin testing panel's controls.
function guiCreateMemo(x,y,w,h,text) return control('memo',text) end
function guiMemoSetReadOnly() end
function outputChatBox() end
local commands={}
function addCommandHandler(name,fn) commands[name]=fn end
dofile('dayzepoch/scripts/shared/admin_testing_locations.lua')
dofile('dayzepoch/scripts/admin_testing_c.lua')
commands.dayztest();assert(requests[#requests][1]=='dayz:testAction' and requests[#requests][3]=='open')
handlers['dayz:openTesting'][resourceRoot]()
local before=#requests
local expected={['Teleport']='teleport',['Return to previous position']='back',['Spawn zombies nearby']='zombies',['Trigger test airdrop']='airdrop',['Inspect nearest vehicle']='inspect',['Clean up my test zombies and airdrops']='cleanup'}
for _,e in ipairs(controls) do
 if expected[e.text] then
  handlers.onClientGUIClick[e]()
  assert(requests[#requests][1]=='dayz:testAction' and requests[#requests][3]==expected[e.text])
 end
end
assert(#requests==before+6)
print('PASS testing panel opens and sends all six actions through server requests')
