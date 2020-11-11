OM_CampaignTooltipMixin = CreateFromMixins(CampaignTooltipMixin);
--[[
function OM_CampaignTooltipMixin:OnShow()
	self.ticker = C_Timer.NewTicker(0.25, function()
		self:SetCampaign(self.campaign);
	end)
end

function OM_CampaignTooltipMixin:OnHide()
	if ( self.ticker ) then
		self.ticker:Cancel();
		self.ticker = nil;
	end
end

function OM_CampaignTooltipMixin:SetCampaign(campaign)
	self.campaign = campaign;

	if campaign.isWarCampaign then
		self:SetWarCampaign(campaign);
	else
		self:SetJourneyCampaign(campaign);
	end
end

function OM_CampaignTooltipMixin:SetWarCampaign(campaign)
	-- Restore spacing
	self.ChapterTitle:SetSpacing(0);
	self.Description:SetSpacing(0);

	self.Title:SetText(campaign.name);

	local chapterID = campaign:GetCurrentChapterID();
	if (chapterID) then
		local campaignChapterInfo = C_CampaignInfo.GetCampaignChapterInfo(chapterID);
		if (campaignChapterInfo) then
			self.ChapterTitle:SetText(campaignChapterInfo.name);
			self.Description:SetText(campaignChapterInfo.description);
			self.Description:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB());
			if ( GetNumQuestLogRewards(campaignChapterInfo.rewardQuestID) > 0 ) then
				if (not EmbeddedItemTooltip_SetItemByQuestReward(self.ItemTooltip, 1, campaignChapterInfo.rewardQuestID)) then
					self.ItemTooltip:Hide();
				end
			elseif ( GetNumQuestLogRewardSpells(campaignChapterInfo.rewardQuestID) > 0 ) then
				if (not EmbeddedItemTooltip_SetSpellByQuestReward(self.ItemTooltip, 1, campaignChapterInfo.rewardQuestID)) then
					self.ItemTooltip:Hide();
				end
			else
				if (QuestUtils_AddQuestCurrencyRewardsToTooltip(campaignChapterInfo.rewardQuestID, nil, self.ItemTooltip) == 0 ) then
					self.ItemTooltip:Hide();
				end
				EmbeddedItemTooltip_UpdateSize(self.ItemTooltip);
			end
		else
			self.ChapterTitle:SetText(campaign.name);

			local failureReason = campaign:GetFailureReason();
			self.Description:SetText(failureReason and failureReason.text or "");

			self.ItemTooltip:Hide();
			self.Description:SetTextColor(NORMAL_FONT_COLOR:GetRGB());
		end
	else
		if campaign:IsComplete() then
			self.Description:SetText(WAR_CAMPAIGN_DONE_DESCRIPTION);
		else
			local failureReason = campaign:GetFailureReason();
			self.Description:SetText(failureReason and failureReason.text or "");
		end
		self.ChapterTitle:SetText(nil);
		self.ItemTooltip:Hide();
		self.Description:SetTextColor(NORMAL_FONT_COLOR:GetRGB());
	end

	if (self.ItemTooltip:IsShown()) then
		self.CompleteRewardText:Show();
	else
		self.CompleteRewardText:Hide();
	end

	self:Layout();
	self:Show();
end

function OM_CampaignTooltipMixin:SetJourneyCampaign(campaign)
	self.ItemTooltip:Hide();
	self.CompleteRewardText:Hide();

	local lineSpacing = 4;
	self.ChapterTitle:SetSpacing(lineSpacing);
	self.Description:SetSpacing(lineSpacing);

	self.Title:SetText(campaign.name);
	self.ChapterTitle:SetText(CampaignUtil.BuildChapterProgressText(campaign, CAMPAIGN_PROGRESS_CHAPTERS_TOOLTIP));
	self.Description:SetText(CampaignUtil.BuildAllChaptersText(campaign, lineSpacing));

	self:Layout();
	self:Show();
end
]]--

OM_CampaignHeaderDisplayMixin = CreateFromMixins(CampaignHeaderDisplayMixin);
--[[
function OM_CampaignHeaderDisplayMixin:OnLoad()
	self.Text:SetFontObjectsToTry(GameFontHighlightMedium, GameFontHighlight, GameFontHighlightSmall);
end

function OM_CampaignHeaderDisplayMixin:UpdateComplete(isComplete)
	self.Background:SetDesaturated(isComplete);
end

local function SetFieldText(field, text, color)
	field:SetText(text or "");
	field:SetTextColor((color or NORMAL_FONT_COLOR):GetRGB());
end

function OM_CampaignHeaderDisplayMixin:SetProgressText(text, color)
	SetFieldText(self.Progress, text, color);
end

function OM_CampaignHeaderDisplayMixin:UpdateJourneyProgressText(state)
	local text = CampaignUtil.BuildChapterProgressText(self:GetCampaign());
	self:SetProgressText(text, HIGHLIGHT_FONT_COLOR);
end

function OM_CampaignHeaderDisplayMixin:UpdateProgress(state)
	self:UpdateJourneyProgressText(state);
end

function OM_CampaignHeaderDisplayMixin:UpdateNextObjective(state)
	if state == Enum.CampaignState.Stalled and not self.suppressNextText then
		local failureReason = self:GetCampaign():GetFailureReason();
		if failureReason and failureReason.text and not self:IsCollapsed() then
			self.NextObjective:Set(failureReason);
			self:SetHitRectInsets(0, 0, 0, self.NextObjective.Text:GetStringHeight() + 6);
			return;
		end
	end

	self.NextObjective:Clear();
	self:SetHitRectInsets(0, 0, 0, 0);
end

function OM_CampaignHeaderDisplayMixin:UpdateTitle(isComplete)
	local campaign = self:GetCampaign();
	local color = isComplete and DISABLED_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
	SetFieldText(self.Text, campaign.name, color);
end

local CampaignTextureKitInfo = {
	Background = "Campaign_%s",
	HighlightTexture = "Campaign_%s",
};

function OM_CampaignHeaderDisplayMixin:SetCampaign(campaignID)
	local campaign = CampaignCache:Get(campaignID);
	self.campaign = campaign;

	SetupTextureKitOnRegions(campaign.uiTextureKit, self, CampaignTextureKitInfo);

	local state = campaign:GetState();
	local isComplete = state == Enum.CampaignState.Complete;
	self:UpdateComplete(isComplete);
	self:UpdateTitle(isComplete);
	self:UpdateProgress(state);
	self:UpdateNextObjective(state);
	self:MarkDirty();
	self:Show();
end

function OM_CampaignHeaderDisplayMixin:GetCampaign()
	return self.campaign;
end

function OM_CampaignHeaderDisplayMixin:SetCampaignFromQuestHeader(questHeader)
	self.questLogIndex = questHeader.questLogIndex;
	self.isCollapsed = questHeader.isCollapsed;
	self:SetCampaign(questHeader.campaignID);
end

]]--
OM_CampaignHeaderMixin = CreateFromMixins(CampaignHeaderMixin);

--[[
function OM_CampaignHeaderMixin:SetCampaign(campaignID)
	OM_CampaignHeaderDisplayMixin.SetCampaign(self, campaignID);
	self.LoreButton:SetMode("overview");
	self:UpdateCollapsedState();

	self:RegisterEvent("LORE_TEXT_UPDATED_CAMPAIGN");
	self.hasLoreEntries = false;
	C_LoreText.RequestLoreTextForCampaignID(campaignID);
end

function OM_CampaignHeaderMixin:UpdateCollapsedState()
	local isCollapsed = self:IsCollapsed();
	self.CollapseButton:UpdateState(isCollapsed);
	self.SelectedHighlight:SetShown(not isCollapsed);
end

function OM_CampaignHeaderMixin:SetCollapsed(collapsed)
	-- Make the request to the client, allow the update to refresh the visual state.
	if collapsed then
		CollapseQuestHeader(self.questLogIndex);
	else
		ExpandQuestHeader(self.questLogIndex);
	end
end

function OM_CampaignHeaderMixin:IsCollapsed()
	return self.isCollapsed;
end

function OM_CampaignHeaderMixin:OnUpdate()
	self:UpdateLoreButtonVisibility();
end

function OM_CampaignHeaderMixin:OnEnter()
	self:ShowTooltip();

	-- Keep requesting lore for every mouse enter, the alternative is to make the dangerous assumption that lore would only update on quest complete
	if not self:HasLoreEntries() then
		C_LoreText.RequestLoreTextForCampaignID(self:GetCampaign():GetID());
	end

	-- NOTE: The OnUpdate handles the logic for OnLeave because of how many elements need to remain visible/highlighted.
	self:SetScript("OnUpdate", self.OnUpdate);
end

function OM_CampaignHeaderMixin:OnLeave()
	self:SetScript("OnUpdate", nil);
	QuestMapLog_GetCampaignTooltip():Hide();
end

function OM_CampaignHeaderMixin:OnMouseUp(button, upInside)
	if upInside and button == "LeftButton" then
		self.CollapseButton:OnClick(button);
	end
end

function OM_CampaignHeaderMixin:OnEvent(event, ...)
	if event == "LORE_TEXT_UPDATED_CAMPAIGN" then
		local id, entries = ...;
		if id == self:GetCampaign():GetID() then
			self.hasLoreEntries = #entries > 0;
			if self.hasLoreEntries then
				self:UnregisterEvent("LORE_TEXT_UPDATED_CAMPAIGN");
			end
		end
	end
end

function OM_CampaignHeaderMixin:HasLoreEntries()
	return self.hasLoreEntries;
end
]]--

function OM_CampaignHeaderMixin:ShowTooltip()
	local tooltip = QuestMapLog_GetCampaignTooltip();

	tooltip:SetCampaign(self:GetCampaign());
	tooltip:ClearAllPoints();
	if (tooltip:GetWidth() > UIParent:GetRight() - OmegaMapFrame:GetRight()) then
		tooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", -5, 0);
	else
		tooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 27, 0);
	end
	tooltip:Show();
end

--[[
function OM_CampaignHeaderMixin:UpdateLoreButtonVisibility()
	local mouseOver = RegionUtil.IsDescendantOfOrSame(GetMouseFocus(), self);
	local showLore = (mouseOver or self:IsLoreButtonLocked()) and self:HasLoreEntries();
	self.LoreButton:SetShown(showLore);
	self:SetDrawLayerEnabled("HIGHLIGHT", mouseOver);

	if showLore then
		self:CheckShowLoreTutorial();
	end

	-- OnLeave logic
	if not mouseOver then
		self:OnLeave();
	end
end

local function UnlockLoreButtonFromHelpTip(acknowledged, campaignHeader)
	campaignHeader:SetLoreButtonLocked(false);
	campaignHeader:UpdateLoreButtonVisibility();
end

function OM_CampaignHeaderMixin:SetLoreButtonLocked(locked)
	self.loreButtonLocked = locked;
end

function OM_CampaignHeaderMixin:IsLoreButtonLocked()
	return self.loreButtonLocked;
end

function OM_CampaignHeaderMixin:CheckShowLoreTutorial()
	if HelpTip:IsShowing(QuestScrollFrame, CAMPAIGN_LORE_BUTTON_HELPTIP) then
		return;
	end

	local helpTipInfo =
	{
		text = CAMPAIGN_LORE_BUTTON_HELPTIP,
		buttonStyle = HelpTip.ButtonStyle.Close,
		targetPoint = HelpTip.Point.TopEdgeCenter,
		cvarBitfield = "closedInfoFrames",
		bitfieldFlag = LE_FRAME_TUTORIAL_CAMPAIGN_LORE_TEXT,
		checkCVars = true,
		onHideCallback = UnlockLoreButtonFromHelpTip,
		callbackArg = self,
		system = "LoreTextButton",
	};

	if HelpTip:Show(QuestScrollFrame, helpTipInfo, self.LoreButton) then
		self:SetLoreButtonLocked(true);
	end
end

CampaignCollapseButtonMixin = {};

function CampaignCollapseButtonMixin:OnClick()
	local header = self:GetParent();
	local isCollapsed = header:IsCollapsed()
	if(isCollapsed) then
		PlaySound(SOUNDKIT.UI_JOURNEYS_EXPAND_HEADER);
	else
		PlaySound(SOUNDKIT.UI_JOURNEYS_COLLAPSE_HEADER);
	end
	header:SetCollapsed(not isCollapsed);
end

function CampaignCollapseButtonMixin:OnEnter()
	self:GetParent():OnEnter();
end

function CampaignCollapseButtonMixin:UpdateState(isCollapsed)
	self:SetNormalAtlas(isCollapsed and "Campaign_HeaderIcon_Closed" or "Campaign_HeaderIcon_Open" );
	self:SetPushedAtlas(isCollapsed and "Campaign_HeaderIcon_ClosedPressed" or "Campaign_HeaderIcon_OpenPressed");
end
]]--
OM_CampaignLoreButtonMixin = CreateFromMixins(CampaignLoreButtonMixin);


function OM_CampaignLoreButtonMixin:SetMode(mode)
	if mode ~= self.mode then
		if mode == "overview" then
			self:SetHighlightAtlas("Campaign-QuestLog-LoreBook-Highlight", "ADD");
			self:SetNormalAtlas("Campaign-QuestLog-LoreBook");
		elseif mode == "questlog" then
			self:SetHighlightAtlas("Campaign-QuestLog-LoreBook-Back-Glow", "ADD");
			self:SetNormalAtlas("Campaign-QuestLog-LoreBook-Back");
		end

		self.mode = mode;
	end
end

function OM_CampaignLoreButtonMixin:OnClick()
	if self.mode == "overview" then
		PlaySound(SOUNDKIT.UI_JOURNEYS_OPEN_LORE_BOOK);
		HelpTip:Hide(QuestScrollFrame, CAMPAIGN_LORE_BUTTON_HELPTIP);
		EventRegistry:TriggerEvent("QuestLog.ShowCampaignOverview", self:GetParent():GetCampaign():GetID());
	elseif self.mode == "questlog" then
		PlaySound(SOUNDKIT.UI_JOURNEYS_CLOSE_LORE_BOOK);
		EventRegistry:TriggerEvent("QuestLog.HideCampaignOverview");
	end
end
--[[
CampaignNextObjectiveMixin = {};

function CampaignNextObjectiveMixin:Set(failureReason)
	self.mapID = failureReason.mapID;
	self.questID = failureReason.questID;
	if failureReason.text then
		self.Text:SetText(failureReason.text);
	end

	self:Show();
	self:MarkDirty();
end

function CampaignNextObjectiveMixin:Clear()
	self.Text:SetText("");
	self.mapID = nil;
	self:Hide();
	self:GetParent():MarkDirty();
end

function CampaignNextObjectiveMixin:OnEnter()
	self.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGBA());
end

function CampaignNextObjectiveMixin:OnLeave()
	self.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGBA());
end

function CampaignNextObjectiveMixin:OnMouseUp(button, upInside)
	if self.mapID and upInside and button == "LeftButton" then
		OpenWorldMap(self.mapID); -- and ping quest?
	end
end
]]--