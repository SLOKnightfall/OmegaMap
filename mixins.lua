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
	--local displayState;
	if self.QuestLog:IsShown() then
		OM_QuestMapFrame:Hide()
		--displayState = DISPLAY_STATE_OPEN_MINIMIZED_NO_LOG;
	else
		OM_QuestMapFrame:Show()
		--displayState = DISPLAY_STATE_OPEN_MINIMIZED_WITH_LOG;
	end
	--self:SetDisplayState(displayState);
	self:RefreshQuestLog();
end




OmegaMapNavBarMixin = CreateFromMixins(WorldMapNavBarMixin);

function OmegaMapNavBarMixin:OnMouseUp()
	OmegaMapFrame:StopMovingOrSizing() 
end
function OmegaMapNavBarMixin:OnMouseDown()
	OmegaMapFrame:StartMoving()
	OmegaMapFrame:SetUserPlaced(true);
end

function MapCanvasMixin:ResetZoom()
	--self.ScrollContainer:ResetZoom();
end