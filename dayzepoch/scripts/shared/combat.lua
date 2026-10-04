-- RedFear combat tuning: full-damage distance, maximum range, lethal headshot range.
DayZCombatWeapons={
 ['weapon1']={base=47850,near=100,far=300,head=180},
 ['weapon2']={base=9200,near=80,far=260,head=160},
 ['weapon3']={base=7800,near=80,far=240,head=150},
 ['weapon4']={base=7500,near=80,far=240,head=150},
 ['weapon5']={base=5600,near=90,far=260,head=170},
 ['weapon6']={base=4500,near=35,far=190,head=90},
 ['weapon7']={base=4276,near=15,far=100,head=40},
 ['weapon8']={base=3900,near=30,far=150,head=75},
 ['weapon9']={base=3850,near=35,far=190,head=90},
 ['weapon10']={base=3600,near=35,far=190,head=90},
 ['weapon11']={base=3420,near=35,far=190,head=90},
 ['weapon12']={base=3200,near=35,far=190,head=90},
 ['weapon13']={base=2800,near=35,far=190,head=90},
 ['weapon14']={base=2755,near=35,far=190,head=90},
 ['weapon15']={base=2321,near=10,far=80,head=30},
 ['weapon16']={base=20000,near=1,far=4,head=0},
 ['weapon17']={base=2939,near=1,far=4,head=0},
 ['weapon18']={base=2132,near=15,far=110,head=45},
 ['weapon19']={base=2789,near=15,far=100,head=40},
 ['weapon20']={base=1934,near=10,far=90,head=35},
 ['weapon21']={base=2189,near=10,far=90,head=35},
 ['weapon22']={base=1934,near=1,far=4,head=0},
 ['weapon23']={base=1889,near=10,far=85,head=30},
 ['weapon24']={base=1869,near=1,far=4,head=0},
 ['weapon25']={base=1553,near=10,far=80,head=30},
 ['weapon26']={base=983,near=1,far=4,head=0},
 ['weapon27']={base=950,near=1,far=4,head=0},
}
DayZCombatHelmets={helmet1=2,helmet2=1.8,helmet3=1.3,helmet4=1.5,helmet5=2.5}
DayZCombatVests={vest1=1.5,vest2=2}
function DayZCalculateHit(spec,distance,part,armor,condition)
 if not spec or distance>=spec.far then return 0,false,0 end
 local factor=distance<=spec.near and 1 or (spec.far-distance)/(spec.far-spec.near)
 local raw=spec.base*factor
 local protected=armor and armor>1 and condition>0
 local lethal=part==9 and spec.head>0 and distance<=spec.head and (not protected or spec.base>=12000)
 local damage=raw
 if part==5 or part==6 then damage=damage*0.45
 elseif part==7 or part==8 then damage=damage*0.60
 elseif part==4 then damage=damage*0.70 end
 if protected then damage=damage/armor end
 local wear=protected and math.max(1,math.ceil(raw/500)) or 0
 return math.floor(damage+0.5),lethal,wear
end
