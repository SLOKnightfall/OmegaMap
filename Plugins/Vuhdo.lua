--	///////////////////////////////////////////////////////////////////////////////////////////

-- Code to stop Vuhdo from reseting the world map back to the current zone when OmegaMap is shown

--	///////////////////////////////////////////////////////////////////////////////////////////


if (IsAddOnLoaded("Vuhdo")) then
local tNextTime = 0;
	function VUHDO_setMapToCurrentZone()
		if not OmegaMapFrame:IsShown() then
			if tNextTime < GetTime() then
				SetMapToCurrentZone();
				tNextTime = GetTime() + 2;
			end
		end
	end
end