-- Survival-themed account screen. Native edits retain keyboard input and masking.
login={window={},button={},edit={},label={}}
local register={window={},button={},edit={},label={}}
local sw,sh=guiGetScreenSize()
local scale=math.min(1,sw/1100,sh/760)
local w,h=980*scale,650*scale
local x,y=(sw-w)/2,(sh-h)/2
local formX=x+550*scale
local formW=390*scale
local active=false
local mode='login'
local errorMessage=''
local pendingUntil=0
local loginped
local languages={{'en','English'},{'lv','Latviešu'},{'ru','Русский'}}
local language=guiCreateComboBox(formX,y+558*scale,formW,130*scale,'English',false)
for _,entry in ipairs(languages) do guiComboBoxAddItem(language,entry[2]) end
guiComboBoxSetSelected(language,0)
guiSetVisible(language,false)
local function label(parent,top,text)
 local e=guiCreateLabel(0,top*scale,formW,22*scale,text,false,parent)
 guiSetFont(e,'default-bold-small');guiLabelSetColor(e,170,179,159)
 return e
end
local function edit(parent,top,masked)
 local e=guiCreateEdit(0,top*scale,formW,40*scale,'',false,parent)
 guiEditSetMaxLength(e,masked and 128 or 64)
 if masked then guiEditSetMasked(e,true) end
 return e
end
local function button(parent,top,text,primary)
 local e=guiCreateButton(0,top*scale,formW,40*scale,text,false,parent)
 guiSetFont(e,'default-bold-small')
 guiSetProperty(e,'NormalTextColour',primary and 'FFF0D2C8' or 'FFB9C2AD')
 return e
end
for _,form in ipairs({login,register}) do
 form.window[1]=guiCreateStaticImage(formX,y+142*scale,formW,400*scale,'empty.png',false)
 guiSetVisible(form.window[1],false)
end
label(login.window[1],0,'ACCOUNT NAME')
login.edit[1]=edit(login.window[1],24,false)
label(login.window[1],80,'PASSWORD')
login.edit[2]=edit(login.window[1],104,true)
login.button[1]=button(login.window[1],168,'ENTER THE WASTELAND',true)
login.button[2]=button(login.window[1],222,'CREATE A SURVIVOR ACCOUNT',false)
label(register.window[1],0,'ACCOUNT NAME')
register.edit[1]=edit(register.window[1],22,false)
label(register.window[1],68,'EMAIL ADDRESS')
register.edit[2]=edit(register.window[1],90,false);guiEditSetMaxLength(register.edit[2],254)
label(register.window[1],136,'PASSWORD')
register.edit[3]=edit(register.window[1],158,true)
label(register.window[1],204,'CONFIRM PASSWORD')
register.edit[4]=edit(register.window[1],226,true)
register.button[1]=button(register.window[1],284,'REGISTER SURVIVOR',true)
register.button[2]=button(register.window[1],334,'BACK TO SIGN IN',false)
local function selectedLanguage()
 local entry=languages[guiComboBoxGetSelected(language)+1]
 return entry and entry[1] or 'en'
end
local function switch(nextMode)
 mode=nextMode;errorMessage=''
 guiSetVisible(login.window[1],active and mode=='login')
 guiSetVisible(register.window[1],active and mode=='register')
end
function seterror(text)
 errorMessage=tostring(text or 'Please try again.');pendingUntil=0
end
local function canSubmit()
 if getTickCount()<pendingUntil then return false end
 return active
end
local function sent()
 pendingUntil=getTickCount()+2000;errorMessage=''
end
function clientSubmitLogin()
 if not canSubmit() then return end
 local username,password=guiGetText(login.edit[1]),guiGetText(login.edit[2])
 if username=='' or password=='' then return seterror('Enter your account name and password.') end
 sent();triggerServerEvent('submitLogin',localPlayer,localPlayer,username,password,selectedLanguage())
end
function clientSubmitRegister()
 if not canSubmit() then return end
 local username,email=guiGetText(register.edit[1]),guiGetText(register.edit[2])
 local password,confirmation=guiGetText(register.edit[3]),guiGetText(register.edit[4])
 if #username<5 then return seterror('Account name must have at least 5 characters.') end
 if not email:match('^[^%s@]+@[^%s@]+%.[^%s@]+$') then return seterror('Enter a valid email address.') end
 if #password<5 then return seterror('Password must have at least 5 characters.') end
 if password~=confirmation then return seterror('The passwords do not match.') end
 sent();triggerServerEvent('submitRegister',localPlayer,localPlayer,username,password,email,selectedLanguage())
end
addEventHandler('onClientGUIClick',resourceRoot,function()
 if source==login.button[1] then clientSubmitLogin()
 elseif source==register.button[1] then clientSubmitRegister()
 elseif source==login.button[2] then switch('register')
 elseif source==register.button[2] then switch('login') end
end)
addEventHandler('onClientGUIAccepted',resourceRoot,function()
 if not active then return end
 if source==login.edit[1] or source==login.edit[2] then clientSubmitLogin()
 elseif source==register.edit[1] or source==register.edit[2] or source==register.edit[3] or source==register.edit[4] then clientSubmitRegister() end
end)
local function rect(px,py,pw,ph,r,g,b,a)
 dxDrawRectangle(x+px*scale,y+py*scale,pw*scale,ph*scale,tocolor(r,g,b,a or 255))
end
local function text(value,px,py,pw,ph,color,size,font,wrap)
 dxDrawText(value,x+px*scale,y+py*scale,x+(px+pw)*scale,y+(py+ph)*scale,color,size*scale,font or 'default','left','top',false,wrap or false)
end
addEventHandler('onClientRender',root,function()
 if not active then return end
 dxDrawRectangle(0,0,sw,sh,tocolor(6,9,7,190))
 rect(0,0,980,650,18,22,18,240)
 rect(0,0,510,650,26,32,24,240)
 rect(0,0,980,4,146,53,41)
 rect(509,28,1,594,91,104,75,120)
 local pale=tocolor(218,225,209);local muted=tocolor(151,163,139)
 text('D A Y Z',42,46,430,90,tocolor(181,66,49),3.5,'pricedown')
 text('SURVIVE  /  SCAVENGE  /  REBUILD',44,137,420,25,muted,1,'default-bold')
 rect(44,188,54,3,146,53,41)
 text('THE WORLD HAS CHANGED.',44,218,410,45,pale,1.55,'default-bold')
 text('Every supply matters. Every sound could be your last.\n\nFind shelter, repair a vehicle and choose who you trust.',44,279,408,125,muted,1.15,'default',true)
 text('SURVIVOR BRIEFING',44,447,420,24,pale,1,'default-bold')
 text('01   Search towns for food and medical supplies.\n02   Stay alert: noise attracts unwanted company.\n03   Keep your equipment ready. Stay alive.',44,485,415,100,muted,1,'default',true)
 text('MTA:SA  /  DAYZ SURVIVAL',44,612,420,22,muted,0.9,'default-bold')
 text(mode=='login' and 'WELCOME BACK' or 'NEW SURVIVOR',550,46,390,34,pale,1.65,'default-bold')
 text(mode=='login' and 'Sign in to continue your story.' or 'Create an account and begin your story.',550,92,390,30,muted,1)
 text('LANGUAGE',550,531,390,22,muted,0.9,'default-bold')
 if errorMessage~='' then
  text(errorMessage,550,608,390,38,tocolor(240,133,113),0.95,'default',true)
 elseif getTickCount()<pendingUntil then
  text('Connecting to the server...',550,608,390,30,muted,0.95)
 else
  text('Your next story starts here.',550,608,390,30,muted,0.95)
 end
end)
local function hide()
 active=false
 guiSetVisible(login.window[1],false);guiSetVisible(register.window[1],false);guiSetVisible(language,false)
 for _,e in ipairs({login.edit[2],register.edit[3],register.edit[4]}) do guiSetText(e,'') end
 if isElement(loginped) then destroyElement(loginped) end
 showCursor(false);showChat(true)
end
function loginSuccess() hide() end
addEvent('seterror',true);addEventHandler('seterror',root,seterror)
addEvent('loginSuccess',true);addEventHandler('loginSuccess',root,loginSuccess)
function lowScreenWarn() end
addEvent('lowScreenWarn',true);addEventHandler('lowScreenWarn',root,lowScreenWarn)
addEventHandler('onClientResourceStart',resourceRoot,function()
 if getElementData(localPlayer,'logedin') then return end
 active=true;switch('login');guiSetVisible(language,true)
 for i,entry in ipairs(languages) do if entry[1]==getElementData(localPlayer,'language') then guiComboBoxSetSelected(language,i-1) end end
 setCameraMatrix(-1440.9035644531,-1506.8837890625,79.716201782227,-1500)
 loginped=createPed(73,-1440,-1503.599609375,79.699996948242,157.994018)
 if isElement(loginped) then setPedAnimation(loginped,'DEALER','DEALER_IDLE') end
 setPlayerHudComponentVisible('radar',false);fadeCamera(true);showChat(false);showCursor(true)
 outputDebugString('[DayZ login] Survival account screen ready.',3)
end)
addEventHandler('onClientResourceStop',resourceRoot,function() if active then hide() end end)
