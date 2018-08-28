--	///////////////////////////////////////////////////////////////////////////////////////////

-- Code to display PetTracer POI within OmegaMap
-- This is modified code taken from Features/WorldMap.lua from PetTracker (V 6.0.3)
-- PetTracker is written by Jaliborc at http://www.curse.com/addons/wow/pettracker

--	///////////////////////////////////////////////////////////////////////////////////////////

if not IsAddOnLoaded("PetTracker") then return end
--print(OMEGAMAP_PETTRACKER_LOADED_MESSAGE)

local OmegaMap = select(2, ...)
OmegaMap = LibStub("AceAddon-3.0"):GetAddon("OmegaMap")
local Config = OmegaMap.Config

local ADDON, Addon = "PetTracker", _G["PetTracker"]
local MapFilter = Addon.MapFilter
local MapCanvas = Addon.MapCanvas
local L = Addon.Locals

OmegaMap.Plugins["showPetTracker"] = true


function OmegaMap:PetTrackerUpdate()
	MapCanvas:TrackingChanged()
end


function OmegaMap:PetTrackerDraw(...)
	if OmegaMapFrame:IsShown() and (not OmegaMap.Config.showPetTracker or not OmegaMap.Plugins["showPetTracker"] )then
		return
	else
		OmegaMap.hooks[MapCanvas].Draw(...)

	end
end

OmegaMap:RawHook(MapCanvas,"Draw", "PetTrackerDraw")



function MapFilter:Init(frame)
  if self.frames[frame] then
    return
  else
    self.frames[frame] = 1
  end

  for i, overlay in ipairs(frame.overlayFrames or {}) do
    if overlay.OnClick == WorldMapTrackingOptionsButtonMixin.OnClick or overlay.OnClick == OmegaMapTrackingOptionsButtonMixin.OnClick then
      local search = CreateFrame('EditBox', '$parent'.. ADDON .. 'Filter', overlay, 'SearchBoxTemplate')
      search.Instructions:SetText(L.FilterPets)
      search:SetPoint('RIGHT', overlay, 'LEFT', 0, 1)
      search:SetSize(128, 20)
      search:SetScript('OnTextChanged', function(search, manual)
        self:SetTextFilter(search:GetText())
      end)

      search:HookScript('OnEditFocusGained', function()
        SushiDropFrame:Toggle('TOP', search, 'BOTTOM', 0, -15, true, self.ShowSuggestions)
      end)

      search:HookScript('OnEditFocusLost', function()
        SushiDropFrame:CloseAll()
      end)

      overlay:SetScript('OnClick', function()
        SushiDropFrame:Toggle('TOPLEFT', overlay, 'BOTTOMLEFT', 0, -15, true, self.ShowTrackingTypes)
      end)

      self.frames[frame] = search
      self:UpdateSearch(frame)
    end
  end
end