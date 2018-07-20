--	///////////////////////////////////////////////////////////////////////////////////////////

-- This code allows the integration of the GatherMate2 addon into Omegamap 
-- Code is a modified version of Display.lua from GatherMate2 (v1.35.4)
-- GatherMate2 is written by the kagaro, Nevcairiel, & Xinhuan @ http://www.wowace.com/addons/gathermate2/

--	///////////////////////////////////////////////////////////////////////////////////////////

if IsAddOnLoaded("GatherMate2") then

local OmegaMap = select(2, ...)
OmegaMap = LibStub("AceAddon-3.0"):GetAddon("OmegaMap")
--Creating Frame in OmegaMap to display the GatherMate2 icons
if not GatherMateOmegaMapOverlay then
	local overlay = CreateFrame("Frame", "GatherMateOmegaMapOverlay", OmegaMapNoteFrame)
	overlay:SetAllPoints(true)
end

local GatherMate = LibStub("AceAddon-3.0"):GetAddon("GatherMate2")
local Display = GatherMate:GetModule("Display","AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("GatherMate2")
local OMpincount = 0

Display.OmegaMapDataProvider = CreateFromMixins(Display.WorldMapDataProvider)
OmegaMap.Plugins["showGatherMate"] = Display.OmegaMapDataProvider
	
	
	
	--OmegaMapFrame:AddDataProvider(Display.OmegaMapDataProvider)


-- Disable the mod
function Display:OnDisable()
	self:UnregisterMapEvents()
	self:UnregisterEvent("SKILL_LINES_CHANGED")
	self:UnregisterEvent("MINIMAP_UPDATE_TRACKING")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	GatherMate.HBD.UnregisterCallback(self, "PlayerZoneChanged")
	WorldMapFrame:RemoveDataProvider(Display.WorldMapDataProvider)
	OmegaMapFrame:RemoveDataProvider(Display.OmegaMapDataProvider)
end

function Display:UpdateWorldMap()
	self.WorldMapDataProvider:RefreshAllData()
	--self.OmegaMapDataProvider:RefreshAllData()
end


end