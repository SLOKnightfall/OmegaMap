
OM_MapCanvasScrollControllerMixin = CreateFromMixins(MapCanvasScrollControllerMixin);

--[[

OM_MapCanvasScrollControllerMixin = {};

MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_SMOOTH = 1;
MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_FULL = 2;
MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_NONE = 3;

function OM_MapCanvasScrollControllerMixin:OnLoad()
	self.targetScrollX = 0.5;
	self.targetScrollY = 0.5;

	self.zoomAmountPerMouseWheelDelta = .075;

	self.mouseWheelZoomMode = MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_FULL;
	self:SetScalingMode("SCALING_MODE_TRANSLATE_FASTER_THAN_SCALE");

	self.normalizedZoomLerpAmount = .15;
	self.normalizedPanXLerpAmount = .15;
	self.normalizedPanYLerpAmount = .15;

	self.mouseButtonInfo = {
		LeftButton = { down = false, },
		RightButton = { down = false, },
	};
end

function OM_MapCanvasScrollControllerMixin:OnMouseDown(button)
	local mouseButtonInfo = self.mouseButtonInfo[button];
	if mouseButtonInfo then
		mouseButtonInfo.down = true;
		mouseButtonInfo.lastX, mouseButtonInfo.lastY = self:GetCursorPosition();
		mouseButtonInfo.startX, mouseButtonInfo.startY = mouseButtonInfo.lastX, mouseButtonInfo.lastY;
	end

	if button == "LeftButton" then
		if self:IsPanning() then
			self.currentScrollX = self:GetNormalizedHorizontalScroll();
			self.currentScrollY = self:GetNormalizedVerticalScroll();

			self.targetScrollX = self.currentScrollX;
			self.targetScrollY = self.currentScrollY;
		end

		self.accumulatedMouseDeltaX = 0.0;
		self.accumulatedMouseDeltaY = 0.0;
	end
end

function OM_MapCanvasScrollControllerMixin:WouldCursorPositionBeClick(button, cursorX, cursorY)
	local mouseButtonInfo = self.mouseButtonInfo[button];
	if mouseButtonInfo and mouseButtonInfo.down then
		local MAX_DIST_FOR_CLICK_SQ = 10;
		local deltaX, deltaY = cursorX - mouseButtonInfo.startX, cursorY - mouseButtonInfo.startY;
		return deltaX * deltaX + deltaY * deltaY <= MAX_DIST_FOR_CLICK_SQ;
	end
	return false;
end

function OM_MapCanvasScrollControllerMixin:FindBestLocationForClick()
	local endCursorX, endCursorY = self:GetCursorPosition();

	-- Make sure it was a click and not a pan
	if self:WouldCursorPositionBeClick("LeftButton", endCursorX, endCursorY) then
		local normalizedCursorX = self:NormalizeHorizontalSize(endCursorX / self:GetCanvasScale() - self.Child:GetLeft());
		local normalizedCursorY = self:NormalizeVerticalSize(self.Child:GetTop() - endCursorY / self:GetCanvasScale());

		local mapInfo = C_Map.GetMapInfoAtPosition(self.mapID, normalizedCursorX, normalizedCursorY);
		if mapInfo and mapInfo.mapID ~= self.mapID then
			local left, right, top, bottom = C_Map.GetMapRectOnMap(mapInfo.mapID, self.mapID);
			local centerX = left + (right - left) * .5;
			local centerY = top + (bottom - top) * .5;

			normalizedCursorX = centerX;
			normalizedCursorY = centerY;
		end

		if not self:ShouldZoomInstantly() then
			local nextZoomOutScale, nextZoomInScale = self:GetCurrentZoomRange();
			local minX, maxX, minY, maxY = self:CalculateScrollExtentsAtScale(nextZoomInScale);

			return Clamp(normalizedCursorX, minX, maxX), Clamp(normalizedCursorY, minY, maxY);
		end

		return normalizedCursorX, normalizedCursorY;
	end
end

function OM_MapCanvasScrollControllerMixin:TryPanOrZoomOnClick()
	if self.mapID then
		local shouldZoomOnClick = self:ShouldZoomInOnClick() and not self:IsAtMaxZoom() and not self:IsZoomingIn() and not self:IsZoomingOut();
		if self:ShouldPanOnClick() or shouldZoomOnClick then
			local x, y = self:FindBestLocationForClick();
			if x and y then
				self:SetPanTarget(x, y);
				if shouldZoomOnClick then
					self:ZoomIn();
				end
				return true;
			end
		end
	end

	return false;
end

function OM_MapCanvasScrollControllerMixin:OnMouseUp(button)
	local cursorX, cursorY = self:GetCursorPosition();
	local isClick = self:WouldCursorPositionBeClick(button, cursorX, cursorY);

	if button == "LeftButton" then
		if isClick then
			if not self:GetMap():ProcessCanvasClickHandlers(button, self:NormalizeUIPosition(cursorX, cursorY)) then
				if self:ShouldNavigateOnClick() then
					self:GetMap():NavigateToCursor(self:GetNormalizedCursorPosition());
				elseif self:ShouldZoomInOnClick() then
					self:TryPanOrZoomOnClick();
				end
			end
		elseif not self:TryPanOrZoomOnClick() and self:IsPanning() then		
			local deltaX, deltaY = self:GetNormalizedMouseDelta(button);
			self:AccumulateMouseDeltas(GetTickTime(), deltaX, deltaY);

			self.targetScrollX = Clamp(self.targetScrollX + self.accumulatedMouseDeltaX, self.scrollXExtentsMin, self.scrollXExtentsMax);
			self.targetScrollY = Clamp(self.targetScrollY + self.accumulatedMouseDeltaY, self.scrollYExtentsMin, self.scrollYExtentsMax);
		end

	elseif button == "RightButton" then
		if isClick and not self:GetMap():ProcessCanvasClickHandlers(button, self:NormalizeUIPosition(cursorX, cursorY)) then
			if self:IsMouseOver() then
				if self:ShouldNavigateOnClick() then
					self:GetMap():NavigateToParentMap();
				elseif self:ShouldZoomInOnClick() then
					self:ZoomOut();
				end
			end
		end
	end
	local mouseButtonInfo = self.mouseButtonInfo[button];
	if mouseButtonInfo then
		mouseButtonInfo.down = false;
	end
end

function OM_MapCanvasScrollControllerMixin:ShouldAdjustTargetPanOnMouseWheel(delta)
	if self.mouseWheelZoomMode == MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_SMOOTH then
		return true;
	end

	if delta > 0 then
		if self:IsAtMaxZoom() then
			return false;
		end

		if self:ShouldZoomInstantly() then
			return true;
		end

		if self:IsZoomingIn() then
			return false;
		end
	else
		if self:IsAtMinZoom() then
			return false;
		end

		if self:ShouldZoomInstantly() then
			return true;
		end

		if self:IsZoomingOut() then
			return false;
		end
	end
	return true;
end

function OM_MapCanvasScrollControllerMixin:OnMouseWheel(delta)
	if self.mouseWheelZoomMode == MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_NONE then
		return;
	end

	if self:ShouldAdjustTargetPanOnMouseWheel(delta) then
		local cursorX, cursorY = self:GetCursorPosition();
		local normalizedCursorX = self:NormalizeHorizontalSize(cursorX / self:GetCanvasScale() - self.Child:GetLeft());
		local normalizedCursorY = self:NormalizeVerticalSize(self.Child:GetTop() - cursorY / self:GetCanvasScale());

		if not self:ShouldZoomInstantly() then
			local nextZoomOutScale, nextZoomInScale = self:GetCurrentZoomRange();
			local minX, maxX, minY, maxY = self:CalculateScrollExtentsAtScale(nextZoomInScale);

			normalizedCursorX, normalizedCursorY = Clamp(normalizedCursorX, minX, maxX), Clamp(normalizedCursorY, minY, maxY);
		end

		self:SetPanTarget(normalizedCursorX, normalizedCursorY);
	end

	if self.mouseWheelZoomMode == MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_SMOOTH then
		self:SetZoomTarget(self:GetCanvasScale() + self.zoomAmountPerMouseWheelDelta * delta)
	elseif self.mouseWheelZoomMode == MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_FULL then
		if delta > 0 then
			self:ZoomIn();
		else
			self:ZoomOut();
		end
	end
end

function OM_MapCanvasScrollControllerMixin:OnHide()
	for button, mouseButtonInfo in pairs(self.mouseButtonInfo) do
		mouseButtonInfo.down = false;
	end

	self.currentScale = nil;
	self.currentScrollX = nil;
	self.currentScrollY = nil;
end

function OM_MapCanvasScrollControllerMixin:SetCanvasSize(width, height)
	self.Child:SetSize(width, height);
	self.Child.TiledBackground:SetSize(width * 2, height * 2);
	self:GetMap():SetPinNudgingDirty(true);
	self:CalculateScaleExtents();
	self:CalculateScrollExtents();
	self:GetMap():OnCanvasSizeChanged();
end

function OM_MapCanvasScrollControllerMixin:RefreshCanvasScale()
	self:SetZoomTarget(self.zoomTarget or 0);
end

function OM_MapCanvasScrollControllerMixin:CalculateScaleExtents()
	local nextZoomOutScale, nextZoomInScale = self:GetCurrentZoomRange();
	self.targetScale = Clamp(self.targetScale or nextZoomOutScale, nextZoomOutScale, nextZoomInScale);
end

function OM_MapCanvasScrollControllerMixin:CalculateScrollExtents()
	self.scrollXExtentsMin, self.scrollXExtentsMax, self.scrollYExtentsMin, self.scrollYExtentsMax = self:CalculateScrollExtentsAtScale(self:GetCanvasScale());
end

function OM_MapCanvasScrollControllerMixin:CalculateScrollExtentsAtScale(scale)
	local xOffset = self:NormalizeHorizontalSize((self:GetWidth() * .5) / scale);
	local yOffset = self:NormalizeVerticalSize((self:GetHeight() * .5) / scale);
	return 0.0 + xOffset, 1.0 - xOffset, 0.0 + yOffset, 1.0 - yOffset;
end

do
	local MOUSE_DELTA_SAMPLES = 100;
	local MOUSE_DELTA_FACTOR = 250;
	function OM_MapCanvasScrollControllerMixin:AccumulateMouseDeltas(elapsed, deltaX, deltaY)
		-- If the mouse changes direction then clear out the old values so it doesn't slide the wrong direction
		if deltaX > 0 and self.accumulatedMouseDeltaX < 0 or deltaX < 0 and self.accumulatedMouseDeltaX > 0 then
			self.accumulatedMouseDeltaX = 0.0;
		end

		if deltaY > 0 and self.accumulatedMouseDeltaY < 0 or deltaY < 0 and self.accumulatedMouseDeltaY > 0 then
			self.accumulatedMouseDeltaY = 0.0;
		end
			
		local normalizedSamples = MOUSE_DELTA_SAMPLES * elapsed * 60;
		self.accumulatedMouseDeltaX = (self.accumulatedMouseDeltaX / normalizedSamples) + (deltaX * MOUSE_DELTA_FACTOR) / normalizedSamples;
		self.accumulatedMouseDeltaY = (self.accumulatedMouseDeltaY / normalizedSamples) + (deltaY * MOUSE_DELTA_FACTOR) / normalizedSamples;
	end
end

function OM_MapCanvasScrollControllerMixin:CalculateLerpScaling()
	if self:ScalingMode() == "SCALING_MODE_TRANSLATE_FASTER_THAN_SCALE" then
		-- Because of the way zooming in + isLeftButtonDown is perceived, we want to reduce the zoom weight so that panning completes first
		-- However, for zooming out we want to prefer the zoom then pan
		local SCALE_DELTA_FACTOR = self:IsZoomingOut() and 1.5 or .01;
		local nextZoomOutScale, nextZoomInScale = self:GetCurrentZoomRange();
		local zoomDelta = nextZoomInScale - nextZoomOutScale;
		-- if there's only 1 zoom level
		if zoomDelta == 0 then
			zoomDelta = 1;
		end
		local scaleDelta = (math.abs(self:GetCanvasScale() - self.targetScale) / zoomDelta) * SCALE_DELTA_FACTOR;
		local scrollXDelta = math.abs(self:GetCurrentScrollX() - self.targetScrollX);
		local scrollYDelta = math.abs(self:GetCurrentScrollY() - self.targetScrollY);

		local largestDelta = math.max(math.max(scaleDelta, scrollXDelta), scrollYDelta);
		if largestDelta ~= 0.0 then
			return scaleDelta / largestDelta, scrollXDelta / largestDelta, scrollYDelta / largestDelta;
		end
		return 1.0, 1.0, 1.0;
	elseif self:ScalingMode() == "SCALING_MODE_LINEAR" then
		return 1.0, 1.0, 1.0;
	end
end

function OM_MapCanvasScrollControllerMixin:SetScalingMode(mode)
	self.scalingMode = mode;
end

function OM_MapCanvasScrollControllerMixin:ScalingMode()
	return self.scalingMode;
end

local DELTA_SCALE_BEFORE_SNAP = .0001;
local DELTA_POSITION_BEFORE_SNAP = .0001;
function OM_MapCanvasScrollControllerMixin:OnUpdate(elapsed)
	if self:IsPanning() then
		local deltaX, deltaY = self:GetNormalizedMouseDelta("LeftButton");

		self.targetScrollX = Clamp(self.targetScrollX + deltaX, self.scrollXExtentsMin, self.scrollXExtentsMax);
		self.targetScrollY = Clamp(self.targetScrollY + deltaY, self.scrollYExtentsMin, self.scrollYExtentsMax);

		self:AccumulateMouseDeltas(elapsed, deltaX, deltaY);
	end

	local cursorX, cursorY = self:GetCursorPosition();
	for button, mouseButtonInfo in pairs(self.mouseButtonInfo) do
		mouseButtonInfo.lastX, mouseButtonInfo.lastY = cursorX, cursorY;
	end

	local scaleScaling, scrollXScaling, scrollYScaling = self:CalculateLerpScaling();

	if self.currentScale ~= self.targetScale then
		local oldScrollX = self:GetNormalizedHorizontalScroll();
		local oldScrollY = self:GetNormalizedVerticalScroll();

		if not self.currentScale or math.abs(self.currentScale - self.targetScale) < DELTA_SCALE_BEFORE_SNAP then
			self.currentScale = self.targetScale;
		else
			self.currentScale = FrameDeltaLerp(self.currentScale, self.targetScale, self.normalizedZoomLerpAmount * scaleScaling);
		end

		self.Child:SetScale(self.currentScale);
		self:CalculateScrollExtents();

		self:SetNormalizedHorizontalScroll(oldScrollX);
		self:SetNormalizedVerticalScroll(oldScrollY);

		self:GetMap():OnCanvasScaleChanged();
		self:MarkAreaTriggersDirty();
		self:MarkViewRectDirty();
	end

	local panChanged = false;
	if not self.currentScrollX or self.currentScrollX ~= self.targetScrollX then
		if not self.currentScrollX or self:IsPanning() or math.abs(self.currentScrollX - self.targetScrollX) < DELTA_POSITION_BEFORE_SNAP then
			self.currentScrollX = self.targetScrollX;
		else
			self.currentScrollX = FrameDeltaLerp(self.currentScrollX, self.targetScrollX, self.normalizedPanXLerpAmount * scrollXScaling);
		end

		self:SetNormalizedHorizontalScroll(self.currentScrollX);
		self:MarkAreaTriggersDirty();
		self:MarkViewRectDirty();

		panChanged = true;
	end

	if not self.currentScrollY or self.currentScrollY ~= self.targetScrollY then
		if not self.currentScrollY or self:IsPanning() or math.abs(self.currentScrollY - self.targetScrollY) < DELTA_POSITION_BEFORE_SNAP then
			self.currentScrollY = self.targetScrollY;
		else
			self.currentScrollY = FrameDeltaLerp(self.currentScrollY, self.targetScrollY, self.normalizedPanYLerpAmount * scrollYScaling);
		end
		self:SetNormalizedVerticalScroll(self.currentScrollY);
		self:MarkAreaTriggersDirty();
		self:MarkViewRectDirty();

		panChanged = true;
	end
	
	if panChanged then
		self:GetMap():OnCanvasPanChanged();
	end

	if self.areaTriggersDirty then
		self.areaTriggersDirty = false;
		local viewRect = self:GetViewRect();
		self:GetMap():UpdateAreaTriggers(viewRect);
	end
end

function OM_MapCanvasScrollControllerMixin:MarkAreaTriggersDirty()
	self.areaTriggersDirty = true;
end

function OM_MapCanvasScrollControllerMixin:MarkViewRectDirty()
	self.viewRect = nil;
end

function OM_MapCanvasScrollControllerMixin:MarkCanvasDirty()
	-- Force an update unless an update is already going to occur
	if self.currentScale == self.targetScale then
		self.currentScale = nil;
	end
	if self.currentScrollX == self.targetScrollX then
		self.currentScrollX = nil;
	end
	if self.currentScrollY == self.targetScrollY then
		self.currentScrollY = nil;
	end
end

function OM_MapCanvasScrollControllerMixin:GetViewRect()
	if not self.viewRect then
		self.viewRect = self:CalculateViewRect(self:GetCanvasScale());
	end
	return self.viewRect;
end

function OM_MapCanvasScrollControllerMixin:SetMapID(mapID)
	self.mapID = mapID;

	self:OnCanvasSizeChanged();
end

function OM_MapCanvasScrollControllerMixin:OnCanvasSizeChanged()
	if not self.mapID then
		return;
	end

	self:CreateZoomLevels();

	self.Child.TiledBackground:SetAtlas(C_Map.GetMapArtBackgroundAtlas(self.mapID), true);

	local layers = C_Map.GetMapArtLayers(self.mapID);
	-- for now we don't support different sizes between layers
	self:SetCanvasSize(layers[1].layerWidth, layers[1].layerHeight);

	self:ResetZoom();
end

function OM_MapCanvasScrollControllerMixin:CreateZoomLevels()
	local layers = C_Map.GetMapArtLayers(self.mapID);
	local widthScale = self:GetWidth() / layers[1].layerWidth;
	local heightScale = self:GetHeight() / layers[1].layerHeight;
	self.baseScale = math.min(widthScale, heightScale);

	local currentScale = 0;
	local MIN_SCALE_DELTA = 0.01;  -- zoomLevels must have increasing scales
	self.zoomLevels = { };
	for layerIndex, layerInfo in ipairs(layers) do
		local zoomDeltaPerStep, numZoomLevels;
		local zoomDelta = layerInfo.maxScale - layerInfo.minScale;
		if zoomDelta > 0 then
			-- make multiple zoom levels
			numZoomLevels = 2 + layerInfo.additionalZoomSteps;
			zoomDeltaPerStep = zoomDelta / (numZoomLevels - 1);
		else
			numZoomLevels = 1;
			zoomDeltaPerStep = 1;
		end

		for zoomLevelIndex = 0, numZoomLevels - 1 do
			currentScale = math.max(layerInfo.minScale + zoomDeltaPerStep * zoomLevelIndex, currentScale + MIN_SCALE_DELTA);			
			table.insert(self.zoomLevels, { scale = currentScale * self.baseScale, layerIndex = layerIndex })
		end
	end
end

function OM_MapCanvasScrollControllerMixin:GetZoomLevelIndexForScale(scale)
	local bestIndex = 1;
	for i, zoomLevel in ipairs(self.zoomLevels) do
		if scale >= zoomLevel.scale then
			bestIndex = i;
		else
			break;
		end
	end
	return bestIndex;
end

function OM_MapCanvasScrollControllerMixin:GetCurrentLayerIndex()
	local canvasScale = self:GetCanvasScale();
	local currentZoomLevelIndex = self:GetZoomLevelIndexForScale(canvasScale);
	return self.zoomLevels[currentZoomLevelIndex].layerIndex;
end

function OM_MapCanvasScrollControllerMixin:AdjustDetailLayerAlpha(detailLayerPool)
	local canvasScale = self:GetCanvasScale();
	local currentZoomLevelIndex = self:GetZoomLevelIndexForScale(canvasScale);
	local currentLayerIndex = self.zoomLevels[currentZoomLevelIndex].layerIndex;
	local alphaLayerIndex, zoomPercent;
	local zoomingIn = self:IsZoomingIn();
	if zoomingIn or self:IsZoomingOut() then
		local nextZoomOutScale, nextZoomInScale = self:GetCurrentZoomRange();
		local bottomZoomLevelIndex, topZoomLevelIndex;
		if zoomingIn then
			bottomZoomLevelIndex = currentZoomLevelIndex;
			topZoomLevelIndex = self:GetZoomLevelIndexForScale(nextZoomInScale);
		else
			topZoomLevelIndex = currentZoomLevelIndex;
			bottomZoomLevelIndex = self:GetZoomLevelIndexForScale(nextZoomOutScale);
		end
		if self.zoomLevels[bottomZoomLevelIndex].layerIndex ~= self.zoomLevels[topZoomLevelIndex].layerIndex then
			currentLayerIndex = self.zoomLevels[bottomZoomLevelIndex].layerIndex;
			alphaLayerIndex = self.zoomLevels[topZoomLevelIndex].layerIndex;
			zoomPercent = PercentageBetween(canvasScale, self.zoomLevels[bottomZoomLevelIndex].scale, self.zoomLevels[topZoomLevelIndex].scale);
		end
	end

	for layer in detailLayerPool:EnumerateActive() do
		local layerIndex = layer:GetLayerIndex();
		if layerIndex == currentLayerIndex then
			layer:SetLayerAlpha(1);
		elseif layerIndex == alphaLayerIndex then
			layer:SetLayerAlpha(zoomPercent);
		else
			layer:SetLayerAlpha(0);
		end
	end
end

function OM_MapCanvasScrollControllerMixin:SetMouseWheelZoomMode(zoomMode)
	self.mouseWheelZoomMode = zoomMode;
end

function OM_MapCanvasScrollControllerMixin:SetShouldZoomInOnClick(shouldZoomInOnClick)
	self.shouldZoomInOnClick = shouldZoomInOnClick;
end

function OM_MapCanvasScrollControllerMixin:ShouldZoomInOnClick()
	return not not self.shouldZoomInOnClick;
end

function OM_MapCanvasScrollControllerMixin:SetShouldNavigateOnClick(shouldNavigateOnClick)
	self.shouldNavigateOnClick = shouldNavigateOnClick;
end

function OM_MapCanvasScrollControllerMixin:ShouldNavigateOnClick()
	return not not self.shouldNavigateOnClick;
end

function OM_MapCanvasScrollControllerMixin:SetShouldPanOnClick(shouldPanOnClick)
	self.shouldPanOnClick = shouldPanOnClick;
end

function OM_MapCanvasScrollControllerMixin:ShouldPanOnClick()
	return not not self.shouldPanOnClick;
end

function OM_MapCanvasScrollControllerMixin:SetShouldZoomInstantly(shouldZoomInstantly)
	self.shouldZoomInstantly = shouldZoomInstantly;
end

function OM_MapCanvasScrollControllerMixin:ShouldZoomInstantly()
	return not not self.shouldZoomInstantly;
end

function OM_MapCanvasScrollControllerMixin:GetMaxZoomViewRect()
	return self:CalculateViewRect(self:GetScaleForMaxZoom());
end

function OM_MapCanvasScrollControllerMixin:GetMinZoomViewRect()
	return self:CalculateViewRect(self:GetScaleForMinZoom());
end

function OM_MapCanvasScrollControllerMixin:CalculateViewRect(scale)
	local childWidth, childHeight = self.Child:GetSize();
	local left = self:GetHorizontalScroll() / childWidth;
	local right = left + (self:GetWidth() / scale) / childWidth;
	local top = self:GetVerticalScroll() / childHeight;
	local bottom = top + (self:GetHeight() / scale) / childHeight;
	return CreateRectangle(left, right, top, bottom);
end

function OM_MapCanvasScrollControllerMixin:CalculateZoomScaleAndPositionForAreaInViewRect(left, right, top, bottom, subViewLeft, subViewRight, subViewTop, subViewBottom)
	local childWidth, childHeight = self.Child:GetSize();
	local viewWidth, viewHeight = self:GetSize();

	-- this is the desired width/height of the full view given the desired positions for the subview
	local fullWidth = (right - left) / (subViewRight - subViewLeft);
	local fullHeight = (bottom - top) / (subViewTop - subViewBottom);

	local scale = ( viewWidth / fullWidth ) / childWidth;

	-- translate from the upper-left of the subview to the center of the view.
	local fullLeft = left - (fullWidth * subViewLeft);
	local fullBottom = (1.0 - bottom) - (fullHeight * subViewBottom);

	local fullCenterX = fullLeft + (fullWidth / 2);
	local fullCenterY = 1.0 - (fullBottom + (fullHeight / 2));

	return scale, fullCenterX, fullCenterY;
end

function OM_MapCanvasScrollControllerMixin:SetPanTarget(normalizedX, normalizedY)
	self.targetScrollX = normalizedX;
	self.targetScrollY = normalizedY;
end

function OM_MapCanvasScrollControllerMixin:SetZoomTarget(zoomTarget)
	self.zoomTarget = zoomTarget;
	self.targetScale = Clamp(zoomTarget, self:GetScaleForMinZoom(), self:GetScaleForMaxZoom());
end

function OM_MapCanvasScrollControllerMixin:ZoomIn()
	local nextZoomOutScale, nextZoomInScale = self:GetCurrentZoomRange();
	if nextZoomInScale > self:GetCanvasScale() then
		if self:ShouldZoomInstantly() then
			self:InstantPanAndZoom(nextZoomInScale, self.targetScrollX, self.targetScrollY);
		else
			self:SetZoomTarget(nextZoomInScale);
		end
	end
end

function OM_MapCanvasScrollControllerMixin:ZoomOut()
	local nextZoomOutScale, nextZoomInScale = self:GetCurrentZoomRange();
	if nextZoomOutScale < self:GetCanvasScale() then
		if self:ShouldZoomInstantly() then
			self:InstantPanAndZoom(nextZoomOutScale, self.targetScrollX, self.targetScrollY);
		else
			self:SetZoomTarget(nextZoomOutScale);
			self:SetPanTarget(.5, .5);
		end
	end
end

function OM_MapCanvasScrollControllerMixin:ResetZoom()
	self:InstantPanAndZoom(self.zoomLevels[1].scale, 0.5, 0.5);
end

function OM_MapCanvasScrollControllerMixin:InstantPanAndZoom(scale, panX, panY)
	local scaleRatio = self:GetCanvasScale() / scale;
	panX = Lerp(panX, self:GetCurrentScrollX() or .5, scaleRatio);
	panY = Lerp(panY, self:GetCurrentScrollY() or .5, scaleRatio);

	self.currentScale = scale;
	self.targetScale = self.currentScale;
	self.Child:SetScale(self.currentScale);
	self:CalculateScrollExtents();

	self.targetScrollX = Clamp(panX, self.scrollXExtentsMin, self.scrollXExtentsMax);
	self.targetScrollY = Clamp(panY, self.scrollYExtentsMin, self.scrollYExtentsMax);
	self.currentScrollX = self.targetScrollX;
	self.currentScrollY = self.targetScrollY;
	self:SetNormalizedHorizontalScroll(self.targetScrollX);
	self:SetNormalizedVerticalScroll(self.targetScrollY);

	self:GetMap():OnCanvasScaleChanged();
	self:MarkAreaTriggersDirty();
	self:MarkViewRectDirty();
end

function OM_MapCanvasScrollControllerMixin:IsZoomingIn()
	return self:GetCanvasScale() < self.targetScale;
end

function OM_MapCanvasScrollControllerMixin:IsZoomingOut()
	return self.targetScale < self:GetCanvasScale();
end

function OM_MapCanvasScrollControllerMixin:IsAtMaxZoom()
	return self:GetCanvasScale() == self:GetScaleForMaxZoom();
end

function OM_MapCanvasScrollControllerMixin:IsAtMinZoom()
	return self:GetCanvasScale() == self:GetScaleForMinZoom();
end

function OM_MapCanvasScrollControllerMixin:CanPan()
	return self:GetCanvasScale() > self.baseScale;
end

function OM_MapCanvasScrollControllerMixin:GetMap()
	return self:GetParent();
end

function OM_MapCanvasScrollControllerMixin:GetScaleForMaxZoom()
	return self.zoomLevels[#self.zoomLevels].scale;
end

function OM_MapCanvasScrollControllerMixin:GetScaleForMinZoom()
	return self.zoomLevels[1].scale;
end

function OM_MapCanvasScrollControllerMixin:GetCurrentZoomRange()
	local index = self:GetZoomLevelIndexForScale(self:GetCanvasScale());
	local nextZoomOutLevel = self.zoomLevels[index - 1] or self.zoomLevels[index];
	local nextZoomInLevel = self.zoomLevels[index + 1] or self.zoomLevels[index];
	return nextZoomOutLevel.scale, nextZoomInLevel.scale;
end

function OM_MapCanvasScrollControllerMixin:IsPanning()
	return self.mouseButtonInfo.LeftButton.down and not self:IsZoomingOut() and self:CanPan();
end

function OM_MapCanvasScrollControllerMixin:GetCanvasScale()
	return self.currentScale or self.targetScale or 1;
end

function OM_MapCanvasScrollControllerMixin:GetCurrentScrollX()
	return self.currentScrollX or self.targetScrollX;
end

function OM_MapCanvasScrollControllerMixin:GetCurrentScrollY()
	return self.currentScrollY or self.targetScrollY;
end

function OM_MapCanvasScrollControllerMixin:GetCanvasZoomPercent()
	return PercentageBetween(self:GetCanvasScale(), self:GetScaleForMinZoom(), self:GetScaleForMaxZoom());
end

function OM_MapCanvasScrollControllerMixin:SetNormalizedHorizontalScroll(scrollAmount)
	local offset = self:DenormalizeHorizontalSize(scrollAmount);
	self:SetHorizontalScroll(offset - (self:GetWidth() * .5) / self:GetCanvasScale());
end

function OM_MapCanvasScrollControllerMixin:GetNormalizedHorizontalScroll()
	return (2.0 * self:GetHorizontalScroll() * self:GetCanvasScale() + self:GetWidth()) / (2.0 * self.Child:GetWidth() * self:GetCanvasScale());
end

function OM_MapCanvasScrollControllerMixin:SetNormalizedVerticalScroll(scrollAmount)
	local offset = self:DenormalizeVerticalSize(scrollAmount);
	self:SetVerticalScroll(offset - (self:GetHeight() * .5) / self:GetCanvasScale());
end

function OM_MapCanvasScrollControllerMixin:GetNormalizedVerticalScroll()
	return (2.0 * self:GetVerticalScroll() * self:GetCanvasScale() + self:GetHeight()) / (2.0 * self.Child:GetHeight() * self:GetCanvasScale());
end

function OM_MapCanvasScrollControllerMixin:NormalizeHorizontalSize(size)
	return size / self.Child:GetWidth();
end

function OM_MapCanvasScrollControllerMixin:DenormalizeHorizontalSize(size)
	return size * self.Child:GetWidth();
end

function OM_MapCanvasScrollControllerMixin:NormalizeVerticalSize(size)
	return size / self.Child:GetHeight();
end

function OM_MapCanvasScrollControllerMixin:DenormalizeVerticalSize(size)
	return size * self.Child:GetHeight();
end

function OM_MapCanvasScrollControllerMixin:GetCursorPosition()
	local currentX, currentY = GetCursorPosition();
	local effectiveScale = UIParent:GetEffectiveScale();
	return currentX / effectiveScale, currentY / effectiveScale;
end

function OM_MapCanvasScrollControllerMixin:GetNormalizedMouseDelta(button)
	local mouseButtonInfo = self.mouseButtonInfo[button];
	if mouseButtonInfo and mouseButtonInfo then
		local currentX, currentY = self:GetCursorPosition();
		return self:NormalizeHorizontalSize(mouseButtonInfo.lastX - currentX) / self:GetCanvasScale(), self:NormalizeVerticalSize(currentY - mouseButtonInfo.lastY) / self:GetCanvasScale();
	end
	return 0.0, 0.0;
end

-- Normalizes a global UI position to the map canvas
function OM_MapCanvasScrollControllerMixin:NormalizeUIPosition(x, y)
	return Saturate(self:NormalizeHorizontalSize(x / self:GetCanvasScale() - self.Child:GetLeft())),
		   Saturate(self:NormalizeVerticalSize(self.Child:GetTop() - y / self:GetCanvasScale()));
end

function OM_MapCanvasScrollControllerMixin:GetNormalizedCursorPosition()
	local x, y = self:GetCursorPosition();
	return self:NormalizeUIPosition(x, y);
end

]]--