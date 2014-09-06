--	///////////////////////////////////////////////////////////////////////////////////////////

--	Code to show exterior & alternate BG maps and notes

--	///////////////////////////////////////////////////////////////////////////////////////////

local currentMapNotes = {} --Table of indexed note names & Tooltips

--Checks current location  against database to see is Alt map is available
function OmegaMap_LoadAltMap()
--print("Location:  "..GetMapInfo())
--print("Zone: "..GetZoneText())
--print("Subzone: "..GetMinimapZoneText())

	local index = 1
	local continent = GetCurrentMapContinent()
	local curWorldMap = GetMapInfo()
	local curZoneName = GetZoneText()
	local curSubZone = GetMinimapZoneText()
	local curMapList = {}
	local curMapId = GetCurrentMapAreaID()

--Check to see if zone is the molten front
	if (curWorldMap == "MoltenFront") then
		curMapList = OMEGAMAP_EXTERIORS_LIST
 --Check to see if in battleground or instance propper
	elseif (continent == -1)  and (OmegaMapConfig.showBattlegrounds)then
		curMapList = OMEGAMAP_BATTLEGROUNDS_LIST
	elseif (continent == 0) then   --Do nothing if world map is shown
		return false
	else
		curMapList = OMEGAMAP_EXTERIORS_LIST
	end

--Cycle through the maps in the list looking for a match
	while ( curMapList[index]) do
		local mapData = curMapList[index]
		local mapName = mapData.name
		local mapSubZone = ""
		local mapNumber = mapData.mapNumber

		if (mapData.subZones) then 
			mapSubZone = mapData.subZones 
		end
		if (mapData.mapNumber) then 
			mapNumber = mapData.mapNumber 
		end

--Checks to see if current location and either zone or subzone match database info
		if (curWorldMap == mapData.location) and ((curZoneName == mapData.zoneName) 
			or (string.find(mapSubZone, curSubZone)) or (curMapId == mapNumber ))then

--Check to see if subzone is "Deepholm" and not the Sactuary area arround the Temple of earth
			if (curWorldMap == "Deepholm") and (string.find(OM_SUBZONE["Deepholm"], curSubZone)) and  not UnitIsPVPSanctuary("player") then 
				return false
			else
				OMEGAMAP_ALTMAP = mapData --Sets global value for ease of future use
				OmegaMapAltMapNoteFrame:SetPoint("TOPLEFT" ,"OmegaMapAltMapFrame" ,"TOPRIGHT",6 ,0)
				return true
			end
--Check to see if exterior is in the molten front
		elseif (curWorldMap == "MoltenFront") and  (string.find(mapSubZone, curSubZone)) then	--
			OMEGAMAP_ALTMAP = mapData --Sets global value for ease of future use
			--move the BG notes to the edge of the map when not full size
			OmegaMapAltMapNoteFrame:SetPoint("TOPLEFT" ,"OmegaMapAltMapFrame" ,"TOPRIGHT",6 ,0)
			return true
		end


		--Battleground check
	--Checks to see if current location and either zone or subzone match database info
		if (curWorldMap == mapData.location or curMapId == mapNumber  ) and continent == -1 then
--Check to exclude the molten front from triggering as a battleground due to being instanced
			if (curWorldMap == "MoltenFront") then
				OMEGAMAP_ALTMAP = false  --no alt map found
				return false
			end
			OMEGAMAP_ALTMAP = mapData --Sets global value for ease of future use
			--move the BG notes to the edge of the map when not full size
			OmegaMapAltMapNoteFrame:SetPoint("TOPLEFT" ,"OmegaMapAltMapFrame" ,"TOPLEFT",mapData.mapEdge*OmegaMapAltMapFrame:GetWidth(),0)
			return true
		end
		
		index = index + 1
	end
	OMEGAMAP_ALTMAP = false  --no alt map found
	return false
end

--Creates the note UI is it doesnt exist  or reset the data if allready made
function OmegaMap_CreateAltMapNote( noteNumber )
	local altMap = OMEGAMAP_ALTMAP
	local noteName = "note"..noteNumber  -- Data Name
	local note = {}
	local frame = _G["OmegaMapPOINote"..noteNumber]  --Note shown in the scroll area
	local button = _G["OmegaMapPOINote"..noteNumber.."Button"] --Button POI shown on the map

--Create frame & button if does not exist all ready
	if not ( frame ) then
		frame = CreateFrame("Frame" ,"OmegaMapPOINote"..noteNumber, OmegaMapAltMapNoteFrameScrollChildFrame, "OmegaMapPOINoteTemplate")
		frame:SetID(noteNumber)
		frame:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL)
		
		local noteButton = CreateFrame("Button" ,"OmegaMapPOINote"..noteNumber.."NoteButton",frame, "NoteButtonTemplate")
		noteButton:SetPoint("RIGHT", "OmegaMapPOINote"..noteNumber.."Title", "LEFT")
		noteButton:CreateTexture(frame:GetName().."NoteButtonTexture", "BACKGROUND")
		noteButton:SetID(noteNumber)
		
		local texture = _G[frame:GetName().."NoteButtonTexture"]
		texture:SetWidth(16)
		texture:SetHeight(16)
		texture:SetPoint("CENTER", 0, 0)
	end

	if not ( button ) then
		button = CreateFrame("Button" ,"OmegaMapPOINote"..noteNumber.."Button", OmegaMapAltMapFrame, "NoteButtonTemplate")
		button:CreateTexture(button:GetName().."Texture", "BACKGROUND")
		button:SetID(noteNumber)
		button:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL)

		local texture = _G[button:GetName().."Texture"]
		texture:SetWidth(16)
		texture:SetHeight(16)
		texture:SetPoint("CENTER", 0, 0)
	end
	
	--Returning values to default
	local frameName = frame:GetName()
	_G[frameName.."Title"]:SetText("")  --Sets Text
	_G[frameName.."Tooltip"]:SetText("")  --Sets Text
	_G[frameName.."NoteButton"]:SetText("")  --Sets Icon Symbol
	_G[frameName.."Button"]:SetText("")
	_G[frameName.."Button"]:SetNormalTexture("Interface\\WorldMap\\GravePicker-Unselected")
	_G[frameName.."NoteButtonTexture"]:SetTexture("Interface\\Addons\\OmegaMap\\Icons\\Clear")
	_G[frameName.."ButtonTexture"]:SetTexture("Interface\\Addons\\OmegaMap\\Icons\\Clear")

--Sets Note position in scroll frame
	if noteNumber == 1 then
		frame:SetPoint("TOPLEFT", OmegaMapAltMapNoteFrameScrollChildFrame, "TOPLEFT", 0, 0)
	else
		frame:SetPoint("TOPLEFT", "OmegaMapPOINote"..(noteNumber-1), "BOTTOMLEFT", 0, 0)
	end

	return frame
end

--Loads the data from the files
function OmegaMap_LoadAltMapNotes()
	if (not OmegaMap_LoadAltMap() )then OmegaMap_HideAltMap() return end --Check to see if Alt map is needed

	local altMap = OMEGAMAP_ALTMAP
	local noteIndex = 1  --Data index
	local totalNotes = 1  --Total number of notes inclding BG POI
	local noteName = "note"..noteIndex  -- Data Name
	local note = {}
	local continent = GetCurrentMapContinent()

	--Loads Battleground POI first
	if continent == -1 then 
		totalNotes = OMLoadBGPOI() +1
		--print(totalNotes)
	end

	--Cycles through note data and creates needed items
	while ( altMap[noteName] ) do
		note = altMap[noteName]
		local AltMapNote = OmegaMap_CreateAltMapNote(totalNotes)
		local AltMapNoteName = AltMapNote:GetName()
		local AltMapNoteTitle = note.text
		if note.special then
			AltMapNoteTitle = AltMapNoteTitle.." - "..note.special
		end
	currentMapNotes[totalNotes] = {AltMapNoteTitle, note.tooltiptxt,"note",""}
	_G[AltMapNoteName.."Title"]:SetText(note.color..AltMapNoteTitle)  --Sets Text
	--_G[AltMapNoteName.."Tooltip"]:SetText(note.tooltiptxt)  --Sets Text
	_G[AltMapNoteName.."NoteButton"]:SetText(note.symbol[1])  --Sets Icon Symbol
	_G[AltMapNoteName.."Button"]:SetText(note.symbol[1])
	_G[AltMapNoteName.."Button"]:SetNormalTexture("Interface\\WorldMap\\GravePicker-Unselected")
	_G[AltMapNoteName.."NoteButton"]:SetNormalTexture("Interface\\WorldMap\\GravePicker-Unselected")
	
	if note.symbol[1] == "FC" or  note.symbol[1] == "F" then
		currentMapNotes[totalNotes][3]= "flag"
		currentMapNotes[totalNotes][4] = note.bgFlag
	end

-- Hide Blank Symbols
			if (note.symbol[1] == " ") or (note.bgPOI) then 
				_G[AltMapNoteName.."NoteButton"]:Hide()
				_G[AltMapNoteName.."Button"]:Hide()
			else 
				_G[AltMapNoteName.."Button"]:Show()
			end 

			local cX = note.coords[1][1]/100 * OmegaMapAltMapFrame:GetWidth()
			local cY = note.coords[1][2]/100 * OmegaMapAltMapFrame:GetHeight()
			_G[AltMapNoteName.."Button"]:SetPoint("Center", OmegaMapAltMapFrame, "TOPLEFT", cX, -cY)

			noteIndex = noteIndex + 1
			totalNotes = totalNotes +1
			noteName = "note"..noteIndex
			_G[AltMapNoteName]:Show()
		end
		--Sets the Altername map file to show
		_G["OmegaMapExtDetailTile1"]:SetTexture(altMap.filename)

		--hides unused poi
		local i = totalNotes
		local t = _G["OmegaMapPOINote"..i]
		local b = _G["OmegaMapPOINote"..i.."Button"]
		while ( t ) do
			t:Hide()
			b:Hide()
			i = i + 1

			t = _G["OmegaMapPOINote"..i]
			b = _G["OmegaMapPOINote"..i.."Button"]
		end

	--Hides Omega Map default world map POI
		local i = 1
		local t = _G[ "OmegaMapFramePOI"..i ]
		while ( t ) do
			t:Hide()
			i = i + 1
			t = _G[ "OmegaMapFramePOI"..i ]
		end

	--
		OmegaMapAltMapFrame:Show()
		OmegaMapDetailFrame:Hide()
		OmegaMapNoteFrame:Hide()
		OmegaMapFrameAreaFrame:Hide()
		OmegaMapQuestScrollFrame:Hide()
		OmegaMapBlobFrame:DrawNone();
		OmegaMapArchaeologyDigSites:DrawNone();

end

--Hides the custom map & notes, while restoring the normal map
function OmegaMap_HideAltMap()
	local noteNumber = 1
	local AltMapNote =_G["OmegaMapPOINote"..noteNumber]

	while ( AltMapNote ) do
		_G["OmegaMapPOINote"..noteNumber]:Hide()
		_G["OmegaMapPOINote"..noteNumber.."Button"]:Hide()
		noteNumber = noteNumber + 1
		AltMapNote =_G["OmegaMapPOINote"..noteNumber]
	end

	OMEGAMAP_ALTMAP = false
	currentMapNotes = {}
	for k,v in pairs(currentMapNotes) do currentMapNotes[k]=nil end

	OmegaMapAltMapFrame:Hide()
	OmegaMapDetailFrame:Show()
	if  not (OmegaMapConfig.clearMap) then
		OmegaMapNoteFrame:Show()
	end
	OmegaMapFrameAreaFrame:Show()
		--Used to hide the objective list, but keep POI on map
		--if (not OmegaMapConfig.hideObjectives) and  OmegaMapDetailFrame:IsShown() then
			--OmegaMapQuestScrollFrame:Show();
		--else
			--OmegaMapShowObjectivesButton:Show();
		--end
end

--Code to retrieve & display BG POI Landmarks
function OMLoadBGPOI()
	local numPOIs = GetNumMapLandmarks()

	for i=1, numPOIs do
		local frame = OmegaMap_CreateAltMapNote(i)
		local omegaMapPOIName = frame:GetName()
		local omegaMapPOI = _G[omegaMapPOIName]

		if ( i <= numPOIs ) then
			local name, description, textureIndex, x, y, mapLinkID, inBattleMap, graveyardID, areaID = GetMapLandmarkInfo(i)
			local x1, x2, y1, y2 = GetPOITextureCoords(textureIndex)
			currentMapNotes[i] = {name,description,"POI"}
			local button = _G[omegaMapPOIName.."Button"]
			local texture = _G[button:GetName().."Texture"]
			local noteButton = _G[omegaMapPOIName.."NoteButton"]
			local noteTexture = _G[omegaMapPOIName.."NoteButtonTexture"]

			button:SetText("")
			button:SetNormalTexture("Interface\\Addons\\OmegaMap\\Icons\\Clear")

			noteButton:SetText("")
			noteButton:SetNormalTexture("Interface\\Addons\\OmegaMap\\Icons\\Clear")


			_G[omegaMapPOIName.."Title"]:SetText(name) --.." "..x.." "..y)  --Sets Text

			--button:SetWidth(32)
			--button:SetHeight(32)

			texture:SetTexture("Interface\\Minimap\\POIIcons")
			texture:SetTexCoord(x1, x2, y1, y2)
			noteTexture:SetTexture("Interface\\Minimap\\POIIcons")
			noteTexture:SetTexCoord(x1, x2, y1, y2)

			x, y = OmegaMapOffsetAltMapCoords(x,y)
			x = x * OmegaMapAltMapFrame:GetWidth()
			y = y * OmegaMapAltMapFrame:GetHeight()

			button:SetPoint("Center", OmegaMapAltMapFrame, "TOPLEFT", x, -y)
			button:Show()
			frame:Show()
			i = i + 1

			end

	end
	return numPOIs
end

--button script handlers
function buttonOnEnter(self)
	local noteId = self:GetID()
	local mapData = OMEGAMAP_ALTMAP
	local tooltip = currentMapNotes[noteId][2]
	local name, description, textureIndex, x, y, mapLinkID, inBattleMap, graveyardID, areaID = GetMapLandmarkInfo(noteId)
	OmegaMapTooltip:SetOwner(self, "ANCHOR_RIGHT")

	if tooltip then
		OmegaMapTooltip:SetText(tooltip, nil, nil, nil, nil, 1)
	end

	local self = self:GetName()
	local targetPair

	if self == "OmegaMapPOINote"..noteId.."Button" then
		targetPair ="OmegaMapPOINote"..noteId.."NoteButton"
	else
		targetPair ="OmegaMapPOINote"..noteId.."Button"
	end

	_G[targetPair]:SetNormalTexture("Interface\\WorldMap\\GravePicker-Selected")
	UIFrameFlash(_G[targetPair]:GetNormalTexture(), .5, .5, -1, true, 0, 0)

end

function buttonOnLeave(self)
	local noteId = self:GetID()
	local mapData = OMEGAMAP_ALTMAP
	local self = self:GetName()
	local targetPair

	if self == "OmegaMapPOINote"..noteId.."Button" then
		targetPair ="OmegaMapPOINote"..noteId.."NoteButton"
	else
		targetPair ="OmegaMapPOINote"..noteId.."Button"
	end

	if currentMapNotes[noteId][3] == "note" then
		_G[targetPair]:SetNormalTexture("Interface\\WorldMap\\GravePicker-Unselected")
	else
		_G[targetPair]:SetNormalTexture("Interface\\Addons\\OmegaMap\\Icons\\Clear")
	end

	UIFrameFlashStop(_G[targetPair]:GetNormalTexture())
	OmegaMapTooltip:Hide()
end

--Dropdown menus for note buttons
local menuFrame = CreateFrame("Frame", "OmegaMapClickMenuFrame", UIParent, "UIDropDownMenuTemplate")

--Menu for Defense BG Announcements
function LeftClickMenu(self)

	local noteId = self:GetID()
	local mapData = OMEGAMAP_ALTMAP

	if currentMapNotes[noteId][3] == "note" then
		return 
	elseif currentMapNotes[noteId][3] == "flag" then
		return
	end

local location = _G["OmegaMapPOINote"..noteId.."Title"]:GetText()
	local LeftClickMenu = {
		{ text = "Alerts", isTitle = true, notCheckable  = true},
		{ text = "Zerg Inc "..location, notCheckable  = true, func = function() SendChatMessage("Zerg Inc "..location, "BATTLEGROUND"); end },
		{ text = "1 Inc "..location, notCheckable  = true, func = function() SendChatMessage("1 Inc "..location, "BATTLEGROUND"); end },
		{ text = "2 Inc "..location, notCheckable  = true, func = function() SendChatMessage("2 Inc "..location, "BATTLEGROUND"); end },
		{ text = "3 Inc "..location, notCheckable  = true, func = function() SendChatMessage("3 Inc "..location, "BATTLEGROUND"); end },
		{ text = "4 Inc "..location, notCheckable  = true, func = function() SendChatMessage("4 Inc "..location, "BATTLEGROUND"); end },
		{ text = "5 Inc "..location, notCheckable  = true, func = function() SendChatMessage("5 Inc "..location, "BATTLEGROUND"); end },
		{ text = location.." OK", notCheckable  = true, func = function() SendChatMessage(location.." OK", "BATTLEGROUND"); end }, 
		}
	EasyMenu(LeftClickMenu, menuFrame, "cursor", 10 , 10, "MENU",10)
end

--Menu for Offense BG announcements
function RightClickMenu(self)
	local noteId = self:GetID()
	local mapData = OMEGAMAP_ALTMAP

	local location = _G["OmegaMapPOINote"..noteId.."Title"]:GetText()
	local RightClickMenu = {
		{ text = "Alerts", isTitle = true, notCheckable  = true},
		{ text = "Fall back to "..location, notCheckable  = true, func = function() SendChatMessage("Fall back to "..location , "BATTLEGROUND"); end },
		{ text = "Regroup at "..location, notCheckable  = true, func = function() SendChatMessage("Regroup at "..location , "BATTLEGROUND"); end },
		{ text = "Attack the "..location, notCheckable  = true, func = function() SendChatMessage("Attack the "..location , "BATTLEGROUND"); end },
		{ text = location.." Undefended", notCheckable  = true, func = function() SendChatMessage(location.." Undefended" , "BATTLEGROUND"); end },
		}

	local OurSide, TheirSide 

	if (currentMapNotes[noteId][4]== "H") then
		OurSide = FACTION_HORDE
		TheirSide = FACTION_ALLIANCE
	else
		OurSide = FACTION_ALLIANCE
		TheirSide = FACTION_HORDE
	end

	local CTFMenu = {
		{ text = "Alerts", isTitle = true, notCheckable  = true},
		{ text = "Zerg Inc "..OurSide.." Flag Room", notCheckable  = true, func = function()  SendChatMessage("Zerg Inc "..OurSide.." Flag Room", "BATTLEGROUND"); end },
		{ text = OurSide.." Flag Headed Via Tunnel", notCheckable  = true, func = function()  SendChatMessage(OurSide.." Flag Headed Via Tunnel", "BATTLEGROUND"); end },
		{ text = OurSide.." Flag Headed East", notCheckable  = true, func = function()  SendChatMessage(OurSide.." Flag Headed East", "BATTLEGROUND"); end },
		{ text = OurSide.." Flag Headed West", notCheckable  = true, func = function()  SendChatMessage(OurSide.." Flag Headed West", "BATTLEGROUND"); end },
		{ text = OurSide.." Flag In Middle", notCheckable  = true, func = function()  SendChatMessage(OurSide.." Flag In Middle", "BATTLEGROUND"); end },
		{ text = TheirSide.." Flag at "..OurSide.." Roof", notCheckable  = true, func = function()  SendChatMessage(TheirSide.." Flag at "..OurSide.." Roof", "BATTLEGROUND"); end },
		{ text = TheirSide.." Flag at "..OurSide.." Flag Room", notCheckable  = true, func = function()  SendChatMessage(TheirSide.." Flag at "..OurSide.." Flag Room", "BATTLEGROUND"); end },
		{ text = TheirSide.." Flag at "..OurSide.." GY", notCheckable  = true, func = function()  SendChatMessage(TheirSide.." Flag at "..OurSide.." GY", "BATTLEGROUND"); end },
		}

	if currentMapNotes[noteId][3] == "note" then
		return 
	elseif currentMapNotes[noteId][3] == "flag" then
		EasyMenu(CTFMenu, menuFrame, "cursor", 10 , 10, "MENU",10)
	else
		EasyMenu(RightClickMenu, menuFrame, "cursor", 10 , 10, "MENU",10)
	end
end


--Function to save map position and scale when entering & exiting BGs
function OmegaMap_SetPosition()
	local inBG = UnitInBattleground("player")
	local currentMapInfo = {}
	currentMapInfo.point, currentMapInfo.relativeTo, currentMapInfo.relativePoint, currentMapInfo.xOffset, currentMapInfo.yOffset = OmegaMapMasterFrame:GetPoint(1)

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

	OmegaMapMasterFrame:SetScale(OmegaMapConfig.scale);
	OmegaMapOptionsFrame.ScaleSlider:SetValue(OmegaMapConfig.scale);
	OmegaMapMasterFrame:ClearAllPoints();
	OmegaMapMasterFrame:SetPoint(currentMapInfo.point, UIParent, currentMapInfo.relativePoint, currentMapInfo.xOffset, currentMapInfo.yOffset)
	OmegaMapPosition.LastType  = inBG  --Stores info incase of relogging during a BG
end


