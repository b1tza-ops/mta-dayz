local handlers={};root={};resourceRoot={};localPlayer={}
function guiGetScreenSize() return 1280,720 end
function addEventHandler(n,_,f) handlers[n]=f end
local now=10000;local fail=false;local bindFail=false;local allocations=0;local draws=0;local target;local blend='blend'
function getTickCount() return now end
function isElement(e) return type(e)=='table' and not e.dead end
function destroyElement(e) e.dead=true end
function dxCreateRenderTarget() allocations=allocations+1;if fail then return false end;return {rt=true} end
function dxCreateTexture(path) assert(path=='images/world.jpg');if fail then return false end;return {} end
function outputDebugString() end
function getElementData(_,k) if k=='logedin' then return true elseif k=='toolbelt2' then return 1 end return false end
exports={e_map={isPlayerMapVisible=function() return false end}}
function dxGetMaterialSize(e) assert(isElement(e));return 180,130 end
function getCamera() return {} end
function getElementRotation() return 0,0,0 end
function getElementPosition() return 0,0,0 end
function dxSetRenderTarget(e) if e and bindFail then return false end;target=e;return true end
function dxSetBlendMode(m) blend=m end
function dxDrawRectangle() assert(target and blend=='modulate_add') end
function dxDrawImage(_,__,___,____,material)
 if type(material)=='table' then assert(isElement(material));draws=draws+1 end
end
function dxDrawText() end
function tocolor() return 0 end
function getElementsByType() return {} end
dofile('e_gps/gps.lua')
fail=true;handlers.onClientRender();assert(draws==0 and not target)
local count=allocations;handlers.onClientRender();assert(allocations==count)
now=now+5000;fail=false;handlers.onClientRender();assert(draws==2 and not target and blend=='blend')
handlers.onClientRestore();handlers.onClientRender();assert(draws==4)
bindFail=true;handlers.onClientRender();assert(not target and blend=='blend')
bindFail=false;handlers.onClientRender();assert(draws==6)
handlers.onClientResourceStop()
print('PASS GPS allocation failure, retry cooldown, recovery, restore redraw and failed target binding')
