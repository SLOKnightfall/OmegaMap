
function OmegaMapFrame_IsCosmicMap()
	return GetCurrentMapContinent() == WORLDMAP_COSMIC_ID and GetCurrentMapAreaID() == WORLDMAP_COSMIC_MAP_AREA_ID;
end

function OmegaMapFrame_IsMaelstromContinentMap()
	return GetCurrentMapContinent() == WORLDMAP_MAELSTROM_ID and GetCurrentMapZone() == 0;
end

function OmegaMapFrame_IsArgusContinentMap()
	return GetCurrentMapContinent() == WORLDMAP_ARGUS_ID and GetCurrentMapZone() == 0;
end

function OmegaMapFrame_IsBrokenIslesContinentMap()
	return GetCurrentMapContinent() == WORLDMAP_BROKEN_ISLES_ID and GetCurrentMapZone() == 0;
end


local CosmicStyleButtons = {
	{ -- Cosmic map
		Buttons = {
			OmegaMapOutlandButton,
			OmegaMapAzerothButton,
			OmegaMapDraenorButton,
		},
		
		Predicate = OmegaMapFrame_IsCosmicMap,
	},
	
	{ -- Maelstrom
		Buttons = {
			OmegaMapDeepholmButton,
			OmegaMapKezanButton,
			OmegaMapLostIslesButton,
			OmegaMapTheMaelstromButton,
		},
		
		Predicate = OmegaMapFrame_IsMaelstromContinentMap,
	},	
	
	{ -- Broken Isles (Argus button)
		Buttons = {
			OmegaMapBrokenIslesArgusButton,
		},
		
		Predicate = OmegaMapFrame_IsBrokenIslesContinentMap,
	},
	
	{ -- Argus continent map
		Buttons = {
			OmegaMapKrokuunButton,
			OmegaMapMacAreeButton,
			OmegaMapAntoranWastesButton,
		},
		
		Predicate = OmegaMapFrame_IsArgusContinentMap,
	},
};
	
function OmegaMapFrame_UpdateCosmicButtons()
	for i, cosmicGroup in ipairs(CosmicStyleButtons) do
		local shouldShow = cosmicGroup.Predicate();
		for j, cosmicButton in ipairs(cosmicGroup.Buttons) do
			cosmicButton:SetShown(shouldShow);
		end
	end
end