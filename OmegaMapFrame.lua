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




NUM_OMEGAMAP_POI_COLUMNS = 14;
OMEGAMAP_POI_TEXTURE_WIDTH = 256;


NUM_OMEGAMAP_POIS = 0;
NUM_OMEGAMAP_WORLDEFFECT_POIS = 0;
NUM_OMEGAMAP_SCENARIO_POIS = 0;
NUM_OMEGAMAP_TASK_POIS = 0;
NUM_OMEGAMAP_GRAVEYARDS = 0;
NUM_OMEGAMAP_OVERLAYS = 0;
NUM_OMEGAMAP_FLAGS = 4;




--QUESTFRAME_MINHEIGHT = 34;
--QUESTFRAME_PADDING = 19;			-- needs to be one the highest frames in the MEDIUM strata
OMEGAMAP_FULLMAP_SIZE = 1.0;
OMEGAMAP_POI_FRAMELEVEL = 100;	-- needs to be one the highest frames in the MEDIUM strata

OMEGAMAP_ALTMAP = false
OMEGAMAP_QUEST_BONUS_OBJECTIVE = 49;
local EJ_QUEST_POI_MINDIS_SQR = 2500;

local QUEST_POI_FRAME_INSET = 12;		-- roughly half the width/height of a POI icon
local QUEST_POI_FRAME_WIDTH;
local QUEST_POI_FRAME_HEIGHT;

local OMEGAMAP_DEFAULT_SCALE = .75;

local PLAYER_ARROW_SIZE_WINDOW = 40;
local PLAYER_ARROW_SIZE_FULL_WITH_QUESTS = 38;
local PLAYER_ARROW_SIZE_FULL_NO_QUESTS = 28;

local STORYLINE_FRAMES = { };

local incombat = false
--local playercombatclose = false

OmegaMapPins = {}
OMEGAMAP_VEHICLES = {};

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


--function OmegaMapToggle()
function ToggleOmegaMap()
	if ( OmegaMapFrame:IsVisible() ) then
		OmegaMapFrame:Hide()
		--OmegaMapBlobFrame:DrawNone();
		--OmegaMapBlobFrame:DrawBlob(GetSuperTrackedQuestID(), false);
		--[[OmegaMapArchaeologyDigSites:DrawNone();
		local numEntries = ArchaeologyMapUpdateAll();
		for i = 1, numEntries do
			local blobID = ArcheologyGetVisibleBlobID(i);
			OmegaMapArchaeologyDigSites:DrawBlob(blobID, false);
		end
		]]--
	else
		OmegaMapFrame:Show()
		OmegaMapQuestFrame:Show()
		if OmegaMapConfig.showQuestList then
			OmegaMapQuestFrame_Show()
			OmegaMapFrame.UIElementsFrame.CloseQuestPanelButton:Show();
		else
			OmegaMapQuestFrame_Hide()
			OmegaMapFrame.UIElementsFrame.OpenQuestPanelButton:Show();
		end
	end
end

function OmegaMapFrame_OnLoad(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("WORLD_MAP_UPDATE");
	self:RegisterEvent("CLOSE_WORLD_MAP");
	self:RegisterEvent("VARIABLES_LOADED");
	self:RegisterEvent("GROUP_ROSTER_UPDATE");
	self:RegisterEvent("DISPLAY_SIZE_CHANGED");
	self:RegisterEvent("REQUEST_CEMETERY_LIST_RESPONSE");
	self:RegisterEvent("UNIT_PORTRAIT_UPDATE");
	self:RegisterEvent("ARTIFACT_DIG_SITE_UPDATED");
	--new 6.0
	self:RegisterEvent("SUPER_TRACKED_QUEST_CHANGED");
	self:RegisterEvent("PLAYER_STARTED_MOVING");
	self:RegisterEvent("PLAYER_STOPPED_MOVING");
	self:RegisterEvent("QUESTLINE_UPDATE");
	self:RegisterEvent("QUEST_LOG_UPDATE");
	self:RegisterEvent("QUESTTASK_UPDATE");
	-- added events
	self:RegisterEvent("MODIFIER_STATE_CHANGED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")

	self:SetClampRectInsets(0, 0, 0, -60);-- don't overlap the xp/rep bars
	self.poiHighlight = nil;
	self.areaName = nil;
	OmegaMapFrame_Update();

	-- setup the zone minimap button
	OmegaMapLevelDropDown_Update();

	local homeData = {
		name = WORLD,
		OnClick = OmegaMapNavBar_OnButtonSelect,
		listFunc = OmegaMapNavBar_GetSibling,
		id = WORLDMAP_COSMIC_ID,
		isContinent = true,
	}


	NavBar_Initialize(self.NavBar, "NavButtonTemplate", homeData, self.navBar.home, self.navBar.overflow);

	--ButtonFrameTemplate_HidePortrait(OmegaMapFrame.BorderFrame);
	--OmegaMapFrame.BorderFrame.TitleText:SetText(MAP_AND_QUEST_LOG);
	--OmegaMapFrame.BorderFrame.portrait:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon");
	--OmegaMapFrame.BorderFrame.CloseButton:SetScript("OnClick", function() HideUIPanel(OmegaMapFrame); end);
	
	local frameLevel = OmegaMapDetailFrame:GetFrameLevel();
	OmegaMapPlayersFrame:SetFrameLevel(frameLevel + 1);
	OmegaMapPOIFrame:SetFrameLevel(frameLevel + 2);
	OmegaMapOtherPOIFrame:SetFrameLevel(frameLevel + 2);
	OmegaMapFrame.UIElementsFrame:SetFrameLevel(frameLevel + 3);

	QUEST_POI_FRAME_WIDTH = OmegaMapDetailFrame:GetWidth();
	QUEST_POI_FRAME_HEIGHT = OmegaMapDetailFrame:GetHeight();
	QuestPOI_Initialize(OmegaMapPOIFrame, OmegaMapPOIButton_Init);


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
	-- pet battle level size adjustment
		OmegaMapFrameAreaPetLevels:SetFontObject("SubZoneTextFont");
		--if ( not WatchFrame.showObjectives and OMEGAMAP_FULLMAP_SIZE ~= WORLDMAP_FULLMAP_SIZE ) then
		--OmegaMapFrame_SetFullMapView();  --REVISIT
		--end		
		
	--UpdateMicroButtons();

	if (not OmegaMapFrame.toggling) then
		SetMapToCurrentZone();
	else
		OmegaMapFrame.toggling = false;
	end
	PlaySound("igQuestLogOpen");
	CloseDropDownMenus();
	OmegaMapFrame_UpdateUnits("OmegaMapRaid", "OmegaMapParty");
	DoEmote("READ", nil, true);
	OmegaMapFrame_Update();
	OmegaMapFrame.fadeOut = false;  --new 6.0

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
--[[
	if ( OpacityFrame:IsShown() and OpacityFrame.saveOpacityFunc and OpacityFrame.saveOpacityFunc == OmegaMapFrame_SaveOpacity ) then
		OmegaMapFrame_SaveOpacity();
		OpacityFrame.saveOpacityFunc = nil;
		OpacityFrame:Hide();
	end
	]]-- out 60
	OmegaMapConfig.hotSpotLock = false;
	--self.fromJournal = false; 

	--UpdateMicroButtons();
	CloseDropDownMenus();
	PlaySound("igQuestLogClose");
	OmegaMap_ClearTextures();
	--New 6.0  REvisist
	if ( not self.toggling ) then
		OmegaMapQuestFrame_CloseQuestDetails();
	end
	if ( OmegaMapScrollFrame.zoomedIn ) then
		OmegaMapScrollFrame_ResetZoom();
	end
	-- 

	OmegaMapPing.Ping:Stop();
	if ( self.showOnHide ) then
		ShowUIPanel(self.showOnHide);
		self.showOnHide = nil;
	end

	--Hide Options window if shown
	if (OmegaMapOptionsFrame.Frame:IsShown()) then
		OmegaMapOptionsFrame.Frame:Hide()
	end 
	--OmegaMapConfig.showObjectives = false

	--Clears Blobs from map.  This is a workaraound for the blob frame being protected

	OmegaMapFrame:Hide()
	--[[
	OmegaMapBlobFrame:DrawBlob(GetSuperTrackedQuestID(), false);
	OmegaMapBlobFrame:DrawNone();
	OmegaMapArchaeologyDigSites:DrawNone();
	OmegaMapScenarioPOIFrame:DrawNone();


	local numEntries = ArchaeologyMapUpdateAll();
	for i = 1, numEntries do
		local blobID = ArcheologyGetVisibleBlobID(i);
		OmegaMapArchaeologyDigSites:DrawBlob(blobID, false);
	end
	--]]
	OmegaMapSolidify("Off")

	-- forces WatchFrame event via the WORLD_MAP_UPDATE event, needed to restore the POIs in the tracker to the current zone
	if (not OmegaMapFrame.toggling) then
		OmegaMapFrame.fromJournal = false;
		OmegaMapFrame.hasBosses = false;
		SetMapToCurrentZone();
	end
	CancelEmote();
	self.mapID = nil;
	self.AnimAlphaOut:Stop();
	self.AnimAlphaIn:Stop();
	--self:SetAlpha(WORLD_MAP_MAX_ALPHA);
end

function OmegaMapFrame_OnEvent(self, event, ...)
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		if ( self:IsShown() ) then
			HideUIPanel(OmegaMapFrame);
		end
		
	elseif ( event == "WORLD_MAP_UPDATE" or event == "REQUEST_CEMETERY_LIST_RESPONSE" or event == "QUESTLINE_UPDATE" ) then
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
			--New 6.0 Revisit
			if ( OmegaMapQuestFrame.DetailsFrame.questMapID and OmegaMapQuestFrame.DetailsFrame.questMapID ~= GetCurrentMapAreaID() ) then
				OmegaMapQuestFrame_CloseQuestDetails();
			else
				OmegaMapQuestFrame_UpdateAll();
			end
			if ( OmegaMapScrollFrame.zoomedIn ) then
				if ( OmegaMapScrollFrame.continent ~= GetCurrentMapContinent() or OmegaMapScrollFrame.mapID ~= GetCurrentMapAreaID() ) then
					OmegaMapScrollFrame_ResetZoom();
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
	

	elseif ( event == "GROUP_ROSTER_UPDATE" ) then
		if ( self:IsShown() ) then
			OmegaMapFrame_UpdateUnits("OmegaMapRaid", "OmegaMapParty");
		end
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
		OmegaMap_UpdateQuestBonusObjectives();
	elseif ( event == "QUESTTASK_UPDATE" and OmegaMapFrame:IsVisible() ) then
		--TaskPOI_OnEnter(_G["lastPOIButtonUsed"]);  -- Revisit
	elseif ( event == "MODIFIER_STATE_CHANGED" ) then
		OmegaMapSolidifyCheck(self,...)
	end
end
--NEw Revisit
function OmegaMapFrame_AnimAlphaIn(self, useStartDelay)
	OmegaMapFrame_AnimateAlpha(self, useStartDelay, self.AnimAlphaIn, self.AnimAlphaOut, WORLD_MAP_MIN_ALPHA, WORLD_MAP_MAX_ALPHA);
end

function OmegaMapFrame_AnimAlphaOut(self, useStartDelay)
	OmegaMapFrame_AnimateAlpha(self, useStartDelay, self.AnimAlphaOut, self.AnimAlphaIn, WORLD_MAP_MAX_ALPHA, WORLD_MAP_MIN_ALPHA);
end

function OmegaMapFrame_AnimateAlpha(self, useStartDelay, anim, otherAnim, startAlpha, endAlpha)
	if ( not WorldMapFrame_InWindowedMode() or not self:IsShown() ) then
		return;
	end

	if ( anim:IsPlaying() or self:GetAlpha() == endAlpha ) then
		otherAnim:Stop();
		return;
	end
	
	local startDelay = 0;
	if ( useStartDelay ) then
		startDelay = tonumber(GetCVar("mapAnimStartDelay"));
	end

	if ( otherAnim:IsPlaying() ) then
		startDelay = 0;
		startAlpha = self:GetAlpha();
		otherAnim:Stop();
		self:SetAlpha(startAlpha);
	end

	local change = endAlpha - startAlpha;
	local duration = (change / (WORLD_MAP_MAX_ALPHA - WORLD_MAP_MIN_ALPHA)) * tonumber(GetCVar("mapAnimDuration"));
	anim.Alpha:SetChange(change);
	anim.Alpha:SetDuration(abs(duration));
	anim.Alpha:SetStartDelay(startDelay);
	anim:Play();	
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
--NEw REvisit  --New minimized world map fades when player is mooving
	if ( WorldMapFrame_InWindowedMode() and IsPlayerMoving() and GetCVarBool("mapFade") and WorldMapFrame.fadeOut ) then
		if ( self:IsMouseOver() ) then
			WorldMapFrame_AnimAlphaIn(self);
			self.wasMouseOver = true;
		elseif ( self.wasMouseOver ) then
			WorldMapFrame_AnimAlphaOut(self);
			self.wasMouseOver = nil;
		end
	end

end

--[[
function OmegaMapFrame_OnKeyDown(self, key)
	local binding = GetBindingFromClick(key)
	if ((binding == "TOGGLEOMEGAMAP") or (binding == "TOGGLEOMEGAMAP")) then
		RunBinding("TOGGLEOMEGAMAP");
	elseif ( binding == "SCREENSHOT" ) then
		RunBinding("SCREENSHOT");
	elseif ( binding == "MOVIE_RECORDING_STARTSTOP" ) then
		RunBinding("MOVIE_RECORDING_STARTSTOP");
	elseif ( binding == "TOGGLEWORLDMAPSIZE" ) then
		RunBinding("TOGGLEWORLDMAPSIZE");
	elseif ( binding == "TOGGLEQUESTLOG" ) then
		RunBinding("TOGGLEQUESTLOG");
	end
end
--]]

--NEw
-----------------------------------------------------------------
-- Draw quest bonus objectives
-----------------------------------------------------------------
function OmegaMap_UpdateQuestBonusObjectives()
	local mapAreaID = GetCurrentMapAreaID();
	local taskInfo = C_TaskQuest.GetQuestsForPlayerByMapID(mapAreaID);
	local numTaskPOIs = 0;
	if(taskInfo ~= nil) then
		numTaskPOIs = #taskInfo;
	end

	--Ensure the button pool is big enough for all the world effect POI's
	if ( NUM_OMEGAMAP_TASK_POIS < numTaskPOIs ) then
		for i=NUM_OMEGAMAP_TASK_POIS+1, numTaskPOIs do
			OmegaMap_CreateTaskPOI(i);
		end
		NUM_OMEGAMAP_TASK_POIS = numTaskPOIs;
	end

	local taskIconCount = 1;
	if ( numTaskPOIs > 0 ) then
		for _, info  in next, taskInfo do
			local textureIndex = MINIMAP_QUEST_BONUS_OBJECTIVE;
			local x = info.x;
			local y = info.y;
			local questid = info.questId;
				
			local taskPOIName = "OmegaMapFrameTaskPOI"..taskIconCount;
			local taskPOI = _G[taskPOIName];
				
			local x1, x2, y1, y2 = GetWorldEffectTextureCoords(textureIndex);
			_G[taskPOIName.."Texture"]:SetTexCoord(x1, x2, y1, y2);
			x = x * OmegaMapButton:GetWidth();
			y = -y * OmegaMapButton:GetHeight();
			taskPOI:SetPoint("CENTER", "OmegaMapButton", "TOPLEFT", x, y);
			taskPOI.name = taskPOIName;
			taskPOI.questID = questid;
			taskPOI:Show();

			taskIconCount = taskIconCount + 1;
		end
	end
	
	-- Hide unused icons in the pool
	for i=taskIconCount, NUM_OMEGAMAP_TASK_POIS do
		local taskPOIName = "OmegaMapFrameTaskPOI"..i;
		local taskPOI = _G[taskPOIName];
		taskPOI:Hide();
	end
end



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
	if( GetCVarBool("questPOI") and (scenarioIconInfo ~= nil))then
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
			OmegaMapDraenorButton:Show();
		else
			-- Temporary Hack (Temporary meaning 6 yrs, haha)
			mapName = "World";
			OmegaMapOutlandButton:Hide();
			OmegaMapAzerothButton:Hide();
			OmegaMapDraenorButton:Hide();
		end
		OmegaMapDeepholmButton:Hide();
		OmegaMapKezanButton:Hide();
		OmegaMapLostIslesButton:Hide();
		OmegaMapTheMaelstromButton:Hide();
	else
		OmegaMapOutlandButton:Hide();
		OmegaMapAzerothButton:Hide();
		OmegaMapDraenorButton:Hide();
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

	local mapWidth = OmegaMapDetailFrame:GetWidth();
	local mapHeight = OmegaMapDetailFrame:GetHeight();

	local mapID, isContinent = GetCurrentMapAreaID();

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
			local name, description, textureIndex, x, y, mapLinkID, inBattleMap, graveyardID, areaID, poiID, isObjectIcon, atlasIcon = GetMapLandmarkInfo(i);
			if( (mapID ~= WORLDMAP_WINTERGRASP_ID) and (areaID == WORLDMAP_WINTERGRASP_POI_AREAID) ) then
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
				omegaMapPOI:SetPoint("CENTER", activeFrame, "TOPLEFT", x, y );

				if ( OmegaMap_IsSpecialPOI(poiID) ) then	--We have special handling for Isle of the Thunder King
					OmegaMap_HandleSpecialPOI(omegaMapPOI, poiID);
				else
					OmegaMap_ResetPOI(omegaMapPOI, isObjectIcon, atlasIcon);

					local x1, x2, y1, y2
					if (not atlasIcon) then
						if (isObjectIcon == true) then
							x1, x2, y1, y2 = GetObjectIconTextureCoords(textureIndex);
						else
							x1, x2, y1, y2 = GetPOITextureCoords(textureIndex);
						end
						_G[omegaMapPOIName.."Texture"]:SetTexCoord(x1, x2, y1, y2);
					else
						_G[omegaMapPOIName.."Texture"]:SetTexCoord(0, 1, 0, 1);
					end

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
	OmegaMap_UpdateQuestBonusObjectives();

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
					OmegaMapDetailTilesFrame:CreateTexture("OmegaMapOverlay"..j, "ARTWORK");
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

	--New

	-- position storyline quests, but not on continent or "world" maps
	local numUsedStoryLineFrames = 0;
	if ( not isContinent and mapID > 0 ) then
		for i = 1, C_Questline.GetNumAvailableQuestlines() do
			local questLineName, questName, continentID, x, y = C_Questline.GetQuestlineInfoByIndex(i);
			if ( questLineName and x > 0 and y > 0 ) then
				numUsedStoryLineFrames = numUsedStoryLineFrames + 1;
				local frame = STORYLINE_FRAMES[numUsedStoryLineFrames];
				if ( not frame ) then
					frame = CreateFrame("FRAME", "OmegaMapStoryLine"..numUsedStoryLineFrames, OmegaMapOtherPOIFrame, "OmegaMapStoryLineTemplate");
					STORYLINE_FRAMES[numUsedStoryLineFrames] = frame;
				end
				frame.index = i;
				frame:SetPoint("CENTER", "OmegaMapDetailTilesFrame", "TOPLEFT", x * mapWidth, -y * mapHeight);
				frame:Show();
			end
		end
	end
	for i = numUsedStoryLineFrames + 1, #STORYLINE_FRAMES do
		STORYLINE_FRAMES[i]:Hide();
	end

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

--Shows Alternate map if avaliable
	if OmegaMapConfig.showExteriors then
		OmegaMap_LoadAltMapNotes()
	else 
		OmegaMap_HideAltMap()
	end
--[[
-- Hides map blobs if an alt map is displayed
	if  not InCombatLockdown() then
		if OMEGAMAP_ALTMAP then
			OmegaMapSpecialFrame:Hide()
		else
			OmegaMapSpecialFrame:Show()
		end
	end
	--]]
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
					OmegaMapTooltip:AddLine(GRAVEYARD_SELECTED_TOOLTIP, 1, 1, 1, true);
					OmegaMapTooltip:Show();
				else
					OmegaMapTooltip:SetText(GRAVEYARD_ELIGIBLE);
					OmegaMapTooltip:AddLine(GRAVEYARD_ELIGIBLE_TOOLTIP, 1, 1, 1, true);
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
	end
end

function OmegaMapEffectPOI_OnLeave()
	OmegaMapFrame.poiHighlight = nil;
	OmegaMapFrameAreaLabel:SetText(OmegaMapFrame.areaName);
	OmegaMapFrameAreaDescription:SetText("");
	OmegaMapTooltip:Hide();
end

function OmegaMapTaskPOI_OnEnter(self)
	if(self ~= nil and self.questID ~= nil) then
		OmegaMapTooltip:SetOwner(self, "ANCHOR_RIGHT");
		local name = C_TaskQuest.GetQuestTitleByQuestID(self.questID)
		local objectives = C_TaskQuest.GetQuestObjectiveStrByQuestID(self.questID)

		--_G["lastPOIButtonUsed"] = self;
		
		OmegaMapTooltip:SetText(name);
		if ( objectives ~= nil ) then
			for key,value in pairs(objectives) do
				OmegaMapTooltip:AddLine(QUEST_DASH..value, 1, 1, 1, true);
			end	
		end
		OmegaMapTooltip:Show();
	end
end

function OmegaMapTaskPOI_OnLeave(self)
	OmegaMapFrame.poiHighlight = nil;
	OmegaMapFrameAreaLabel:SetText(OmegaMapFrame.areaName);
	OmegaMapFrameAreaDescription:SetText("");
	OmegaMapTooltip:Hide();
end

function OmegaMapScenarioPOI_OnEnter(self)
	if(ScenarioPOITooltips[self.name] ~= nil) then
		OmegaMapTooltip:SetOwner(self, "ANCHOR_RIGHT");
		OmegaMapTooltip:SetText(ScenarioPOITooltips[self.name]);
		OmegaMapTooltip:Show();
	end
end

function OmegaMapScenarioPOI_OnLeave()
	OmegaMapFrame.poiHighlight = nil;
	OmegaMapFrameAreaLabel:SetText(OmegaMapFrame.areaName);
	OmegaMapFrameAreaDescription:SetText("");
	OmegaMapTooltip:Hide();
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

function OmegaMap_CreatePOI(index, isObjectIcon, atlasIcon)
	local button = CreateFrame("Button", "OmegaMapFramePOI"..index, OmegaMapOtherPOIFrame);
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	button:SetScript("OnEnter", OmegaMapPOI_OnEnter);
	button:SetScript("OnLeave", OmegaMapPOI_OnLeave);
	button:SetScript("OnClick", OmegaMapPOI_OnClick);

	button.Texture = button:CreateTexture(button:GetName().."Texture", "BACKGROUND");

	OmegaMap_ResetPOI(button, isObjectIcon, atlasIcon);
end

function OmegaMap_ResetPOI(button, isObjectIcon, atlasIcon)
		if (atlasIcon) then
		button.Texture:SetAtlas(atlasIcon, true);
		button:SetSize(button.Texture:GetSize());
		button.Texture:SetPoint("CENTER", 0, 0);
	elseif (isObjectIcon == true) then
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
	local button = CreateFrame("Button", "OmegaMapFrameWorldEffectPOI"..index, OmegaMapOtherPOIFrame);
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

function OmegaMap_CreateTaskPOI(index)
	local button = CreateFrame("Button", "OmegaMapFrameTaskPOI"..index, OmegaMapOtherPOIFrame);
	button:SetScript("OnEnter", OmegaMapTaskPOI_OnEnter);
	button:SetScript("OnLeave", OmegaMapTaskPOI_OnLeave);
	
	button.Texture = button:CreateTexture(button:GetName().."Texture", "BACKGROUND");
	OmegaMap_ResetPOI(button, true, false)
end

function OmegaMap_CreateScenarioPOI(index)
	local button = CreateFrame("Button", "OmegaMapFrameScenarioPOI"..index, OmegaMapOtherPOIFrame);
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
		button = CreateFrame("Button", frameName, OmegaMapOtherPOIFrame);
		button:SetWidth(32);
		button:SetHeight(32);
		button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
		button:SetScript("OnEnter", nil);
		button:SetScript("OnLeave", nil);
		button:SetScript("OnClick", nil);
		
		local texture = button:CreateTexture(button:GetName().."Texture", "ARTWORK");
		texture:SetWidth(48);
		texture:SetHeight(48);
		texture:SetPoint("CENTER", 0, 0);
		button.texture = texture;
	end
	return button;
end

function OmegaMapLevelDropDown_Update()
	UIDropDownMenu_Initialize(OmegaMapLevelDropDown, OmegaMapLevelDropDown_Initialize);
	UIDropDownMenu_SetWidth(OmegaMapLevelDropDown, 130);

	if ( (GetNumDungeonMapLevels() == 0) ) then
		UIDropDownMenu_ClearAll(OmegaMapLevelDropDown);
		OmegaMapLevelDropDown:Hide();
	else
		local floorMapCount, firstFloor = GetNumDungeonMapLevels();
		local levelID = GetCurrentMapDungeonLevel() - firstFloor + 1;

		UIDropDownMenu_SetSelectedID(OmegaMapLevelDropDown, GetCurrentMapDungeonLevel());
		OmegaMapLevelDropDown:Show();
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
	OmegaMapScrollFrame_ResetZoom()
end

function OmegaMapZoomOutButton_OnClick()
	PlaySound("igMainMenuOptionCheckBoxOn");
	OmegaMapTooltip:Hide();
	
	-- check if code needs to zoom out before going to the continent map
	if ( ZoomOut() ~= nil ) then
		return;
	elseif ( GetCurrentMapContinent() == WORLDMAP_AZEROTH_ID ) then
		SetMapZoom(WORLDMAP_COSMIC_ID);
	elseif ( GetCurrentMapContinent() == WORLDMAP_OUTLAND_ID or GetCurrentMapContinent() == WORLDMAP_DRAENOR_ID ) then
		SetMapZoom(WORLDMAP_COSMIC_ID);
	else
		SetMapZoom(WORLDMAP_AZEROTH_ID);
	end
end

function OmegaMapButton_OnClick(button, mouseButton)
	if ( OmegaMapButton.ignoreClick ) then
		OmegaMapButton.ignoreClick = false;
		return;
	end
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
	elseif ( GetBindingFromClick(mouseButton) ==  "TOGGLEWORLDMAP" ) then  --Revisit
		ToggleOmegaMap();
	end
end

function OmegaMapFakeButton_OnClick(button, mouseButton)
	if ( OmegaMapButton.ignoreClick ) then
		OmegaMapButton.ignoreClick = false;
		return;
	end
	if ( mouseButton == "LeftButton" ) then
		if ( button.zoneID ) then
			SetMapByID(button.zoneID);
		elseif ( button.continent ) then
			SetMapZoom(button.continent);
		end
	else
		OmegaMapZoomOutButton_OnClick();
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
	if ( OmegaMapScrollFrame.panning ) then
		OmegaMapScrollFrame_OnPan(x, y);
	end
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
				OmegaMapFrameAreaLabel:SetText(OmegaMapFrameAreaLabel:GetText()..color.." ("..minLevel.."-"..maxLevel..")"..FONT_COLOR_CODE_CLOSE);
			else
				OmegaMapFrameAreaLabel:SetText(OmegaMapFrameAreaLabel:GetText()..color.." ("..maxLevel..")"..FONT_COLOR_CODE_CLOSE);
			end
		end

		local _, _, _, _, locked = C_PetJournal.GetPetLoadOutInfo(1);
		if (not locked) then --don't show pet levels for people who haven't unlocked battle petting
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
					OmegaMapFrameAreaPetLevels:SetText(WORLD_MAP_WILDBATTLEPET_LEVEL..color.."("..petMinLevel.."-"..petMaxLevel..")"..FONT_COLOR_CODE_CLOSE);
				else
					OmegaMapFrameAreaPetLevels:SetText(WORLD_MAP_WILDBATTLEPET_LEVEL..color.."("..petMaxLevel..")"..FONT_COLOR_CODE_CLOSE);
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
			OmegaMapHighlight:SetPoint("TOPLEFT", "OmegaMapDetailTilesFrame", "TOPLEFT", scrollChildX, scrollChildY);
			OmegaMapHighlight:Show();
			--OmegaMapFrameAreaLabel:SetPoint("TOP", "OmegaMapHighlight", "TOP", 0, 0);
		end
		
	else
		OmegaMapHighlight:Hide();
	end

	local activeFrame = OmegaMapPlayersFrame
	if (OMEGAMAP_ALTMAP) then
		activeFrame = OmegaMapAltMapFrame
	else
		activeFrame = OmegaMapPlayersFrame
	end

	local playersFrameWidth = activeFrame:GetWidth();
	local playersFrameHeight = activeFrame:GetHeight();

	--Position player
	local playerX, playerY = OmegaMapOffsetAltMapCoords( GetPlayerMapPosition("player"));
	if ( (playerX == 0 and playerY == 0) ) then
		OmegaMapPlayerLower:Hide();
		OmegaMapPlayerUpper:Hide();
	else
		playerX = playerX * playersFrameWidth;
		playerY = -playerY * playersFrameHeight;

		-- Position clear button to detect mouseovers
		OmegaMapPlayerLower:Show();
		OmegaMapPlayerUpper:Show();
		OmegaMapPlayerLower:SetPoint("CENTER", OmegaMapPlayersFrame, "TOPLEFT", playerX, playerY);
		OmegaMapPlayerUpper:SetPoint("CENTER", OmegaMapPlayersFrame, "TOPLEFT", playerX, playerY);
		UpdateWorldMapArrow(OmegaMapPlayerLower.icon);
		UpdateWorldMapArrow(OmegaMapPlayerUpper.icon);
		OmegaMapPing:SetPoint("CENTER", OmegaMapPlayersFrame, "TOPLEFT", playerX, playerY);
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
				partyX = partyX * playersFrameWidth;
				partyY = -partyY * playersFrameHeight;
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
				partyX = partyX * playersFrameWidth;
				partyY = -partyY * playersFrameWidth;
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
	if ( GetCurrentMapContinent() == WORLDMAP_AZEROTH_ID or (GetCurrentMapContinent() ~= -1 and GetCurrentMapZone() == 0) ) then
		-- Hide vehicles on the worldmap and continent maps
		numVehicles = 0;
	else
		numVehicles = GetNumBattlefieldVehicles();
	end
	local totalVehicles = #OMEGAMAP_VEHICLES;
	local playerBlipFrameLevel = OmegaMapRaid1:GetFrameLevel();
	local index = 0;
	for i=1, numVehicles do
		if (i > totalVehicles) then
			local vehicleName = "OmegaMapVehicles"..i;
			OMEGAMAP_VEHICLES[i] = CreateFrame("FRAME", vehicleName, OmegaMapOtherPOIFrame, "OmegaMapVehicleTemplate");
			OMEGAMAP_VEHICLES[i].texture = _G[vehicleName.."Texture"];
		end
		local vehicleX, vehicleY, unitName, isPossessed, vehicleType, orientation, isPlayer, isAlive = OmegaMapOffsetAltMapCoords( GetBattlefieldVehicleInfo(i));
		if ( vehicleX and isAlive and not isPlayer and VEHICLE_TEXTURES[vehicleType]) then
			local mapVehicleFrame = OMEGAMAP_VEHICLES[i];
			vehicleX = vehicleX * activeFrame:GetWidth();
			vehicleY = -vehicleY * activeFrame:GetHeight();
			mapVehicleFrame.texture:SetRotation(orientation);
			mapVehicleFrame.texture:SetTexture(OmegaMap_GetVehicleTexture(vehicleType, isPossessed));
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

function OmegaMap_ClearTextures()
	for i=1, NUM_OMEGAMAP_OVERLAYS do
		_G["OmegaMapOverlay"..i]:SetTexture(nil);
	end
	local numOfDetailTiles = GetNumberOfDetailTiles();
	for i=1, numOfDetailTiles do
		--_G["OmegaMapFrameTexture"..i]:SetTexture(nil);  --NEEDed?
		_G["OmegaMapDetailTile"..i]:SetTexture(nil);
	end
end

function OmegaMapUnit_OnLoad(self)
	self:SetFrameLevel(self:GetFrameLevel() + 1);
end

function OmegaMapUnit_OnEnter(self, motion)
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
		if ( instanceType == "pvp" or  IsInActiveWorldPVP() ) then
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

--OUT?
--[[
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
]]--


--[[  -- OUT REVISIT
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

]]--

function OmegaMapFrame_UpdateMap()
	OmegaMapFrame_Update();
	OmegaMapLevelDropDown_Update();
	OmegaMapNavBar_Update();
end

function OmegaMapScenarioPOIFrame_OnUpdate()
	if (not OmegaMapFrame:IsVisible()) then return end

	OmegaMapScenarioPOIFrame:DrawNone();
	if( GetCVarBool("questPOI") ) then
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

function OmegaMapQuestPOI_SetTooltip(poiButton, questLogIndex, numObjectives)
	local title = GetQuestLogTitle(questLogIndex);
	OmegaMapTooltip:SetOwner(poiButton or OmegaMapBlobFrame, "ANCHOR_CURSOR_RIGHT", 5, 2);
	OmegaMapTooltip:SetText(title);
	if ( poiButton and poiButton.style ~= "numeric" ) then
		OmegaMapTooltip:AddLine("- "..GetQuestLogCompletionText(questLogIndex), 1, 1, 1, true);
	else
		local text, finished, objectiveType;
		local numItemDropTooltips = GetNumQuestItemDrops(questLogIndex);
		if(numItemDropTooltips and numItemDropTooltips > 0) then
			for i = 1, numItemDropTooltips do
				text, objectiveType, finished = GetQuestLogItemDrop(i, questLogIndex);
				if ( text and not finished ) then
					OmegaMapTooltip:AddLine(QUEST_DASH..text, 1, 1, 1, true);
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
					OmegaMapTooltip:AddLine(QUEST_DASH..text, 1, 1, 1, true);
				end
			end		
		end
	end
	OmegaMapTooltip:Show();
end


function OmegaMapQuestPOI_AppendTooltip(poiButton, questLogIndex)
	local title = GetQuestLogTitle(questLogIndex);
	OmegaMapTooltip:AddLine(" ");
	OmegaMapTooltip:AddLine(title);
	if ( poiButton and poiButton.style ~= "numeric" ) then
		OmegaMapTooltip:AddLine("- "..GetQuestLogCompletionText(questLogIndex), 1, 1, 1, true);
	else
		local text, finished, objectiveType;
		local numItemDropTooltips = GetNumQuestItemDrops(questLogIndex);
		if(numItemDropTooltips and numItemDropTooltips > 0) then
			for i = 1, numItemDropTooltips do
				text, objectiveType, finished = GetQuestLogItemDrop(i, questLogIndex);
				if ( text and not finished ) then
					OmegaMapTooltip:AddLine(QUEST_DASH..text, 1, 1, 1, true);
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
					OmegaMapTooltip:AddLine(QUEST_DASH..text, 1, 1, 1, true);
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

-- for when we need to wait a frame
function OmegaMapBlobFrame_DelayedUpdateBlobs()	
	OmegaMapBlobFrame.updateBlobs = true;
end

function OmegaMapBlobFrame_OnUpdate(self)
	if ( self.updateBlobs ) then
		OmegaMapBlobFrame_UpdateBlobs();
		self.updateBlobs = nil;
	end

	if ( not OmegaMapBlobFrame:IsMouseOver() ) then
		return;
	end
	if ( OmegaMapTooltip:IsShown() and OmegaMapTooltip:GetOwner() ~= OmegaMapBlobFrame ) then
		return;
	end

	if ( not self.scale ) then
		OmegaMapBlobFrame_CalculateHitTranslations();
	end
	
	local cursorX, cursorY = GetCursorPosition();
	local frameX = cursorX / self.scale - self.offsetX;
	local frameY = - cursorY / self.scale + self.offsetY;
	local adjustedX = frameX / QUEST_POI_FRAME_WIDTH;
	local adjustedY = frameY / QUEST_POI_FRAME_HEIGHT;

	local questLogIndex, numObjectives = self:UpdateMouseOverTooltip(adjustedX, adjustedY);
	if ( numObjectives ) then
		OmegaMapTooltip:SetOwner(OmegaMapBlobFrame, "ANCHOR_CURSOR");
		OmegaMapQuestPOI_SetTooltip(nil, questLogIndex, numObjectives);
	else
		OmegaMapTooltip:Hide();
	end
end

function OmegaMapBlobFrame_ResetHitTranslations()
	OmegaMapBlobFrame.scale = nil;
end

function OmegaMapBlobFrame_CalculateHitTranslations()
	local self = OmegaMapBlobFrame;
	--if ( WorldMapFrame_InWindowedMode() ) then
	--	self.scale = UIParent:GetScale();
	--else
		self.scale = OmegaMapFrame:GetScale();
	--end
	self.offsetX = OmegaMapScrollFrame:GetLeft() - OmegaMapScrollFrame:GetHorizontalScroll();
	self.offsetY = OmegaMapScrollFrame:GetTop() + OmegaMapScrollFrame:GetVerticalScroll();
end

function OmegaMapFrame_ResetQuestColors()
	-- FIXME
end

--- advanced options ---

-- *****************************************************************************************************
-- ***** PAN AND ZOOM
-- *****************************************************************************************************
local MAX_ZOOM = 1.495;

function OmegaMapScrollFrame_OnMouseWheel(self, delta)

	--Blocks pan/zoom if alt exterior/battleground map is displayed
	if OMEGAMAP_ALTMAP then return end

	local scrollFrame = OmegaMapScrollFrame;
	local oldScrollH = scrollFrame:GetHorizontalScroll();
	local oldScrollV = scrollFrame:GetVerticalScroll();

	-- get the mouse position on the frame, with 0,0 at top left
	local cursorX, cursorY = GetCursorPosition();
	local relativeFrame;
	--if ( OmegaMapFrame_InWindowedMode() ) then
		--relativeFrame = UIParent;
	--else
		relativeFrame = OmegaMapFrame;
	--end
	local frameX = cursorX / relativeFrame:GetScale() - scrollFrame:GetLeft();
	local frameY = scrollFrame:GetTop() - cursorY / relativeFrame:GetScale();

	local oldScale = OmegaMapDetailFrame:GetScale();
	local newScale = oldScale + delta * 0.3;
	newScale = max(OMEGAMAP_FULLMAP_SIZE, newScale);  --CHECK
	newScale = min(MAX_ZOOM, newScale);
	OmegaMapDetailFrame:SetScale(newScale);
	QUEST_POI_FRAME_WIDTH = OmegaMapDetailFrame:GetWidth() * newScale;
	QUEST_POI_FRAME_HEIGHT = OmegaMapDetailFrame:GetHeight() * newScale;

	scrollFrame.maxX = QUEST_POI_FRAME_WIDTH - 1002 * OMEGAMAP_FULLMAP_SIZE;
	scrollFrame.maxY = QUEST_POI_FRAME_HEIGHT - 668 * OMEGAMAP_FULLMAP_SIZE;
	scrollFrame.zoomedIn = abs(OmegaMapDetailFrame:GetScale() - OMEGAMAP_FULLMAP_SIZE) > 0.05;
	scrollFrame.continent = GetCurrentMapContinent();
	scrollFrame.mapID = GetCurrentMapAreaID();

	-- figure out new scroll values
	local scaleChange = newScale / oldScale;
	local newScrollH = scaleChange * ( frameX + oldScrollH ) - frameX;
	local newScrollV = scaleChange * ( frameY + oldScrollV ) - frameY;
	-- clamp scroll values
	newScrollH = min(newScrollH, scrollFrame.maxX);
	newScrollH = max(0, newScrollH);
	newScrollV = min(newScrollV, scrollFrame.maxY);
	newScrollV = max(0, newScrollV);
	-- set scroll values
	scrollFrame:SetHorizontalScroll(newScrollH);
	scrollFrame:SetVerticalScroll(newScrollV);

	OmegaMapFrame_Update();
	OmegaMapScrollFrame_ReanchorQuestPOIs();
	OmegaMapBlobFrame_ResetHitTranslations();
	OmegaMapBlobFrame_DelayedUpdateBlobs();
end

function OmegaMapScrollFrame_ResetZoom()
	OmegaMapScrollFrame.panning = false;
	OmegaMapDetailFrame:SetScale(OMEGAMAP_FULLMAP_SIZE);  --CHECK/FIX
	QUEST_POI_FRAME_WIDTH = OmegaMapDetailFrame:GetWidth() * OMEGAMAP_FULLMAP_SIZE;--CHECK/FIX
	QUEST_POI_FRAME_HEIGHT = OmegaMapDetailFrame:GetHeight() * OMEGAMAP_FULLMAP_SIZE;	--CHECK/FIX
	OmegaMapScrollFrame:SetHorizontalScroll(0);
	OmegaMapScrollFrame:SetVerticalScroll(0);
	OmegaMapScrollFrame.zoomedIn = false;
	OmegaMapFrame_Update();
	OmegaMapScrollFrame_ReanchorQuestPOIs();
	OmegaMapBlobFrame_ResetHitTranslations();
	OmegaMapBlobFrame_DelayedUpdateBlobs();

end

function OmegaMapScrollFrame_ReanchorQuestPOIs()
	for _, poiType in pairs(OmegaMapPOIFrame.poiTable) do
		for _, poiButton in pairs(poiType) do
			if ( poiButton.used ) then
				local _, posX, posY = QuestPOIGetIconInfo(poiButton.questID);
				OmegaMapPOIFrame_AnchorPOI(poiButton, posX, posY);			
			end
		end
	end
end

function OmegaMapScrollFrame_OnPan(cursorX, cursorY)
	local dx = OmegaMapScrollFrame.cursorX - cursorX;
	local dy = cursorY - OmegaMapScrollFrame.cursorY;
	if ( abs(dx) >= 1 or abs(dy) >= 1 ) then
		OmegaMapScrollFrame.moved = true;
		local x = max(0, dx + OmegaMapScrollFrame.x);
		x = min(x, OmegaMapScrollFrame.maxX);
		OmegaMapScrollFrame:SetHorizontalScroll(x);
		local y = max(0, dy + OmegaMapScrollFrame.y);
		y = min(y, OmegaMapScrollFrame.maxY);
		OmegaMapScrollFrame:SetVerticalScroll(y);
		OmegaMapBlobFrame_ResetHitTranslations();
		OmegaMapBlobFrame_DelayedUpdateBlobs();
	end
end

function OmegaMapButton_OnMouseDown(self, button)
	if ( button == "LeftButton" and OmegaMapScrollFrame.zoomedIn ) then
		OmegaMapScrollFrame.panning = true;
		local x, y = GetCursorPosition();		
		OmegaMapScrollFrame.cursorX = x;
		OmegaMapScrollFrame.cursorY = y;
		OmegaMapScrollFrame.x = OmegaMapScrollFrame:GetHorizontalScroll();
		OmegaMapScrollFrame.y = OmegaMapScrollFrame:GetVerticalScroll();
		OmegaMapScrollFrame.moved = false;
	end
end

function OmegaMapButton_OnMouseUp(self, button)
	if ( button == "LeftButton" and OmegaMapScrollFrame.panning ) then
		OmegaMapScrollFrame.panning = false;
		if ( OmegaMapScrollFrame.moved ) then
			OmegaMapButton.ignoreClick = true;
		end
	end
end


-- *****************************************************************************************************
-- ***** POI FRAME
-- *****************************************************************************************************

function OmegaMapPOIFrame_AnchorPOI(poiButton, posX, posY)
	if ( posX and posY ) then
		posX = posX * QUEST_POI_FRAME_WIDTH;
		posY = posY * QUEST_POI_FRAME_HEIGHT;
		-- keep outlying POIs within map borders
		if ( posY < QUEST_POI_FRAME_INSET ) then
			posY = QUEST_POI_FRAME_INSET;
		elseif ( posY > QUEST_POI_FRAME_HEIGHT - 12 ) then
			posY = QUEST_POI_FRAME_HEIGHT - 12;
		end
		if ( posX < QUEST_POI_FRAME_INSET ) then
			posX = QUEST_POI_FRAME_INSET;
		elseif ( posX > QUEST_POI_FRAME_WIDTH - 12 ) then
			posX = QUEST_POI_FRAME_WIDTH - 12;
		end
		poiButton:SetPoint("CENTER", OmegaMapPOIFrame, "TOPLEFT", posX, -posY);
	end
end

function OmegaMapPOIFrame_Update(poiTable)
	QuestPOI_ResetUsage(OmegaMapPOIFrame);
	local detailQuestID = OmegaMapQuestFrame_GetDetailQuestID();
	local poiButton;
	for index, questID in pairs(poiTable) do
		if ( not detailQuestID or questID == detailQuestID ) then
			local _, posX, posY = QuestPOIGetIconInfo(questID);
			if ( posX and posY ) then
				local storyQuest = IsStoryQuest(questID);
				if ( IsQuestComplete(questID) ) then
					poiButton = QuestPOI_GetButton(OmegaMapPOIFrame, questID, "map", nil, storyQuest);
				else
					-- if a quest is being viewed there is only going to be one POI and it's going to have number 1
					poiButton = QuestPOI_GetButton(OmegaMapPOIFrame, questID, "numeric", (detailQuestID and 1) or index, storyQuest);
				end
				OmegaMapPOIFrame_AnchorPOI(poiButton, posX, posY);
			end
		end
	end
	OmegaMapPOIFrame_SelectPOI(GetSuperTrackedQuestID());
	QuestPOI_HideUnusedButtons(OmegaMapPOIFrame);
end

function OmegaMapPOIFrame_SelectPOI(questID)
	-- POIs can overlap each other, bring the selection to the top
	local poiButton = QuestPOI_FindButton(OmegaMapPOIFrame, questID);
	if ( poiButton ) then
		QuestPOI_SelectButton(poiButton);
		poiButton:Raise();
	else
		QuestPOI_ClearSelection(OmegaMapPOIFrame);
	end
	OmegaMapBlobFrame_UpdateBlobs();	
end

function OmegaMapBlobFrame_UpdateBlobs()
	OmegaMapBlobFrame:DrawNone();
	-- always draw the blob for either the quest being viewed or the supertracked
	local questID = OmegaMapQuestFrame_GetDetailQuestID() or GetSuperTrackedQuestID();
	-- see if there is a poiButton for it (no button == not on viewed map)
	local poiButton = QuestPOI_FindButton(OmegaMapPOIFrame, questID);
	if ( poiButton and not IsQuestComplete(questID) ) then
		OmegaMapBlobFrame:DrawBlob(questID, true);
	end
end

function OmegaMapPOIButton_Init(self)
	self:SetScript("OnEnter", OmegaMapPOIButton_OnEnter);
	self:SetScript("OnLeave", OmegaMapPOIButton_OnLeave);
end

--BLOB_OVERLAP_DELTA = math.pow(0.005, 2);

function OmegaMapPOIButton_OnEnter(self)
	OmegaMapQuestPOI_SetTooltip(self, GetQuestLogIndexByID(self.questID));

	local _, posX, posY = QuestPOIGetIconInfo(self.questID);
	for _, poiType in pairs(OmegaMapPOIFrame.poiTable) do
		for _, poiButton in pairs(poiType) do
			if ( poiButton ~= self and poiButton.used ) then
				local _, otherPosX, otherPosY = QuestPOIGetIconInfo(poiButton.questID);

				if ((math.pow(posX - otherPosX, 2) + math.pow(posY - otherPosY, 2)) < BLOB_OVERLAP_DELTA) then
					OmegaMapQuestPOI_AppendTooltip(poiButton, GetQuestLogIndexByID(poiButton.questID));
				end
			end
		end
	end
end

function OmegaMapPOIButton_OnLeave(self)
	OmegaMapTooltip:Hide();
end

-- *****************************************************************************************************
-- ***** ENCOUNTER JOURNAL STUFF
-- *****************************************************************************************************

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
	
	local width = OmegaMapDetailFrame:GetWidth();
	local height = OmegaMapDetailFrame:GetHeight();

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
		index = index + 1;
		x, y, instanceID, name, description, encounterID = EJ_GetMapEncounter(index, OmegaMapFrame.fromJournal);
	end

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

-- *****************************************************************************************************
-- ***** MAP TRACKING DROPDOWN
-- *****************************************************************************************************

function OmegaMapTrackingOptionsDropDown_Initialize()
	local info = UIDropDownMenu_CreateInfo();

	-- Show quests button
	info.text = SHOW_QUEST_OBJECTIVES_ON_MAP_TEXT;
	info.value = "quests";
	info.func = OmegaMapTrackingOptionsDropDown_OnClick;
	info.checked = GetCVarBool("questPOI");
	info.isNotRadio = true;
	info.keepShownOnClick = 1;
	info.tooltipText = OPTION_TOOLTIP_SHOW_QUEST_OBJECTIVES_ON_MAP;
	info.tooltipOnButton = OPTION_TOOLTIP_SHOW_QUEST_OBJECTIVES_ON_MAP;
	UIDropDownMenu_AddButton(info);

	if (OmegaMapFrame.hasBosses) then
		-- Show bosses button
		info.text = SHOW_BOSSES_ON_MAP_TEXT;
		info.value = "bosses";
		info.func = OmegaMapTrackingOptionsDropDown_OnClick;
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
			info.func = OmegaMapTrackingOptionsDropDown_OnClick;
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
			info.func = OmegaMapTrackingOptionsDropDown_OnClick;
			info.checked = showTamers;
			info.isNotRadio = true;
			info.keepShownOnClick = 1;
			info.tooltipText = OPTION_TOOLTIP_SHOW_BATTLE_PET_TAMERS_ON_MAP;
			info.tooltipOnButton = OPTION_TOOLTIP_SHOW_BATTLE_PET_TAMERS_ON_MAP;
			UIDropDownMenu_AddButton(info);
		end
	end

end

function OmegaMapTrackingOptionsDropDown_OnClick(self)
	local checked = self.checked;
	local value = self.value;
	
	if (checked) then
		PlaySound("igMainMenuOptionCheckBoxOn");
	else
		PlaySound("igMainMenuOptionCheckBoxOff");
	end
	
	if (value == "quests") then
		SetCVar("questPOI", checked and "1" or "0");
		OmegaMapQuestFrame_UpdateAll(); --CHECK
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

-- *****************************************************************************************************
-- ***** NAV BAR
-- *****************************************************************************************************

local SIBLING_MENU_DATA = { };
local SIBLING_MENU_PARENT_ID;
local SIBLING_MENU_PARENT_IS_CONTINENT;

function OmegaMapNavBar_LoadSiblings(parentID, isContinent, doSort, ...)
	if ( parentID == SIBLING_MENU_PARENT_ID ) then
		-- we already have this loaded
		return;
	end

	wipe(SIBLING_MENU_DATA);
	local count = select("#", ...);
	for i = 1, count, 2 do
		local id = select(i, ...);
		local name = select(i+1, ...);
		if ( name ) then
			local t = { id = id, name = name };
			tinsert(SIBLING_MENU_DATA, t);
		end
	end
	if ( doSort ) then
		table.sort(SIBLING_MENU_DATA, OmegaMapNavBar_SortSiblings);
	end
	SIBLING_MENU_PARENT_ID = parentID;
	SIBLING_MENU_PARENT_IS_CONTINENT = isContinent;
end

function OmegaMapNavBar_SortSiblings(map1, map2)
	return map1.name < map2.name;
end

function OmegaMapNavBar_OnButtonSelect(self, button)
	if ( self.data.isContinent ) then
		SetMapZoom(self.data.id);
	else
		SetMapByID(self.data.id);
	end
end

function OmegaMapNavBar_SelectSibling(self, index, navBar)
	if ( SIBLING_MENU_PARENT_IS_CONTINENT ) then
		SetMapZoom(SIBLING_MENU_DATA[index].id);
	else
		SetMapByID(SIBLING_MENU_DATA[index].id);
	end
end

function OmegaMapNavBar_GetSibling(self, index)
	if ( self.data.isContinent ) then
		if ( self.data.id ~= WORLDMAP_COSMIC_ID ) then
			-- storing continent index as a negative ID to prevent collision with map ID
			-- this is only used for SIBLING_MENU_PARENT_ID comparisons
			local continentID = -self.data.id;
			-- for Azeroth or Outland, add them both
			if ( self.data.id == WORLDMAP_OUTLAND_ID or self.data.id == WORLDMAP_AZEROTH_ID or self.data.id == WORLDMAP_DRAENOR_ID ) then
				OmegaMapNavBar_LoadSiblings(continentID, true, true, WORLDMAP_OUTLAND_ID, GetContinentName(WORLDMAP_OUTLAND_ID), WORLDMAP_AZEROTH_ID, AZEROTH, WORLDMAP_DRAENOR_ID, GetContinentName(WORLDMAP_DRAENOR_ID));
			else
				local continentData = { GetMapContinents() };		-- mapID1, mapName1, mapID2, mapName2, ...
				-- SetMap needs index for continent so replace the IDs
				local index = 0;
				for i = 1, #continentData, 2 do
					index = index + 1;
					continentData[i] = index;
					-- this list is meant for continents on Azeroth so remove Outland
					if ( index == WORLDMAP_OUTLAND_ID or index == WORLDMAP_DRAENOR_ID ) then
						continentData[i + 1] = nil;
					end
				end
				OmegaMapNavBar_LoadSiblings(continentID, true, true, unpack(continentData));
			end
		end
	else
		local parentData = self.navParent.data;
		-- if this button is right after a continent button then it's a regular zone
		if ( parentData.isContinent ) then
			-- this zone data is already sorted
			OmegaMapNavBar_LoadSiblings(parentData.id, false, false, GetMapZones(parentData.id));
		else
			-- this is a "subzone", like Northshire
			OmegaMapNavBar_LoadSiblings(parentData.id, false, true, GetMapSubzones(parentData.id));
		end
	end
	if ( SIBLING_MENU_DATA[index] ) then
		return SIBLING_MENU_DATA[index].name, OmegaMapNavBar_SelectSibling;
	end
end

function OmegaMapNavBar_Update()
	local parentData = GetMapHierarchy();
	local currentContinent = GetCurrentMapContinent();
	-- if the last parent is not a continent and we're not on the cosmic view we need to add the current continent
	local haveParentContinent = parentData[#parentData] and parentData[#parentData].isContinent;
	if ( not haveParentContinent and currentContinent ~= WORLDMAP_COSMIC_ID ) then
		local continentData = { };
		if ( currentContinent == WORLDMAP_AZEROTH_ID ) then
			continentData.name = AZEROTH;
		else
			continentData.name = GetContinentName(currentContinent);
		end
		continentData.id = currentContinent;
		continentData.isContinent = true;
		tinsert(parentData, continentData);
	elseif ( haveParentContinent ) then
		currentContinent = parentData[#parentData] and parentData[#parentData].id;
	end
	-- most continents have Azeroth as a parent
	if ( currentContinent ~= WORLDMAP_COSMIC_ID and currentContinent ~= WORLDMAP_AZEROTH_ID and currentContinent ~= WORLDMAP_OUTLAND_ID and currentContinent ~= WORLDMAP_DRAENOR_ID ) then
		local continentData = { };
		continentData.name = AZEROTH;
		continentData.id = WORLDMAP_AZEROTH_ID;
		continentData.isContinent = true;
		tinsert(parentData, continentData);		
	end

	local mapID, isContinent = GetCurrentMapAreaID();	
	-- time to add the buttons
	NavBar_Reset(OmegaMapFrame.NavBar);
	for i = #parentData, 1, -1 do
		local id = parentData[i].id;
		-- might get self back as part of hierarchy in the case of dungeon maps - see Dalaran floor The Underbelly
		if ( id and id ~= mapID ) then
			local buttonData = {
				name = parentData[i].name,
				id = parentData[i].id,
				isContinent = parentData[i].isContinent,
				OnClick = OmegaMapNavBar_OnButtonSelect,
				listFunc = OmegaMapNavBar_GetSibling,
			}
			NavBar_AddButton(OmegaMapFrame.NavBar, buttonData);
		end
	end
	-- add the current map unless it's a continent
	if ( mapID and mapID ~= -1 and not isContinent ) then
		local buttonData = {
			name = GetMapNameByID(mapID),
			id = mapID,
			isContinent = false,
			OnClick = OmegaMapNavBar_OnButtonSelect,
		}
		-- only do a dropdown menu if its parent is not a continent
		if ( parentData[1] and parentData[1].isContinent ) then
			buttonData.listFunc = OmegaMapNavBar_GetSibling;
		end
		NavBar_AddButton(OmegaMapFrame.NavBar, buttonData);
	end
end

---  New Functions

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
	OmegaMapOtherPOIFrame:SetAlpha(alpha);

	-- set map alpha
	--alpha = 0.35 + (1.0 - opacity) * 0.65;
	alpha = (1.0 - opacity);
	OmegaMapDetailFrame:SetAlpha(alpha);
	OmegaMapButton.AzerothHighlight:SetAlpha(alpha);
	OmegaMapButton.DraenorHighlight:SetAlpha(alpha);
	OmegaMapButton.OutlandHighlight:SetAlpha(alpha);
	if OmegaMapAltMapFrame then
		OmegaMapAltMapFrame:SetAlpha(alpha);
	end

	-- set blob alpha
	alpha = 0.65 + (1.0 - opacity) * 0.55;
	--OmegaMapPOIFrame:SetAlpha(alpha);
	OmegaMapBlobFrame:SetFillAlpha(128 * alpha);
	OmegaMapBlobFrame:SetBorderAlpha(192 * alpha);
	OmegaMapArchaeologyDigSites:SetFillAlpha(128 * alpha);
	OmegaMapArchaeologyDigSites:SetBorderAlpha(192 * alpha);
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
		OmegaMapButton:EnableMouse(false);
		OmegaMapScrollFrame:EnableMouseWheel(false);
		OmegaMapMovementFrameTop:Hide();
		OmegaMapMovementFrameTop:EnableMouse(false)
		OmegaMapMovementFrameBottom:Hide();
		OmegaMapMovementFrameBottom:EnableMouse(false)
	elseif (state == "On") then
		OmegaMapButton:EnableMouse(true);
		OmegaMapScrollFrame:EnableMouseWheel(true)
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
		end
	end
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