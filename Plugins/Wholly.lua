--	///////////////////////////////////////////////////////////////////////////////////////////

-- This code allows the integration of the Wholly addon into Omegamap 


--	///////////////////////////////////////////////////////////////////////////////////////////

if not C_AddOns.IsAddOnLoaded("Wholly") then return end

--print("Whol")
local OmegaMap = select(2, ...)
OmegaMap = LibStub("AceAddon-3.0"):GetAddon("OmegaMap")
--Creating Frame in OmegaMap to display the GatherMate2 icons
if not WhollyOmegaMapOverlay then
	local overlay = CreateFrame("Frame", "WhollyOmegaMapOverlay", OmegaMapNoteFrame)
	overlay:SetAllPoints(true)
end

--OM_WhollyDataProviderMixin = CreateFromMixins(Wholly.mapPinsProvider)

local omegamapPinsPool = CreateFramePool("FRAME")
omegamapPinsPool.parent = OmegaMapFrame:GetCanvas()
omegamapPinsPool.creationFunc = function(framepool)
    local frame = CreateFrame(framepool.frameType, nil, framepool.parent)
    frame:SetSize(16, 16)
    return Mixin(frame, self.mapPinsProviderPin)
end
omegamapPinsPool.resetterFunc = function(pinPool, pin)
    FramePool_HideAndClearAnchors(pinPool, pin)
    pin:OnReleased()
    pin.pinTemplate = nil
    pin.owningMap = nil
end
OmegaMapFrame.pinPools[Wholly.mapPinsTemplateName] = omegamapPinsPool

OM_Wholly_DataProviderMixin = CreateFromMixins(Wholly.mapPinsProvider);

--function OM_Wholly_DataProviderMixin:RemoveAllData()
    --self:GetMap():RemoveAllPinsByTemplate(Wholly.mapPinsTemplateName)
--end

--Wholly["_UpdatePins"] = function(self, forceUpdate)
			--if WorldMapFrame:IsVisible() or OmegaMapFrame:IsVisible() then
            	--self.mapPinsProvider:RefreshAllData()
            	--print("UDD")
		--	end
     --   end




OmegaMapFrame:AddDataProvider(OM_Wholly_DataProviderMixin)









