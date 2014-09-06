--	///////////////////////////////////////////////////////////////////////////////////////////

-- Code to display _NPCScan.Overlay POI within OmegaMap
-- This is modified code taken from Modules/OmegaMap.lua from _NPCScan.Overlay (v5.4)
-- _NPCScan.Overlay is written and maintained by the Saiket @ http://www.curse.com/addons/wow/npcscan-overlay

--	///////////////////////////////////////////////////////////////////////////////////////////


if (IsAddOnLoaded("_NPCScan.Overlay")) then

	local ScanVersion = GetAddOnMetadata("_NPCScan.Overlay", "Version");
	if ScanVersion <= "5.0" then




	local Overlay = _NPCScan.Overlay;
	local NS = Overlay.Modules.WorldMapTemplate.Embed( CreateFrame( "Frame","NPCScanOmegaMapOverlay" ) );

	NS.AlphaDefault = 0.8;



	--- Attaches the canvas to OmegaMap's custom frame when it loads.
	function NS:OnLoad ( ... )
		self:SetParent( OmegaMapNoteFrame );

		return self.super.OnLoad( self, ... );
	end


	Overlay.Modules.Register( "OmegaMap", NS, "OmegaMap Addon");
	Overlay.Modules.Enable ( "OmegaMap" )
	_NPCScanOverlayOptions["ModulesAlpha"]["OmegaMap"]= .5
	_NPCScanOverlayModuleOmegaMapAlpha:SetValue(_NPCScanOverlayOptions["ModulesAlpha"]["OmegaMap"])
	_NPCScanOverlayModuleOmegaMapAlpha:Enable()
	_NPCScanOverlayOptions["Modules"]["OmegaMap"] = true
	_NPCScanOverlayModuleOmegaMapEnabled:SetChecked(_NPCScanOverlayOptions["Modules"]["OmegaMap"])

end
	NPCScanOmegaMapOverlay:SetParent(OmegaMapNoteFrame)
	NPCScanOmegaMapOverlay:SetAllPoints(OmegaMapNoteFrame)
print(OMEGAMAP_NPCSCANOVERLAY_LOADED_MESSAGE)
end