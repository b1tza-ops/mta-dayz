local handlers,commands,output={}, {},{}
root={};local now=1000
function addEventHandler(n,_,f) handlers[n]=f end
function addCommandHandler(n,f) commands[n]=f end
function isElement(p) return type(p)=='table' and p.kind=='player' end
function getElementType(p) return p.kind end
function getPlayerAccount(p) return p.account end
function isGuestAccount(a) return a.guest end
function getAccountName(a) return a.name end
local groups={Admin=true,VIP=true,Moderator=true}
function aclGetGroup(g) return groups[g] and g end
function isObjectInACLGroup(n,g) return memberships[n] and memberships[n][g] or false end
function getPlayerName(p) return p.name end
function getElementData(p,k) return p.data[k] or false end
function getTickCount() return now end
function isPlayerMuted(p) return p.muted end
function getLanguageTextServer(k) return k end
function outputChatBox(s,p) output[#output+1]={s=s,p=p} end
function outputDebugString() end
function getElementPosition(p) return p.x,0,0 end
function getElementDimension(p) return p.dim or 0 end
function getElementInterior(p) return p.int or 0 end
function getDistanceBetweenPoints3D(x,_,__,y) return math.abs(x-y) end
function cancelEvent() cancelled=true end
function triggerClientEvent() radioMissing=true end
function executeCommandHandler(n,p,s) commands[n](p,n,s) end
local function player(n,x) return {kind='player',name=n,x=x or 0,data={},account={name=n}} end
local owner,admin,vip,regular=player('b1tza'),player('admin'),player('vip'),player('regular')
local players={owner,admin,vip,regular}
function getElementsByType() return players end
memberships={['user.admin']={Admin=true,VIP=true},['user.vip']={VIP=true}}
configVar={globalchat=true}
dofile('dayzepoch/scripts/chat_s.lua')
assert(DayZChatRole(owner)=='Owner' and DayZChatRole(admin)=='Admin' and DayZChatRole(vip)=='VIP' and DayZChatRole(regular)=='Player')
regular.name='b1tza';regular.data.admin=true;assert(DayZChatRole(regular)=='Player')
regular.account={name='b1tza',guest=true};assert(DayZChatRole(regular)=='Player');regular.account={name='regular'}
local line=DayZFormatChat(owner,'GLOBAL','#FF0000Hi\nthere');assert(line:find('[GLOBAL]',1,true) and line:find('[Owner] b1tza',1,true) and not line:find('#FF0000',1,true))
commands.globalchat(owner,'globalchat','hello');assert(#output==4)
output={};commands.globalchat(owner,'globalchat','spam');assert(#output==1 and output[1].p==owner)
now=now+1000;owner.muted=true;output={};commands.globalchat(owner,'globalchat','muted');assert(#output==1);owner.muted=false
output={};commands.globalchat(owner,'globalchat','   ');assert(#output==0)
commands.globalchat(owner,'globalchat',string.rep('x',201));assert(#output==1)
output={};admin.x=16;vip.dim=1;regular.int=1;source=owner;handlers.onPlayerChat('nearby',0);assert(cancelled and #output==1 and output[1].p==owner)
now=now+1000;output={};owner.data.toolbelt8=1;owner.data.radiochannel=5;admin.data.toolbelt8=1;admin.data.radiochannel=5;vip.data.toolbelt8=1;vip.data.radiochannel=6
commands.radiochat(owner,'radiochat','radio');assert(#output==2)
commands.radiochat(regular,'radiochat','no radio');assert(radioMissing)
now=now+1000;output={};configVar.globalchat=false;commands.globalchat(owner,'globalchat','disabled');assert(#output==0)
local f=assert(io.open('dayzepoch/scripts/tools/team/team_s.lua'));local s=f:read('*a');f:close()
local body=assert(s:match('addCommandHandler%("teamchat", function%(player, _, %.%.%.%)(.-)\nend%);'))
function getPlayerGang() return 'Test' end
function getPlayersInGang() return {owner,regular} end
assert(load('return function(player,_,...) '..body..' end'))()(owner,'teamchat','team');assert(#output==2 and output[1].s:find('[TEAM]',1,true))
print('PASS roles, spoof resistance, format, colour stripping, global, local world/range, radio, team, mute, empty messages and throttling')
