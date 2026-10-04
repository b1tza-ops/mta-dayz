-- Display roles only; these labels never grant administrative permissions.
local ownerAccounts = {b1tza=true}
local roles = {
    {name="Owner",group="Owner",color="#FFB347"},
    {name="Admin",group="Admin",color="#FF6666"},
    {name="Moderator",group="SuperModerator",color="#66CCFF"},
    {name="Moderator",group="Moderator",color="#66CCFF"},
    {name="VIP",group="VIP",color="#CC99FF"}
}
local channels={GLOBAL="#66CCFF",LOCAL="#D3D3D3",RADIO="#FFD966",TEAM="#55DDBB"}
local lastMessage={}
local function clean(value)
    return tostring(value or ""):gsub("#%x%x%x%x%x%x",""):gsub("%c"," ")
end
function DayZChatRole(player)
    local account=getPlayerAccount(player)
    if account and not isGuestAccount(account) then
        local name=getAccountName(account)
        if ownerAccounts[name] then return "Owner","#FFB347" end
        for _,role in ipairs(roles) do
            local group=aclGetGroup(role.group)
            if group and isObjectInACLGroup("user."..name,group) then return role.name,role.color end
        end
    end
    return "Player","#FFFFFF"
end
function DayZFormatChat(player,channel,message)
    local role,color=DayZChatRole(player)
    return (channels[channel] or "#FFFFFF").."["..channel.."] "..color.."["..role.."] "
        ..clean(getPlayerName(player)).."#FFFFFF: "..clean(message)
end
function DayZPrepareChat(player,message)
    if not isElement(player) or getElementType(player)~="player" then return false end
    message=clean(message):match("^%s*(.-)%s*$")
    if message=="" then return false end
    if isPlayerMuted(player) then
        outputChatBox(getLanguageTextServer("clientinfotext43",player),player,160,40,40)
        return false
    end
    if #message>200 then
        outputChatBox("Chat messages must be 200 bytes or fewer.",player,160,40,40)
        return false
    end
    local now=getTickCount()
    if (lastMessage[player] and now-lastMessage[player]<1000) or getElementData(player,"antichat") then
        outputChatBox(getLanguageTextServer("clientinfotext41",player),player,160,40,40)
        return false
    end
    lastMessage[player]=now
    return message
end
local function send(player,channel,message)
    local line=DayZFormatChat(player,channel,message)
    local x,y,z=getElementPosition(player)
    for _,recipient in ipairs(getElementsByType("player")) do
        local receives=channel=="GLOBAL"
        if channel=="LOCAL" then
            local rx,ry,rz=getElementPosition(recipient)
            receives=getElementDimension(player)==getElementDimension(recipient)
                and getElementInterior(player)==getElementInterior(recipient)
                and getDistanceBetweenPoints3D(x,y,z,rx,ry,rz)<=15
        elseif channel=="RADIO" then
            receives=(tonumber(getElementData(recipient,"toolbelt8")) or 0)>=1
                and getElementData(recipient,"radiochannel")==getElementData(player,"radiochannel")
        end
        if receives then outputChatBox(line,recipient,255,255,255,true) end
    end
end
addEventHandler("onPlayerChat",root,function(message,kind)
    if kind==0 or kind==1 or kind==2 then cancelEvent() end
    if kind==0 then
        message=DayZPrepareChat(source,message)
        if message then send(source,"LOCAL",message) end
    elseif kind==2 then
        -- Native team chat follows the existing DayZ gang channel.
        executeCommandHandler("teamchat",source,message)
    end
end)
addCommandHandler("localchat",function(player,_,...)
    local message=DayZPrepareChat(player,table.concat({...}," "))
    if message then send(player,"LOCAL",message) end
end)
addCommandHandler("globalchat",function(player,_,...)
    if not configVar.globalchat then return end
    local message=DayZPrepareChat(player,table.concat({...}," "))
    if message then send(player,"GLOBAL",message) end
end)
addCommandHandler("radiochat",function(player,_,...)
    if not isElement(player) or getElementType(player)~="player" then return end
    if (tonumber(getElementData(player,"toolbelt8")) or 0)<1 then
        triggerClientEvent(player,"displayClientInfo",player,getLanguageTextServer("clientinfotext7",player),160,40,40)
        return
    end
    local message=DayZPrepareChat(player,table.concat({...}," "))
    if message then send(player,"RADIO",message) end
end)
addEventHandler("onPlayerQuit",root,function() lastMessage[source]=nil end)
outputDebugString("[DayZ chat] Loaded role labels for local, global, radio and team chat.",3)
