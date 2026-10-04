local attempts = {}
local function text(value,min,max)
    return type(value) == "string" and #value >= min and #value <= max and not value:find("%c")
end
local function caller(player)
    if not isElement(client) or source ~= client or player ~= client then return false end
    local now = getTickCount()
    if attempts[client] and now-attempts[client] < 1500 then return false end
    attempts[client] = now
    return client
end
local function fail(player,message)
    triggerClientEvent(player,"seterror",player,message)
end
local function success(player,language)
    setElementData(player,"language",language)
    triggerClientEvent(player,"loginSuccess",player)
    triggerClientEvent(player,"lowScreenWarn",player)
end
local function validLanguage(language)
    return type(language) == "string" and (language == "en" or language == "ru" or language == "lv")
end
function loginHandler(player,username,password,language)
    player = caller(player)
    if not player then return end
    if not isGuestAccount(getPlayerAccount(player)) then fail(player,"Already logged in."); return end
    if not text(username,1,64) or not text(password,1,128) or not validLanguage(language) then
        fail(player,"Invalid login details."); return
    end
    local account = getAccount(username,password)
    if not account or not logIn(player,account,password) then fail(player,"Login failed."); return end
    -- Internal character events cannot be invoked over the network.
    triggerEvent("onPlayerDayZLogin",player,player)
    success(player,language)
end
addEvent("submitLogin",true)
addEventHandler("submitLogin",root,loginHandler)
function registerHandler(player,username,password,email,language)
    player = caller(player)
    if not player then return end
    if not isGuestAccount(getPlayerAccount(player)) then fail(player,"Already logged in."); return end
    if not text(username,1,64) or not text(password,1,128) or not text(email,0,254)
        or not validLanguage(language) then fail(player,"Invalid registration details."); return end
    local account = addAccount(username,password)
    if not account then fail(player,"Account could not be created."); return end
    if not logIn(player,account,password) then fail(player,"Login failed. Please sign in."); return end
    triggerEvent("onPlayerDayZRegister",player,player,email)
    success(player,language)
end
addEvent("submitRegister",true)
addEventHandler("submitRegister",root,registerHandler)
function set_account_pass(oldPassword,newPassword)
    local player = caller(source)
    if not player then return end
    local account = getPlayerAccount(player)
    if not account or isGuestAccount(account) or not text(oldPassword,1,128) or not text(newPassword,1,128) then return end
    local authenticated = getAccount(getAccountName(account),oldPassword)
    local changed = authenticated == account and setAccountPassword(account,newPassword)
    triggerClientEvent(player,"settingsErrorMessage",player,changed and "Password changed." or "Password change failed.",
        changed and 0 or 255,changed and 255 or 0,0)
end
addEvent("set_account_pass",true)
addEventHandler("set_account_pass",root,set_account_pass)
addEventHandler("onPlayerQuit",root,function() attempts[source] = nil end)
