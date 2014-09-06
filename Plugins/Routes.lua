--	///////////////////////////////////////////////////////////////////////////////////////////

-- Code for Routes  Integration 
-- Code is a modified version of Routes.lua from Routes (v1.4.2-8-g4b93fad)
-- Routes is written by Xinhuan, & grum @ http://www.wowace.com/addons/routes/

--	///////////////////////////////////////////////////////////////////////////////////////////

if IsAddOnLoaded("Routes") then


--Creating a Frame to display Routes in Omega Map
if not RoutesOmegaMapOverlay then
	local overlay = CreateFrame("Frame", "RoutesOmegaMapOverlay", OmegaMapNoteFrame)
	overlay:SetAllPoints(true)
end

--Maping to phased zones
local remapMapFile = {
	["Uldum_terrain1"] = "Uldum",
	["TwilightHighlands_terrain1"] = "TwilightHighlands",
	["Gilneas_terrain1"] = "Gilneas",
	["Gilneas_terrain2"] = "Gilneas",
	["BattleforGilneas"] = "GilneasCity",
	["TheLostIsles_terrain1"] = "TheLostIsles",
	["TheLostIsles_terrain2"] = "TheLostIsles",
	["Hyjal_terrain1"] = "Hyjal",
}

function OmegaMapDrawWorldmapLines()
if (not (OmegaMapConfig.showRoutes)) then return end
	-- setup locals
	local mapID = GetCurrentMapAreaID()
	local fh, fw = OmegaMapButton:GetHeight(), OmegaMapButton:GetWidth()
	local bfh, bfw  -- BattlefieldMinimap height and width
	local db = RoutesDB.global
	local defaults = db.defaults

	-- clear all the lines
	Routes.G:HideLines(RoutesOmegaMapOverlay)

	-- check for conditions not to draw the world map lines
	if Routes.mapData:GetContinentFromMap(mapID) <= 0 then return end -- player is not viewing a zone map of a continent
	local flag1 = defaults.draw_worldmap and OmegaMapFrame:IsShown() -- Draw worldmap lines?
	if (not flag1) then	return end 	-- Nothing to draw

	local mapFile = GetMapInfo()
	mapFile = remapMapFile[mapFile] or mapFile
	for route_name, route_data in pairs( db.routes[mapFile] ) do
		if type(route_data) == "table" and type(route_data.route) == "table" and #route_data.route > 1 then
			local width = route_data.width or defaults.width
			local color = route_data.color or defaults.color

			if (not route_data.hidden and not route_data.editing and (route_data.visible or not defaults.use_auto_showhide)) or defaults.show_hidden then
				if route_data.hidden then color = defaults.hidden_color end
				local last_point
				local sx, sy
				if route_data.looped then
					last_point = route_data.route[ #route_data.route ]
					sx, sy = floor(last_point / 10000) / 10000, (last_point % 10000) / 10000
					sy = (1 - sy)
				end
				for i = 1, #route_data.route do
					local point = route_data.route[i]
					if point == defaults.fake_point then
						point = nil
					end
					if last_point and point then
						local ex, ey = floor(point / 10000) / 10000, (point % 10000) / 10000
						ey = (1 - ey)
						if (flag1) then
							Routes.G:DrawLine(RoutesOmegaMapOverlay, sx*fw, sy*fh, ex*fw, ey*fh, width, color , "OVERLAY")
						end
						sx, sy = ex, ey
					end
					last_point = point
				end
			end
		end
	end
end

hooksecurefunc(Routes,"DrawWorldmapLines", OmegaMapDrawWorldmapLines)

print(OMEGAMAP_ROUTES_LOADED_MESSAGE)

end