OmegaMap_WorldQuestDataProviderMixin = CreateFromMixins(WorldQuestDataProviderMixin);

function OmegaMap_WorldQuestDataProviderMixin:GetPinTemplate()
	return "OmegaMap_WorldQuestPinTemplate";
end

function OmegaMap_WorldQuestDataProviderMixin:ShouldShowQuest(info)
	if self.focusedQuestID or self:IsQuestSuppressed(info.questId) then
		return false;
	end
	local mapID = self:GetMap():GetMapID();
	return mapID == info.mapID;
end

function OmegaMap_WorldQuestDataProviderMixin:OnAdded(canvas)
	WorldQuestDataProviderMixin.OnAdded(self, canvas);

	if not self.poiQuantizer then
		self.poiQuantizer = CreateFromMixins(WorldMapPOIQuantizerMixin);
		self.poiQuantizer.size = 75;
		self.poiQuantizer:OnLoad(self.poiQuantizer.size, self.poiQuantizer.size);
	end
end

function OmegaMap_WorldQuestDataProviderMixin:RefreshAllData(fromOnShow)
	WorldQuestDataProviderMixin.RefreshAllData(self, fromOnShow);

	self.poiQuantizer:ClearAndQuantize(self.activePins);

	for i, pin in pairs(self.activePins) do
		pin:SetPosition(pin.quantizedX or pin.normalizedX, pin.quantizedY or pin.normalizedY);
	end
end

function OmegaMap_WorldQuestDataProviderMixin:OnCanvasSizeChanged()
	local ratio = self:GetMap():DenormalizeHorizontalSize(1.0) / self:GetMap():DenormalizeVerticalSize(1.0);
	self.poiQuantizer:Resize(math.ceil(self.poiQuantizer.size * ratio), self.poiQuantizer.size);
end

OmegaMap_WorldQuestPinMixin = CreateFromMixins(WorldQuestPinMixin);

function OmegaMap_WorldQuestPinMixin:OnLoad()
	WorldQuestPinMixin.OnLoad(self);

	self:SetScalingLimits(1, 0.425, 0.425);
end

function OmegaMap_WorldQuestPinMixin:RefreshVisuals()
	WorldQuestPinMixin.RefreshVisuals(self);

	local effectivelyTracked = IsWorldQuestHardWatched(self.questID) or (IsWorldQuestWatched(self.questID) and GetSuperTrackedQuestID() == self.questID);
	self.TrackedCheck:SetShown(effectivelyTracked);
end