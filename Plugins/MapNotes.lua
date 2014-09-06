--	///////////////////////////////////////////////////////////////////////////////////////////

-- Code for MapNotes  Integration 
-- Code is a modified version of MapNotes.lua from MapNotes_v6.09.50001
-- MapNotes is written by project Manager: Cortello & Telic @ http://www.curse.com/addons/wow/map-notes-fans-update

--	///////////////////////////////////////////////////////////////////////////////////////////


if IsAddOnLoaded("MapNotes") then

	if not MapNotesOmegaMapOverlay then
		local overlay = CreateFrame("Frame", "MapNotesOmegaMapOverlay", OmegaMapNoteFrame)
		overlay:SetAllPoints(true)
	end

--MapNotes_EnablePlugin(OM_WN_PLUGIN)
-- The Below style of Plugin Information demonstrates how you can display/change actual Blizzard World Map Notes
-- on your own AddOn's Frames using the Plugin functionality - It will depend on your Frame having the same proportions
-- as the World Map Button in order to display notes in the correct positions.
-- Notes made on the AddOn frame will be displayed on the World Map, and vice versa.
MAPNOTES_PLUGINS_LIST.OM =	{	name	= "WM OmegaMap",			--
					frame	= "MapNotesOmegaMapOverlay",	-- Just use a different anchor Frame
					keyVal	= "OmegaMapNotes_GetMapKey",		-- SAFEST Use MapNotes own Key Fetching routine
					lclFnc	= "OmegaMap_WM_Localiser",	-- MUST Provide own Localiser to avoid Recursion
					wmflag	= '1',
				};

-----------------------------------------------------------------------------------------------
-- Second MapNotes Registration as Plugin to use MapNotes functionality on main World Map Zones
-- Basically an attempt to Register as a Plugin that uses the same MapNotes root Key of "WM"
-----------------------------------------------------------------------------------------------


function OmegaMapNotes_GetMapKey()

  local map = GetMapInfo();

  if map then
    map = map:gsub('_terrain%d$', ''); -- Account for phased areas

  elseif GetCurrentMapContinent() == WORLDMAP_COSMIC_ID then
    map = "Cosmic";

  else
    map = "WorldMap";

  end

  local level = GetCurrentMapDungeonLevel();

  if level > 0 then
    map = "WM "..map..level;
  else
    map = "WM "..map;
  end

  return map;
end



function OmegaMap_WM_Localiser(key)
	for j, value in ipairs(AtlasMaps) do
		if (value[key]) then
			return value[key].ZoneName;
		end
	end

	return;
end

-----------------------------------------------------------------------------------------------

if ( MAPNOTES_PLUGINS_LIST ) then
	MapNotes_RegisterPlugin(MAPNOTES_PLUGINS_LIST.OM);
end
--[[
--Local variables & functions from MapNotes.lua needed to overwrite with new functions
local minimapShaped;
local visibilityUpdate = 0;
local MN_zoneData, MN_key;
local MN_playerX, MN_playerY, MN_dist = 0, 0, 0;
local MN_noteX, MN_noteY = 0, 0;
local MN_minimapScaleX, MN_minimapScaleY = 1, 1;

-- Take the gaps out of a table to make it contiguous
--Not changed, needed due to being a local function
local function CompactTable(t)

  local valid = {};

  for i = 1, table.maxn(t) do
    if (t[i]) then
      tinsert(valid, i);
    end
  end

  -- If there are no non-nil entries or the very last entry belongs where it is
  -- then the table is already in a proper state

  if (#valid == 0 or valid[#valid] == #valid) then
    return false;
  end

  -- Move everything that's out of place to where it belongs,  deleting it
  -- from its original slot

  for i, n in ipairs(valid) do
    if (n > i) then
      t[i] = t[n];
      t[n] = nil;
    end
  end

end

--Not changed, needed due to being a local function
local function SanitizeNotes(zoneData)

  CompactTable(zoneData);

  local function ValidCoord(xy)
    return xy and xy >= 0.0 and xy <= 1.0;
  end

  local i = 1;
  while (i <= #zoneData) do

    local note = zoneData[i];

    if (note.name and ValidCoord(note.xPos) and ValidCoord(note.yPos)) then
      i = i + 1;
    else
      tremove(zoneData, i);
    end

  end

end

--Not changed, needed due to being a local function
local function MN_GetMinimapShape()
  if ( MapNotes_Options.customMinimap ) then
    return MN_AUTO_MINIMAPS[ MN_MINIMAP_STYLES[MapNotes_Options.customMinimap] ];

  elseif ( GetMinimapShape ) then
    return MN_AUTO_MINIMAPS[ GetMinimapShape() ];
  end

  return nil;
end
-- end of unchanged functions --

--modified to fix mouseover tooltip error
function MN_NoteOnEnter(note)
--printf('function MN_NoteOnEnter(%s)', note:GetName());
  local key, id = note.key, note.nid;
  local Plugin = MapNotes.pluginKeys[key];
  local loc, lLoc = MapNotes_GetMapDisplayName(key, Plugin);
  local pFrame = note:GetParent();
  local tt;
  if (pFrame == WorldMapButton) then
    tt = MapNotes_WorldMapTooltip;
  elseif   (pFrame == OmegaMapButton) then --Fix so it does not thow an error in OmegaMap on Mouseover
    tt = OmegaMapTooltip;
  else --if (pFrame == Minimap) then  
   tt = GameTooltip;
  end

  local x, y = note:GetCenter();
  local x2, y2 = pFrame:GetCenter();
  local anchor;
  if x > x2 then
    anchor = "ANCHOR_LEFT";
  else
    anchor = "ANCHOR_RIGHT";
  end
  tt:SetOwner(note, anchor);

  if (id == 0) then -- Thottbot Note

    if (MapNotes_tloc_name) then
      tt:AddLine(MapNotes_tloc_name);
    else
      tt:AddLine(MAPNOTES_THOTTBOTLOC);
    end

    if (lLoc) then
      tt:AddLine(lLoc, 1, 1, 1);
    end

    local x, y = MapNotes_tloc_xPos * 100, MapNotes_tloc_yPos * 100;
    local xy = string.format(MN_COORD_FS[MN_COORD_F], x, y);
    tt:AddLine(xy, 0, 1, 0);

    MN_TestTexture:SetTexture( MN_TLOC_ICON );
    local t = MN_TestTexture:GetTexture();
    if ( not t ) then
      t = MAPNOTES_PATH.."POIIcons\\Icontloc";
    end
    tt:AddTexture( t );
    tt:Show();

  elseif ( id == -1 ) then -- Party Note

    tt:AddLine(MAPNOTES_PARTYNOTE);

    if ( lLoc ) then
      tt:AddLine(lLoc, 1, 1, 1);
    end

    local x, y = MapNotes_PartyNoteData.xPos * 100, MapNotes_PartyNoteData.yPos * 100;
    local xy = string.format(MN_COORD_FS[MN_COORD_F], x, y);
    tt:AddLine(xy, 0, 1, 0);

    MN_TestTexture:SetTexture( MN_PARTY_ICON );
    local t = MN_TestTexture:GetTexture();
    if ( not t ) then
      t = MAPNOTES_PATH.."POIIcons\\Iconparty";
    end
    tt:AddTexture( t );
    tt:Show();

  else -- Normal Map Notes

    local noteDetails = MapNotes_Data_Notes[key][id];

    local cRef = noteDetails.ncol;
    local colours = MapNotes_Options.colourT[1][cRef] or MapNotes_Colours[cRef];
    tt:AddLine(noteDetails.name, colours.r, colours.g, colours.b);

    if (noteDetails.inf1 ~= nil and noteDetails.inf1 ~= '') then
      cRef = noteDetails.in1c;
      colours = MapNotes_Options.colourT[2][cRef] or MapNotes_Colours[cRef];
      tt:AddLine(noteDetails.inf1, colours.r, colours.g, colours.b);
    end

    if (noteDetails.inf2 ~= nil and noteDetails.inf2 ~= '') then
      cRef = noteDetails.in2c;
      colours = MapNotes_Options.colourT[3][cRef] or MapNotes_Colours[cRef];
      tt:AddLine(noteDetails.inf2, colours.r, colours.g, colours.b);
    end

    if (noteDetails.creator and noteDetails.creator ~= '') then
      tt:AddDoubleLine(MAPNOTES_CREATEDBY, noteDetails.creator, 0.79, 0.69, 0.0, 0.79, 0.69, 0.0)
    end

    if (lLoc) then
      tt:AddLine(lLoc, 1, 1, 1);
    end

    local x, y = noteDetails.xPos * 100, noteDetails.yPos * 100;
    local xy = string.format(MN_COORD_FS[MN_COORD_F], x, y);
    tt:AddLine(xy, 0, 1, 0);

    local t = noteDetails.customIcon;
    MN_TestTexture:SetTexture(nil);
    if (MNIL and t) then
      MN_TestTexture:SetTexture(t);
    end

    if not (MN_TestTexture:GetTexture()) then
      t = MAPNOTES_PATH.."POIIcons\\Icon"..noteDetails.icon;
    end
    tt:AddTexture(t);

    tt:SetFrameStrata("TOOLTIP");
    tt:SetFrameLevel(note:GetFrameLevel() + 2);
    tt:Show();
  end

end

--Modified to fix constant closing of the menus
function MapNotes_OnUpdate(self, elapsed)

  visibilityUpdate = visibilityUpdate + elapsed;

  if (MapNotes_TargetInfo_Proceed and GameTooltip:IsVisible()) then
    MapNotes_TargetInfo_Proceed.func();
    return;
  end

  if (visibilityUpdate < MapNotes_WorldMap_UpdateRate) then   -- Update Rate = 0.1 as of 9-JAN-2011
    return;
  end

  -- check for Minimap shape change via SimpleMinimap in this OnUpdate function
  minimapShaped = MN_GetMinimapShape();

  if (not WorldMapFrame:IsVisible()) then
--SetMapToCurrentZone();  --Removed to Fix OmegaMap

  end
  MN_playerX, MN_playerY = GetPlayerMapPosition("player");
  local continent = GetCurrentMapContinent();

  -- NOTE : if no player position or MapZone == 0... no need to show
  if (MN_playerX <= 0 and MN_playerY <= 0) then
    MN_MiniNotePOI:Hide();
    MapNotes_HideMiniNotes(1);
    visibilityUpdate = 0;
    return;
  end

  MN_zoneData = nil;  -- reset & use as control for individual OnUpdates
  local counter = 1;
  local mapKey = MapNotes_GetMapKey();

  local miniData;
  if (MapNotes_Keys[mapKey] and MapNotes_Keys[mapKey].miniData) then
    miniData = MapNotes_Keys[mapKey].miniData;
  elseif (MAPNOTES_BASEKEYS[mapKey] and MAPNOTES_BASEKEYS[mapKey].miniData) then
    miniData = MAPNOTES_BASEKEYS[mapKey].miniData;
  end

  if (not miniData) then
--print('No miniData - hiding');
    MN_MiniNotePOI:Hide();
  else

    if (miniData) then
      MN_zoneData = miniData;
    else
      MN_zoneData = MAPNOTES_BASEKEYS.DEFAULT.miniData;
    end

    MN_minimapZoom = Minimap:GetZoom();

    MN_rotatingMinimap = (GetCVar("rotateMinimap") == '1');

    -- Fetch the x and y scale values for the continent this map belongs to. If
    -- it doesn't belong to any continent then use the data for the default continent
    -- (currently Eastern Kingdoms)

    if not (continent and 1 <= continent and continent <= #MapNotes_MiniConst) then
      continent = MAPNOTES_BASEKEYS.DEFAULT.miniData.cont;
    end

    do
      local minimap = MapNotes_MiniConst[continent][MN_minimapZoom];
      MN_minimapScaleX, MN_minimapScaleY = minimap.xScale, minimap.yScale;
    end


    if (MapNotes_Minimap_IsIndoors) then
      local factor = MapNotes_IndoorsScale[MN_minimapZoom];
      MN_minimapScaleX = MN_minimapScaleX * factor;
      MN_minimapScaleY = MN_minimapScaleY * factor;
    end

    if (MapNotes_MiniNote_Data.key == mapKey
        and MapNotes_MiniNote_Data.xPos and MapNotes_MiniNote_Data.yPos) then

      MN_noteX = (MapNotes_MiniNote_Data.xPos - MN_playerX) * MN_zoneData.scale * MN_minimapScaleX;
      MN_noteY = (MapNotes_MiniNote_Data.yPos - MN_playerY) * MN_zoneData.scale * MN_minimapScaleY;

      MN_MiniNotePOI.key = mapKey;
      MN_MiniNotePOI.nid = MapNotes_MiniNote_Data.id;
      MN_MiniNotePOI.xPos = MN_noteX;
      MN_MiniNotePOI.yPos = MN_noteY;
      MN_MiniNotePOI.ref = MapNotes_MiniNote_Data.id;
      MN_MiniNotePOI.dist = sqrt( MN_noteX*MN_noteX + MN_noteY*MN_noteY );

      if (not MN_MiniNotePOI:IsVisible()) then

        MN_MiniNotePOI.timeSinceLastUpdate = 0;

        -- MN_MiniNotePOI only shown through this routine now, and no explicit
        -- Show() anywhere else, so the expected values for POI should be
        -- managed from here so that it can be treated in exactly the same way
        -- as a normal MapNote Mininote detailed below

        POI_OnUpdate(MN_MiniNotePOI);

      end

    else
      MN_MiniNotePOI:Hide();
    end

    -- Plot normal MapNote Mininotes
    local currentZone = MapNotes_Data_Notes[mapKey];
    if (currentZone) then

      SanitizeNotes(currentZone);

      for i, currentNote in ipairs(currentZone) do

        if (currentNote.mininote) then

          local POIName = "MN_MiniNotePOI"..counter;
          local POI = _G[POIName];

          if (not POI) then
            POI = CreateFrame("Button", POIName, Minimap, "MN_MiniNotePOITemplate");
          end

          if (POI) then

            MN_noteX = (currentNote.xPos - MN_playerX) * MN_zoneData.scale * MN_minimapScaleX;
            MN_noteY = (currentNote.yPos - MN_playerY) * MN_zoneData.scale * MN_minimapScaleY;

            POI.ref = i;
            POI.key = mapKey;
            POI.nid = i;
            POI.xPos = MN_noteX;
            POI.yPos = MN_noteY;
            POI.dist = sqrt(MN_noteX * MN_noteX + MN_noteY * MN_noteY);

            POI.timeSinceLastUpdate = 0;

            -- Add icon texture - standard 0..9 or custome
            local POITexture = _G[POIName.."Texture"];
            POITexture:SetTexture(nil);

            if (MNIL and currentNote.customIcon) then
              POITexture:SetTexture(currentNote.customIcon);
            end

            if (not POITexture:GetTexture()) then
              POITexture:SetTexture(MAPNOTES_PATH.."POIIcons\\Icon"..currentNote.icon);
            end

            POI_OnUpdate(POI);

            counter = counter + 1;
          end
        end
      end
    end
  end

  MapNotes_HideMiniNotes(counter);    -- hide remaining Mininotes
  visibilityUpdate = 0;
end

--Overwrites the old OnUpdate with the new.
local frame = MN_TestTexture:GetParent()
frame:SetScript("OnUpdate", MapNotes_OnUpdate);

--Overwrites old OnEnter to fix tooltip error found in Mapnotes
local partynote = _G["WM OmegaMapPartyNote"]
partynote:SetScript("OnEnter", MN_NoteOnEnter);

--Overwriting the OnClick to be ignored if OmegaMap is not accepting clicks and to fix error in MapNotes Code
MapNotesOmegaMapOverlay_MNOverlay:SetScript("OnClick",
	function(self, button, down)
		--if OmegaMapConfig.solidify then
			--MapNotes_PlugInsOnClick(MapNotesOmegaMapOverlay_MNOverlay, button, down);
		--else
			--return
		--end
	end
);

--Overwrites the OnClick for the OmegaMapButton
local origScript = OmegaMapButton_OnClick
OmegaMapButton_OnClick = function(self, ...)
    local mouseButton, button = ...
    if MapNotesOmegaMapOverlay_MNOverlay:IsShown() then
   	MapNotes_PlugInsOnClick(MapNotesOmegaMapOverlay_MNOverlay, mouseButton, down);

    else
        return origScript and origScript(self, ...) or true
    end
end

if OmegaMapButton:GetScript("OnMouseUp") == origScript then
   OmegaMapButton:SetScript("OnMouseUp", OmegaMapButton_OnClick)
end

--]]



print(OMEGAMAP_MAPNOTES_LOADED_MESSAGE)
end