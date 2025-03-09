--	///////////////////////////////////////////////////////////////////////////////////////////

-- Code to display CTMapMod POI within OmegaMap
-- This is modified code taken from CT_ MapMod.lua from CT_MapMod (v6.0.3.0)
-- CTMapMod is written and maintained by the CT_Mod crew @ http://www.ctmod.net/

--	///////////////////////////////////////////////////////////////////////////////////////////

if not C_AddOns.IsAddOnLoaded("CT_MapMod") then return end

local OmegaMap = select(2, ...)
OmegaMap = LibStub("AceAddon-3.0"):GetAddon("OmegaMap")

local _G = getfenv(0);
local MODULE_NAME = "CT_MapMod";
local module =_G[MODULE_NAME]

OM_CT_MapMod_DataProviderMixin = CreateFromMixins(CT_MapMod_DataProviderMixin);

function OM_CT_MapMod_DataProviderMixin:RemoveAllData()
	self:GetMap():RemoveAllPinsByTemplate("OM_CT_MapMod_PinTemplate");
end
 

function OM_CT_MapMod_DataProviderMixin:RefreshAllData(fromOnShow)
	-- Clear the map
	self:RemoveAllData();
	module.PinHasFocus = nil;  --rather than calling this for each pin, just call it once when all pins are gone.
	
	-- determine what types of notes to show
	local prof1, prof2 = GetProfessions();
	local name, icon, skillLevel, maxSkillLevel, numAbilities, spellOffset, skillLine, skillModifier, specializationIndex, specializationOffset;
	if (prof1) then 
		name, icon, skillLevel, maxSkillLevel, numAbilities, spellOffset, skillLine, skillModifier, specializationIndex, specializationOffset = GetProfessionInfo(prof1)
		if (icon == 136246) then 
			module.isHerbalist = true;
		elseif (icon == 134708) then 
			module.isMiner = true; 
		end
	end
	if (prof2) then 
		name, icon, skillLevel, maxSkillLevel, numAbilities, spellOffset, skillLine, skillModifier, specializationIndex, specializationOffset = GetProfessionInfo(prof2)
		if (icon == 136246) then 
			module.isHerbalist = true;
		elseif (icon == 134708) then 
			module.isMiner = true;
		end
	end

	-- Fetch and push the pins to be used for this map
	local mapid = self:GetMap():GetMapID();
	if (mapid and CT_MapMod_Notes[mapid]) then
		for i, info in ipairs(CT_MapMod_Notes[mapid]) do
			if (
				-- if user is set to always (the default)
				( (info["set"] == "User") and ((module:getOption("CT_MapMod_UserNoteDisplay") or 1) == 1) ) or
				
				-- if herb is set to always, or if herb is set to auto (the default) and the toon is an herbalist
				( (info["set"] == "Herb") and ((module:getOption("CT_MapMod_HerbNoteDisplay") or 1) == 1) and (module.isHerbalist) ) or
				( (info["set"] == "Herb") and ((module:getOption("CT_MapMod_HerbNoteDisplay") or 1) == 2) ) or
				
				-- if ore is set to always, or if ore is set to auto (the default) and the toon is a miner
				( (info["set"] == "Ore") and ((module:getOption("CT_MapMod_HerbNoteDisplay") or 1) == 1) and (module.isMiner) ) or
				( (info["set"] == "Ore") and ((module:getOption("CT_MapMod_OreNoteDisplay") or 1) == 2) )
			) then
				self:GetMap():AcquirePin("OM_CT_MapMod_PinTemplate", mapid, i, info["x"], info["y"], info["name"], info["descript"], info["set"], info["subset"], info["datemodified"], info["version"]);
			end
		end
	end
end


--OmegaMapFrame:AddDataProvider(CreateFromMixins(OM_CT_MapMod_DataProviderMixin));
OM_CT_MapMod_PinMixin = CreateFromMixins(CT_MapMod_PinMixin);
OmegaMap.Plugins["showCTMap"] = OM_CT_MapMod_DataProviderMixin


function OM_CT_MapMod_PinMixin:OnClick(button)
	-- Override in your mixin, called when this pin is clicked

	-- create the notepanel if it hasn't been done already.   This is deferred from onload
	if (not self.notepanel) then
		self:CreateNotePanel();  -- happens only once
		self:UpdateNotePanel();  -- happens every time the pin is acquired
	end
	self.notepanel:SetParent(OmegaMapFrame)
	self.notepanel:ClearAllPoints();
	self.notepanel:SetPoint("Center", OmegaMapFrame, "Center")
	self.notepanel:SetFrameLevel( OmegaMapFrame:GetFrameLevel() +  100);

	if (module.PinHasFocus) then return; end

	if (IsShiftKeyDown()) then
		module.PinHasFocus = self;
		self.notepanel:Show();
	end
end

--print(OMEGAMAP_CTMAP_LOADED_MESSAGE)