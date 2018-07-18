local Addon_Name, private = ...

local OmegaMap = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("OmegaMap")
local Config = OmegaMap.Config
OmegaMap = LibStub("AceAddon-3.0"):NewAddon(Addon_Name, "AceConsole-3.0")

NUM_OMEGAMAP_POI_COLUMNS = 14;
OMEGAMAP_POI_TEXTURE_WIDTH = 256;


NUM_OMEGAMAP_POIS = 0;
NUM_OMEGAMAP_WORLDEFFECT_POIS = 0;
NUM_OMEGAMAP_SCENARIO_POIS = 0;
NUM_OMEGAMAP_TASK_POIS = 0;
NUM_OMEGAMAP_GRAVEYARDS = 0;
NUM_OMEGAMAP_OVERLAYS = 0;
NUM_OMEGAMAP_FLAGS = 4;

local OMEGAMAP_DEFAULT_SCALE = .75;


--QUESTFRAME_MINHEIGHT = 34;
--QUESTFRAME_PADDING = 19;			-- needs to be one the highest frames in the MEDIUM strata
OMEGAMAP_FULLMAP_SIZE = 1.0;
OMEGAMAP_POI_FRAMELEVEL = 100;	-- needs to be one the highest frames in the MEDIUM strata

OMEGAMAP_ALTMAP = false
OMEGAMAP_QUEST_BONUS_OBJECTIVE = 49;

local function CheckPlugin(Name)
	return not IsAddOnLoaded(Name)
end

local function ToggleFrame(frame, value)
		if value then
			frame:Show()
		else
			frame:Hide()
		end

end

--ACE3 Options Constuctor
local options = {
	name = "OmegaMap",
	handler = OmegaMap,
	type = 'group',
	childGroups = "tab",
	inline = true,
	args = {
		settings={
			name = "Options",
			type = "group",
			--inline = true,
			order = 0,
			args={
				Options_Header = {
					order = 0,
					name = "OM",
					type = "header",
					width = "full",
				},
				showCoords = {
					order = 1,
					name = L["OMEGAMAP_OPTIONS_COORDS"] ,
					desc = L["OMEGAMAP_OPTIONS_COORDS_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showCoords = val end,
					get = function(info) return Config.showCoords end,
					width = 1.5,
				},
				showAlpha = {
					order = 2,
					name = L["OMEGAMAP_OPTIONS_ALPHA"] ,
					desc = L["OMEGAMAP_OPTIONS_ALPHA_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showAlpha = val; ToggleFrame(OmegaMapSliderFrame, val) end,
					get = function(info) return Config.showAlpha end,
					width = 1.5,
				},
				showExteriors = {
					order = 3,
					name = L["OMEGAMAP_OPTIONS_ALTMAP"] ,
					desc = L["OMEGAMAP_OPTIONS_ALTMAP_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showExteriors = val end,
					get = function(info) return Config.showExteriors end,
					width = 1.5,
					disabled = true,
				},
				showBattlegrounds = {
					order = 4,
					name = L["OMEGAMAP_OPTIONS_BG"] ,
					desc = L["OMEGAMAP_OPTIONS_BG_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showBattlegrounds = val end,
					get = function(info) return Config.showBattlegrounds end,
					width = 1.5,
					disabled = true,
				},
				escapeClose = {
					order = 5,
					name = L["OMEGAMAP_OPTIONS_ESCAPECLOSE"] ,
					desc = L["OMEGAMAP_OPTIONS_ESCAPECLOSE_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.escapeClose = val end,
					get = function(info) return Config.escapeClose end,
					width = 1.5,
				},
				showMiniMapIcon = {
					order = 6,
					name = L["OMEGAMAP_OPTIONS_MINIMAP"] ,
					desc = L["OMEGAMAP_OPTIONS_MINIMAP_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showMiniMapIcon = val end,
					get = function(info) return Config.showMiniMapIcon end,
					width = 1.5,
				},
				showHotSpot = {
					order = 7,
					name = L["OMEGAMAP_OPTIONS_HOTSPOT"] ,
					desc = L["OMEGAMAP_OPTIONS_HOTSPOT_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showHotSpot = val end,
					get = function(info) return Config.showHotSpot end,
					width = 1.5,
				},
				showCompactMode = {
					order = 8,
					name = L["OMEGAMAP_OPTIONS_COMPACT"] ,
					desc = L["OMEGAMAP_OPTIONS_COMPACT_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showCompactMode = val end,
					get = function(info) return Config.showCompactMode end,
					width = 1.5,
					disabled = true,
				},
				keepInteractive = {
					order = 9,
					name = L["OMEGAMAP_OPTIONS_INTERACTIVE"] ,
					desc = L["OMEGAMAP_OPTIONS_INTERACTIVE_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.keepInteractive = val end,
					get = function(info) return Config.keepInteractive end,
					width = 1.5,
				},
				interactiveHotKey = {
					order = 10,
					name = "Select Map Interaction Hotkey",
					desc = nil,
					type = "select",
					set = function(info,val) Config.interactiveHotKey = val end,
					get = function(info) return Config.interactiveHotKey end,
					width = 1.5,
					values = {["None"] = "None", ["Shift"] = "Shift", ["Ctrl"] = "Ctrl", ["Alt"] = "Alt"}
				},
				showScale = {
					order = 11,
					name = L["OMEGAMAP_OPTIONS_SCALESLIDER"] ,
					desc = L["OMEGAMAP_OPTIONS_SCALESLIDER_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showScale = val; ToggleFrame(OmegaMapZoomSliderFrame, val) end,
					get = function(info) return Config.showScale end,
					width = 1.5,
				},
				scale = {
					order = 12,
					name = L["OMEGAMAP_OPTIONS_SCALE"],
					desc = L["OMEGAMAP_OPTIONS_SCALE_TOOLTIP"],
					type = "select",
					type = "range",
					set = function(info,val) Config.scale = val/100; OmegaMapFrame:SetScale( Config.scale ); OmegaMapZoomSliderFrame:SetValue(Config.scale); end,
					get = function(info) return Config.scale*100 end,
					width = "double",
					min = 1,
					max = 125,
					step = 1,
				},
				plugins_Header = {
					order = 13,
					name = "Plugins",
					type = "header",
					width = "full",
				},
				gathermate = {
					order = 14,
					name = L["OMEGAMAP_OPTIONS_GATHERMATE"] ,
					desc = L["OMEGAMAP_OPTIONS_GATHERMATE_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showGatherMate = val end,
					get = function(info) return Config.showGatherMate end,
					width = 1.5,
					disabled = CheckPlugin("GatherMate2")
				},
				gatherer = {
					order = 15,
					name = L["OMEGAMAP_OPTIONS_GATHERER"] ,
					desc = L["OMEGAMAP_OPTIONS_GATHERER_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showGatherer = val end,
					get = function(info) return Config.showGatherer end,
					width = 1.5,
					disabled = CheckPlugin("Gatherer")
				},
				routes = {
					order = 16,
					name = L["OMEGAMAP_OPTIONS_ROUTES"] ,
					desc = L["OMEGAMAP_OPTIONS_ROUTES_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showRoutes = val end,
					get = function(info) return Config.showRoutes end,
					width = 1.5,
					disabled = CheckPlugin("Routes")
				},
				tomtom = {
					order = 17,
					name = L["OMEGAMAP_OPTIONS_TOMTOM"] ,
					desc = L["OMEGAMAP_OPTIONS_TOMTOM_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showTomTom = val end,
					get = function(info) return Config.showTomTom end,
					width = 1.5,
					disabled = CheckPlugin("TomTom")
				},
				ctmap = {
					order = 18,
					name = L["OMEGAMAP_OPTIONS_CTMAP"] ,
					desc = L["OMEGAMAP_OPTIONS_CTMAP_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showCTMap = val end,
					get = function(info) return Config.showCTMap end,
					width = 1.5,
					disabled = CheckPlugin("CT_MapMod")
				},
				mapnotes = {
					order = 19,
					name = L["OMEGAMAP_OPTIONS_MAPNOTES"] ,
					desc = L["OMEGAMAP_OPTIONS_MAPNOTES_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showMapNotes = val end,
					get = function(info) return Config.showMapNotes end,
					width = 1.5,
					disabled = CheckPlugin("MapNotes")
				},
				questhelper = {
					order = 20,
					name = L["OMEGAMAP_OPTIONS_QUESTHELPERLITE"] ,
					desc = L["OMEGAMAP_OPTIONS_QUESTHELPERLITE_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showQuestHelperLite = val end,
					get = function(info) return Config.showQuestHelperLite end,
					width = 1.5,
					disabled = CheckPlugin("QuestHelperLite")
				},
				handynotes = {
					order = 21,
					name = L["OMEGAMAP_OPTIONS_HANDYNOTES"] ,
					desc = L["OMEGAMAP_OPTIONS_HANDYNOTES_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showHandyNotes = val end,
					get = function(info) return Config.showHandyNotes end,
					width = 1.5,
					disabled = CheckPlugin("HandyNotes")
				},






			},
		},
	},
}






local defaults = {
	profile ={
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
	}
};

OmegaMap_Config = defaults.profile

function OmegaMap:OnInitialize()
  -- Code that you want to run when the addon is first loaded goes here.
	self.db = LibStub("AceDB-3.0"):New("OmegaMapConfig", defaults, true)
	OmegaMap.Config  = self.db.profile
	OmegaMap_Config = self.db.profile
	Config = OmegaMap.Config

	LibStub("AceConfigRegistry-3.0"):ValidateOptionsTable(options, "OmegaMap")
	LibStub("AceConfig-3.0"):RegisterOptionsTable("OmegaMap", options)

	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("OmegaMap", "OmegaMap")

	OmegaMapSliderFrame:SetValue(OmegaMap.Config.opacity);
	--OmegaMapQuestShowObjectives_Toggle();
	OmegaMapFrame:SetScale(OmegaMap.Config.scale);
	--OmegaMapOptionsFrame_init();
	--OmegaMapSetEscPress()
	--OmegaMapMiniMap_Register()
	--OmegaMapHotSpotToggle()
	ToggleFrame(OmegaMapSliderFrame, OmegaMap.Config.showAlpha)
	ToggleFrame(OmegaMapZoomSliderFrame, OmegaMap.Config.showScale)
	--ToggleFrame(OmegaMapCoordinates, OmegaMapConfig.showCoords)
	--ToggleFrame(OmegaMapNoteFrame, OmegaMapConfig.clearMap)




end

function OmegaMapSetEscPress()
	--Register to close on ESC
	if(OmegaMapConfig.escapeClose) then
		tinsert(UISpecialFrames, "OmegaMapFrame");
	else
		for id=1, getn(UISpecialFrames), 1 do
			if ( UISpecialFrames[id] == "OmegaMapFrame" ) then
				tremove(UISpecialFrames, id)
				end
			end
	end
end



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
	OmegaMap_Config.opacity = OmegaMapSliderFrame:GetValue();
	OmegaMapFrame_SetOpacity(OmegaMap_Config.opacity);
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
		--OmegaMap.Config.solidify = true
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

	if (OmegaMap.Config.interactiveHotKey == nil) then return end

	local key, state = ...
	if string.match(key, string.upper(OmegaMap.Config.interactiveHotKey)) then
		if state==1 then
			OmegaMapSolidify("On")
			OmegaMap.Config.solidify = true
			OmegaMapLockButton:SetNormalTexture("Interface\\Buttons\\UI-MICROBUTTON-World-Up")
		elseif state==0 then
			if (OmegaMap.Config.keepInteractive) then
				return
			else
				OmegaMapLockButton:SetNormalTexture("Interface\\Buttons\\UI-MICROBUTTON-World-Disabled")
				OmegaMapSolidify("Off")
				OmegaMap.Config.solidify = false
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
	
	if (zone ~=0  and isSubzone == false and shown and compact) and OmegaMap.Config.showCompactMode then 
 		for i=1, GetNumberOfDetailTiles(), 1 do
			_G["OmegaMapDetailTile"..i]:Hide();
		end
	else --if zone ==0  or overlay ==0  or not OmegaMap.Config.showCompactMode then 
		for i=1, GetNumberOfDetailTiles(), 1 do
			_G["OmegaMapDetailTile"..i]:Show();
		end
	end
end

function OmegaMapFrame_OnEvent(self, event, ...)
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		if ( self:IsShown() ) then
			HideUIPanel(OmegaMapFrame);
		end
		
	elseif ( event == "WORLD_MAP_UPDATE" or event == "REQUEST_CEMETERY_LIST_RESPONSE" or event == "QUESTLINE_UPDATE" or event == "MINIMAP_UPDATE_TRACKING" ) then
		local mapID = GetCurrentMapAreaID();
		local dungeonLevel = GetCurrentMapDungeonLevel();
		if ( not self.blockOmegaMapUpdate and self:IsShown() ) then
			-- if we are exiting a micro dungeon we should update the world map
			if (event == "REQUEST_CEMETERY_LIST_RESPONSE") then
				local _, _, _, isMicroDungeon = GetMapInfo();
				if (isMicroDungeon) then
					SetMapToCurrentZone();
				end
			end
			OmegaMapFrame_UpdateMap(mapID == self.mapID and dungeonLevel == self.dungeonLevel);
		end
		--New
		if ( event == "WORLD_MAP_UPDATE" ) then
			if ( self:IsShown() ) then
				if ( mapID ~= self.mapID) then
					self.mapID = mapID;
					if OmegaMap_DoesCurrentMapHideMapIcons() then
						OmegaMapUnitPositionFrame:Hide();
					else
						OmegaMapUnitPositionFrame:Show();
						OmegaMapUnitPositionFrame:StartPlayerPing(2, .25);
					end
				end
				self.dungeonLevel = dungeonLevel;
			end
			--New 6.0 Revisit
			if ( OmegaMapQuestFrame.DetailsFrame.questMapID and OmegaMapQuestFrame.DetailsFrame.questMapID ~= GetCurrentMapAreaID() ) then
				OmegaMapQuestFrame_CloseQuestDetails(self);
			else
				OmegaMapQuestFrame_UpdateAll();
			end
			if ( OmegaMapScrollFrame.zoomedIn ) then
				if ( OmegaMapScrollFrame.continent ~= GetCurrentMapContinent() or OmegaMapScrollFrame.mapID ~= GetCurrentMapAreaID() ) then
					OmegaMapScrollFrame_ResetZoom();
				end
			end
		end
	elseif ( event == "RESEARCH_ARTIFACT_DIG_SITE_UPDATED" ) then --New
		if ( self:IsShown() ) then
			RefreshWorldMap();
		end
	elseif ( event == "CLOSE_WORLD_MAP" ) then
		HideUIPanel(self);
	elseif ( event == "VARIABLES_LOADED" ) then
		--OmegaMapZoneMinimapDropDown_Update();
		--WORLDMAP_SETTINGS.locked = GetCVarBool("lockedOmegaMap");
		--WORLDMAP_SETTINGS.opacity = (tonumber(GetCVar("worldMapOpacity")));
		--OmegaMapQuestShowObjectives:SetChecked(GetCVarBool("questPOI"));

		OmegaMapSliderFrame:SetValue(OmegaMap.Config.opacity);
		--OmegaMapQuestShowObjectives_Toggle();
		OmegaMapMasterFrame:SetScale(OmegaMap.Config.scale);
		OmegaMapOptionsFrame_init();
		OmegaMapSetEscPress()
		OmegaMapMiniMap_Register()
		OmegaMapHotSpotToggle()
	
	elseif ( event == "UNIT_PORTRAIT_UPDATE" ) then
		OmegaMapJournal_UpdateMapButtonPortraits();
	--new 6.0
	elseif ( event == "SUPER_TRACKED_QUEST_CHANGED" ) then
		local questID = ...;
		local mapID, floorNumber = GetQuestWorldMapAreaID(questID);
		if ( mapID ~= 0 ) then
			SetMapByID(mapID, floorNumber);
			if ( floorNumber ~= 0 ) then
				SetDungeonMapLevel(floorNumber);
			end
		end
		OmegaMapFrame_SetBonusObjectivesDirty();
		OmegaMapQuestFrame_CloseQuestDetails(self);
		OmegaMapPOIFrame_SelectPOI(questID);
	elseif ( event == "PLAYER_STARTED_MOVING" ) then
		if ( GetCVarBool("mapFade") ) then
			OmegaMapFrame_AnimAlphaOut(self, true);
			OmegaMapFrame.fadeOut = true;
		end
	elseif ( event == "PLAYER_STOPPED_MOVING" ) then
		OmegaMapFrame_AnimAlphaIn(self, true);
		OmegaMapFrame.fadeOut = false;
	elseif ( event == "QUEST_LOG_UPDATE" and OmegaMapFrame:IsVisible() ) then
		if OmegaMapFrame:IsVisible() then
			OmegaMap_UpdateQuestBonusObjectives();
			OmegaMapFrame_UpdateOverlayLocations();
		end;
	elseif ( event == "WORLD_QUEST_COMPLETED_BY_SPELL" ) then
		if OmegaMapFrame:IsVisible() then
			OmegaMapFrame_SetBonusObjectivesDirty();
		end
	elseif ( event == "MODIFIER_STATE_CHANGED" ) then
		OmegaMapSolidifyCheck(self,...)
	end
end