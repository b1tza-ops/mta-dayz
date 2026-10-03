-- Readable DayZ catalogue. Item IDs stay in row data for server validation.
local categories = {"All items"}
local selfButton, searchEdit, statusLabel
local function selectedItem()
    local row = guiGridListGetSelectedItem(giveWindowGridlist)
    if row == -1 then return false end
    return guiGridListGetItemData(giveWindowGridlist,row,1)
end
function refreshGiveItems()
    if not isElement(giveWindowGridlist) then return end
    guiGridListClear(giveWindowGridlist)
    local category = categories[guiComboBoxGetSelected(giveWindowCombobox)+1] or "All items"
    local query = string.lower(guiGetText(searchEdit))
    local rows = {}
    for group, entries in pairs(items) do
        if category == "All items" or category == group then
            for _,id in ipairs(entries) do
                local name = exports.dayzepoch:getLanguageTextClient(id) or id
                if string.find(string.lower(name),query,1,true) or string.find(string.lower(id),query,1,true) then
                    rows[#rows+1]={id=id,name=name,category=group}
                end
            end
        end
    end
    table.sort(rows,function(a,b) return a.name < b.name end)
    for _,item in ipairs(rows) do
        local row=guiGridListAddRow(giveWindowGridlist)
        guiGridListSetItemText(giveWindowGridlist,row,1,item.name,false,false)
        guiGridListSetItemData(giveWindowGridlist,row,1,item.id)
        guiGridListSetItemText(giveWindowGridlist,row,2,item.category,false,false)
    end
end
local function giveToSelf()
    local item=selectedItem()
    local quantity=tonumber(guiGetText(giveWindowEditboxQuant))
    if not item then guiSetText(statusLabel,"Choose an item first.");return end
    if not quantity or quantity%1~=0 or quantity<1 or quantity>10000 then
        guiSetText(statusLabel,"Enter a quantity from 1 to 10000.");return
    end
    guiSetText(statusLabel,"Requesting items...")
    triggerServerEvent("giveEvent",localPlayer,localPlayer,item,quantity)
end
function giveGui()
    local sw,sh=guiGetScreenSize()
    local w,h=math.min(620,sw-30),math.min(500,sh-30)
    giveWindow=guiCreateWindow((sw-w)/2,(sh-h)/2,w,h,"DayZ admin items",false)
    guiWindowSetSizable(giveWindow,false)
    guiSetProperty(giveWindow,"AlwaysOnTop","True")
    guiSetVisible(giveWindow,false)
    guiCreateLabel(15,30,50,20,"Search:",false,giveWindow)
    searchEdit=guiCreateEdit(70,26,w-85,28,"",false,giveWindow)
    guiEditSetMaxLength(searchEdit,80)
    giveWindowCombobox=guiCreateComboBox(15,62,w-30,220,"All items",false,giveWindow)
    categories={"All items"}
    local sorted={};for category in pairs(items) do sorted[#sorted+1]=category end;table.sort(sorted)
    for _,category in ipairs(sorted) do categories[#categories+1]=category end
    for _,category in ipairs(categories) do guiComboBoxAddItem(giveWindowCombobox,category) end
    guiComboBoxSetSelected(giveWindowCombobox,0)
    giveWindowGridlist=guiCreateGridList(15,96,w-30,h-206,false,giveWindow)
    guiGridListSetSortingEnabled(giveWindowGridlist,false)
    guiGridListAddColumn(giveWindowGridlist,"Item name",0.61)
    guiGridListAddColumn(giveWindowGridlist,"Category",0.31)
    guiCreateLabel(15,h-101,70,22,"Quantity:",false,giveWindow)
    giveWindowEditboxQuant=guiCreateEdit(90,h-105,75,28,"1",false,giveWindow)
    guiEditSetMaxLength(giveWindowEditboxQuant,5)
    selfButton=guiCreateButton(180,h-105,w-195,28,"Give to myself",false,giveWindow)
    giveWindowButtonGive=guiCreateButton(15,h-68,(w-45)/2,28,"Give to selected player",false,giveWindow)
    giveWindowButtonClose=guiCreateButton(30+(w-45)/2,h-68,(w-45)/2,28,"Close",false,giveWindow)
    statusLabel=guiCreateLabel(15,h-34,w-30,20,"Admin grants can exceed backpack capacity.",false,giveWindow)
    addEventHandler("onClientGUIChanged",searchEdit,refreshGiveItems,false)
    addEventHandler("onClientGUIComboBoxAccepted",giveWindowCombobox,refreshGiveItems,false)
    addEventHandler("onClientGUIClick",selfButton,giveToSelf,false)
    addEventHandler("onClientGUIClick",giveWindowButtonGive,function()
        if guiGridListGetSelectedItem(gridlistPlayers1)==-1 then
            guiSetText(statusLabel,"Select a player in the main admin panel first.");return
        end
        give()
    end,false)
    addEventHandler("onClientGUIClick",giveWindowButtonClose,closeGiveGui,false)
    addEventHandler("onClientGUIClick",buttonItems,openGiveGui,false)
    refreshGiveItems()
end
function openGiveGui()
    if not isElement(giveWindow) then return end
    setElementData(localPlayer,"isGui",true,false)
    guiSetVisible(giveWindow,true)
    showCursor(true)
    refreshGiveItems()
end
function closeGiveGui()
    guiSetVisible(giveWindow,false)
    if isElement(hiddenGridlist) then guiSetVisible(hiddenGridlist,false) end
    local mainOpen=isElement(window) and guiGetVisible(window)
    showCursor(mainOpen)
    setElementData(localPlayer,"isGui",mainOpen,false)
end
addEventHandler("onClientResourceStart",resourceRoot,giveGui)
addEvent("dayz:openItemPanel",true)
addEventHandler("dayz:openItemPanel",resourceRoot,openGiveGui)
addCommandHandler("dayzpanel",function()
    triggerServerEvent("dayz:requestItemPanel",localPlayer)
end)
addEvent("dayz:adminItemGranted",true)
addEventHandler("dayz:adminItemGranted",resourceRoot,function(item,quantity,targetName)
    if isElement(statusLabel) then
        local name=exports.dayzepoch:getLanguageTextClient(item) or item
        guiSetText(statusLabel,"Added "..quantity.." x "..name.." to "..targetName..".")
    end
end)
