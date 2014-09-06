--	///////////////////////////////////////////////////////////////////////////////////////////

--Omega Map Options Frame & Controls
--Omega Map Minimap & Hotspot Code

--	///////////////////////////////////////////////////////////////////////////////////////////


OmegaMapMiniMap = LibStub("LibDBIcon-1.0")
local HotSpotState = false

--Registers OmegaMap for LDB addons
local OmegaMapLDB = LibStub("LibDataBroker-1.1"):NewDataObject("OmegaMapMini", {
	type = "data source",
	text = "OmegaMap",
	icon = "Interface\\Icons\\INV_Misc_Map04",
	OnClick = function(self, button, down) 
		if (button == "RightButton") then
			OmegaMapOptionsFrame.Toggle()
		elseif (button == "LeftButton") then
			OmegaMapToggle()
		elseif (button == "MiddleButton") then
		OmegaMapConfig.showHotSpot = not OmegaMapConfig.showHotSpot
		OmegaMapHotSpotToggle()
		OmegaMapOptionsFrame.showHotSpot:SetChecked(OmegaMapConfig.showHotSpot)
		end
	end,})

function OmegaMapMiniMap_Register()
OmegaMapMiniMap:Register("OmegaMapMini", OmegaMapLDB, OmegaMapConfig.MMDB)
end

--Minimap/LDB Tooltip Creation
function OmegaMapLDB:OnTooltipShow()
	self:AddLine(OMEGAMAP_MINI_LEFT)
	self:AddLine(OMEGAMAP_MINI_MID)
	self:AddLine(OMEGAMAP_MINI_RIGHT)
end

function OmegaMapLDB:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()
	OmegaMapLDB.OnTooltipShow(GameTooltip)
	GameTooltip:Show()
end

function OmegaMapLDB:OnLeave()
	GameTooltip:Hide()
end

--Toggles the Display of the HotSpot Button
function OmegaMapHotSpotToggle()		
	if  OmegaMapConfig.showHotSpot == true then
		OmegaMapHotSpotFrame:Show()
	else
		OmegaMapHotSpotFrame:Hide()
	end
end

if  not OmegaMapHotSpot then 
	OmegaMapHotSpotFrame = CreateFrame("Button", "OmegaMapHotSpot", UIParent)
end 

--Initializes the HotSpot Button Attributes
 function OmegaMapHotSpotInit()
	

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
	OmegaMapHotSpotFrame:SetScript("OnEnter", function() OmegaMapHotSpotMapToggle(true) HotSpotState = true end)
	OmegaMapHotSpotFrame:SetScript("OnLeave", function() OmegaMapHotSpotMapToggle()  HotSpotState = false end)
	OmegaMapHotSpotFrame:SetScript("OnClick", function()
	
	if OmegaMapConfig.hotSpotLock == true then
		OmegaMapConfig.hotSpotLock = false 
	else 
		OmegaMapConfig.hotSpotLock = true 
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

function OmegaMapHotSpotMapToggle(state)
if state == true and OmegaMapFrame:IsVisible()
then return
elseif OmegaMapConfig.hotSpotLock == true then
return
else
OmegaMapToggle()
--OmegaMapConfig.hotSpotLock = false
end

end --[[


end
	if OmegaMapConfig.hotSpotLock == true or then 
		return
	else
		OmegaMapToggle()
		OmegaMapConfig.hotSpotLock = false
	end
end
--]]
OmegaMapHotSpotInit()