local sW,sH = guiGetScreenSize();
local worldW,worldH = 3072/2,3072/2;
local blip = 25;

local rt, worldTexture;
local nextRetry = 0;
local warned = false;
local function ensureGPSMaterials()
    if isElement(rt) and isElement(worldTexture) then return true; end
    if getTickCount() < nextRetry then return false; end
    nextRetry = getTickCount()+5000;
    if not isElement(rt) then rt = dxCreateRenderTarget(180,130); end
    if not isElement(worldTexture) then worldTexture = dxCreateTexture("images/world.jpg","dxt1",false,"clamp"); end
    local ready = isElement(rt) and isElement(worldTexture);
    if not ready and not warned then
        outputDebugString("[DayZ GPS] Could not allocate map graphics; retrying every 5 seconds.",2);
        warned = true;
    elseif ready and warned then
        outputDebugString("[DayZ GPS] Map graphics recovered.",3);warned = false;
    end
    return ready;
end
addEventHandler("onClientRestore",root,function()
    -- The next frame repaints the entire target, including after alt-tab.
    nextRetry = 0;
end);
addEventHandler("onClientResourceStop",resourceRoot,function()
    if isElement(rt) then destroyElement(rt); end
    if isElement(worldTexture) then destroyElement(worldTexture); end
end);

local frameW,frameH = 210,200;
local gpsW,gpsH = 168,120;
local xOffset = 3;

function findRotation(x1,y1,x2,y2)
	local t = -math.deg(math.atan2(x2-x1,y2-y1));
	if (t < 0) then t = t+360 end;
	return t;
end

function getPointFromDistanceRotation(x, y, dist, angle)
	local a = math.rad(90-angle);
	local dx = math.cos(a)*dist;
	local dy = math.sin(a)*dist;
	return x+dx, y+dy;
end

addEventHandler("onClientRender",root,function()
	if (getElementData(localPlayer,"logedin") and (tonumber(getElementData(localPlayer,"toolbelt2")) or 0) >= 1) then
		if exports.e_map:isPlayerMapVisible() then return; end
        if not ensureGPSMaterials() then
            dxDrawText("GPS map loading...",15,sH-frameH+40,210,sH-40,tocolor(220,220,180),1,"default-bold");
            return;
        end
        local mW,mH = dxGetMaterialSize(rt);
		local camX,camY,camZ = getElementRotation(getCamera());
		local playerX,playerY,playerZ = getElementRotation(localPlayer);
		local x,y = getElementPosition(localPlayer);
		local xx,yy = mW/2-(x/(6000/worldW)), mH/2+(y/(6000/worldH));
		local xFactor,yFactor = 15,sH-frameH+23;
		local cX, cY = gpsW/2+xFactor, gpsH/2+yFactor;
        if not dxSetRenderTarget(rt,true) then
            dxSetRenderTarget();dxSetBlendMode("blend");
            if isElement(rt) then destroyElement(rt); end
            rt = nil;nextRetry = 0;
            return;
        end
        dxSetBlendMode("modulate_add");
		dxDrawRectangle(0, 0, mW, mH, 0xFF7CA7D1);
		dxDrawImage(xx-worldW/2,yy-worldH/2+20,worldW,worldH,worldTexture,camZ,(x/(6000/worldW)),-(y/(6000/worldH)));
		--outputChatBox("x: "..(mW/2-(x/3072)).." y: "..(mH/2-(y/3072)))
		dxDrawImage(mW/2-(x/3072)-(blip/2),mH/2-(y/3072)-(blip/2)+20,blip,blip, "images/player.png", camZ-playerZ, 0, 0, tocolor(255, 0, 0, 255));
		dxSetBlendMode("blend");
		dxSetRenderTarget();
		dxDrawImage(xOffset+6+xFactor,yFactor,gpsW,gpsH,rt);
		local toLeft, toTop, toRight, toBottom = cX-gpsW, cY-gpsH, cX+gpsW, cY+gpsH;
		for _,v in ipairs(getElementsByType("player")) do
			local gang = getElementData(localPlayer,"gang") or "None";
			if (gang ~= "None") then
				if (getElementData(v, "gang") == gang and v ~= localPlayer and not getElementData(v, "isDead")) then
					local bx, by = getElementPosition(v);
					local _,_,ppZ = getElementRotation(v);
					local actualDist = getDistanceBetweenPoints2D(x, y, bx, by);
					local maxDist = 600;
					if (actualDist <= maxDist) then
						local dist = actualDist/(6000/((worldW+worldH)/2));
						local rot = findRotation(bx, by, x, y)-camZ;
						local bpx, bpy = getPointFromDistanceRotation(cX, cY, math.min(dist, math.sqrt(toTop^2 + toRight^2)), rot);
						local bpx = math.max(xFactor+3, math.min(xFactor+gpsW, bpx));
						local bpy = math.max(yFactor-17, math.min(yFactor-20+gpsH, bpy));
						--dxDrawImage(bpx-(blip/2+5), bpy, blip+10, blip+10, "images/players.png", 0, 0, 0, tocolor(0, 0, 255, 100));
						dxDrawImage(bpx-(blip/2)+xOffset+6, bpy+5, blip, blip, "images/player.png", camZ-ppZ, 0, 0, tocolor(0, 0, 255, 255));
					end
				end
			end
		end
		dxDrawImage(xOffset,sH-frameH,frameW,frameH,"images/gps.png");
	end
end);