dofile('dayzepoch/scripts/shared/progression.lua')
assert(DayZLevelFromXP(0)==1 and DayZLevelFromXP(199)==1 and DayZLevelFromXP(200)==2)
assert(DayZLevelFromXP(38000)==20 and DayZLevelFromXP(999999)==20)
local counts={civilian=0,military=0,fast=0}
for roll=1,100 do local k=DayZChooseZombieType(roll); counts[k]=counts[k]+1 end
assert(counts.civilian==75 and counts.military==20 and counts.fast==5)
assert(DayZZombieTypes.military.blood>DayZZombieTypes.civilian.blood)
assert(DayZZombieTypes.fast.speed>DayZZombieTypes.civilian.speed)
root={};resourceRoot={};local commands={};local events={};local saved={};local notices=0
function isElement(p) return type(p)=='table' end
function getElementType(p) return p.kind end
function getElementData(p,k) return p[k] end
function setDayZData(p,k,v) p[k]=v end
function isPedDead(p) return p.dead end
function getPlayerAccount(p) return p end
function isGuestAccount() return false end
function setAccountData(_,k,v) saved[k]=v end
function addEventHandler(n,_,fn) events[n]=fn end
function addEvent() end
function addCommandHandler(n,fn) commands[n]=fn end
function triggerClientEvent() notices=notices+1 end
function outputChatBox() end
function dayZRequest() return true end
function setElementModel(p,m) p.model=m end
function isPedInVehicle() return false end
function setPedAnimation(p,...) p.animated=true end
function setTimer() end
dofile('dayzepoch/scripts/progression_s.lua')
local p={kind='player',logedin=true,['stats.xp']=190,skin=22}
local z={kind='ped',['zombie:type']='military'}
assert(DayZAwardZombieXP(p,z,true) and p['stats.xp']==220 and p['stats.level']==2)
assert(saved['stats.xp']==220 and saved['stats.level']==2 and notices==1)
assert(not DayZAwardZombieXP(p,z,true) and p['stats.xp']==220)
assert(not DayZAwardZombieXP(p,{['zombie:noXP']=true},false))
commands.outfit(p,'outfit','scout'); assert(not p.model)
p['stats.xp']=600
commands.outfit(p,'outfit','scout'); assert(p.model==29 and p.skin==22 and saved['stats.cosmeticSkin']=='scout')
commands.outfit(p,'outfit','none'); assert(p.model==22 and p.skin==22)
commands.title(p,'title','legend'); assert(not p['stats.title'])
commands.title(p,'title','survivor'); assert(saved['stats.title']=='survivor')
commands.emote(p,'emote','dance');assert(not p.animated)
commands.emote(p,'emote','wave');assert(p.animated)
client=p;source=p;events['dayz:selectCosmetic']('title','rookie');assert(p['stats.title']=='survivor')
print('PASS XP thresholds, variant distribution, saved rewards, replay rejection, test exclusion, cosmetic gating and event source validation')
