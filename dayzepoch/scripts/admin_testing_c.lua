local panel, locations, quantity, status, vehicles
local function request(action,value) triggerServerEvent("dayz:testAction",localPlayer,action,value) end
local function button(x,y,w,text,callback)
    local element=guiCreateButton(x,y,w,30,text,false,panel)
    addEventHandler("onClientGUIClick",element,callback,false)
end
local function open()
    if not isElement(panel) then
        local sw,sh=guiGetScreenSize();local w,h=math.min(600,sw-30),math.min(590,sh-30)
        panel=guiCreateWindow((sw-w)/2,(sh-h)/2,w,h,"DayZ admin testing",false)
        guiWindowSetSizable(panel,false)
        locations=guiCreateComboBox(15,30,w-30,200,"Choose teleport location",false,panel)
        for _,location in ipairs(DayZAdminTestLocations) do guiComboBoxAddItem(locations,location.name) end
        guiComboBoxSetSelected(locations,0)
        button(15,70,(w-45)/2,"Teleport",function() request("teleport",guiComboBoxGetSelected(locations)+1) end)
        button(30+(w-45)/2,70,(w-45)/2,"Return to previous position",function() request("back") end)
        guiCreateLabel(15,118,140,20,"Zombie count (1-10):",false,panel)
        quantity=guiCreateEdit(160,112,60,28,"3",false,panel)
        guiEditSetMaxLength(quantity,2)
        button(235,112,w-250,"Spawn zombies nearby",function() request("zombies",guiGetText(quantity)) end)
        button(15,156,(w-45)/2,"Trigger test airdrop",function() request("airdrop") end)
        button(30+(w-45)/2,156,(w-45)/2,"Inspect nearest vehicle",function() request("inspect") end)
        vehicles=guiCreateComboBox(15,200,(w-45)/2,230,"Choose DayZ vehicle",false,panel)
        for _,vehicle in ipairs(DayZAdminTestVehicles) do guiComboBoxAddItem(vehicles,vehicle.name.." ("..vehicle.model..")") end
        guiComboBoxSetSelected(vehicles,0)
        button(30+(w-45)/2,200,(w-45)/2,"Spawn fully working vehicle",function() request("vehicle",guiComboBoxGetSelected(vehicles)+1) end)
        button(15,244,w-30,"Clean up my test zombies, airdrops and vehicles",function() request("cleanup") end)
        status=guiCreateMemo(15,288,w-30,h-334,"Ready. Spawn on flat ground, on foot and outdoors.\nZombies expire after 5 minutes; airdrops after 15 minutes.\nTeleport destinations and return position are handled by the server.",false,panel)
        guiMemoSetReadOnly(status,true)
        button(15,h-40,w-30,"Close",function()
            guiSetVisible(panel,false)
            setElementData(localPlayer,"isGui",false,false)
            showCursor(false)
        end)
    end
    guiSetVisible(panel,true);showCursor(true)
    setElementData(localPlayer,"isGui",true,false)
end
addCommandHandler("dayztest",function() request("open") end)
addEvent("dayz:openTesting",true)
addEventHandler("dayz:openTesting",resourceRoot,open)
addEvent("dayz:testResult",true)
addEventHandler("dayz:testResult",resourceRoot,function(message)
    if type(message)~="string" then return end
    if isElement(status) then guiSetText(status,message) end
    outputChatBox("[DayZ testing] "..message,150,220,255)
end)
addEvent("dayz:testDropLanded",true)
addEventHandler("dayz:testDropLanded",resourceRoot,function(col,crate)
    if isElement(col) and isElement(crate) and isElementWithinColShape(localPlayer,col) then
        -- Re-evaluate the normal loot menu for players already beside the landing point.
        triggerEvent("onClientColShapeHit",col,localPlayer,true)
    end
end)
addEventHandler("onClientResourceStop",resourceRoot,function()
    if isElement(panel) and guiGetVisible(panel) then showCursor(false) end
end)
