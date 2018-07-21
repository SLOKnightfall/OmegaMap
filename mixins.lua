OM_QuestLogOwnerMixin = CreateFromMixins(QuestLogOwnerMixin);



local DISPLAY_STATE_CLOSED = 1;
local DISPLAY_STATE_OPEN_MINIMIZED_NO_LOG = 2;
local DISPLAY_STATE_OPEN_MINIMIZED_WITH_LOG = 3;
local DISPLAY_STATE_OPEN_MAXIMIZED = 4;

function OM_QuestLogOwnerMixin:HandleUserActionToggleSelf()
	local displayState;
	if self:IsShown() then
		displayState = DISPLAY_STATE_CLOSED;
	else
		self.wasShowingQuestLog = nil;
		displayState = DISPLAY_STATE_OPEN_MAXIMIZED;
	end
	self:SetDisplayState(displayState);
end

function OM_QuestLogOwnerMixin:SetDisplayState(displayState)
	if displayState == DISPLAY_STATE_CLOSED then

		OmegaMapFrame:Hide();
	else
		OmegaMapFrame:Show();

		local hasSynchronizedDisplayState = false;

		if displayState == DISPLAY_STATE_OPEN_MAXIMIZED then
			if not self:IsMaximized() then
				--self:SetQuestLogPanelShown(false);
				--self:Maximize();
				hasSynchronizedDisplayState = true;
			end
		elseif displayState == DISPLAY_STATE_OPEN_MINIMIZED_NO_LOG then
			if self:IsMaximized() then
				--self:Minimize();
				hasSynchronizedDisplayState = true;
			end
			self:SetQuestLogPanelShown(false);
		elseif displayState == DISPLAY_STATE_OPEN_MINIMIZED_WITH_LOG then
			if self:IsMaximized() then
				--self:Minimize();
				hasSynchronizedDisplayState = true;
			end
			--self:SetQuestLogPanelShown(true);
		end
	end



	self:RefreshQuestLog();
	self:UpdateSpacerFrameAnchoring();

	if not hasSynchronizedDisplayState then
		self:SynchronizeDisplayState();
	end
end


function OM_QuestLogOwnerMixin:HandleUserActionToggleSidePanel()
	local displayState;
	if self.QuestLog:IsShown() then
		displayState = DISPLAY_STATE_OPEN_MINIMIZED_NO_LOG;
	else
		displayState = DISPLAY_STATE_OPEN_MINIMIZED_WITH_LOG;
	end
	self:SetDisplayState(displayState);
end


OM_POI_Mixin = CreateFromMixins(MapCanvasMixin);

function OM_POI_Mixin:OnLoad()
	CallbackRegistryBaseMixin.OnLoad(self);
	self.detailLayerPool = CreateFramePool("FRAME", self:GetCanvas(), "MapCanvasDetailLayerTemplate");
	self.dataProviders = {};
	self.dataProviderEventsCount = {};
	self.pinPools = {};
	self.pinTemplateTypes = {};
	self.activeAreaTriggers = {};
	self.lockReasons = {};
	self.pinsToNudge = {};
	self.pinFrameLevelsManager = CreateFromMixins(MapCanvasPinFrameLevelsManagerMixin);
	self.pinFrameLevelsManager:Initialize();
	self.mouseClickHandlers = {};
	self:SetFrameLevel( OmegaMapFrame:GetFrameLevel() +  10000);

	self:EvaluateLockReasons();

	self.debugAreaTriggers = false;
end

function OM_POI_Mixin:OnUpdate()
	self:UpdatePinNudging();
end

function OM_POI_Mixin:SetMapID(mapID)
	local mapArtID = C_Map.GetMapArtID(mapID) -- phased map art may be different for the same mapID
	if self.mapID ~= mapID or self.mapArtID ~= mapArtID then
		self.areDetailLayersDirty = true;
		self.mapID = mapID; 
		self.mapArtID = mapArtID;
		self.expandedMapInsetsByMapID = {};
		self:SetMapID(mapID);
		if self:IsShown() then
			self:RefreshDetailLayers();
		end
		self:OnMapChanged();
	end
end

function OM_POI_Mixin:OnFrameSizeChanged()
	self:OnCanvasSizeChanged();
end

function OM_POI_Mixin:GetMapID()
	return self.mapID;
end

function OM_POI_Mixin:SetMapInsetPool(mapInsetPool)
	self.mapInsetPool = mapInsetPool;
end

function OM_POI_Mixin:GetMapInsetPool()
	return self.mapInsetPool;
end

function OM_POI_Mixin:OnShow()
	local FROM_ON_SHOW = true;
	self:RefreshAll(FROM_ON_SHOW);

	for dataProvider in pairs(self.dataProviders) do
		dataProvider:OnShow();
	end
end

function OM_POI_Mixin:OnHide()
	for dataProvider in pairs(self.dataProviders) do
		dataProvider:OnHide();
	end
end

function OM_POI_Mixin:OnEvent(event, ...)
	-- Data provider event
	for dataProvider in pairs(self.dataProviders) do
		dataProvider:SignalEvent(event, ...);
	end
end

function OM_POI_Mixin:AddDataProvider(dataProvider)
	self.dataProviders[dataProvider] = true;
	dataProvider:OnAdded(self);
end

function OM_POI_Mixin:RemoveDataProvider(dataProvider)
	dataProvider:RemoveAllData();
	self.dataProviders[dataProvider] = nil;
	dataProvider:OnRemoved(self);
end

function OM_POI_Mixin:AddDataProviderEvent(event)
	self.dataProviderEventsCount[event] = (self.dataProviderEventsCount[event] or 0) + 1;
	self:RegisterEvent(event);
end

function OM_POI_Mixin:RemoveDataProviderEvent(event)
	if self.dataProviderEventsCount[event] then
		self.dataProviderEventsCount[event] = self.dataProviderEventsCount[event] - 1;
		if self.dataProviderEventsCount[event] == 0 then
			self.dataProviderEventsCount[event] = nil;
			self:UnregisterEvent(event);
		end
	end
end

function OM_POI_Mixin:SetPinNudgingDirty(dirty)
	self.pinNudgingDirty = dirty;
end

do
	local function OnPinReleased(pinPool, pin)
		FramePool_HideAndClearAnchors(pinPool, pin);
		pin:OnReleased();

		pin.pinTemplate = nil;
		pin.owningMap = nil;
	end

	local function OnPinMouseUp(pin, button, upInside)
		pin:OnMouseUp(button);
		if upInside then
			pin:OnClick(button);
		end
	end

	function OM_POI_Mixin:AcquirePin(pinTemplate, ...)
		if not self.pinPools[pinTemplate] then
			local pinTemplateType = self.pinTemplateTypes[pinTemplate] or "FRAME";
			self.pinPools[pinTemplate] = CreateFramePool(pinTemplateType, self:GetCanvas(), pinTemplate, OnPinReleased);
		end

		local pin, newPin = self.pinPools[pinTemplate]:Acquire();

		if newPin then
			local isMouseClickEnabled = pin:IsMouseClickEnabled();
			local isMouseMotionEnabled = pin:IsMouseMotionEnabled();

			if isMouseClickEnabled then
				pin:SetScript("OnMouseUp", OnPinMouseUp);
				pin:SetScript("OnMouseDown", pin.OnMouseDown);
			end

			if isMouseMotionEnabled then
				if newPin then
					-- These will never be called, just define a OnMouseEnter and OnMouseLeave on the pin mixin and it'll be called when appropriate
					assert(pin:GetScript("OnEnter") == nil);
					assert(pin:GetScript("OnLeave") == nil);
				end
				pin:SetScript("OnEnter", pin.OnMouseEnter);
				pin:SetScript("OnLeave", pin.OnMouseLeave);
			end

			pin:SetMouseClickEnabled(isMouseClickEnabled);
			pin:SetMouseMotionEnabled(isMouseMotionEnabled);
		end

		pin.pinTemplate = pinTemplate;
		pin.owningMap = self;

		if newPin then
			pin:OnLoad();
		end

		self:MarkCanvasDirty();
		pin:Show();
		pin:OnAcquired(...);
		
		return pin;
	end
end

function OM_POI_Mixin:SetPinTemplateType(pinTemplate, pinTemplateType)
	self.pinTemplateTypes[pinTemplate] = pinTemplateType;
end

function OM_POI_Mixin:RemoveAllPinsByTemplate(pinTemplate)
	if self.pinPools[pinTemplate] then
		self.pinPools[pinTemplate]:ReleaseAll();
		self:MarkCanvasDirty();
	end
end

function OM_POI_Mixin:RemovePin(pin)
	if pin:GetNudgeSourceRadius() > 0 then
		self.pinNudgingDirty = true;
	end
	
	self.pinPools[pin.pinTemplate]:Release(pin);
	self:MarkCanvasDirty();
end

function OM_POI_Mixin:EnumeratePinsByTemplate(pinTemplate)
	if self.pinPools[pinTemplate] then
		return self.pinPools[pinTemplate]:EnumerateActive();
	end
	return nop;
end

function OM_POI_Mixin:GetNumActivePinsByTemplate(pinTemplate)
	if self.pinPools[pinTemplate] then
		return self.pinPools[pinTemplate]:GetNumActive();
	end
	return 0;
end

function OM_POI_Mixin:EnumerateAllPins()
	local currentPoolKey, currentPool = next(self.pinPools, nil);
	local currentPin = nil;
	return function()
		if currentPool then
			currentPin = currentPool:GetNextActive(currentPin);
			while not currentPin do
				currentPoolKey, currentPool = next(self.pinPools, currentPoolKey);
				if currentPool then
					currentPin = currentPool:GetNextActive();
				else
					break;
				end
			end
		end

		return currentPin;
	end, nil;
end

function OM_POI_Mixin:AcquireAreaTrigger(namespace)
	if not self.activeAreaTriggers[namespace] then
		self.activeAreaTriggers[namespace] = {};
	end
	local areaTrigger = CreateRectangle();
	areaTrigger.enclosed = false;
	areaTrigger.intersects = false;

	areaTrigger.intersectCallback = nil;
	areaTrigger.enclosedCallback = nil;
	areaTrigger.triggerPredicate = nil;

	self.activeAreaTriggers[namespace][areaTrigger] = true;
	self:MarkAreaTriggersDirty();
	return areaTrigger;
end

function OM_POI_Mixin:SetAreaTriggerEnclosedCallback(areaTrigger, enclosedCallback)
	areaTrigger.enclosedCallback = enclosedCallback;
	self:MarkAreaTriggersDirty();
end

function OM_POI_Mixin:SetAreaTriggerIntersectsCallback(areaTrigger, intersectCallback)
	areaTrigger.intersectCallback = intersectCallback;
	self:MarkAreaTriggersDirty();
end

function OM_POI_Mixin:SetAreaTriggerPredicate(areaTrigger, triggerPredicate)
	areaTrigger.triggerPredicate = triggerPredicate;
	self:MarkAreaTriggersDirty();
end

function OM_POI_Mixin:ReleaseAreaTriggers(namespace)
	self.activeAreaTriggers[namespace] = nil;
	self:TryRefreshingDebugAreaTriggers();
end

function OM_POI_Mixin:ReleaseAreaTrigger(namespace, areaTrigger)
	if self.activeAreaTriggers[namespace] then
		self.activeAreaTriggers[namespace][areaTrigger] = nil;
		self:TryRefreshingDebugAreaTriggers();
	end
end

function OM_POI_Mixin:UpdateAreaTriggers(scrollRect)
	for namespace, areaTriggers in pairs(self.activeAreaTriggers) do
		for areaTrigger in pairs(areaTriggers) do
			if areaTrigger.intersectCallback then
				local intersects = (not areaTrigger.triggerPredicate or areaTrigger.triggerPredicate(areaTrigger)) and scrollRect:IntersectsRect(areaTrigger);
				if areaTrigger.intersects ~= intersects then
					areaTrigger.intersects = intersects;
					areaTrigger.intersectCallback(areaTrigger, intersects);
				end
			end

			if areaTrigger.enclosedCallback then
				local enclosed = (not areaTrigger.triggerPredicate or areaTrigger.triggerPredicate(areaTrigger)) and scrollRect:EnclosesRect(areaTrigger);

				if areaTrigger.enclosed ~= enclosed then
					areaTrigger.enclosed = enclosed;
					areaTrigger.enclosedCallback(areaTrigger, enclosed);
				end
			end
		end
	end

	self:TryRefreshingDebugAreaTriggers();
end

function SquaredDistanceBetweenPoints(firstX, firstY, secondX, secondY)
	local xDiff = firstX - secondX;
	local yDiff = firstY - secondY;
	
	return xDiff * xDiff + yDiff * yDiff;
end

function OM_POI_Mixin:CalculatePinNudging(targetPin)
	targetPin:SetNudgeVector(nil, nil, nil, nil);
	if not targetPin:IgnoresNudging() and targetPin:GetNudgeTargetFactor() > 0 then
		local normalizedX, normalizedY = targetPin:GetPosition();
		for sourcePin in self:EnumerateAllPins() do
			if targetPin ~= sourcePin and not sourcePin:IgnoresNudging() and sourcePin:GetNudgeSourceRadius() > 0 then
				local otherNormalizedX, otherNormalizedY = sourcePin:GetPosition();
				local distanceSquared = SquaredDistanceBetweenPoints(normalizedX, normalizedY, otherNormalizedX, otherNormalizedY);
				
				local nudgeFactor = targetPin:GetNudgeTargetFactor() * sourcePin:GetNudgeSourceRadius();
				if distanceSquared < nudgeFactor * nudgeFactor then
					local distance = math.sqrt(distanceSquared);
					
					-- Avoid divide by zero: just push it right.
					if distanceSquared == 0 then
						targetPin:SetNudgeVector(sourcePin:GetNudgeSourceZoomedOutMagnitude(), sourcePin:GetNudgeSourceZoomedInMagnitude(), 1, 0);
					else
						targetPin:SetNudgeVector(sourcePin:GetNudgeSourceZoomedOutMagnitude(), sourcePin:GetNudgeSourceZoomedInMagnitude(), (normalizedX - otherNormalizedX) / distance, (normalizedY - otherNormalizedY) / distance);
					end
					
					targetPin:SetNudgeFactor(1 - (distance / nudgeFactor));
					break; -- This is non-exact: each target pin only gets pushed by one source pin.
				end
			end
		end
	end
end

function OM_POI_Mixin:UpdatePinNudging()
	if not self.pinNudgingDirty and #self.pinsToNudge == 0 then
		return;
	end
	
	if self.pinNudgingDirty then
		for targetPin in self:EnumerateAllPins() do
			self:CalculatePinNudging(targetPin);
		end
	else
		for _, targetPin in ipairs(self.pinsToNudge) do
			self:CalculatePinNudging(targetPin);
		end
	end
	
	self.pinNudgingDirty = false;
	self.pinsToNudge = {};
end

function OM_POI_Mixin:TryRefreshingDebugAreaTriggers()
	if self.debugAreaTriggers then
		self:RefreshDebugAreaTriggers();
	elseif self.debugAreaTriggerPool then
		self.debugAreaTriggerPool:ReleaseAll();
	end
end

function OM_POI_Mixin:RefreshDebugAreaTriggers()
	if not self.debugAreaTriggerPool then
		self.debugAreaTriggerPool = CreateTexturePool(self:GetCanvas(), "OVERLAY", 7, "MapCanvasDebugTriggerAreaTemplate");
		self.debugAreaTriggerColors = {};
	end
	
	self.debugAreaTriggerPool:ReleaseAll();

	local canvas = self:GetCanvas();

	for namespace, areaTriggers in pairs(self.activeAreaTriggers) do
		if not self.debugAreaTriggerColors[namespace] then
			self.debugAreaTriggerColors[namespace] = { math.random(), math.random(), math.random(), 0.45 };
		end
		for areaTrigger in pairs(areaTriggers) do
			local debugAreaTexture = self.debugAreaTriggerPool:Acquire();
			debugAreaTexture:SetPoint("TOPLEFT", canvas, "TOPLEFT", canvas:GetWidth() * areaTrigger:GetLeft(), -canvas:GetHeight() * areaTrigger:GetTop());
			debugAreaTexture:SetPoint("BOTTOMRIGHT", canvas, "TOPLEFT", canvas:GetWidth() * areaTrigger:GetRight(), -canvas:GetHeight() * areaTrigger:GetBottom());
			debugAreaTexture:SetColorTexture(unpack(self.debugAreaTriggerColors[namespace]));
			debugAreaTexture:Show();
		end
	end
end

function OM_POI_Mixin:SetDebugAreaTriggersEnabled(enabled)
	self.debugAreaTriggers = enabled;
	self:MarkAreaTriggersDirty();
end

function OM_POI_Mixin:RefreshDetailLayers()
	if not self.areDetailLayersDirty then return end;
	self.detailLayerPool:ReleaseAll();

	local layers = C_Map.GetMapArtLayers(self.mapID);
	for layerIndex, layerInfo in ipairs(layers) do
		local detailLayer = self.detailLayerPool:Acquire();
		detailLayer:SetAllPoints(self:GetCanvas());
		detailLayer:SetMapAndLayer(self.mapID, layerIndex);
		detailLayer:SetGlobalAlpha(self:GetGlobalAlpha());
		detailLayer:Show();
	end

	self:AdjustDetailLayerAlpha();

	self.areDetailLayersDirty = false;
end

function OM_POI_Mixin:AreDetailLayersLoaded()
	for detailLayer in self.detailLayerPool:EnumerateActive() do
		if not detailLayer:IsFullyLoaded() then
			return false;
		end
	end
	return true;
end

function OM_POI_Mixin:AdjustDetailLayerAlpha()
	self:AdjustDetailLayerAlpha(self.detailLayerPool);
end

function OM_POI_Mixin:RefreshAllDataProviders(fromOnShow)
	for dataProvider in pairs(self.dataProviders) do
		dataProvider:RefreshAllData(fromOnShow);
	end
end

function OM_POI_Mixin:ResetInsets()
	if self.mapInsetPool then
		self.mapInsetPool:ReleaseAll();
		self.mapInsetsByIndex = {};
	end
end

function OM_POI_Mixin:RefreshInsets()
	self:ResetInsets();
end

function OM_POI_Mixin:AddInset(insetIndex, mapID, title, description, collapsedIcon, numDetailTiles, normalizedX, normalizedY)
	if self.mapInsetPool then
		local mapInset = self.mapInsetPool:Acquire();
		local expanded = self.expandedMapInsetsByMapID[mapID];
		mapInset:Initialize(self, not expanded, insetIndex, mapID, title, description, collapsedIcon, numDetailTiles, normalizedX, normalizedY);

		self.mapInsetsByIndex[insetIndex] = mapInset;
	end
end

function OM_POI_Mixin:RefreshAll(fromOnShow)
	self:RefreshDetailLayers();
	self:RefreshInsets();
	self:RefreshAllDataProviders(fromOnShow);
end

function OM_POI_Mixin:SetPinPosition(pin, normalizedX, normalizedY, insetIndex)
	self:ApplyPinPosition(pin, normalizedX, normalizedY, insetIndex);
	if not pin:IgnoresNudging() then
		if pin:GetNudgeSourceRadius() > 0 then
			-- If we nudge other things we need to recalculate all nudging.
			self.pinNudgingDirty = true;
		else
			self.pinsToNudge[#self.pinsToNudge + 1] = pin;
		end
	end
end

function OM_POI_Mixin:ApplyPinPosition(pin, normalizedX, normalizedY, insetIndex)
	if insetIndex then
		if self.mapInsetsByIndex and self.mapInsetsByIndex[insetIndex] then
			self.mapInsetsByIndex[insetIndex]:SetLocalPinPosition(pin, normalizedX, normalizedY);
			pin:ApplyFrameLevel();
		end
	else
		pin:ClearAllPoints();
		if normalizedX and normalizedY then
			local x = normalizedX;
			local y = normalizedY;
			
			local nudgeVectorX, nudgeVectorY = pin:GetNudgeVector();
			if nudgeVectorX and nudgeVectorY then
				local finalNudgeFactor = pin:GetNudgeFactor() * pin:GetNudgeTargetFactor() * pin:GetNudgeZoomFactor();
				x = normalizedX + nudgeVectorX * finalNudgeFactor;
				y = normalizedY + nudgeVectorY * finalNudgeFactor;
			end
			
			local canvas = self:GetCanvas();
			local scale = pin:GetScale();
			pin:SetParent(canvas);
			pin:ApplyFrameLevel();
			pin:SetPoint("CENTER", canvas, "TOPLEFT", (canvas:GetWidth() * x) / scale, -(canvas:GetHeight() * y) / scale);
		end
	end
end

function OM_POI_Mixin:GetGlobalPosition(normalizedX, normalizedY, insetIndex)
	if self.mapInsetsByIndex and self.mapInsetsByIndex[insetIndex] then
		return self.mapInsetsByIndex[insetIndex]:GetGlobalPosition(normalizedX, normalizedY);
	end
	return normalizedX, normalizedY;
end

function OM_POI_Mixin:GetCanvas()
	return self;
end

function OM_POI_Mixin:GetCanvasContainer()
	return self;
end

function OM_POI_Mixin:CallMethodOnPinsAndDataProviders(methodName, ...)
	for dataProvider in pairs(self.dataProviders) do
		dataProvider[methodName](dataProvider, ...);
	end

	for pin in self:EnumerateAllPins() do
		pin[methodName](pin, ...);
	end
end

function OM_POI_Mixin:OnMapInsetSizeChanged(mapID, mapInsetIndex, expanded)
	self.expandedMapInsetsByMapID[mapID] = expanded;
	self:CallMethodOnPinsAndDataProviders("OnMapInsetSizeChanged", mapInsetIndex, expanded);
end

function OM_POI_Mixin:OnMapInsetMouseEnter(mapInsetIndex)
	self:CallMethodOnPinsAndDataProviders("OnMapInsetMouseEnter", mapInsetIndex);
end

function OM_POI_Mixin:OnMapInsetMouseLeave(mapInsetIndex)
	self:CallMethodOnPinsAndDataProviders("OnMapInsetMouseLeave", mapInsetIndex);
end

function OM_POI_Mixin:OnMapChanged()
	for dataProvider in pairs(self.dataProviders) do
		dataProvider:OnMapChanged();
	end
end

function OM_POI_Mixin:OnCanvasScaleChanged()
	self:AdjustDetailLayerAlpha();

	if self.mapInsetsByIndex then
		for insetIndex, mapInset in pairs(self.mapInsetsByIndex) do
			mapInset:OnCanvasScaleChanged();
		end
	end

	self:CallMethodOnPinsAndDataProviders("OnCanvasScaleChanged");
end

function OM_POI_Mixin:OnCanvasPanChanged()
	self:CallMethodOnPinsAndDataProviders("OnCanvasPanChanged");
end

function OM_POI_Mixin:OnCanvasSizeChanged()
	self:CallMethodOnPinsAndDataProviders("OnCanvasSizeChanged");
end

function OM_POI_Mixin:GetCanvasScale()
	return self:GetCanvasScale();
end

function OM_POI_Mixin:GetCanvasZoomPercent()
	return self:GetCanvasZoomPercent();
end

function OM_POI_Mixin:IsZoomingIn()
	return self:IsZoomingIn();
end

function OM_POI_Mixin:IsZoomingOut()
	return self:IsZoomingOut();
end

function OM_POI_Mixin:ZoomIn()
	self:ZoomIn();
end

function OM_POI_Mixin:ZoomOut()
	self:ZoomOut();
end

function OM_POI_Mixin:ResetZoom()
	self:ResetZoom();
end

function OM_POI_Mixin:IsAtMaxZoom()
	return self:IsAtMaxZoom();
end

function OM_POI_Mixin:IsAtMinZoom()
	return self:IsAtMinZoom();
end

function OM_POI_Mixin:PanTo(normalizedX, normalizedY)
	self:SetPanTarget(normalizedX, normalizedY);
end

function OM_POI_Mixin:PanAndZoomTo(normalizedX, normalizedY)
	self:SetPanTarget(normalizedX, normalizedY);
	self:ZoomIn();
end

function OM_POI_Mixin:SetMouseWheelZoomMode(zoomMode)
	self:SetMouseWheelZoomMode(zoomMode);
end

function OM_POI_Mixin:SetShouldZoomInOnClick(shouldZoomInOnClick)
	self:SetShouldZoomInOnClick(shouldZoomInOnClick);
end

function OM_POI_Mixin:ShouldZoomInOnClick()
	return self:ShouldZoomInOnClick();
end

function OM_POI_Mixin:SetShouldNavigateOnClick(shouldNavigateOnClick)
	self:SetShouldNavigateOnClick(shouldNavigateOnClick);
end

function OM_POI_Mixin:ShouldNavigateOnClick()
	return self:ShouldNavigateOnClick();
end

function OM_POI_Mixin:SetShouldPanOnClick(shouldPanOnClick)
	self:SetShouldPanOnClick(shouldPanOnClick);
end

function OM_POI_Mixin:ShouldPanOnClick()
	return self:ShouldPanOnClick();
end

function OM_POI_Mixin:SetShouldZoomInstantly(shouldZoomInstantly)
	self:SetShouldZoomInstantly(shouldZoomInstantly);
end

function OM_POI_Mixin:ShouldZoomInstantly()
	return self:ShouldZoomInstantly();
end

function OM_POI_Mixin:GetViewRect()
	return self:GetViewRect();
end

function OM_POI_Mixin:GetMaxZoomViewRect()
	return self:GetMaxZoomViewRect();
end

function OM_POI_Mixin:GetMinZoomViewRect()
	return self:GetMinZoomViewRect();
end

function OM_POI_Mixin:GetScaleForMaxZoom()
	return self:GetScaleForMaxZoom();
end

function OM_POI_Mixin:GetScaleForMinZoom()
	return self:GetScaleForMinZoom();
end

function OM_POI_Mixin:CalculateZoomScaleAndPositionForAreaInViewRect(...)
	return self:CalculateZoomScaleAndPositionForAreaInViewRect(...);
end

function OM_POI_Mixin:NormalizeHorizontalSize(size)
	return self:NormalizeHorizontalSize(size);
end

function OM_POI_Mixin:DenormalizeHorizontalSize(size)
	return self:DenormalizeHorizontalSize(size);
end

function OM_POI_Mixin:NormalizeVerticalSize(size)
	return self:NormalizeVerticalSize(size);
end

function OM_POI_Mixin:DenormalizeVerticalSize(size)
	return self:DenormalizeVerticalSize(size);
end

function OM_POI_Mixin:GetNormalizedCursorPosition()
	return self:GetNormalizedCursorPosition()
end

function OM_POI_Mixin:IsCanvasMouseFocus()
	return self == GetMouseFocus();
end

function OM_POI_Mixin:AddLockReason(reason)
	self.lockReasons[reason] = true;
	self:EvaluateLockReasons();
end

function OM_POI_Mixin:RemoveLockReason(reason)
	self.lockReasons[reason] = nil;
	self:EvaluateLockReasons();
end

function OM_POI_Mixin:EvaluateLockReasons()
	if next(self.lockReasons) then
		--self.BorderFrame:EnableMouse(true);
		--self.BorderFrame:EnableMouseWheel(true);
		--if self.BorderFrame.Underlay then
			--self.BorderFrame.Underlay:Show();
		--end
	else
		--self.BorderFrame:EnableMouse(false);
		--self.BorderFrame:EnableMouseWheel(false);
		--if self.BorderFrame.Underlay then
			--self.BorderFrame.Underlay:Hide();
		--end
	end
end

function OM_POI_Mixin:GetPinFrameLevelsManager()
	return self.pinFrameLevelsManager;
end

function OM_POI_Mixin:ReapplyPinFrameLevels(pinFrameLevelType)
	for pin in self:EnumerateAllPins() do
		if pin:GetFrameLevelType() == pinFrameLevelType then
			pin:ApplyFrameLevel();
		end
	end
end

function OM_POI_Mixin:NavigateToParentMap()
	local mapInfo = C_Map.GetMapInfo(self:GetMapID());
	if mapInfo.parentMapID > 0 then
		self:SetMapID(mapInfo.parentMapID);
	end
end

function OM_POI_Mixin:NavigateToCursor()
	local normalizedCursorX, normalizedCursorY = self:GetNormalizedCursorPosition();
	local mapInfo = C_Map.GetMapInfoAtPosition(self:GetMapID(), normalizedCursorX, normalizedCursorY);
	if mapInfo then
		self:SetMapID(mapInfo.mapID);
	end
end

-- Add a function that will be checked when the canvas is clicked
-- If the function returns true then handling will stop
-- A priority can optionally be specified, higher priority values will be called first
do
	local function PrioritySorter(left, right)
		return left.priority > right.priority;
	end
	function OM_POI_Mixin:AddCanvasClickHandler(handler, priority)
		table.insert(self.mouseClickHandlers, { handler = handler, priority = priority or 0 });
		table.sort(self.mouseClickHandlers, PrioritySorter);
	end
end

function OM_POI_Mixin:RemoveCanvasClickHandler(handler, priority)
	for i, handlerInfo in ipairs(self.mouseClickHandlers) do
		if handlerInfo.handler == handler and (not priority or handlerInfo.priority == priority) then
			table.remove(i);
			break;
		end
	end
end

function OM_POI_Mixin:ProcessCanvasClickHandlers(button, cursorX, cursorY)
	for i, handlerInfo in ipairs(self.mouseClickHandlers) do
		local success, stopChecking = xpcall(handlerInfo.handler, CallErrorHandler, self, button, cursorX, cursorY);
		if success and stopChecking then
			return true;
		end
	end
	return false;
end

function OM_POI_Mixin:GetGlobalPinScale()
	return self.globalPinScale or 1;
end

function OM_POI_Mixin:SetGlobalPinScale(scale)
	if self.globalPinScale ~= scale then
		self.globalPinScale = scale;
		for pin in self:EnumerateAllPins() do
			pin:ApplyCurrentScale();
		end
	end
end

function OM_POI_Mixin:GetGlobalAlpha()
	return self.globalAlpha or 1;
end

function OM_POI_Mixin:SetGlobalAlpha(globalAlpha)
	if self.globalAlpha ~= globalAlpha then
		self.globalAlpha = globalAlpha;
		for detailLayer in self.detailLayerPool:EnumerateActive() do
			detailLayer:SetGlobalAlpha(globalAlpha);
		end
		for dataProvider in pairs(self.dataProviders) do
			dataProvider:OnGlobalAlphaChanged();
		end
	end
end