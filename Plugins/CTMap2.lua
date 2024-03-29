--	///////////////////////////////////////////////////////////////////////////////////////////

-- Code to display CTMapMod POI within OmegaMap
-- This is modified code taken from CT_ MapMod.lua from CT_MapMod (v5.3)
-- CTMapMod is written and maintained by the CT_Mod crew @ http://www.ctmod.net/

--	///////////////////////////////////////////////////////////////////////////////////////////

if IsAddOnLoaded("CT_MapMod") then

--Creating a Frame to display Routes in Omega Map
if not CTMapOmegaMapOverlay then
	local overlay = CreateFrame("Frame", "CTMapOmegaMapOverlay", OmegaMapNoteFrame)
	overlay:SetAllPoints(true)
	overlay:SetScript("OnHide", function()
	--Sets the window back to the World Map
		CT_MapMod_NoteWindow:SetParent(WorldMapFrame);
		CT_MapMod_NoteWindow:SetPoint("CENTER", "WorldMapDetailFrame");
		CT_MapMod_NoteWindow:SetFrameStrata("DIALOG")
		WorldMapTooltip:SetParent(WorldMapFrame)
		WorldMapTooltip:SetFrameStrata("DIALOG")
	end)
end

local CT_UserMap_NoteButtons = 0;

-- Initialization

local module = { };
local _G = getfenv(0);

local MODULE_NAME = "CT_MapMod";
local MODULE_VERSION = strmatch(GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME..1;
module.version = MODULE_VERSION;

_G[MODULE_NAME..1] = module;
CT_Library:registerModule(module);

--------------------------------------------

local CT_UserMap_NoteButtons = 0;

local unlockCoord;

---------------------------------------------
-- Miscellaneous

CT_MapMod_Print = ( CT_Print or function(msg, r, g, b) DEFAULT_CHAT_FRAME:AddMessage(msg, r, g,b) end );

local function round(num, dec)
	local mult = 10 ^ (dec or 0);
	return math.floor(num * mult + 0.5) / mult;
end

local function CT_MapMod_GetCharKey()
	-- Get the current character's name key (combination of player name and server name).
	local characterKey = UnitName("player") .. "@" .. GetCVar("realmName");

	-- autoGather == (1 or nil) -- No longer used in 4.0100
	-- autoHerbs ==  (true or false) -- Added in 4.0100
	-- autoMinerals  (true or false) -- Added in 4.0100
	-- hideGroups == (table)
	-- receiveNotes == Player can receive notes
	-- mainPos1 == Position of the notes button on the full size map.
	-- mainPos2 == Position of the notes button on the small size map.
	-- countPos1 == Position of the note count text relative to notes button on full size map (1==Left, 2==Top, 3==Right, 4==Bottom).
	-- countPos2 == Position of the note count text relative to notes button on small size map (1==Left, 2==Top, 3==Right, 4==Bottom).
	-- coordPos1 == Position of the coordinates frame on the full size map.
	-- coordPos2 == Position of the coordinates frame on the small size map.
	-- coordHide1 == Hide the coordinates frame on the full size map.
	-- coordHide2 == Hide the coordinates frame on the small size map.
	-- hideMainTooltip == Hide the Notes button tooltip.

	if ( not CT_MapMod_Options[characterKey] ) then
		CT_MapMod_Options[characterKey] = { 
			autoHerbs = true,
			autoMinerals = true,
			hideGroups = {},
			-- receiveNotes = nil,
			-- mainPos1 = nil,
			-- mainPos2 = nil,
			-- countPos1 = nil,
			-- countPos2 = nil,
			-- coordPos1 = nil,
			-- coordPos2 = nil,
			-- coordHide1 = nil,
			-- coordHide2 = nil,
			-- hideMainTooltip = nil,
		};
	end

	return UnitName("player") .. "@" .. GetCVar("realmName");
end

local function CT_MapMod_GetMapName()
local continent = GetCurrentMapContinent()
local zones = {GetMapZones(continent)}
local zoneName = zones[GetCurrentMapZone()]
return zoneName
end

local function CT_MapMod_IsDialogShown()
	-- Is a dialog window currently being shown?
	if (CT_MapMod_NoteWindow:IsShown() or CT_MapMod_FilterWindow:IsShown()) then
		return true;
	end
	return false;
end

local function CT_MapMod_GetMapSizeNumber(value)
	local mapSize;
	if (value == "max") then
		return 2;
	end
	if ( WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE ) then
		-- Small size world map
		mapSize = 2;
	else
		-- Full size world map
		mapSize = 1;
	end
	return mapSize;
end

local function CT_MapMod_anchorFrame(ancFrame)
	-- Set the BOTTOMLEFT anchor point of a frame relative to
	-- the BOTTOMLEFT of the appropriate world map frame.
	local relFrame;
	if ( WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE ) then
		-- Small size world map
		relFrame = WorldMapDetailFrame;
	else
		-- Full screen size world map
		relFrame = WorldMapPositioningGuide;
	end

	local ancFrameScale, ancFrameBottom, ancFrameLeft;
	ancFrameScale = (ancFrame:GetEffectiveScale() or 1);
	ancFrameBottom = (ancFrame:GetBottom() or 0) * ancFrameScale;
	ancFrameLeft = (ancFrame:GetLeft() or 0) * ancFrameScale;

	local relScale, relBottom, relLeft;
	relScale = (relFrame:GetEffectiveScale() or 1);
	relBottom = (relFrame:GetBottom() or 0) * relScale;
	relLeft = (relFrame:GetLeft() or 0) * relScale;

	local xOffset, yOffset;
	yOffset = (ancFrameBottom - relBottom) / ancFrameScale;
	xOffset = (ancFrameLeft - relLeft) / ancFrameScale;

	ancFrame:ClearAllPoints();
	ancFrame:SetPoint("BOTTOMLEFT", relFrame, "BOTTOMLEFT", xOffset, yOffset);
end

--Modified
local function CT_MapMod_GetCursorMapPosition()
	local button = WorldMapButton;
	local x, y = GetCursorPosition();
	x = x / button:GetEffectiveScale();
	y = y / button:GetEffectiveScale();
	local centerX, centerY = button:GetCenter();
	local width = button:GetWidth();
	local height = button:GetHeight();
	local adjustedY = (centerY + (height/2) - y) / height;
	local adjustedX = (x - (centerX - (width/2))) / width;
	if (adjustedX < 0) then
		adjustedX = 0;
	elseif (adjustedX > 1) then
		adjustedX = 1;
	end
	if (adjustedY < 0) then
		adjustedY = 0;
	elseif (adjustedY > 1) then
		adjustedY = 1;
	end

---
if (OmegaMapFrame:IsShown()) then
	local x, y = GetCursorPosition()
        local left, top = CTMapOmegaMapOverlay:GetLeft(), CTMapOmegaMapOverlay:GetTop()
        local width = CTMapOmegaMapOverlay:GetWidth()
        local height = CTMapOmegaMapOverlay:GetHeight()
        local scale = CTMapOmegaMapOverlay:GetEffectiveScale()
        local cx = (x/scale - left) / width
        local cy = (top - y/scale) / height

        --if cx < 0 Oor cx > 1 or Ocy < 0 or Ocy > 1 then
            --return nil, nil
        --end
	--end

	return cx, cy ;
end

	return adjustedX, adjustedY;
end

local function CT_MapMod_AdjustPositions()
	-- Adjust position of certain elements based on the size of the world map window.
	CT_MapMod_MainButton_RestorePosition();
	CT_MapMod_MainButton_SetCountPosition();
	CT_MapMod_Coord_RestorePosition();
	CT_MapMod_ShowHideCoord();
end

local function CT_MapMod_FindResourceIcon(oldName, prefix)
	if ( prefix == "Ore_" ) then
		local n, endPoint;
		-- Remove the trailing word and set it to "Vein" (we want it
		-- to match the names of the .tga files in the Resource folder).
		n, n, endPoint = string.find(oldName, "(.+)%sVein$");
		if ( endPoint ) then
			oldName = endPoint .. "Vein";
		else
			n, n, endPoint = string.find(oldName, "(.+)%sDeposit$");
			if ( endPoint ) then
				oldName = endPoint .. "Vein";
			else
				n, n, endPoint = string.find(oldName, "(.+)%sNode$");
				if ( endPoint ) then
					oldName = endPoint .. "Vein";
				end
			end
		end
		-- Remove any "Small " prefix
		n, n, endPoint = string.find(oldName, "^Small%s(.+)");
		if ( endPoint ) then
			oldName = endPoint;
		end
		-- Remove any "Rich " prefix
		n, n, endPoint = string.find(oldName, "^Rich%s(.+)");
		if ( endPoint ) then
			oldName = endPoint;
		end
	end
	-- Strip out everything except alphanumeric characters
	local name = "";
	for i = 1, strlen(oldName), 1 do
		local l = strsub(oldName, i, i);
		if ( string.find(l, "%w") ) then
			name = name .. l;
		end
	end
	-- Determine icon number
	local icons;
	if ( prefix == "Ore_" ) then
		icons = CT_UserMap_OreIcons;
	elseif ( prefix == "Herb_" ) then
		icons = CT_UserMap_HerbIcons;
	else
		return 1;
	end
	for k, v in pairs(icons) do
		if ( v == prefix .. name ) then
			return k;
		end
	end
	return 1;
end

---------------------------------------------
-- Notes

local function CT_MapMod_CanCreateNoteOnPlayer()
	-- Can the user create a note on the player's position?
	local canCreate = false;
	local mapName = CT_MapMod_GetMapName();
	-- If we have a name for the zone and user is not looking at a dialog window...
	if (mapName and not CT_MapMod_IsDialogShown()) then
		-- Only allow if user is looking at the map of the zone they are in.
		local x, y = GetPlayerMapPosition("player");
		if (x and y and not (x == 0 and y == 0)) then
			canCreate = true;
		end
	end
	return canCreate;
end

--Updated
local function CT_MapMod_CreateNoteButton()
	-- Create a new note button.
	local id = CT_UserMap_NoteButtons + 1;
	local note = CreateFrame("BUTTON", "CT_UserMap_Note" .. id, CT_MapMod_MapButtonFrame, "CT_MapMod_NoteTemplate");
	note:SetID(id);
--ADDING creation of Omega map note
	local note2 = CreateFrame("BUTTON", "OmegaCT_UserMap_Note" .. id, CTMapOmegaMapOverlay, "CT_MapMod_NoteTemplate");
	note2:SetID(id);
	CT_UserMap_NoteButtons = id;
end

--Updated
local function CT_MapMod_HideNotes(first, last)
	-- Hide a range of notes.
	if (not first) then
		first = 1;
	end
	if (not last) then
		last = CT_UserMap_NoteButtons;
	end
	for i = first, last, 1 do
		_G["CT_UserMap_Note" .. i]:Hide();
	end
--Adding Removal of OmegaMap Note
	for i = first, last, 1 do
		_G["OmegaCT_UserMap_Note" .. i]:Hide();
	end
	
end
-- Updated
local function CT_MapMod_UpdateMap()
	-- Update the world map.
	local notes, mapName;
	local characterKey;
	local count;

	CT_MapMod_AdjustPositions();

	mapName = CT_MapMod_GetMapName();
	if ( mapName ) then
		notes = CT_UserMap_Notes[mapName];
	end
	if ( not mapName or not notes ) then
		CT_MapMod_HideNotes(1, CT_UserMap_NoteButtons);
		CT_NumNotes:SetText("|c00FFFFFF0|r/|c00FFFFFF0|r");

		return;
	end

	characterKey = CT_MapMod_GetCharKey();

	-- Calculate what notes to show
	count = 1;
	for i, var in pairs(notes) do
		if (
			-- If not hiding this set of notes, and
			not CT_MapMod_Options[characterKey].hideGroups[(CT_MAPMOD_SETS[(var.set or 1)])] and 
			(
				-- not filtering the notes, or
				not CT_MapMod_Filter or 

				-- we are filtering the notes and the note's name matches the filter pattern, or
				string.find(strlower(var.name), strlower(CT_MapMod_Filter)) or

				-- we are filtering the notes and the note's description matches the filter pattern
				string.find(strlower(var.descript), strlower(CT_MapMod_Filter))
			)
		) then
			local note;
			local IconTexture;

			if ( count > CT_UserMap_NoteButtons ) then
				CT_MapMod_CreateNoteButton();
			end

			note = _G["CT_UserMap_Note" .. count];
			IconTexture = _G["CT_UserMap_Note" .. count .."Icon"];

			OMnote = _G["OmegaCT_UserMap_Note".. count]
			OMIconTexture = _G["OmegaCT_UserMap_Note" .. count .."Icon"]

			if ( var.set == 7 ) then
				-- Herbalism notes.
				-- If icon is 1 and the name is not what the default was, then try correcting the icon.
				--if (var.icon == 1 and var.name and string.lower(var.name) ~= "bruiseweed") then
				if (var.name) then
					var.icon = CT_MapMod_FindResourceIcon(var.name, "Herb_")
				end
				if ( CT_UserMap_HerbIcons[var.icon] ) then
					IconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Resource\\" .. CT_UserMap_HerbIcons[var.icon]);
					OMIconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Resource\\" .. CT_UserMap_HerbIcons[var.icon]);
				else
					IconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed");
					OMIconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed");
				end
			elseif ( var.set == 8 ) then
				-- Mining notes.
				-- If icon is 1 and the name is not what the default was, then try correcting the icon.
				--if (var.icon == 1 and var.name and string.lower(var.name) ~= "copper vein") then
					if (var.name) then

					var.icon = CT_MapMod_FindResourceIcon(var.name, "Ore_")
				end
				if ( CT_UserMap_OreIcons[var.icon] ) then
					IconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Resource\\" .. CT_UserMap_OreIcons[var.icon]);
					OMIconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Resource\\" .. CT_UserMap_OreIcons[var.icon]);
				else
					IconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein");
					OMIconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein");
				end
			else
				IconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Skin\\" .. CT_UserMap_Icons[var.set]);
				OMIconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Skin\\" .. CT_UserMap_Icons[var.set]);
			end
			note:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", var.x * WorldMapButton:GetWidth(), -var.y * WorldMapButton:GetHeight());			
			note:Show();

			OMnote:SetPoint("CENTER", "OmegaMapDetailFrame", "TOPLEFT", var.x * OmegaMapButton:GetWidth(), -var.y * OmegaMapButton:GetHeight());			
			OMnote:Show();
			OMnote:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL)

			if ( not var.name ) then
				var.name = "";
			end
			if ( not var.set or not CT_MAPMOD_SETS[var.set] ) then
				var.set = 1;
			end
			if ( not var.descript ) then
				var.descript = "";
			end
	
			note.name = var.name;
			note.set = CT_MAPMOD_SETS[var.set];
			note.descript = var.descript;
			note.id = i;
			note.x = var.x;
			note.y = var.y;

--Set Omega Map notes
			OMnote.name = var.name;
			OMnote.set = CT_MAPMOD_SETS[var.set];
			OMnote.descript = var.descript;
			OMnote.id = i;
			OMnote.x = var.x/100;
			OMnote.y = var.y/100;

			count = count + 1;
		end
	end

	-- The number of notes currently displayed on this map / The total number of notes on this map
	CT_NumNotes:SetText("|c00FFFFFF" .. (count - 1) .. "|r/|c00FFFFFF" .. (#notes) .. "|r");

	-- Hide all other notes on this map
	CT_MapMod_HideNotes(count, CT_UserMap_NoteButtons);
end

local function CT_MapMod_ExecuteFilter(filter)
	CT_MapMod_Filter = filter;
	CT_MapMod_UpdateMap();
end

local function CT_MapMod_FindNote(zone, x, y)
	-- Look up note in zone at specified x,y location.
	local notes = CT_UserMap_Notes[zone];
	x = tonumber(x);
	y = tonumber(y);
	if (notes) then
		for num, note in ipairs(notes) do
			if ( abs(note.x - x) <= 0.0000000005 and abs(note.y - y) <= 0.0000000005 ) then
				return num;
			end
		end
	end
	return nil;
end

local function CT_MapMod_AddNote(x, y, zone, text, descript, icon, set)
	-- Add a note to the map (or change existing one at the same x,y location).
	local group;
	if ( tonumber(set) ) then
		group = tonumber(set);
	else
		group = set;
	end

	local notes = CT_UserMap_Notes[zone];
	if ( not notes ) then
		notes = {};
		CT_UserMap_Notes[zone] = notes;
	end

	-- If there is already a note at this x,y location...
	local found = CT_MapMod_FindNote(zone, x, y);
	if (found) then
		-- Update existing note.
		local temp = notes[found];
		temp.name = text;
		temp.descript = descript;
		temp.icon = icon;
		temp.set = group;
		CT_MapMod_UpdateMap();
		return found;
	else
		-- Add new note.
		local temp = { x = x, y = y, name = text, descript = descript, icon = icon, set = group };
		tinsert(notes, temp);
		CT_MapMod_UpdateMap();
		return #notes;
	end
end

local function CT_MapMod_EditNote(id)
	local mapName = CT_MapMod_GetMapName();
	if (mapName) then
		if (not id) then
			local notes = CT_UserMap_Notes[mapName];
			if (notes) then
				id = #(notes);
			else
				id = 0;
			end
		end
		if (id > 0) then
			CT_MapMod_NoteWindow.note = id;
			CT_MapMod_NoteWindow.zone = mapName;
			CT_MapMod_NoteWindow:Show();
		end
	end
end

local function CT_MapMod_CreateNoteOnCursor()
	-- Create a new note at the cursor position.
	local mapName = CT_MapMod_GetMapName();
	if (mapName) then
		local x, y = CT_MapMod_GetCursorMapPosition();
		local id = CT_MapMod_AddNote(x, y, mapName, "New note at cursor", "", 1, 1);
		CT_MapMod_NoteWindow.note = id;
		CT_MapMod_NoteWindow.zone = mapName;
		CT_MapMod_NoteWindow:Show();
	end
end

local function CT_MapMod_CreateNoteOnPlayer()
	-- Create a new note on the player's position.
	local x, y = GetPlayerMapPosition("player");
	if (not (x == 0 and y == 0)) then
		local mapName = CT_MapMod_GetMapName();
		if (mapName) then
			local id = CT_MapMod_AddNote(x, y, mapName, "New note at player", "", 1, 1,x,y);
			CT_MapMod_NoteWindow.note = id;
			CT_MapMod_NoteWindow.zone = mapName;
			CT_MapMod_NoteWindow:Show();
		end
	end
end

function CT_MapMod_OnNoteOver(self)
	-- Mouse is over a note on the map.

	-- Have to do this in order to be able to see our note's tooltip.
	WorldMapPOIFrame.allowBlobTooltip = false;

	-- Display the note's tooltip.
	local x, y = self:GetCenter();
	local parentX, parentY = WorldMapButton:GetCenter();
	if ( x > parentX ) then
		WorldMapTooltip:SetOwner(self, "ANCHOR_LEFT");
	else
		WorldMapTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end
	WorldMapTooltip:ClearLines();
	WorldMapTooltip:AddDoubleLine(self.name, self.set, 0, 1, 0, 0.6, 0.6, 0.6);
	if ( self.descript ) then
		WorldMapTooltip:AddLine(self.descript, nil, nil, nil, 1);
	end
	WorldMapTooltip:AddLine("Right-click to edit.", 0, 0.5, 0.9, 1);
	WorldMapTooltip:Show();

end

function CT_MapMod_OnNoteLeave(self)
	-- Mouse is leaving a note.

	-- Undo what we did in CT_MapMod_OnNoteOver()
	WorldMapPOIFrame.allowBlobTooltip = true;

	-- Hide the note's tooltip.
	WorldMapTooltip:Hide();
end

function CT_MapMod_OnClick(self, btn)
	-- User clicked a note on the map
	if ( btn == "LeftButton" ) then
		return;
	end
	CT_MapMod_EditNote(self.id);
end

---------------------------------------------
-- Note window

function CT_MapMod_NoteWindow_OnLoad(self)
	self.note = -1;
	-- Set names
	CT_MapMod_NoteWindowTitle:SetText(CT_MAPMOD_TEXT_TITLE);
	CT_MapMod_NoteWindowNameText:SetText(CT_MAPMOD_TEXT_NAME);
	CT_MapMod_NoteWindowDescriptText:SetText(CT_MAPMOD_TEXT_DESC);
	CT_MapMod_NoteWindowGroupText:SetText(CT_MAPMOD_TEXT_GROUP);
	CT_MapMod_NoteWindowSendText:SetText(CT_MAPMOD_TEXT_SEND);
	CT_MapMod_NoteWindowOkayButton:SetText(CT_MAPMOD_BUTTON_OKAY);
	CT_MapMod_NoteWindowCancelButton:SetText(CT_MAPMOD_BUTTON_CANCEL);
	CT_MapMod_NoteWindowDeleteButton:SetText(CT_MAPMOD_BUTTON_DELETE);
	CT_MapMod_NoteWindowEditButton:SetText(CT_MAPMOD_BUTTON_EDITGROUPS);
	CT_MapMod_NoteWindowSendButton:SetText(CT_MAPMOD_BUTTON_SEND);
end

function CT_MapMod_NoteWindow_OnShow(self)
	-- The note window is being shown.
	CT_MapMod_MapButtonFrame:Hide();
	CT_MapMod_MainButton:Disable();

	local note = CT_UserMap_Notes[self.zone][self.note];

	CT_MapMod_NoteWindowNameEB:SetText(note.name);
	CT_MapMod_NoteWindowNameEB:HighlightText();

	CT_MapMod_NoteWindowDescriptEB:SetText(note.descript);

	CT_MapMod_NoteWindowSendButton:Disable();

	CT_MapMod_NoteWindowSendEB.lastsend = "";
	CT_MapMod_NoteWindowSendEB:SetText("");

	PlaySound("UChatScrollButton");
end

function CT_MapMod_NoteWindow_OnHide(self)
	-- The note window is being hidden.
	CT_MapMod_MapButtonFrame:Show();
	CT_MapMod_MainButton:Enable();

	PlaySound("UChatScrollButton");
end

function CT_MapMod_NoteWindow_Accept()
	-- Accept the note information.
	local name, descript, set, icon;
	local zoneKey, noteKey;
	local note;

	-- Get information from the note window
	zoneKey = CT_MapMod_NoteWindow.zone;
	noteKey = CT_MapMod_NoteWindow.note;

	note = CT_UserMap_Notes[zoneKey][noteKey];

	name = CT_MapMod_NoteWindowNameEB:GetText();
	descript = CT_MapMod_NoteWindowDescriptEB:GetText();

	icon = note.icon;

	if ( Lib_UIDropDownMenu_GetSelectedName(CT_MapMod_NoteWindowGroupDropDown) ) then
		set = note.set;
	else
		set = Lib_UIDropDownMenu_GetSelectedID( CT_MapMod_NoteWindowGroupDropDown );
	end

	-- Update the note
	note.name = name;
	note.descript = descript;
	note.set = set;
	note.icon = icon;
	
	CT_MapMod_NoteWindow:Hide();
	CT_MapMod_UpdateMap();
end

function CT_MapMod_NoteWindow_Cancel()
	-- Cancel the note editing.
	CT_MapMod_NoteWindow:Hide();
end

function CT_MapMod_NoteWindow_Delete()
	-- Delete the note
	local zoneKey = CT_MapMod_NoteWindow.zone;
	local noteKey = CT_MapMod_NoteWindow.note;

	tremove(CT_UserMap_Notes[zoneKey], noteKey);

	CT_MapMod_NoteWindow:Hide();
	CT_MapMod_UpdateMap();
end

function CT_MapMod_NoteWindow_GroupDropDown_OnClick(self)
	-- User clicked on an item in the group menu.
	Lib_UIDropDownMenu_SetSelectedID(CT_MapMod_NoteWindowGroupDropDown, self:GetID(), 1);
end

function CT_MapMod_NoteWindow_GroupDropDown_OnShow()
	-- The group menu is being displayed (not actually called until note window is being shown).
	local zoneKey = CT_MapMod_NoteWindow.zone;
	local noteKey = CT_MapMod_NoteWindow.note;
	if ( zoneKey and noteKey ) then
		local note = CT_UserMap_Notes[zoneKey][noteKey];
		local set = note.set;
		if ( tonumber(set) and tonumber(set) == set ) then
			Lib_UIDropDownMenu_SetSelectedName(CT_MapMod_NoteWindowGroupDropDown, CT_MAPMOD_SETS[set], nil);
		else
			Lib_UIDropDownMenu_SetSelectedName(CT_MapMod_NoteWindowGroupDropDown, set, nil);
		end
		Lib_UIDropDownMenu_SetText(CT_MapMod_NoteWindowGroupDropDown, CT_MAPMOD_SETS[set]);
	end
end

function CT_MapMod_NoteWindow_GroupDropDown_Initialize(self)
	-- Initialize the group menu.
	for key, val in pairs(CT_MAPMOD_SETS) do
		local info = {};
		info.text = val;
		info.value = val;
		info.owner = self;
		info.func = CT_MapMod_NoteWindow_GroupDropDown_OnClick;
		Lib_UIDropDownMenu_AddButton(info);
	end
end

function CT_MapMod_NoteWindow_GroupDropDown_OnLoad(self)
	-- The group menu is being loaded.
	Lib_UIDropDownMenu_Initialize(self, CT_MapMod_NoteWindow_GroupDropDown_Initialize);
	Lib_UIDropDownMenu_SetWidth(self, 130);
end

---------------------------------------------
-- Filter window

function CT_MapMod_FilterWindow_OnLoad(self)
	-- Set names
	CT_MapMod_FilterWindowTitleText:SetText("Notes Filter");
	CT_MapMod_FilterWindowOkayButton:SetText(CT_MAPMOD_BUTTON_OKAY);
	CT_MapMod_FilterWindowCancelButton:SetText(CT_MAPMOD_BUTTON_CANCEL);
end

function CT_MapMod_FilterWindow_OnShow(self)
	-- The filter window is being shown.
	CT_MapMod_MapButtonFrame:Hide();
	CT_MapMod_MainButton:Disable();

	local eb = CT_MapMod_FilterWindowFilterEB;
	eb:SetText(CT_MapMod_Filter or "");
	eb:HighlightText();

	PlaySound("UChatScrollButton");
end

function CT_MapMod_FilterWindow_OnHide(self)
	-- The filter window is being hidden.
	CT_MapMod_MapButtonFrame:Show();
	CT_MapMod_MainButton:Enable();

	PlaySound("UChatScrollButton");
end

function CT_MapMod_FilterWindow_Accept()
	-- Accept the filter window information.
	local eb = CT_MapMod_FilterWindowFilterEB;
	CT_MapMod_ExecuteFilter(eb:GetText() or "");
	CT_MapMod_FilterWindow:Hide();
end

function CT_MapMod_FilterWindow_Cancel()
	-- Cancel editing the filter.
	CT_MapMod_FilterWindow:Hide();
end

---------------------------------------------
-- Sending notes

local CT_LastIncMessage = {};
local CT_LastOutMessage = {};

local function CT_MapMod_EnableReceiveNotes(enable)
	local characterKey = CT_MapMod_GetCharKey();
	if (enable) then
		enable = 1;
	else
		enable = nil;
	end
	CT_LastIncMessage.msg = nil;
	CT_LastIncMessage.user = nil;
	CT_MapMod_Options[characterKey].receiveNotes = enable;
end

local function CT_MapMod_GetZone(zoneid)
	if ( not tonumber(zoneid) ) then
		return "(Error: Please report zoneid " .. zoneid .. ")";
	end

	local zone = tonumber(zoneid);
	for key, val in pairs(CT_UserMap_Zone) do
		if ( val == zone ) then
			return key;
		end
	end
	return "(Error: Please report zone " .. zoneid .. ")";
end

local function CT_MapMod_ProcessWhisper(self, event, msg, user)
	-- Process incoming whispers.
	-- Return nil to allow the game to continue processing the message (should show up in chat window).
	-- Return true to prevent the message from being processed any further (won't show up in chat window).

	if (not msg) then
		return nil;
	end

	-- Examine the message
	if (strsub(msg, 1, 7) ~= "<CTMod>") then
		return nil;
	end
	local pos1, pos2, xpos, ypos, zone, name, descript, group, icon = string.find(msg, "^<CTMod> New map note received: x=(.+) y=(.+) z=(.+) n=(.*) d=(.*) g=(.+) i=(.+)$");
	if (not zone) then
		pos1, pos2, name, xpos, ypos, zone = string.find(msg, "^<CTMod> New map note: (.*) x=(.+) y=(.+) z=(.+) v=.+$");
		if (not zone) then
			return nil;
		end
		descript = "Received from " .. user;
		icon = 1;
		group = 1;
	end

	-- If this is the same as the last incoming message we processed...
	if (msg == CT_LastIncMessage.msg and CT_LastIncMessage.user == user) then
		-- Will happen if user has multiple chat frames that trap whispers.
		-- Will happen if user is sent the same whisper twice in a row.
		return true;  -- true == don't show whisper in chat frame
	end

	-- Remember this message for next time.
	CT_LastIncMessage.msg = msg;
	CT_LastIncMessage.user = user;

	-- Notify user of a received message.
	local zonename = CT_MapMod_GetZone(zone);
	local characterKey = CT_MapMod_GetCharKey();

	if ( not CT_MapMod_Options[characterKey].receiveNotes ) then
		module:printcolor(1.0, 0.5, 0.0, "<CTMapMod> Blocked incoming map note from " .. user .. ".");
	else
		module:printcolor(1.0, 0.5, 0.0, "<CTMapMod> Map note received in zone '" .. zonename .. "' at " .. round(xpos * 100, 0) .. ", " .. round(ypos * 100, 0) .. " from " .. user .. ".");
		if (strsub(zonename, 1, 1) ~= "(") then
			-- Add the note to the map
			CT_MapMod_AddNote(xpos, ypos, zonename, name, descript, tonumber(icon), group);
		end
	end
	return true;  -- true == don't show whisper in chat frame
end

-- Add a chat message filter so we can intercept incoming whispers involving CT_MapMod notes.
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", CT_MapMod_ProcessWhisper);

local function CT_MapMod_ProcessOutgoingWhisper(self, event, msg, user)
	-- Process outgoing whispers.
	-- Return nil to allow the game to continue processing the message (should show up in chat window).
	-- Return true to prevent the message from being processed any further (won't show up in chat window).
	if (not msg) then
		return nil;
	end
	-- Examine the message
	if (strsub(msg, 1, 7) ~= "<CTMod>") then
		return nil;
	end
	local pos1, pos2, xpos, ypos, zone = string.find(msg, "^<CTMod> New map note received: x=(.+) y=(.+) z=(.+) n=.* d=.* g=.+ i=.+$");
	if (not zone) then
		return nil;
	end

	-- If this is the same as the last outgoing message we processed...
	if (msg == CT_LastOutMessage.msg and CT_LastOutMessage.user == user) then
		-- Will happen if user has multiple chat frames that trap whispers.
		return true;  -- true == don't show whisper in chat frame
	end

	-- Remember this message for next time.
	CT_LastOutMessage.msg = msg;
	CT_LastOutMessage.user = user;

	-- Notify user of sent message.
	local zonename = CT_MapMod_GetZone(zone);
	module:printcolor(1.0, 0.5, 0.0, "<CTMapMod> Sent map note in zone '" .. zonename .. "' at " .. round(xpos * 100, 0) .. ", " .. round(ypos * 100, 0) .. " to " .. user .. ".");
	return true;  -- true == don't show whisper in chat frame
end

-- Add a chat message filter so we can intercept outgoing whispers involving CT_MapMod notes.
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", CT_MapMod_ProcessOutgoingWhisper);

function CT_MapMod_SendNote()
	-- Send a note to a player.
	local name, descript, zone, player;
	local note;
	local group, x, y, icon;

	CT_LastOutMessage.msg = nil;
	CT_LastOutMessage.user = nil;

	name = CT_MapMod_NoteWindowNameEB:GetText();
	descript = CT_MapMod_NoteWindowDescriptEB:GetText();
	zone = CT_MapMod_NoteWindow.zone;
	player = CT_MapMod_NoteWindowSendEB:GetText();
	
	note = CT_UserMap_Notes[zone][CT_MapMod_NoteWindow.note];

	if ( not CT_MapMod_NoteWindow:IsVisible() or strlen(player) == 0 or not CT_UserMap_Zone[zone] ) then
		return;
	end

	if ( Lib_UIDropDownMenu_GetSelectedName(CT_MapMod_NoteWindowGroupDropDown) ) then
		group = note.set;
	else
		group = Lib_UIDropDownMenu_GetSelectedID(CT_MapMod_NoteWindowGroupDropDown);
	end

	x = note.x;
	y = note.y;
	icon = note.icon;

	SendChatMessage("<CTMod> New map note received: x="..x.." y="..y.." z="..CT_UserMap_Zone[zone].." n="..name.." d="..descript.." g="..group .. " i=" .. icon, "WHISPER", nil, player);

	CT_MapMod_NoteWindowSendEB.lastsend = player;
	CT_MapMod_NoteWindowSendEB:SetText("");
	CT_MapMod_NoteWindowSendButton:Disable();
end

---------------------------------------------
-- Gathering resources

local function CT_MapMod_EnableAutoGatherNotes(enable, key)
	-- key == "autoHerbs", "autoMinerals"
	local characterKey = CT_MapMod_GetCharKey();
	if (enable) then
		enable = true;
	else
		enable = false;
	end
	CT_MapMod_Options[characterKey][key] = enable;
end

local function CT_MapMod_GetZoneName(id, ...)
	if ( id >= 1 and select('#', ...) >= id ) then
		return select(id, ...);
	end
end

local function CT_MapMod_GetCurrentZone()
	local x, y = GetPlayerMapPosition("player");
	local currC, currZ = GetCurrentMapContinent(), GetCurrentMapZone();
	SetMapToCurrentZone();
	local name = CT_MapMod_GetZoneName(GetCurrentMapZone(), GetMapZones(GetCurrentMapContinent()));
	if ( x == 0 and y == 0 ) then
		SetMapZoom(currC, currZ);
	end
	return name;
end

local function CT_MapMod_ParseResource(event, arg1)
	local characterKey = CT_MapMod_GetCharKey();
	local options = CT_MapMod_Options[characterKey];

	if (
		not options.autoHerbs and
		not options.autoMinerals
	) then
		return;
	end

	local x, y = GetPlayerMapPosition("player");
	if ( x == 0 and y == 0 ) then
		return;
	end

	local _, name, prefix, node;
	if ( string.find(event, "^CHAT_MSG" ) ) then
		if ( options.autoHerbs and string.find(arg1, "^You perform Herb Gathering on") ) then
			_,_, name = string.find(arg1, "^You perform Herb Gathering on (.+)%.$");
			prefix = "Herb_";
			node = 7;

		elseif ( options.autoMinerals and string.find(arg1, "^You perform Mining on") ) then
			_,_, name = string.find(arg1, "^You perform Mining on (.+)%.$");
			prefix = "Ore_";
			node = 8;

		end
	elseif ( string.find(event, "UI_ERROR_MESSAGE") ) then
		name = GameTooltipTextLeft1:GetText();
		if ( name and strlen(name) > 0 ) then
			if ( options.autoHerbs and string.find(arg1, "Requires Herbalism") ) then
				prefix = "Herb_";
				node = 7;

			elseif ( options.autoMinerals and string.find(arg1, "Requires Mining") ) then
				prefix = "Ore_";
				node = 8;
			else
				name = nil;
			end
		else
			name = nil;
		end
	end

	if (name) then
		local zone = CT_MapMod_GetCurrentZone();
		if ( not zone or not CT_UserMap_Zone[zone] ) then
			return;
		end
		if ( not CT_UserMap_Notes[zone] ) then
			CT_UserMap_Notes[zone] = { };
		end
		for k, v in pairs(CT_UserMap_Notes[zone]) do
			if ( abs(v.x-x) <= 0.005 and abs(v.y-y) <= 0.005 ) then
				-- Two very close nodes, most likely the same node, we don't want to add another note then
				return;
			end
		end
		CT_MapMod_AddNote(x, y, zone, name, "", CT_MapMod_FindResourceIcon(name, prefix), node);
	end
end

---------------------------------------------
-- Group window (not functional)

function CT_MapMod_GroupWindow_Show()
	CT_MapMod_GroupWindow:Show();
end

function CT_MapMod_GroupWindow_Update()
	local numGroups = #(CT_MAPMOD_SETS);
	FauxScrollFrame_Update(CT_MapMod_GroupWindowScrollFrame, numGroups, 6, 16, CT_MapMod_GroupWindowHighlightFrame, 293, 316);

	local i;
	for i = 1, 6, 1 do
		local btn = _G["CT_MapMod_GroupWindowGroup" .. i];
		if ( i <= numGroups ) then
			btn:Show();
			btn:SetText(" " .. CT_MAPMOD_SETS[FauxScrollFrame_GetOffset(CT_MapMod_GroupWindowScrollFrame)+i]);
		else
			btn:Hide();
		end
	end
end

function CT_MapMod_GroupWindow_SetSelection(id)
	local i;
	for i = 1, 6, 1 do
		_G["CT_MapMod_GroupWindowGroup"..i]:UnlockHighlight();
	end

	-- Get xml id
	local xmlid = id - FauxScrollFrame_GetOffset( CT_MapMod_GroupWindowScrollFrame );
	local groupButton = _G["CT_MapMod_GroupWindowGroup"..xmlid];

	-- Set newly selected quest and highlight it
	CT_MapMod_GroupWindow.selectedButtonID = xmlid;
	local scrollFrameOffset = FauxScrollFrame_GetOffset( CT_MapMod_GroupWindowScrollFrame );
	if ( id > scrollFrameOffset and id <= (scrollFrameOffset + 6) and id <= #(CT_MAPMOD_SETS) ) then
		groupButton:LockHighlight();
	end
end

function CT_MapMod_GroupButton_OnClick(self, button)
	if ( button == "LeftButton" ) then
		CT_MapMod_GroupWindow_SetSelection(self:GetID() + FauxScrollFrame_GetOffset(CT_MapMod_GroupWindowScrollFrame))
		CT_MapMod_GroupWindow_Update();
	end
end

---------------------------------------------
-- Player and cursor coordinates

local function CT_MapMod_Coord_Unlock(unlock)
	unlockCoord = unlock;
	CT_MapMod_Coord:EnableMouse(unlockCoord);
end

function CT_MapMod_Coord_OnEnter(self)
	if (not unlockCoord) then
		return;
	end

	local text;

	-- Have to do this in order to be able to see the tooltip if button is positioned over the map.
	WorldMapPOIFrame.allowBlobTooltip = false;

	text = "To move the Coordinates, left-click and drag them. Release the mouse button to stop moving them.";

	WorldMapTooltip:SetOwner(self, "ANCHOR_NONE");
	WorldMapTooltip:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, 0);
	WorldMapTooltip:SetText("Coordinates", nil, nil, nil, nil, 1);
	WorldMapTooltip:AddLine(text, 1, 1, 1, 1);
	WorldMapTooltip:Show();
end

function CT_MapMod_Coord_OnLeave(self)
	-- Undo what we did in CT_MapMod_Coord_OnEnter()
	if (unlockCoord) then
		WorldMapPOIFrame.allowBlobTooltip = true;
		WorldMapTooltip:Hide();
	end
end

local function CT_MapMod_Coord_GetPositionOptionName(mapSize)
	-- Get the name of the option used for the position of the coordinates on the current map size
	if (not mapSize) then
		mapSize = CT_MapMod_GetMapSizeNumber();
	end
	return "coordPos" .. mapSize;
end

local function CT_MapMod_Coord_SavePosition()
	-- Save the position of the coordinates on the current map size.
	local button = CT_MapMod_Coord;
	local characterKey = CT_MapMod_GetCharKey();

	-- Anchor the coordinates frame.
	CT_MapMod_anchorFrame(CT_MapMod_Coord);

	-- Save the anchor point values.
	local anchorPoint, anchorTo, relativePoint, xoffset, yoffset = button:GetPoint(1);
	if (anchorTo) then
		anchorTo = anchorTo:GetName();
	end
	local optName = CT_MapMod_Coord_GetPositionOptionName();
	CT_MapMod_Options[characterKey][optName] = { anchorPoint, anchorTo, relativePoint, xoffset, yoffset };
end

local function CT_MapMod_Coord_StopMoving()
	local self = CT_MapMod_Coord;
	if (self.isMoving) then
		self:StopMovingOrSizing();
		self:SetUserPlaced(false);
		self.isMoving = false;
		CT_MapMod_Coord_SavePosition();
	end
end

function CT_MapMod_Coord_OnMouseDown(self, button)
	if (button == "LeftButton") then
		self:StartMoving();
		self.isMoving = true;
		CT_MapMod_Coord_OnLeave(self);  -- Hide the tooltip while dragging
	end
end

function CT_MapMod_Coord_OnMouseUp(self, button)
	if (button == "LeftButton") then
		if (self.isMoving) then
			CT_MapMod_Coord_StopMoving();
		end
	end
end

local function CT_MapMod_Coord_ResetPosition(clearSaved)
	-- Reset position of the coordinates on the current map size
	local characterKey = CT_MapMod_GetCharKey();
	if ( WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE ) then
		-- Small size world map
		CT_MapMod_Coord:ClearAllPoints();
		CT_MapMod_Coord:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPLEFT", 0, 20);
	else
		-- Full screen size world map
		CT_MapMod_Coord:ClearAllPoints();
		CT_MapMod_Coord:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOPLEFT", 10, -5);
	end
	if (clearSaved) then
		local optName = CT_MapMod_Coord_GetPositionOptionName();
		CT_MapMod_Options[characterKey][optName] = nil;
	end
end

local function CT_MapMod_Coord_ResetPositions()
	-- Reset all positions of the coordinats (1 per map size)
	local characterKey = CT_MapMod_GetCharKey();
	for i = 1, CT_MapMod_GetMapSizeNumber("max") do
		local optName = CT_MapMod_Coord_GetPositionOptionName(i);
		CT_MapMod_Options[characterKey][optName] = nil;
	end		
	CT_MapMod_Coord_ResetPosition(false);
end

function CT_MapMod_Coord_RestorePosition()
	-- Restore the position of the coordinates on the current map size.
	local button = CT_MapMod_Coord;
	local characterKey = CT_MapMod_GetCharKey();

	-- Set the frame's position
	local optName = CT_MapMod_Coord_GetPositionOptionName();
	local pos = CT_MapMod_Options[characterKey][optName];
	if (pos) then
		-- Restore to the saved position.
		button:ClearAllPoints();
		button:SetPoint(pos[1], pos[2], pos[3], pos[4], pos[5]);
	else
		-- Restore to default position.
		CT_MapMod_Coord_ResetPosition(false)
	end
end

local function CT_MapMod_Coord_GetHideOptionName(mapSize)
	-- Get the name of the option used for hiding the coordinates on the current map size
	if (not mapSize) then
		mapSize = CT_MapMod_GetMapSizeNumber();
	end
	return "coordHide" .. mapSize;
end

local coordHide;  -- local copy of this size map's hide coordinates option

function CT_MapMod_ShowHideCoord(hide)
	local characterKey = CT_MapMod_GetCharKey();
	local optName = CT_MapMod_Coord_GetHideOptionName();
	if (hide == nil) then
		-- Get current value
		hide = not not (CT_MapMod_Options[characterKey][optName]);
	else
		-- Change current value
		CT_MapMod_Options[characterKey][optName] = hide;
	end
	coordHide = hide;  -- save in local var for use by OnUpdate
	if (hide) then
		CT_MapMod_Coord:Hide();
	else
		CT_MapMod_Coord:Show();
	end
end

function CT_MapMod_MapFrame_OnUpdate()
	local cX, cY = CT_MapMod_GetCursorMapPosition();
	local pX, pY = GetPlayerMapPosition("player");
	local dec = 1;

	cX = round(cX * 100, dec);
	cY = round(cY * 100, dec);
	pX = round(pX * 100, dec);
	pY = round(pY * 100, dec);

	if (not coordHide) then
		CT_MapMod_CoordPlayerText:SetFormattedText("Player: |c00FFFFFF%3.1f|r, |c00FFFFFF%3.1f|r", pX, pY);
		if (WorldMapButton:IsMouseOver()) then
			CT_MapMod_CoordCursorText:SetFormattedText("(|c00FFFFFF%3.1f|r, |c00FFFFFF%3.1f|r)", cX, cY);
		else
			CT_MapMod_CoordCursorText:SetText("");
		end
	end
end

---------------------------------------------
-- Main button

function CT_MapMod_MainButton_OnShow(self)
	CT_MapMod_MainButton_SetCountPosition();
end

local function CT_MapMod_MainButton_SetHideMainTooltip(hide)
	-- Set the hide main button tooltip option.
	local characterKey = CT_MapMod_GetCharKey();
	CT_MapMod_Options[characterKey]["hideMainTooltip"] = hide;
end

function CT_MapMod_MainButton_OnEnter(self)
	local text;

	local characterKey = CT_MapMod_GetCharKey();
	local hide = not not (CT_MapMod_Options[characterKey]["hideMainTooltip"]);
	if (hide) then
		return;
	end

	-- Have to do this in order to be able to see the tooltip if button is positioned over the map.
	WorldMapPOIFrame.allowBlobTooltip = false;

	local mapName = CT_MapMod_GetMapName();
	if (mapName) then
		text = "To open the menu, left-click the Notes button.";
		if (CT_MapMod_CanCreateNoteOnPlayer()) then
			text = text .. "\n\nTo create a new note at the player, Ctrl left-click the Notes button (or use the menu).";
		end
		text = text .. "\n\nTo create a new note at the cursor, Ctrl left-click an open spot on the map.";
	else
		text = "Left-click the Notes button to open the menu.";
	end
	text = text .. "\n\nTo move the Notes button, shift left-click it. Click the button again to stop moving it.";

	WorldMapTooltip:SetOwner(self, "ANCHOR_NONE");
	WorldMapTooltip:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, 0);
	WorldMapTooltip:SetText("Notes", nil, nil, nil, nil, 1);
	WorldMapTooltip:AddLine(text, 1, 1, 1, 1);
	WorldMapTooltip:Show();
end

function CT_MapMod_MainButton_OnLeave(self)
	-- Undo what we did in CT_MapMod_MainButton_OnEnter()
	WorldMapPOIFrame.allowBlobTooltip = true;

	WorldMapTooltip:Hide();
end

local function CT_MapMod_MainButton_GetPositionOptionName(mapSize)
	-- Get the name of the option used for the position of the note count text on the current map size
	if (not mapSize) then
		mapSize = CT_MapMod_GetMapSizeNumber();
	end
	return "mainPos" .. mapSize;
end

local function CT_MapMod_MainButton_SavePosition()
	-- Save the position of the notes button on the current map size.
	local button = CT_MapMod_MainButton;
	local characterKey = CT_MapMod_GetCharKey();

	-- Anchor the main button.
	CT_MapMod_anchorFrame(CT_MapMod_MainButton);

	-- Save the anchor point values.
	local anchorPoint, anchorTo, relativePoint, xoffset, yoffset = button:GetPoint(1);
	if (anchorTo) then
		anchorTo = anchorTo:GetName();
	end
	local optName = CT_MapMod_MainButton_GetPositionOptionName();
	CT_MapMod_Options[characterKey][optName] = { anchorPoint, anchorTo, relativePoint, xoffset, yoffset };
end

local function CT_MapMod_MainButton_StopMoving()
	local self = CT_MapMod_MainButton;
	if (self.isMoving) then
		self:StopMovingOrSizing();
		self:SetUserPlaced(false);
		self.isMoving = false;
		CT_MapMod_MainButton_SavePosition();
	end
end

function CT_MapMod_MainButton_OnClick(self, button)
	if (self.isMoving) then
		CT_MapMod_MainButton_StopMoving();
		return;
	end
	if (IsControlKeyDown()) then
		if (CT_MapMod_CanCreateNoteOnPlayer()) then
			CT_MapMod_CreateNoteOnPlayer();
		end
	elseif (IsShiftKeyDown()) then
		self:StartMoving();
		self.isMoving = true;
		CT_MapMod_MainButton_OnLeave(self);  -- Hide the tooltip while dragging
	else
		-- Toggle the main menu
		local dropdown = CT_MapMod_MainMenuDropDown;
		CT_MapMod_MainButton_OnLeave(self);

		local uscale = UIParent:GetEffectiveScale();
		local ucenterX, ucenterY = UIParent:GetCenter();
		ucenterX = ucenterX * uscale;
		ucenterY = ucenterY * uscale;

		local bscale = self:GetEffectiveScale();
		local bcenterX, bcenterY = self:GetCenter();
		bcenterX = bcenterX * bscale;
		bcenterY = bcenterY * bscale;

		if (bcenterY < ucenterY) then
			dropdown.point = "BOTTOM";
			dropdown.relativePoint = "TOP";
		else
			dropdown.point = "TOP";
			dropdown.relativePoint = "BOTTOM";
		end
		if (bcenterX < bcenterY) then
			dropdown.point = dropdown.point .. "LEFT";
			dropdown.relativePoint = dropdown.relativePoint .. "LEFT";
		else
			dropdown.point = dropdown.point .. "RIGHT";
			dropdown.relativePoint = dropdown.relativePoint .. "RIGHT";
		end
		dropdown.relativeTo = CT_MapMod_MainButton;

		dropdown.xOffset = 0;
		dropdown.yOffset = 0;
		BW_ToggleDropDownMenu(1, nil, dropdown);
		PlaySound("igMainMenuOptionCheckBoxOn");
	end
end

local function CT_MapMod_MainButton_ResetPosition(clearSaved)
	-- Reset position of the notes button on the current map size
	local characterKey = CT_MapMod_GetCharKey();
	if ( WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE ) then
		-- Small size world map
		CT_MapMod_MainButton:ClearAllPoints();
		CT_MapMod_MainButton:SetPoint("TOPRIGHT", WorldMapDetailFrame, "TOPRIGHT", -40, 23);
	else
		-- Full screen size world map
		CT_MapMod_MainButton:ClearAllPoints();
		CT_MapMod_MainButton:SetPoint("TOPRIGHT", WorldMapPositioningGuide, "TOPRIGHT", -43, -2);
	end
	if (clearSaved) then
		local optName = CT_MapMod_MainButton_GetPositionOptionName();
		CT_MapMod_Options[characterKey][optName] = nil;
	end
end

local function CT_MapMod_MainButton_ResetPositions()
	-- Reset all positions of the notes button (1 per map size)
	local characterKey = CT_MapMod_GetCharKey();
	for i = 1, CT_MapMod_GetMapSizeNumber("max") do
		local optName = CT_MapMod_MainButton_GetPositionOptionName(i);
		CT_MapMod_Options[characterKey][optName] = nil;
	end		
	CT_MapMod_MainButton_ResetPosition(false);
end

function CT_MapMod_MainButton_RestorePosition()
	-- Restore the position of the notes button on the current map size.
	local button = CT_MapMod_MainButton;
	local characterKey = CT_MapMod_GetCharKey();

	-- Set the frame's position
	local optName = CT_MapMod_MainButton_GetPositionOptionName();
	local pos = CT_MapMod_Options[characterKey][optName];
	if (pos) then
		-- Restore to the saved position.
		button:ClearAllPoints();
		button:SetPoint(pos[1], pos[2], pos[3], pos[4], pos[5]);
	else
		-- Restore to default position.
		CT_MapMod_MainButton_ResetPosition(false)
	end
end

local function CT_MapMod_MainButton_GetCountPositionOptionName(mapSize)
	-- Get the name of the option used for the position of the note count text on the current map size
	if (not mapSize) then
		mapSize = CT_MapMod_GetMapSizeNumber();
	end
	return "countPos" .. mapSize;
end

function CT_MapMod_MainButton_SetCountPosition(pos)
	-- Change the position of the note count text on the current map size
	local characterKey = CT_MapMod_GetCharKey();
	local optName = CT_MapMod_MainButton_GetCountPositionOptionName();
	if (not pos) then
		-- Get option
		pos = CT_MapMod_Options[characterKey][optName] or 1;
	else
		-- Set option
		CT_MapMod_Options[characterKey][optName] = pos;
	end
	-- 1==Left side of button, 2==Top, 3==Right, 4==Bottom
	CT_NumNotes:ClearAllPoints();
	if (pos == 4) then
		CT_NumNotes:SetPoint("TOP", CT_MapMod_MainButton, "BOTTOM", 0, -3);
	elseif (pos == 3) then
		CT_NumNotes:SetPoint("LEFT", CT_MapMod_MainButton, "RIGHT", 3, 0);
	elseif (pos == 2) then
		CT_NumNotes:SetPoint("BOTTOM", CT_MapMod_MainButton, "TOP", 0, 3);
	else
		CT_NumNotes:SetPoint("RIGHT", CT_MapMod_MainButton, "LEFT", -3, 0);
	end
end

local function CT_MapMod_MainButton_ToggleCountPosition()
	-- Change the position of the note count text on the current map size
	local characterKey = CT_MapMod_GetCharKey();
	local optName = CT_MapMod_MainButton_GetCountPositionOptionName();
	pos = CT_MapMod_Options[characterKey][optName] or 1;
	pos = pos + 1;
	if (pos > 4) then
		pos = 1;
	end
	CT_MapMod_Options[characterKey][optName] = pos;
	CT_MapMod_MainButton_SetCountPosition();
end

---------------------------------------------
-- Main menu

function CT_MapMod_MainMenu_DropDown_OnClick(self)
	local characterKey = CT_MapMod_GetCharKey();

	if (
		self.value == "autoHerbs" or
		self.value == "autoMinerals"
	) then
		if (CT_MapMod_Options[characterKey][self.value]) then
			CT_MapMod_EnableAutoGatherNotes(false, self.value);
		else
			CT_MapMod_EnableAutoGatherNotes(true, self.value);
		end

	elseif (self.value == "receivenotes") then
		if (CT_MapMod_Options[characterKey].receiveNotes) then
			CT_MapMod_EnableReceiveNotes(nil);
		else
			CT_MapMod_EnableReceiveNotes(1);
		end

	elseif (self.value == "resetposition") then
		-- Reset position of the Notes button on the current map (small or full).
		CT_MapMod_MainButton_ResetPosition(true);

	elseif (self.value == "togglecountpos") then
		CT_MapMod_MainButton_ToggleCountPosition();

	elseif (self.value == "resetcoord") then
		-- Reset position of the coordinates on the current map (small or full).
		CT_MapMod_Coord_ResetPosition(true);

	elseif (self.value == "unlockCoord") then
		CT_MapMod_Coord_Unlock(true);

	elseif (self.value == "lockCoord") then
		CT_MapMod_Coord_Unlock(false);

	elseif (self.value == "hideCoord") then
		local optName = CT_MapMod_Coord_GetHideOptionName();
		if (CT_MapMod_Options[characterKey][optName]) then
			CT_MapMod_ShowHideCoord(false);
		else
			CT_MapMod_ShowHideCoord(1);
		end

	elseif (self.value == "hideMainTooltip") then
		if (CT_MapMod_Options[characterKey].hideMainTooltip) then
			CT_MapMod_MainButton_SetHideMainTooltip(false);
		else
			CT_MapMod_MainButton_SetHideMainTooltip(1);
		end

	elseif (self.value == "setfilter") then
		CT_MapMod_FilterWindow:Show();

	elseif (self.value == "clearfilter") then
		CT_MapMod_ExecuteFilter("");

	elseif (self.value == "playernote") then
		if (CT_MapMod_CanCreateNoteOnPlayer()) then
			CT_MapMod_CreateNoteOnPlayer();
		end

	elseif (self.value == "editlast") then
		CT_MapMod_EditNote();

	else
		-- Show/hide groups
		for key, val in pairs(CT_MAPMOD_SETS) do
			if (val == self.value) then
				local characterKey = CT_MapMod_GetCharKey();
				if ( not CT_MapMod_Options[characterKey].hideGroups ) then
					CT_MapMod_Options[characterKey].hideGroups = { };
				end
				CT_MapMod_Options[characterKey].hideGroups[self.value] = not CT_MapMod_Options[characterKey].hideGroups[self.value];
				CT_MapMod_UpdateMap();
				break;
			end
		end
	end
end

function CT_MapMod_MainMenu_DropDown_Initialize(self, level)
	local info;
	local characterKey = CT_MapMod_GetCharKey();
	local optName;

	if (level == 2 and Lib_UIDROPDOWNMENU_MENU_VALUE == "menu_button") then

		info = Lib_UIDropDownMenu_CreateInfo();
		info.text = "Reset position"
		info.value = "resetposition";
		info.notCheckable = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		optName = CT_MapMod_MainButton_GetPositionOptionName();
		if (not CT_MapMod_Options[characterKey]) then
			info.disabled = true;
		elseif (not CT_MapMod_Options[characterKey][optName]) then
			info.disabled = true;
		end
		Lib_UIDropDownMenu_AddButton(info, level);

		info = Lib_UIDropDownMenu_CreateInfo();
		info.text = "Hide tooltip"
		info.value = "hideMainTooltip";
		if (CT_MapMod_Options[characterKey] and CT_MapMod_Options[characterKey].hideMainTooltip) then
			info.checked = 1;
		end
		info.keepShownOnClick = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		Lib_UIDropDownMenu_AddButton(info, level);

		info = Lib_UIDropDownMenu_CreateInfo();
		info.text = "Change note count position"
		info.value = "togglecountpos";
		info.notCheckable = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		info.keepShownOnClick = 1;
		Lib_UIDropDownMenu_AddButton(info, level);

		return;

	elseif (level == 2 and Lib_UIDROPDOWNMENU_MENU_VALUE == "menu_coord") then

		info = Lib_UIDropDownMenu_CreateInfo();
		if (unlockCoord) then
			info.text = "Lock"
			info.value = "lockCoord";
		else
			info.text = "Unlock"
			info.value = "unlockCoord";
		end
		info.notCheckable = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		Lib_UIDropDownMenu_AddButton(info, level);

		info = Lib_UIDropDownMenu_CreateInfo();
		info.text = "Reset position"
		info.value = "resetcoord";
		info.notCheckable = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		optName = CT_MapMod_Coord_GetPositionOptionName();
		if (not CT_MapMod_Options[characterKey]) then
			info.disabled = true;
		elseif (not CT_MapMod_Options[characterKey][optName]) then
			info.disabled = true;
		end
		Lib_UIDropDownMenu_AddButton(info, level);

		info = Lib_UIDropDownMenu_CreateInfo();
		info.text = "Hide"
		info.value = "hideCoord";
		optName = CT_MapMod_Coord_GetHideOptionName();
		if (CT_MapMod_Options[characterKey] and CT_MapMod_Options[characterKey][optName]) then
			info.checked = 1;
		end
		info.keepShownOnClick = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		Lib_UIDropDownMenu_AddButton(info, level);

		return;

	elseif (level == 2 and Lib_UIDROPDOWNMENU_MENU_VALUE == "auto_add") then

		info = Lib_UIDropDownMenu_CreateInfo();
		info.text = "Herbs"
		info.value = "autoHerbs";
		if (CT_MapMod_Options[characterKey] and CT_MapMod_Options[characterKey].autoHerbs) then
			info.checked = 1;
		end
		info.keepShownOnClick = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		Lib_UIDropDownMenu_AddButton(info, level);

		info = Lib_UIDropDownMenu_CreateInfo();
		info.text = "Minerals"
		info.value = "autoMinerals";
		if (CT_MapMod_Options[characterKey] and CT_MapMod_Options[characterKey].autoMinerals) then
			info.checked = 1;
		end
		info.keepShownOnClick = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		Lib_UIDropDownMenu_AddButton(info, level);

		return;

	end

	info = Lib_UIDropDownMenu_CreateInfo();
	info.text = "CT_MapMod";
	info.notCheckable = 1;
	info.justifyH = "CENTER";
	info.isTitle = true;
	Lib_UIDropDownMenu_AddButton(info);

	info = Lib_UIDropDownMenu_CreateInfo();
	info.text = "Create note at player"
	info.value = "playernote";
	info.notCheckable = 1;
	info.func = CT_MapMod_MainMenu_DropDown_OnClick;
	if (not CT_MapMod_CanCreateNoteOnPlayer()) then
		info.disabled = true;
	end
	Lib_UIDropDownMenu_AddButton(info);

	info = Lib_UIDropDownMenu_CreateInfo();
	info.text = "Edit last note added to this map"
	info.value = "editlast";
	info.notCheckable = 1;
	info.func = CT_MapMod_MainMenu_DropDown_OnClick;
	do
		local id = 0;
		local mapName = CT_MapMod_GetMapName();
		if (mapName) then
			local notes = CT_UserMap_Notes[mapName];
			if (notes) then
				id = #(notes);
			else
				id = 0;
			end
		end
		if (id == 0) then
			info.disabled = true;
		end
	end
	Lib_UIDropDownMenu_AddButton(info);

	local emptyFilter = ((CT_MapMod_Filter or "") == "");

	info = Lib_UIDropDownMenu_CreateInfo();
	if (emptyFilter) then
		info.text = "Set filter text"
	else
		info.text = "Edit filter text"
	end
	info.value = "setfilter";
	info.notCheckable = 1;
	info.func = CT_MapMod_MainMenu_DropDown_OnClick;
	Lib_UIDropDownMenu_AddButton(info);

	info = Lib_UIDropDownMenu_CreateInfo();
	info.text = "Clear filter text"
	info.value = "clearfilter";
	info.notCheckable = 1;
	info.func = CT_MapMod_MainMenu_DropDown_OnClick;
	if (emptyFilter) then
		info.disabled = true;
	end
	Lib_UIDropDownMenu_AddButton(info);

	info = Lib_UIDropDownMenu_CreateInfo();
	info.text = "Options";
	info.notCheckable = 1;
	info.justifyH = "CENTER";
	info.isTitle = true;
	Lib_UIDropDownMenu_AddButton(info);

	info = Lib_UIDropDownMenu_CreateInfo();
	info.text = "Notes button"
	info.value = "menu_button";
	info.keepShownOnClick = 1;
	info.notCheckable = 1;
	info.hasArrow = true;
	Lib_UIDropDownMenu_AddButton(info);

	info = Lib_UIDropDownMenu_CreateInfo();
	info.text = "Coordinates"
	info.value = "menu_coord";
	info.keepShownOnClick = 1;
	info.notCheckable = 1;
	info.hasArrow = true;
	Lib_UIDropDownMenu_AddButton(info);

	info = Lib_UIDropDownMenu_CreateInfo();
	info.text = "Create notes when gathering"
	info.value = "auto_add";
	info.keepShownOnClick = 1;
	info.notCheckable = 1;
	info.hasArrow = true;
	Lib_UIDropDownMenu_AddButton(info);

	info = Lib_UIDropDownMenu_CreateInfo();
	info.text = "Receive notes from players"
	info.value = "receivenotes";
	if (CT_MapMod_Options[characterKey] and CT_MapMod_Options[characterKey].receiveNotes) then
		info.checked = 1;
	end
	info.keepShownOnClick = 1;
	info.func = CT_MapMod_MainMenu_DropDown_OnClick;
	Lib_UIDropDownMenu_AddButton(info);

	info = Lib_UIDropDownMenu_CreateInfo();
	info.text = "Groups To Show";
	info.notCheckable = 1;
	info.justifyH = "CENTER";
	info.isTitle = true;
	Lib_UIDropDownMenu_AddButton(info);

	for key, val in pairs(CT_MAPMOD_SETS) do
		info = Lib_UIDropDownMenu_CreateInfo();
		info.text = val;
		info.value = val;
		if ( CT_MapMod_Options[characterKey] and ( not CT_MapMod_Options[characterKey].hideGroups or not CT_MapMod_Options[characterKey].hideGroups[val] ) ) then
			info.checked = 1;
		end
		info.keepShownOnClick = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		Lib_UIDropDownMenu_AddButton(info);
	end
end

function CT_MapMod_MainMenu_DropDown_OnLoad(self)
	Lib_UIDropDownMenu_Initialize(self, CT_MapMod_MainMenu_DropDown_Initialize, "MENU");
	Lib_UIDropDownMenu_SetWidth(self, 130);
end

---------------------------------------------
-- Convert old notes

local function CT_MapMod_UpdateOldNotes()
	-- Convert old notes to new format.
	local temp = {};
	local update = false;
	for key, val in pairs(CT_UserMap_Notes) do
		if ( type(key) == "number" and type(val) == "table" ) then
			update = true;
			-- Old notes 
			local tempvar = {
				name = val.desc,
				x = val.x,
				y = val.y,
				icon = 1,
				set = 1,
			};
			local zone = val.zone;
			if (zone) then
				if (not temp[zone]) then
					temp[zone] = {};
				end
				temp[zone][#(temp[zone])+1] = tempvar;
			end
			CT_UserMap_Notes[key] = nil;
		end
	end
	if (update) then
		for key, val in pairs(temp) do
			if ( not CT_UserMap_Notes[key] ) then
				CT_UserMap_Notes[key] = {};
			end
			for k, v in pairs(val) do
				tinsert(CT_UserMap_Notes[key], v);
			end
		end
		CT_MapMod_Print("<CTMod> Updated old notes to new format.", 1, 0.5, 0);
	end
end

---------------------------------------------
-- Event frame

function CT_MapMod_EventFrame_OnEvent(self, event, arg1)

	if ( event == "CHAT_MSG_OPENING" ) then
		CT_MapMod_ParseResource(event, arg1);

	elseif ( event == "UI_ERROR_MESSAGE" ) then
		if ( arg1 and ( string.find(arg1, "Requires Herbalism") or string.find(arg1, "Requires Mining") ) ) then
			CT_MapMod_ParseResource(event, arg1);
		end

	elseif ( event == "DISPLAY_SIZE_CHANGED" ) then
		CT_MapMod_AdjustPositions();

	elseif ( event == "WORLD_MAP_UPDATE" ) then
		CT_MapMod_UpdateMap();

	elseif (event == "PLAYER_LOGIN") then

		-- Get character key. Will also establish default options table if needed.
		local characterKey = CT_MapMod_GetCharKey();

		-- Get options table for this character
		local options = CT_MapMod_Options[characterKey];

		-- options.autoHerbs will be nil only if user was using CT_MapMod prior to 4.0100
		if (options.autoHerbs == nil) then
			-- Convert existing CT_MapMod user's old autoGather option.
			if (options.autoGather) then
				options.autoHerbs = true;
			else
				options.autoHerbs = false;
			end
		end

		-- options.autoMinerals will be nil only if user was using CT_MapMod prior to 4.0100
		if (options.autoMinerals == nil) then
			-- Convert existing CT_MapMod user's old autoGather option.
			if (options.autoGather) then
				options.autoMinerals = true;
			else
				options.autoMinerals = false;
			end
		end

		CT_MapMod_UpdateOldNotes();

	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		local characterKey = CT_MapMod_GetCharKey();
		SetMapToCurrentZone();

	end
end

---------------------------------------------
-- WorldMap hooks

local oldProcessMapClick = ProcessMapClick;
function ProcessMapClick(...)
	-- This gets called from WorldMapFrame.lua when user left clicks on the map.
	local mapName = CT_MapMod_GetMapName();
	if ( IsControlKeyDown() and mapName and not CT_MapMod_IsDialogShown() ) then
		-- Create a new note at the cursor position.
		CT_MapMod_CreateNoteOnCursor();
	else
		oldProcessMapClick(...);
	end
end

local function CT_MapMod_WorldMapFrame_OnHide(...)
	CT_MapMod_NoteWindow_Cancel();
	CT_MapMod_FilterWindow:Hide();
	CT_MapMod_MainButton_StopMoving();
	CT_MapMod_Coord_StopMoving();
end
WorldMapFrame:HookScript("OnHide", CT_MapMod_WorldMapFrame_OnHide);
hooksecurefunc("WorldMapFrame_OnHide", CT_MapMod_WorldMapFrame_OnHide);


local function CT_MapMod_WorldMap_ToggleSizeUp()
	CT_MapMod_AdjustPositions();
end
hooksecurefunc("WorldMap_ToggleSizeUp", CT_MapMod_WorldMap_ToggleSizeUp);


local function CT_MapMod_WorldMap_ToggleSizeDown()
	CT_MapMod_AdjustPositions();
end
hooksecurefunc("WorldMap_ToggleSizeDown", CT_MapMod_WorldMap_ToggleSizeDown);


hooksecurefunc("WorldMapFrame_SetOpacity",
	function(opacity)
		local alpha;
		alpha = 0.5 + (1.0 - opacity) * 0.50;
		CT_MapMod_MainButton:SetAlpha(alpha);
		CT_MapMod_Coord:SetAlpha(alpha);
		CT_MapMod_MapButtonFrame:SetAlpha(alpha);
		WorldMapTrackQuest:SetAlpha(alpha);
		WorldMapQuestShowObjectives:SetAlpha(alpha);
	end
);

hooksecurefunc("WorldMap_OpenToQuest",
	function(...)
		CT_MapMod_UpdateMap();
	end
);

hooksecurefunc("WorldMapFrame_ToggleWindowSize",
	function(...)
		CT_MapMod_UpdateMap();
	end
);

--Hooks the CT_MapMod_NoteWindow so it can be displayed on OmegaMap
hooksecurefunc("OmegaMapToggle", function()
	if ( OmegaMapFrame:IsVisible() ) then
	--Sets the window to OmegaMap
		CT_MapMod_NoteWindow:SetParent(OmegaMapFrame);
		CT_MapMod_NoteWindow:SetPoint("CENTER", "OmegaMapDetailFrame");
		CT_MapMod_NoteWindow:SetFrameStrata("DIALOG")
		WorldMapTooltip:SetParent(OmegaMapFrame)
		WorldMapTooltip:SetFrameStrata("DIALOG")
	else
	--Sets the window back to the World Map
		CT_MapMod_NoteWindow:SetParent(WorldMapFrame);
		CT_MapMod_NoteWindow:SetPoint("CENTER", "WorldMapDetailFrame");
		CT_MapMod_NoteWindow:SetFrameStrata("DIALOG")
		WorldMapTooltip:SetParent(WorldMapFrame)
		WorldMapTooltip:SetFrameStrata("DIALOG")

	end
end)





--------------------------------------------
-- Options Frame Code

-- Slash command
local function slashCommand(msg)
	module:showModuleOptions(module.name);
end

module:setSlashCmd(slashCommand, "/ctmapmod", "/ctmap", "/mapmod");


local theOptionsFrame;

local optionsFrameList;

local function optionsInit()
	optionsFrameList = {};

	-- Dummy frame representing a master frame.
	local frame = {};
	frame.offset = 0;
	frame.size = 0;
	frame.details = "";
	frame.yoffset = 0;
	frame.top = 0;
	frame.data = {};

	tinsert(optionsFrameList, frame);
end

local function optionsGetData()
	local frame = optionsFrameList[#optionsFrameList];
	return frame.data;
end

local function optionsAddFrame(offset, size, details, data)
	local yoffset;
	local prevFrame = optionsFrameList[#optionsFrameList];
	if (prevFrame) then
		yoffset = prevFrame.yoffset;
	else
		yoffset = 0;
	end
	yoffset = yoffset + offset;

	local frame = {};
	frame.offset = offset;
	frame.size = size;
	frame.details = details;
	frame.yoffset = 0;
	frame.top = yoffset;
	frame.data = data or {};

	tinsert(optionsFrameList, frame);
end

local function optionsAddObject(offset, size, details)
	local frame = optionsFrameList[#optionsFrameList];
	local yoffset = frame.yoffset + offset;

	details = gsub(details, "%%y", yoffset);
	details = gsub(details, "%%b", yoffset - size);
	details = gsub(details, "%%s", size);
	tinsert(frame.data, details);

	frame.yoffset = yoffset - size;
end

local function optionsAddScript(name, func)
	local frame = optionsFrameList[#optionsFrameList];
	frame.data[name] = func;
end

local function optionsEndFrame()
	local frame = tremove(optionsFrameList);

	local size = frame.size;
	local top = frame.top;
	local bot;
	if (size == 0) then
		bot = top + frame.yoffset;
		size = top - bot + 1;
	else
		bot = top - size - 1;
	end

	local details = frame.details;

	details = gsub(details, "%%y", top);
	details = gsub(details, "%%b", bot);
	details = gsub(details, "%%s", size);

	local prevFrame = optionsFrameList[#optionsFrameList];
	prevFrame.yoffset = bot;
	prevFrame.data[details] = frame.data;
end

-- Options frame
module.frame = function()
	local textColor0 = "1.0:1.0:1.0";
	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "0.9:0.72:0.0";
	local xoffset, yoffset;

	optionsInit();

	optionsAddFrame(-5, 0, "frame#tl:0:%y#r");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Tips");
		optionsAddObject( -2, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#You can use /ctmap, /ctmapmod, or /mapmod to open this options window directly.#" .. textColor2 .. ":l");
		optionsAddObject( -5, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#To access most of the options for CT_MapMod, open the game's World Map and click on the 'Notes' button.#" .. textColor2 .. ":l");

		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Notes Button");
		optionsAddObject(-10, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#Click the button below to reset the position of the Notes button and the coordinates on the map window.#" .. textColor2 .. ":l");
		optionsAddFrame( -10,   30, "button#t:0:%y#s:120:%s#v:UIPanelButtonTemplate#Reset position");
			optionsAddScript("onclick",
				function(self)
					CT_MapMod_MainButton_ResetPositions();
					CT_MapMod_Coord_ResetPositions();
				end
			);
		optionsEndFrame();

		optionsAddScript("onload",
			function(self)
				theOptionsFrame = self;
			end
		);
	optionsEndFrame();

	return "frame#all", optionsGetData();
end

module.update = function(self, optName, value)
	if (optName == "init") then
	else
	end
end

print(OMEGAMAP_CTMAP_LOADED_MESSAGE)

end