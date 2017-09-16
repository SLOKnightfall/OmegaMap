--	///////////////////////////////////////////////////////////////////////////////////////////
--
--	OmegaMap	V
--	Author: Gathirer

--	OmegaMap: A worldmap frame that is transparent and allows character manipulation
--
--	Contributions: Part of the code for this is adapted from the WorldMapFrame.lua(v)
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
--LoadAddOn("Blizzard_EncounterJournal") --preloads Blizzard's Encounter Journal so it can be opened from Omega Map without errors
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
local GROUP_MEMBER_SIZE_FULL = 10;
local RAID_MEMBER_SIZE_FULL = GROUP_MEMBER_SIZE_FULL * 0.75;

local BATTLEFIELD_ICON_SIZE_FULL = 36;
local BATTLEFIELD_ICON_SIZE_WINDOW = 30;

local STORYLINE_FRAMES = { };

local INVASION_TIME_FORMAT = "%02d:%02d |cFFFF0000|r";
local incombat = false
--local playercombatclose = false

OmegaMapPins = {}
OMEGAMAP_VEHICLES = {};

local BAD_BOY_UNITS = {};
local BAD_BOY_COUNT = 0;

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
		OmegaMap_ToggleSizeDown()
	end
end

function OmegaMapFrame_IsVindicaarTextureKit(textureKitPrefix)
	return textureKitPrefix == "FlightMaster_VindicaarArgus" or textureKitPrefix == "FlightMaster_VindicaarStygianWake" or textureKitPrefix == "FlightMaster_VindicaarMacAree";
end

function OmegaMapFrame_OnLoad(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("WORLD_MAP_UPDATE");
	self:RegisterEvent("CLOSE_WORLD_MAP");
	self:RegisterEvent("VARIABLES_LOADED");
	self:RegisterEvent("DISPLAY_SIZE_CHANGED");
	self:RegisterEvent("REQUEST_CEMETERY_LIST_RESPONSE");
	self:RegisterEvent("UNIT_PORTRAIT_UPDATE");
	self:RegisterEvent("RESEARCH_ARTIFACT_DIG_SITE_UPDATED");
	self:RegisterEvent("SUPER_TRACKED_QUEST_CHANGED");
	self:RegisterEvent("PLAYER_STARTED_MOVING");
	self:RegisterEvent("PLAYER_STOPPED_MOVING");
	self:RegisterEvent("QUESTLINE_UPDATE");
	self:RegisterEvent("QUEST_LOG_UPDATE");
	self:RegisterEvent("WORLD_QUEST_COMPLETED_BY_SPELL");
	self:RegisterEvent("MINIMAP_UPDATE_TRACKING");
	-- added events
	self:RegisterEvent("MODIFIER_STATE_CHANGED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")

	self:SetClampRectInsets(0, 0, 0, -60);-- don't overlap the xp/rep bars
	self.poiHighlight = nil;
	self.areaName = nil;
	--OmegaMapFrame_Update();

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
	
	--local frameLevel = OmegaMapDetailFrame:GetFrameLevel();
	--OmegaMapPlayersFrame:SetFrameLevel(frameLevel + 1);
	--OmegaMapPOIFrame:SetFrameLevel(frameLevel + 2);
	--OmegaMapOtherPOIFrame:SetFrameLevel(frameLevel + 2);
	--OmegaMapFrame.UIElementsFrame:SetFrameLevel(frameLevel + 3);

	QUEST_POI_FRAME_WIDTH = OmegaMapDetailFrame:GetWidth();
	QUEST_POI_FRAME_HEIGHT = OmegaMapDetailFrame:GetHeight();
	QuestPOI_Initialize(OmegaMapPOIFrame, OmegaMapPOIButton_Init);



--Disable Mouse interaction with the map
	OmegaMapButton:EnableMouse(false); --set to false to enable click trhough
	--OmegaMapPlayerUpper:EnableMouse(false);

	OmegaMapFrame.UIElementsFrame.BountyBoard:SetSelectedBountyChangedCallback(OmegaMapFrame_SetBonusObjectivesDirty);
	--OmegaMapFrame.UIElementsFrame.ActionButton:SetOnCastChangedCallback(OmegaMapFrame_SetBonusObjectivesDirty);

	OmegaMapUnitPositionFrame:SetPlayerPingTexture(1, "Interface\\minimap\\UI-Minimap-Ping-Center", 32, 32);
	OmegaMapUnitPositionFrame:SetPlayerPingTexture(2, "Interface\\minimap\\UI-Minimap-Ping-Expand", 32, 32);
	OmegaMapUnitPositionFrame:SetPlayerPingTexture(3, "Interface\\minimap\\UI-Minimap-Ping-Rotate", 70, 70);

	OmegaMapUnitPositionFrame:SetMouseOverUnitExcluded("player", true);
	OmegaMapUnitPositionFrame:SetPinTexture("player", "Interface\\WorldMap\\WorldMapArrow");

	local WORLD_QUEST_NUM_CELLS_HIGH = 75;
	local WORLD_QUEST_NUM_CELLS_WIDE = math.ceil(WORLD_QUEST_NUM_CELLS_HIGH * 1002/668);

	self.poiQuantizer = CreateFromMixins(WorldMapPOIQuantizerMixin);
	self.poiQuantizer:OnLoad(WORLD_QUEST_NUM_CELLS_WIDE, WORLD_QUEST_NUM_CELLS_HIGH);
	self.flagsPool = CreateFramePool("FRAME", OmegaMapButton, "WorldMapFlagTemplate");

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

function OmegaMapFrame_SetBonusObjectivesDirty() 
	OmegaMapFrame.bonusObjectiveUpdateTimeLeft = 0;
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
	PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN);
	CloseDropDownMenus();
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
	PlaySound(SOUNDKIT.IG_QUEST_LOG_CLOSE);

	--New 6.0  REvisist
	if ( not self.toggling ) then
		OmegaMapQuestFrame_CloseQuestDetails();
	end
	if ( OmegaMapScrollFrame.zoomedIn ) then
		OmegaMapScrollFrame_ResetZoom();
	end
	-- 

	OmegaMapUnitPositionFrame:StopPlayerPing();
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
	self.dungeonLevel = nil;

	self.AnimAlphaOut:Stop();
	self.AnimAlphaIn:Stop();
	--self:SetAlpha(WORLD_MAP_MAX_ALPHA);

	self.bonusObjectiveUpdateTimeLeft = nil;

	OmegaMapOverlayHighlights = {};

	--self.UIElementsFrame.ActionButton:SetMapAreaID(nil);
	--self.UIElementsFrame.ActionButton:SetHasWorldQuests(false);
	OmegaMapPOIFrame.POIPing:Stop();

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

		OmegaMapSliderFrame:SetValue(OmegaMapConfig.opacity);
		--OmegaMapQuestShowObjectives_Toggle();
		OmegaMapMasterFrame:SetScale(OmegaMapConfig.scale);
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

	local duration = ((endAlpha - startAlpha) / (WORLD_MAP_MAX_ALPHA - WORLD_MAP_MIN_ALPHA)) * tonumber(GetCVar("mapAnimDuration"));
	anim.Alpha:SetFromAlpha(startAlpha);
	anim.Alpha:SetToAlpha(endAlpha);
	anim.Alpha:SetDuration(abs(duration));
	anim.Alpha:SetStartDelay(startDelay);
	anim:Play();
end

local TIME_BETWEEN_BONUS_OBJECTIVE_REFRESH_SECS = 10;
function OmegaMapFrame_OnUpdate(self, elapsed)
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

	self.bonusObjectiveUpdateTimeLeft = (self.bonusObjectiveUpdateTimeLeft or TIME_BETWEEN_BONUS_OBJECTIVE_REFRESH_SECS) - elapsed;
	if ( self.bonusObjectiveUpdateTimeLeft <= 0 ) then
		OmegaMap_UpdateQuestBonusObjectives();
		self.bonusObjectiveUpdateTimeLeft = TIME_BETWEEN_BONUS_OBJECTIVE_REFRESH_SECS;
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
local function ApplyTextureToPOI(texture, width, height)
	texture:SetTexCoord(0, 1, 0, 1);
	texture:ClearAllPoints();
	texture:SetPoint("CENTER", texture:GetParent());
	texture:SetSize(width or 32, height or 32);
end

local function ApplyAtlasTexturesToPOI(button, normal, pushed, highlight, width, height)
	button:SetSize(20, 20);
	button:SetNormalAtlas(normal);
	ApplyTextureToPOI(button:GetNormalTexture(), width, height);

	button:SetPushedAtlas(pushed);
	ApplyTextureToPOI(button:GetPushedTexture(), width, height);

	button:SetHighlightAtlas(highlight);
	ApplyTextureToPOI(button:GetHighlightTexture(), width, height);

	if button.SelectedGlow then
		button.SelectedGlow:SetAtlas(pushed);
		ApplyTextureToPOI(button.SelectedGlow, width, height);
	end
end

local function ApplyStandardTexturesToPOI(button, selected)
	button:SetSize(20, 20);
	button:SetNormalTexture("Interface/WorldMap/UI-QuestPoi-NumberIcons");
	ApplyTextureToPOI(button:GetNormalTexture());
	if selected then
		button:GetNormalTexture():SetTexCoord(0.500, 0.625, 0.375, 0.5);
	else
		button:GetNormalTexture():SetTexCoord(0.875, 1, 0.375, 0.5);
	end
	

	button:SetPushedTexture("Interface/WorldMap/UI-QuestPoi-NumberIcons");
	ApplyTextureToPOI(button:GetPushedTexture());
	if selected then
		button:GetPushedTexture():SetTexCoord(0.375, 0.500, 0.375, 0.5);
	else
		button:GetPushedTexture():SetTexCoord(0.750, 0.875, 0.375, 0.5);
	end

	button:SetHighlightTexture("Interface/WorldMap/UI-QuestPoi-NumberIcons");
	ApplyTextureToPOI(button:GetHighlightTexture());
	button:GetHighlightTexture():SetTexCoord(0.625, 0.750, 0.875, 1);
end

function OmegaMap_IsWorldQuestEffectivelyTracked(questID)
	return IsWorldQuestHardWatched(questID) or (IsWorldQuestWatched(questID) and GetSuperTrackedQuestID() == questID);
end

function OmegaMap_SetupWorldQuestButton(button, worldQuestType, rarity, isElite, tradeskillLineIndex, inProgress, selected, isCriteria, isSpellTarget, isEffectivelyTracked)
	button.Glow:SetShown(selected);
	if rarity == LE_WORLD_QUEST_QUALITY_COMMON then
		ApplyStandardTexturesToPOI(button, selected);
	elseif rarity == LE_WORLD_QUEST_QUALITY_RARE then
		ApplyAtlasTexturesToPOI(button, "worldquest-questmarker-rare", "worldquest-questmarker-rare-down", "worldquest-questmarker-rare", 18, 18);
	elseif rarity == LE_WORLD_QUEST_QUALITY_EPIC then
		ApplyAtlasTexturesToPOI(button, "worldquest-questmarker-epic", "worldquest-questmarker-epic-down", "worldquest-questmarker-epic", 18, 18);
	end

	if ( button.SelectedGlow ) then
		button.SelectedGlow:SetShown(rarity ~= LE_WORLD_QUEST_QUALITY_COMMON and selected);
	end

	if ( isElite ) then
		button.Underlay:SetAtlas("worldquest-questmarker-dragon");
		button.Underlay:Show();
	else
		button.Underlay:Hide();
	end

	local tradeskillLineID = tradeskillLineIndex and select(7, GetProfessionInfo(tradeskillLineIndex));
	if ( worldQuestType == LE_QUEST_TAG_TYPE_PVP ) then
		if ( inProgress ) then
			button.Texture:SetAtlas("worldquest-questmarker-questionmark");
			button.Texture:SetSize(10, 15);
		else
			button.Texture:SetAtlas("worldquest-icon-pvp-ffa", true);
		end
	elseif ( worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE ) then
		if ( inProgress ) then
			button.Texture:SetAtlas("worldquest-questmarker-questionmark");
			button.Texture:SetSize(10, 15);
		else
			button.Texture:SetAtlas("worldquest-icon-petbattle", true);
		end
	elseif ( worldQuestType == LE_QUEST_TAG_TYPE_PROFESSION and WORLD_QUEST_ICONS_BY_PROFESSION[tradeskillLineID] ) then
		if ( inProgress ) then
			button.Texture:SetAtlas("worldquest-questmarker-questionmark");
			button.Texture:SetSize(10, 15);
		else
			button.Texture:SetAtlas(WORLD_QUEST_ICONS_BY_PROFESSION[tradeskillLineID], true);
		end
	elseif ( worldQuestType == LE_QUEST_TAG_TYPE_DUNGEON ) then
		if ( inProgress ) then
			button.Texture:SetAtlas("worldquest-questmarker-questionmark");
			button.Texture:SetSize(10, 15);
		else
			button.Texture:SetAtlas("worldquest-icon-dungeon", true);
		end
	elseif ( worldQuestType == LE_QUEST_TAG_TYPE_RAID ) then
		if ( inProgress ) then
			button.Texture:SetAtlas("worldquest-questmarker-questionmark");
			button.Texture:SetSize(10, 15);
		else
			button.Texture:SetAtlas("worldquest-icon-raid", true);
		end
	elseif ( worldQuestType == LE_QUEST_TAG_TYPE_INVASION ) then
		if ( inProgress ) then
			button.Texture:SetAtlas("worldquest-questmarker-questionmark");
			button.Texture:SetSize(10, 15);
		else
			button.Texture:SetAtlas("worldquest-icon-burninglegion", true);
		end
	else
		if ( inProgress ) then
			button.Texture:SetAtlas("worldquest-questmarker-questionmark");
			button.Texture:SetSize(10, 15);
		else
			button.Texture:SetAtlas("worldquest-questmarker-questbang");
			button.Texture:SetSize(6, 15);
		end
	end

	if ( button.TimeLowFrame ) then
		button.TimeLowFrame:Hide();
	end

	if ( button.CriteriaMatchRing ) then
		button.CriteriaMatchRing:SetShown(isCriteria);
	end

	if ( button.TrackedCheck ) then
		button.TrackedCheck:SetShown(isEffectivelyTracked);
	end

	if ( button.SpellTargetGlow ) then
		button.SpellTargetGlow:SetShown(isSpellTarget);
	end
end

function OmegaMap_DoesWorldQuestInfoPassFilters(info, ignoreTypeFilters)
	local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, displayTimeLeft = GetQuestTagInfo(info.questId);

	if ( not ignoreTypeFilters ) then
		if ( worldQuestType == LE_QUEST_TAG_TYPE_PROFESSION ) then
			local prof1, prof2, arch, fish, cook, firstAid = GetProfessions();

			if ( tradeskillLineIndex == prof1 or tradeskillLineIndex == prof2 ) then
				if ( not GetCVarBool("primaryProfessionsFilter") ) then
					return false;
				end
			end

			if ( tradeskillLineIndex == fish or tradeskillLineIndex == cook or tradeskillLineIndex == firstAid ) then
				if ( not GetCVarBool("secondaryProfessionsFilter") ) then
					return false;
				end
			end
		elseif ( worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE ) then
			if ( not GetCVarBool("showTamers") ) then
				return false;
			end
		else
			local dataLoaded, worldQuestRewardType = WorldMap_GetWorldQuestRewardType(info.questId);

			if ( not dataLoaded ) then
				return false;
			end

			local typeMatchesFilters = false;
			if ( GetCVarBool("worldQuestFilterGold") and bit.band(worldQuestRewardType, WORLD_QUEST_REWARD_TYPE_FLAG_GOLD) ~= 0 ) then
				typeMatchesFilters = true;
			elseif ( GetCVarBool("worldQuestFilterOrderResources") and bit.band(worldQuestRewardType, WORLD_QUEST_REWARD_TYPE_FLAG_ORDER_RESOURCES) ~= 0 ) then
				typeMatchesFilters = true;
			elseif ( GetCVarBool("worldQuestFilterArtifactPower") and bit.band(worldQuestRewardType, WORLD_QUEST_REWARD_TYPE_FLAG_ARTIFACT_POWER) ~= 0 ) then
				typeMatchesFilters = true;
			elseif ( GetCVarBool("worldQuestFilterProfessionMaterials") and bit.band(worldQuestRewardType, WORLD_QUEST_REWARD_TYPE_FLAG_MATERIALS) ~= 0 ) then
				typeMatchesFilters = true;
			elseif ( GetCVarBool("worldQuestFilterEquipment") and bit.band(worldQuestRewardType, WORLD_QUEST_REWARD_TYPE_FLAG_EQUIPMENT) ~= 0 ) then
				typeMatchesFilters = true;
			end

			-- We always want to show quests that do not fit any of the enumerated reward types.
			if ( worldQuestRewardType ~= 0 and not typeMatchesFilters ) then
				return false;
			end
		end
	end

	return true;
end

function OmegaMap_TryCreatingWorldQuestPOI(info, taskIconIndex)
	if ( OmegaMap_IsWorldQuestSuppressed(info.questId) or not OmegaMap_DoesWorldQuestInfoPassFilters(info) ) then
		return nil;

	end

	local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, displayTimeLeft = GetQuestTagInfo(info.questId);

	local taskPOI = OmegaMap_GetOrCreateTaskPOI(taskIconIndex);
	local selected = info.questId == GetSuperTrackedQuestID();

	local isCriteria = OmegaMapFrame.UIElementsFrame.BountyBoard:IsWorldQuestCriteriaForSelectedBounty(info.questId);
	local isSpellTarget = SpellCanTargetQuest() and IsQuestIDValidSpellTarget(info.questId);
	local isEffectivelyTracked = OmegaMap_IsWorldQuestEffectivelyTracked(info.questId);

	taskPOI.worldQuest = true;
	taskPOI.Texture:SetDrawLayer("OVERLAY");

	OmegaMap_SetupWorldQuestButton(taskPOI, worldQuestType, rarity, isElite, tradeskillLineIndex, info.inProgress, selected, isCriteria, isSpellTarget, isEffectivelyTracked);

	C_TaskQuest.RequestPreloadRewardData(info.questId);

	return taskPOI;
end

function OmegaMap_TryCreatingBonusObjectivePOI(info, taskIconIndex)
	local taskPOI = OmegaMap_GetOrCreateTaskPOI(taskIconIndex);
	taskPOI:SetSize(24, 24);
	taskPOI:SetNormalTexture(nil);
	taskPOI:SetPushedTexture(nil);
	taskPOI:SetHighlightTexture(nil);
	taskPOI.Underlay:Hide();
	taskPOI.Texture:SetAtlas("QuestBonusObjective");
	taskPOI.Texture:SetSize(24, 24);
	taskPOI.Texture:SetDrawLayer("BACKGROUND");
	taskPOI.TimeLowFrame:Hide();
	taskPOI.CriteriaMatchRing:Hide();
	taskPOI.TrackedCheck:Hide();
	taskPOI.SpellTargetGlow:Hide();
	taskPOI.Glow:Hide();
	taskPOI.SelectedGlow:Hide();
	taskPOI.worldQuest = false;

	return taskPOI;
end

----
function OmegaMap_GetActiveTaskPOIForQuestID(questID)
	for i = 1, NUM_OMEGAMAP_TASK_POIS do
		local taskPOI = _G["OmegaMapFrameTaskPOI"..i];
		if taskPOI and taskPOI.questID == questID and taskPOI:IsShown() then
			return taskPOI;
		end
	end
end

function OmegaMap_UpdateQuestBonusObjectives()
	local showOnlyInvasionWorldQuests = false;
	if ( OmegaMapQuestFrame.DetailsFrame.questID ) then
		-- Hide all task POIs while the player looks at quest details.
		-- but for invasion quests we're gonna show all the invasion world quests
		if ( IsQuestInvasion(OmegaMapQuestFrame.DetailsFrame.questID) ) then
			showOnlyInvasionWorldQuests = true;
		else
			for i = 1, NUM_OMEGAMAP_TASK_POIS do
				_G["OmegaMapFrameTaskPOI"..i]:Hide();
			end
			return;
		end
	end

	local mapAreaID = GetCurrentMapAreaID();
	local taskInfo = C_TaskQuest.GetQuestsForPlayerByMapID(mapAreaID);
	local numTaskPOIs = 0;
	if(taskInfo ~= nil) then
		numTaskPOIs = #taskInfo;
	end

	--Ensure the button pool is big enough for all the world effect POI's
	if ( NUM_OMEGAMAP_TASK_POIS < numTaskPOIs ) then
		for i=NUM_OMEGAMAP_TASK_POIS+1, numTaskPOIs do
			OmegaMap_GetOrCreateTaskPOI(i);
		end
		NUM_OMEGAMAP_TASK_POIS = numTaskPOIs;
	end

	local taskIconIndex = 1;
	local worldQuestPOIs = {};

	if ( numTaskPOIs > 0 ) then
		for i, info  in ipairs(taskInfo) do
			if ( HaveQuestData(info.questId) ) then
				local taskPOI;
				local isWorldQuest = QuestUtils_IsQuestWorldQuest(info.questId);
				if ( isWorldQuest ) then
					local showThisWorldQuest = true;
					if ( showOnlyInvasionWorldQuests ) then
						local _, _, worldQuestType = GetQuestTagInfo(info.questId);
						if ( worldQuestType ~= LE_QUEST_TAG_TYPE_INVASION ) then
							showThisWorldQuest = false;
						end
					end
					if ( showThisWorldQuest ) then
						taskPOI = OmegaMap_TryCreatingWorldQuestPOI(info, taskIconIndex);
					end
				elseif ( not showOnlyInvasionWorldQuests ) then
					taskPOI = OmegaMap_TryCreatingBonusObjectivePOI(info, taskIconIndex);
				end

				if ( taskPOI ) then
					taskPOI.x = info.x;
					taskPOI.y = info.y;
					taskPOI.quantizedX = nil;
					taskPOI.quantizedY = nil;
					taskPOI.questID = info.questId;
					taskPOI.numObjectives = info.numObjectives;
					taskPOI:Show();

					taskIconIndex = taskIconIndex + 1;

					if ( isWorldQuest ) then
						worldQuestPOIs[#worldQuestPOIs + 1] = taskPOI;
					else
						OmegaMapPOIFrame_AnchorPOI(taskPOI, info.x, info.y, WORLD_MAP_POI_FRAME_LEVEL_OFFSETS.BONUS_OBJECTIVE);
					end

					OmegaMapPing_UpdatePing(taskPOI, info.questId);
				end
			end
		end
	end
	
	-- Hide unused icons in the pool
	for i = taskIconIndex, NUM_OMEGAMAP_TASK_POIS do
		_G["OmegaMapFrameTaskPOI"..i]:Hide();
	end

	--OmegaMapFrame.UIElementsFrame.ActionButton:SetHasWorldQuests(#worldQuestPOIs > 0);
	OmegaMap_QuantizeWorldQuestPOIs(worldQuestPOIs);
end

function OmegaMap_QuantizeWorldQuestPOIs(worldQuestPOIs)
	OmegaMapFrame.poiQuantizer:Clear();
	OmegaMapFrame.poiQuantizer:Quantize(worldQuestPOIs);

	for i, worldQuestPOI in ipairs(worldQuestPOIs) do
		OmegaMapPOIFrame_AnchorPOI(worldQuestPOI, worldQuestPOI.quantizedX or worldQuestPOI.x, worldQuestPOI.quantizedY or worldQuestPOI.y, WORLD_MAP_POI_FRAME_LEVEL_OFFSETS.WORLD_QUEST);
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
		for _, info  in pairs(scenarioIconInfo) do
		
			--textureIndex, x, y, name
			local textureIndex = info.index;
			local x = info.x;
			local y = info.y;
			local name = info.description;
			
			local scenarioPOIName = "OmegaMapFrameScenarioPOI"..scenarioIconCount;
			local scenarioPOI = _G[scenarioPOIName];
			
			local x1, x2, y1, y2 = GetObjectIconTextureCoords(textureIndex);
			_G[scenarioPOIName.."Texture"]:SetTexCoord(x1, x2, y1, y2);
			OmegaMapPOIFrame_AnchorPOI(scenarioPOI, x, y, WORLD_MAP_POI_FRAME_LEVEL_OFFSETS.SCENARIO);
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

function OmegaMap_ShouldShowLandmark(landmarkType)
	if not landmarkType then
		return false;
	end

	if landmarkType == LE_MAP_LANDMARK_TYPE_DIGSITE then
		return GetCVarBool("digSites");
	end

	if landmarkType == LE_MAP_LANDMARK_TYPE_TAMER then
		return GetCVarBool("showTamers");
	end

	return true;
end

function OmegaMapPOI_ShouldShowAreaLabel(poi)
	if poi.landmarkType == LE_MAP_LANDMARK_TYPE_CONTRIBUTION or poi.landmarkType == LE_MAP_LANDMARK_TYPE_INVASION then
		return false;
	end
	if poi.poiID and C_WorldMap.IsAreaPOITimed(poi.poiID) then
		return false;
	end

	return true;
end

function OmegaMap_GetFrameLevelForLandmark(landmarkType)
	if landmarkType == LE_MAP_LANDMARK_TYPE_INVASION then
		return WORLD_MAP_POI_FRAME_LEVEL_OFFSETS.INVASION;
	elseif landmarkType == LE_MAP_LANDMARK_TYPE_DUNGEON_ENTRANCE then
		return WORLD_MAP_POI_FRAME_LEVEL_OFFSETS.DUNGEON_ENTRANCE;
	elseif landmarkType == LE_MAP_LANDMARK_TYPE_TAXINODE then
		return WORLD_MAP_POI_FRAME_LEVEL_OFFSETS.TAXINODE;
	elseif landmarkType == LE_MAP_LANDMARK_TYPE_MAP_LINK then
		return WORLD_MAP_POI_FRAME_LEVEL_OFFSETS.MAP_LINK
	end
	return WORLD_MAP_POI_FRAME_LEVEL_OFFSETS.LANDMARK;
end

function OmegaMap_DoesCurrentMapHideMapIcons(mapID)
	local isArgusContinent = GetCurrentMapAreaID() == 1184;
	return isArgusContinent;
end

local NUM_WORLDMAP_POIS = 0; 
local areaPOIBannerLabelTextureInfo = {};

function OmegaMap_UpdateLandmarks()
	if WorldMap_DoesCurrentMapHideMapIcons() then
		for i = 1, NUM_WORLDMAP_POIS do
			local omegaMapPOI = _G["OmegaMapFramePOI"..i];
			omegaMapPOI:Hide();
		end
		return;
	end
	local numPOIs = GetNumMapLandmarks();
	if ( NUM_WORLDMAP_POIS < numPOIs ) then
		for i=NUM_WORLDMAP_POIS+1, numPOIs do
			OmegaMap_CreatePOI(i);
		end
		NUM_WORLDMAP_POIS = numPOIs;
	end
	local numGraveyards = 0;
	local currentGraveyard = GetCemeteryPreference();
	local mapID = GetCurrentMapAreaID();
	OmegaMapFrame_ClearAreaLabel(WORLDMAP_AREA_LABEL_TYPE.AREA_POI_BANNER);
	OmegaMapAreaPOIBannerOverlay:Hide();

	if OmegaMapFrame.mapLinkPingInfo and GetCurrentMapAreaID() ~= OmegaMapFrame.mapLinkPingInfo.mapID then
		OmegaMapFrame.mapLinkPingInfo = nil;
	end

	for i=1, NUM_WORLDMAP_POIS do
		local omegaMapPOIName = "OmegaMapFramePOI"..i;
		local omegaMapPOI = _G[omegaMapPOIName];
		if ( i <= numPOIs ) then
			local landmarkType, name, description, textureIndex, x, y, mapLinkID, inBattleMap, graveyardID, areaID, poiID, isObjectIcon, atlasIcon, displayAsBanner, mapFloor, textureKitPrefix = C_WorldMap.GetMapLandmarkInfo(i);
			if( not OmegaMap_ShouldShowLandmark(landmarkType) or (mapID ~= WORLDMAP_WINTERGRASP_ID and areaID == WORLDMAP_WINTERGRASP_POI_AREAID) or displayAsBanner ) then

				omegaMapPOI:Hide();
			else
				OmegaMapPOIFrame_AnchorPOI(omegaMapPOI, x, y, OmegaMap_GetFrameLevelForLandmark(landmarkType));
				if ( landmarkType == LE_MAP_LANDMARK_TYPE_NORMAL and OmegaMap_IsSpecialPOI(poiID) ) then	--We have special handling for Isle of the Thunder King
					OmegaMap_HandleSpecialPOI(omegaMapPOI, poiID);
				else
					OmegaMap_ResetPOI(omegaMapPOI, isObjectIcon, atlasIcon, textureKitPrefix);



					if (not atlasIcon) then
						local x1, x2, y1, y2;
						if (isObjectIcon) then
							x1, x2, y1, y2 = GetObjectIconTextureCoords(textureIndex);
						else
							x1, x2, y1, y2 = GetPOITextureCoords(textureIndex);
						end
						omegaMapPOI.Texture:SetTexCoord(x1, x2, y1, y2);
						omegaMapPOI.HighlightTexture:SetTexCoord(x1, x2, y1, y2);
					else
						omegaMapPOI.Texture:SetTexCoord(0, 1, 0, 1);
						omegaMapPOI.HighlightTexture:SetTexCoord(0, 1, 0, 1);
					end

					omegaMapPOI.name = name;
					omegaMapPOI.description = description;
					omegaMapPOI.mapLinkID = mapLinkID;
					omegaMapPOI.mapFloor = mapFloor;
					omegaMapPOI.poiID = poiID;
					omegaMapPOI.landmarkType = landmarkType;
					omegaMapPOI.textureKitPrefix = textureKitPrefix;

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

					else
						omegaMapPOI.graveyard = nil;
					end
					omegaMapPOI:Hide();		-- lame way to force tooltip redraw
					omegaMapPOI:Show();

					local pingInfo = OmegaMapFrame.mapLinkPingInfo;
					if pingInfo and landmarkType == LE_MAP_LANDMARK_TYPE_MAP_LINK and mapFloor == pingInfo.floorIndex then
						OmegaMapPing_StartPingPOI(OmegaMapPOI);
					end

				end
			end
			if (displayAsBanner) then
				local timeLeftMinutes = C_WorldMap.GetAreaPOITimeLeft(poiID);
				local descriptionLabel = nil;
				if (timeLeftMinutes) then
					local hoursLeft = math.floor(timeLeftMinutes / 60);
					local minutesLeft = timeLeftMinutes % 60;
					descriptionLabel = INVASION_TIME_FORMAT:format(hoursLeft, minutesLeft)
				end

				local x1, x2, y1, y2;
				if (not atlasIcon) then
					if (isObjectIcon) then
						x1, x2, y1, y2 = GetObjectIconTextureCoords(textureIndex);
					else
						x1, x2, y1, y2 = GetPOITextureCoords(textureIndex);
					end
				else
					x1, x2, y1, y2 = 0, 1, 0, 1;
				end

				areaPOIBannerLabelTextureInfo.x1 = x1;
				areaPOIBannerLabelTextureInfo.x2 = x2;
				areaPOIBannerLabelTextureInfo.y1 = y1;
				areaPOIBannerLabelTextureInfo.y2 = y2;
				areaPOIBannerLabelTextureInfo.texture = OmegaMapFrameAreaLabelTexture;
				areaPOIBannerLabelTextureInfo.atlasIcon = atlasIcon;
				areaPOIBannerLabelTextureInfo.isObjectIcon = isObjectIcon;

				OmegaMapFrame_SetAreaLabel(WORLDMAP_AREA_LABEL_TYPE.AREA_POI_BANNER, name, descriptionLabel, INVASION_FONT_COLOR, INVASION_DESCRIPTION_FONT_COLOR, OmegaMapFrame_OnAreaPOIBannerVisibilityChanged);
				OmegaMapAreaPOIBannerOverlay:Show();
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
	OmegaMapFrame.mapLinkPingInfo = nil;
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

		else
			-- Temporary Hack (Temporary meaning 14 yrs, haha)
			mapName = "World";
		end
	end
	OmegaMapFrame_UpdateCosmicButtons();

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

	OmegaMap_UpdateLandmarks();
	OmegaMap_DrawWorldEffects();
	OmegaMapFrame.UIElementsFrame.BountyBoard:SetMapAreaID(mapID);
	--OmegaMapFrame.UIElementsFrame.ActionButton:SetMapAreaID(mapID);
	OmegaMapFrame_UpdateOverlayLocations();
	OmegaMap_UpdateQuestBonusObjectives();

	-- Setup the overlays
	local textureCount = 0;
	OmegaMapOverlayHighlights = {};

	for i=1, GetNumMapOverlays() do
		local textureName, textureWidth, textureHeight, offsetX, offsetY, isShownByMouseOver = GetMapOverlayInfo(i);
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
					if isShownByMouseOver == true then
						-- keep track of the textures to show by mouseover
						texture:SetDrawLayer("ARTWORK", 1);
						texture:Hide();
						if ( not OmegaMapOverlayHighlights[i] ) then
							OmegaMapOverlayHighlights[i] = { };
						end
						table.insert(OmegaMapOverlayHighlights[i], texture);
					else
						texture:SetDrawLayer("ARTWORK", 0);
						texture:Show();
					end
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
			local questLineName, questName, x, y, isHidden, floorLocation, isLegendary = C_Questline.GetQuestlineInfoByIndex(i);

			local showQuest = questLineName and x > 0 and y > 0;
			if ( showQuest and isHidden ) then
				local _, _, active = GetTrackingInfo(MINIMAP_TRACK_HIDDEN_QUESTS);
				showQuest = active;
			end
			if ( showQuest ) then
				numUsedStoryLineFrames = numUsedStoryLineFrames + 1;
				local frame = STORYLINE_FRAMES[numUsedStoryLineFrames];
				if ( not frame ) then
					frame = CreateFrame("FRAME", "OmegaMapStoryLine"..numUsedStoryLineFrames, OmegaMapPOIFrame, "OmegaMapStoryLineTemplate");
					STORYLINE_FRAMES[numUsedStoryLineFrames] = frame;
				end
				frame.index = i;
				OmegaMapPOIFrame_AnchorPOI(frame, x, y, WORLD_MAP_POI_FRAME_LEVEL_OFFSETS.STORY_LINE);
				if ( isLegendary ) then
					frame.Texture:SetAtlas("QuestLegendary", true);
				elseif ( isHidden ) then
					frame.Texture:SetAtlas("TrivialQuests", true);
				else
					frame.Texture:SetAtlas("QuestNormal", true);
				end
				frame.Below:SetShown(floorLocation == LE_QUESTLINE_FLOOR_LOCATION_BELOW);
				frame.Above:SetShown(floorLocation == LE_QUESTLINE_FLOOR_LOCATION_ABOVE);
				frame.Texture:SetDesaturated(floorLocation ~= LE_QUESTLINE_FLOOR_LOCATION_SAME);

				frame:Show();
			end
		end
	end
	for i = numUsedStoryLineFrames + 1, #STORYLINE_FRAMES do
		STORYLINE_FRAMES[i]:Hide();
	end

	OmegaMapFrame_UpdateInvasion();

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

function OmegaMapFrame_SetOverlayLocation(frame, location)
	frame:ClearAllPoints();
	if location == LE_MAP_OVERLAY_DISPLAY_LOCATION_BOTTOM_LEFT then
		frame:SetPoint("BOTTOMLEFT", 15, 15);
	elseif location == LE_MAP_OVERLAY_DISPLAY_LOCATION_TOP_LEFT then
		frame:SetPoint("TOPLEFT", 15, -15);
	elseif location == LE_MAP_OVERLAY_DISPLAY_LOCATION_BOTTOM_RIGHT then
		frame:SetPoint("BOTTOMRIGHT", -18, 15);
	elseif location == LE_MAP_OVERLAY_DISPLAY_LOCATION_TOP_RIGHT then
		frame:SetPoint("TOPRIGHT", -15, -15);
	end
end

function OmegaMapFrame_UpdateOverlayLocations()
	local bountyBoard = OmegaMapFrame.UIElementsFrame.BountyBoard;
	local bountyBoardLocation = bountyBoard:GetDisplayLocation();
	if bountyBoardLocation then
		OmegaMapFrame_SetOverlayLocation(bountyBoard, bountyBoardLocation);
	end

	--local actionButton = OmegaMapFrame.UIElementsFrame.ActionButton;
	local useAlternateLocation = bountyBoardLocation == LE_MAP_OVERLAY_DISPLAY_LOCATION_BOTTOM_RIGHT;
	--local actionButtonLocation = actionButton:GetDisplayLocation(useAlternateLocation);
	--if actionButtonLocation then
		--OmegaMapFrame_SetOverlayLocation(actionButton, actionButtonLocation);
	--end
end

function OmegaMapFrame_OnAreaPOIBannerVisibilityChanged(visible)
	if (visible) then
		OmegaMap_SetupAreaPOIBannerTexture(areaPOIBannerLabelTextureInfo.texture, areaPOIBannerLabelTextureInfo.isObjectIcon, areaPOIBannerLabelTextureInfo.atlasIcon);
		areaPOIBannerLabelTextureInfo.texture:Show();
	else
		areaPOIBannerLabelTextureInfo.texture:Hide();
	end
end

function OmegaMapFrame_OnInvasionLabelVisibilityChanged(visible)
	if visible then
		OmegaMapFrameAreaLabelTexture:SetAtlas("legioninvasion-map-icon-portal-large");
		OmegaMapFrameAreaLabelTexture:SetSize(77, 81);
		OmegaMapFrameAreaLabelTexture:Show();
	else
		OmegaMapFrameAreaLabelTexture:Hide();
	end
end

function OmegaMapFrame_UpdateInvasion()
	local mapID, isContinent = GetCurrentMapAreaID();
	local name, timeLeftMinutes, rewardQuestID;
	if not isContinent then
		name, timeLeftMinutes, rewardQuestID = GetInvasionInfoByMapAreaID(mapID);
	end

	if name then
		OmegaMapInvasionOverlay:Show();
		local descriptionLabel;
		if timeLeftMinutes and mapID ~= GetPlayerMapAreaID("player") then -- only show the timer if you're not in that zone
			local hoursLeft = math.floor(timeLeftMinutes / 60);
			local minutesLeft = timeLeftMinutes % 60;
			descriptionLabel = INVASION_TIME_FORMAT:format(hoursLeft, minutesLeft)
		end
		OmegaMapFrame_SetAreaLabel(WORLDMAP_AREA_LABEL_TYPE.INVASION, MAP_UNDER_INVASION, descriptionLabel, INVASION_FONT_COLOR, INVASION_DESCRIPTION_FONT_COLOR, OmegaMapFrame_OnInvasionLabelVisibilityChanged);
	else
		OmegaMapInvasionOverlay:Hide();
		OmegaMapFrame_ClearAreaLabel(WORLDMAP_AREA_LABEL_TYPE.INVASION);
	end
end

do
	local areaLabelInfoByType = {};
	local areaLabelsDirty = false;
	function OmegaMapFrame_SetAreaLabel(areaLabelType, name, description, nameColor, descriptionColor, callback)
		if not areaLabelInfoByType[areaLabelType] then
			areaLabelInfoByType[areaLabelType] = {};
		end

		local areaLabelInfo = areaLabelInfoByType[areaLabelType];
		if areaLabelInfo.name ~= name or areaLabelInfo.description ~= description or not AreColorsEqual(areaLabelInfo.nameColor, nameColor) or not AreColorsEqual(areaLabelInfo.descriptionColor, descriptionColor) or areaLabelInfo.callback ~= callback then
			areaLabelInfo.name = name;
			areaLabelInfo.description = description;
			areaLabelInfo.nameColor = nameColor;
			areaLabelInfo.descriptionColor = descriptionColor;
			areaLabelInfo.callback = callback;
			
			areaLabelsDirty = true;
		end
	end

	function OmegaMapFrame_ClearAreaLabel(areaLabelType)
		if areaLabelInfoByType[areaLabelType] then
			OmegaMapFrame_SetAreaLabel(areaLabelType, nil);
		end
	end

	local pendingOnHideCallback;
	function OmegaMapFrame_EvaluateAreaLabels()
		if not areaLabelsDirty then
			return;
		end
		areaLabelsDirty = false;

		local highestPriorityAreaLabelType;

		for areaLabelName, areaLabelType in pairs(WORLDMAP_AREA_LABEL_TYPE) do
			local areaLabelInfo = areaLabelInfoByType[areaLabelType];
			if areaLabelInfo and areaLabelInfo.name then
				if not highestPriorityAreaLabelType or areaLabelType > highestPriorityAreaLabelType then
					highestPriorityAreaLabelType = areaLabelType;
				end
			end
		end

		if pendingOnHideCallback then
			pendingOnHideCallback(false);
			pendingOnHideCallback = nil;
		end

		if highestPriorityAreaLabelType then
			local areaLabelInfo = areaLabelInfoByType[highestPriorityAreaLabelType];
			OmegaMapFrameAreaLabel:SetText(areaLabelInfo.name);
			OmegaMapFrameAreaDescription:SetText(areaLabelInfo.description);

			if areaLabelInfo.nameColor then
				OmegaMapFrameAreaLabel:SetVertexColor(areaLabelInfo.nameColor:GetRGB());
			else
				OmegaMapFrameAreaLabel:SetVertexColor(AREA_NAME_FONT_COLOR:GetRGB());
			end

			if areaLabelInfo.descriptionColor then
				OmegaMapFrameAreaDescription:SetVertexColor(areaLabelInfo.descriptionColor:GetRGB());
			else
				OmegaMapFrameAreaDescription:SetVertexColor(AREA_DESCRIPTION_FONT_COLOR:GetRGB());
			end

			if areaLabelInfo.callback then
				areaLabelInfo.callback(true);
				pendingOnHideCallback = areaLabelInfo.callback;
			end
		else
			OmegaMapFrameAreaLabel:SetText("");
			OmegaMapFrameAreaDescription:SetText("");
		end
	end
end

function OmegaMap_DoesLandMarkTypeShowHighlights(landmarkType)
	if OmegaMapFrame_IsVindicaarTextureKit(textureKitPrefix) then
		return false;
	end

	return landmarkType == LE_MAP_LANDMARK_TYPE_NORMAL
		or landmarkType == LE_MAP_LANDMARK_TYPE_TAMER
		or landmarkType == LE_MAP_LANDMARK_TYPE_GOSSIP
		or landmarkType == LE_MAP_LANDMARK_TYPE_TAXINODE
		or landmarkType == LE_MAP_LANDMARK_TYPE_VIGNETTE
		or landmarkType == LE_MAP_LANDMARK_TYPE_INVASION
		or landmarkType == LE_MAP_LANDMARK_TYPE_CONTRIBUTION
		or landmarkType == LE_MAP_LANDMARK_TYPE_MAP_LINK;
end

function OmegaMapPOI_AddContributionsToTooltip(tooltip, ...)
	for i = 1, select("#", ...) do
		local contributionID = select(i, ...);
		local contributionName = C_ContributionCollector.GetName(contributionID);
		local state, stateAmount, timeOfNextStateChange = C_ContributionCollector.GetState(contributionID);
		local appearanceData = CONTRIBUTION_APPEARANCE_DATA[state];

		if i ~= 1 then
			tooltip:AddLine(" ");
		end

		tooltip:AddLine(contributionName, HIGHLIGHT_FONT_COLOR:GetRGB());

		local tooltipLine = appearanceData.tooltipLine;
		if tooltipLine then
			if timeOfNextStateChange and appearanceData.tooltipUseTimeRemaining then
				local time = math.max(timeOfNextStateChange - GetServerTime(), 60); -- Never display times below one minute
				tooltipLine = tooltipLine:format(SecondsToTime(time, true, true, 1));
			else
				tooltipLine = tooltipLine:format(FormatPercentage(stateAmount));
			end

			tooltip:AddLine(tooltipLine, appearanceData.stateColor:GetRGB());
		end
	end
end

function OmegaMapPOI_AddPOITimeLeftText(anchor, areaPoiID, name, description)
	if name and #name > 0 and description and #description > 0 and C_WorldMap.IsAreaPOITimed(areaPoiID) then
		OmegaMapTooltip:SetOwner(anchor, "ANCHOR_RIGHT");
		OmegaMapTooltip:SetText(HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(name));
		OmegaMapTooltip:AddLine(NORMAL_FONT_COLOR:WrapTextInColorCode(description));
		local timeLeftMinutes = C_WorldMap.GetAreaPOITimeLeft(areaPoiID);
		if timeLeftMinutes then
			local timeString = SecondsToTime(timeLeftMinutes * 60);
			OmegaMapTooltip:AddLine(BONUS_OBJECTIVE_TIME_LEFT:format(timeString), NORMAL_FONT_COLOR:GetRGB());
		end
		OmegaMapTooltip:Show();
	end
end

function OmegaMapPOI_OnEnter(self)
	OmegaMapFrame.poiHighlight = true;
	if ( self.specialPOIInfo and self.specialPOIInfo.onEnter ) then
		self.specialPOIInfo.onEnter(self, self.specialPOIInfo);
	else
		self.HighlightTexture:SetShown(OmegaMap_DoesLandMarkTypeShowHighlights(self.landmarkType, self.textureKitPrefix));

		if ( OmegaMapPOI_ShouldShowAreaLabel(self) ) then
			OmegaMapFrame_SetAreaLabel(WORLDMAP_AREA_LABEL_TYPE.POI, self.name, self.description);
		end

		if ( self.graveyard ) then
			OmegaMapTooltip:SetOwner(self, "ANCHOR_RIGHT");
			local r, g, b = HIGHLIGHT_FONT_COLOR:GetRGB();

			if ( self.graveyard == GetCemeteryPreference() ) then
				OmegaMapTooltip:SetText(GRAVEYARD_SELECTED);
				OmegaMapTooltip:AddLine(GRAVEYARD_SELECTED_TOOLTIP, r, g, b, true);
			else
				OmegaMapTooltip:SetText(GRAVEYARD_ELIGIBLE);
				OmegaMapTooltip:AddLine(GRAVEYARD_ELIGIBLE_TOOLTIP, r, g, b, true);
			end

			OmegaMapTooltip:Show();
		end

		if self.landmarkType == LE_MAP_LANDMARK_TYPE_INVASION then
			local name, timeLeftMinutes, rewardQuestID = GetInvasionInfo(self.poiID);

			OmegaMapTooltip:SetOwner(self, "ANCHOR_RIGHT");
			OmegaMapTooltip:SetText(name, HIGHLIGHT_FONT_COLOR:GetRGB());

			if timeLeftMinutes and timeLeftMinutes > 0 then
				local timeString = SecondsToTime(timeLeftMinutes * 60);
				OmegaMapTooltip:AddLine(BONUS_OBJECTIVE_TIME_LEFT:format(timeString), NORMAL_FONT_COLOR:GetRGB());
			end

			if rewardQuestID then
				if not HaveQuestData(rewardQuestID) then
					OmegaMapTooltip:AddLine(RETRIEVING_DATA, RED_FONT_COLOR:GetRGB());
				else
					GameTooltip_AddQuestRewardsToTooltip(OmegaMapTooltip, rewardQuestID);

				end
			end

			OmegaMapTooltip:Show();
		elseif self.landmarkType == LE_MAP_LANDMARK_TYPE_CONTRIBUTION then
			OmegaMapTooltip:SetOwner(self, "ANCHOR_RIGHT");
			OmegaMapTooltip:SetText(self.name, HIGHLIGHT_FONT_COLOR:GetRGB());
			OmegaMapTooltip:AddLine(" ");

			WorldMapPOI_AddContributionsToTooltip(OmegaMapTooltip, C_ContributionCollector.GetManagedContributionsForCreatureID(self.mapLinkID));

			OmegaMapTooltip:Show();
		else
			OmegaMapPOI_AddPOITimeLeftText(self, self.poiID, self.name, self.description);
		end
	end
end

function OmegaMapPOI_OnLeave(self)
	OmegaMapFrame.poiHighlight = nil;
	if ( self.specialPOIInfo and self.specialPOIInfo.onLeave ) then
		self.specialPOIInfo.onLeave(self, self.specialPOIInfo);
	else
		OmegaMapFrame_ClearAreaLabel(WORLDMAP_AREA_LABEL_TYPE.POI);
		OmegaMapTooltip:Hide();
	end

	self.HighlightTexture:Hide();
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
	v.onLeave = OmegaMap_ThunderIslePOI_OnLeave;
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
	OmegaMapTooltip:Hide();
end

local g_supressedWorldQuestTimeStamps = {};
function OmegaMap_AddWorldQuestSuppression(questID)
	g_supressedWorldQuestTimeStamps[questID] = GetTime();
	OmegaMapFrame_SetBonusObjectivesDirty();
end

local WORLD_QUEST_SUPPRESSION_TIME_SECS = 60.0;
function OmegaMap_IsWorldQuestSuppressed(questID)
	local lastSuppressedTime = g_supressedWorldQuestTimeStamps[questID];
	if lastSuppressedTime then
		if GetTime() - lastSuppressedTime < WORLD_QUEST_SUPPRESSION_TIME_SECS then
			return true;
		end
		g_supressedWorldQuestTimeStamps[questID] = nil;
	end
	return false;
end

function OmegaMap_OnWorldQuestCompletedBySpell(questID)
	local mapAreaID = GetCurrentMapAreaID();
	local x, y = C_TaskQuest.GetQuestLocation(questID, mapAreaID);
	if x and y then
		OmegaMap_AddWorldQuestSuppression(questID);
		local spellID, spellVisualKitID = GetWorldMapActionButtonSpellInfo();
		if spellVisualKitID then
			OmegaMapPOIFrame_AnchorPOI(OmegaMapPOIFrame.WorldQuestCompletedBySpellModel, x, y, 5000);
			OmegaMapPOIFrame.WorldQuestCompletedBySpellModel:SetCameraTarget(0, 0, 0);
			OmegaMapPOIFrame.WorldQuestCompletedBySpellModel:SetCameraPosition(0, 0, 25);
			OmegaMapPOIFrame.WorldQuestCompletedBySpellModel:SetSpellVisualKit(spellVisualKitID);
		end
	end
end

function OmegaMap_AddQuestTimeToTooltip(questID)
	local timeLeftMinutes = C_TaskQuest.GetQuestTimeLeftMinutes(questID);
	if ( timeLeftMinutes and timeLeftMinutes > 0 ) then
		local color = NORMAL_FONT_COLOR;
		if ( timeLeftMinutes <= WORLD_QUESTS_TIME_CRITICAL_MINUTES ) then
			color = RED_FONT_COLOR;
		end

		local timeString;
		if timeLeftMinutes <= 60 then
			timeString = SecondsToTime(timeLeftMinutes * 60);
		elseif timeLeftMinutes < 24 * 60  then
			timeString = D_HOURS:format(math.floor(timeLeftMinutes) / 60);
		else
			timeString = D_DAYS:format(math.floor(timeLeftMinutes) / 1440);
		end

		OmegaMapTooltip:AddLine(BONUS_OBJECTIVE_TIME_LEFT:format(timeString), color.r, color.g, color.b);
	end
end

function OmegaMapTaskPOI_OnEnter(self)
	OmegaMapTooltip:SetOwner(self, "ANCHOR_RIGHT");

	if ( not HaveQuestData(self.questID) ) then
		OmegaMapTooltip:SetText(RETRIEVING_DATA, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
		OmegaMapTooltip:Show();
		return;
	end

	local title, factionID, capped = C_TaskQuest.GetQuestInfoByQuestID(self.questID);
	if ( self.worldQuest ) then
		local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, displayTimeLeft = GetQuestTagInfo(self.questID);

		local color = WORLD_QUEST_QUALITY_COLORS[rarity];
		OmegaMapTooltip:SetText(title, color.r, color.g, color.b);
		QuestUtils_AddQuestTypeToTooltip(OmegaMapTooltip, self.questID, NORMAL_FONT_COLOR);

		if ( factionID ) then
			local factionName = GetFactionInfoByID(factionID);
			if ( factionName ) then
				if (capped) then
					OmegaMapTooltip:AddLine(factionName, GRAY_FONT_COLOR:GetRGB());
				else
					OmegaMapTooltip:AddLine(factionName);
				end
			end
		end

		if displayTimeLeft then
			OmegaMap_AddQuestTimeToTooltip(self.questID);
		end
	else
		OmegaMapTooltip:SetText(title);
	end

	for objectiveIndex = 1, self.numObjectives do
		local objectiveText, objectiveType, finished = GetQuestObjectiveInfo(self.questID, objectiveIndex, false);
		if ( objectiveText and #objectiveText > 0 ) then
			local color = finished and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
			OmegaMapTooltip:AddLine(QUEST_DASH .. objectiveText, color.r, color.g, color.b, true);
		end
	end

	local percent = C_TaskQuest.GetQuestProgressBarInfo(self.questID);
	if ( percent ) then
		GameTooltip_InsertFrame(OmegaMapTooltip, OmegaMapTaskTooltipStatusBar);
		OmegaMapTaskTooltipStatusBar.Bar:SetValue(percent);
		OmegaMapTaskTooltipStatusBar.Bar.Label:SetFormattedText(PERCENTAGE_STRING, percent);
	end

	GameTooltip_AddQuestRewardsToTooltip(OmegaMapTooltip, self.questID);

	if ( self.worldQuest and OmegaMapTooltip.AddDebugWorldQuestInfo ) then
		OmegaMapTooltip:AddDebugWorldQuestInfo(self.questID);
	end

	OmegaMapTooltip:Show();
	OmegaMapTooltip.recalculatePadding = true;

end

function OmegaMapTaskPOI_OnLeave(self)
	OmegaMapTooltip:Hide();
end

function OmegaMapTaskPOI_OnClick(self, button)
	if self.worldQuest then
		if SpellCanTargetQuest() then
		--print("`?????")
			--if IsQuestIDValidSpellTarget(self.questID) then
				--UseWorldMapActionButtonSpellOnQuest(self.questID);
				-- Assume success for responsiveness
				--OmegaMap_OnWorldQuestCompletedBySpell(self.questID);
			--else
				--UIErrorsFrame:AddMessage(WORLD_QUEST_CANT_COMPLETE_BY_SPELL, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
			--end
		else
			if ( not ChatEdit_TryInsertQuestLinkForQuestID(self.questID) ) then
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);

				if IsShiftKeyDown() then
					if IsWorldQuestHardWatched(self.questID) or (IsWorldQuestWatched(self.questID) and GetSuperTrackedQuestID() == self.questID) then
						BonusObjectiveTracker_UntrackWorldQuest(self.questID);
					else
						BonusObjectiveTracker_TrackWorldQuest(self.questID, true);
					end
				else
					if IsWorldQuestHardWatched(self.questID) then
						SetSuperTrackedQuestID(self.questID);
					else
						BonusObjectiveTracker_TrackWorldQuest(self.questID);
					end
				end
			end
		end
	end
end

function OmegaMapTaskPOI_OnHide(self)
	OmegaMapPing_StopPing(self);
end

function OmegaMapScenarioPOI_OnEnter(self)
	if(ScenarioPOITooltips[self.name] ~= nil) then
		OmegaMapTooltip:SetOwner(self, "ANCHOR_RIGHT");
		OmegaMapTooltip:SetText(ScenarioPOITooltips[self.name]);
		OmegaMapTooltip:Show();
	end
end

function OmegaMapScenarioPOI_OnLeave()
	OmegaMapTooltip:Hide();
end

function OmegaMapPOI_OnClick(self, button)
	if ( self.mapLinkID and self.landmarkType ~= LE_MAP_LANDMARK_TYPE_CONTRIBUTION ) then
		if self.landmarkType == LE_MAP_LANDMARK_TYPE_DUNGEON_ENTRANCE then
			if not EncounterJournal or not EncounterJournal:IsShown() then
				if not ToggleEncounterJournal() then
					return;
				end
			end
			EncounterJournal_ListInstances();
			EncounterJournal_DisplayInstance(self.mapLinkID);
		elseif self.landmarkType == LE_MAP_LANDMARK_TYPE_MAP_LINK then
			-- We need to cache this data in advance because it can change when we change map IDs.
			local currentMapID = GetCurrentMapAreaID();
			local currentFloorIndex = GetCurrentMapDungeonLevel();
			local mapID = self.mapLinkID
			local floorIndex = self.mapFloor;
			if floorIndex and mapID then
				SetMapByID(mapID);
				OmegaMapFrame.mapLinkPingInfo = { mapID = currentMapID, floorIndex = currentFloorIndex };
				SetDungeonMapLevel(floorIndex);
			elseif mapID then
				OmegaMapFrame.mapLinkPingInfo = { mapID = currentMapID, floorIndex = currentFloorIndex };
				SetMapByID(mapID);
			elseif floorIndex then
				OmegaMapFrame.mapLinkPingInfo = { mapID = currentMapID, floorIndex = currentFloorIndex };
				SetDungeonMapLevel(floorIndex);
			end
			
			PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN);
		else
			ClickLandmark(self.mapLinkID);
		end
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
	local button = CreateFrame("Button", "OmegaMapFramePOI"..index, OmegaMapPOIFrame);
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	button:SetScript("OnEnter", OmegaMapPOI_OnEnter);
	button:SetScript("OnLeave", OmegaMapPOI_OnLeave);
	button:SetScript("OnClick", OmegaMapPOI_OnClick);

	button.UpdateTooltip = OmegaMapPOI_OnEnter;

	button.Texture = button:CreateTexture(button:GetName().."Texture", "BACKGROUND");
	button.HighlightTexture = button:CreateTexture(button:GetName().."HighlightTexture", "HIGHLIGHT");
	button.HighlightTexture:SetBlendMode("ADD");
	button.HighlightTexture:SetAlpha(.4);
	button.HighlightTexture:SetAllPoints(button.Texture);

	OmegaMap_ResetPOI(button, isObjectIcon, atlasIcon);
end

function OmegaMap_SetupAreaPOIBannerTexture(texture, isObjectIcon, atlasIcon)
	if (atlasIcon) then
		texture:SetAtlas(atlasIcon);
	elseif (isObjectIcon == true) then
		texture:SetTexture("Interface\\Minimap\\ObjectIconsAtlas");
	else
		texture:SetTexture("Interface\\Minimap\\POIIcons");
	end
	texture:SetSize(77, 81);
end

local ATLAS_WITH_TEXTURE_KIT_PREFIX = "%s-%s";
function OmegaMap_ResetPOI(button, isObjectIcon, atlasIcon, textureKitPrefix)
	if (atlasIcon) then
		if (textureKitPrefix) then
			atlasIcon = ATLAS_WITH_TEXTURE_KIT_PREFIX:format(textureKitPrefix, atlasIcon);
		end
		button.Texture:SetAtlas(atlasIcon, true);
		if button.HighlightTexture then
			button.HighlightTexture:SetAtlas(atlasIcon, true);
		end
		local sizeX, sizeY = button.Texture:GetSize();
		if (textureKitPrefix == "FlightMaster_Argus") then
			sizeX = 21;
			sizeY = 18;
		end
		button.Texture:SetSize(sizeX, sizeY);
		button.HighlightTexture:SetSize(sizeX, sizeY);
		button:SetSize(sizeX, sizeY);
		button.Texture:SetPoint("CENTER", 0, 0);
	elseif (isObjectIcon == true) then
		button:SetWidth(32);
		button:SetHeight(32);
		button.Texture:SetWidth(28);
		button.Texture:SetHeight(28);
		button.Texture:SetPoint("CENTER", 0, 0);
		button.Texture:SetTexture("Interface\\Minimap\\ObjectIconsAtlas");
		if button.HighlightTexture then
			button.HighlightTexture:SetTexture("Interface\\Minimap\\ObjectIconsAtlas");
		end
	else
		button:SetWidth(32);
		button:SetHeight(32);
		button.Texture:SetWidth(16);
		button.Texture:SetHeight(16);
		button.Texture:SetPoint("CENTER", 0, 0);
		button.Texture:SetTexture("Interface\\Minimap\\POIIcons");
		if button.HighlightTexture then
			button.HighlightTexture:SetTexture("Interface\\Minimap\\POIIcons");
		end
	end

	button.specialPOIInfo = nil;
end

function OmegaMap_CreateWorldEffectPOI(index)
	local button = CreateFrame("Button", "OmegaMapFrameWorldEffectPOI"..index, OmegaMapPOIFrame);

	button:SetWidth(32);
	button:SetHeight(32);
	button:SetScript("OnEnter", OmegaMapEffectPOI_OnEnter);
	button:SetScript("OnLeave", OmegaMapEffectPOI_OnLeave);
	
	local texture = button:CreateTexture(button:GetName().."Texture", "BACKGROUND");
	texture:SetWidth(16);
	texture:SetHeight(16);
	texture:SetPoint("CENTER", 0, 0);
	texture:SetTexture("Interface\\Minimap\\ObjectIconsAtlas");
end

function OmegaMap_GetOrCreateTaskPOI(index)
	local existingButton = _G["OmegaMapFrameTaskPOI"..index];
	if existingButton then
		return existingButton;
	end

	local button = CreateFrame("Button", "OmegaMapFrameTaskPOI"..index, OmegaMapPOIFrame);
	button:SetFlattensRenderLayers(true);
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	button:SetScript("OnEnter", OmegaMapTaskPOI_OnEnter);
	button:SetScript("OnLeave", OmegaMapTaskPOI_OnLeave);
	button:SetScript("OnClick", OmegaMapTaskPOI_OnClick);
	button:SetScript("OnHide", OmegaMapTaskPOI_OnHide)

	button.UpdateTooltip = OmegaMapTaskPOI_OnEnter;
	
	button.Texture = button:CreateTexture(button:GetName().."Texture", "OVERLAY");

	button.Glow = button:CreateTexture(button:GetName().."Glow", "BACKGROUND", nil, -2);

	button.Glow:SetSize(50, 50);
	button.Glow:SetPoint("CENTER");
	button.Glow:SetTexture("Interface/WorldMap/UI-QuestPoi-IconGlow.tga");
	button.Glow:SetBlendMode("ADD");

	button.SelectedGlow = button:CreateTexture(button:GetName().."SelectedGlow", "OVERLAY", nil, 2);
	button.SelectedGlow:SetBlendMode("ADD");

	button.CriteriaMatchRing = button:CreateTexture(button:GetName().."CriteriaMatchRing", "BACKGROUND", nil, 2);
	button.CriteriaMatchRing:SetAtlas("worldquest-emissary-ring", true)
	button.CriteriaMatchRing:SetPoint("CENTER", 0, 0)
	
	button.SpellTargetGlow = button:CreateTexture(button:GetName().."SpellTargetGlow", "OVERLAY", nil, 1);
	button.SpellTargetGlow:SetAtlas("worldquest-questmarker-abilityhighlight", true);
	button.SpellTargetGlow:SetAlpha(.6);
	button.SpellTargetGlow:SetBlendMode("ADD");
	button.SpellTargetGlow:SetPoint("CENTER", 0, 0);

	button.Underlay = button:CreateTexture(button:GetName().."Underlay", "BACKGROUND");
	button.Underlay:SetWidth(34);
	button.Underlay:SetHeight(34);
	button.Underlay:SetPoint("CENTER", 0, -1);

	button.TimeLowFrame = CreateFrame("Frame", nil, button);
	button.TimeLowFrame:SetSize(22, 22);
	button.TimeLowFrame:SetPoint("CENTER", -10, -10);
	button.TimeLowFrame.Texture = button.TimeLowFrame:CreateTexture(nil, "OVERLAY");
	button.TimeLowFrame.Texture:SetAllPoints(button.TimeLowFrame);
	button.TimeLowFrame.Texture:SetAtlas("worldquest-icon-clock");

	button.TrackedCheck = button:CreateTexture(button:GetName().."TrackedCheck", "OVERLAY", nil, 1);
	button.TrackedCheck:SetAtlas("worldquest-emissary-tracker-checkmark", true);
	button.TrackedCheck:SetPoint("BOTTOM", button, "BOTTOMRIGHT", 0, -2);

	OmegaMap_ResetPOI(button, true, false);

	return button;
end

function OmegaMap_CreateScenarioPOI(index)
	local button = CreateFrame("Button", "OmegaMapFrameScenarioPOI"..index, OmegaMapPOIFrame);
	button:SetWidth(32);
	button:SetHeight(32);
	button:SetScript("OnEnter", OmegaMapScenarioPOI_OnEnter);
	button:SetScript("OnLeave", OmegaMapScenarioPOI_OnLeave);
	
	local texture = button:CreateTexture(button:GetName().."Texture", "BACKGROUND");
	texture:SetWidth(16);
	texture:SetHeight(16);
	texture:SetPoint("CENTER", 0, 0);
	texture:SetTexture("Interface\\Minimap\\ObjectIconsAtlas");
end

function OmegaMap_GetGraveyardButton(index)
	local frameName = "OmegaMapFrameGraveyard"..index;
	local button = _G[frameName];
	if ( not button ) then
		button = CreateFrame("Button", frameName, OmegaMapPOIFrame);
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

	local dungeonLevels = { GetNumDungeonMapLevels() };
	if ( #dungeonLevels <= 1 ) then
		UIDropDownMenu_ClearAll(OmegaMapLevelDropDown);
		OmegaMapLevelDropDown:Hide();
	else
		local level = GetCurrentMapDungeonLevel();
		if (DungeonUsesTerrainMap()) then
			level = level - 1;
		end

		-- find the current floor in the list of levels, that's its ID in the dropdown
		local levelID = 1;
		for id, floorNum in ipairs(dungeonLevels) do
			if (floorNum == level) then
				levelID = id;
			end
		end

		UIDropDownMenu_SetSelectedID(OmegaMapLevelDropDown, GetCurrentMapDungeonLevel());
		OmegaMapLevelDropDown:Show();
	end
end

function OmegaMapLevelDropDown_Initialize()
	local info = UIDropDownMenu_CreateInfo();
	local level = GetCurrentMapDungeonLevel();

	if (DungeonUsesTerrainMap()) then
		level = level - 1;
	end
	
	local mapname = strupper(GetMapInfo() or "");
	local dungeonLevels = { GetNumDungeonMapLevels() };
		
	for i, floorNum in ipairs(dungeonLevels) do
		local floornameToken = "DUNGEON_FLOOR_" .. mapname .. floorNum;
		local floorname =_G[floornameToken];
		info.text = floorname or string.format(FLOOR_NUMBER, i);
		info.func = OmegaMapLevelButton_OnClick;
		info.checked = (floorNum == level);
		UIDropDownMenu_AddButton(info);
	end
end

function OmegaMapLevelButton_OnClick(self)
	local dropDownID = self:GetID();
	UIDropDownMenu_SetSelectedID(OmegaMapLevelDropDown, dropDownID);

	local dungeonLevels = { GetNumDungeonMapLevels() };
	if (dropDownID <= #dungeonLevels) then
		local level = dungeonLevels[dropDownID];
		if (DungeonUsesTerrainMap()) then
			level = level + 1;
		end
		SetDungeonMapLevel(level);
		OmegaMapScrollFrame_ResetZoom()
	end
end

function OmegaMapZoomOutButton_OnClick()
	--PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	OmegaMapTooltip:Hide();
	WorldMapZoomOutButton_OnClick()

	--[[
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
	--]]
end

function OmegaMapButton_OnClick(button, mouseButton)
	if ( OmegaMapButton.ignoreClick ) then
		OmegaMapButton.ignoreClick = false;
		return;
	end
	CloseDropDownMenus();
	-- If currently over units then see if they should handle the click before moving on to the zoom
	if ( OmegaMap_HandleUnitClick(OmegaMapUnitPositionFrame:GetCurrentMouseOverUnits(), mouseButton) ) then
		return;
	elseif ( mouseButton == "LeftButton" ) then
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
	if ( OmegaMapScrollFrame:IsMouseOver() ) then
		name, fileName, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY, minLevel, maxLevel, petMinLevel, petMaxLevel = UpdateMapHighlight( adjustedX, adjustedY );

		for index,textures in pairs(OmegaMapOverlayHighlights) do
			local isHighlighted = IsMapOverlayHighlighted(index, adjustedX, adjustedY);
			for _,texture in pairs(textures) do
				if (isHighlighted == true) then
					texture:Show();
				else
					texture:Hide();
				end
			end
		end
	
	end
	
	OmegaMapFrameAreaPetLevels:SetText(""); --make sure pet level is cleared
	
	local effectiveAreaName = name;
	OmegaMapFrame_ClearAreaLabel(WORLDMAP_AREA_LABEL_TYPE.AREA_NAME);

	if ( not OmegaMapFrame.poiHighlight ) then
		OmegaMapFrame_UpdateInvasion();

		if ( OmegaMapFrame.maelstromZoneText ) then
			effectiveName = OmegaMapFrame.maelstromZoneText;
			minLevel = OmegaMapFrame.minLevel;
			name = OmegaMapFrame.maelstromZone
			maxLevel = OmegaMapFrame.maxLevel;
			petMinLevel = OmegaMapFrame.petMinLevel;
			petMaxLevel = OmegaMapFrame.petMaxLevel;
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
				effectiveAreaName = effectiveAreaName..color.." ("..minLevel.."-"..maxLevel..")"..FONT_COLOR_CODE_CLOSE;
			else
				effectiveAreaName = effectiveAreaName..color.." ("..maxLevel..")"..FONT_COLOR_CODE_CLOSE;
			end
		end

		OmegaMapFrame_SetAreaLabel(WORLDMAP_AREA_LABEL_TYPE.AREA_NAME, effectiveAreaName);

		local _, _, _, _, locked = C_PetJournal.GetPetLoadOutInfo(1);
		if (not locked and GetCVarBool("showTamers")) then --don't show pet levels for people who haven't unlocked battle petting
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

	OmegaMapUnitPositionFrame:UpdatePlayerPins();

	local activeFrame = OmegaMapPOIFrame

	-- Position flags
	do
		--local flagSize = OmegaMapFrame_InWindowedMode() and BATTLEFIELD_ICON_SIZE_WINDOW or BATTLEFIELD_ICON_SIZE_FULL;
		local flagSize = BATTLEFIELD_ICON_SIZE_FULL;

		local flagScale = 1 / OmegaMapDetailFrame:GetScale();

		OmegaMapFrame.flagsPool:ReleaseAll();
		for flagIndex = 1, GetNumBattlefieldFlagPositions() do
			local flagX, flagY, flagToken = GetBattlefieldFlagPosition(flagIndex);
			if flagX ~= 0 or flagY ~= 0 then
				local flagFrame = OmegaMapFrame.flagsPool:Acquire();

				flagX = flagX * OmegaMapDetailFrame:GetWidth();
				flagY = -flagY * OmegaMapDetailFrame:GetHeight();
				flagFrame:SetPoint("CENTER", OmegaMapDetailFrame, "TOPLEFT", flagX / flagScale, flagY / flagScale);
				flagFrame.Texture:SetTexture("Interface\\WorldStateFrame\\"..flagToken);

				flagFrame:SetSize(flagSize, flagSize);
				flagFrame:SetScale(flagScale);
				flagFrame:Show();
			end
		end
	end

	if OmegaMap_DoesCurrentMapHideMapIcons() then
		OmegaMapCorpse:Hide();
		OmegaMapDeathRelease:Hide();
	else
		-- Position corpse
		local corpseX, corpseY = OmegaMapOffsetAltMapCoords(GetCorpseMapPosition());
		if ( corpseX == 0 and corpseY == 0 ) then
			WorldMapCorpse:Hide();
		else
			corpseX = corpseX * OmegaMapDetailFrame:GetWidth();
			corpseY = -corpseY * OmegaMapDetailFrame:GetHeight();

			OmegaMapCorpse:SetPoint("CENTER", "OmegaMapDetailFrame", "TOPLEFT", corpseX, corpseY);
			OmegaMapCorpse:SetFrameStrata("DIALOG");
			OmegaMapCorpse:Show();
		end
		
			-- Position Death Release marker
		local deathReleaseX, deathReleaseY = GetDeathReleasePosition();
		if ((deathReleaseX == 0 and deathReleaseY == 0) or UnitIsGhost("player")) then
			OmegaMapDeathRelease:Hide();
		else
			deathReleaseX = deathReleaseX * OmegaMapDetailFrame:GetWidth();
			deathReleaseY = -deathReleaseY * OmegaMapDetailFrame:GetHeight();

			OmegaMapDeathRelease:SetPoint("CENTER", "OmegaMapDetailFrame", "TOPLEFT", deathReleaseX, deathReleaseY);
			OmegaMapDeathRelease:SetFrameStrata("DIALOG");
			OmegaMapDeathRelease:Show();
		end
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
	local playerBlipFrameLevel = OmegaMapUnitPositionFrame:GetFrameLevel();
	local index = 0;
	for i=1, numVehicles do
		if (i > totalVehicles) then
			local vehicleName = "OmegaMapVehicles"..i;
			OMEGAMAP_VEHICLES[i] = CreateFrame("FRAME", vehicleName, OmegaMapPOIFrame, "OmegaMapVehicleTemplate");
			OMEGAMAP_VEHICLES[i].texture = _G[vehicleName.."Texture"];
		end
		local vehicleX, vehicleY, unitName, isPossessed, vehicleType, orientation, isPlayer, isAlive = OmegaMapOffsetAltMapCoords( GetBattlefieldVehicleInfo(i));
		if ( vehicleX and isAlive and not isPlayer and VEHICLE_TEXTURES[vehicleType]) then
			local mapVehicleFrame = OMEGAMAP_VEHICLES[i];
			--vehicleX = vehicleX * activeFrame:GetWidth();
			--vehicleY = -vehicleY * activeFrame:GetHeight();
			vehicleX = vehicleX * activeFrame:GetWidth() * activeFrame:GetScale();
			vehicleY = -vehicleY * activeFrame:GetHeight() * activeFrame:GetScale();

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
	OmegaMapFrame_EvaluateAreaLabels();

	OmegaMapUnitPositionFrame:UpdateTooltips(OmegaMapTooltip);
end

function OmegaMap_UpdateBattlefieldFlagSizes(size)
	for flagFrame in OmegaMapFrame.flagsPool:EnumerateActive() do
		flagFrame:SetSize(size, size);
	end
end

function OmegaMap_UpdateBattlefieldFlagScales()
	for flagFrame in OmegaMapFrame.flagsPool:EnumerateActive() do
		flagFrame:SetScale(newScale);
	end
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

function OmegaMapUnit_OnEnter(self, motion)
	-- Adjust the tooltip based on which side the unit button is on
	SetMapTooltipPosition(OmegaMapTooltip, self);

	-- See which POI's are in the same region and include their names in the tooltip
	local unitButton;
	local newLineString = "";
	local tooltipText = "";

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

function OmegaMap_HandleUnitClick(mouseOverUnits, mouseButton)
	BAD_BOY_COUNT = 0;

	if ( GetCVarBool("enablePVPNotifyAFK") and mouseButton == "RightButton" ) then
		local _, instanceType = IsInInstance();
		if ( instanceType == "pvp" or  IsInActiveWorldPVP() ) then
			local timeNowSeconds = GetTime();
			for unit in pairs(mouseOverUnits) do
				if ( not GetIsPVPInactive(unit, timeNowSeconds) ) then
					BAD_BOY_COUNT = BAD_BOY_COUNT + 1;
					BAD_BOY_UNITS[BAD_BOY_COUNT] = unit;
				end
			end
		end

		if ( BAD_BOY_COUNT > 0 ) then
			UIDropDownMenu_Initialize( OmegaMapUnitDropDown, OmegaMapUnitDropDown_Initialize, "MENU");
			ToggleDropDownMenu(1, nil, OmegaMapUnitDropDown, "cursor", 0, -5);
			return true;
		end
	end

	return false;
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

function OmegaMapFrame_SyncMaximizeMinimizeButton(maximizeMinimizeFrame)
	--if (OmegaMapFrame_InWindowedMode()) then
		--maximizeMinimizeFrame.MinimizeButton:Hide();
		--maximizeMinimizeFrame.MaximizeButton:Show();
	--else
		maximizeMinimizeFrame.MinimizeButton:Show();
		maximizeMinimizeFrame.MaximizeButton:Hide();
	--end
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

function OmegaMap_ToggleSizeDown()
	--OmegaMapFrame.UIElementsFrame.OpenQuestPanelButton:Show();
	--OmegaMapFrame.MainHelpButton:Show();
	--OMEGAMAP_SETTINGS.size = OmegaMapConfig.scale;
	-- adjust main frame
	--OmegaMapFrame:SetParent(UIParent);
	OmegaMapFrame:SetFrameStrata("HIGH");
	OmegaMapTooltip:SetFrameStrata("TOOLTIP");
	OmegaMapCompareTooltip1:SetFrameStrata("TOOLTIP");
	OmegaMapCompareTooltip2:SetFrameStrata("TOOLTIP");
	--OmegaMapFrame:EnableKeyboard(false);
	-- adjust map frames
	--OmegaMapDetailFrame:SetScale(OmegaMapConfig.scale);
	--OmegaMapFrameAreaFrame:SetScale(OmegaMapConfig.scale);
	--OmegaMapUnitPositionFrame:SetScale(OmegaMapConfig.scale);
	--OmegaMapFrame_ResetPOIHitTranslations();
	--QUEST_POI_FRAME_WIDTH = OmegaMapDetailFrame:GetWidth() * OmegaMapConfig.scale;
	--QUEST_POI_FRAME_HEIGHT = OmegaMapDetailFrame:GetHeight() * OmegaMapConfig.scale;
	-- hide big window elements
	--BlackoutWorld:Hide();
	--OmegaMapFrameSizeDownButton:Hide();
	--ToggleMapFramerate();
	-- show small window elements
	--OmegaMapTitleButton:Show();
	--OmegaMapFrameSizeUpButton:Show();
	-- floor dropdown
	--WorldMapLevelDropDown:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPLEFT", -18, 2);

	-- tiny adjustments
	-- pet battle level size adjustment
	OmegaMapFrameAreaPetLevels:SetFontObject("SubZoneTextFont");
	-- user-movable
	--OmegaMapFrame:ClearAllPoints();
	--SetUIPanelAttribute(OmegaMapFrame, "area", "center");
	--SetUIPanelAttribute(OmegaMapFrame, "allowOtherPanels", true);
	--OmegaMapFrame:SetMovable(true);
	--OmegaMapFrame:SetSize(702, 534);
	--OmegaMapFrame.BorderFrame:SetSize(702, 534);

	--OmegaMapFrame.BorderFrame.Inset:SetPoint("TOPLEFT", 0, -63);
	--OmegaMapFrame.BorderFrame.Inset:SetPoint("BOTTOMRIGHT", -2, 1);
	--ButtonFrameTemplate_ShowPortrait(OmegaMapFrame.BorderFrame);
	--OmegaMapFrame.NavBar:SetPoint("TOPLEFT", OmegaMapFrame.BorderFrame, 64, -23);
	--OmegaMapFrame.NavBar:SetWidth(628);

	--OmegaMapFrame:SetPoint("TOPLEFT", OmegaMapScreenAnchor, 0, 0);
	--OmegaMapScrollFrame:ClearAllPoints();
	--OmegaMapScrollFrame:SetPoint("TOPLEFT", 3, -68);
	--OmegaMapScrollFrame:SetSize(696, 464);
	OmegaMapUnitPositionFrame:SetPinSize("player", PLAYER_ARROW_SIZE_WINDOW);
	OmegaMapUnitPositionFrame:SetPinSize("party", GROUP_MEMBER_SIZE_WINDOW);
	OmegaMapUnitPositionFrame:SetPinSize("raid", RAID_MEMBER_SIZE_WINDOW);
	OmegaMap_UpdateBattlefieldFlagSizes(BATTLEFIELD_ICON_SIZE_WINDOW);
	OmegaMap_UpdateBattlefieldFlagScales();
	--OmegaMapBarFrame_UpdateLayout(OmegaMapBarFrame);
end

function OmegaMapFrame_UpdateMap(skipDropDownUpdate)
	OmegaMapFrame_Update();
	if (not skipDropDownUpdate) then
		OmegaMapLevelDropDown_Update();
		OmegaMapNavBar_Update();
	end
end
function OmegaMapScenarioPOIFrame_OnUpdate(self)
	if (not OmegaMapFrame:IsVisible()) then return end

	OmegaMapScenarioPOIFrame:DrawNone();
	if( GetCVarBool("questPOI") ) then
		OmegaMapScenarioPOIFrame:DrawAll();
	end

	local canUpdateTooltip, mouseX, mouseY = OmegaMapFrame_POITooltipUpdate(self);

	if ( not canUpdateTooltip ) then
		return;
	end

	local hasScenarioTooltip = self:UpdateMouseOverTooltip(mouseX, mouseY);
	if ( hasScenarioTooltip ) then
		OmegaMapScenarioPOI_SetTooltip(self);
	else
		OmegaMapTooltip:Hide();
	end
end

function OmegaMapFrame_POITooltipUpdate(self,tooltipOwner)
	if ( not self:IsMouseOver() ) then
		return false;
	end
	if ( OmegaMapTooltip:IsShown() and OmegaMapTooltip:GetOwner() ~= (tooltipOwner or self) ) then
		return false;
	end

	if ( not self.scale ) then
		OmegaMapFrame_CalculateHitTranslations(self);
	end
	
	local cursorX, cursorY = GetCursorPosition();
	local frameX = cursorX / self.scale - self.offsetX;
	local frameY = - cursorY / self.scale + self.offsetY;	
	local adjustedX = frameX / QUEST_POI_FRAME_WIDTH;
	local adjustedY = frameY / QUEST_POI_FRAME_HEIGHT;

	return true, adjustedX, adjustedY;
end

function OmegaMapScenarioPOI_SetTooltip(self)
	OmegaMapTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 5, 2);
	local description = self:GetScenarioTooltipText();
	OmegaMapTooltip:SetText(description);
	OmegaMapTooltip:Show();
end

function OmegaMapQuestPOI_SetTooltip(poiButton, questLogIndex, numObjectives)
	local title, _, _, _, _, _, _, questID = GetQuestLogTitle(questLogIndex);
	OmegaMapTooltip:SetOwner(poiButton or OmegaMapPOIFrame, "ANCHOR_CURSOR_RIGHT", 5, 2);
	OmegaMapTooltip:SetText(title);
	QuestUtils_AddQuestTypeToTooltip(OmegaMapTooltip, questID, NORMAL_FONT_COLOR);
	if ( poiButton and poiButton.style ~= "numeric" ) then
		local completionText = GetQuestLogCompletionText(questLogIndex) or QUEST_WATCH_QUEST_READY;
		OmegaMapTooltip:AddLine("- "..completionText, 1, 1, 1, true);

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
		local completionText = GetQuestLogCompletionText(questLogIndex) or QUEST_WATCH_QUEST_READY;
		OmegaMapTooltip:AddLine("- "..completionText, 1, 1, 1, true);
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

	local canUpdateTooltip, mouseX, mouseY = OmegaMapFrame_POITooltipUpdate(self,OmegaMapPOIFrame);

	if ( not canUpdateTooltip ) then
		return;
	end

	local questLogIndex, numObjectives = self:UpdateMouseOverTooltip(mouseX, mouseY);

	if ( numObjectives ) then
		OmegaMapQuestPOI_SetTooltip(nil, questLogIndex, numObjectives);
	else
		OmegaMapTooltip:Hide();
	end
end

function OmegaMapBlobFrame__ResetPOIHitTranslations()
	OmegaMapBlobFrame.scale = nil;
	OmegaScenarioPOIFrame.scale = nil;
end

function OmegaMapFrame_CalculateHitTranslations(self)
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
	--OmegaMapBlobFrame_ResetPOIHitTranslations();
	OmegaMapBlobFrame_DelayedUpdateBlobs();
	OmegaMap_UpdateBattlefieldFlagScales();
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
	--OmegaMapBlobFrame_ResetPOIHitTranslations();
	OmegaMapBlobFrame_DelayedUpdateBlobs();

end

function OmegaMapScrollFrame_ReanchorQuestPOIs()
	for _, poiType in pairs(OmegaMapPOIFrame.poiTable) do
		for _, poiButton in pairs(poiType) do
			if ( poiButton.used ) then
				local _, posX, posY = QuestPOIGetIconInfo(poiButton.questID);
				OmegaMapPOIFrame_AnchorPOI(poiButton, posX, posY, WORLD_MAP_POI_FRAME_LEVEL_OFFSETS.TRACKED_QUEST);
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
		--OmegaMapBlobFrame_ResetPOIHitTranslations();
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

function OmegaMapPOIFrame_AnchorPOI(poiButton, posX, posY, frameLevelOffset)
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
		poiButton:SetFrameLevel(poiButton:GetParent():GetFrameLevel() + frameLevelOffset);

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
				if ( IsQuestComplete(questID) ) then
					poiButton = QuestPOI_GetButton(OmegaMapPOIFrame, questID, "map", nil);
				else
					local shownIndex = index;

					-- if a quest is being viewed there is only going to be one POI and we need to match it to the ObjectiveTracker's index for that quest.
					if ( detailQuestID ) then
						shownIndex = 1;
						for trackerIndex, poi in ipairs(ObjectiveTrackerFrame.BlocksFrame.poiTable["numeric"]) do
							if ( poi:IsShown() ) then
								if ( detailQuestID == poi.questID ) then
									shownIndex = trackerIndex;
									break;
								else
									shownIndex = shownIndex + 1;
								end
							end
						end
					end
					poiButton = QuestPOI_GetButton(OmegaMapPOIFrame, questID, "numeric", shownIndex);
				end
				OmegaMapPOIFrame_AnchorPOI(poiButton, posX, posY, WORLD_MAP_POI_FRAME_LEVEL_OFFSETS.TRACKED_QUEST);
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

function OmegaMap_HijackTooltip(owner)
	OmegaMapTooltip:SetParent(owner);
	OmegaMapTooltip:SetFrameStrata("TOOLTIP");

	for i, tooltip in ipairs(OmegaMapTooltip.ItemTooltip.Tooltip.shoppingTooltips) do
		tooltip:SetParent(owner);
		tooltip:SetFrameStrata("TOOLTIP");
	end
end

function OmegaMap_RestoreTooltip()
	for i, tooltip in ipairs(OmegaMapTooltip.ItemTooltip.Tooltip.shoppingTooltips) do
		tooltip:SetParent(OmegaMapFrame);
		tooltip:SetFrameStrata("TOOLTIP");
	end

	OmegaMapTooltip:SetParent(OmegaMapFrame);
	OmegaMapTooltip:SetFrameStrata("TOOLTIP");
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
	
	local index = 1;
	if CanShowEncounterJournal() then
		local width = OmegaMapDetailFrame:GetWidth();
		local height = OmegaMapDetailFrame:GetHeight();

		local x, y, instanceID, name, description, encounterID = EJ_GetMapEncounter(index, OmegaMapFrame.fromJournal);
		while name do
			local bossButton = _G["EJMapButton"..index];
			if not bossButton then
				bossButton = CreateFrame("Button", "EJMapButton"..index, OemegaMapBossButtonFrame, "EncounterMapButtonTemplate");
			end

			bossButton.instanceID = instanceID;
			bossButton.encounterID = encounterID;
			bossButton.tooltipTitle = name;
			bossButton.tooltipText = description;
			bossButton:SetPoint("CENTER", OemegaMapBossButtonFrame, "BOTTOMLEFT", x*width, y*height);
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
	end

	OmegaMapFrame.hasBosses = index ~= 1;
	
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

	info.isTitle = true;
	info.notCheckable = true;
	info.text = WORLD_MAP_FILTER_TITLE;
	UIDropDownMenu_AddButton(info);
	info.isTitle = nil;
	info.disabled = nil;
	info.notCheckable = nil;
	info.isNotRadio = true;
	info.keepShownOnClick = true;
	info.func = WorldMapTrackingOptionsDropDown_OnClick;

	info.text = SHOW_QUEST_OBJECTIVES_ON_MAP_TEXT;
	info.value = "quests";
	info.checked = GetCVarBool("questPOI");
	UIDropDownMenu_AddButton(info);

	local prof1, prof2, arch, fish, cook, firstAid = GetProfessions();
	if arch then
		info.text = ARCHAEOLOGY_SHOW_DIG_SITES;
		info.value = "digsites";
		info.checked = GetCVarBool("digSites");
		UIDropDownMenu_AddButton(info);
	end

	if CanTrackBattlePets() then
		info.text = SHOW_PET_BATTLES_ON_MAP_TEXT;
		info.value = "tamers";
		info.checked = GetCVarBool("showTamers");
		UIDropDownMenu_AddButton(info);
	end

	-- If we aren't on a map with world quests don't show the world quest reward filter options.
	if not OmegaMapFrame.UIElementsFrame.BountyBoard or not OmegaMapFrame.UIElementsFrame.BountyBoard:AreBountiesAvailable() then
		return;
	end

	if prof1 or prof2 then
		info.text = SHOW_PRIMARY_PROFESSION_ON_MAP_TEXT;
		info.value = "primaryProfessionsFilter";
		info.checked = GetCVarBool("primaryProfessionsFilter");
		UIDropDownMenu_AddButton(info);
	end

	if fish or cook or firstAid then
		info.text = SHOW_SECONDARY_PROFESSION_ON_MAP_TEXT;
		info.value = "secondaryProfessionsFilter";
		info.checked = GetCVarBool("secondaryProfessionsFilter");
		UIDropDownMenu_AddButton(info);
	end

	UIDropDownMenu_AddSeparator(info);
	-- Clear out the info from the separator wholesale.
	info = UIDropDownMenu_CreateInfo();

	info.isTitle = true;
	info.notCheckable = true;
	info.text = WORLD_QUEST_REWARD_FILTERS_TITLE;
	UIDropDownMenu_AddButton(info);
	info.text = nil;

	info.isTitle = nil;
	info.disabled = nil;
	info.notCheckable = nil;
	info.isNotRadio = true;
	info.keepShownOnClick = true;
	info.func = WorldMapTrackingOptionsDropDown_OnClick;

	info.text = WORLD_QUEST_REWARD_FILTERS_ORDER_RESOURCES;
	info.value = "worldQuestFilterOrderResources";
	info.checked = GetCVarBool("worldQuestFilterOrderResources");
	UIDropDownMenu_AddButton(info);

	info.text = WORLD_QUEST_REWARD_FILTERS_ARTIFACT_POWER;
	info.value = "worldQuestFilterArtifactPower";
	info.checked = GetCVarBool("worldQuestFilterArtifactPower");
	UIDropDownMenu_AddButton(info);

	info.text = WORLD_QUEST_REWARD_FILTERS_PROFESSION_MATERIALS;
	info.value = "worldQuestFilterProfessionMaterials";
	info.checked = GetCVarBool("worldQuestFilterProfessionMaterials");
	UIDropDownMenu_AddButton(info);

	info.text = WORLD_QUEST_REWARD_FILTERS_GOLD;
	info.value = "worldQuestFilterGold";
	info.checked = GetCVarBool("worldQuestFilterGold");
	UIDropDownMenu_AddButton(info);

	info.text = WORLD_QUEST_REWARD_FILTERS_EQUIPMENT;
	info.value = "worldQuestFilterEquipment";
	info.checked = GetCVarBool("worldQuestFilterEquipment");
	UIDropDownMenu_AddButton(info);
end

function OmegaMapTrackingOptionsDropDown_OnClick(self)
	local checked = self.checked;
	local value = self.value;
	
	if (checked) then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	else
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
	end
	
	if (value == "quests") then
		SetCVar("questPOI", checked and "1" or "0");
		OmegaMapQuestFrame_UpdateAll(); --CHECK
	elseif (value == "digsites") then
		SetCVar("digSites", checked and "1" or "0");
		OmegaMapFrame_Update();
	elseif (value == "tamers") then
		SetCVar("showTamers", checked and "1" or "0");
		OmegaMapFrame_Update();
	elseif (value == "primaryProfessionsFilter" or value == "secondaryProfessionsFilter") then
		SetCVar(value, checked and "1" or "0");
		OmegaMapFrame_Update();
	elseif (value == "worldQuestFilterOrderResources" or value == "worldQuestFilterArtifactPower" or
			value == "worldQuestFilterProfessionMaterials" or value == "worldQuestFilterGold" or
			value == "worldQuestFilterEquipment") then
		-- World quest reward filter cvars
		SetCVar(value, checked and "1" or "0");
		OmegaMap_UpdateQuestBonusObjectives();
	end
end

-- *****************************************************************************************************
-- ***** NAV BAR
-- *****************************************************************************************************

local SIBLING_MENU_DATA = { };
local SIBLING_MENU_PARENT_ID;
local SIBLING_MENU_PARENT_IS_CONTINENT;

local BROKEN_ISLES_ID = 8;

function IsMapAllowedInKioskMode(id)
	return true;
end

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
		local allowed = true;
		if (IsKioskModeEnabled()) then
			allowed = IsMapAllowedInKioskMode(id);
		end
		if ( name and allowed ) then
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

OmegaMapPingMixin = {};

function OmegaMapPingMixin:PlayOnFrame(frame, contextData)
	if self.targetFrame ~= frame then
		if frame and frame:IsVisible() then
			self:ClearAllPoints();
			self:SetPoint("CENTER", frame);

			self:Stop();
			self:SetTargetFrame(frame);
			self:SetContextData(contextData);
			self:Play();
		else
			self:Stop();
		end
	end
end

function OmegaMapPingMixin:SetTargetFrame(frame)
	-- Stop this ping from playing on any previous target
	if self.targetFrame then
		self.targetFrame.worldMapPing = nil;
	end

	-- This ping is now targeting a new frame (or nothing)
	self.targetFrame = frame;

	-- Clear out context data, it's meaningless with a new frame
	self:SetContextData(nil);

	-- If that frame is a valid target, then let it know that a ping is attached
	if frame then
		frame.worldMapPing = self;

		-- Layer this behind the frame that's targeted (could make this dynamic)
		-- Might need to reparent, this currently works because it's only operating
		-- on TaskPOI pins.
		self:SetFrameLevel(frame:GetFrameLevel() + 1);
	end
end

function OmegaMapPingMixin:SetContextData(contextData)
	self.contextData = contextData;
end

function OmegaMapPingMixin:GetContextData()
	return self.contextData;
end

function OmegaMapPingMixin:Play()
	self.DriverAnimation:Play();
end

function OmegaMapPingMixin:Stop()
	self.DriverAnimation:Stop();
end

OmegaMapPingAnimationMixin = {};

function OmegaMapPingAnimationMixin:OnPlay()
	local ping = self:GetParent();
	ping.ScaleAnimation:Play();
end

function OmegaMapPingAnimationMixin:OnStop()
	local ping = self:GetParent();
	ping:SetTargetFrame(nil);
	ping.ScaleAnimation:Stop();
end

function OmegaMapPing_StartPingQuest(questID)
	if OmegaMapFrame:IsVisible() then
		local ping = OmegaMapPOIFrame.POIPing;
		local target = OmegaMap_GetActiveTaskPOIForQuestID(questID);
		ping:PlayOnFrame(target, questID);
	end
end

function OmegaMapPing_StartPingPOI(poiFrame)
	if OmegaMapFrame:IsVisible() then
		OmegaMapPOIFrame.POIPing:PlayOnFrame(poiFrame);
	end
end

function OmegaMapPing_StopPing(frame)
	if frame.worldMapPing then
		frame.worldMapPing:Stop();
	end
end

function OmegaMapPing_UpdatePing(frame, contextData)
	if frame.worldMapPing and frame.worldMapPing:GetContextData() ~= contextData then
		frame.worldMapPing:Stop();
	end
end

function OmegaMapFrame_MaximizeMinimizeFrame_OnLoad(self)
	-- We don't have the mixin handle the CVar because we use specialized logic for setting it.
	self:SetOnMaximizedCallback(OmegaMapFrame_ToggleWindowSize);
	self:SetOnMinimizedCallback(OmegaFrame_ToggleWindowSize);
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
	OmegaMapPOIFrame:SetAlpha(alpha);

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