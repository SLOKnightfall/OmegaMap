OmegaMap_InvasionDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin);

function OmegaMap_InvasionDataProviderMixin:ShowOverlay()
	self.InvasionOverlay:Show();
end

function OmegaMap_InvasionDataProviderMixin:HideOverlay()
	self.InvasionOverlay:Hide();
end

function OmegaMap_InvasionDataProviderMixin:RemoveAllData()
	self:HideOverlay();
end

function OmegaMap_InvasionDataProviderMixin:RefreshAllData(fromOnShow)
	local map = self:GetMap();
	local mapID = map:GetMapID();
	local mapInfo = C_Map.GetMapInfo(mapID);
	local show = mapInfo and mapInfo.mapType ~= Enum.UIMapType.Continent and C_InvasionInfo.GetInvasionForUiMapID(mapID) ~= nil;
	if (show) then
		self:ShowOverlay();
	else
		self:HideOverlay();
	end
end

function OmegaMap_InvasionDataProviderMixin:OnAdded(owningMap)
	MapCanvasDataProviderMixin.OnAdded(self, owningMap);
	if (not self.InvasionOverlay) then
		self.InvasionOverlay = CreateFrame("Frame", nil, nil, "OmegaMapInvasionOverlayTemplate");
	end
	self.InvasionOverlay:SetParent(owningMap:GetCanvas());
	self.InvasionOverlay:SetAllPoints(owningMap);
end

function OmegaMap_InvasionDataProviderMixin:OnRemoved(owningMap)
	MapCanvasDataProviderMixin.OnRemoved(self, owningMap);
	self.InvasionOverlay:SetParent(nil);
end