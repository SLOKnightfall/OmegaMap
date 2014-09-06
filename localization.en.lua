-- English is the default localization 
--if GetLocale() == "usEN" then

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

OMEGAMAP_LOADED_MESSAGE = OM_RED.."OmegaMap @project-version@ Loaded".."|r"
OMEGAMAP_CTMAP_LOADED_MESSAGE = OM_YELLOW.."OmegaMap-CTMap Plugin Loaded".."|r"
OMEGAMAP_GATHERER_LOADED_MESSAGE = OM_YELLOW.."OmegaMap-Gatherer Plugin Loaded".."|r"
OMEGAMAP_GATHERMATE2_LOADED_MESSAGE = OM_YELLOW.."OmegaMap-Gathermate2 Plugin Loaded".."|r"
OMEGAMAP_MAPNOTES_LOADED_MESSAGE = OM_YELLOW.."OmegaMap-MapNotes Plugin Loaded".."|r"
OMEGAMAP_MOZZ_LOADED_MESSAGE = OM_YELLOW.."OmegaMap-MozzFullWorldMap Plugin Loaded".."|r"
OMEGAMAP_NPCSCANOVERLAY_LOADED_MESSAGE = OM_YELLOW.."OmegaMap-NPCScanOverlay Plugin Loaded".."|r"
OMEGAMAP_QUESTHELPERLITE_LOADED_MESSAGE = OM_YELLOW.."OmegaMap-QuestHelper Lite Plugin Loaded".."|r"
OMEGAMAP_ROUTES_LOADED_MESSAGE = OM_YELLOW.."OmegaMap-Routes Plugin Loaded".."|r"
OMEGAMAP_TOMTOM_LOADED_MESSAGE = OM_YELLOW.."OmegaMap-TomTom Plugin Loaded".."|r"
OMEGAMAP_PETTRACKER_LOADED_MESSAGE = OM_YELLOW.."OmegaMap-PetTracker Plugin Loaded".."|r"
OMEGAMAP_HANDYNOTES_LOADED_MESSAGE = OM_YELLOW.."OmegaMap-HandyNotes Plugin Loaded".."|r"
OMEGAMAP_EXPLORER_LOADED_MESSAGE = OM_YELLOW.."OmegaMap-Explorer Plugin Loaded".."|r"

--Localization Strings
BINDING_NAME_TOGGLEOMEGAMAP = "Toggle OmegaMap"
BINDING_HEADER_OMEGAMAP = "Omega Map"

--Map Icon Tooltips
OMEGAMAP_OPTION_BUTTON_TOOLTIP = "Options"
OMEGAMAP_EJ_TOOLTIP = "Open Dungeon Journal"
OMEGAMAPPOITOGGLE_TOOLTIP = "Toggle Points of Interest"
OMEGAMAPLOCKBUTTON_TOOLTIP = "Allows Map Interaction"

--Option Menu
OMEGAMAP_OPTIONS_COORDS = "Display Coordinates"
OMEGAMAP_OPTIONS_COORDS_TOOLTIP = "Have map display coordinates"
OMEGAMAP_OPTIONS_ALPHA = "Show Alpha Slider"
OMEGAMAP_OPTIONS_ALPHA_TOOLTIP = "Show Alpha slider on map"
OMEGAMAP_OPTIONS_SCALE = "Scale"
OMEGAMAP_OPTIONS_SCALE_TOOLTIP = "Resize Scale Of Map"
OMEGAMAP_OPTIONS_SCALESLIDER = "Show Scale Slider"
OMEGAMAP_OPTIONS_SCALESLIDER_TOOLTIP = "Show Scale slider on map"
OMEGAMAP_OPTIONS_ALTMAP = "Exterior Maps"
OMEGAMAP_OPTIONS_ALTMAP_TOOLTIP = "Show Dungeon Exterior Maps"
OMEGAMAP_OPTIONS_BG = "Show Battleground Maps"
OMEGAMAP_OPTIONS_BG_TOOLTIP = "Show Alternate Battleground Maps"
OMEGAMAP_OPTIONS_INTERACTIVE = "Lock Interactive"
OMEGAMAP_OPTIONS_INTERACTIVE_TOOLTIP = "Keep Map Interactive Between Viewings"
OMEGAMAP_OPTIONS_HOTKEY_TOOLTIP = "Hotkey To Make Map Interactive"
OMEGAMAP_OPTIONS_ESCAPECLOSE = "Close on Escape key press"
OMEGAMAP_OPTIONS_ESCAPECLOSE_TOOLTIP = "Close OmegaMap window on Escape key press"
OMEGAMAP_OPTIONS_MINIMAP = "Show Minimap Icon"
OMEGAMAP_OPTIONS_MINIMAP_TOOLTIP = "Toggle the display of the Minimap Icon"
OMEGAMAP_OPTIONS_HOTSPOT = "Show Moveable HotSpot"
OMEGAMAP_OPTIONS_HOTSPOT_TOOLTIP = "Moveable HotSpot that toggles OmegaMap on mouseover"
OMEGAMAP_OPTIONS_COMPACT = "Show Compact Map Mode"
OMEGAMAP_OPTIONS_COMPACT_TOOLTIP = "Trims the viewed portions of the map to explored areas."

--Option Menu Plugins
OMEGAMAP_OPTIONS_GATHERMATE = "Display GatherMate Nodes"
OMEGAMAP_OPTIONS_GATHERMATE_TOOLTIP = "Have Map Display GatherMate2 Nodes"
OMEGAMAP_OPTIONS_GATHERMATE_DISABLED = "GatherMate Not Loaded"
OMEGAMAP_OPTIONS_GATHERER = "Display Gatherer Nodes"
OMEGAMAP_OPTIONS_GATHERER_TOOLTIP = "Have Map Display Gatherer Nodes"
OMEGAMAP_OPTIONS_GATHERER_DISABLED = "Gatherer Not Loaded"
OMEGAMAP_OPTIONS_ROUTES = "Show Routes"
OMEGAMAP_OPTIONS_ROUTES_TOOLTIP = "Have Map Display Routes"
OMEGAMAP_OPTIONS_ROUTES_DISABLED = "Routes Not Loaded"
OMEGAMAP_OPTIONS_NPCSCANOVERLAY = "Show NPCScanOverlay"
OMEGAMAP_OPTIONS_NPCSCANOVERLAY_TOOLTIP = "Have Map Display NPCScanOverlay"
OMEGAMAP_OPTIONS_NPCSCANOVERLAY_DISABLED = "NPCScanOverlay Not Loaded"
OMEGAMAP_OPTIONS_TOMTOM = "Show TomTom Points"
OMEGAMAP_OPTIONS_TOMTOM_TOOLTIP = "Have Map Display TomTom Points"
OMEGAMAP_OPTIONS_TOMTOM_DISABLED = "TomTom Not Loaded"
OMEGAMAP_OPTIONS_CTMAP = "Show CTMapMod Points"
OMEGAMAP_OPTIONS_CTMAP_TOOLTIP = "Have Map Display CTMapMod Points"
OMEGAMAP_OPTIONS_CTMAP_DISABLED = "CTMap Mod Not Loaded"
OMEGAMAP_OPTIONS_MAPNOTES = "Show MapNotes Points"
OMEGAMAP_OPTIONS_MAPNOTES_TOOLTIP = "Have Map Display MapNotes Points"
OMEGAMAP_OPTIONS_MAPNOTES_DISABLED = "MapNotes Not Loaded"
OMEGAMAP_OPTIONS_QUESTHELPERLITE = "Show QuestHelper Lite"
OMEGAMAP_OPTIONS_QUESTHELPERLITE_TOOLTIP = "Have Map Display QuestHelper Lite"
OMEGAMAP_OPTIONS_QUESTHELPERLITE_DISABLED = "QuestHelper Lite Not Loaded"
OMEGAMAP_OPTIONS_HANDYNOTES = "Show HandyNotes "
OMEGAMAP_OPTIONS_HANDYNOTES_TOOLTIP = "Have Map Display HandyNotes items"
OMEGAMAP_OPTIONS_HANDYNOTES_DISABLED = "HandyNotes Lite Not Loaded"

--Minimap Tooltip
OMEGAMAP_MINI_LEFT = OM_WHITE.."Left Click: ".."|r".."Toggle Map"
OMEGAMAP_MINI_MID = OM_WHITE.."Middle Click: ".."|r".."Toggle HotSpot"
OMEGAMAP_MINI_RIGHT = OM_WHITE.."Right Click: ".."|r".."Toggle Options"


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