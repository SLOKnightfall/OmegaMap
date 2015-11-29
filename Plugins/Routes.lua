--	///////////////////////////////////////////////////////////////////////////////////////////

-- Code for Routes  Integration 
-- Code is a modified version of Routes.lua from Routes (v1.5.2b)
-- Routes is written by Xinhuan, & grum @ http://www.wowace.com/addons/routes/

--	///////////////////////////////////////////////////////////////////////////////////////////

if IsAddOnLoaded("Routes") then


--Creating a Frame to display Routes in Omega Map
if not RoutesOmegaMapOverlay then
	local overlay = CreateFrame("Frame", "RoutesOmegaMapOverlay", OmegaMapNoteFrame)
	overlay:SetAllPoints(true)
end

-- Remap mapfiles internally due to phasing
local remapMapFile = {
	["Uldum_terrain1"] = "Uldum",
	["TwilightHighlands_terrain1"] = "TwilightHighlands",
	["Gilneas_terrain1"] = "Gilneas",
	["Gilneas_terrain2"] = "Gilneas",
	["BattleforGilneas"] = "GilneasCity",
	["TheLostIsles_terrain1"] = "TheLostIsles",
	["TheLostIsles_terrain2"] = "TheLostIsles",
	["Hyjal_terrain1"] = "Hyjal",
	["Krasarang_terrain1"] = "Krasarang",
}
local remapMapID = {
	[748] = 720,  --["Uldum_terrain1"] = "Uldum",
	[770] = 700,  --["TwilightHighlands_terrain1"] = "TwilightHighlands",
	[678] = 545,  --["Gilneas_terrain1"] = "Gilneas",
	[679] = 545,  --["Gilneas_terrain2"] = "Gilneas",
	[677] = 611,  --["BattleforGilneas"] = "GilneasCity",
	[681] = 544,  --["TheLostIsles_terrain1"] = "TheLostIsles",
	[682] = 544,  --["TheLostIsles_terrain2"] = "TheLostIsles",
	[683] = 606,  --["Hyjal_terrain1"] = "Hyjal",
	[910] = 857,  --["Krasarang_terrain1"] = "Krasarang",
}

-- Use local remapped versions of these 2 functions
local RealGetMapInfo = GetMapInfo
local GetMapInfo = function()
	local mapFile, x, y = RealGetMapInfo()
	return remapMapFile[mapFile] or mapFile, x, y
end

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
	if GetCurrentMapContinent() <= 0 then return end -- player is not viewing a zone map of a continent
	local flag1 = defaults.draw_worldmap and OmegaMapFrame:IsShown() -- Draw worldmap lines?
	if (not flag1) and (not flag2) then	return end 	-- Nothing to draw

local mapFile = GetMapInfo()
	-- microdungeon check
	local mapName, textureWidth, textureHeight, isMicroDungeon, microDungeonName = RealGetMapInfo()
	if isMicroDungeon then
		if not OmegaMapFrame:IsShown() then
			-- return to the main map of this zone
			ZoomOut()
		else
			-- can't do anything while in a micro dungeon and the main map is visible
			return
		end
	end --end check


	for route_name, route_data in pairs( db.routes[mapFile] ) do
		if type(route_data) == "table" and type(route_data.route) == "table" and #route_data.route > 1 then
			local width = route_data.width or defaults.width
			local halfwidth = route_data.width_battlemap or defaults.width_battlemap
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