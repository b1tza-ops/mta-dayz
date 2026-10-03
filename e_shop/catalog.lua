DayZShops = {
	["sf_docks"] = {
		["normal"] = {
			["supply_dealer"] = {-2316.357,2341.581,5.816,0},
			["vehicle_dealer"] = {-2318.751,2341.252,5.816,0},
			["supply_dealer_marker"] = {-2316.474,2342.978,5.816},
			["vehicle_dealer_marker"] = {-2318.938,2342.724,5.816,-2323.510,2343.452,5.816,0,0,0}, -- {marker_x,marker_y,marker_z,vehicle_spawn_x,vehicle_spawn_y,vehicle_spawn_z,rx,ry,rz}
		},
	},
	["ls_docks"] = {
		["normal"] = {
			["supply_dealer"] = {2771.237,-1605.615,11.440,-90},
			["vehicle_dealer"] = {2789.657,-1624.846,11.282,0},
			["supply_dealer_marker"] = {2772.641,-1605.640,11.440},
			["vehicle_dealer_marker"] = {2789.610,-1623.489,10.921,2787.918,-1619.733,11.006,0,0,80}, -- {marker_x,marker_y,marker_z,vehicle_spawn_x,vehicle_spawn_y,vehicle_spawn_z,rx,ry,rz}
		},
	},
}

DayZShopItems = {
	["normal"] = {
		["supply"] = {
			-- example: {"itemdata",amount,price};
			["Weapons"] = {
				{"weapon11",1,50},
				{"weapon21",1,20},
				{"weapon23",1,15},
				{"weapon20",1,30},
			},
			["Ammo"] = {
				{"mag5",20,12},
				{"mag1",15,12},
				{"mag3",30,12},
			},
			["Food"] = {
				{"fooditem4",1,10},
				{"fooditem5",1,10},
				{"fooditem1",1,10},
			},
			["Parts"] = {
				{"vehiclepart1",1,25},
				{"vehiclepart2",1,25},
				{"vehiclepart3",1,25},
				{"vehiclepart4",1,25},
				{"vehiclepart5",1,25}
			},
			["Backpacks"] = {
				{"backpack4",1,15},
				{"backpack3",1,25},
				{"backpack2",1,35},
			},
			["Toolbelts"] = {
				{"toolbelt4",1,10},
			},
			--["Convert"] = {
			--	{"zKill Bag",1,10},
			--},
		},
		["vehicle"] = {
			["Vehicles"] = {
				-- example: {"name",id,engine,rotor,tires,tankparts,scrap,slots,fuel,price}
				{"Armored Truck",528,1,0,4,1,1,50,80,500},
				{"HMMWV",470,1,0,4,1,1,46,100,100},
				{"Pickup Truck",422,1,0,4,1,1,25,80,80},
				{"Motorcycle",468,1,0,2,1,1,10,30,60},
				{"Old Bike",509,0,0,0,0,0,0,0,30},
			},
		},
	},
}

DayZShopCurrency = "zombieskilled";

