--	///////////////////////////////////////////////////////////////////////////////////////////

-- Code for TomTom  Integration 
-- Code is a modified version of TomTom_Waypoints.lua from TomTom (v60200-2.1.0)
-- TomTom is written by Cladhaire @ http://wow.curseforge.com/addons/tomtom/

--	///////////////////////////////////////////////////////////////////////////////////////////

if IsAddOnLoaded("TomTom") then


local L = TomTomLocals
local hbdp = LibStub("HereBeDragons-Pins-2.0")


-- Create a local table used as a frame pool
local pool = {}
local all_points = {}
local waypointMap = {}


-- Hook the WorldMap OnClick
local world_click_verify = {
    ["A"] = function() return IsAltKeyDown() end,
    ["C"] = function() return IsControlKeyDown() end,
    ["S"] = function() return IsShiftKeyDown() end,
}


--Overwrites the OnClick for the OmegaMapButton
function OM_MapCanvasScrollControllerMixin:OnMouseUp(button)
	local cursorX, cursorY = self:GetCursorPosition();
	local isClick = self:WouldCursorPositionBeClick(button, cursorX, cursorY);

	if button == "LeftButton" then
		if isClick then
			if not self:GetMap():ProcessCanvasClickHandlers(button, self:NormalizeUIPosition(cursorX, cursorY)) then
				if self:ShouldNavigateOnClick() then
					self:GetMap():NavigateToCursor(self:GetNormalizedCursorPosition());
				elseif self:ShouldZoomInOnClick() then
					self:TryPanOrZoomOnClick();
				end
			end
		elseif not self:TryPanOrZoomOnClick() and self:IsPanning() then		
			local deltaX, deltaY = self:GetNormalizedMouseDelta(button);
			self:AccumulateMouseDeltas(GetTickTime(), deltaX, deltaY);

			self.targetScrollX = Clamp(self.targetScrollX + self.accumulatedMouseDeltaX, self.scrollXExtentsMin, self.scrollXExtentsMax);
			self.targetScrollY = Clamp(self.targetScrollY + self.accumulatedMouseDeltaY, self.scrollYExtentsMin, self.scrollYExtentsMax);
		end

	elseif button == "RightButton" then

	local TTmod = false
		for mod in TomTom.db.profile.worldmap.create_modifier:gmatch("[ACS]") do
			if not world_click_verify[mod] or not world_click_verify[mod]() then
				TTmod = false
			else
				TTmod = true
			end
		end

		if TTmod then 
			local m = OmegaMapFrame.mapID
			local x,y = OmegaMapFrame:GetNormalizedCursorPosition()

			if not m or m == 0 then
			    return false
			end

			local uid = TomTom:AddWaypoint(m, x, y, { title = L["TomTom waypoint"],})
			TomTom:ReloadWaypoints()
			return true
		end

		if isClick and not self:GetMap():ProcessCanvasClickHandlers(button, self:NormalizeUIPosition(cursorX, cursorY)) then
			if self:IsMouseOver() then
				if self:ShouldNavigateOnClick() then
					self:GetMap():NavigateToParentMap();
				elseif self:ShouldZoomInOnClick() then
					self:ZoomOut();
				end
			end
		end
	end
	local mouseButtonInfo = self.mouseButtonInfo[button];
	if mouseButtonInfo then
		mouseButtonInfo.down = false;
	end
end

OmegaMapFrame.ScrollContainer:SetScript("OnMouseUp", OM_MapCanvasScrollControllerMixin.OnMouseUp)

--print(OMEGAMAP_TOMTOM_LOADED_MESSAGE)
end
