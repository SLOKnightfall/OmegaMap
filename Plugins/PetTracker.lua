--	///////////////////////////////////////////////////////////////////////////////////////////

-- Code to display PetTracer POI within OmegaMap
-- This is modified code taken from Features/WorldMap.lua from PetTracker (V 6.0.3)
-- PetTracker is written by Jaliborc at http://www.curse.com/addons/wow/pettracker

--	///////////////////////////////////////////////////////////////////////////////////////////

if not C_AddOns.IsAddOnLoaded("PetTracker") then return end
--print(OMEGAMAP_PETTRACKER_LOADED_MESSAGE)

local OmegaMap = select(2, ...)
OmegaMap = LibStub("AceAddon-3.0"):GetAddon("OmegaMap")
local Config = OmegaMap.Config

local ADDON, Addon = "PetTracker", _G["PetTracker"]
local MapSearch = Addon.MapSearch
local MapCanvas = Addon.MapCanvas
local L = Addon.Locals

OmegaMap.Plugins["showPetTracker"] = true


function OmegaMap:PetTrackerUpdate()
--MapSearch:ToggleTrackingTypes()
end



function OmegaMap:PetTrackerDraw(...)
	if OmegaMapFrame:IsShown() and (not OmegaMap.Config.showPetTracker or not OmegaMap.Plugins["showPetTracker"] )then
		return
	else
		OmegaMap.hooks[MapCanvas].Draw(...)

	end
end

OmegaMap:RawHook(MapCanvas,"Draw", "PetTrackerDraw")



function MapSearch:Init(frame)
  if not self.Frames[frame] then
    for i, overlay in ipairs(frame.overlayFrames or {}) do
      if overlay.Icon and overlay.Icon.GetTexture and overlay.Icon:GetTexture() == 'Interface\\Minimap\\Tracking\\None' then
        overlay:SetScript('OnMouseDown', function()
          overlay.Icon:SetPoint('TOPLEFT', 8, -8)
          overlay.IconOverlay:Show()

          PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
          self:ToggleTrackingTypes(overlay)
        end)
        self.Frames[frame] = overlay
      end
    end
   end
end