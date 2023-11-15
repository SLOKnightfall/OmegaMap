-- English is the default localization 
--if GetLocale() == "usEN" then
local addonName, addon = ...

OmegaMap = LibStub("AceAddon-3.0"):NewAddon("OmegaMap", "AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0")	
local L = LibStub("AceLocale-3.0"):NewLocale("OmegaMap", "enUS", true)
--Colors
OM_RED	= "|c00FF1010";
OM_GREEN	= "|c0000FF00";
OM_BLUE	= "|c005070FF";
OM_GOLD	= "|c00FFD200";
OM_PURPLE	= "|c00FF35A3";
OM_ORANGE	= "|c00FF7945";
OM_YELLOW	= "|c00FFFF00";
OM_CYAN	= "|cff008888";
OM_WHITE =  "|cffFFFFFF";

L["OMEGAMAP_LOADED_MESSAGE"] = OM_RED.."OmegaMap @project-version@ Loaded".."|r"
L["OMEGAMAP_CTMAP_LOADED_MESSAGE"] = OM_YELLOW.."OmegaMap-CTMap Plugin Loaded".."|r"
L["OMEGAMAP_GATHERER_LOADED_MESSAGE"] = OM_YELLOW.."OmegaMap-Gatherer Plugin Loaded".."|r"
L["OMEGAMAP_GATHERMATE2_LOADED_MESSAGE"] = OM_YELLOW.."OmegaMap-Gathermate2 Plugin Loaded".."|r"
L["OMEGAMAP_MAPNOTES_LOADED_MESSAGE"] = OM_YELLOW.."OmegaMap-MapNotes Plugin Loaded".."|r"
L["OMEGAMAP_MOZZ_LOADED_MESSAGE"] = OM_YELLOW.."OmegaMap-MozzFullWorldMap Plugin Loaded".."|r"
L["OMEGAMAP_NPCSCANOVERLAY_LOADED_MESSAGE"] = OM_YELLOW.."OmegaMap-NPCScanOverlay Plugin Loaded".."|r"
L["OMEGAMAP_QUESTHELPERLITE_LOADED_MESSAGE"] = OM_YELLOW.."OmegaMap-QuestHelper Lite Plugin Loaded".."|r"
L["OMEGAMAP_ROUTES_LOADED_MESSAGE"] = OM_YELLOW.."OmegaMap-Routes Plugin Loaded".."|r"
L["OMEGAMAP_TOMTOM_LOADED_MESSAGE"] = OM_YELLOW.."OmegaMap-TomTom Plugin Loaded".."|r"
L["OMEGAMAP_PETTRACKER_LOADED_MESSAGE"] = OM_YELLOW.."OmegaMap-PetTracker Plugin Loaded".."|r"
L["OMEGAMAP_HANDYNOTES_LOADED_MESSAGE"] = OM_YELLOW.."OmegaMap-HandyNotes Plugin Loaded".."|r"
L["OMEGAMAP_EXPLORER_LOADED_MESSAGE"] = OM_YELLOW.."OmegaMap-Explorer Plugin Loaded".."|r"

--Localization Strings
BINDING_NAME_TOGGLEOMEGAMAP = "Toggle OmegaMap"
BINDING_HEADER_OMEGAMAP = "Omega Map"

--Map Icon Tooltips
L["OMEGAMAP_OPTION_BUTTON_TOOLTIP"] = "Options"
L["OMEGAMAP_EJ_TOOLTIP"] = "Open Dungeon Journal"
L["OMEGAMAPPOITOGGLE_TOOLTIP"] = "Toggle Points of Interest"
L["OMEGAMAPLOCKBUTTON_TOOLTIP"] = "Allows Map Interaction"

--Option Menu
L["OMEGAMAP_OPTIONS_NAVBAR"] = "Display Map Navbar"
L["OMEGAMAP_OPTIONS_NAVBAR_TOOLTIP"] = "Have map navbar shown on map"
L["OMEGAMAP_OPTIONS_COORDS"] = "Display Coordinates"
L["OMEGAMAP_OPTIONS_COORDS_TOOLTIP"] = "Have map display coordinates"
L["OMEGAMAP_OPTIONS_ALPHA"] = "Show Alpha Slider"
L["OMEGAMAP_OPTIONS_ALPHA_TOOLTIP"] = "Show Alpha slider on map"
L["OMEGAMAP_OPTIONS_SCALE"] = "Scale"
L["OMEGAMAP_OPTIONS_SCALE_TOOLTIP"] = "Resize Scale Of Map"
L["OMEGAMAP_OPTIONS_SCALESLIDER"] = "Show Scale Slider"
L["OMEGAMAP_OPTIONS_SCALESLIDER_TOOLTIP"] = "Show Scale slider on map"
L["OMEGAMAP_OPTIONS_ALTMAP"] = "Exterior Maps"
L["OMEGAMAP_OPTIONS_ALTMAP_TOOLTIP"] = "Show Dungeon Exterior Maps"
L["OMEGAMAP_OPTIONS_BG"] = "Show Battleground Maps"
L["OMEGAMAP_OPTIONS_BG_TOOLTIP"] = "Show Alternate Battleground Maps"
L["OMEGAMAP_OPTIONS_INTERACTIVE"] = "Lock Interactive"
L["OMEGAMAP_OPTIONS_INTERACTIVE_TOOLTIP"] = "Keep Map Interactive Between Viewings"
L["OMEGAMAP_OPTIONS_HOTKEY_TOOLTIP"] = "Hotkey To Make Map Interactive"
L["OMEGAMAP_OPTIONS_ESCAPECLOSE"] = "Close on Escape key press"
L["OMEGAMAP_OPTIONS_ESCAPECLOSE_TOOLTIP"] = "Close OmegaMap window on Escape key press"
L["OMEGAMAP_OPTIONS_MINIMAP"] = "Show Minimap Icon"
L["OMEGAMAP_OPTIONS_MINIMAP_TOOLTIP"] = "Toggle the display of the Minimap Icon"
L["OMEGAMAP_OPTIONS_HOTSPOT"] = "Show Moveable HotSpot"
L["OMEGAMAP_OPTIONS_HOTSPOT_TOOLTIP"] = "Moveable HotSpot that toggles OmegaMap on mouseover"
L["OMEGAMAP_OPTIONS_COMPACT"] = "Show Compact Map Mode"
L["OMEGAMAP_OPTIONS_COMPACT_TOOLTIP"] = "Trims the viewed portions of the map to explored areas."
L["OMEGAMAP_OPTIONS_ZOOM_RESET"] = "Disable Map Zoom Reset"
L["OMEGAMAP_OPTIONS_ZOOM_RESET_TOOLTIP"] = "Disables Map Zoom Reseting when map is shown."
L["OMEGAMAP_OPTIONS_HIDE_IN_COMBAT"] = "Hide map while in combat"
L["OMEGAMAP_OPTIONS_HIDE_IN_COMBAT_TOOLTIP"] = "Hide map while in combat."
L["OMEGAMAP_OPTIONS_SHOW_AFTER_COMBAT"] = "Show hidden map after combat"
L["OMEGAMAP_OPTIONS_SHOW_AFTER_COMBAT_TOOLTIP"] = "Show hidden map after combat."
L["OMEGAMAP_OPTIONS_FULL_HOTSPOT_ALPHA"] = "HotSpot 100% Alpha"
L["OMEGAMAP_OPTIONS_FULL_HOTSPOT_ALPHA_TOOLTIP"] = "Using the HotSpot sets the alpha to 100%."
--Option Menu Plugins
L["OMEGAMAP_OPTIONS_GATHERMATE"] = "Display GatherMate Nodes"
L["OMEGAMAP_OPTIONS_GATHERMATE_TOOLTIP"] = "Have Map Display GatherMate2 Nodes"
L["OMEGAMAP_OPTIONS_GATHERMATE_DISABLED"] = "GatherMate Not Loaded"
L["OMEGAMAP_OPTIONS_GATHERER"] = "Display Gatherer Nodes"
L["OMEGAMAP_OPTIONS_GATHERER_TOOLTIP"] = "Have Map Display Gatherer Nodes"
L["OMEGAMAP_OPTIONS_GATHERER_DISABLED"] = "Gatherer Not Loaded"
L["OMEGAMAP_OPTIONS_ROUTES"] = "Show Routes"
L["OMEGAMAP_OPTIONS_ROUTES_TOOLTIP"] = "Have Map Display Routes"
L["OMEGAMAP_OPTIONS_ROUTES_DISABLED"] = "Routes Not Loaded"
L["OMEGAMAP_OPTIONS_NPCSCANOVERLAY"] = "Show NPCScanOverlay"
L["OMEGAMAP_OPTIONS_NPCSCANOVERLAY_TOOLTIP"] = "Have Map Display NPCScanOverlay"
L["OMEGAMAP_OPTIONS_NPCSCANOVERLAY_DISABLED"] = "NPCScanOverlay Not Loaded"
L["OMEGAMAP_OPTIONS_TOMTOM"] = "Show TomTom Points"
L["OMEGAMAP_OPTIONS_TOMTOM_TOOLTIP"] = "Have Map Display TomTom Points"
L["OMEGAMAP_OPTIONS_TOMTOM_DISABLED"] = "TomTom Not Loaded"
L["OMEGAMAP_OPTIONS_CTMAP"] = "Show CTMapMod Points"
L["OMEGAMAP_OPTIONS_CTMAP_TOOLTIP"] = "Have Map Display CTMapMod Points"
L["OMEGAMAP_OPTIONS_CTMAP_DISABLED"] = "CTMap Mod Not Loaded"
L["OMEGAMAP_OPTIONS_MAPNOTES"] = "Show MapNotes Points"
L["OMEGAMAP_OPTIONS_MAPNOTES_TOOLTIP"] = "Have Map Display MapNotes Points"
L["OMEGAMAP_OPTIONS_MAPNOTES_DISABLED"] = "MapNotes Not Loaded"
L["OMEGAMAP_OPTIONS_QUESTHELPERLITE"] = "Show QuestHelper Lite"
L["OMEGAMAP_OPTIONS_QUESTHELPERLITE_TOOLTIP"] = "Have Map Display QuestHelper Lite"
L["OMEGAMAP_OPTIONS_QUESTHELPERLITE_DISABLED"] = "QuestHelper Lite Not Loaded"
L["OMEGAMAP_OPTIONS_HANDYNOTES"] = "Show HandyNotes "
L["OMEGAMAP_OPTIONS_HANDYNOTES_TOOLTIP"] = "Have Map Display HandyNotes items"
L["OMEGAMAP_OPTIONS_HANDYNOTES_DISABLED"] = "HandyNotes Lite Not Loaded"
L["OMEGAMAP_OPTIONS_PETTRACKER"] = "Show PetTracker "
L["OMEGAMAP_OPTIONS_PETTRACKER_TOOLTIP"] = "Have Map Display PetTracker items"
L["OMEGAMAP_OPTIONS_PETTRACKER_DISABLED"] = "PetTracker Lite Not Loaded"

--Minimap Tooltip
L["OMEGAMAP_MINI_LEFT"] = OM_WHITE.."Left Click: ".."|r".."Toggle Map"
L["OMEGAMAP_MINI_MID"] = OM_WHITE.."Middle Click: ".."|r".."Toggle HotSpot"
L["OMEGAMAP_MINI_RIGHT"] = OM_WHITE.."Right Click: ".."|r".."Toggle Options"


--BG & Exteriors Notes
OM_TYP_EXTERIORS		= "Exteriors";
OM_EXTERIOR			= " Exterior";
OM_INSTANCE_TITLE_LOCATION= "Location ";
OM_INSTANCE_TITLE_LEVELS	= "Levels ";
OM_INSTANCE_TITLE_PLAYERS= "Max. Players ";
OM_INSTANCE_CHESTS		= "Chest ";
OM_INSTANCE_STAIRS		= "Stairs";
OM_INSTANCE_ENTRANCES	= "Entrance ";
OM_INSTANCE_EXITS		= "Exit ";
OM_LEADSTO			= "Leads to...";
OM_INSTANCE_PREREQS		= "Prerequisites : ";
OM_INSTANCE_GENERAL		= "General Notes : ";
OM_RARE				= "(Rare)";
OM_VARIES				= "(Varies)";
OM_WANDERS			= "(Patrols)";
OM_OPTIONAL			= "(Optional)";

OM_EXIT_SYMBOL			= "X";
OM_ENTRANCE_SYMBOL		= "X";
OM_CHEST_SYMBOL		= "C";
OM_STAIRS_SYMBOL		= "S";
OM_ROUTE_SYMBOL		= "R";
OM_QUEST_SYMBOL		= "Q";
OM_DFLT_SYMBOL			= "X";
OM_ABBREVIATED			= "..";
OM_BLANK_KEY_SYMBOL		= " ";