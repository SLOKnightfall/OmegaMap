--	///////////////////////////////////////////////////////////////////////////////////////////

-- Code for Gatherer Integration within OmegaMap
-- Code is a modified version of GatherMapNotes.lua from Gatherer (v4.4.0)
-- Gatherer is written and maintained by the folks @ http://www.gathereraddon.com/

--	///////////////////////////////////////////////////////////////////////////////////////////


if IsAddOnLoaded("Gatherer") then

--Creating a Frame to display Gatherer nodes in Omega Map
if not GathererOmegaMapOverlayParent then
	local overlay = CreateFrame("Frame", "GathererOmegaMapOverlayParent", OmegaMapNoteFrame)
	overlay:SetAllPoints(true)
end


local Astrolabe = DongleStub(Gatherer.AstrolabeVersion)
local _tr = Gatherer.Locale.Tr
local _trC = Gatherer.Locale.TrClient
local _trL= Gatherer.Locale.TrLocale
local UpdateWorldMap = -1

local AstrolabeMapMonitor = DongleStub("AstrolabeMapMonitor");
--AstrolabeMapMonitor:RegisterAstrolabeLibrary(Astrolabe, LIBRARY_VERSION_MAJOR);
AstrolabeMapMonitor:MonitorWorldMap( OmegaMapFrame )

function OmegaMap_DrawGathererPOI()
local GathererMapOverlayParent = GathererOmegaMapOverlayParent
	local setting = Gatherer.Config.GetSetting
	local maxNotes = setting("mainmap.count", 600)
	local noteCount = 0

	local h, w = GathererOmegaMapOverlayParent:GetHeight(), GathererOmegaMapOverlayParent:GetWidth();

	-- prevent the function from running twice at the same time.
	if (Gatherer.Var.UpdateWorldMap == 0 ) then return; end
	Gatherer.Var.UpdateWorldMap = 0

	local GetNodeInfo = Gatherer.Storage.GetNodeInfo
	local GetNodeGatherNames = Gatherer.Storage.GetNodeGatherNames
	
	
	local showType, showObject
	local mapID, mapFloor = Gatherer.ZoneTokens.GetZoneMapIDAndFloor(Gatherer.ZoneTokens.GetZoneToken(GetCurrentMapAreaID()))
	if ( Gatherer.Storage.HasDataOnZone(mapID) ) then
		for _, gatherType in pairs(Gatherer.Constants.SupportedGatherTypes) do
			for index, xPos, yPos in Gatherer.Storage.ZoneGatherNodes(mapID, gatherType) do
				local displayNode = false
				for _, gatherID, count in GetNodeGatherNames(mapID, gatherType, index) do
					if ( Gatherer.Config.DisplayFilter_MainMap(gatherID) ) then
						displayNode = true
						break
					end
				end
				local _, _, _, isMicroDungeon = GetMapInfo();
				if ( displayNode and isMicroDungeon ) then
					local _, _, indoors = GetNodeInfo(mapID, gatherType, index)
					displayNode = indoors
				end
				if ( displayNode ) then
					if ( noteCount < maxNotes ) then
						noteCount = noteCount + 1
		local mainNote = OmegaMap_CreateGathererPOI(noteCount)

						--xPos = xPos * w;
						--yPos = yPos * h;
						mainNote:ClearAllPoints();
						--mainNote:SetPoint("CENTER", "GathererOmegaMapOverlayParent", "TOPLEFT", xPos, -yPos);
						
						mainNote:SetAlpha(setting("mainmap.opacity", 80) / 100)
						--mainNote:Show()
						local texture = Gatherer.Util.GetNodeTexture(mapID, gatherType, index)
						_G[mainNote:GetName().."Texture"]:SetTexture(texture)

						
						local iconsize = setting("mainmap.iconsize", 16)
						mainNote:SetWidth(iconsize)
						mainNote:SetHeight(iconsize)
						
						mainNote.mapID = mapID
						mainNote.index = index
						mainNote.gType = gatherType
						
						local tooltip = setting("mainmap.tooltip.enable")
						if (tooltip and not mainNote:IsMouseEnabled()) then
							mainNote:EnableMouse(true)
						elseif (not tooltip and mainNote:IsMouseEnabled()) then
							mainNote:EnableMouse(false)
						end
						
						Astrolabe:PlaceIconOnWorldMap(OmegaMapButton, mainNote, mapID, mapFloor, xPos, yPos)
					else -- reached note limit
						break
					end
				end
			end
		end
	end
	local numUsedOverlays = math.ceil(noteCount / 100)
	local partialOverlay = GathererMapOverlayParent[numUsedOverlays]
	for i = (noteCount - ((numUsedOverlays - 1) * 100) + 1), 100 do
		local note = partialOverlay[i]
		if not ( note ) then
			break
		end
		note:Hide()
	end
	for i, overlay in ipairs(GathererMapOverlayParent) do
		if ( i <= numUsedOverlays ) then
			overlay:Show()
		else
			overlay:Hide()
		end
	end
	
	Gatherer.Var.UpdateWorldMap = -1
end


function OmegaMap_CreateGathererPOI( noteNumber )
local GathererMapOverlayParent = GathererOmegaMapOverlayParent
	
	local button = _G["OmegaMapGatherMain"..noteNumber]
	if not ( button ) then
		local overlayFrameNumber = math.ceil(noteNumber / 100)
		local overlayFrame = GathererMapOverlayParent[overlayFrameNumber]
		if not ( overlayFrame ) then
			overlayFrame = CreateFrame("Frame", "GathererOmegaMapOverlayParentFrame"..overlayFrameNumber, GathererOmegaMapOverlayParent, "GathererMapOverlayTemplate")
			GathererMapOverlayParent[overlayFrameNumber] = overlayFrame
		end
		button = CreateFrame("Button" ,"OmegaMapGatherMain"..noteNumber, overlayFrame, "GatherMainTemplate")
		button:SetID(noteNumber)
		overlayFrame[(noteNumber-1) % 100 + 1] = button
		button:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL);
		button:SetScript("OnEnter", OmegaMap_GathererOnEnter)
		--Gatherer.Util.Debug("create id "..noteNumber.." frame ".. overlayFrameNumber)
	end
	return button
end

function OmegaMap_GathererOnEnter(frame)
	local setting = Gatherer.Config.GetSetting
	
	local enabled = setting("mainmap.tooltip.enable")
	if (not enabled) then 
		return
	end
	
	local showcount = setting("mainmap.tooltip.count")
	local showsource = setting("mainmap.tooltip.source")
	local showseen = setting("mainmap.tooltip.seen")
	local showrate = setting("mainmap.tooltip.rate")
	
	local cont = frame.continent
	local zone = Gatherer.ZoneTokens.GetZoneToken(frame.mapID)
	local index = frame.index
	local gType = frame.gType
	local inspected = Gatherer.Storage.GetNodeInspected(zone, gType, index)
	
	local numTooltips = 0
	for id, gatherID, count, harvested, who in Gatherer.Storage.GetNodeGatherNames(zone, gType, index) do
		local tooltip = Gatherer.Tooltip.GetTooltip(id)
		tooltip:ClearLines()
		tooltip:SetParent(OmegaMapFrame)
		tooltip:SetFrameLevel(OMEGAMAP_POI_FRAMELEVEL + 5)
		if ( id == 1 ) then
			tooltip:SetOwner(frame, "ANCHOR_BOTTOMLEFT")
		else
			tooltip:SetOwner(frame, "ANCHOR_PRESERVE")
			tooltip:SetPoint("TOPLEFT", Gatherer.Tooltip.GetTooltip(id - 1),"BOTTOMLEFT")
		end
		
		local name = Gatherer.Util.GetNodeName(gatherID)
		local last = inspected or harvested
		
		tooltip:AddLine(name)
		if (count > 0 and showcount) then
			tooltip:AddLine(_tr("NOTE_COUNT", count))
		end
		if (who and showsource) then
			if (who == "REQUIRE") then
				tooltip:AddLine(_tr("NOTE_UNSKILLED"))
			elseif (who == "IMPORTED") then
				tooltip:AddLine(_tr("NOTE_IMPORTED"))
			else
				tooltip:AddLine(_tr("NOTE_SOURCE", who:gsub(",", ", ")))
			end
		end
		if (last and last > 0 and showseen) then
			tooltip:AddLine(_tr("NOTE_LASTVISITED", Gatherer.Util.SecondsToTime(time()-last)))
		end
		
		if ( showrate ) then
			local num = Gatherer.Config.GetSetting("mainmap.tooltip.rate.num")
			if ( gType ~= "OPEN" and gatherID ~= 190175 ) then
				zone = nil
			end
			Gatherer.Tooltip.AddDropRates(tooltip, gatherID, zone, num)
		end
		tooltip:Show()
		numTooltips = id
	end
	Gatherer.Tooltip.SetClamps(numTooltips)
end


print(OMEGAMAP_GATHERER_LOADED_MESSAGE)
end