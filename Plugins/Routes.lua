--	///////////////////////////////////////////////////////////////////////////////////////////

-- Code for Routes  Integration 
-- Code is a modified version of Routes.lua from Routes (v1.5.2b)
-- Routes is written by Xinhuan, & grum @ http://www.wowace.com/addons/routes/

--	///////////////////////////////////////////////////////////////////////////////////////////

if IsAddOnLoaded("Routes") then

local OmegaMap = select(2, ...)
OmegaMap = LibStub("AceAddon-3.0"):GetAddon("OmegaMap")
local Routes = LibStub("AceAddon-3.0"):GetAddon("Routes")

--Creating a Frame to display Routes in Omega Map
if not RoutesOmegaMapOverlay then
	local overlay = CreateFrame("Frame", "RoutesOmegaMapOverlay", OmegaMapNoteFrame)
	overlay:SetAllPoints(true)
end

local DataProvider 

local function RoutesMixins(provider)
	DataProvider = CreateFromMixins(provider)
	OmegaMap.Plugins["showRoutes"] = DataProvider
	--OmegaMapFrame:AddDataProvider(DataProvider)

	function DataProvider:OnRemoved(mapCanvas)
	--MapCanvasDataProviderMixin.OnRemoved(self, mapCanvas);
	--self:GetMap():RemoveAllPinsByTemplate("RoutesPinTemplate");
	--self:GetMap():RemoveAllPinsByTemplate("RoutesTabooPinTemplate");


end

function DataProvider:UpdateWorldMap()
	DataProvider:RefreshAllData()
end
end




hooksecurefunc(Routes, "OnEnable", function(...) 
	RoutesMixins(Routes.DataProvider); end)


--print(OMEGAMAP_ROUTES_LOADED_MESSAGE)

end