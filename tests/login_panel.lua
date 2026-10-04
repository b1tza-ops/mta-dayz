local handlers,controls,requests={}, {},{}
root={};resourceRoot={};localPlayer={}
local function control(kind,x,y,w,h,text,parent)
 local e={kind=kind,x=x,y=y,w=w,h=h,text=text or '',parent=parent,visible=true};controls[#controls+1]=e;return e
end
function guiGetScreenSize() return 800,600 end
function guiCreateStaticImage(x,y,w,h,t,_,p) return control('image',x,y,w,h,t,p) end
function guiCreateLabel(x,y,w,h,t,_,p) return control('label',x,y,w,h,t,p) end
function guiCreateEdit(x,y,w,h,t,_,p) return control('edit',x,y,w,h,t,p) end
function guiCreateButton(x,y,w,h,t,_,p) return control('button',x,y,w,h,t,p) end
function guiCreateComboBox(x,y,w,h,t) return control('combo',x,y,w,h,t) end
function guiComboBoxAddItem() end
function guiComboBoxSetSelected(e,i) e.selected=i end
function guiComboBoxGetSelected(e) return e.selected end
function guiSetVisible(e,v) e.visible=v end
function guiSetFont() end
function guiLabelSetColor() end
function guiSetProperty() end
function guiEditSetMaxLength(e,v) e.max=v end
function guiEditSetMasked(e,v) e.mask=v end
function guiGetText(e) return e.text end
function guiSetText(e,t) e.text=t end
function addEvent() end
function addEventHandler(n,_,f) handlers[n]=handlers[n] or {};table.insert(handlers[n],f) end
local function event(n) for _,f in ipairs(handlers[n]) do f() end end
local now=10000
function getTickCount() return now end
function triggerServerEvent(...) requests[#requests+1]={...} end
function getElementData() return 'en' end
function getElementData(_,key) if key=='language' then return 'en' end return false end
function setCameraMatrix() end
function createPed() return {ped=true} end
function isElement(e) return e and e.ped and not e.destroyed end
function destroyElement(e) e.destroyed=true end
function setPedAnimation() end
function setPlayerHudComponentVisible() end
function fadeCamera() end
function showChat() end
function showCursor() end
function outputDebugString() end
function tocolor(...) return {...} end
function dxDrawRectangle() end
function dxDrawText() end
dofile('e_login/login_c.lua')
event('onClientResourceStart');assert(login.window[1].visible)
for _,e in ipairs(controls) do
 if not e.parent then assert(e.x>=0 and e.y>=0 and e.x+e.w<=800 and e.y+e.h<=600) end
end
assert(login.edit[2].mask and login.edit[2].max==128)
clientSubmitLogin();assert(#requests==0)
login.edit[1].text='b1tza';login.edit[2].text='password';clientSubmitLogin()
assert(requests[1][1]=='submitLogin' and requests[1][2]==localPlayer and requests[1][3]==localPlayer and requests[1][6]=='en')
clientSubmitLogin();assert(#requests==1)
seterror('Login failed');source=login.button[2];event('onClientGUIClick');assert(not login.window[1].visible)
local registerEdits={}
for _,e in ipairs(controls) do if e.kind=='edit' and e.parent~=login.window[1] then registerEdits[#registerEdits+1]=e end end
assert(#registerEdits==4 and registerEdits[3].mask and registerEdits[4].mask)
registerEdits[1].text='survivor';registerEdits[2].text='test@example.com';registerEdits[3].text='secret';registerEdits[4].text='wrong'
clientSubmitRegister();assert(#requests==1)
registerEdits[4].text='secret';clientSubmitRegister();assert(#requests==2 and requests[2][1]=='submitRegister' and requests[2][7]=='en')
event('onClientRender');loginSuccess();assert(not login.window[1].visible and login.edit[2].text=='' and registerEdits[3].text=='')
clientSubmitLogin();assert(#requests==2)
print('PASS login/register layout, masked passwords, validation, event arguments, throttling and successful cleanup')
