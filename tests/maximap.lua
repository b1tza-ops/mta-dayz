local handlers={};root={};resourceRoot={};localPlayer={}
function guiGetScreenSize() return 1280,720 end
function getLocalPlayer() return localPlayer end
function getThisResource() return resourceRoot end
function getResourceRootElement() return resourceRoot end
function getRootElement() return root end
function addEventHandler(n,_,fn) handlers[n]=handlers[n] or {};table.insert(handlers[n],fn) end
function toggleControl() end
function tocolor() return 1 end
function bindKey() end
function addEvent() end
local tick,allocations,draws,fail=10000,0,0,false
local blend='add';local lastMaterial
function getTickCount() return tick end
function isElement(e) return type(e)=='table' and not e.dead end
function destroyElement(e) e.dead=true end
function dxCreateTexture(path,format,mipmap,edge)
 assert(format=='dxt1' and mipmap==false and edge=='clamp')
 allocations=allocations+1;if fail then return false end;return {path=path}
end
function outputDebugString() end
function dxSetBlendMode(mode) blend=mode end
function dxDrawImage(_,__,___,____,material)
 if type(material)=='table' then assert(isElement(material) and blend=='blend');draws=draws+1;lastMaterial=material end
end
function dxDrawRectangle() assert(blend=='blend') end
function dxDrawText() end
function getPedControlState() return false end
function getElementsByType() return {} end
function getElementPosition() return 0,0,0 end
function getPedRotation() return 0 end
function getElementData() return false end
function triggerEvent() return true end
function getResourceName() return 'e_map' end
dofile('e_map/maximap_c.lua')
setPlayerMapVisible(true)
fail=true;drawMap();assert(draws==0 and allocations==1)
drawMap();assert(allocations==1)
tick=tick+5000;fail=false;drawMap();assert(draws==1 and allocations==2)
drawMap();assert(draws==2 and allocations==2)
for _,fn in ipairs(handlers.onClientRestore) do fn() end
assert(lastMaterial.dead);drawMap();assert(draws==3 and allocations==3)
assert(setPlayerMapImage('custom.png',-3000,3000,3000,-3000));drawMap();assert(lastMaterial.path==':e_map/custom.png')
fail=true;assert(not setPlayerMapImage('missing.png',-3000,3000,3000,-3000));drawMap();assert(lastMaterial.path==':e_map/custom.png')
fail=false;setPlayerMapImage();drawMap();assert(lastMaterial.path==':e_map/images/world.png')
print('PASS maximap texture persistence, failed allocation cooldown, recovery, restore and replacement')
