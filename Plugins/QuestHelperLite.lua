--	///////////////////////////////////////////////////////////////////////////////////////////

-- Code for QuestHelper Light  Integration 
-- Code is a modified version of Version 5.3.00
-- QuestHelper Light   is written by WakeZero	@ http://www.curse.com/addons/wow/questhelperlite

--	///////////////////////////////////////////////////////////////////////////////////////////

if IsAddOnLoaded("QuestHelperLite") then


function OmegaMap_QHL_OnShow()
if QuestHelperLite_MapOverlayFrame then
	QuestHelperLite_MapOverlayFrame:SetParent(QHLOmegaMapOverlay)
	QuestHelperLite_MapOverlayFrame:SetAllPoints(QHLOmegaMapOverlay)
	end
end

function OmegaMap_QHL_OnHide()
if QuestHelperLite_MapOverlayFrame then

	QuestHelperLite_MapOverlayFrame:SetParent(WorldMapButton)
	QuestHelperLite_MapOverlayFrame:SetAllPoints(WorldMapButton)
	end
end

if not QHLOmegaMapOverlay then
	local overlay = CreateFrame("Frame", "QHLOmegaMapOverlay", OmegaMapNoteFrame)
	overlay:SetAllPoints(true)
	overlay:SetScript("OnShow", OmegaMap_QHL_OnShow)
	overlay:SetScript("OnHide", OmegaMap_QHL_OnHide)
end


--Overwrites the QuestHelperLight function to show tooltips on OmegaMap
function POI_OnEnter(self)
	WorldMapPOIFrame.allowBlobTooltip = false;
	OmegaMapPOIFrame.allowBlobTooltip = false;
	local quest = QHL.quests:GetQuest(self.questId);
	if quest then 
		if OmegaMapFrame:IsShown() then
			OmegaMapQuestPOI_SetTooltip(self, quest.questLogIndex);
		else
			WorldMapQuestPOI_SetTooltip(self, quest.questLogIndex);
		end
	end

end


--Overwrites the QuestHelperLight function to hide the displayed tooltips properly
function POI_OnLeave(self)
		OmegaMapPOIFrame.allowBlobTooltip = false;
		WorldMapPOIFrame.allowBlobTooltip = true;
				if OmegaMapFrame:IsShown() then
			OmegaMapTooltip:Hide();
		else
			WorldMapTooltip:Hide();
		end
end

--[[
OmegaMapFrame:HookScript("OnShow", function(self, button)
        QHL.Astrolabe.WorldMapVisible = true
    end)

OmegaMapFrame:HookScript("OnHide", function(self, button)
        QHL.Astrolabe.WorldMapVisible = false
    end)
]]--

--Will only load if the TomTom addon is loaded
local AstrolabeMapMonitor = DongleStub("AstrolabeMapMonitor");
--AstrolabeMapMonitor:RegisterAstrolabeLibrary(Astrolabe, LIBRARY_VERSION_MAJOR);
AstrolabeMapMonitor:MonitorWorldMap( OmegaMapFrame )

print(OMEGAMAP_QUESTHELPERLITE_LOADED_MESSAGE)

end

