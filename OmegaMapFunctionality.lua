OmegaMapConfig = {
	size = OMEGAMAP_FULLMAP_SIZE,
	opacity = 0,
	scale = OMEGAMAP_DEFAULT_SCALE,
	showScale = false, -- Show Scale slider on map
	showQuestList = false,  --Show Quest Objectives
	clearMap = false,		--Hide all optional POI
	solidify = false,		--Make map able to be clicked
	showCoords = true,		--Show Coords on map
	coordsLocX = 60,
	coordsLocY= 60,
	showAlpha = true,		--Show transparency slider
	alphaLocX = 60,
	alphaLocY = 175,
--OmegaMap Option Menu Settings
	showExteriors = true,	--Show dungeon exteriros when available
	showBattlegrounds = true,	--Show alt battleground maps when available
	showAltMapNotes = true,		--Show notes on Exteriors & alt battlegrounds
	interactiveHotKey = "None",	--Hotkey for making the map interactive
	keepInteractive = false, -- Keeps map interactive between viewings
	escapeClose = true, --Closes OmegaMap on Escape key press,
	showMiniMapIcon = true,
	showHotSpot = false,
	showCompactMode = false,
--Plugin Settings
	showGatherer = false,	--Show gathering POI
	showTomTom = false,		--Show Tomtom poi
	showRoutes = false,		--Show Routes
	showCTMap = false,		--Show CT Map
	showMapNotes = false,	--Show MapNotes
	showGatherMate = false,	--Show Gathermate POI
	showNPCScanOverlay = false,  --Show NPCScan.Overlay
	showQuestHelperLite = false,
	showHandyNotes = false,
	hotSpotLock = false,
--MiniMap button Settings
	MMDB = { hide = false,
			--minimap = {},
		},
};
--Position and scal for Standard and BG Views
OmegaMapPosition = {
	["Map"] = {
		["xOffset"] = 0,
		["yOffset"] = 0,
		["point"] = "Center",
		["relativePoint"] = "Center",
		["scale"] = OMEGAMAP_DEFAULT_SCALE, 
	},
	["BG"] = {
		["xOffset"] = 0,
		["yOffset"] = 0,
		["point"] = "Center",
		["relativePoint"] = "Center",
		["scale"] = OMEGAMAP_DEFAULT_SCALE, 
	},
	["LastType"] = nil,
}

OMCompactWorldMap = {
	["Errata"] = {},  -- any differences from the base dataset are recorded here.
	Enabled = 1,  
	colorStyle = 02,
	transparency = 1.0,
	["colorArray"] = {
		["b"] = 0.6313725490196078,
		["g"] = 0.5254901960784314,
		["r"] = 0.5254901960784314,},
}


function OmegaMapFrame_ChangeOpacity()
	OmegaMapConfig.opacity = OmegaMapSliderFrame:GetValue();
	OmegaMapFrame_SetOpacity(OmegaMapConfig.opacity);
end

--Sets the opacity of the various parts of themap
function OmegaMapFrame_SetOpacity(opacity)
	local alpha;
	-- set border alphas
	alpha = 0.5 + (1.0 - opacity) * 0.50;
	OmegaMapFrameCloseButton:SetAlpha(alpha);

	alpha = 0.2 + (1.0 - opacity) * 0.50;
	--OmegaMapPOIFrame:SetAlpha(alpha);

	-- set map alpha
	--alpha = 0.35 + (1.0 - opacity) * 0.65;
	alpha = (1.0 - opacity);
	OmegaMapFrame.ScrollContainer:SetAlpha(alpha);
	--OmegaMapButton.AzerothHighlight:SetAlpha(alpha);
	--OmegaMapButton.DraenorHighlight:SetAlpha(alpha);
	--OmegaMapButton.OutlandHighlight:SetAlpha(alpha);
	if OmegaMapAltMapFrame then
		--OmegaMapAltMapFrame:SetAlpha(alpha);
	end

	-- set blob alpha
	alpha = 0.65 + (1.0 - opacity) * 0.55;
	--OmegaMapPOIFrame:SetAlpha(alpha);
	--OmegaMapBlobFrame:SetFillAlpha(128 * alpha);
	--OmegaMapBlobFrame:SetBorderAlpha(192 * alpha);
	--OmegaMapArchaeologyDigSites:SetFillAlpha(128 * alpha);
	--OmegaMapArchaeologyDigSites:SetBorderAlpha(192 * alpha);
	--OmegaMapBossButtonFrame:SetAlpha(alpha);
end

--Converts standard map cords to relative altmap cords
function OmegaMapOffsetAltMapCoords(pX, pY,...)
	if not OMEGAMAP_ALTMAP or (pX == 0 and pY == 0 ) then return pX,pY,... end

	local negX, negY = nil, nil;
	local wmDimension, wmOffset, relativeOffset, amDimension, amOffset;
	local wmData = OMEGAMAP_ALTMAP.wmData
	local omData = OMEGAMAP_ALTMAP.omData
	if ( pX < 0 ) then
		negX = true;
		pX = -(pX);
	end

	if ( pY < 0 ) then
		negY = true;
		pY = -(pY);
	end

	if ( pX < wmData.minX ) then
		pX = omData.minX;
	elseif ( pX > wmData.maxX ) then
		pX = omData.maxX;
	else
		wmDimension = wmData.maxX - wmData.minX;
		wmOffset = pX - wmData.minX;
		relativeOffset = wmOffset/wmDimension;
		amDimension = omData.maxX - omData.minX;
		amOffset = amDimension * relativeOffset;
		pX = omData.minX + amOffset;
	end

	if ( pY < wmData.minY ) then
		pY = omData.minY;
		elseif ( pY > wmData.maxY ) then
		pY = omData.maxY;
	else
		local wmDimension = wmData.maxY - wmData.minY;
		local wmOffset = pY - wmData.minY;
		local relativeOffset = wmOffset/wmDimension;
		local amDimension = omData.maxY - omData.minY;
		local amOffset = amDimension * relativeOffset;
		pY = omData.minY + amOffset;
	end

	if ( negX ) then
		pX = -(pX);
	end
	if ( negY ) then
		pY = -(pY);
	end
	return pX , pY,...;
end

--Solidifies Map to allow clicks & movement
function OmegaMapSolidify(state)
	if  (state == "Off")then
		--OmegaMapButton:EnableMouse(false);
		--OmegaMapScrollFrame:EnableMouseWheel(false);
		--OmegaMapMovementFrameTop:Hide();
		--OmegaMapMovementFrameTop:EnableMouse(false)
		--OmegaMapMovementFrameBottom:Hide();
		--OmegaMapMovementFrameBottom:EnableMouse(false)
	elseif (state == "On") then
		--OmegaMapButton:EnableMouse(true);
		--OmegaMapScrollFrame:EnableMouseWheel(true)
		--OmegaMapConfig.solidify = true
		--OmegaMapMovementFrameTop:Show();
		--OmegaMapMovementFrameTop:EnableMouse(true)
		--OmegaMapMovementFrameBottom:Show();
		--OmegaMapMovementFrameBottom:EnableMouse(true)
	end
end

function OmegaMapCoordsOnUpdate(self, elapsed)
	if ( not self.isMoving ) then
		if ( not self.timer ) then
			self.timer = 0;
		end

		self.timer = self.timer + elapsed;

		if ( self.timer > 0.1 ) then
			self.timer = 0;
			local cX, cY, cLoc = nil, nil, nil;
			local pX, pY = 0,0 --GetPlayerMapPosition("player");
			if pX == nil then return end
			local fmtng = "%d, %d";

			local pLoc = OM_GREEN..(format( fmtng, pX * 100.0, pY * 100.0)).."|r\n";
			if ( OmegaMapFrame:IsVisible() ) then
				cX, cY = OmegaMapGetCLoc(OmegaMapFrame);
			else
				cX, cY = OmegaMapGetCLoc(OmegaMapFrame);
			end
			if ( ( cX ) and ( cY ) ) then
				cLoc = OM_YELLOW..( format( fmtng, cX, cY ) ).."|r";
			end
			OmegaMapLocationText:SetText( pLoc .. (cLoc or "") );

			OmegaMapCoordinates:SetWidth( OmegaMapLocationText:GetWidth() + 9 );
			if ( cLoc ) then
				OmegaMapCoordinates:SetHeight(48);
			else
				OmegaMapCoordinates:SetHeight(30);
			end
		end
	end
end

--Gets coords of cursor in relation to its positon over the map
function OmegaMapGetCLoc()
	local x, y = nil, nil;
	local activeFrame = nil

	--if (OmegaMapAltMapFrame:IsShown()) then
		--activeFrame = OmegaMapAltMapFrame
	--else 
		--activeFrame = OmegaMapDetailFrame
	--end

	local x, y = GetCursorPosition()
	local left, top = activeFrame:GetLeft(), activeFrame:GetTop()
	local width = activeFrame:GetWidth()
	local height = activeFrame:GetHeight()
	local scale = activeFrame:GetEffectiveScale()
	local cx = (x/scale - left) / width
	local cy = (top - y/scale) / height

	if cx < 0 or cx > 1 or cy < 0 or cy > 1 then
		return nil, nil
	end

	return cx*100.000, cy*100.000;
end

--Solidifies the map is hot key is held
function OmegaMapSolidifyCheck(self,...)
	if (not OmegaMapButton:IsVisible()) then return end

	if (OmegaMapConfig.interactiveHotKey == nil) then return end

	local key, state = ...
	if string.match(key, string.upper(OmegaMapConfig.interactiveHotKey)) then
		if state==1 then
			OmegaMapSolidify("On")
			OmegaMapConfig.solidify = true
			OmegaMapLockButton:SetNormalTexture("Interface\\Buttons\\UI-MICROBUTTON-World-Up")
		elseif state==0 then
			if (OmegaMapConfig.keepInteractive) then
				return
			else
				OmegaMapLockButton:SetNormalTexture("Interface\\Buttons\\UI-MICROBUTTON-World-Disabled")
				OmegaMapSolidify("Off")
				OmegaMapConfig.solidify = false
			end
		end
	end
end

--Only shows the explored areas of the map in a compact view. 
function OmegaMapCompactView()
	local zone = GetCurrentMapZone()
	local overlay = GetNumMapOverlays()
	local curMapId = GetCurrentMapAreaID()
	local curZoneName = GetMapInfo()
	local broken = false
	local shown = true
	local _, _, _, isSubzone = GetMapInfo();
	local compact = GetMapOverlayInfo(1)

	--if MozzFullWorldMap and not MozzFullWorldMap.Enabled then shown = false end

	--fix to display map on isele of thunder king
	if curZoneName == "IsleoftheThunderKing" then
		for i=1, GetNumberOfDetailTiles(), 1 do
			_G["OmegaMapDetailTile"..i]:Show();
		end
		return
	end
	
	if (zone ~=0  and isSubzone == false and shown and compact) and OmegaMapConfig.showCompactMode then 
 		for i=1, GetNumberOfDetailTiles(), 1 do
			_G["OmegaMapDetailTile"..i]:Hide();
		end
	else --if zone ==0  or overlay ==0  or not OmegaMapConfig.showCompactMode then 
		for i=1, GetNumberOfDetailTiles(), 1 do
			_G["OmegaMapDetailTile"..i]:Show();
		end
	end
end