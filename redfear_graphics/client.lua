-- Local-only postprocessing before the HUD; never changes server weather or gameplay.
local presets={low=true,balanced=true,cinematic=true,off=true}
local mode="balanced"
local shader,screen,width,height
local fault=false
local function release()
 if isElement(shader) then destroyElement(shader) end
 if isElement(screen) then destroyElement(screen) end
 shader,screen,width,height=nil,nil,nil,nil
end
local function save()
 local config=xmlCreateFile("@graphics.xml","graphics")
 if config then
  xmlNodeSetAttribute(config,"preset",mode)
  if not xmlSaveFile(config) then outputDebugString("[RedFear Graphics] Could not save preference.",2) end
  xmlUnloadFile(config)
 end
end
local function fail(reason)
 release();fault=true
 outputDebugString("[RedFear Graphics] Disabled effect: "..reason,2)
 outputChatBox("[RedFear] Graphics effect unavailable; normal graphics restored. Try /graphics low or /fixgraphics.",255,180,100)
end
local function create(w,h)
 release()
 shader=dxCreateShader("shaders/"..mode..".fx")
 if not shader then fail("shader compilation/allocation failed ("..mode..")");return false end
 screen=dxCreateScreenSource(w,h)
 if not screen then fail("screen source allocation failed");return false end
 if not dxSetShaderValue(shader,"ScreenTexture",screen) or not dxSetShaderValue(shader,"PixelSize",1/w,1/h) then
  fail("shader texture binding failed");return false
 end
 width,height=w,h
 outputDebugString("[RedFear Graphics] "..mode.." at "..w.."x"..h,3)
 return true
end
local function ready()
 return getElementData(localPlayer,"logedin") and not isPedDead(localPlayer)
  and not isCursorShowing() and not isMainMenuActive() and not isConsoleActive()
  and getCameraGoggleEffect()=="normal"
end
local function render()
 if mode=="off" or fault or not ready() then return end
 local w,h=guiGetScreenSize()
 if not isElement(shader) or not isElement(screen) or w~=width or h~=height then
  if not create(w,h) then return end
 end
 -- Capture this frame before drawing, so the effect cannot recursively capture itself.
 if not dxUpdateScreenSource(screen,true) then fail("screen capture failed");return end
 local hour,minute=getTime()
 local time=hour+minute/60
 local daylight=math.max(0,math.min(1,(time-5)/2,(21-time)/2))
 if not dxSetShaderValue(shader,"Daylight",daylight) then fail("daylight binding failed");return end
 if not dxDrawImage(0,0,w,h,shader,0,0,0,tocolor(255,255,255,255),false) then fail("effect draw failed") end
end
addEventHandler("onClientHUDRender",root,render,false,"high+20")
addCommandHandler("graphics",function(_,preset)
 if not preset then return outputChatBox("[RedFear] /graphics low | balanced | cinematic | off (current: "..mode..")",180,210,190) end
 preset=preset:lower()
 if not presets[preset] then return outputChatBox("Choose low, balanced, cinematic or off.",255,180,100) end
 mode=preset;fault=false;release();save()
 outputChatBox("[RedFear] Graphics: "..mode,110,210,150)
end)
addCommandHandler("fixgraphics",function() release();fault=false;outputChatBox("[RedFear] Graphics reset. Use /graphics off to disable.",110,210,150) end)
addEventHandler("onClientResourceStart",resourceRoot,function()
 local config=xmlLoadFile("@graphics.xml")
 if config then
  local preset=xmlNodeGetAttribute(config,"preset")
  if presets[preset] then mode=preset end
  xmlUnloadFile(config)
 end
end)
addEventHandler("onClientRestore",root,function() release();fault=false end)
addEventHandler("onClientResourceStop",resourceRoot,release)
