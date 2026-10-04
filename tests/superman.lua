local handlers={};root={};resourceRoot={}
function getRootElement() return root end
function getThisResource() return {} end
function getResourceRootElement() return resourceRoot end
function addEvent() end
function addEventHandler(n,_,fn) handlers[n]=fn end
function setTimer(fn) permissionCheck=fn end
function outputDebugString() end
function outputChatBox() end
function isElement(p) return type(p)=='table' end
function isDayZAdmin(p) return p.admin==true end
function isPedDead(p) return p.dead==true end
function getElementData(p,k) return p[k] end
function setElementData(p,k,v,sync,policy) assert(sync=='broadcast' and policy=='deny');p[k]=v end
local admin={admin=true,logedin=true};local player={logedin=true}
function getElementsByType() return {admin,player} end
dofile('e_admin/superman/server.lua');handlers.onResourceStart()
source=player;client=player;handlers['superman:start']();assert(player['superman:flying']==false)
source=admin;client=player;handlers['superman:start']();assert(not admin['superman:flying'])
client=admin;handlers['superman:start']();assert(admin['superman:flying']==true)
admin.admin=false;permissionCheck();assert(admin['superman:flying']==false)
admin.admin=true;handlers['superman:start']();handlers.onPlayerLogout();assert(admin['superman:flying']==false)
admin.logedin=false;handlers['superman:start']();assert(admin['superman:flying']==false)
print('PASS Superman rejects non-admin, spoofed and logged-out callers; revokes flight on ACL removal and logout')
