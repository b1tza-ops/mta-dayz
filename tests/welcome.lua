local controls,handlers,commands={}, {},{}
root={};resourceRoot={};localPlayer={logedin=false}
local cursor=false
local function control(text) local e={text=text,visible=true};controls[#controls+1]=e;return e end
function guiGetScreenSize() return 640,480 end
function guiCreateStaticImage(x,y,w,h) assert(x>=0 and y>=0 and w<=640 and h<=480);return control('panel') end
function guiCreateLabel(_,__,___,____,text) return control(text) end
function guiCreateMemo(_,__,___,____,text) return control(text) end
function guiCreateButton(_,__,___,____,text) return control(text) end
function guiSetFont() end
function guiLabelSetColor() end
function guiMemoSetReadOnly() end
function guiSetText(e,t) e.text=t end
function guiSetVisible(e,v) e.visible=v end
function guiGetVisible(e) return e.visible end
function guiBringToFront() end
function isElement(e) return type(e)=='table' end
function getElementData(e,k) return e[k] end
function isCursorShowing() return cursor end
function showCursor(v) cursor=v end
function addEventHandler(n,e,fn) handlers[n]=handlers[n] or {};handlers[n][e]=fn end
function addCommandHandler(n,fn) commands[n]=fn end
function xmlLoadFile() return false end
function xmlCreateFile() return {} end
function xmlNodeSetAttribute(_,k,v) savedValue=v end
function xmlSaveFile() end
function xmlUnloadFile() end
function outputDebugString() end
function setTimer(fn) timer={fn=fn};return timer end
function isTimer(t) return t and t.fn end
function killTimer(t) t.fn=nil end
dofile('dayzepoch/scripts/welcome_c.lua')
commands.help();assert(#controls==0)
localPlayer.logedin=true;cursor=true;timer.fn();assert(#controls==0)
cursor=false;timer.fn();assert(cursor and controls[1].visible)
assert(not timer.fn)
local close
for _,e in ipairs(controls) do if e.text=='Ready to survive' then close=e end end
handlers.onClientGUIClick[close]();assert(not cursor and not controls[1].visible and savedValue=='true')
cursor=true;commands.dayzhelp();handlers.onClientGUIClick[close]();assert(cursor)
print('PASS guide login guard, delayed welcome, small screen bounds, preference saving and cursor ownership')
