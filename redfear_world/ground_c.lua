-- Sample native world collision only: floating map props must never become the ground.
addEvent("redfear:measureGround",true)
addEventHandler("redfear:measureGround",resourceRoot,function(id,x,y,z)
 setTimer(function()
  local hit,_,__,height=processLineOfSight(x,y,z+100,x,y,z-100,
   true,false,false,false,false,false,false,false)
  triggerServerEvent("redfear:groundMeasured",resourceRoot,id,hit and height or false)
 end,1500,1)
end)
