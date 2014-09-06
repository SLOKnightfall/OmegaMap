--	///////////////////////////////////////////////////////////////////////////////////////////
--
--	OmegaMap	V1.3
--	Author: Gathirer

--	OmegaMap: A worldmap frame that is transparent and allows character manipulation
--
--	Contributions: Part of the code for this is adapted from the WorldMapFrame.lua(v5.0.4 r16016)
--		of the original Blizzard(tm) Entertainment distribution.  OmegaMap is bassed off of the AlphaMap addon
--		which I used from Vanilla WOW untill it stoped being maintined/updated during Cataclysm.
--
--	3rd Party Components: Part of the code is taken from MapNotes, Gatherer, Gathermate2, CTMapMod, TomTom, Routes, \
--		_NPCScan.Overlay.  This is done to provide optional support for those addons.
--
--	Special Thanks: Special thanks to Jeremy Walsh, Telic, Alchemys Indomane,  Kesitah, AnonDev, dalewake and all others
--		who maintained AlphaMap over the years.  Without their efforts there would have been no inspiration for OmegaMap
--
--	License: You are hereby authorized to freely modify and/or distribute all files of this add-on, in whole or in part,
--		providing that this header stays intact, and that you do not claim ownership of this Add-on.
--
--		Additionally, the original owner wishes to be notified by email if you make any improvements to this add-on.
--		Any positive alterations will be added to a future release, and any contributing authors will be
--		identified in the section above.
--
--	SEE CHANGELOG.TXT FOR LATEST PATCH NOTES
--
--	///////////////////////////////////////////////////////////////////////////////////////////


--OmegaMap = LibStub("AceAddon-3.0"):NewAddon("OmegaMap","AceConsole-3.0","AceEvent-3.0")
LoadAddOn("Blizzard_EncounterJournal") --preloads Blizzard's Encounter Journal so it can be opened from Omega Map without errors
--Fix for astrolabe problems
local LibStub = _G.LibStub
--local OM_Fader = LibStub("LibFrameFade-1.0")


NUM_OMEGAMAP_POIS = 0;
NUM_OMEGAMAP_GRAVEYARDS = 0;
NUM_OMEGAMAP_POI_COLUMNS = 14;
OMEGAMAP_POI_TEXTURE_WIDTH = 256;
NUM_OMEGAMAP_OVERLAYS = 0;
NUM_OMEGAMAP_FLAGS = 4;
--QUESTFRAME_MINHEIGHT = 34;
--QUESTFRAME_PADDING = 19;			-- needs to be one the highest frames in the MEDIUM strata
OMEGAMAP_FULLMAP_SIZE = 1.0;
OMEGAMAP_POI_FRAMELEVEL = 100;	-- needs to be one the highest frames in the MEDIUM strata

OMEGAMAP_ALTMAP = false

local EJ_QUEST_POI_MINDIS_SQR = 2500;
local OMEGAMAP_DEFAULT_SCALE = .75;
local OMEGAMAP_POI_MIN_X = 12;
local OMEGAMAP_POI_MIN_Y = -12;
local OMEGAMAP_POI_MAX_X;		-- changes based on current scale, see OmegaMapFrame_SetPOIMaxBounds
local OMEGAMAP_POI_MAX_Y;		-- changes based on current scale, see OmegaMapFrame_SetPOIMaxBounds
local PLAYER_ARROW_SIZE_WINDOW = 40;
local PLAYER_ARROW_SIZE_FULL_WITH_QUESTS = 38;
local PLAYER_ARROW_SIZE_FULL_NO_QUESTS = 28;


local Update_Timer_P = 0;
local Main_Update_Timer = 0;
local incombat = false
--local playercombatclose = false

OmegaMapPins = {}
OMEGAMAP_VEHICLES = {};

OmegaMapConfig = {
	size = OMEGAMAP_FULLMAP_SIZE,
	opacity = 0,
	scale = OMEGAMAP_DEFAULT_SCALE,
	showScale = false, -- Show Scale slider on map
	showQuest = false,  --Show Quest Objectives
	showArch = false,	--Show Arch dig sites
	showBoss = false,	--Show EJ Boss Icons
	showObjectives = false,	--Hide quest objectives
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
--[[
--Hooking SetMapToCurrentZone to prevent other addons from calling it if OmegaMap is shown.
OrgSetMapToCurrentZone = SetMapToCurrentZone;
SetMapToCurrentZone= function(...)
	if OmegaMapFrame:IsVisible() then return end
		OrgSetMapToCurrentZone();
	
	print("Hook Block")
end
--]]
local WorldEffectPOITooltips = {};
local ScenarioPOITooltips = {};

local OmegaMapConfigDefaults = OmegaMapConfig
function omegareset()
	OmegaMapConfig = OmegaMapConfigDefaults
end

function OmegaMapFrame_OnLoad(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("WORLD_MAP_UPDATE");
	self:RegisterEvent("CLOSE_WORLD_MAP");
	self:RegisterEvent("VARIABLES_LOADED");
	self:RegisterEvent("GROUP_ROSTER_UPDATE"); --New
	self:RegisterEvent("DISPLAY_SIZE_CHANGED");
	self:RegisterEvent("QUEST_LOG_UPDATE");
	self:RegisterEvent("QUEST_POI_UPDATE");
	self:RegisterEvent("SKILL_LINES_CHANGED");
	self:RegisterEvent("REQUEST_CEMETERY_LIST_RESPONSE");
	self:RegisterEvent("UNIT_PORTRAIT_UPDATE");
	self:RegisterEvent("ARTIFACT_DIG_SITE_UPDATED"); --New
	-- added events
	self:RegisterEvent("MODIFIER_STATE_CHANGED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")

	self:SetClampRectInsets(0, 0, 0, -60);				-- don't overlap the xp/rep bars
	self.poiHighlight = nil;
	self.areaName = nil;
	--CreateWorldMapArrowFrame(OmegaMapFrame);
	--WorldMapFrameTexture18:SetVertexColor(0, 0, 0);		-- this texture just needs to be a black line
	--InitWorldMapPing(OmegaMapFrame);
	OmegaMapFrame_Update();

	-- setup the zone minimap button
	OmegaMapLevelDropDown_Update();

	-- PlayerArrowEffectFrame is created in code: COmegaMap::CreateArrowFrame()
	--PlayerArrowEffectFrame:SetAlpha(0.65);

	-- font stuff for objectives text
	local refFrame = OmegaMapFrame_GetQuestFrame(0);
	local _, fontHeight = refFrame.objectives:GetFont();
	refFrame.lineSpacing = refFrame.objectives:GetSpacing();
	refFrame.lineHeight = fontHeight + refFrame.lineSpacing;
	
	OmegaMapFrame_ResetFrameLevels();
	OmegaMapDetailFrame:SetScale(OMEGAMAP_FULLMAP_SIZE);
	OmegaMapButton:SetScale(OMEGAMAP_FULLMAP_SIZE);
	OmegaMapFrame_SetPOIMaxBounds();
	--OmegaMapQuestDetailScrollChildFrame:SetScale(0.9);
	--OmegaMapQuestRewardScrollChildFrame:SetScale(0.9);
	OmegaMapFrame.numQuests = 0;
	if (GetCVarBool("questPOI") > 0) then
		WatchFrame.showObjectives = true;
	else
		WatchFrame.showObjectives = false;
	end
	OmegaMapPOIFrame.allowBlobTooltip = true;
	-- scrollframes
	--OmegaMapQuestDetailScrollFrame.scrollBarHideable = true;
	--OmegaMapQuestRewardScrollFrame.scrollBarHideable = true;
	--ScrollBar_AdjustAnchors(OmegaMapQuestDetailScrollFrameScrollBar, 1, -2);
	--OmegaMapQuestDetailScrollFrameScrollBarTrack:SetAlpha(0.4);
	--ScrollBar_AdjustAnchors(OmegaMapQuestRewardScrollFrameScrollBar, 1, -2);
	--OmegaMapQuestRewardScrollFrameScrollBarTrack:SetAlpha(0.4);

--Disable Mouse interaction with the map
	OmegaMapButton:EnableMouse(false); --set to false to enable click trhough

	print(OMEGAMAP_LOADED_MESSAGE)
	--Registers OmegaMap with Astrolabe if present
	if WorldMapDisplayFrames  then
		local AstrolabeMapMonitor = DongleStub("AstrolabeMapMonitor");
		AstrolabeMapMonitor:MonitorWorldMap( OmegaMapFrame )
	end
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

function OmegaMapFrame_OnShow(self)
	SetupFullscreenScale(self);
	OmegaMap_LoadTextures();
	-- pet battle level size adjustment
		WorldMapFrameAreaPetLevels:SetFontObject("SubZoneTextFont");
		--if ( not WatchFrame.showObjectives and WORLDMAP_SETTINGS.size ~= WORLDMAP_FULLMAP_SIZE ) then
		OmegaMapFrame_SetFullMapView();
		--end		
		
	--UpdateMicroButtons();

	if (not OmegaMapFrame.toggling) then
		SetMapToCurrentZone();
	else
		OmegaMapFrame.toggling = false;
	end
	PlaySound("igQuestLogOpen");
	CloseDropDownMenus();
	--OmegaMapFrame_PingPlayerPosition();	
	OmegaMapFrame_UpdateUnits("OmegaMapRaid", "OmegaMapParty");
	DoEmote("READ", nil, true);
	OmegaMapFrame_Update();

	if(OmegaMapConfig.showAlpha) then
		OmegaMapSliderFrame:Show()
	else
		OmegaMapSliderFrame:Hide()
	end
	if(OmegaMapConfig.showScale) then
		OmegaMapZoomSliderFrame:Show()
	else
		OmegaMapZoomSliderFrame:Hide()
	end
	 
	if(OmegaMapConfig.showCoords) then
		OmegaMapCoordinates:Show()
	else
		OmegaMapCoordinates:Hide()
	end

	if (OmegaMapConfig.clearMap) then
		OmegaMapNoteFrame:Hide()
	end
	OmegaMap_SetPosition() --Sets regular or BG map settings
end

function OmegaMapFrame_OnHide(self)
	if ( OpacityFrame:IsShown() and OpacityFrame.saveOpacityFunc and OpacityFrame.saveOpacityFunc == OmegaMapFrame_SaveOpacity ) then
		OmegaMapFrame_SaveOpacity();
		OpacityFrame.saveOpacityFunc = nil;
		OpacityFrame:Hide();
	end
	OmegaMapConfig.hotSpotLock = false;
	--self.fromJournal = false; 

	--UpdateMicroButtons();
	CloseDropDownMenus();
	PlaySound("igQuestLogClose");
	OmegaMap_ClearTextures();
	OmegaMapPing.Ping:Stop();  --New
	if ( self.showOnHide ) then
		ShowUIPanel(self.showOnHide);
		self.showOnHide = nil;
	end

	--Hide Options window if shown
	if (OmegaMapOptionsFrame.Frame:IsShown()) then
		OmegaMapOptionsFrame.Frame:Hide()
	end 
	OmegaMapConfig.showObjectives = false

	--Clears Blobs from map
	OmegaMapFrame:Hide()
	OmegaMapBlobFrame:DrawBlob(GetSuperTrackedQuestID(), false);
	OmegaMapBlobFrame:DrawNone();
	OmegaMapArchaeologyDigSites:DrawNone();
	OmegaMapScenarioPOIFrame:DrawNone();

	local numEntries = ArchaeologyMapUpdateAll();
	for i = 1, numEntries do
		local blobID = ArcheologyGetVisibleBlobID(i);
		OmegaMapArchaeologyDigSites:DrawBlob(blobID, false);
	end
	OmegaMapSolidify("Off")

	-- forces WatchFrame event via the WORLD_MAP_UPDATE event, needed to restore the POIs in the tracker to the current zone
	if (not OmegaMapFrame.toggling) then
		OmegaMapFrame.fromJournal = false;
		OmegaMapFrame.hasBosses = false;
		SetMapToCurrentZone();
	end
	CancelEmote();
	--[[
		if ( WORLDMAP_SETTINGS.superTrackedQuestID > 0 ) then
		SetSuperTrackedQuestID(WORLDMAP_SETTINGS.superTrackedQuestID);
		QuestPOI_SelectButtonByQuestId("WatchFrameLines", WORLDMAP_SETTINGS.superTrackedQuestID, true);
		WORLDMAP_SETTINGS.superTrackedQuestID = 0;
	end
	]]--
	self.mapID = nil;
end

function OmegaMapFrame_OnEvent(self, event, ...)
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		if ( self:IsShown() ) then
			HideUIPanel(OmegaMapFrame);
		end
		
	elseif ( event == "WORLD_MAP_UPDATE" or event == "REQUEST_CEMETERY_LIST_RESPONSE" ) then
		if ( not self.blockOmegaMapUpdate and self:IsShown() ) then
			-- if we are exiting a micro dungeon we should update the world map
			if (event == "REQUEST_CEMETERY_LIST_RESPONSE") then
				local _, _, _, isMicroDungeon = GetMapInfo();
				if (isMicroDungeon) then
					SetMapToCurrentZone();
				end
			end
			OmegaMapFrame_UpdateMap();
		end
		--New
		if ( event == "WORLD_MAP_UPDATE" ) then
			local mapID = GetCurrentMapAreaID();
			if ( mapID ~= self.mapID) then
				self.mapID = mapID;
				OmegaMapPing.Ping:Stop();
				local playerX, playerY = GetPlayerMapPosition("player");
				if ( playerX ~= 0 or playerY ~= 0 ) then
					OmegaMapPing.Ping:Play();
				end
			end
		end
	elseif ( event == "ARTIFACT_DIG_SITE_UPDATED" ) then --New
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

		OmegaMapSliderFrame:SetValue(OmegaMapConfig.opacity);
		--OmegaMapQuestShowObjectives_Toggle();
		OmegaMapMasterFrame:SetScale(OmegaMapConfig.scale);
		OmegaMapOptionsFrame_init();
		OmegaMapSetEscPress()
		OmegaMapMiniMap_Register()
		OmegaMapHotSpotToggle()
	

	elseif ( event == "GROUP_ROSTER_UPDATE" ) then --replaces elseif ( event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" ) then		if ( self:IsShown() ) then
		if ( self:IsShown() ) then
			OmegaMapFrame_UpdateUnits("OmegaMapRaid", "OmegaMapParty");
		end
	elseif ( ( event == "QUEST_LOG_UPDATE" or event == "QUEST_POI_UPDATE" ) and self:IsShown() ) then
		OmegaMapFrame_DisplayQuests();
		OmegaMapQuestFrame_UpdateMouseOver();
	elseif  ( event == "SKILL_LINES_CHANGED" ) then
		OmegaMapShowDropDown_OnLoad(OmegaMapShowDropDown)
	elseif ( event == "UNIT_PORTRAIT_UPDATE" ) then
		OmegaMapJournal_UpdateMapButtonPortraits();
	elseif ( event == "MODIFIER_STATE_CHANGED" ) then
		OmegaMapSolidifyCheck(self,...)
	end
end

function OmegaMapFrame_OnUpdate(self)
	local nextBattleTime = GetOutdoorPVPWaitTime();
	if ( nextBattleTime and not IsInInstance()) then
		local battleSec = mod(nextBattleTime, 60);
		local battleMin = mod(floor(nextBattleTime / 60), 60);
		local battleHour = floor(nextBattleTime / 3600);
		OmegaMapZoneInfo:SetFormattedText(NEXT_BATTLE, battleHour, battleMin, battleSec);
		OmegaMapZoneInfo:Show();
	else
		OmegaMapZoneInfo:Hide();
	end
end

NUM_OMEGAMAP_SCENARIO_POIS = 0

function OmegaMap_DrawWorldEffects()
	-----------------------------------------------------------------
	-- Draw quest POI world effects
	-----------------------------------------------------------------
	-- local numPOIWorldEffects = GetNumQuestPOIWorldEffects();
	
	-- --Ensure the button pool is big enough for all the world effect POI's
	-- if ( NUM_WORLDMAP_WORLDEFFECT_POIS < numPOIWorldEffects ) then
		-- for i=NUM_WORLDMAP_WORLDEFFECT_POIS+1, numPOIWorldEffects do
			-- WorldMap_CreateWorldEffectPOI(i);
		-- end
		-- NUM_WORLDMAP_WORLDEFFECT_POIS = numPOIWorldEffects;
	-- end
	
	-- -- Process every button in the world event POI pool
	-- for i=1,NUM_WORLDMAP_WORLDEFFECT_POIS do
		
		-- local worldEventPOIName = "WorldMapFrameWorldEffectPOI"..i;
		-- local worldEventPOI = _G[worldEventPOIName];
		
		-- -- Draw if used
		-- if ( (i <= numPOIWorldEffects) and (WatchFrame.showObjectives == true)) then
			-- local name, textureIndex, x, y  = GetQuestPOIWorldEffectInfo(i);	
			-- if (textureIndex) then -- could be outside this map
				-- local x1, x2, y1, y2 = GetWorldEffectTextureCoords(textureIndex);
				-- _G[worldEventPOIName.."Texture"]:SetTexCoord(x1, x2, y1, y2);
				-- x = x * WorldMapButton:GetWidth();
				-- y = -y * WorldMapButton:GetHeight();
				-- worldEventPOI:SetPoint("CENTER", "WorldMapButton", "TOPLEFT", x, y );
				-- worldEventPOI.name = worldEventPOIName;		
				-- worldEventPOI:Show();
				-- WorldEffectPOITooltips[worldEventPOIName] = name;
			-- else
				-- worldEventPOI:Hide();
			-- end
		-- else
			-- -- Hide if unused
			-- worldEventPOI:Hide();
		-- end		
	-- end
	
	-----------------------------------------------------------------
	-- Draw scenario POIs
	-----------------------------------------------------------------
	local scenarioIconInfo = C_Scenario.GetScenarioIconInfo();
	local numScenarioPOIs = 0;
	if(scenarioIconInfo ~= nil) then
		numScenarioPOIs = #scenarioIconInfo;
	end
	
	--Ensure the button pool is big enough for all the world effect POI's
	if ( NUM_OMEGAMAP_SCENARIO_POIS < numScenarioPOIs ) then
		for i=NUM_OMEGAMAP_SCENARIO_POIS+1, numScenarioPOIs do
			OmegaMap_CreateScenarioPOI(i);
		end
		NUM_OMEGAMAP_SCENARIO_POIS = numScenarioPOIs;
	end
	
	-- Draw scenario icons
	local scenarioIconCount = 1;
	if((WatchFrame.showObjectives == true) and (scenarioIconInfo ~= nil))then
		for _, info  in next, scenarioIconInfo do
		
			--textureIndex, x, y, name
			local textureIndex = info.index;
			local x = info.x;
			local y = info.y;
			local name = info.description;
			
			local scenarioPOIName = "OmegaMapFrameScenarioPOI"..scenarioIconCount;
			local scenarioPOI = _G[scenarioPOIName];
			
			local x1, x2, y1, y2 = GetWorldEffectTextureCoords(textureIndex);
			_G[scenarioPOIName.."Texture"]:SetTexCoord(x1, x2, y1, y2);
			x = x * OmegaMapButton:GetWidth();
			y = -y * OmegaMapButton:GetHeight();
			scenarioPOI:SetPoint("CENTER", "OmegaMapButton", "TOPLEFT", x, y );
			scenarioPOI.name = scenarioPOIName;		
			scenarioPOI:Show();
			ScenarioPOITooltips[scenarioPOIName] = name;
				
			scenarioIconCount = scenarioIconCount + 1;
		end
	end
	
	-- Hide unused icons in the pool
	for i=scenarioIconCount, NUM_OMEGAMAP_SCENARIO_POIS do
		local scenarioPOIName = "OmegaMapFrameScenarioPOI"..i;
		local scenarioPOI = _G[scenarioPOIName];
		scenarioPOI:Hide();
	end
	
end

function OmegaMapFrame_Update()
	local mapName, textureHeight, _, isMicroDungeon, microDungeonMapName = GetMapInfo();
	if (isMicroDungeon and (not microDungeonMapName or microDungeonMapName == "")) then
		return;
	end
	local activeFrame = OmegaMapButton
	
	if ( not mapName ) then
		if ( GetCurrentMapContinent() == WORLDMAP_COSMIC_ID ) then
			mapName = "Cosmic";
			OmegaMapOutlandButton:Show();
			OmegaMapAzerothButton:Show();
		else
			-- Temporary Hack (Temporary meaning 6 yrs, haha)
			mapName = "World";
			OmegaMapOutlandButton:Hide();
			OmegaMapAzerothButton:Hide();
		end
		OmegaMapDeepholmButton:Hide();
		OmegaMapKezanButton:Hide();
		OmegaMapLostIslesButton:Hide();
		OmegaMapTheMaelstromButton:Hide();
	else
		OmegaMapOutlandButton:Hide();
		OmegaMapAzerothButton:Hide();
		if ( GetCurrentMapContinent() == WORLDMAP_MAELSTROM_ID and GetCurrentMapZone() == 0 ) then
			OmegaMapDeepholmButton:Show();
			OmegaMapKezanButton:Show();
			OmegaMapLostIslesButton:Show();
			OmegaMapTheMaelstromButton:Show();
		else
			OmegaMapDeepholmButton:Hide();
			OmegaMapKezanButton:Hide();
			LostIslesButton:Hide();
			TheMaelstromButton:Hide();
		end
	end

	local dungeonLevel = GetCurrentMapDungeonLevel();
	if (DungeonUsesTerrainMap()) then
		dungeonLevel = dungeonLevel - 1;
	end

	local fileName;

	local path;
	if (not isMicroDungeon) then
		path = "Interface\\WorldMap\\"..mapName.."\\";
		fileName = mapName;
	else
		path = "Interface\\WorldMap\\MicroDungeon\\"..mapName.."\\"..microDungeonMapName.."\\";
		fileName = microDungeonMapName;
	end

	if ( dungeonLevel > 0 ) then
		fileName = fileName..dungeonLevel.."_";
	end

	local numOfDetailTiles = GetNumberOfDetailTiles();
	for i=1, numOfDetailTiles do
		local texName = path..fileName..i;
		_G["OmegaMapDetailTile"..i]:SetTexture(texName);
	end

	if OmegaMapConfig.showCompactMode then 
		OmegaMapCompactView() 
	else --if zone ==0  or overlay ==0  or not OmegaMapConfig.showCompactMode then 
		for i=1, GetNumberOfDetailTiles(), 1 do
		_G["OmegaMapDetailTile"..i]:Show();
		end
	end
	--OmegaMapHighlight:Hide();

	-- Enable/Disable zoom out button
	if ( IsZoomOutAvailable() ) then
		OmegaMapZoomOutButton:Enable();
	else
		OmegaMapZoomOutButton:Disable();
	end

	-- Setup the POI's
	local numPOIs = GetNumMapLandmarks();
	if ( NUM_OMEGAMAP_POIS < numPOIs ) then
		for i=NUM_OMEGAMAP_POIS+1, numPOIs do
			OmegaMap_CreatePOI(i);
		end
		NUM_OMEGAMAP_POIS = numPOIs;
	end
	local numGraveyards = 0;
	local currentGraveyard = GetCemeteryPreference();
	for i=1, NUM_OMEGAMAP_POIS do
		local omegaMapPOIName = "OmegaMapFramePOI"..i;
		local omegaMapPOI = _G[omegaMapPOIName];
		if ( i <= numPOIs ) then
			local name, description, textureIndex, x, y, mapLinkID, inBattleMap, graveyardID, areaID, poiID, isObjectIcon = GetMapLandmarkInfo(i);
			if( (GetCurrentMapAreaID() ~= WORLDMAP_WINTERGRASP_ID) and (areaID == WORLDMAP_WINTERGRASP_POI_AREAID) ) then
				omegaMapPOI:Hide();
			else

--alt map code

	if (OMEGAMAP_ALTMAP) then
		activeFrame = OmegaMapAltMapFrame
	else
		activeFrame = OmegaMapButton
	end
	x, y = OmegaMapOffsetAltMapCoords(x,y)
			x = x * activeFrame:GetWidth();
			y = -y * activeFrame:GetHeight();
			--omegaMapPOI:SetPoint("CENTER", "OmegaMapButton", "TOPLEFT", x, y );
			omegaMapPOI:SetPoint("CENTER", activeFrame, "TOPLEFT", x, y );
			--new
			if ( OmegaMap_IsSpecialPOI(poiID) ) then	--We have special handling for Isle of the Thunder King
				OmegaMap_HandleSpecialPOI(omegaMapPOI, poiID);
			else
				OmegaMap_ResetPOI(omegaMapPOI, isObjectIcon);

				local x1, x2, y1, y2
				if (isObjectIcon == true) then
					x1, x2, y1, y2 = GetObjectIconTextureCoords(textureIndex);
				else
					x1, x2, y1, y2 = GetPOITextureCoords(textureIndex);
				end
				_G[omegaMapPOIName.."Texture"]:SetTexCoord(x1, x2, y1, y2);
				omegaMapPOI.name = name;
				omegaMapPOI.description = description;
				omegaMapPOI.mapLinkID = mapLinkID;
				if ( graveyardID and graveyardID > 0 ) then
					omegaMapPOI.graveyard = graveyardID;
					numGraveyards = numGraveyards + 1;
					local graveyard = OmegaMap_GetGraveyardButton(numGraveyards);
					graveyard:SetPoint("CENTER", omegaMapPOI);
					graveyard:SetFrameLevel(omegaMapPOI:GetFrameLevel() - 1);
					graveyard:Show();
					if ( currentGraveyard == graveyardID ) then
						graveyard.texture:SetTexture("Interface\\WorldMap\\GravePicker-Selected");
					else
						graveyard.texture:SetTexture("Interface\\WorldMap\\GravePicker-Unselected");
					end
					omegaMapPOI:Hide();		-- lame way to force tooltip redraw
				else
					omegaMapPOI.graveyard = nil;
				end
				omegaMapPOI:Show();	
			end
			end
		else
			omegaMapPOI:Hide();
		end
	end

	if ( numGraveyards > NUM_OMEGAMAP_GRAVEYARDS ) then
		NUM_OMEGAMAP_GRAVEYARDS = numGraveyards;
	else
		for i = numGraveyards + 1, NUM_OMEGAMAP_GRAVEYARDS do
			_G["OmegaMapFrameGraveyard"..i]:Hide();
		end
	end
	
	OmegaMap_DrawWorldEffects();

	-- Setup the overlays
	local textureCount = 0;
	for i=1, GetNumMapOverlays() do
		local textureName, textureWidth, textureHeight, offsetX, offsetY = GetMapOverlayInfo(i);
		if ( textureName and textureName ~= "" ) then
			local numTexturesWide = ceil(textureWidth/256);
			local numTexturesTall = ceil(textureHeight/256);
			local neededTextures = textureCount + (numTexturesWide * numTexturesTall);
			if ( neededTextures > NUM_OMEGAMAP_OVERLAYS ) then
				for j=NUM_OMEGAMAP_OVERLAYS+1, neededTextures do
					OmegaMapDetailFrame:CreateTexture("OmegaMapOverlay"..j, "ARTWORK");
				end
				NUM_OMEGAMAP_OVERLAYS = neededTextures;
			end
			local texturePixelWidth, textureFileWidth, texturePixelHeight, textureFileHeight;
			for j=1, numTexturesTall do
				if ( j < numTexturesTall ) then
					texturePixelHeight = 256;
					textureFileHeight = 256;
				else
					texturePixelHeight = mod(textureHeight, 256);
					if ( texturePixelHeight == 0 ) then
						texturePixelHeight = 256;
					end
					textureFileHeight = 16;
					while(textureFileHeight < texturePixelHeight) do
						textureFileHeight = textureFileHeight * 2;
					end
				end
				for k=1, numTexturesWide do
					textureCount = textureCount + 1;
					local texture = _G["OmegaMapOverlay"..textureCount];
					if ( k < numTexturesWide ) then
						texturePixelWidth = 256;
						textureFileWidth = 256;
					else
						texturePixelWidth = mod(textureWidth, 256);
						if ( texturePixelWidth == 0 ) then
							texturePixelWidth = 256;
						end
						textureFileWidth = 16;
						while(textureFileWidth < texturePixelWidth) do
							textureFileWidth = textureFileWidth * 2;
						end
					end
					texture:SetWidth(texturePixelWidth);
					texture:SetHeight(texturePixelHeight);
					texture:SetTexCoord(0, texturePixelWidth/textureFileWidth, 0, texturePixelHeight/textureFileHeight);
					texture:SetPoint("TOPLEFT", offsetX + (256 * (k-1)), -(offsetY + (256 * (j - 1))));
					texture:SetTexture(textureName..(((j - 1) * numTexturesWide) + k));
					texture:Show();
				end
			end
		end
	end
	for i=textureCount+1, NUM_OMEGAMAP_OVERLAYS do
		_G["OmegaMapOverlay"..i]:Hide();
	end
	
	OmegaMapJournal_AddMapButtons();

-- sets up Gatherer POI
	if (GathererOmegaMapOverlayParent) then
		if (OmegaMapConfig.showGatherer) then
			GathererOmegaMapOverlayParent:Show()
			OmegaMap_DrawGathererPOI();

		else 
			GathererOmegaMapOverlayParent:Hide()
			--[[
		elseif ( OmegaMapGathererPOI1 ) then
			OmegaMapGathererPOI1:Hide();
			local i = 2;
			local GathererPOI = _G[ "OmegaMapGathererPOI"..i ];
			while ( GathererPOI ) do
				GathererPOI:Hide();
				i = i + 1;
				GathererPOI = _G[ "OmegaMapGathererPOI"..i ];
			end
			GathererOmegaMapOverlayParent:Hide()
]]--
		end
	end
--CTMapmod POI
	if (CTMapOmegaMapOverlay) then
		if (OmegaMapConfig.showCTMap) then
			--CT_MapMod_UpdateMap();
			CTMapOmegaMapOverlay:Show()
		else
			CTMapOmegaMapOverlay:Hide()
		end
	end
--TomTom POI
	if  (TomTomOmegaMapOverlay) then
		if ((OmegaMapConfig.showTomTom) and (TomTom.profile)) then
			TomTomOmegaMapOverlay:Show()
			OmegaMap_DrawTomToms();	
		else
			TomTomOmegaMapOverlay:Hide()
		end
	end
--Routes POI
	if (RoutesOmegaMapOverlay) then
		if (OmegaMapConfig.showRoutes) then
			RoutesOmegaMapOverlay:Show()
			OmegaMapDrawWorldmapLines();
		else
			RoutesOmegaMapOverlay:Hide()
		end
	end
--Gathermate POI
	if (GatherMateOmegaMapOverlay) then
		if (OmegaMapConfig.showGatherMate) then
			GatherMateOmegaMapOverlay:Show() 
		else
			GatherMateOmegaMapOverlay:Hide()
		end
	end
--MapNotes
	if  (MapNotesOmegaMapOverlay) then
		if (OmegaMapConfig.showMapNotes) then
			MapNotesOmegaMapOverlay:Show()
		else
			MapNotesOmegaMapOverlay:Hide()
		end
	end
--NPCScan.Overlay
	if  (NPCScanOmegaMapOverlay) then
		if (OmegaMapConfig.showNPCScanOverlay) then
			NPCScanOmegaMapOverlay:Show()
		else
			NPCScanOmegaMapOverlay:Hide()
		end
	end

--QuestHelperLite
	if  (QHLOmegaMapOverlay) then
		if (OmegaMapConfig.showQuestHelperLite) then
			QHLOmegaMapOverlay:Show()
		else
			QHLOmegaMapOverlay:Hide()
		end
	end

	--HandyNotes
	if  (HandyNotesOmegaMapOverlay) then
		if (OmegaMapConfig.showHandyNotes) then
			HandyNotesOmegaMapOverlay:Show()
		else
			HandyNotesOmegaMapOverlay:Hide()
		end
	end

	if  (PetTracker) then

	end

	if  (Explorer) then


	end

--Shows Alternate map if avaliable
	if OmegaMapConfig.showExteriors then
		OmegaMap_LoadAltMapNotes()
	else 
		OmegaMap_HideAltMap()
	end

-- Hides map blobs if an alt map is displayed
	if  not InCombatLockdown() then
		if OMEGAMAP_ALTMAP then
			OmegaMapSpecialFrame:Hide()
		else
			OmegaMapSpecialFrame:Show()
		end
	end
end

function OmegaMapFrame_UpdateUnits(raidUnitPrefix, partyUnitPrefix)
	for i=1, MAX_RAID_MEMBERS do
		local partyMemberFrame = _G["OmegaMapRaid"..i];
		if ( partyMemberFrame:IsShown() ) then
			OmegaMapUnit_Update(partyMemberFrame);
		end
	end
	for i=1, MAX_PARTY_MEMBERS do
		local partyMemberFrame = _G["OmegaMapParty"..i];
		if ( partyMemberFrame:IsShown() ) then
			OmegaMapUnit_Update(partyMemberFrame);
		end
	end
end

function OmegaMapPOI_OnEnter(self)
	OmegaMapFrame.poiHighlight = 1;
	if ( self.specialPOIInfo and self.specialPOIInfo.onEnter ) then
		self.specialPOIInfo.onEnter(self, self.specialPOIInfo);
	else
		if ( self.description and strlen(self.description) > 0 ) then
			OmegaMapFrameAreaLabel:SetText(self.name);
			OmegaMapFrameAreaDescription:SetText(self.description);
		else
			OmegaMapFrameAreaLabel:SetText(self.name);
			OmegaMapFrameAreaDescription:SetText("");
			-- need localization
			if ( self.graveyard ) then
				OmegaMapTooltip:SetOwner(self, "ANCHOR_RIGHT");
				if ( self.graveyard == GetCemeteryPreference() ) then
					OmegaMapTooltip:SetText(GRAVEYARD_SELECTED);
					OmegaMapTooltip:AddLine(GRAVEYARD_SELECTED_TOOLTIP, 1, 1, 1, 1);
					OmegaMapTooltip:Show();
				else
					OmegaMapTooltip:SetText(GRAVEYARD_ELIGIBLE);
					OmegaMapTooltip:AddLine(GRAVEYARD_ELIGIBLE_TOOLTIP, 1, 1, 1, 1);
					OmegaMapTooltip:Show();
				end
			end
		end
	end
end

function OmegaMapPOI_OnLeave(self)
	OmegaMapFrame.poiHighlight = nil;
	if ( self.specialPOIInfo and self.specialPOIInfo.onLeave ) then
		self.specialPOIInfo.onLeave(self, self.specialPOIInfo);
	else
		OmegaMapFrameAreaLabel:SetText(OmegaMapFrame.areaName);
		OmegaMapFrameAreaDescription:SetText("");
		OmegaMapTooltip:Hide();
	end
end

--New
function OmegaMap_ThunderIslePOI_OnEnter(self, poiInfo)
	OmegaMapTooltip:SetOwner(self, "ANCHOR_RIGHT");
	local tag = "THUNDER_ISLE";
	local phase = poiInfo.phase;

	local title = OmegaMapBarFrame_GetString("TITLE", tag, phase);
	if ( poiInfo.active ) then
		local tooltipText = OmegaMapBarFrame_GetString("TOOLTIP", tag, phase);
		local percentage = math.floor(100 * C_MapBar.GetCurrentValue() / C_MapBar.GetMaxValue());
		OmegaMapTooltip:SetText(format(MAP_BAR_TOOLTIP_TITLE, title, percentage), 1, 1, 1);
		OmegaMapTooltip:AddLine(tooltipText, nil, nil, nil, true);
		OmegaMapTooltip:Show();
	else
		local disabledText = OmegaMapBarFrame_GetString("LOCKED", tag, phase);
		OmegaMapTooltip:SetText(title, 1, 1, 1);
		OmegaMapTooltip:AddLine(disabledText, nil, nil, nil, true);
		OmegaMapTooltip:Show();
	end
end

function OmegaMap_ThunderIslePOI_OnLeave(self, poiInfo)
	OmegaMapTooltip:Hide();
end

function OmegaMap_HandleThunderIslePOI(poiFrame, poiInfo)
	poiFrame:SetSize(64, 64);
	poiFrame.Texture:SetSize(64, 64);
	
	poiFrame.Texture:SetTexCoord(0, 1, 0, 1);
	if ( poiInfo.active ) then
		poiFrame.Texture:SetTexture("Interface\\WorldMap\\MapProgress\\mappoi-mogu-on");
	else
		poiFrame.Texture:SetTexture("Interface\\WorldMap\\MapProgress\\mappoi-mogu-off");
	end
end

OM_SPECIAL_POI_INFO = {
	[2943] = { phase = 0, active = true },
	[2944] = { phase = 0, active = true },
	[2925] = { phase = 1, active = true },
	[2927] = { phase = 1, active = false },
	[2945] = { phase = 1, active = true },
	[2949] = { phase = 1, active = false },
	[2937] = { phase = 2, active = true },
	[2938] = { phase = 2, active = false },
	[2946] = { phase = 2, active = true },
	[2950] = { phase = 2, active = false },
	[2939] = { phase = 3, active = true },
	[2940] = { phase = 3, active = false },
	[2947] = { phase = 3, active = true },
	[2951] = { phase = 3, active = false },
	[2941] = { phase = 4, active = true },
	[2942] = { phase = 4, active = false },
	[2948] = { phase = 4, active = true },
	[2952] = { phase = 4, active = false },
	--If you add another special POI, make sure to change the setup below
};

for k, v in pairs(OM_SPECIAL_POI_INFO) do
	v.handleFunc = OmegaMap_HandleThunderIslePOI;
	v.onEnter = OmegaMap_ThunderIslePOI_OnEnter;
	v.onLeave = OmegadMap_ThunderIslePOI_OnLeave;
end

function OmegaMap_IsSpecialPOI(poiID)
	if ( OM_SPECIAL_POI_INFO[poiID] ) then
		return true;
	else
		return false;
	end
end

function OmegaMap_HandleSpecialPOI(poiFrame, poiID)
	local poiInfo = OM_SPECIAL_POI_INFO[poiID];
	poiFrame.specialPOIInfo = poiInfo;
	if ( poiInfo and poiInfo.handleFunc ) then
		poiInfo.handleFunc(poiFrame, poiInfo)
		poiFrame:Show();
	else
		poiFrame:Hide();
	end
end

function OmegaMapEffectPOI_OnEnter(self)
	if(WorldEffectPOITooltips[self.name] ~= nil) then
		OmegaMapTooltip:SetOwner(self, "ANCHOR_RIGHT");
		OmegaMapTooltip:SetText(WorldEffectPOITooltips[self.name]);
		OmegaMapTooltip:Show();
		OmegaMapTooltip.WE_using = true;
	end
end

function OmegaMapEffectPOI_OnLeave()
	OmegaMapFrame.poiHighlight = nil;
	OmegaMapFrameAreaLabel:SetText(OmegaMapFrame.areaName);
	OmegaMapFrameAreaDescription:SetText("");
	OmegaMapTooltip:Hide();
	OmegaMapTooltip.WE_using = false;
end

function OmegaMapScenarioPOI_OnEnter(self)
	if(ScenarioPOITooltips[self.name] ~= nil) then
		OmegaMapTooltip:SetOwner(self, "ANCHOR_RIGHT");
		OmegaMapTooltip:SetText(ScenarioPOITooltips[self.name]);
		OmegaMapTooltip:Show();
		OmegaMapTooltip.WE_using = true;
	end
end

function OmegaMapScenarioPOI_OnLeave()
	OmegaMapFrame.poiHighlight = nil;
	OmegaMapFrameAreaLabel:SetText(OmegaMapFrame.areaName);
	OmegaMapFrameAreaDescription:SetText("");
	OmegaMapTooltip:Hide();
	OmegaMapTooltip.WE_using = false;
end

function OmegaMapPOI_OnClick(self, button)
	if ( self.mapLinkID ) then
		ClickLandmark(self.mapLinkID);
	elseif ( self.graveyard ) then
		SetCemeteryPreference(self.graveyard);
		OmegaMapFrame_Update();
	else
		if OmegaMapConfig.solidify then
			OmegaMapButton_OnClick(OmegaMapButton, button);
		else
			return
		end
	end
end

function OmegaMap_CreatePOI(index, isObjectIcon)
	local button = CreateFrame("Button", "OmegaMapFramePOI"..index, OmegaMapDetailFrame);
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	button:SetScript("OnEnter", OmegaMapPOI_OnEnter);
	button:SetScript("OnLeave", OmegaMapPOI_OnLeave);
	button:SetScript("OnClick", OmegaMapPOI_OnClick);

	button.Texture = button:CreateTexture(button:GetName().."Texture", "BACKGROUND");

	OmegaMap_ResetPOI(button, isObjectIcon);
end

function OmegaMap_ResetPOI(button, isObjectIcon)
	if (isObjectIcon == true) then
		button:SetWidth(32);
		button:SetHeight(32);
		button.Texture:SetWidth(28);
		button.Texture:SetHeight(28);
		button.Texture:SetPoint("CENTER", 0, 0);
		button.Texture:SetTexture("Interface\\Minimap\\ObjectIcons");
	else
		button:SetWidth(32);
		button:SetHeight(32);
		button.Texture:SetWidth(16);
		button.Texture:SetHeight(16);
		button.Texture:SetPoint("CENTER", 0, 0);
		button.Texture:SetTexture("Interface\\Minimap\\POIIcons");
	end

	button.specialPOIInfo = nil;
end

function OmegadMap_CreateWorldEffectPOI(index)
	local button = CreateFrame("Button", "OmegaMapFrameWorldEffectPOI"..index, OmegaMapButton);
	button:SetWidth(32);
	button:SetHeight(32);
	button:SetScript("OnEnter", OmegaMapEffectPOI_OnEnter);
	button:SetScript("OnLeave", OmegaMapEffectPOI_OnLeave);
	
	local texture = button:CreateTexture(button:GetName().."Texture", "BACKGROUND");
	texture:SetWidth(16);
	texture:SetHeight(16);
	texture:SetPoint("CENTER", 0, 0);
	texture:SetTexture("Interface\\Minimap\\OBJECTICONS");
end

function OmegaMap_CreateScenarioPOI(index)
	local button = CreateFrame("Button", "OmegaMapFrameScenarioPOI"..index, OmegaMapButton);
	button:SetWidth(32);
	button:SetHeight(32);
	button:SetScript("OnEnter", OmegaMapScenarioPOI_OnEnter);
	button:SetScript("OnLeave", OmegaMapScenarioPOI_OnLeave);
	
	local texture = button:CreateTexture(button:GetName().."Texture", "BACKGROUND");
	texture:SetWidth(16);
	texture:SetHeight(16);
	texture:SetPoint("CENTER", 0, 0);
	texture:SetTexture("Interface\\Minimap\\OBJECTICONS");
end

function OmegaMap_GetGraveyardButton(index)
	-- everything here is temp
	local frameName = "OmegaMapFrameGraveyard"..index;
	local button = _G[frameName];
	if ( not button ) then
		button = CreateFrame("Button", frameName, OmegaMapButton);
		button:SetWidth(32);
		button:SetHeight(32);
		button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
		button:SetScript("OnEnter", nil);
		button:SetScript("OnLeave", nil);
		button:SetScript("OnClick", nil);
		
		local texture = button:CreateTexture(button:GetName().."Texture", "ARTWORK");
		texture:SetWidth(24);
		texture:SetHeight(24);
		texture:SetPoint("CENTER", 0, 0);
		button.texture = texture;
	end
	return button;
end


function OmegaMapContinentsDropDown_Update()
	UIDropDownMenu_Initialize(OmegaMapContinentDropDown, OmegaMapContinentsDropDown_Initialize);
	UIDropDownMenu_SetWidth(OmegaMapContinentDropDown, 130);

	if ( (GetCurrentMapContinent() == WORLDMAP_WORLD_ID) or (GetCurrentMapContinent() == WORLDMAP_COSMIC_ID) ) then
		UIDropDownMenu_ClearAll(OmegaMapContinentDropDown);
	else
		UIDropDownMenu_SetSelectedID(OmegaMapContinentDropDown,GetCurrentMapContinent());
	end
end

function OmegaMapContinentsDropDown_Initialize()
	OmegaMapFrame_LoadContinents(GetMapContinents());
end

function OmegaMapFrame_LoadContinents(...)
	local info = UIDropDownMenu_CreateInfo();
	for i=1, select("#", ...), 1 do
		info.text = select(i, ...);
		info.func = OmegaMapContinentButton_OnClick;
		info.checked = nil;
		UIDropDownMenu_AddButton(info);
	end
end

function OmegaMapZoneDropDown_Update()
	UIDropDownMenu_Initialize(OmegaMapZoneDropDown, OmegaMapZoneDropDown_Initialize);
	UIDropDownMenu_SetWidth(OmegaMapZoneDropDown, 130);

	if ( (GetCurrentMapContinent() == WORLDMAP_WORLD_ID) or (GetCurrentMapContinent() == WORLDMAP_COSMIC_ID) ) then
		UIDropDownMenu_ClearAll(OmegaMapZoneDropDown);
	else
		UIDropDownMenu_SetSelectedID(OmegaMapZoneDropDown, GetCurrentMapZone());
	end
end

function OmegaMapZoneDropDown_Initialize()
	OmegaMapFrame_LoadZones(GetMapZones(GetCurrentMapContinent()));
end

function OmegaMapFrame_LoadZones(...)
	local info = UIDropDownMenu_CreateInfo();
	for i=1, select("#", ...), 1 do
		info.text = select(i, ...);
		info.func = OmegaMapZoneButton_OnClick;
		info.checked = nil;
		UIDropDownMenu_AddButton(info);
	end
end

function OmegaMapLevelDropDown_Update()
	UIDropDownMenu_Initialize(OmegaMapLevelDropDown, OmegaMapLevelDropDown_Initialize);
	UIDropDownMenu_SetWidth(OmegaMapLevelDropDown, 130);

	if ( (GetNumDungeonMapLevels() == 0) ) then
		UIDropDownMenu_ClearAll(OmegaMapLevelDropDown);
		OmegaMapLevelDropDown:Hide();
		OmegaMapLevelUpButton:Hide();
		OmegaMapLevelDownButton:Hide();
	else
		UIDropDownMenu_SetSelectedID(OmegaMapLevelDropDown, GetCurrentMapDungeonLevel());
		OmegaMapLevelDropDown:Show();
		OmegaMapLevelUpButton:Show();
		OmegaMapLevelDownButton:Show();
	end
end

function OmegaMapLevelDropDown_Initialize()
	local info = UIDropDownMenu_CreateInfo();
	local level = GetCurrentMapDungeonLevel();
	
	local mapname = strupper(GetMapInfo() or "");
	
	local usesTerrainMap = DungeonUsesTerrainMap();
	local floorMapCount, firstFloor = GetNumDungeonMapLevels();
	local _, _, _, isMicroDungeon = GetMapInfo();

	local lastFloor = firstFloor + floorMapCount - 1;
	
	for i=firstFloor, lastFloor do
		local floorNum = i;
		if (usesTerrainMap) then
			floorNum = i - 1;
		end
		local floorname =_G["DUNGEON_FLOOR_" .. mapname .. floorNum];
		info.text = floorname or string.format(FLOOR_NUMBER, i - firstFloor + 1);
		info.func = OmegaMapLevelButton_OnClick;
		info.checked = (i == level);
		UIDropDownMenu_AddButton(info);
	end
end

function OmegaMapLevelButton_OnClick(self)
	UIDropDownMenu_SetSelectedID(OmegaMapLevelDropDown, self:GetID());	
	local floorMapCount, firstFloor = GetNumDungeonMapLevels();
	local level = firstFloor + self:GetID() - 1;
	
	SetDungeonMapLevel(level);
end

function OmegaMapLevelUp_OnClick(self)
	CloseDropDownMenus();
	local currMapLevel = GetCurrentMapDungeonLevel();
	SetDungeonMapLevel(currMapLevel - 1);
	local newMapLevel = GetCurrentMapDungeonLevel();
	if ( currMapLevel ~= newMapLevel ) then
		local floorMapCount, firstFloor = GetNumDungeonMapLevels();
		UIDropDownMenu_SetSelectedID(OmegaMapLevelDropDown, newMapLevel - firstFloor + 1)
	end
	PlaySound("UChatScrollButton");
end

function OmegaMapLevelDown_OnClick(self)
	CloseDropDownMenus();
	local currMapLevel = GetCurrentMapDungeonLevel();
	SetDungeonMapLevel(currMapLevel + 1);
	local newMapLevel = GetCurrentMapDungeonLevel();
	if ( currMapLevel ~= newMapLevel ) then
		local floorMapCount, firstFloor = GetNumDungeonMapLevels();
		UIDropDownMenu_SetSelectedID(OmegaMapLevelDropDown, newMapLevel - firstFloor + 1);
	end
	PlaySound("UChatScrollButton");
end

function OmegaMapContinentButton_OnClick(self)
	UIDropDownMenu_SetSelectedID(OmegaMapContinentDropDown, self:GetID());
	SetMapZoom(self:GetID());
end

function OmegaMapZoneButton_OnClick(self)
	UIDropDownMenu_SetSelectedID(OmegaMapZoneDropDown, self:GetID());
	SetMapZoom(GetCurrentMapContinent(), self:GetID());
end

function OmegaMapZoomOutButton_OnClick()
	PlaySound("igMainMenuOptionCheckBoxOn");
	OmegaMapTooltip:Hide();
	
	-- check if code needs to zoom out before going to the continent map
	if ( ZoomOut() ~= nil ) then
		return;
	elseif ( GetCurrentMapZone() ~= WORLDMAP_WORLD_ID ) then
		SetMapZoom(GetCurrentMapContinent());
	elseif ( GetCurrentMapContinent() == WORLDMAP_WORLD_ID ) then
		SetMapZoom(WORLDMAP_COSMIC_ID);
	elseif ( GetCurrentMapContinent() == WORLDMAP_OUTLAND_ID ) then
		SetMapZoom(WORLDMAP_COSMIC_ID);
	else
		SetMapZoom(WORLDMAP_WORLD_ID);
	end
end

function OmegaMapButton_OnClick(button, mouseButton)
	CloseDropDownMenus();
	if ( mouseButton == "LeftButton" ) then
		local x, y = GetCursorPosition();
		x = x / button:GetEffectiveScale();
		y = y / button:GetEffectiveScale();

		local centerX, centerY = button:GetCenter();
		local width = button:GetWidth();
		local height = button:GetHeight();
		local adjustedY = (centerY + (height/2) - y) / height;
		local adjustedX = (x - (centerX - (width/2))) / width;
		ProcessMapClick( adjustedX, adjustedY);
	elseif ( mouseButton == "RightButton" ) then
	--Map Notes  plugin click register

			OmegaMapZoomOutButton_OnClick();

	elseif ( GetBindingFromClick(mouseButton) ==  "TOGGLEWORLDMAP" ) then
		ToggleFrame(OmegaMapFrame);
	end
end

local BLIP_TEX_COORDS = {
["WARRIOR"] = { 0, 0.125, 0, 0.25 },
["PALADIN"] = { 0.125, 0.25, 0, 0.25 },
["HUNTER"] = { 0.25, 0.375, 0, 0.25 },
["ROGUE"] = { 0.375, 0.5, 0, 0.25 },
["PRIEST"] = { 0.5, 0.625, 0, 0.25 },
["DEATHKNIGHT"] = { 0.625, 0.75, 0, 0.25 },
["SHAMAN"] = { 0.75, 0.875, 0, 0.25 },
["MAGE"] = { 0.875, 1, 0, 0.25 },
["WARLOCK"] = { 0, 0.125, 0.25, 0.5 },
["DRUID"] = { 0.25, 0.375, 0.25, 0.5 },
["MONK"] = { 0.125, 0.25, 0.25, 0.5 },
}

local BLIP_RAID_Y_OFFSET = 0.5;

function OmegaMapButton_OnUpdate(self, elapsed)
	local x, y = GetCursorPosition();
	x = x / self:GetEffectiveScale();
	y = y / self:GetEffectiveScale();

	local centerX, centerY = self:GetCenter();
	local width = self:GetWidth();
	local height = self:GetHeight();
	local adjustedY = (centerY + (height/2) - y ) / height;
	local adjustedX = (x - (centerX - (width/2))) / width;
	
	local name, fileName, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY, minLevel, maxLevel, petMinLevel, petMaxLevel
	if ( self:IsMouseOver() ) then
		name, fileName, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY, minLevel, maxLevel, petMinLevel, petMaxLevel = UpdateMapHighlight( adjustedX, adjustedY );
	end
	
	OmegaMapFrameAreaPetLevels:SetText(""); --make sure pet level is cleared
	
	OmegaMapFrame.areaName = name;
	if ( not OmegaMapFrame.poiHighlight ) then
		if ( OmegaMapFrame.maelstromZoneText ) then
			OmegaMapFrameAreaLabel:SetText(OmegaMapFrame.maelstromZoneText);
			name = OmegaMapFrame.maelstromZoneText;
			minLevel = OmegaMapFrame.minLevel;
			maxLevel = OmegaMapFrame.maxLevel;
			petMinLevel = OmegaMapFrame.petMinLevel;
			petMaxLevel = OmegaMapFrame.petMaxLevel;

		else
			OmegaMapFrameAreaLabel:SetText(name);
		end

		if (name and minLevel and maxLevel and minLevel > 0 and maxLevel > 0) then
			local playerLevel = UnitLevel("player");
			local color;
			if (playerLevel < minLevel) then
				color = GetQuestDifficultyColor(minLevel);
			elseif (playerLevel > maxLevel) then
				--subtract 2 from the maxLevel so zones entirely below the player's level won't be yellow
				color = GetQuestDifficultyColor(maxLevel - 2); 
			else
				color = QuestDifficultyColors["difficult"];
			end
			color = ConvertRGBtoColorString(color);
			if (minLevel ~= maxLevel) then
				OmegaMapFrameAreaLabel:SetText(OmegaMapFrameAreaLabel:GetText()..color.." ("..minLevel.."-"..maxLevel..")");
			else
				OmegaMapFrameAreaLabel:SetText(OmegaMapFrameAreaLabel:GetText()..color.." ("..maxLevel..")");
			end
		end

		local _, _, _, _, locked = C_PetJournal.GetPetLoadOutInfo(1);
		if (not locked and IsTrackingBattlePets()) then --don't show pet levels for people who haven't unlocked battle petting
			if (petMinLevel and petMaxLevel and petMinLevel > 0 and petMaxLevel > 0) then 
				local teamLevel = C_PetJournal.GetPetTeamAverageLevel();
				local color
				if (teamLevel) then
					if (teamLevel < petMinLevel) then
						--add 2 to the min level because it's really hard to fight higher level pets
						color = GetRelativeDifficultyColor(teamLevel, petMinLevel + 2);
					elseif (teamLevel > petMaxLevel) then
						color = GetRelativeDifficultyColor(teamLevel, petMaxLevel); 
					else
						--if your team is in the level range, no need to call the function, just make it yellow
						color = QuestDifficultyColors["difficult"];
					end
				else
					--If you unlocked pet battles but have no team, level ranges are meaningless so make them grey
					color = QuestDifficultyColors["header"];
				end
				color = ConvertRGBtoColorString(color);
				if (petMinLevel ~= petMaxLevel) then
					OmegaMapFrameAreaPetLevels:SetText(WORLD_MAP_WILDBATTLEPET_LEVEL..color.."("..petMinLevel.."-"..petMaxLevel..")");
				else
					OmegaMapFrameAreaPetLevels:SetText(WORLD_MAP_WILDBATTLEPET_LEVEL..color.."("..petMaxLevel..")");
				end
			end
		end

	end
	if ( fileName ) then
		OmegaMapHighlight:SetTexCoord(0, texPercentageX, 0, texPercentageY);
		OmegaMapHighlight:SetTexture("Interface\\WorldMap\\"..fileName.."\\"..fileName.."Highlight");
		textureX = textureX * width;
		textureY = textureY * height;
		scrollChildX = scrollChildX * width;
		scrollChildY = -scrollChildY * height;
		if ( (textureX > 0) and (textureY > 0) ) then
			OmegaMapHighlight:SetWidth(textureX);
			OmegaMapHighlight:SetHeight(textureY);
			OmegaMapHighlight:SetPoint("TOPLEFT", "OmegaMapDetailFrame", "TOPLEFT", scrollChildX, scrollChildY);
			OmegaMapHighlight:Show();
			--OmegaMapFrameAreaLabel:SetPoint("TOP", "OmegaMapHighlight", "TOP", 0, 0);
		end
		
	else
		OmegaMapHighlight:Hide();
	end
	--Position player
	local playerX, playerY = OmegaMapOffsetAltMapCoords( GetPlayerMapPosition("player"));
	local activeFrame = OmegaMapDetailFrame

	if ( (playerX == 0 and playerY == 0) ) then
		OmegaMapPlayerLower:Hide();
		OmegaMapPlayerUpper:Hide();
	else
-- Code for exterior swtich
	local uX, uY = OmegaMapOffsetAltMapCoords( playerX, playerY)

	if (OMEGAMAP_ALTMAP) then
		activeFrame = OmegaMapAltMapFrame
	else
		activeFrame = OmegaMapDetailFrame
	end

	playerX = playerX  * activeFrame:GetWidth();
	playerY = -playerY  * activeFrame:GetHeight();
	
	--OmegaMapPlayer:SetPoint("CENTER", activeFrame, "TOPLEFT", playerX, playerY);


		-- Position clear button to detect mouseovers
		--OmegaMapPlayer:Show();
		OmegaMapPlayerLower:Show();
		OmegaMapPlayerUpper:Show();
		OmegaMapPlayerLower:SetPoint("CENTER", "OmegaMapDetailFrame", "TOPLEFT", playerX, playerY);
		OmegaMapPlayerUpper:SetPoint("CENTER", "OmegaMapDetailFrame", "TOPLEFT", playerX, playerY);
		UpdateWorldMapArrow(OmegaMapPlayerLower.icon);
		UpdateWorldMapArrow(OmegaMapPlayerUpper.icon);
		OmegaMapPing:SetPoint("CENTER", "OmegaMapDetailFrame", "TOPLEFT", playerX, playerY);
--[[
		--OmegaMapPlayer:SetPoint("CENTER", "OmegaMapDetailFrame", "TOPLEFT", playerX, playerY);
		local angle = GetPlayerFacing() + 2.356;
		local cos, sin = math.cos(angle), math.sin(angle);
		OM_pArrow:SetTexCoord(	0.5-sin, 0.5+cos,
							0.5+cos, 0.5+sin,
							0.5-cos, 0.5-sin,
							0.5+sin, 0.5-cos);

		-- Position player ping if its shown
		if ( OmegaMapPing:IsShown() ) then
			OmegaMapPing:SetPoint("CENTER", activeFrame, "TOPLEFT", playerX, playerY);
			--UIFrameFlash(OmegaMapPing, 0.25, 0.25, 20, false, 0.15, 0.15);
			OM_Fader.FrameFlash(OmegaMapPing, 0.25, 0.25, 6, false, 0.15, 0.15);
			-- If ping has a timer greater than 0 count it down, otherwise fade it out

		end
		]]--
	end

	--Position groupmates
	if ( IsInRaid() ) then
		for i=1, MAX_PARTY_MEMBERS do
			local partyMemberFrame = _G["OmegaMapParty"..i];
			partyMemberFrame:Hide();
		end
		for i=1, MAX_RAID_MEMBERS do
			local unit = "raid"..i;
			local partyX, partyY = OmegaMapOffsetAltMapCoords(GetPlayerMapPosition(unit));
			local partyMemberFrame = _G["OmegaMapRaid"..i];
			if ( (partyX == 0 and partyY == 0) or UnitIsUnit(unit, "player") ) then
				partyMemberFrame:Hide();
			else
				partyX = partyX * activeFrame:GetWidth();
				partyY = -partyY * activeFrame:GetHeight();
				partyMemberFrame:SetPoint("CENTER", activeFrame, "TOPLEFT", partyX, partyY);
				local class = select(2, UnitClass(unit));
				if ( class ) then
					if ( UnitInParty(unit) ) then
						partyMemberFrame.icon:SetTexCoord(
							BLIP_TEX_COORDS[class][1],
							BLIP_TEX_COORDS[class][2],
							BLIP_TEX_COORDS[class][3],
							BLIP_TEX_COORDS[class][4]
						);
					else
						partyMemberFrame.icon:SetTexCoord(
							BLIP_TEX_COORDS[class][1],
							BLIP_TEX_COORDS[class][2],
							BLIP_TEX_COORDS[class][3] + BLIP_RAID_Y_OFFSET,
							BLIP_TEX_COORDS[class][4] + BLIP_RAID_Y_OFFSET
						);
					end
				end
				partyMemberFrame.name = nil;
				partyMemberFrame.unit = unit;
				partyMemberFrame:Show();
			end
		end
	else
		for i=1, MAX_RAID_MEMBERS do
			local partyMemberFrame = _G["OmegaMapRaid"..i];
			partyMemberFrame:Hide();
		end
		for i=1, MAX_PARTY_MEMBERS do
			local unit = "party"..i;
			local partyX, partyY = OmegaMapOffsetAltMapCoords(GetPlayerMapPosition(unit));
			local partyMemberFrame = _G["OmegaMapParty"..i];
			if ( partyX == 0 and partyY == 0 ) then
				partyMemberFrame:Hide();
			else
				partyX = partyX * activeFrame:GetWidth();
				partyY = -partyY * activeFrame:GetHeight();
				partyMemberFrame:SetPoint("CENTER", activeFrame, "TOPLEFT", partyX, partyY);
				local class = select(2, UnitClass(unit));
				if ( class ) then
					partyMemberFrame.icon:SetTexCoord(
						BLIP_TEX_COORDS[class][1],
						BLIP_TEX_COORDS[class][2],
						BLIP_TEX_COORDS[class][3],
						BLIP_TEX_COORDS[class][4]
					);
				end
				partyMemberFrame:Show();
			end
		end
	end

	-- Position flags
	local numFlags = GetNumBattlefieldFlagPositions();
	for i=1, numFlags do
		local flagX, flagY, flagToken = OmegaMapOffsetAltMapCoords(GetBattlefieldFlagPosition(i));
		local flagFrameName = "OmegaMapFlag"..i;
		local flagFrame = _G[flagFrameName];
		if ( flagX == 0 and flagY == 0 ) then
			flagFrame:Hide();
		else
			flagX = flagX * activeFrame:GetWidth();
			flagY = -flagY * activeFrame:GetHeight();
			flagFrame:SetPoint("CENTER", activeFrame, "TOPLEFT", flagX, flagY);
			local flagTexture = _G[flagFrameName.."Texture"];
			flagTexture:SetTexture("Interface\\WorldStateFrame\\"..flagToken);
			flagFrame:Show();
		end
	end
	for i=numFlags+1, NUM_OMEGAMAP_FLAGS do
		local flagFrame = _G["OmegaMapFlag"..i];
		flagFrame:Hide();
	end

	-- Position corpse
	local corpseX, corpseY = OmegaMapOffsetAltMapCoords(GetCorpseMapPosition());
	if ( corpseX == 0 and corpseY == 0 ) then
		OmegaMapCorpse:Hide();
	else
		corpseX = corpseX * activeFrame:GetWidth();
		corpseY = -corpseY * activeFrame:GetHeight();
		
		OmegaMapCorpse:SetPoint("CENTER", activeFrame, "TOPLEFT", corpseX, corpseY);
		OmegaMapCorpse:Show();
	end

	-- Position Death Release marker
	local deathReleaseX, deathReleaseY = OmegaMapOffsetAltMapCoords(GetDeathReleasePosition());
	if ((deathReleaseX == 0 and deathReleaseY == 0) or UnitIsGhost("player")) then
		OmegaMapDeathRelease:Hide();
	else
		deathReleaseX = deathReleaseX * activeFrame:GetWidth();
		deathReleaseY = -deathReleaseY * activeFrame:GetHeight();
		
		OmegaMapDeathRelease:SetPoint("CENTER", activeFrame, "TOPLEFT", deathReleaseX, deathReleaseY);
		OmegaMapDeathRelease:Show();
	end
	
	-- position vehicles
	local numVehicles;
	--if ( (GetCurrentMapContinent() ~= -1 and GetCurrentMapZone() == 0) ) then
	if ( GetCurrentMapContinent() == WORLDMAP_WORLD_ID or (GetCurrentMapContinent() ~= -1 and GetCurrentMapZone() == 0) ) then

		-- Hide vehicles on the worldmap and continent maps
		numVehicles = 0;
	else
		numVehicles = GetNumBattlefieldVehicles();
	end
	local totalVehicles = #OMEGAMAP_VEHICLES;
	local playerBlipFrameLevel = WorldMapRaid1:GetFrameLevel();
	local index = 0;
	for i=1, numVehicles do
		if (i > totalVehicles) then
			local vehicleName = "OmegaMapVehicles"..i;
			OMEGAMAP_VEHICLES[i] = CreateFrame("FRAME", vehicleName, OmegaMapButton, "OmegaMapVehicleTemplate");
			OMEGAMAP_VEHICLES[i].texture = _G[vehicleName.."Texture"];
		end
		local vehicleX, vehicleY, unitName, isPossessed, vehicleType, orientation, isPlayer, isAlive = OmegaMapOffsetAltMapCoords( GetBattlefieldVehicleInfo(i));
		if ( vehicleX and isAlive and not isPlayer and VEHICLE_TEXTURES[vehicleType]) then
			--print("VF")
			local mapVehicleFrame = OMEGAMAP_VEHICLES[i];
			vehicleX = vehicleX * activeFrame:GetWidth();
			vehicleY = -vehicleY * activeFrame:GetHeight();
			mapVehicleFrame.texture:SetRotation(orientation);
			mapVehicleFrame.texture:SetTexture(WorldMap_GetVehicleTexture(vehicleType, isPossessed));
			mapVehicleFrame:SetPoint("CENTER", activeFrame, "TOPLEFT", vehicleX, vehicleY);
			mapVehicleFrame:SetWidth(VEHICLE_TEXTURES[vehicleType].width);
			mapVehicleFrame:SetHeight(VEHICLE_TEXTURES[vehicleType].height);
			mapVehicleFrame.name = unitName;
			if ( VEHICLE_TEXTURES[vehicleType].belowPlayerBlips ) then
				mapVehicleFrame:SetFrameLevel(playerBlipFrameLevel - 1);
			else
				mapVehicleFrame:SetFrameLevel(playerBlipFrameLevel + 1);
			end
			mapVehicleFrame:Show();
			index = i;	-- save for later

		else
			OMEGAMAP_VEHICLES[i]:Hide();
			--print("VH")

		end
	end
	if (index < totalVehicles) then
		for i=index+1, totalVehicles do
			OMEGAMAP_VEHICLES[i]:Hide();
		end
	end
end

function OmegaMapPing_OnPlay(self)
	OmegaMapPing:Show();
	self.loopCount = 0;
end
function OmegaMapPing_OnLoop(self, loopState)
	self.loopCount = self.loopCount + 1;
	if ( self.loopCount >= 3 ) then
		self:Stop();
	end
end

function OmegaMapPing_OnStop(self)
	OmegaMapPing:Hide();
end

function OmegaMap_GetVehicleTexture(vehicleType, isPossessed)
	if ( not vehicleType ) then
		return;
	end
	if ( not isPossessed ) then
		isPossessed = 1;
	else
		isPossessed = 2;
	end
	if ( not VEHICLE_TEXTURES[vehicleType]) then
		return;
	end
	return VEHICLE_TEXTURES[vehicleType][isPossessed];
end

function OmegaMap_LoadTextures()
end

function OmegaMap_ClearTextures()
	for i=1, NUM_OMEGAMAP_OVERLAYS do
		_G["OmegaMapOverlay"..i]:SetTexture(nil);
	end
	local numOfDetailTiles = GetNumberOfDetailTiles();
	for i=1, numOfDetailTiles do
		--_G["OmegaMapFrameTexture"..i]:SetTexture(nil);
		_G["OmegaMapDetailTile"..i]:SetTexture(nil);
	end

end


function OmegaMapUnit_OnLoad(self)
	self:SetFrameLevel(self:GetFrameLevel() + 1);
end

function OmegaMapUnit_OnEnter(self, motion)
	OmegaMapPOIFrame.allowBlobTooltip = false;
	-- Adjust the tooltip based on which side the unit button is on
	local x, y = self:GetCenter();
	local parentX, parentY = self:GetParent():GetCenter();
	if ( x > parentX ) then
		OmegaMapTooltip:SetOwner(self, "ANCHOR_LEFT");
	else
		OmegaMapTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end

	-- See which POI's are in the same region and include their names in the tooltip
	local unitButton;
	local newLineString = "";
	local tooltipText = "";

	-- Check player
	if ( OmegaMapPlayerUpper:IsMouseOver() ) then

		if ( PlayerIsPVPInactive(OmegaMapPlayerUpper.unit) ) then
			tooltipText = format(PLAYER_IS_PVP_AFK, UnitName(OmegaMapPlayerUpper.unit));
		else
			tooltipText = UnitName(OmegaMapPlayerUpper.unit);
		end
		newLineString = "\n";
	end
	-- Check party
	for i=1, MAX_PARTY_MEMBERS do
		unitButton = _G["OmegaMapParty"..i];
		if ( unitButton:IsVisible() and unitButton:IsMouseOver() ) then
			if ( PlayerIsPVPInactive(unitButton.unit) ) then
				tooltipText = tooltipText..newLineString..format(PLAYER_IS_PVP_AFK, UnitName(unitButton.unit));
			else
				tooltipText = tooltipText..newLineString..UnitName(unitButton.unit);
			end
			newLineString = "\n";
		end
	end
	-- Check Raid
	for i=1, MAX_RAID_MEMBERS do
		unitButton = _G["OmegaMapRaid"..i];
		if ( unitButton:IsVisible() and unitButton:IsMouseOver() ) then
			if ( unitButton.name ) then
				-- Handle players not in your raid or party, but on your team
				if ( PlayerIsPVPInactive(unitButton.name) ) then
					tooltipText = tooltipText..newLineString..format(PLAYER_IS_PVP_AFK, unitButton.name);
				else
					tooltipText = tooltipText..newLineString..unitButton.name;		
				end
			else
				if ( PlayerIsPVPInactive(unitButton.unit) ) then
					tooltipText = tooltipText..newLineString..format(PLAYER_IS_PVP_AFK, UnitName(unitButton.unit));
				else
					tooltipText = tooltipText..newLineString..UnitName(unitButton.unit);
				end
			end
			newLineString = "\n";
		end
	end
	-- Check Vehicles
	local numVehicles = GetNumBattlefieldVehicles();
	for _, v in pairs(OMEGAMAP_VEHICLES) do
		if ( v:IsVisible() and v:IsMouseOver() ) then
			if ( v.name ) then
				tooltipText = tooltipText..newLineString..v.name;
			end
			newLineString = "\n";
		end
	end
	OmegaMapTooltip:SetText(tooltipText);
	OmegaMapTooltip:Show();
end

function OmegaMapUnit_OnLeave(self, motion)
	OmegaMapPOIFrame.allowBlobTooltip = true;
	OmegaMapTooltip:Hide();
end

function OmegaMapUnit_OnEvent(self, event, ...)
	if ( event == "UNIT_AURA" ) then
		if ( self.unit ) then
			local unit = ...;
			if ( self.unit == unit ) then
				OmegaMapUnit_Update(self);
			end
		end
	end
end

function OmegaMapUnit_OnMouseUp(self, mouseButton, raidUnitPrefix, partyUnitPrefix)
	if ( GetCVar("enablePVPNotifyAFK") == "0" ) then
		return;
	end

	if ( mouseButton == "RightButton" ) then
		BAD_BOY_COUNT = 0;

		local inInstance, instanceType = IsInInstance();
		if ( instanceType == "pvp" ) then
			--Check Raid
			local unitButton;
			for i=1, MAX_RAID_MEMBERS do
				unitButton = _G[raidUnitPrefix..i];
				if ( unitButton.unit and unitButton:IsVisible() and unitButton:IsMouseOver() and
					 not PlayerIsPVPInactive(unitButton.unit) ) then
					BAD_BOY_COUNT = BAD_BOY_COUNT + 1;
					BAD_BOY_UNITS[BAD_BOY_COUNT] = unitButton.unit;
				end
			end
			if ( BAD_BOY_COUNT > 0 ) then
				-- Check party
				for i=1, MAX_PARTY_MEMBERS do
					unitButton = _G[partyUnitPrefix..i];
					if ( unitButton.unit and unitButton:IsVisible() and unitButton:IsMouseOver() and
						 not PlayerIsPVPInactive(unitButton.unit) ) then
						BAD_BOY_COUNT = BAD_BOY_COUNT + 1;
						BAD_BOY_UNITS[BAD_BOY_COUNT] = unitButton.unit;
					end
				end
			end
		end

		if ( BAD_BOY_COUNT > 0 ) then
			UIDropDownMenu_Initialize( OmegaMapUnitDropDown, OmegaMapUnitDropDown_Initialize, "MENU");
			ToggleDropDownMenu(1, nil, OmegaMapUnitDropDown, self:GetName(), 0, -5);
		end
	end
end

function OmegaMapUnit_OnShow(self)
	self:RegisterEvent("UNIT_AURA");
	OmegaMapUnit_Update(self);

end

function OmegaMapUnit_OnHide(self)
	self:UnregisterEvent("UNIT_AURA");
end

function OmegaMapUnit_Update(self)
	-- check for pvp inactivity (pvp inactivity is a debuff so make sure you call this when you get a UNIT_AURA event)
	local player = self.unit or self.name;
	if ( player and PlayerIsPVPInactive(player) ) then
		self.icon:SetVertexColor(0.5, 0.2, 0.8);
	else
		self.icon:SetVertexColor(1.0, 1.0, 1.0);
	end
end

function OmegaMapUnitDropDown_Initialize()
	local info = UIDropDownMenu_CreateInfo();
	info.text = PVP_REPORT_AFK;
	info.notClickable = 1;
	info.isTitle = 1;
	info.notCheckable = true;
	UIDropDownMenu_AddButton(info);

	if ( BAD_BOY_COUNT > 0 ) then
		for i=1, BAD_BOY_COUNT do
			info = UIDropDownMenu_CreateInfo();
			info.func = OmegaMapUnitDropDown_OnClick;
			info.arg1 = BAD_BOY_UNITS[i];
			info.text = UnitName( BAD_BOY_UNITS[i] );
			info.notCheckable = true;
			UIDropDownMenu_AddButton(info);
		end
		
		if ( BAD_BOY_COUNT > 1 ) then
			info = UIDropDownMenu_CreateInfo();
			info.func = OmegaMapUnitDropDown_ReportAll_OnClick;
			info.text = PVP_REPORT_AFK_ALL;
			info.notCheckable = true;
			UIDropDownMenu_AddButton(info);
		end
	end

	info = UIDropDownMenu_CreateInfo();
	info.text = CANCEL;
	info.notCheckable = true;
	UIDropDownMenu_AddButton(info);
end

function OmegaMapUnitDropDown_OnClick(self, unit)
	ReportPlayerIsPVPAFK(unit);
end

function OmegaMapUnitDropDown_ReportAll_OnClick()
	if ( BAD_BOY_COUNT > 0 ) then
		for i=1, BAD_BOY_COUNT do
			ReportPlayerIsPVPAFK(BAD_BOY_UNITS[i]);
		end
	end
end

function OmegaMapFrame_ResetFrameLevels()
	
OmegaMapMasterFrame:SetFrameStrata("HIGH")
	OmegaMapSpecialFrame:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL - 14);
	OmegaMapFrame:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL - 13);
	OmegaMapDetailFrame:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL - 12);
	OmegaMapBlobFrame:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL - 11);
	OmegaMapArchaeologyDigSites:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL - 11);
	OmegaMapScenarioPOIFrame:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL - 11);
	OmegaMapButton:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL - 10);
	OmegaMapQuestScrollFrame:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL - 9);
	OmegaMapPOIFrame:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL);
		OmegaMapNoteFrame:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL);
    for i=1, MAX_PARTY_MEMBERS do
        _G["OmegaMapParty"..i]:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL + 100 - 1);
    end
end

function OmegaMapQuestShowObjectives_Toggle()
	if ( not OmegaMapConfig.showObjectives ) then
		WatchFrame.showObjectives= true;
		QuestLogFrameShowMapButton:Show();		
	else
		WatchFrame.showObjectives = nil;
		WatchFrame_Update();
		QuestLogFrameShowMapButton:Hide();	
	end
end


function OmegaMapFrame_DisplayQuests(selectQuestId)
if (QuestFrame:IsShown()) then return end --Fix for clearing quest rewards when opening 
	if ( OmegaMapFrame_UpdateQuests() > 0 ) then
		-- if a quest id wasn't passed in, try to select either current supertracked quest or original supertracked (saved when map was opened)
		if ( not OmegaMapFrame_SelectQuestById(selectQuestId) and not OmegaMapFrame_SelectQuestById(GetSuperTrackedQuestID())
			and not OmegaMapFrame_SelectQuestById(WORLDMAP_SETTINGS.superTrackedQuestID) ) then
			-- quest id wasn't found on this map, select the first quest
			if ( OmegaMapQuestFrame1 ) then
				OmegaMapFrame_SelectQuestFrame(OmegaMapQuestFrame1);
			end
		end
		if not InCombatLockdown() then 

		OmegaMapBlobFrame:Show();
		end
		OmegaMapPOIFrame:Show();
		OmegaMapShowObjectivesButton:Show()
		--OmegaMapTrackQuest:Show();	
		if (OmegaMapConfig.showObjectives) then
			OmegaMapQuestScrollFrame:Show();
		else
			OmegaMapQuestScrollFrame:Hide();
		end
		--OmegaMapQuestDetailScrollFrame:Show();
		--OmegaMapQuestRewardScrollFrame:Show()
		--[[		--Used to hide the objective list, but keep POI on map
		if (OmegaMapConfig.showObjectives) and  OmegaMapDetailFrame:IsShown() then
			OmegaMapQuestScrollFrame:Show();
		else			OmegaMapShowObjectivesButton:Show();
		end --]]
	else
		if  InCombatLockdown() then 

			OmegaMapBlobFrame:DrawBlob(GetSuperTrackedQuestID(), false);
		else
			OmegaMapBlobFrame:Hide();
		end
		OmegaMapPOIFrame:Hide();
		OmegaMapTrackQuest:Hide();
		OmegaMapQuestScrollFrame:Hide()
		--OmegaMapQuestDetailScrollFrame:Hide()
		--OmegaMapQuestRewardScrollFrame:Hide()
		OmegaMapShowObjectivesButton:Hide()
	end
end

function OmegaMapFrame_SelectQuestById(questId)
	if ( not questId or questId <= 0 ) then
		return false;
	end
	local questFrame;
	for i = 1, MAX_NUM_QUESTS do
		questFrame = _G["OmegaMapQuestFrame"..i];
		if ( not questFrame ) then
			break
		elseif ( questFrame.questId == questId ) then
			OmegaMapFrame_SelectQuestFrame(questFrame);
			return true;
		end
	end
	return false;
end

function OmegaMapFrame_SetFullMapView()
	OmegaMapConfig.size = OMEGAMAP_FULLMAP_SIZE;
	OmegaMapDetailFrame:SetScale(OMEGAMAP_FULLMAP_SIZE);
	OmegaMapButton:SetScale(OMEGAMAP_FULLMAP_SIZE);
	OmegaMapFrameAreaFrame:SetScale(OMEGAMAP_FULLMAP_SIZE);
	OmegaMapDetailFrame:SetPoint("TOPLEFT", OmegaMapPositioningGuide, "TOP", -502, -69);
		
	local numOfDetailTiles = GetNumberOfDetailTiles();
	for i = numOfDetailTiles + 1, numOfDetailTiles + NUM_WORLDMAP_PATCH_TILES do
		_G["WorldMapFrameTexture"..i]:Show();
	end
	
	--OmegaMapQuestDetailScrollFrame:Hide();
	--OmegaMapQuestRewardScrollFrame:Hide();
	--OmegaMapQuestScrollFrame:Show();

	OmegaMapJournal_AddMapButtons();
	-- pet battle level size adjustment
	--OmegaMapFrameAreaPetLevels:SetFontObject("PVPInfoTextFont")
	OmegaMapFrameAreaPetLevels:SetFontObject("TextStatusBarTextLarge");
	OmegaMapPlayerLower:SetSize(PLAYER_ARROW_SIZE_FULL_NO_QUESTS,PLAYER_ARROW_SIZE_FULL_NO_QUESTS);
	OmegaMapPlayerUpper:SetSize(PLAYER_ARROW_SIZE_FULL_NO_QUESTS,PLAYER_ARROW_SIZE_FULL_NO_QUESTS);
	OmegaMapBarFrame_UpdateLayout(OmegaMapBarFrame);  
end

function OmegaMapFrame_UpdateMap(questId)
	OmegaMapFrame_Update();
	OmegaMapContinentsDropDown_Update();
	OmegaMapZoneDropDown_Update();
	OmegaMapLevelDropDown_Update();
	if ( WatchFrame.showObjectives ) then
		OmegaMapFrame_DisplayQuests(questId);
	end
end

function OmegaMapScenarioPOIFrame_OnUpdate()
	if (not OmegaMapFrame:IsVisible()) then return end

	OmegaMapScenarioPOIFrame:DrawNone();
	if(WatchFrame.showObjectives == true) then
		OmegaMapScenarioPOIFrame:DrawAll();
	end
end

function ArchaeologyDigSiteFrame_OnUpdate()
	if (not OmegaMapFrame:IsVisible()) then return end

	OmegaMapArchaeologyDigSites:DrawNone();
	local numEntries = ArchaeologyMapUpdateAll();
	for i = 1, numEntries do
		local blobID = ArcheologyGetVisibleBlobID(i);
		OmegaMapArchaeologyDigSites:DrawBlob(blobID, true);
	end
end

function OmegaMapFrame_UpdateQuests()
	local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily;
	local questId, questLogIndex, startEvent;
	local questFrame;
	local lastFrame;
	local refFrame = OmegaMapQuestFrame0;
	local questCount = 0;
	local numObjectives, requiredMoney;
	local text, _, finished;
	local playerMoney = GetMoney();
	
	local numPOINumeric = 0;
	local numPOICompleteSwap = 0;
	
	local numEntries = QuestMapUpdateAllQuests();
	OmegaMapFrame_ClearQuestPOIs();
	QuestPOIUpdateIcons();
	if ( OmegaMapQuestScrollFrame.highlightedFrame ) then
		OmegaMapQuestScrollFrame.highlightedFrame.ownPOI:UnlockHighlight();
	end
	QuestPOI_HideAllButtons("OmegaMapQuestScrollChildFrame");
	-- clear blobs
	OmegaMapBlobFrame:DrawNone();
	-- populate quest frames
	for i = 1, numEntries do
		questId, questLogIndex = QuestPOIGetQuestIDByVisibleIndex(i);
		if ( questLogIndex and questLogIndex > 0 ) then
			questCount = questCount + 1;
			title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questId, startEvent = GetQuestLogTitle(questLogIndex);
			requiredMoney = GetQuestLogRequiredMoney(questLogIndex);
			numObjectives = GetNumQuestLeaderBoards(questLogIndex);
			if ( isComplete and isComplete < 0 ) then
				isComplete = false;
			elseif ( numObjectives == 0 and playerMoney >= requiredMoney and not startEvent) then
				isComplete = true;
			end
			questFrame = OmegaMapFrame_GetQuestFrame(questCount, isComplete);
			if ( lastFrame ) then
				questFrame:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, 0);
			else
				questFrame:SetPoint("TOPLEFT", OmegaMapQuestScrollChildFrame, "TOPLEFT", 2, 0);
			end
			-- set up indexes
			questFrame.questId = questId;
			questFrame.questLogIndex = questLogIndex;
			questFrame.completed = isComplete;
			questFrame.level = level;		-- for difficulty color
			-- display map POI
			OmegaMapFrame_DisplayQuestPOI(questFrame, isComplete);
			-- set quest text
			questFrame.title:SetText(title);
			if ( IsQuestWatched(questLogIndex) ) then
				questFrame.title:SetWidth(224);
				questFrame.check:Show();
			else
				questFrame.title:SetWidth(240);
				questFrame.check:Hide();
			end
			numObjectives = GetNumQuestLeaderBoards(questLogIndex);
			if ( isComplete ) then
				numPOICompleteSwap = numPOICompleteSwap + 1;
				questFrame.objectives:SetText(GetQuestLogCompletionText(questLogIndex));
				questFrame.dashes:SetText(QUEST_DASH);
			else
				numPOINumeric = numPOINumeric + 1;
				local questText = "";
				local dashText = "";
				local reversedText;
				local numLines;
				for j = 1, numObjectives do
					local text, objectiveType, finished = GetQuestLogLeaderBoard(j, questLogIndex);
					if ( text and not finished ) then
						reversedText = ReverseQuestObjective(text, objectiveType);
						questText = questText..reversedText.."|n";
						refFrame.objectives:SetText(reversedText);
						-- need to add 1 spacing's worth to height because for n number of lines there are n-1 spacings
						numLines = (refFrame.objectives:GetHeight() + refFrame.lineSpacing) / refFrame.lineHeight;
						-- round numLines to the closest integer
						numLines = floor(numLines + 0.5);
						dashText = dashText..QUEST_DASH..string.rep("|n", numLines);
					end
				end
				if ( requiredMoney > playerMoney ) then
					questText = questText.."- "..GetMoneyString(playerMoney).." / "..GetMoneyString(requiredMoney);
					dashText = dashText..QUEST_DASH;
				end				
				questFrame.objectives:SetText(questText);
				questFrame.dashes:SetText(dashText);
			end
			questFrame.title:SetTextColor(1,1,0)
			questFrame.objectives:SetTextColor(1,1,0)
			questFrame.dashes:SetTextColor(1,1,0)
			-- difficulty
			if ( MAP_QUEST_DIFFICULTY == "1" ) then
				local color = GetQuestDifficultyColor(level);
				questFrame.title:SetTextColor(color.r, color.g, color.b);
			end
			-- size and show
			questFrame:SetHeight(max(questFrame.title:GetHeight() + questFrame.objectives:GetHeight() + QUESTFRAME_PADDING, QUESTFRAME_MINHEIGHT));
			questFrame:Show();
			lastFrame = questFrame;
		end
	end
	OmegaMapFrame.numQuests = questCount;
	-- hide frames not being used for this map
	for i = questCount + 1, MAX_NUM_QUESTS do
		questFrame = _G["OmegaMapQuestFrame"..i];
		if ( not questFrame ) then
			break;
		end		
		questFrame:Hide();
		questFrame.questId = 0;
	end
	QuestPOI_HideButtons("OmegaMapPOIFrame", QUEST_POI_NUMERIC, numPOINumeric + 1);
	QuestPOI_HideButtons("OmegaMapPOIFrame", QUEST_POI_COMPLETE_SWAP, numPOICompleteSwap + 1);
	
	OmegaMapJournal_CheckQuestButtons();
	return questCount;
end

function OmegaMapFrame_SelectQuestFrame(questFrame, userAction)
	local poiIcon;
	local color;
	-- clear current selection	
	if ( WORLDMAP_SETTINGS.selectedQuest ) then
		local currentSelection = WORLDMAP_SETTINGS.selectedQuest;
		poiIcon = currentSelection.poiIcon;
		QuestPOI_DeselectButton(poiIcon);
		QuestPOI_DeselectButtonByParent("OmegaMapQuestScrollChildFrame");
		OmegaMapBlobFrame:DrawBlob(currentSelection.questId, false);
		if ( MAP_QUEST_DIFFICULTY == "1" ) then
			color = GetQuestDifficultyColor(currentSelection.level);
			currentSelection.title:SetTextColor(color.r, color.g, color.b);
		end
		poiIcon:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL);
	end
	WORLDMAP_SETTINGS.selectedQuest = questFrame;
	-- Change the supertrackedquestID on user action
	if ( userAction ) then
		WORLDMAP_SETTINGS.superTrackedQuestID = questFrame.questId;
	end
	SetSuperTrackedQuestID(questFrame.questId);
	OmegaMapQuestSelectedFrame:SetPoint("TOPLEFT", questFrame, "TOPLEFT", -10, 0);
	OmegaMapQuestSelectedFrame:SetHeight(questFrame:GetHeight());
	OmegaMapQuestSelectedFrame:Show();
	poiIcon = questFrame.poiIcon;
	QuestPOI_SelectButton(poiIcon);
	QuestPOI_SelectButton(questFrame.ownPOI);
	poiIcon:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL + 1);
	-- colors
	if ( MAP_QUEST_DIFFICULTY == "1" ) then
		questFrame.title:SetTextColor(1, 1, 1);
		color = GetQuestDifficultyColor(questFrame.level);
		OmegaMapQuestSelectBar:SetVertexColor(color.r, color.g, color.b);
	end
	-- only display quest info if omegamap frame is embiggened
		--SelectQuestLogEntry(questFrame.questLogIndex);
		--QuestInfo_Display(QUEST_TEMPLATE_MAP1, OmegaMapQuestDetailScrollChildFrame);
		--OmegaMapQuestDetailScrollFrameScrollBar:SetValue(0);
		--ScrollFrame_OnScrollRangeChanged(OmegaMapQuestDetailScrollFrame);
		--QuestInfo_Display(QUEST_TEMPLATE_MAP2, OmegaMapQuestRewardScrollChildFrame);
		--OmegaMapQuestRewardScrollFrameScrollBar:SetValue(0);
		--ScrollFrame_OnScrollRangeChanged(OmegaMapQuestRewardScrollFrame);

	-- track quest checkbark
	OmegaMapTrackQuest:SetChecked(IsQuestWatched(questFrame.questLogIndex));
	-- quest blob
	if ( questFrame.completed ) then
		OmegaMapBlobFrame:DrawBlob(questFrame.questId, false);
	else
		OmegaMapBlobFrame:DrawBlob(questFrame.questId, true);
	end
	OmegaMap_DrawWorldEffects();
end

local numCompletedQuests = 0;
function OmegaMapFrame_ClearQuestPOIs()
	QuestPOI_HideButtons("OmegaMapPOIFrame", QUEST_POI_NUMERIC, 1);
	QuestPOI_HideButtons("OmegaMapPOIFrame", QUEST_POI_COMPLETE_IN, 1);
	numCompletedQuests = 0;
end

function OmegaMapFrame_DisplayQuestPOI(questFrame, isComplete)
	local index = questFrame.index;
	local poiButton;
	if ( isComplete ) then
		poiButton = QuestPOI_DisplayButton("OmegaMapPOIFrame", QUEST_POI_COMPLETE_IN, questFrame.completedIndex, questFrame.questId);
	else
		poiButton = QuestPOI_DisplayButton("OmegaMapPOIFrame", QUEST_POI_NUMERIC, index - numCompletedQuests, questFrame.questId);
	end
	questFrame.poiIcon = poiButton;
	local _, posX, posY, objective = QuestPOIGetIconInfo(questFrame.questId);
	if ( posX and posY ) then
		local POIscale;
		POIscale = 1;
		posX = posX * OmegaMapDetailFrame:GetWidth() * POIscale;
		posY = -posY * OmegaMapDetailFrame:GetHeight() * POIscale;
		-- keep outlying POIs within map borders
		if ( posY > OMEGAMAP_POI_MIN_Y ) then
			posY = OMEGAMAP_POI_MIN_Y;
		elseif ( posY < OMEGAMAP_POI_MAX_Y ) then
			posY = OMEGAMAP_POI_MAX_Y
		end
		if ( posX < OMEGAMAP_POI_MIN_X ) then
			posX = OMEGAMAP_POI_MIN_X;
		elseif ( posX > OMEGAMAP_POI_MAX_X ) then
			posX = OMEGAMAP_POI_MAX_X;
		end
		poiButton:SetPoint("CENTER", "OmegaMapPOIFrame", "TOPLEFT", posX, posY);
		poiButton:SetScript("OnEnter", OmegaMapQuestPOI_OnEnter);
		poiButton:SetScript("OnLeave", OmegaMapQuestPOI_OnLeave);
		poiButton:SetScript("OnClick", OmegaMapQuestPOI_OnClick)
	end
	poiButton.quest = questFrame;
end

function OmegaMapFrame_SetPOIMaxBounds()
	OMEGAMAP_POI_MAX_Y = OmegaMapDetailFrame:GetHeight() * -OmegaMapConfig.size + 12;
	OMEGAMAP_POI_MAX_X = OmegaMapDetailFrame:GetWidth() * OmegaMapConfig.size + 12;
end

function OmegaMapFrame_GetQuestFrame(index, isComplete)
	local frame = _G["OmegaMapQuestFrame"..index];
	if ( not frame ) then
		frame = CreateFrame("Frame", "OmegaMapQuestFrame"..index, OmegaMapQuestScrollChildFrame, "OmegaMapQuestFrameTemplate");
		frame.index = index;
	end
	
	local poiButton;
	if ( isComplete ) then
		numCompletedQuests = numCompletedQuests + 1;
		poiButton = QuestPOI_DisplayButton("OmegaMapQuestScrollChildFrame", QUEST_POI_COMPLETE_IN, numCompletedQuests, 0);
		frame.completedIndex = numCompletedQuests;
	else
		poiButton = QuestPOI_DisplayButton("OmegaMapQuestScrollChildFrame", QUEST_POI_NUMERIC, index - numCompletedQuests, 0);
	end
	poiButton:SetPoint("TOPLEFT", frame, 4, 0);
	frame.ownPOI = poiButton;
	return frame;
end

function OmegaMapQuestFrame_OnEnter(self)
	self.ownPOI:LockHighlight();
	OmegaMapQuestScrollFrame.highlightedFrame = self;
	if ( WORLDMAP_SETTINGS.selectedQuest == self ) then
		return;
	end
	OmegaMapQuestHighlightedFrame:SetPoint("TOPLEFT", self, "TOPLEFT", -10, -1);
	OmegaMapQuestHighlightedFrame:SetHeight(self:GetHeight() - 2);
	if ( MAP_QUEST_DIFFICULTY == "1" ) then
		local color = GetQuestDifficultyColor(self.level);
		self.title:SetTextColor(1, 1, 1);
		OmegaMapQuestHighlightBar:SetVertexColor(color.r, color.g, color.b);
	end	
	OmegaMapQuestHighlightedFrame:Show();
	if ( not self.completed ) then
		OmegaMapBlobFrame:DrawBlob(self.questId, true);
	end
end

function OmegaMapQuestFrame_OnLeave(self)
	self.ownPOI:UnlockHighlight();
	OmegaMapQuestScrollFrame.highlightedFrame = nil;
	if ( WORLDMAP_SETTINGS.selectedQuest == self ) then
		return;
	end
	if ( MAP_QUEST_DIFFICULTY == "1" ) then
		local color = GetQuestDifficultyColor(self.level);
		self.title:SetTextColor(color.r, color.g, color.b);
	end		
	OmegaMapQuestHighlightedFrame:Hide();
	if ( not self.completed ) then
		OmegaMapBlobFrame:DrawBlob(self.questId, false);
	end
end

function OmegaMapQuestFrame_OnMouseDown(self)
	self.title:SetPoint("TOPLEFT", 35, -9);
	self.ownPOI:SetButtonState("PUSHED");
	QuestPOIButton_OnMouseDown(self.ownPOI);	
end

function OmegaMapQuestFrame_OnMouseUp(self)
	self.title:SetPoint("TOPLEFT", 34, -8);
	self.ownPOI:SetButtonState("NORMAL");
	QuestPOIButton_OnMouseUp(self.ownPOI);
	if ( self:IsMouseOver() ) then
		if ( WORLDMAP_SETTINGS.selectedQuest ~= self ) then
			OmegaMapQuestHighlightedFrame:Hide();
			PlaySound("igMainMenuOptionCheckBoxOn");
		end
		OmegaMapFrame_SelectQuestFrame(self, true);
		if ( IsShiftKeyDown() ) then
			local isChecked = not OmegaMapTrackQuest:GetChecked();
			OmegaMapTrackQuest:SetChecked(isChecked);		
			OmegaMapTrackQuest_Toggle(isChecked);
			OmegaMapQuestFrame_UpdateMouseOver();			
		end		
	end
end

function OmegaMapQuestFrame_UpdateMouseOver()
	if ( OmegaMapQuestScrollFrame:IsMouseOver() ) then
		for i = 1, OmegaMapFrame.numQuests do
			local questFrame = _G["OmegaMapQuestFrame"..i];
			if ( questFrame:IsMouseOver() ) then
				OmegaMapQuestFrame_OnEnter(questFrame);
				break;
			end
		end
	end
end

function OmegaMapQuestPOI_OnClick(self)
	PlaySound("igMainMenuOptionCheckBoxOn");
	if ( self.quest ~= WORLDMAP_SETTINGS.selectedQuest ) then
		if ( WORLDMAP_SETTINGS.selectedQuest ) then
			OmegaMapBlobFrame:DrawBlob(GetSuperTrackedQuestID(), false);
		end
	end
	OmegaMapFrame_SelectQuestFrame(self.quest, true);
	if ( IsShiftKeyDown() ) then
		local isChecked = not OmegaMapTrackQuest:GetChecked();
		OmegaMapTrackQuest:SetChecked(isChecked);		
		OmegaMapTrackQuest_Toggle(isChecked);
	end
end

function OmegaMapQuestPOI_OnEnter(self)
	OmegaMapPOIFrame.allowBlobTooltip = false;
	OmegaMapQuestPOI_SetTooltip(self, self.quest.questLogIndex);	
end

function OmegaMapQuestPOI_OnLeave(self)
	OmegaMapPOIFrame.allowBlobTooltip = true;
end

function OmegaMapQuestPOI_SetTooltip(poiButton, questLogIndex, numObjectives)
	local title = GetQuestLogTitle(questLogIndex);
	OmegaMapTooltip:SetOwner(OmegaMapFrame, "ANCHOR_CURSOR_RIGHT", 5, 2);
	OmegaMapTooltip:SetText(title);
	if ( poiButton and poiButton.type == QUEST_POI_COMPLETE_SWAP ) then
		if ( poiButton.type == QUEST_POI_COMPLETE_SWAP ) then
			OmegaMapTooltip:AddLine("- "..GetQuestLogCompletionText(questLogIndex), 1, 1, 1, 1);
		else
			local numObjectives = GetNumQuestLeaderBoards(questLogIndex);
			for i = 1, numObjectives do
				local text, objectiveType, finished = GetQuestLogLeaderBoard(i, questLogIndex);
				if ( text and not finished ) then
					OmegaMapTooltip:AddLine("- "..ReverseQuestObjective(text, objectiveType), 1, 1, 1, 1);
				end
			end
		end
	else
		local text, finished, objectiveType;
		local numItemDropTooltips = GetNumQuestItemDrops(questLogIndex);
		if(numItemDropTooltips and numItemDropTooltips > 0) then
			for i = 1, numItemDropTooltips do
				text, objectiveType, finished = GetQuestLogItemDrop(i, questLogIndex);
				if ( text and not finished ) then
					OmegaMapTooltip:AddLine("- "..ReverseQuestObjective(text, objectiveType), 1, 1, 1, 1);
				end
			end
		else
			local numPOITooltips = OmegaMapBlobFrame:GetNumTooltips();
			numObjectives = numObjectives or GetNumQuestLeaderBoards(questLogIndex);
			for i = 1, numObjectives do
				if(numPOITooltips and (numPOITooltips == numObjectives)) then
					local questPOIIndex = OmegaMapBlobFrame:GetTooltipIndex(i);
					text, objectiveType, finished = GetQuestPOILeaderBoard(questPOIIndex, questLogIndex);
				else
					text, objectiveType, finished = GetQuestLogLeaderBoard(i, questLogIndex);
				end
				if ( text and not finished ) then
					OmegaMapTooltip:AddLine("- "..ReverseQuestObjective(text, objectiveType), 1, 1, 1, 1);
				end
			end		
		end
	end	
	OmegaMapTooltip:Show();
end

function OmegaMapBlobFrame_OnLoad(self)
	self:SetFillTexture("Interface\\WorldMap\\UI-QuestBlob-Inside");
	self:SetBorderTexture("Interface\\WorldMap\\UI-QuestBlob-Outside");
	self:SetFillAlpha(128);
	self:SetBorderAlpha(192);
	self:SetBorderScalar(1.0);
end

function OmegaMapBlobFrame_OnUpdate(self)
	if ( not OmegaMapPOIFrame.allowBlobTooltip or not OmegaMapDetailFrame:IsMouseOver() ) then
		return;
	end
	if ( not self.xRatio ) then
		OmegaMapBlobFrame_CalculateHitTranslations();
	end
	local x, y = GetCursorPosition();
	local adjustedX = x / self.xRatio - self.xOffset;
	local adjustedY = self.yOffset - y / self.yRatio;
	local questLogIndex, numObjectives = self:UpdateMouseOverTooltip(adjustedX, adjustedY);
	if(numObjectives) then
		OmegaMapTooltip:SetOwner(OmegaMapFrame, "ANCHOR_CURSOR");
		OmegaMapQuestPOI_SetTooltip(nil, questLogIndex, numObjectives);
	elseif(not OmegaMapTooltip.EJ_using) and (not OmegaMapTooltip.WE_using) and (not OmegaMapTooltip.MB_using) then
		OmegaMapTooltip:Hide();
	end
end

function OmegaMapBlobFrame_CalculateHitTranslations()
	local self = OmegaMapBlobFrame;
	local centerX, centerY = self:GetCenter();
	local width = self:GetWidth();
	local height = self:GetHeight();
	local scale = self:GetEffectiveScale();
	self.yOffset = centerY / height + 0.5;
	self.yRatio = height * scale;
	self.xOffset = centerX / width - 0.5;
	self.xRatio = width * scale;
end

function OmegaMapFrame_ResetQuestColors()
	if ( MAP_QUEST_DIFFICULTY == "0" ) then
		OmegaMapQuestSelectBar:SetVertexColor(1, 0.824, 0);
		OmegaMapQuestHighlightBar:SetVertexColor(0.243, 0.570, 1);
		for i = 1, MAX_NUM_QUESTS do
			local questFrame = _G["OmegaMapQuestFrame"..i];
			if ( not questFrame ) then
				break;
			end
			questFrame.title:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
		end
	end
end

function OmegaMap_OpenToQuest(questID, frameToShowOnClose)
	OmegaMapFrame.blockOmegaMapUpdate = true;
	ShowUIPanel(OmegaMapFrame);	
	local mapID, floorNumber = GetQuestOmegaMapAreaID(questID);
	if ( mapID ~= 0 ) then
		SetMapByID(mapID);
		if ( floorNumber ~= 0 ) then
			SetDungeonMapLevel(floorNumber);
		end
	end
	OmegaMapFrame.blockOmegaMapUpdate = nil;
	OmegaMapFrame_UpdateMap(questID);	
end


--- advanced options ---
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
	-- set map alpha
	--alpha = 0.35 + (1.0 - opacity) * 0.65;
	alpha = (1.0 - opacity);

	OmegaMapDetailFrame:SetAlpha(alpha);
	if OmegaMapAltMapFrame then
		OmegaMapAltMapFrame:SetAlpha(alpha);
	end
	OmegaMapNoteFrame:SetAlpha(alpha);
	-- set blob alpha
	alpha = 0.65 + (1.0 - opacity) * 0.55;
	

	--OmegaMapPOIFrame:SetAlpha(alpha);
	OmegaMapBlobFrame:SetFillAlpha(128 * alpha);
	OmegaMapBlobFrame:SetBorderAlpha(192 * alpha);
	OmegaMapArchaeologyDigSites:SetFillAlpha(128 * alpha);
	OmegaMapArchaeologyDigSites:SetBorderAlpha(192 * alpha);
	--OmegaMapBossButtonFrame:SetAlpha(alpha);
end

function OmegaMapTrackQuest_Toggle(isChecked)
	local questIndex = WORLDMAP_SETTINGS.selectedQuest.questLogIndex;
	local questId = GetSuperTrackedQuestID();
	if ( isChecked ) then
		if ( GetNumQuestWatches() > MAX_WATCHABLE_QUESTS ) then
			UIErrorsFrame:AddMessage(format(QUEST_WATCH_TOO_MANY, MAX_WATCHABLE_QUESTS), 1.0, 0.1, 0.1, 1.0);
			OmegaMapTrackQuest:SetChecked(false);
			return;
		end
		if ( LOCAL_MAP_QUESTS["zone"] == GetCurrentMapZone() ) then
			LOCAL_MAP_QUESTS[questId] = true;
		end
		AddQuestWatch(questIndex);	
	else
		LOCAL_MAP_QUESTS[questId] = nil
		RemoveQuestWatch(questIndex);
	end
	WatchFrame_Update();
	OmegaMapFrame_DisplayQuests(questId);
end


--- For EJ boss butons
function OmegaMapJournal_AddMapButtons()
	local left = OmegaMapBossButtonFrame:GetLeft();
	local right = OmegaMapBossButtonFrame:GetRight();
	local top = OmegaMapBossButtonFrame:GetTop();
	local bottom = OmegaMapBossButtonFrame:GetBottom();

	if not left or not right or not top or not bottom then
		--This frame is resizing
		OmegaMapBossButtonFrame.ready = false;
		OmegaMapBossButtonFrame:SetScript("OnUpdate", OmegaMapJournal_AddMapButtons);
		return;
	else
		OmegaMapBossButtonFrame:SetScript("OnUpdate", nil);
	end
	
	local scale = OmegaMapDetailFrame:GetScale();
	local width = OmegaMapDetailFrame:GetWidth() * scale;
	local height = OmegaMapDetailFrame:GetHeight() * scale;
	local bossButton, questPOI, displayInfo, _;
	local index = 1;
	local x, y, instanceID, name, description, encounterID = EJ_GetMapEncounter(index);
	while name do
		bossButton = _G["EJOmegaMapButton"..index];
		if not bossButton then -- create button
			bossButton = CreateFrame("Button", "EJOmegaMapButton"..index, OmegaMapBossButtonFrame, "OmegaMapEncounterButtonTemplate");
	end
	
	bossButton.instanceID = instanceID;
	bossButton.encounterID = encounterID;
	bossButton.tooltipTitle = name;
	bossButton.tooltipText = description;
	bossButton:SetPoint("CENTER", OmegaMapBossButtonFrame, "BOTTOMLEFT", x*width, y*height);
	local _, _, _, displayInfo = EJ_GetCreatureInfo(1, encounterID);
	bossButton.displayInfo = displayInfo;
	if ( displayInfo ) then
			SetPortraitTexture(bossButton.bgImage, displayInfo);
		else 
			bossButton.bgImage:SetTexture("DoesNotExist");
		end

	bossButton:Show();
	  -- bossButton:SetFrameLevel(100 - 5);
	index = index + 1;
	x, y, instanceID, name, description, encounterID = EJ_GetMapEncounter(index);

	end

 --   if (index == 1) then --not looking at dungeon map
		--OmegaMapQuestShowObjectives:Show();
		--OmegaMapShowDropDown:Hide();
	--else
	---- OmegaMapQuestShowObjectives:Hide();
	--   OmegaMapShowDropDown:Show();
	--end
	OmegaMapFrame.hasBosses = index ~= 1;
	if (not GetCVarBool("showBosses")) then
		index = 1;
	end
	
	bossButton = _G["EJOmegaMapButton"..index];
	while bossButton do
		bossButton:Hide();
		index = index + 1;
		bossButton = _G["EJOmegaMapButton"..index];
	end
	
	OmegaMapBossButtonFrame.ready = true;
	OmegaMapJournal_CheckQuestButtons();
	
end

--- For EJ boss butons	
function OmegaMapJournal_UpdateMapButtonPortraits()
	if ( OmegaMapFrame:IsShown() ) then
		local index = 1;
		local bossButton = _G["EJOmegaMapButton"..index];
		while ( bossButton and bossButton:IsShown() ) do
			SetPortraitTexture(bossButton.bgImage, bossButton.displayInfo);
			index = index + 1;
			bossButton = _G["EJOmegaMapButton"..index];
		end
	end
end

--- For EJ boss butons	
function OmegaMapJournal_CheckQuestButtons()
	if not OmegaMapBossButtonFrame.ready then
		return;
	end

	--Validate that there are no quest button intersection
	local questI, bossI = 1, 1;
	local bossButton = _G["EJOmegaMapButton"..bossI];
	local questPOI = _G["poiOmegaMapPOIFrame1_"..questI];
	while bossButton and bossButton:IsShown() do
		while questPOI and questPOI:IsShown() do
			local qx,qy = questPOI:GetCenter();
			local bx,by = bossButton:GetCenter();
			if not qx or not qy or not bx or not by then
				_G["EJOmegaMapButton1"]:SetScript("OnUpdate", OmegaMapJournal_CheckQuestButtons);
				return;
			end
			 
			local xdis = abs(bx-qx);
			local ydis = abs(by-qy);
			local disSqr = xdis*xdis + ydis*ydis;
			 
			if EJ_QUEST_POI_MINDIS_SQR > disSqr then
				questPOI:SetPoint("CENTER", bossButton, "BOTTOMRIGHT",  -15, 15);
			end
			questI = questI + 1;
			questPOI = _G["poiOmegaMapPOIFrame1_"..questI];
		end
		questI = 1;
		bossI = bossI + 1;
		bossButton = _G["EJOmegaMapButton"..bossI];
		questPOI = _G["poiOmegaMapPOIFrame1_"..questI];
	end
	if _G["EEJOmegaMapButton1"] then
		_G["EJOmegaMapButton1"]:SetScript("OnUpdate", nil);
	end

end

-- functions to deal with map options dropdown that shows up when looking at a dungeon map
function OmegaMapShowDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, OmegaMapShowDropDown_Initialize);
	UIDropDownMenu_SetText(self, MAP_OPTIONS_TEXT);
	UIDropDownMenu_SetWidth(self, 150);
end


function OmegaMapShowDropDown_Initialize()
	local info = UIDropDownMenu_CreateInfo();
	-- Show quests button
	info.text = SHOW_QUEST_OBJECTIVES_ON_MAP_TEXT;
	info.value = "quests";
	info.func = OmegaMapShowDropDown_OnClick;
	info.checked = GetCVarBool("questPOI");
	info.isNotRadio = true;
	info.keepShownOnClick = 1;
	UIDropDownMenu_AddButton(info);

	-- Show bosses button
	info.text = SHOW_BOSSES_ON_MAP_TEXT;
	info.value = "bosses";
	info.func = OmegaMapShowDropDown_OnClick;
	info.checked = GetCVarBool("showBosses");
	info.isNotRadio = true;
	info.keepShownOnClick = 1
	info.tooltipText = OPTION_TOOLTIP_SHOW_QUEST_OBJECTIVES_ON_MAP;
	info.tooltipOnButton = OPTION_TOOLTIP_SHOW_QUEST_OBJECTIVES_ON_MAP;
	UIDropDownMenu_AddButton(info);
	if (WorldMapFrame.hasBosses) then
		-- Show bosses button
		info.text = SHOW_BOSSES_ON_MAP_TEXT;
		info.value = "bosses";
		info.func = OmegaMapShowDropDown_OnClick;
		info.checked = GetCVarBool("showBosses");
		info.isNotRadio = true;
		info.keepShownOnClick = 1;
		info.tooltipText = OPTION_TOOLTIP_SHOW_BOSSES_ON_MAP;
		info.tooltipOnButton = OPTION_TOOLTIP_SHOW_BOSSES_ON_MAP;
		UIDropDownMenu_AddButton(info);
	else
		local _, _, arch = GetProfessions();
		if arch then
			local showDig = GetCVarBool("digSites");

			-- Show bosses button
			info.text = ARCHAEOLOGY_SHOW_DIG_SITES;
			info.value = "digsites";
			info.func = OmegaMapShowDropDown_OnClick;
			info.checked = showDig;
			info.isNotRadio = true;
			info.keepShownOnClick = 1;
			info.tooltipText = OPTION_TOOLTIP_SHOW_DIG_SITES_ON_MAP;
			info.tooltipOnButton = OPTION_TOOLTIP_SHOW_DIG_SITES_ON_MAP;
			UIDropDownMenu_AddButton(info);
			if showDig then
				OmegaMapArchaeologyDigSites:Show();
			else
				OmegaMapArchaeologyDigSites:Hide();
			end
		end
		
		local showTamers = GetCVarBool("showTamers");
		
		-- Show tamers button
		if (CanTrackBattlePets()) then
			info.text = SHOW_BATTLE_PET_TAMERS_ON_MAP_TEXT;
			info.value = "tamers";
			info.func = OmegaMapShowDropDown_OnClick;
			info.checked = showTamers;
			info.isNotRadio = true;
			info.keepShownOnClick = 1;
			info.tooltipText = OPTION_TOOLTIP_SHOW_BATTLE_PET_TAMERS_ON_MAP;
			info.tooltipOnButton = OPTION_TOOLTIP_SHOW_BATTLE_PET_TAMERS_ON_MAP;
			UIDropDownMenu_AddButton(info);
		end
	end

end


function OmegaMapShowDropDown_OnClick(self)
	local checked = self.checked;
	local value = self.value;
	
	if (checked) then
		PlaySound("igMainMenuOptionCheckBoxOn");
	else
		PlaySound("igMainMenuOptionCheckBoxOff");
	end
	
	if (value == "quests") then
		SetCVar("questPOI", checked and "1" or "0");
		WatchFrame.showObjectives = checked;
		if (checked) then
			QuestLogFrameShowMapButton:Show();
		else
			QuestLogFrameShowMapButton:Hide();
			WatchFrame_Update();
		end
		OmegaMapFrame_DisplayQuests();
		OmegaMapFrame_Update();
	elseif (value == "bosses") then
		SetCVar("showBosses", checked and "1" or "0");
		OmegaMapFrame_Update();
	elseif (value == "digsites") then
		if (checked) then
			OmegaMapArchaeologyDigSites:Show();
		else
			OmegaMapArchaeologyDigSites:Hide();
		end
		SetCVar("digSites", checked and "1" or "0");
		OmegaMapFrame_Update();
	elseif (value == "tamers") then
		SetCVar("showTamers", checked and "1" or "0");
		OmegaMapFrame_Update();
	end
end

---  New Functions
function OmegaMapToggle()
	if ( OmegaMapFrame:IsVisible() ) then
		OmegaMapFrame:Hide()
		OmegaMapBlobFrame:DrawBlob(GetSuperTrackedQuestID(), false);
		OmegaMapArchaeologyDigSites:DrawNone();
		local numEntries = ArchaeologyMapUpdateAll();
		for i = 1, numEntries do
			local blobID = ArcheologyGetVisibleBlobID(i);
			OmegaMapArchaeologyDigSites:DrawBlob(blobID, false);
		end
	else
		OmegaMapFrame:Show()
	end
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
		OmegaMapButton:EnableMouse(false);
		OmegaMapMovementFrameTop:Hide();
		OmegaMapMovementFrameTop:EnableMouse(false)
		OmegaMapMovementFrameBottom:Hide();
		OmegaMapMovementFrameBottom:EnableMouse(false)
	elseif (state == "On") then
		OmegaMapButton:EnableMouse(true);
		--OmegaMapConfig.solidify = true
		OmegaMapMovementFrameTop:Show();
		OmegaMapMovementFrameTop:EnableMouse(true)
		OmegaMapMovementFrameBottom:Show();
		OmegaMapMovementFrameBottom:EnableMouse(true)
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
			local pX, pY = GetPlayerMapPosition("player");
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

			--OmegaMapSetCoordsPos();
		end
	end
end

function OmegaMapSetCoordsPos()
	local x, y = OmegaMapConfig.coordsLocX, OmegaMapConfig.coordsLocY;

	local UnitScale = .8;
--[[
	OmegaMapCoordinates:ClearAllPoints();
	OmegaMapCoordinates:SetUserPlaced(0);
	OmegaMapCoordinates:SetParent(OmegaMapFrame);
	OmegaMapCoordinates:SetScale( UnitScale );
	OmegaMapCoordinates:SetPoint("CENTER", "OmegaMapFrame", "BOTTOMLEFT", x / UnitScale, y / UnitScale);
	OmegaMapCoordinates:SetFrameLevel( OmegaMapFrame:GetFrameLevel() + 3);
	OmegaMapCoordinates:Show();
	if ( not OmegaMapConfig.showCoords ) then
		OmegaMapCoordinates:Hide();
	end
	]]--
end

--Gets coords of cursor in relation to its positon over the map
function OmegaMapGetCLoc()
	local x, y = nil, nil;
	local activeFrame = nil

	if (OmegaMapAltMapFrame:IsShown()) then
		activeFrame = OmegaMapAltMapFrame
	else 
		activeFrame = OmegaMapDetailFrame
	end

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




