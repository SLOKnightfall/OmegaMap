--	///////////////////////////////////////////////////////////////////////////////////////////

-- Code for Routes  Integration 
-- Code is a modified version of Routes.lua from Routes (v1.5.2b)
-- Routes is written by Xinhuan, & grum @ http://www.wowace.com/addons/routes/

--	///////////////////////////////////////////////////////////////////////////////////////////

if IsAddOnLoaded("Routes") then

local Routes = LibStub("AceAddon-3.0"):GetAddon("Routes")

--Creating a Frame to display Routes in Omega Map
if not RoutesOmegaMapOverlay then
	local overlay = CreateFrame("Frame", "RoutesOmegaMapOverlay", OmegaMapNoteFrame)
	overlay:SetAllPoints(true)
end


local function RoutesMixins(provider)
	local DataProvider = CreateFromMixins(provider)		
	OmegaMapFrame:AddDataProvider(DataProvider)
end


hooksecurefunc(Routes, "OnEnable", function(...) 
	RoutesMixins(Routes.DataProvider); end)


--print(OMEGAMAP_ROUTES_LOADED_MESSAGE)

end