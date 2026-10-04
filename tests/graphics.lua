root={};resourceRoot={};localPlayer={logedin=true}
local events,commands={},{}
local objects={};local w,h=1280,720;local draw,capture=0,0
local failShader,failSource,failCapture=false,false,false
local cursor,menu,vision=false,false,'normal'
local saved={};local logs=0
function addEventHandler(n,_,f) events[n]=f end
function addCommandHandler(n,f) commands[n]=f end
function isElement(e) return type(e)=='table' and not e.dead end
function destroyElement(e) e.dead=true end
function getElementData(p,k) return p[k] end
function isPedDead(p) return p.dead end
function isCursorShowing() return cursor end
function isMainMenuActive() return menu end
function isConsoleActive() return false end
function getCameraGoggleEffect() return vision end
function guiGetScreenSize() return w,h end
function dxCreateShader(path)
 if failShader then return false end
 local e={path=path};objects[#objects+1]=e;return e
end
function dxCreateScreenSource()
 if failSource then return false end
 local e={};objects[#objects+1]=e;return e
end
function dxSetShaderValue() return true end
function dxUpdateScreenSource(_,immediate) assert(immediate);capture=capture+1;return not failCapture end
function dxDrawImage() draw=draw+1;return true end
function getTime() return 12,0 end
function tocolor() return 0 end
function outputChatBox() end
function outputDebugString() logs=logs+1 end
function xmlCreateFile() return {} end
function xmlNodeSetAttribute(_,k,v) saved[k]=v end
function xmlSaveFile() return true end
function xmlUnloadFile() end
function xmlLoadFile() return false end
dofile('redfear_graphics/client.lua')
events.onClientResourceStart();events.onClientHUDRender();assert(draw==1 and capture==1 and #objects==2)
local original=objects[1]
for _,key in ipairs({'cursor','menu','vision'}) do
 if key=='cursor' then cursor=true elseif key=='menu' then menu=true else vision='nightvision' end
 events.onClientHUDRender();assert(draw==1)
 cursor=false;menu=false;vision='normal'
end
localPlayer.logedin=false;events.onClientHUDRender();assert(draw==1);localPlayer.logedin=true
commands.graphics('graphics','off');events.onClientHUDRender();assert(draw==1 and original.dead and saved.preset=='off')
commands.graphics('graphics','low');events.onClientHUDRender();assert(draw==2 and objects[#objects-1].path=='shaders/low.fx')
w,h=1920,1080;local old=objects[#objects];events.onClientHUDRender();assert(old.dead and draw==3)
events.onClientRestore();assert(objects[#objects].dead);events.onClientHUDRender();assert(draw==4)
failSource=true;commands.fixgraphics();events.onClientHUDRender();assert(draw==4 and objects[#objects].dead)
failSource=false;events.onClientHUDRender();assert(draw==4) -- fault does not retry each frame
commands.fixgraphics();events.onClientHUDRender();assert(draw==5)
failCapture=true;events.onClientHUDRender();assert(draw==5 and objects[#objects].dead)
failCapture=false;commands.graphics('graphics','cinematic');events.onClientHUDRender();assert(draw==6)
commands.graphics('graphics','invalid');events.onClientHUDRender();assert(draw==7 and saved.preset=='cinematic')
events.onClientResourceStop();for _,o in ipairs(objects) do assert(o.dead) end
failShader=true;commands.fixgraphics();events.onClientHUDRender();assert(draw==7)
for _,mode in ipairs({'low','balanced','cinematic'}) do
 local f=assert(io.open('redfear_graphics/shaders/'..mode..'.fx'));local src=f:read('*a');f:close()
 assert(src:find('compile ps_2_0 main',1,true) and src:find('return float4(saturate(color),1)',1,true))
 assert(not src:find('SATURATION',1,true) and not src:find('CONTRAST',1,true))
end
print('PASS presets, UI/night-vision/login bypass, immediate capture, resize/restore, allocation/capture failure, fault recovery, cleanup and shader templates')
