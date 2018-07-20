--	///////////////////////////////////////////////////////////////////////////////////////////

--Omega Map Options Frame & Controls
--Omega Map Hotspot Code

--	///////////////////////////////////////////////////////////////////////////////////////////
local OmegaMap = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("OmegaMap")
OmegaMap = LibStub("AceAddon-3.0"):GetAddon("OmegaMap")
local Config = OmegaMap_Config
local HotSpotState = false

--Toggles the Display of the HotSpot Button
function OmegaMap:HotSpotToggle(value)
	if  value then
		OmegaMapHotSpotFrame:Show()
	else
		OmegaMapHotSpotFrame:Hide()
	end
end

if  not OmegaMapHotSpot then 
	OmegaMapHotSpotFrame = CreateFrame("Button", "OmegaMapHotSpot", UIParent)
end 

--Initializes the HotSpot Button Attributes
 function OmegaMap:HotSpotInit()
	OmegaMapHotSpotFrame:SetMovable(true)
	OmegaMapHotSpotFrame:SetUserPlaced(true)
	OmegaMapHotSpotFrame:ClearAllPoints()
	OmegaMapHotSpotFrame:SetPoint("CENTER");
	OmegaMapHotSpotFrame:SetWidth(25)
	OmegaMapHotSpotFrame:SetHeight(25)
	OmegaMapHotSpotFrame:SetFrameStrata("DIALOG")

	OmegaMapHotSpotFrame:SetClampedToScreen( true )
	OmegaMapHotSpotFrame:SetScript("OnMouseDown", function() OmegaMapHotSpotFrame:StartMoving() end)
	OmegaMapHotSpotFrame:SetScript("OnMouseUp", function() OmegaMapHotSpotFrame:StopMovingOrSizing() end)
	OmegaMapHotSpotFrame:SetScript("OnEnter", function() OmegaMap:HotSpotMapToggle(true) HotSpotState = true end)
	OmegaMapHotSpotFrame:SetScript("OnLeave", function() OmegaMap:HotSpotMapToggle()  HotSpotState = false end)
	OmegaMapHotSpotFrame:SetScript("OnClick", function()
	
	if Config.hotSpotLock == true then
		Config.hotSpotLock = false 
	else 
		Config.hotSpotLock = true 
	end
	end);

		OmegaMapHotSpotFrame:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true, tileSize = 32, edgeSize = 16,
			insets = { left = 5, right = 5, top = 5, bottom = 5 },
		})
	OmegaMapHotSpotFrame:SetBackdropColor(0,0,0, 0.95)
		OmegaMapHotSpotFrame:SetNormalTexture("Interface\\Icons\\INV_Misc_Map04")
end

function OmegaMap:HotSpotMapToggle(state)
	if state == true and OmegaMapFrame:IsVisible()then 
		return
	elseif Config.hotSpotLock == true then
		return
	else
		ToggleOmegaMap()
	--Config.hotSpotLock = false
	end
end