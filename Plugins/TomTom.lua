--	///////////////////////////////////////////////////////////////////////////////////////////

-- Code for TomTom  Integration 
-- Code is a modified version of TomTom_Waypoints.lua from TomTom (v50400-1.0.0)
-- TomTom is written by Cladhaire @ http://wow.curseforge.com/addons/tomtom/

--	///////////////////////////////////////////////////////////////////////////////////////////

if IsAddOnLoaded("TomTom") then
local firstDisplay = true
local LastWay = nil

--Will only load if the TomTom addon is loaded
local AstrolabeMapMonitor = DongleStub("AstrolabeMapMonitor");
--AstrolabeMapMonitor:RegisterAstrolabeLibrary(Astrolabe, LIBRARY_VERSION_MAJOR);
AstrolabeMapMonitor:MonitorWorldMap( OmegaMapFrame )


function OmegaMap_DrawTomToms()
end

function OmegaMap_TomTom_OnShow()
if TomTomMapOverlay then
	TomTomMapOverlay:SetParent(TomTomOmegaMapOverlay)
	TomTomMapOverlay:SetAllPoints(TomTomOmegaMapOverlay)
	TomTomTooltip:SetFrameLevel(TomTomOmegaMapOverlay:GetFrameLevel() + 50)
	TomTomTooltip:SetFrameStrata("TOOLTIP")
	end
end

function OmegaMap_TomTom_OnHide()
if TomTomMapOverlay then
	TomTomMapOverlay:SetParent(WorldMapButton)
	TomTomMapOverlay:SetAllPoints(WorldMapButton)
	end
end

if not TomTomOmegaMapOverlay then
	local overlay = CreateFrame("Frame", "TomTomOmegaMapOverlay", OmegaMapNoteFrame)
	overlay:SetAllPoints(true)
	overlay:SetScript("OnShow", OmegaMap_TomTom_OnShow)
	overlay:SetScript("OnHide", OmegaMap_TomTom_OnHide)
end

--Modified 
-- Hook the WorldMap OnClick WorldMapButton_OnClick hook from TomTom.Lua

local world_click_verify = {
	["A"] = function() return IsAltKeyDown() end,
	["C"] = function() return IsControlKeyDown() end,
	["S"] = function() return IsShiftKeyDown() end,
}

local origScript = OmegaMapButton_OnClick   -- Hook for Checking Clicks to add buttons to Omega Map

local waypointMap = {}
local pool = {}
local astrolabe = DongleStub("Astrolabe-1.0")
local all_points = {}



-- Local declarations
local Minimap_OnEnter,Minimap_OnLeave,Minimap_OnUpdate,Minimap_OnClick,Minimap_OnEvent
local Arrow_OnUpdate
local World_OnEnter,World_OnLeave,World_OnClick,World_OnEvent

local square_half = math.sqrt(0.5)
local rad_135 = math.rad(135)

--Overwrites the OnClick for the OmegaMapButton
local origScript = OmegaMapButton_OnClick
OmegaMapButton_OnClick = function(self, ...)
	local mouseButton, button = ...
	if mouseButton == "RightButton" then
	-- Check for all the modifiers that are currently set
		for mod in TomTom.db.profile.worldmap.create_modifier:gmatch("[ACS]") do
			if not world_click_verify[mod] or not world_click_verify[mod]() then
				return origScript and origScript(self, ...) or true
			end
		end

		local m,f = GetCurrentMapAreaID()
		local x,y = OmegaMapGetCLoc(OmegaMapFrame)

		if not m then
			return origScript and origScript(self, ...) or true
		end

		local uid = TomTom:AddMFWaypoint(m,f,x/100,y/100)
	else
		return origScript and origScript(self, ...) or true
	end
end

if OmegaMapButton:GetScript("OnMouseUp") == origScript then
	OmegaMapButton:SetScript("OnMouseUp", OmegaMapButton_OnClick)
end
--[[
--Fix to stop TomTom from changing the map
local throttle = 0.25
local counter = 0
local function TomTomFix(self, elapsed)
        counter = counter + elapsed
        if counter >= throttle then
            counter = counter - throttle
            if (not WorldMapFrame:IsVisible() and not WorldMapFrame:IsShown()  )and
		  (not OmegaMapFrame:IsVisible() and not OmegaMapFrame:IsShown() ) then
                local x, y = GetPlayerMapPosition("player")
                if x <= 0 or y <= 0 then
                    -- Flip the map, do not flip it back
                    SetMapToCurrentZone()
                end
            end
        end
end
;
TomTomMapFlipFixFrame:SetScript("OnUpdate",TomTomFix)
]]--
print(OMEGAMAP_TOMTOM_LOADED_MESSAGE)
end
