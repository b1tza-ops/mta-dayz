DayZZombieTypes = {
 civilian={blood=10000,xp=10,damage=1,speed=1},
 military={blood=18000,xp=25,damage=1.35,speed=0.85,skin=287},
 fast={blood=7000,xp=40,damage=1.1,speed=1.4,skin=105}
}
DayZCosmetics = {
 title={rookie={level=1,name="Rookie"},survivor={level=3,name="Survivor"},hunter={level=7,name="Hunter"},veteran={level=12,name="Veteran"},legend={level=20,name="Legend"}},
 outfit={scout={level=3,name="Scout",skin=29},ranger={level=7,name="Ranger",skin=73},veteran={level=12,name="Veteran",skin=179}},
 emote={wave={level=1,name="Wave",block="ON_LOOKERS",anim="wave_loop"},cheer={level=5,name="Cheer",block="ON_LOOKERS",anim="shout_01"},dance={level=10,name="Dance",block="DANCING",anim="dnce_M_a"}}
}
function DayZXPThreshold(level) return 100*level*(level-1) end
function DayZLevelFromXP(xp)
 local level=1
 while level<20 and xp>=DayZXPThreshold(level+1) do level=level+1 end
 return level
end
function DayZChooseZombieType(roll)
 if roll<=5 then return "fast" elseif roll<=25 then return "military" end
 return "civilian"
end
