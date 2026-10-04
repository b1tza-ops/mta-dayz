unpack=unpack or table.unpack
dofile('dayzepoch/scripts/shared/combat.lua')
local spec=DayZCombatWeapons.weapon11
assert(DayZCalculateHit(spec,0,3,nil,0)==3420)
assert(DayZCalculateHit(spec,spec.far,3,nil,0)==0)
assert(DayZCalculateHit(spec,(spec.near+spec.far)/2,3,nil,0)==1710)
assert(DayZCalculateHit(spec,0,5,nil,0)==1539)
assert(DayZCalculateHit(spec,0,7,nil,0)==2052)
local damage,lethal,wear=DayZCalculateHit(spec,20,9,nil,0);assert(lethal and wear==0)
damage,lethal,wear=DayZCalculateHit(spec,20,9,2,100);assert(not lethal and damage==1710 and wear>0)
damage,lethal=DayZCalculateHit(spec,20,9,2,0);assert(lethal)
damage,lethal=DayZCalculateHit(spec,100,9,nil,0);assert(not lethal and damage>0)
damage,lethal=DayZCalculateHit(DayZCombatWeapons.weapon1,20,9,2,100);assert(lethal)
local handlers={};root={};resourceRoot={};local now=1000;local kills,feedback=0,0
local function player(x) return {kind='player',logedin=true,humanity=100,blood=12000,x=x or 0,dim=0,int=0,currentweapon_1='weapon11'} end
local attacker,victim=player(0),player(10)
function isElement(p) return type(p)=='table' and not p.destroyed end
function getElementType(p) return p.kind end
function getElementData(p,k) return p[k] or false end
function setDayZData(p,k,v) p[k]=v end
function getElementDimension(p) return p.dim end
function getElementInterior(p) return p.int end
function isPedDead(p) return p.dead or false end
function getPedOccupiedVehicle() return false end
function getElementModel() return 528 end
function getSlotFromWeapon(w) return w==31 and 5 or 2 end
function getPedWeapon() return 31 end
function getWeaponAmmoType() return 'mag5',31 end
function getElementPosition(p) return p.x,0,0 end
function getDistanceBetweenPoints3D(x,_,__,y) return math.abs(x-y) end
function getTickCount() return now end
function getWeaponNameFromID() return 'M4' end
function addEvent() end
function addEventHandler(n,_,fn) handlers[n]=fn end
function triggerClientEvent() feedback=feedback+1 end
function triggerEvent() kills=kills+1 end
function outputDebugString() end
dofile('dayzepoch/scripts/combat_s.lua')
local function hit(who,origin,part,w)
 now=now+100;client=who;source=origin;handlers['dayz:combatHit'](attacker,w or 31,part or 3)
end
hit(victim,attacker);assert(victim.blood==12000)
hit(victim,victim,3,24);assert(victim.blood==12000)
victim.dim=1;hit(victim,victim);assert(victim.blood==12000);victim.dim=0
victim.x=300;hit(victim,victim);assert(victim.blood==12000);victim.x=10
victim.vest='vest2';victim['armorCondition.vest2']=100;hit(victim,victim);assert(victim.blood==10290 and victim['armorCondition.vest2']==93)
local blood=victim.blood;handlers['dayz:combatHit'](attacker,31,3);assert(victim.blood==blood)
victim['armorCondition.vest2']=1;hit(victim,victim);assert(victim.vest=='' and victim['armorCondition.vest2']==100)
hit(victim,victim,9);assert(victim.blood==0 and kills==1 and feedback>=6)
print('PASS combat range, limb scaling, helmet protection, lethal boundaries, spoofing, world/range validation, wear, breakage, throttling, feedback and death')
