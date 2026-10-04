local spawnPositions = {
	{-977.9072265625, -1626.1865234375, 76.3671875},
	{2533.2099609375, -2259.544921875, 3},
	{2917.044921875, -1257.7265625, 10.980945587158},
	{2864.2763671875, 149.7216796875, 11.823875427246},
	{2294.65625, 530.1083984375, 1.794376373291},
	{467.509765625, 309.349609375, 5.1328544616699},
	{-949.10546875, 964.1845703125, 16.716831207275},
	{-1430.421875, 1670.4423828125, 13.517515182495},
	{-2612.28125, 2239.365234375, 4.984375},
	{-2321.0419921875, 1398.4267578125, 4.9447212219238},
	{-2855.13671875, -336.994140625, 14.25234413147},
	{-2928.275390625, 1202.828125, 3.745231628418},
	{-1062.4326171875, 2788.62890625, 53.051651000977},
	{1934.921875, 2953.8095703125, 30.115264892578},
	{2922.9931640625, 2154.740234375, 12.194546699524},
	{2138.349609375, -84.2421875, 2.8917050361633},
};

local playerDataTable = {
	{"alivetime", 0},
	{"skin", 0},
	{"MAX_Slots", 8},
	{"helmet", ""},
	{"vest", ""},
	{"armorCondition.helmet1", 100},
	{"armorCondition.helmet2", 100},
	{"armorCondition.helmet3", 100},
	{"armorCondition.helmet4", 100},
	{"armorCondition.helmet5", 100},
	{"armorCondition.vest1", 100},
	{"armorCondition.vest2", 100},

	{"blood", 12000},
	{"food", math.random(80, 100)},
	{"thirst", math.random(80, 100)},
	{"temperature", 37},
	{"currentweapon_1", ""},
	{"currentweapon_2", ""},
	{"currentweapon_3", ""},
	{"bleeding", 0},
	{"brokenbone", false},
	{"pain", false},
	{"cold", false},
	{"spawnedzombies", 0},
	{"humanity", 2500},
	{"zombieskilled", 0},
	{"headshots", 0},
	{"murders", 0},
	{"banditskilled", 0},
	{"radiochannel", ""},
	{"gpschannel", ""},

	{"weapon1", 0},
	{"weapon2", 0},
	{"weapon3", 0},
	{"weapon4", 0},
	{"weapon5", 0},
	{"weapon6", 0},
	{"weapon7", 0},
	{"weapon8", 0},
	{"weapon9", 0},
	{"weapon10", 0},
	{"weapon11", 0},
	{"weapon12", 0},
	{"weapon13", 0},
	{"weapon14", 0},
	{"weapon15", 0},
	{"weapon16", 0},
	{"weapon17", 0},
	{"weapon18", 0},
	{"weapon19", 0},
	{"weapon20", 0},
	{"weapon21", 0},
	{"weapon22", 0},
	{"weapon23", 0},
	{"weapon24", 0},
	{"weapon25", 0},
	{"weapon26", 0},
	{"weapon27", 0},
	{"weapon28", 0},

	{"mag1", 0},
	{"mag2", 0},
	{"mag3", 0},
	{"mag4", 0},
	{"mag5", 0},
	{"mag6", 0},
	{"mag7", 0},
	{"mag8", 0},
	{"mag9", 0},
	{"mag10", 0},

	{"item1", 0},
	{"item2", 0},
	{"item3", 0},
	{"item4", 0},
	{"item5", 0},
	{"item6", 0},
	{"item7", 0},
	{"item8", 0},
	{"item9", 0},
	{"item10", 0},
	{"item11", 0},
	{"item12", 0},
	{"item13", 0},
	{"item14", 0},

	{"backpack1", 0},
	{"backpack2", 0},
	{"backpack3", 0},
	{"backpack4", 0},
	{"backpack5", 0},
	{"backpack6", 0},
	{"backpack7", 0},

	{"helmet1", 0},
	{"helmet2", 0},
	{"helmet3", 0},
	{"helmet4", 0},
	{"helmet5", 0},
	{"helmet6", 0},
	{"helmet7", 0},

	{"vest1", 0},
	{"vest2", 0},

	{"clothing1", 0},
	{"clothing2", 0},
	{"clothing3", 0},
	{"clothing4", 0},
	{"clothing5", 0},
	{"clothing6", 0},
	{"clothing7", 0},
	{"clothing8", 0},
	{"clothing9", 0},

	--{"currency1", 0},
	--{"currency2", 0},
	--{"currency3", 0},

	{"vehiclepart1", 0},
	{"vehiclepart2", 0},
	{"vehiclepart3", 0},
	{"vehiclepart4", 0},
	{"vehiclepart5", 0},

	{"medicine1", 0},
	{"medicine2", 0},
	{"medicine3", 0},
	{"medicine4", 0},
	{"medicine5", 2},
	{"medicine6", 1},
	{"medicine7", 0},
	{"medicine8", 0},

	{"fooditem1", 0},
	{"fooditem2", 0},
	{"fooditem3", 0},
	{"fooditem4", 0},
	{"fooditem5", 0},
	{"fooditem6", 0},
	{"fooditem7", 0},
	{"fooditem8", 0},
	{"fooditem9", 0},
	{"fooditem10", 0},
	{"fooditem11", 0},

	{"toolbelt1", 0},
	{"toolbelt2", 0},
	{"toolbelt3", 0},
	{"toolbelt4", 0},
	{"toolbelt5", 0},
	{"toolbelt6", 0},
	{"toolbelt7", 0},
	{"toolbelt8", 0},
	{"toolbelt9", 0},
};

-- player statistics or any other data that will save and load when player join/quit game (note: theese data does not and will not reset upon's player death)
local playerData2Table = {
    {"stats.xp",0},
    {"stats.level",1},
    {"stats.title","none"},
    {"stats.cosmeticSkin","none"},
	{"stats.email",""},
	{"stats.zombieskilled",0},
	{"stats.headshots",0},
	{"stats.murders",0},
	{"stats.banditskilled",0},
	{"stats.deaths",0},
	{"stats.playtime",0},
	{"stats.joined",0},
}

addEvent("onPlayerDayZRegister", false);
addEvent("onPlayerDayZLogin", false);
addEvent("kilLDayZPlayer", true);

addEventHandler("onPlayerDayZLogin", root, function(player)
	if not isElement(player) or getElementType(player) ~= "player" then return end
	local account = getPlayerAccount(player);
	if not account or isGuestAccount(account) then return end
	-- Console-created accounts have no character statistics yet. Initialize these
	-- before the fresh-spawn path and preserve existing statistics on respawn.
	for _,v in ipairs(playerData2Table) do
		local value = getAccountData(account,v[1]);
		if v[1] == "stats.joined" then
			value = tonumber(value);
			if not value or value ~= value or value <= 0 or value == math.huge then
				value = getTimestamp();
			end
			setAccountData(account,v[1],value);
		elseif type(value) ~= type(v[2]) then
			value = v[2]; setAccountData(account,v[1],value);
		end
		setDayZData(player,v[1],value);
	end
	local x,y,z = getAccountData(account, "last_x"), getAccountData(account, "last_y"), getAccountData(account, "last_z");
	local skin = tonumber(getAccountData(account, "skin")) or 71;
	if getAccountData(account, "isDead") or type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
		return spawnDayZPlayer(player);
	end
	spawnPlayer(player, x, y, z+0.5, math.random(360), skin, 0, 0);
	setElementFrozen(player,true);
	setTimer(setElementFrozen, 1000, 1, player, false);
	fadeCamera(player, true);
	setCameraTarget(player, player);
	local previousCol = getElementData(player,"playerCol");
	if isElement(previousCol) then destroyElement(previousCol) end
	local playerCol = createColSphere(x, y, z, 1.5);
	setDayZData(player, "playerCol", playerCol);
	attachElements(playerCol, player, 0, 0, 0);
	setDayZData(playerCol, "parent", player);
	setDayZData(playerCol, "player", true);
	for _,v in ipairs(playerDataTable) do
		local data = getAccountData(account,v[1]);
		if not data then
			setAccountData(account,v[1],v[2]);
			data = getAccountData(account,v[1]);
		end
		setDayZData(player,v[1],data);
	end
	setDayZData(player, "logedin", true);
	setElementModel(player, getElementData(player, "skin"));
	setTimer(checkBuggedAccont, (25*1000), 1, player);
	setDayZData(player, "spawnedzombies", 0);
	equipThem(player, 0);
	loadPlayerSafeCodes(player);
end);

addEventHandler("onPlayerDayZRegister", getRootElement(), function(player,email)
	if not isElement(player) or isGuestAccount(getPlayerAccount(player)) then return end
	spawnDayZPlayer(player);
	setDayZData(player, "radiochannel", "99999");
	setDayZData(player, "gpschannel", "");
	setDayZData(player, "gang", "None");
	for _,v in ipairs(playerData2Table) do
		setDayZData(player,v[1],v[2]);
	end
	setDayZData(player, "stats.email", email);
	setDayZData(player, "stats.joined", getTimestamp());
	savePlayerData(player);
	savePlayerData2(player);
end);

function spawnDayZPlayer(player)
	if player then
		local x,y,z = unpack(spawnPositions[math.random(#spawnPositions)]);
		local skin = math.random(71,73);
		spawnPlayer(player, x, y, z, math.random(360), skin, 0, 0);
		setCameraTarget(player, player);
		fadeCamera(player, true);
		setPedHeadless(player,false);
		local previousCol = getElementData(player,"playerCol");
	if isElement(previousCol) then destroyElement(previousCol) end
	local playerCol = createColSphere(x, y, z, 1.5);
		setDayZData(player, "playerCol", playerCol);
		attachElements(playerCol, player, 0, 0, 0);
		setDayZData(playerCol, "parent", player);
		setDayZData(playerCol, "player", true);
		setAccountData(getPlayerAccount(player), "isDead", false);
		setDayZData(player, "isDead", false);
		setDayZData(player, "logedin", true);
		setDayZData(player, "skin", skin);
		for _,v in ipairs(playerDataTable) do
			if (v[1] ~= "skin" and v[1] ~= "radiochannel" and v[1] ~= "gpschannel") then
				setDayZData(player, v[1], v[2]);
			end
		end
		setDayZData(player, "weapon25", 1);
		setDayZData(player, "mag1", 30);
		setDayZData(player, "toolbelt2", 1);
		setDayZData(player, "toolbelt1", 1);
		setDayZData(player, "MAX_Slots", 12);
		setDayZData(player, "logedin", true);
		setTimer(checkBuggedAccont, (25*1000), 1, player);
		setDayZData(player, "spawnedzombies", 0);
		showhelp(player,true);
	end
end

addEventHandler("kilLDayZPlayer", root, function(killer, headshot, weapon)
	if not dayZValidateAction("kilLDayZPlayer",{killer,headshot,weapon}) then return end
	local account = getPlayerAccount(source);
	if not account then return; end
	if (getElementData(source,"isDead")) then return; end
	triggerClientEvent(source, "onClientPlayerDeathInfo", source);
	if (headshot == true) then
		setPedHeadless(source,true);
	end
	killPed(source);
	triggerClientEvent(source, "hideInventoryManual", source);
	triggerClientEvent(source,"playSoundForClient",source,"death");
	setDayZData(source, "stats.deaths", getElementData(source, "stats.deaths") + 1);
	if (getElementData(source, "alivetime") >= 2) then
		--if not isElementInWater(source) then
			local x,y,z = getElementPosition(source);
			if (getDistanceBetweenPoints3D(x, y, z, 6000, 6000, 0) > 200) then
				local x,y,z = getElementPosition(source);
				local _,_,rotz = getElementRotation(source);
				local skin = getElementModel(source);
				local ped = createPed(skin, x, y, z, rotz);
				local pedCol = createColSphere(x, y, z, 1.5);
				if (headshot == true) then
					setPedHeadless(ped,true);
				end
				killPed(ped);
				setTimer(function(ped, pedCol)
					if isElement(ped) then destroyElement(ped); end
					if isElement(pedCol) then destroyElement(pedCol); end
				end, (15*60000), 1, ped, pedCol);
				attachElements(pedCol, ped, 0, 0, 0);
				setDayZData(pedCol, "parent", ped);
				setDayZData(pedCol, "playername", getPlayerName(source));
				setDayZData(pedCol, "deadman", true);
				setDayZData(pedCol, "MAX_Slots", getElementData(source, "MAX_Slots"));
				local time = getRealTime();
				setDayZData(pedCol, "deadreason",{"player",getPlayerName(source),"deadplayertext1",weapon,"deadplayertext2","deadplayertext3",time.hour,time.minute,"clocktext"});
				if (pedCol) then
					for _,v in ipairs(playerDataTable) do
						local itemPlus = getElementData(source, v[1]);
						setDayZData(pedCol, v[1], itemPlus);
					end
					local skin = getSkinNameFromID(getElementData(source, "skin"));
					setDayZData(pedCol, skin, getElementData(pedCol, skin) + 1);
					local backpack = getBackpackNameFromSlots(getElementData(source, "MAX_Slots"));
					setDayZData(pedCol, backpack, (getElementData(pedCol, backpack) or 0) + 1);
					local helmet = getElementData(source,"helmet");
					local vest = getElementData(source,"vest");
					if (helmet ~= "") then setDayZData(pedCol,helmet,getElementData(pedCol,helmet)+1); end
					if (vest ~= "") then setDayZData(pedCol,vest,getElementData(pedCol,vest)+1); end
				end
			end
		--end
	end
	if (killer and killer ~= source and getElementType(killer) == "player") then
		if (getElementData(source, "humanity") >= 1) then
			addPlayerStats(killer, "humanity", math.random(-2500, -1000));
		else
			addPlayerStats(killer, "humanity", math.random(1000, 2500));
		end
		setDayZData(killer, "murders", getElementData(killer, "murders") + 1);
		setDayZData(killer, "stats.murders", getElementData(killer, "stats.murders") + 1);
		if (getElementData(source, "humanity") <= 0) then
			setDayZData(killer, "banditskilled", getElementData(killer, "banditskilled") + 1);
			setDayZData(killer, "stats.banditskilled", getElementData(killer, "stats.banditskilled") + 1);
		end
		if (headshot == true) then
			setDayZData(killer, "headshots", getElementData(killer, "headshots") + 1);
			setDayZData(killer, "stats.headshots", getElementData(killer, "stats.headshots") + 1);
		end
		setDayZData(killer,"zombieskilled",getElementData(killer,"zombieskilled")+getElementData(source,"zombieskilled"))
		triggerClientEvent("displayClientInfo", root, getPlayerName(source):gsub("#%x%x%x%x%x%x", ""), 255, 255, 255, 3, getPlayerName(killer):gsub("#%x%x%x%x%x%x", ""));
	else
		triggerClientEvent("displayClientInfo", root, getPlayerName(source):gsub("#%x%x%x%x%x%x", ""), 255, 255, 255, 2);
	end
	for _,v in ipairs({1,2,3,4,5,6,7,8}) do
		setDayZData(source,"show_"..v,true)
	end
	setTimer(setElementPosition, 500, 1, source, 6000, 6000, 0);
	setAccountData(account, "isDead", true);
	setDayZData(source, "isDead", true);
	setTimer(spawnDayZPlayer, configVar.respawntime*1000+1000, 1, source);
end);

addEventHandler("onPlayerQuit", root, function()
	local previousCol = getElementData(source,"playerCol");
	if isElement(previousCol) then destroyElement(previousCol) end
	savePlayerData(source);
	savePlayerData2(source);
	savePlayerSafeCodes(source);
end);

addEventHandler("onResourceStop", resourceRoot, function()
	for _,v in pairs(getElementsByType("player")) do
		savePlayerData(v);
		savePlayerData2(v);
		savePlayerSafeCodes(v);
	end
end);

function savePlayerData(player)
	local account = getPlayerAccount(player);
	if account and not isGuestAccount(account) and getElementData(player,"logedin") then
		for _,v in ipairs(playerDataTable) do
			setAccountData(account, v[1], getElementData(player, v[1]));
		end
		local x,y,z = getElementPosition(player);
		setAccountData(account, "last_x", x);
		setAccountData(account, "last_y", y);
		setAccountData(account, "last_z", z);
	end
end

function savePlayerData2(player)
	local account = getPlayerAccount(player);
	if account and not isGuestAccount(account) and getElementData(player,"logedin") then
		for _,v in ipairs(playerData2Table) do
			setAccountData(account,v[1],getElementData(player,v[1]));
		end
	end
end

function savePlayerSafeCodes(player)
	local account = getPlayerAccount(player);
	if account and not isGuestAccount(account) and getElementData(player,"logedin") then
		for _,v in ipairs(getElementsByType("colshape")) do
			if (getElementData(v,"safe") and getElementData(v,"id")) then
				local safe_id = getElementData(v,"id");
				local safe_code = getElementData(v,safe_id);
				local player_code = getElementData(player,safe_id)
				if (player_code == safe_code) then
					setAccountData(account,safe_id,player_code);
				else
					setAccountData(account,safe_id,false);
				end
			end
		end
	end
end

function loadPlayerSafeCodes(player)
	local account = getPlayerAccount(player);
	if (account) then
		for _,v in pairs(getAllAccountData(account)) do
			local data = _;
			local value = v;
			for _,v in ipairs(getElementsByType("colshape")) do
				if (getElementData(v,"safe")) then
					local safe_id = getElementData(v,"id");
					local safe_code = getElementData(v,safe_id);
					if (safe_code == "raided") then
						setAccountData(account,safe_id,false);
					elseif (string.find(data,safe_id)) then
						setDayZData(player,data,value);
					end
				end
			end
		end
	end
end

function checkBuggedAccont(player)
	if isElement(player) then
		if not isGuestAccount(getPlayerAccount(player)) then
			if getElementData(player, "logedin") then
				if (getElementModel(player) == 0) then
					removeBackpack(player);
					removeHelmet(player);
					removeVest(player);
					removeWeaponBack(player);
					removeWeaponBack2(player);
					removeWeaponReplace(player);
					removeWeaponReplace2(player);
					spawnDayZPlayer(player);
					outputChatBox(getPlayerName(player).."'s account is buggy and has been reset.", getRootElement(), 25, 255, 25);
					return;
				end
				for _,v in ipairs(playerDataTable) do
					if (not getElementData(player,v[1])) then
						setDayZData(player,v[1],v[2]);
					end
					if (type(getElementData(player, v[1])) ~= type(v[2])) then
						removeBackpack(player);
						removeHelmet(player);
						removeVest(player);
						removeWeaponBack(player);
						removeWeaponBack2(player);
						removeWeaponReplace(player);
						removeWeaponReplace2(player);
						spawnDayZPlayer(player);
						outputChatBox(getPlayerName(player).."'s account is buggy and has been reset.", getRootElement(), 25, 255, 25);
					end
				end
			end
		end
	end
end

addCommandHandler("kill", function(player)
	triggerEvent("kilLDayZPlayer", player);
end);
setTimer(function()
    for _, player in ipairs(getElementsByType("player")) do
        savePlayerData(player); savePlayerData2(player); savePlayerSafeCodes(player)
    end
end,60000,0)
