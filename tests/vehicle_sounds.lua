local handlers,commands,sounds={}, {},{}
root={};resourceRoot={};localPlayer={logedin=true,dim=0,int=0}
local vehicle={kind='vehicle',model=422,dim=0,int=0,health=900,running=true,streamed=true}
local tick,fail,attempts=10000,false,0
function isElement(e) return type(e)=='table' and not e.dead end
function getElementType(e) return e.kind end
function getElementModel(e) return e.model end
function getElementData(e,k) return e[k] or false end
function getElementHealth(e) return e.health end
function getElementDimension(e) return e.dim end
function getElementInterior(e) return e.int end
function isElementStreamedIn(e) return e.streamed end
function getVehicleEngineState(e) return e.running end
function getVehicleRotorSpeed() return 0.2 end
function getElementVelocity() return 0,0,0 end
function getElementPosition() return 0,0,0 end
function getTickCount() return tick end
function getElementsByType() return {vehicle} end
function playSound3D() attempts=attempts+1;if fail then return false end;local s={};sounds[#sounds+1]=s;return s end
function destroyElement(e) e.dead=true end
function setElementDimension(e,v) e.dim=v end
function setElementInterior(e,v) e.int=v end
function attachElements(s,v) s.vehicle=v end
function setSoundMinDistance() end
function setSoundMaxDistance() end
function setSoundPaused(s,p) assert(not p and isElement(s)) end
function setSoundSpeed(s,v) assert(isElement(s) and v>0) end
function outputDebugString() end
function outputChatBox() end
function setTimer(fn) update=fn end
function addEventHandler(n,_,fn) handlers[n]=fn end
function addCommandHandler(n,fn) commands[n]=fn end
local function live() local n=0;for _,s in ipairs(sounds) do if isElement(s) then n=n+1 end end;return n end
dofile('dayzepoch/scripts/vehicle_sounds_c.lua')
update();update();assert(live()==1 and attempts==1)
sounds[1].dead=true;update();assert(live()==1 and attempts==2)
vehicle.running=false;update();assert(live()==0)
vehicle.running=true;fail=true;update();local count=attempts;update();assert(attempts==count)
tick=tick+5000;fail=false;update();assert(live()==1)
vehicle.dim=1;update();assert(live()==0)
vehicle.dim=0;update();assert(live()==1)
source=vehicle;handlers.onClientElementStreamOut();assert(live()==0)
update();commands.fixvehiclesounds();assert(live()==1)
vehicle.helicrash=true;update();assert(live()==0)
vehicle.helicrash=false;update();localPlayer.logedin=false;update();assert(live()==0)
print('PASS vehicle audio single loop, missing-loop recovery, engine stop, retry cooldown, world change, stream cleanup, manual reset, crash exclusion and logout')
