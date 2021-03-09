local OmegaMap = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("OmegaMap")
local Config = OmegaMap.Config

OmegaMap = LibStub("AceAddon-3.0"):NewAddon("OmegaMap", "AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0")
OmegaMap.Plugins = {}

NUM_OMEGAMAP_POI_COLUMNS = 14;
OMEGAMAP_POI_TEXTURE_WIDTH = 256;


NUM_OMEGAMAP_POIS = 0;
NUM_OMEGAMAP_WORLDEFFECT_POIS = 0;
NUM_OMEGAMAP_SCENARIO_POIS = 0;
NUM_OMEGAMAP_TASK_POIS = 0;
NUM_OMEGAMAP_GRAVEYARDS = 0;
NUM_OMEGAMAP_OVERLAYS = 0;
NUM_OMEGAMAP_FLAGS = 4;


OmegaMapMiniMap = LibStub("LibDBIcon-1.0")
local HotSpotState = false


--Registers OmegaMap for LDB addons
local OmegaMapLDB = LibStub("LibDataBroker-1.1"):NewDataObject("OmegaMapMini", {
	type = "data source",
	text = "OmegaMap",
	icon = "Interface\\Icons\\INV_Misc_Map04",
	OnClick = function(self, button, down) 
		if (button == "RightButton") then
			LibStub("AceConfigDialog-3.0"):Open("OmegaMap")
		elseif (button == "LeftButton") then
			ToggleOmegaMap()
		elseif (button == "MiddleButton") then
			Config.showHotSpot = not Config.showHotSpot
			OmegaMap:HotSpotToggle(Config.showHotSpot)
		end
	end,})



--Minimap/LDB Tooltip Creation
function OmegaMapLDB:OnTooltipShow()
	self:AddLine(L["OMEGAMAP_MINI_LEFT"])
	self:AddLine(L["OMEGAMAP_MINI_MID"])
	self:AddLine(L["OMEGAMAP_MINI_RIGHT"])
end


function OmegaMapLDB:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()
	OmegaMapLDB.OnTooltipShow(GameTooltip)
	GameTooltip:Show()
end

function OmegaMapLDB:OnLeave()
	GameTooltip:Hide()
end

function OmegaMapLDB:Toggle(value)
		if value then
			OmegaMapMiniMap:Show("OmegaMapMini")
			Config.MMDB.hide = false;
			Config.showMiniMapIcon = true;
		else
			OmegaMapMiniMap:Hide("OmegaMapMini")
			Config.MMDB.hide = true;
			Config.showMiniMapIcon = false;
		end
end


local OMEGAMAP_DEFAULT_SCALE = 1.0;


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



local function TogglePlugin(plugin, value, refresh)
	local DataHandler = OmegaMap.Plugins[plugin]

	if plugin == "showPetTracker" then
		OmegaMap.Plugins["showPetTracker"] = value
		OmegaMap:PetTrackerUpdate()
	else
		if value then
			OmegaMapFrame:AddDataProvider(DataHandler)
		else
			if OmegaMapFrame.dataProviders[DataHandler] then 
				OmegaMapFrame:RemoveDataProvider(DataHandler)
			end
		end
	end

	if refresh then 
		OmegaMapFrame:RefreshAll()
	end

end


function HidePOI(value, refresh)
	for plugin, _ in pairs(OmegaMap.Plugins) do
		TogglePlugin(plugin, not value and OmegaMap.Config[plugin], false)
	end
	if value then

	end
end


function setplayerscale()
	--print(Config.player_scale)
	--OM_groupMembersDataProvider.unitPinSizes = {
		--player = 27 * Config.player_scale,
		--party = 11 * Config.player_scale,
		--raid = 11 * 0.75 * Config.player_scale;
--};
	if OmegaMapFrame:IsVisible() then 
		OmegaMapFrame:RefreshAll(true)
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
				showNavBar = {
					order = 1,
					name = L["OMEGAMAP_OPTIONS_NAVBAR"] ,
					desc = L["OMEGAMAP_OPTIONS_NAVBAR_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showNavBar = val; ToggleFrame(OmegaMapFrame.NavBar, val) end,
					get = function(info) return Config.showNavBar end,
					width = 1.5,
				},
				showCoords = {
					order = 1,
					name = L["OMEGAMAP_OPTIONS_COORDS"] ,
					desc = L["OMEGAMAP_OPTIONS_COORDS_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showCoords = val; ToggleFrame(OmegaMapCoordinates, val) end,
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
					set = function(info,val) Config.escapeClose = val; OmegaMapSetEscPress(); end,
					get = function(info) return Config.escapeClose end,
					width = 1.5,
				},
				disableZoomReset = {
					order = 5.1,
					name = L["OMEGAMAP_OPTIONS_ZOOM_RESET"] ,
					desc = L["OMEGAMAP_OPTIONS_ZOOM_RESET_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.disableZoomReset = val; end,
					get = function(info) return Config.disableZoomReset end,
					width = 1.5,
				},
				showMiniMapIcon = {
					order = 6,
					name = L["OMEGAMAP_OPTIONS_MINIMAP"] ,
					desc = L["OMEGAMAP_OPTIONS_MINIMAP_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showMiniMapIcon = val; OmegaMapLDB:Toggle(val); end,
					get = function(info) return Config.showMiniMapIcon end,
					width = 1.5,
				},
				break1 = {
					order = 6.1,
					name = "" ,
					type = "description",
					width = 1.5,

				},
				showHotSpot = {
					order = 7,
					name = L["OMEGAMAP_OPTIONS_HOTSPOT"] ,
					desc = L["OMEGAMAP_OPTIONS_HOTSPOT_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showHotSpot = val; OmegaMap:HotSpotToggle(val) end,
					get = function(info) return Config.showHotSpot end,
					width = 1.5,
				},
				fullHotSpotAlpha = {
					order = 7.5,
					name = L["OMEGAMAP_OPTIONS_FULL_HOTSPOT_ALPHA"] ,
					desc = L["OMEGAMAP_OPTIONS_FULL_HOTSPOT_ALPHA_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.fullHotSpotAlpha = val; end,
					get = function(info) return Config.fullHotSpotAlpha end,
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
					hidden = true
				},

				hideInCombat = {
					order = 8.5,
					name = L["OMEGAMAP_OPTIONS_HIDE_IN_COMBAT"] ,
					desc = L["OMEGAMAP_OPTIONS_HIDE_IN_COMBAT_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.hideInCombat = val end,
					get = function(info) return Config.hideInCombat end,
					width = 1.5,
				},
				ShowAfterCombat = {
					order = 8.6,
					name = L["OMEGAMAP_OPTIONS_SHOW_AFTER_COMBAT"] ,
					desc = L["OMEGAMAP_OPTIONS_SHOW_AFTER_COMBAT_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showAfterCombat = val end,
					get = function(info) return Config.showAfterCombat end,
					width = 1.5,
					disabled = function() return not Config.hideInCombat end
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
					set = function(info,val) Config.scale = val/100; OmegaMap_SetScale(OmegaMapFrame); OmegaMapZoomSliderFrame:SetValue(Config.scale); end,
					get = function(info) return Config.scale*100 end,
					width = "double",
					min = 20,
					max = 125,
					step = 1,
				},
				player_scale = {
					order = 12,
					name = L["OMEGAMAP_OPTIONS_SCALE"],
					desc = L["OMEGAMAP_OPTIONS_SCALE_TOOLTIP"],
					type = "select",
					type = "range",
					set = function(info,val) Config.player_scale = val/100; setplayerscale();  end,
					get = function(info) return Config.player_scale*100 end,
					width = "double",
					min = 100,
					max = 200,
					step = 1,
					hidden = true, 
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
					set = function(info,val) Config.showGatherMate = val; TogglePlugin("showGatherMate", val, true) end,
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
					set = function(info,val) Config.showRoutes = val; TogglePlugin("showRoutes", val, true) end,
					get = function(info) return Config.showRoutes end,
					width = 1.5,
					disabled = CheckPlugin("Routes")
				},
				tomtom = {
					order = 17,
					name = L["OMEGAMAP_OPTIONS_TOMTOM"] ,
					desc = L["OMEGAMAP_OPTIONS_TOMTOM_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showTomTom = val; TogglePlugin("showTomTom", val, true) end,
					get = function(info) return Config.showTomTom end,
					width = 1.5,
					disabled = CheckPlugin("TomTom")
				},
				ctmap = {
					order = 18,
					name = L["OMEGAMAP_OPTIONS_CTMAP"] ,
					desc = L["OMEGAMAP_OPTIONS_CTMAP_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showCTMap = val; TogglePlugin("showCTMap", val, true) end,

					set = function(info,val) Config.showCTMap = val end,
					get = function(info) return Config.showCTMap end,
					width = 1.5,
					disabled = CheckPlugin("CT_MapMod")
				},
				handynotes = {
					order = 21,
					name = L["OMEGAMAP_OPTIONS_HANDYNOTES"] ,
					desc = L["OMEGAMAP_OPTIONS_HANDYNOTES_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showHandyNotes = val; TogglePlugin("showHandyNotes", val, true) end,
					get = function(info) return Config.showHandyNotes end,
					width = 1.5,
					disabled = CheckPlugin("HandyNotes")
				},
				pettracker = {
					order = 22,
					name = L["OMEGAMAP_OPTIONS_PETTRACKER"] ,
					desc = L["OMEGAMAP_OPTIONS_PETTRACKER_TOOLTIP"],
					type = "toggle",
					set = function(info,val) Config.showPetTracker = val; TogglePlugin("showPetTracker", val, true) end,
					get = function(info) return Config.showPetTracker end,
					width = 1.5,
					disabled = CheckPlugin("PetTracker")
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
		player_scale = 1,
	--OmegaMap Option Menu Settings
		showExteriors = true,	--Show dungeon exteriros when available
		showBattlegrounds = true,	--Show alt battleground maps when available
		showAltMapNotes = true,		--Show notes on Exteriors & alt battlegrounds
		interactiveHotKey = "None",	--Hotkey for making the map interactive
		keepInteractive = false, -- Keeps map interactive between viewings
		escapeClose = true, --Closes OmegaMap on Escape key press,
		disableZoomReset = false,
		showMiniMapIcon = true,
		showHotSpot = false,
		fullHotSpotAlpha = false,
		showCompactMode = false,
		hideInCombat = false,
		showAfterCombat = false,
	--Plugin Settings
		showGatherer = false,	--Show gathering POI
		showTomTom = false,		--Show Tomtom poi
		showRoutes = false,		--Show Routes
		showCTMap = false,		--Show CT Map
		showMapNotes = false,	--Show MapNotes
		showGatherMate = false,	--Show Gathermate POI
		showPetTracker = false,
		showNPCScanOverlay = false,  --Show NPCScan.Overlay
		showQuestHelperLite = false,
		showHandyNotes = false,
		hotSpotLock = false,
		showNavBar = true, 
	--MiniMap button Settings
		MMDB = { hide = false,
				--minimap = {},
			},
		}
};

OmegaMap_Config = defaults.profile

function OmegaMap_SetScale(self)
	local scale = OmegaMap.Config.scale
	local parentWidth, parentHeight = self:GetParent():GetSize();
	local SCREEN_BORDER_PIXELS = 30;
	parentWidth = (parentWidth - SCREEN_BORDER_PIXELS);

	local spacerFrameHeight = self.TitleCanvasSpacerFrame:GetHeight();
	local unclampedWidth = (((parentHeight - spacerFrameHeight) * self.minimizedWidth) / (self.minimizedHeight - spacerFrameHeight));
	local clampedWidth = (math.min(parentWidth, unclampedWidth));

	local unclampedHeight = parentHeight;
	local clampHeight = (((parentHeight - spacerFrameHeight) * (clampedWidth / unclampedWidth)) + spacerFrameHeight);
	self:SetSize(math.floor(clampedWidth*scale), math.floor(clampHeight)*scale);

	self.NavBar:SetPoint("TOPLEFT", self.TitleCanvasSpacerFrame, "TOPLEFT", 0, -25);

	self.isMaximized = true;

	--self:SetSize(self.minimizedWidth, self.minimizedHeight);
	--self:SetSize(parentWidth*scale, parentHeight*scale);
	--UpdateUIPanelPositions(self);

	--ButtonFrameTemplate_ShowPortrait(self.BorderFrame);
	--self.BorderFrame.Tutorial:Show();
	--self.NavBar:SetPoint("TOPLEFT", self.TitleCanvasSpacerFrame, "TOPLEFT", 64, -25);

	--self:SynchronizeDisplayState();

	--self.BorderFrame.MaximizeMinimizeFrame.MinimizeButton:Hide();
	--self.BorderFrame.MaximizeMinimizeFrame.MaximizeButton:Show();

	self:OnFrameSizeChanged();
	OmegaMapSliderFrame:SetPoint("CENTER",OmegaMapFrame.ScrollContainer, "BOTTOMLEFT", 25, 450 *scale)
	--frame:SetScale(OmegaMap.Config.scale);
	--frame:UpdateMaximizedSize();
	--frame:SynchronizeDisplayState();

	--self.BorderFrame.MaximizeMinimizeFrame.MinimizeButton:Show();
	--self.BorderFrame.MaximizeMinimizeFrame.MaximizeButton:Hide();

	--frame:OnFrameSizeChanged();

end


local function setOptionSettings()
	OmegaMapSliderFrame:SetValue(OmegaMap.Config.opacity);
	--OmegaMapQuestShowObjectives_Toggle();
	OmegaMap_SetScale(OmegaMapFrame)
	--OmegaMapFrame:SetScale(OmegaMap.Config.scale);
	--OmegaMapFrame.ScrollContainer.Child:SetScale( OmegaMap.Config.scale ); 
	OmegaMapSetEscPress()
	--OmegaMapMiniMap_Register()
	
	ToggleFrame(OmegaMapSliderFrame, OmegaMap.Config.showAlpha)
	ToggleFrame(OmegaMapZoomSliderFrame, OmegaMap.Config.showScale)
	ToggleFrame(OmegaMapCoordinates, OmegaMap.Config.showCoords)
	ToggleFrame(OmegaMapFrame.NavBar, OmegaMap.Config.showNavBar)
	--ToggleFrame(OmegaMapCoordinates, OmegaMapConfig.showCoords)
	--ToggleFrame(OmegaMapNoteFrame, OmegaMapConfig.clearMap)
	OmegaMap:HotSpotToggle(Config.showHotSpot)
	setplayerscale()
end


---Updates Profile after changes
function OmegaMap:RefreshConfig()
	OmegaMap.Config  = self.db.profile
	OmegaMap_Config = self.db.profile
	Config = self.db.profile
	setOptionSettings()
end



local CombatToggleTriggered = false

local function CombatToggle(trigger)
	if trigger and  Config.hideInCombat then
		OmegaMapFrame:Hide();
		CombatToggleTriggered = true
	end

	if not trigger and Config.hideInCombat and Config.showAfterCombat and CombatToggleTriggered then
		OmegaMapFrame:Show();
		CombatToggleTriggered = false
	end
end

function OmegaMap:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("OmegaMapConfigProfile", defaults, true)
	options.args.profiles  = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibStub("AceConfigRegistry-3.0"):ValidateOptionsTable(options, "OmegaMap")
	LibStub("AceConfig-3.0"):RegisterOptionsTable("OmegaMap", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("OmegaMap", "OmegaMap")
	self.db.RegisterCallback(OmegaMap, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(OmegaMap, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(OmegaMap, "OnProfileReset", "RefreshConfig")


	OmegaMapFrame.ScrollContainer:EnableMouse(false)
	OmegaMapFrame:RegisterForDrag("LeftButton")
	OmegaMapFrame:SetMovable(true)
	OmegaMap.Config  = self.db.profile
	OmegaMap_Config = self.db.profile
	Config = self.db.profile

	OmegaMap:RegisterEvent("MODIFIER_STATE_CHANGED", OmegaMapSolidifyCheck)
	OmegaMap:RegisterEvent("PLAYER_REGEN_DISABLED", function() CombatToggle(true)  end)
	OmegaMap:RegisterEvent("PLAYER_REGEN_ENABLED", function() CombatToggle(false) end)

	OmegaMapMiniMap:Register("OmegaMapMini", OmegaMapLDB, Config.MMDB)

	--OmegaMapFrame:AddDataProvider(OmegaMap.Plugins["GatherMate2"])
	OmegaMap:HotSpotInit()



	setOptionSettings()
end


function OmegaMapSetEscPress()
	--Register to close on ESC
	if(OmegaMap.Config.escapeClose) then

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
		OmegaMapFrame:EnableMouse(false);
		OmegaMapFrame.ScrollContainer:EnableMouse(false)
		OmegaMapFrame.ScrollContainer:EnableMouseWheel(false);
		--OmegaMapMovementFrameTop:Hide();
		--OmegaMapMovementFrameTop:EnableMouse(false)
		--OmegaMapMovementFrameBottom:Hide();
		--OmegaMapMovementFrameBottom:EnableMouse(false)
	elseif (state == "On") then
		OmegaMapFrame:EnableMouse(true);
		OmegaMapFrame.ScrollContainer:EnableMouse(true)
		OmegaMapFrame.ScrollContainer:EnableMouseWheel(true);
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
			local mapID = C_Map.GetBestMapForUnit("player")
			local playerPosition = C_Map.GetPlayerMapPosition(mapID, "player")
			if pX == playerPosition then return end
			local pX, pY = playerPosition:GetXY()

			local fmtng = "%d, %d";

			local pLoc = "Player: "..(format( fmtng, pX * 100.0, pY * 100.0)).."\n";

			if ( OmegaMapFrame:IsVisible() ) then
				cX, cY = OmegaMapGetCLoc(OmegaMapFrame);
			else
				cX, cY = OmegaMapGetCLoc(OmegaMapFrame);
			end

			if ( ( cX ) and ( cY ) ) then
				cLoc = "Cursor: "..( format( fmtng, cX, cY ) );
			else
				cLoc = "Cursor: "..( format( fmtng, "--", "--" ) );
			end

			OmegaMapLocationText:SetText( pLoc .. (cLoc or "") );
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
		activeFrame = OmegaMapFrame
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
	if (not OmegaMapFrame:IsVisible()) then return end

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


--Function to save map position and scale when entering & exiting BGs
function OmegaMap_SetPosition()

	local inBG = UnitInBattleground("player")
	local currentMapInfo = {}
	currentMapInfo.point, currentMapInfo.relativeTo, currentMapInfo.relativePoint, currentMapInfo.xOffset, currentMapInfo.yOffset = OmegaMapFrame:GetPoint(1)

		if inBG == OmegaMapPosition.LastType  then --If map type has not changed skip

		return
	end

	if inBG then
		OmegaMapPosition.Map = currentMapInfo --Saves World info
		OmegaMapPosition.Map.scale = OmegaMapConfig.scale
		currentMapInfo = OmegaMapPosition.BG  --loads BG info
		OmegaMapConfig.scale = OmegaMapPosition.BG.scale	--loads world info
	else
		OmegaMapPosition.BG = currentMapInfo	--Saves BG info
		OmegaMapPosition.BG.scale = OmegaMapConfig.scale
		currentMapInfo = OmegaMapPosition.Map	--loads world info
		OmegaMapConfig.scale = OmegaMapPosition.Map.scale	--loads world info
	end

	OmegaMap_SetScale(OmegaMap_Config.scale);
	OmegaMapFrame:ClearAllPoints();
	OmegaMapFrame:SetPoint(currentMapInfo.point, UIParent, currentMapInfo.relativePoint, currentMapInfo.xOffset, currentMapInfo.yOffset)
	OmegaMapPosition.LastType  = inBG  --Stores info incase of relogging during a BG
end