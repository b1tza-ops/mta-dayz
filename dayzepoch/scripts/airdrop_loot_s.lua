-- Every crate has useful essentials; rare military crates occur on 8% of rolls.
function DayZRollAirdropLoot()
    local rare=math.random(1,100)<=8
    local loot={medicine5=math.random(3,6),medicine3=math.random(1,3)}
    local function add(item,quantity) loot[item]=(loot[item] or 0)+quantity end
    local function pick(pool) return pool[math.random(1,#pool)] end
    add(pick({"fooditem3","fooditem4","fooditem10"}),math.random(3,6))
    add(pick({"fooditem1","fooditem7","fooditem6"}),math.random(3,6))
    add(pick({"vehiclepart1","vehiclepart3","vehiclepart4","vehiclepart5","item9"}),math.random(1,2))
    add(pick({"toolbelt4","toolbelt2","toolbelt5","backpack3","medicine8"}),1)
    local weapons=rare and {{"weapon11","mag5",120,180},{"weapon12","mag6",150,240},{"weapon2","mag10",30,60},{"weapon5","mag8",30,60}}
        or {{"weapon7","mag7",21,42},{"weapon9","mag4",60,120},{"weapon10","mag4",60,120}}
    local weapon=pick(weapons)
    add(weapon[1],1);add(weapon[2],math.random(weapon[3],weapon[4]))
    if rare then
        add("medicine1",1);add("medicine7",math.random(1,2))
        add(pick({"backpack1","vest2","toolbelt7","toolbelt6"}),1)
        add(pick({"vehiclepart1","vehiclepart2","item3"}),1)
    end
    return loot,rare
end
