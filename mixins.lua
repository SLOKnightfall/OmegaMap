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
				self:SetQuestLogPanelShown(false);
				self:Maximize();
				hasSynchronizedDisplayState = true;
			end
		elseif displayState == DISPLAY_STATE_OPEN_MINIMIZED_NO_LOG then
			if self:IsMaximized() then
				self:Minimize();
				hasSynchronizedDisplayState = true;
			end
			self:SetQuestLogPanelShown(false);
		elseif displayState == DISPLAY_STATE_OPEN_MINIMIZED_WITH_LOG then
			if self:IsMaximized() then
				self:Minimize();
				hasSynchronizedDisplayState = true;
			end
			self:SetQuestLogPanelShown(true);
		end
	end



	self:RefreshQuestLog();
	self:UpdateSpacerFrameAnchoring();

	if not hasSynchronizedDisplayState then
		self:SynchronizeDisplayState();
	end
end



