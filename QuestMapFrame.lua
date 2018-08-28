
local MIN_STORY_TOOLTIP_WIDTH = 240;

local tooltipButton;

local WarCampaignTextureKitInfo = {
	Background = "Campaign_%s"
};

QUEST_LOG_WAR_CAMPAIGN_LAYOUT_INDEX = 2;
QUEST_LOG_WAR_CAMPAIGN_NEXT_OBJECTIVE_LAYOUT_INDEX = 12;
QUEST_LOG_SEPARATOR_LAYOUT_INDEX = 24;
QUEST_LOG_STORY_LAYOUT_INDEX = 25;

OM_QuestLogMixin = { };

function OM_QuestLogMixin:Refresh()
	SortQuestSortTypes();
	SortQuests();
	OM_QuestMapFrame_ResetFilters();
	OM_QuestMapFrame_UpdateAll();
end

function OM_QuestLogMixin:UpdatePOIs()
	local mapID;
	if self:GetParent():IsShown() then
		mapID = self:GetParent():GetMapID();
	else
		mapID = C_Map.GetBestMapForUnit("player");
	end
	if mapID then
		C_QuestLog.SetMapForQuestPOIs(mapID);
		QuestMapUpdateAllQuests();
		QuestPOIUpdateIcons();
		QuestObjectiveTracker_UpdatePOIs();
	end
end

function OM_QuestLogMixin:InitLayoutIndexManager()
	self.layoutIndexManager = CreateLayoutIndexManager();
	self.layoutIndexManager:AddManagedLayoutIndex("Campaign", QUEST_LOG_WAR_CAMPAIGN_LAYOUT_INDEX + 1);
	self.layoutIndexManager:AddManagedLayoutIndex("Other", QUEST_LOG_STORY_LAYOUT_INDEX + 1);
end

function OM_QuestLogMixin:GetManagedLayoutIndex(key)
	return self.layoutIndexManager:GetManagedLayoutIndex(key);
end

function OM_QuestLogMixin:ResetLayoutIndexManager()
	self.layoutIndexManager:Reset();
end

function OM_QuestMapFrame_OnLoad(self)
	self:RegisterEvent("QUEST_LOG_UPDATE");
	self:RegisterEvent("QUEST_LOG_CRITERIA_UPDATE");
	self:RegisterEvent("QUEST_WATCH_LIST_CHANGED");
	self:RegisterEvent("SUPER_TRACKED_QUEST_CHANGED");
	self:RegisterEvent("GROUP_ROSTER_UPDATE");
	self:RegisterEvent("PARTY_MEMBER_ENABLE");
	self:RegisterEvent("PARTY_MEMBER_DISABLE");
	self:RegisterEvent("QUEST_POI_UPDATE");
	self:RegisterEvent("QUEST_WATCH_UPDATE");
	self:RegisterEvent("QUEST_ACCEPTED");
	self:RegisterEvent("UNIT_QUEST_LOG_CHANGED");
	self:RegisterEvent("AJ_QUEST_LOG_OPEN");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("CVAR_UPDATE");

	self:InitLayoutIndexManager();
	
	self.completedCriteria = {};
	QuestPOI_Initialize(OM_QuestScrollFrame.Contents);
	OM_QuestMapQuestOptionsDropDown.questID = 0;		-- for OM_QuestMapQuestOptionsDropDown_Initialize
	UIDropDownMenu_Initialize(OM_QuestMapQuestOptionsDropDown, OM_QuestMapQuestOptionsDropDown_Initialize, "MENU");
end

function OM_QuestMapFrame_OnEvent(self, event, ...)
	local arg1, arg2 = ...;
	if ( (event == "QUEST_LOG_UPDATE" or (event == "UNIT_QUEST_LOG_CHANGED" and arg1 == "player")) and not self.ignoreQuestLogUpdate ) then
		if (not IsTutorialFlagged(55) and TUTORIAL_QUEST_TO_WATCH) then
			local isComplete = select(6, GetQuestLogTitle(GetQuestLogIndexByID(TUTORIAL_QUEST_TO_WATCH)));
			if (isComplete) then
				TriggerTutorial(55);
			end
		end


		local updateButtons = false;
		if ( OM_QuestLogPopupDetailFrame.questID ) then
			if ( GetQuestLogIndexByID(OM_QuestLogPopupDetailFrame.questID) == 0 ) then
				HideUIPanel(OM_QuestLogPopupDetailFrame);
			else
				QuestLogPopupDetailFrame_Update();
				updateButtons = true;
			end
		end
		local questDetailID = OM_QuestMapFrame.DetailsFrame.questID;
		if ( questDetailID ) then
			if ( GetQuestLogIndexByID(questDetailID) == 0 ) then
				-- this will call OM_QuestMapFrame_UpdateAll
				OM_QuestMapFrame_ReturnFromQuestDetails();
				return;
			else
				updateButtons = true;
			end
		end
		if ( updateButtons ) then
			OM_QuestMapFrame_UpdateQuestDetailsButtons();
		end
		OM_QuestMapFrame_UpdateAll();
		OM_QuestMapFrame_UpdateAllQuestCriteria();

		if ( tooltipButton ) then
			OM_QuestMapLogTitleButton_OnEnter(tooltipButton);
		end
	elseif ( event == "QUEST_LOG_CRITERIA_UPDATE" ) then
		local questID, criteriaID, description, fulfilled, required = ...;

		if (OM_QuestMapFrame_CheckQuestCriteria(questID, criteriaID, description, fulfilled, required)) then
			UIErrorsFrame:AddMessage(ERR_QUEST_ADD_FOUND_SII:format(description, fulfilled, required), YELLOW_FONT_COLOR:GetRGB());
		end
	elseif ( event == "QUEST_WATCH_UPDATE" ) then
		if (not IsTutorialFlagged(11) and TUTORIAL_QUEST_TO_WATCH) then
			local questID = select(8, GetQuestLogTitle(arg1));
			if (questID == TUTORIAL_QUEST_TO_WATCH) then
				TriggerTutorial(11);
			end
		end
		if ( AUTO_QUEST_WATCH == "1" and
			GetNumQuestLeaderBoards(arg1) > 0 and
			GetNumQuestWatches() < MAX_WATCHABLE_QUESTS ) then
			AddQuestWatch(arg1);
		end
	elseif ( event == "QUEST_WATCH_LIST_CHANGED" ) then
		OM_QuestMapFrame_UpdateQuestDetailsButtons();
		OM_QuestMapFrame_UpdateAll();
	elseif ( event == "SUPER_TRACKED_QUEST_CHANGED" ) then
		OM_QuestMapFrame_CloseQuestDetails(self:GetParent());
		local questID = ...;
		QuestPOI_SelectButtonByQuestID(OM_QuestScrollFrame.Contents, questID);
	elseif ( event == "GROUP_ROSTER_UPDATE" ) then
		if ( OM_QuestMapFrame.DetailsFrame.questID ) then
			OM_QuestMapFrame_UpdateQuestDetailsButtons();
		end

		if ( self:IsVisible() ) then
			OM_QuestMapFrame_UpdateAll();
		end
	elseif ( event == "QUEST_POI_UPDATE" ) then
		OM_QuestMapFrame_UpdateAll();
	elseif ( event == "PARTY_MEMBER_ENABLE" or event == "PARTY_MEMBER_DISABLE" ) then
		if ( self:IsVisible() ) then
			OM_QuestMapFrame_UpdateAll();
		end
	elseif ( event == "QUEST_ACCEPTED" ) then
		TUTORIAL_QUEST_ACCEPTED = arg2;
	elseif ( event == "AJ_QUEST_LOG_OPEN" ) then
		OM_OpenQuestLog();
		local questIndex = GetQuestLogIndexByID(arg1)
		local mapID = GetQuestUiMapID(arg1);
		if ( questIndex > 0 ) then
			OM_QuestMapFrame_OpenToQuestDetails(arg1);
		elseif ( mapID ~= 0 ) then
			OM_QuestMapFrame:GetParent():SetMapID(mapID);
		elseif ( arg2 and arg2 > 0) then
			OM_QuestMapFrame:GetParent():SetMapID(arg2);
		end
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then	
		self:Refresh();
	elseif ( event == "CVAR_UPDATE" ) then
		local arg1 =...;
		if ( arg1 == "QUEST_POI" ) then
			OM_QuestMapFrame_UpdateAll();
		end
	end
end

function OM_QuestMapFrame_OnHide(self)
	OM_QuestMapFrame_CloseQuestDetails(self:GetParent());
end

-- opening/closing the quest frame is different from showing/hiding because of fullscreen map mode
-- opened indicates the quest frame should show in windowed map mode
-- in fullscreen map mode the quest frame could be opened but hidden
function OM_QuestMapFrame_Open(userAction)
	if ( userAction ) then
		SetCVar("questLogOpen", 1);
	end
	if ( OM_QuestMapFrame:GetParent():CanDisplayQuestLog() ) then
		OM_QuestMapFrame_Show();
	end
end

function OM_QuestMapFrame_Close(userAction)
	if ( userAction ) then
		SetCVar("questLogOpen", 0);
	end
	OM_QuestMapFrame_Hide();
end

function OM_QuestMapFrame_Show()
	if ( not OM_QuestMapFrame:IsShown() ) then
		OM_QuestMapFrame_UpdateAll();
		OM_QuestMapFrame:Show();
		OM_QuestMapFrame:GetParent():OnQuestLogShow();
	end
end

function OM_QuestMapFrame_Hide()
	if ( OM_QuestMapFrame:IsShown() ) then
		OM_QuestMapFrame:Hide();
		OM_QuestMapFrame_UpdateAll();
		OM_QuestMapFrame_CheckTutorials();
		OM_QuestMapFrame:GetParent():OnQuestLogHide();
	end
end

function OM_QuestMapFrame_CheckTutorials()
	if (TUTORIAL_QUEST_ACCEPTED) then
		if (not IsTutorialFlagged(2)) then
			local _, raceName  = UnitRace("player");
			if ( strupper(raceName) ~= "PANDAREN" ) then
				TriggerTutorial(2);
			end
		end
		if (not IsTutorialFlagged(10) and (TUTORIAL_QUEST_ACCEPTED == TUTORIAL_QUEST_TO_WATCH)) then
			TriggerTutorial(10);
		end
		TUTORIAL_QUEST_ACCEPTED = nil;
	end
end

function OM_QuestMapFrame_UpdateAll()
	OM_QuestMapFrame:UpdatePOIs();

	local numPOIs = QuestMapUpdateAllQuests();

	if ( OM_QuestMapFrame:GetParent():IsShown() ) then
		local poiTable = { };
		if ( numPOIs > 0 and GetCVarBool("questPOI") ) then
			GetQuestPOIs(poiTable);
		end
		local questDetailID = OM_QuestMapFrame.DetailsFrame.questID;
		if ( questDetailID ) then
			-- update rewards
			SelectQuestLogEntry(GetQuestLogIndexByID(questDetailID));
			OM_QuestMapFrame_ShowQuestDetails(questDetailID);
		else
			OM_QuestLogQuests_Update(poiTable);
		end
		OM_QuestMapFrame:GetParent():OnQuestLogUpdate();
	end
end

function OM_QuestMapFrame_ResetFilters()
	local numEntries, numQuests = GetNumQuestLogEntries();
	OM_QuestMapFrame.ignoreQuestLogUpdate = true;
	for questLogIndex = 1, numEntries do
		local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(questLogIndex);
		local difficultyColor = GetQuestDifficultyColor(level, isScaling);
		if ( isHeader ) then
			if (isOnMap) then
				ExpandQuestHeader(questLogIndex, true);
			else
				CollapseQuestHeader(questLogIndex, true);
			end
		end
	end
	OM_QuestMapFrame.ignoreQuestLogUpdate = nil;
end

function OM_QuestMapFrame_ShowQuestDetails(questID)
	local questLogIndex = GetQuestLogIndexByID(questID);
	SelectQuestLogEntry(questLogIndex);
	OM_QuestMapFrame.DetailsFrame.questID = questID;
	OM_QuestMapFrame:GetParent():SetFocusedQuestID(questID);
	QuestInfo_Display(QUEST_TEMPLATE_MAP_DETAILS, OM_QuestMapFrame.DetailsFrame.ScrollFrame.Contents);
	QuestInfo_Display(QUEST_TEMPLATE_MAP_REWARDS, OM_QuestMapFrame.DetailsFrame.RewardsFrame, nil, nil, true);
	OM_QuestMapFrame.DetailsFrame.ScrollFrame.ScrollBar:SetValue(0);

	local mapFrame = OM_QuestMapFrame:GetParent();
	local questPortrait, questPortraitText, questPortraitName, questPortraitMount = GetQuestLogPortraitGiver();
	if (questPortrait and questPortrait ~= 0 and QuestLogShouldShowPortrait() and (UIParent:GetRight() - mapFrame:GetRight() > QuestNPCModel:GetWidth() + 6)) then
		QuestFrame_ShowQuestPortrait(mapFrame, questPortrait, questPortraitMount, questPortraitText, questPortraitName, -2, -43);
		QuestNPCModel:SetFrameLevel(mapFrame:GetFrameLevel() + 2);
	else
		QuestFrame_HideQuestPortrait();
	end

	-- height
	local height;
	if ( MapQuestInfoRewardsFrame:IsShown() ) then
		height = MapQuestInfoRewardsFrame:GetHeight() + 49;
	else
		height = 59;
	end
	height = min(height, 275);
	OM_QuestMapFrame.DetailsFrame.RewardsFrame:SetHeight(height);
	OM_QuestMapFrame.DetailsFrame.RewardsFrame.Background:SetTexCoord(0, 1, 0, height / 275);

	OM_QuestMapFrame.QuestsFrame:Hide();
	OM_QuestMapFrame.DetailsFrame:Show();

	-- save current view
	OM_QuestMapFrame.DetailsFrame.returnMapID = OM_QuestMapFrame:GetParent():GetMapID();
	local mapID = GetQuestUiMapID(questID);
	if ( mapID ~= 0 ) then
		OM_QuestMapFrame:GetParent():SetMapID(mapID);
	end

	OM_QuestMapFrame_UpdateQuestDetailsButtons();

	if ( IsQuestComplete(questID) and GetQuestLogIsAutoComplete(questLogIndex) ) then
		OM_QuestMapFrame.DetailsFrame.CompleteQuestFrame:Show();
		OM_QuestMapFrame.DetailsFrame.RewardsFrame:SetPoint("BOTTOMLEFT", 0, 44);
	else
		OM_QuestMapFrame.DetailsFrame.CompleteQuestFrame:Hide();
		OM_QuestMapFrame.DetailsFrame.RewardsFrame:SetPoint("BOTTOMLEFT", 0, 20);
	end

	StaticPopup_Hide("ABANDON_QUEST");
	StaticPopup_Hide("ABANDON_QUEST_WITH_ITEMS");
end

function OM_QuestMapFrame_CloseQuestDetails(optPortraitOwnerCheckFrame)
	OM_QuestMapFrame.QuestsFrame:Show();
	OM_QuestMapFrame.DetailsFrame:Hide();
	OM_QuestMapFrame.DetailsFrame.questID = nil;
	OM_QuestMapFrame:GetParent():ClearFocusedQuestID();
	OM_QuestMapFrame.DetailsFrame.returnMapID = nil;
	OM_QuestMapFrame_UpdateAll();
	QuestFrame_HideQuestPortrait(optPortraitOwnerCheckFrame);

	StaticPopup_Hide("ABANDON_QUEST");
	StaticPopup_Hide("ABANDON_QUEST_WITH_ITEMS");
end

function OM_QuestMapFrame_PingQuestID(questId)
	OM_QuestMapFrame:GetParent():PingQuestID(questId);
end

function OM_QuestMapFrame_UpdateQuestDetailsButtons()
	local questLogSelection = GetQuestLogSelection();
	local _, _, _, _, _, _, _, questID = GetQuestLogTitle(questLogSelection);
	if ( CanAbandonQuest(questID)) then
		OM_QuestMapFrame.DetailsFrame.AbandonButton:Enable();
		OM_QuestLogPopupDetailFrame.AbandonButton:Enable();
	else
		OM_QuestMapFrame.DetailsFrame.AbandonButton:Disable();
		OM_QuestLogPopupDetailFrame.AbandonButton:Disable();
	end

	if ( IsQuestWatched(questLogSelection) ) then
		OM_QuestMapFrame.DetailsFrame.TrackButton:SetText(UNTRACK_QUEST_ABBREV);
		OM_QuestLogPopupDetailFrame.TrackButton:SetText(UNTRACK_QUEST_ABBREV);
	else
		OM_QuestMapFrame.DetailsFrame.TrackButton:SetText(TRACK_QUEST_ABBREV);
		OM_QuestLogPopupDetailFrame.TrackButton:SetText(TRACK_QUEST_ABBREV);
	end

	if ( GetQuestLogPushable() and IsInGroup() ) then
		OM_QuestMapFrame.DetailsFrame.ShareButton:Enable();
		OM_QuestLogPopupDetailFrame.ShareButton:Enable();
	else
		OM_QuestMapFrame.DetailsFrame.ShareButton:Disable();
		OM_QuestLogPopupDetailFrame.ShareButton:Disable();
	end
end

function OM_QuestMapFrame_ReturnFromQuestDetails()
	if ( OM_QuestMapFrame.DetailsFrame.returnMapID ) then
		OM_QuestMapFrame:GetParent():SetMapID(OM_QuestMapFrame.DetailsFrame.returnMapID);
	end
	OM_QuestMapFrame_CloseQuestDetails();
end

function OM_QuestMapFrame_OpenToQuestDetails(questID)
	OM_OpenQuestLog();
	OM_QuestMapFrame_ShowQuestDetails(questID);
end

function OM_QuestMapFrame_GetDetailQuestID()
	return OM_QuestMapFrame.DetailsFrame.questID;
end

function OM_QuestMapFrame_UpdateAllQuestCriteria()
	for questID, _ in pairs(OM_QuestMapFrame.completedCriteria) do
		if (not IsQuestTask(questID) and GetQuestLogIndexByID(questID) == 0) then
			OM_QuestMapFrame.completedCriteria[questID] = nil;
		end
	end
end

function OM_QuestMapFrame_CheckQuestCriteria(questID, criteriaID, description, fulfilled, required)
	if (fulfilled == required) then
		if (OM_QuestMapFrame.completedCriteria[questID] and OM_QuestMapFrame.completedCriteria[questID][criteriaID]) then
			return false;
		end
		if (not OM_QuestMapFrame.completedCriteria[questID]) then
			OM_QuestMapFrame.completedCriteria[questID] = {};
		end
		OM_QuestMapFrame.completedCriteria[questID][criteriaID] = true;
	end

	return true;
end

-- Quests Frame

function OM_QuestsFrame_OnLoad(self)
	ScrollFrame_OnLoad(self);
	self.Contents.StoryHeader.HighlightTexture:SetVertexColor(0.243, 0.570, 1);
	self.Contents.WarCampaignHeader.HighlightTexture:SetVertexColor(0.243, 0.570, 1);
	self.StoryTooltip:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
	self.StoryTooltip:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);

	self.titleFramePool = CreateFramePool("BUTTON", OM_QuestMapFrame.QuestsFrame.Contents, "OM_QuestLogTitleTemplate");
	self.objectiveFramePool = CreateFramePool("FRAME", OM_QuestMapFrame.QuestsFrame.Contents, "OM_QuestLogObjectiveTemplate");
	self.headerFramePool = CreateFramePool("BUTTON", OM_QuestMapFrame.QuestsFrame.Contents, "OM_QuestLogHeaderTemplate");
end

-- *****************************************************************************************************
-- ***** QUEST OPTIONS DROPDOWN
-- *****************************************************************************************************

function OM_QuestMapQuestOptionsDropDown_Initialize(self)
	local questLogIndex = GetQuestLogIndexByID(self.questID);
	local info = UIDropDownMenu_CreateInfo();
	info.isNotRadio = true;
	info.notCheckable = true;

	info.text = TRACK_QUEST;
	if ( IsQuestWatched(questLogIndex) ) then
		info.text = UNTRACK_QUEST;
	end
	info.func =function(_, questID) OM_QuestMapQuestOptions_TrackQuest(questID) end;
	info.arg1 = self.questID;
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

	info.text = SHARE_QUEST;
	info.func = function(_, questID) OM_QuestMapQuestOptions_ShareQuest(questID) end;
	info.arg1 = self.questID;
	if ( not GetQuestLogPushable(questLogIndex) or not IsInGroup() ) then
		info.disabled = 1;
	end
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

	if CanAbandonQuest(self.questID) then
		info.text = ABANDON_QUEST;
		info.func = function(_, questID) OM_QuestMapQuestOptions_ShareQuest(questID) end;
		info.arg1 = self.questID;
		info.disabled = nil;
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
	end
end

function OM_QuestMapQuestOptions_TrackQuest(questID)
	local questLogIndex = GetQuestLogIndexByID(questID);
	if ( IsQuestWatched(questLogIndex) ) then
		QuestObjectiveTracker_UntrackQuest(nil, questID);
	else
		AddQuestWatch(questLogIndex, true);
		QuestSuperTracking_OnQuestTracked(questID);
	end
end

function OM_QuestMapQuestOptions_ShareQuest(questID)
	local questLogIndex = GetQuestLogIndexByID(questID);
	QuestLogPushQuest(questLogIndex);
	PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN);
end

function OM_QuestMapQuestOptions_ShareQuest(questID)
	local lastQuestIndex = GetQuestLogSelection();
	SelectQuestLogEntry(GetQuestLogIndexByID(questID));
	SetAbandonQuest();
	local items = GetAbandonQuestItems();
	if ( items ) then
		StaticPopup_Hide("ABANDON_QUEST");
		StaticPopup_Show("ABANDON_QUEST_WITH_ITEMS", GetAbandonQuestName(), items);
	else
		StaticPopup_Hide("ABANDON_QUEST_WITH_ITEMS");
		StaticPopup_Show("ABANDON_QUEST", GetAbandonQuestName());
	end
	SelectQuestLogEntry(lastQuestIndex);
end

-- *****************************************************************************************************
-- ***** QUEST LIST
-- *****************************************************************************************************

function OM_QuestLogQuests_AddQuestButton(prevButton, questLogIndex, poiTable, title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling, layoutIndex)
	local totalHeight = 8;
	local button = OM_QuestScrollFrame.titleFramePool:Acquire();
	button.questID = questID;
	local difficultyColor = GetQuestDifficultyColor(level, isScaling);

	if ( displayQuestID ) then
		title = questID.." - "..title;
	end
	if ( ENABLE_COLORBLIND_MODE == "1" ) then
		title = "["..level.."] " .. title;
	end

	-- If not a header see if any nearby group mates are on this quest
	local partyMembersOnQuest = 0;
	for j=1, GetNumSubgroupMembers() do
		if ( IsUnitOnQuestByQuestID(questID, "party"..j) ) then
			partyMembersOnQuest = partyMembersOnQuest + 1;
		end
	end

	if ( partyMembersOnQuest > 0 ) then
		title = "["..partyMembersOnQuest.."] "..title;
	end

	button.Text:SetText(title);
	button.Text:SetTextColor( difficultyColor.r, difficultyColor.g, difficultyColor.b );

	totalHeight = totalHeight + button.Text:GetHeight();
	if ( IsQuestHardWatched(questLogIndex) ) then
		button.Check:Show();
		button.Check:SetPoint("LEFT", button.Text, button.Text:GetWrappedWidth() + 2, 0);
	else
		button.Check:Hide();
	end

	-- tag. daily icon can be alone or before other icons except for COMPLETED or FAILED
	local tagID;
	local questTagID, tagName = GetQuestTagInfo(questID);
	if ( isComplete and isComplete < 0 ) then
		tagID = "FAILED";
	elseif ( isComplete and isComplete > 0 ) then
		tagID = "COMPLETED";
	elseif( questTagID and questTagID == QUEST_TAG_ACCOUNT ) then
		local factionGroup = GetQuestFactionGroup(questID);
		if( factionGroup ) then
			if ( factionGroup == LE_QUEST_FACTION_HORDE ) then
				tagID = "HORDE";
			else
				tagID = "ALLIANCE";
			end
		else
			tagID = QUEST_TAG_ACCOUNT;
		end
	elseif( frequency == LE_QUEST_FREQUENCY_DAILY and (not isComplete or isComplete == 0) ) then
		tagID = "DAILY";
	elseif( frequency == LE_QUEST_FREQUENCY_WEEKLY and (not isComplete or isComplete == 0) )then
		tagID = "WEEKLY";
	elseif( questTagID ) then
		tagID = questTagID;
	end

	if ( tagID ) then
		local tagCoords = QUEST_TAG_TCOORDS[tagID];
		if( tagCoords ) then
			button.TagTexture:SetTexCoord( unpack(tagCoords) );
			button.TagTexture:Show();
		else
			button.TagTexture:Hide();
		end
	else
		button.TagTexture:Hide();
	end

	-- POI/objectives
	local requiredMoney = GetQuestLogRequiredMoney(questLogIndex);
	local playerMoney = GetMoney();
	local numObjectives = GetNumQuestLeaderBoards(questLogIndex);
	-- complete?
	if ( isComplete and isComplete < 0 ) then
		isComplete = false;
	elseif ( numObjectives == 0 and playerMoney >= requiredMoney and not startEvent) then
		isComplete = true;
	end
	-- objectives
	if ( isComplete ) then
		local objectiveFrame = OM_QuestScrollFrame.objectiveFramePool:Acquire();
		objectiveFrame.questID = questID;
		objectiveFrame:Show();
		local completionText = GetQuestLogCompletionText(questLogIndex) or QUEST_WATCH_QUEST_READY;
		objectiveFrame.Text:SetText(completionText);
		local height = objectiveFrame.Text:GetStringHeight();
		objectiveFrame:SetHeight(height);
		objectiveFrame:SetPoint("TOPLEFT", button.Text, "BOTTOMLEFT", 0, -3);
		totalHeight = totalHeight + height + 3;
	else
		local prevObjective;
		for i = 1, numObjectives do
			local text, objectiveType, finished = GetQuestLogLeaderBoard(i, questLogIndex);
			if ( text and not finished ) then
				local objectiveFrame = OM_QuestScrollFrame.objectiveFramePool:Acquire();
				objectiveFrame.questID = questID;
				objectiveFrame:Show();
				objectiveFrame.Text:SetText(text);
				local height = objectiveFrame.Text:GetStringHeight();
				objectiveFrame:SetHeight(height);
				if ( prevObjective ) then
					objectiveFrame:SetPoint("TOPLEFT", prevObjective, "BOTTOMLEFT", 0, -2);
					height = height + 2;
				else
					objectiveFrame:SetPoint("TOPLEFT", button.Text, "BOTTOMLEFT", 0, -3);
					height = height + 3;
				end
				totalHeight = totalHeight + height;
				prevObjective = objectiveFrame;
			end
		end
		if ( requiredMoney > playerMoney ) then
			local objectiveFrame = OM_QuestScrollFrame.objectiveFramePool:Aquire();
			objectiveFrame.questID = questID;
			objectiveFrame:Show();
			objectiveFrame.Text:SetText(GetMoneyString(playerMoney).." / "..GetMoneyString(requiredMoney));
			local height = objectiveFrame.Text:GetStringHeight();
			objectiveFrame:SetHeight(height);
			if ( prevObjective ) then
				objectiveFrame:SetPoint("TOPLEFT", prevObjective, "BOTTOMLEFT", 0, -2);
				height = height + 2;
			else
				objectiveFrame:SetPoint("TOPLEFT", button.Text, "BOTTOMLEFT", 0, -3);
				height = height + 3;
			end
			totalHeight = totalHeight + height;
		end
	end
	-- POI

	if ( hasLocalPOI and GetCVarBool("questPOI") ) then
		local poiButton;
		if ( isComplete ) then
			poiButton = QuestPOI_GetButton(OM_QuestScrollFrame.Contents, questID, "normal", nil);
		else
			for i = 1, #poiTable do
				if ( poiTable[i] == questID ) then
					poiButton = QuestPOI_GetButton(OM_QuestScrollFrame.Contents, questID, "numeric", i);
					break;
				end
			end
		end
		if ( poiButton ) then
			poiButton:SetPoint("TOPLEFT", button, 6, -4);
			poiButton.parent = button;
		end
		-- extra room because of POI icon
		totalHeight = totalHeight + 6;
		button.Text:SetPoint("TOPLEFT", 31, -8);
	else
		button.Text:SetPoint("TOPLEFT", 31, -4);
	end

	button:SetHeight(totalHeight);
	button.questLogIndex = questLogIndex;
	button:ClearAllPoints();
	if ( prevButton ) then
		button:SetPoint("TOPLEFT", prevButton, "BOTTOMLEFT", 0, 0);
	else
		button:SetPoint("TOPLEFT", 1, -6);
	end
	button.layoutIndex = layoutIndex;
	button:Show();
	prevButton = button;

	return prevButton;
end

function OM_QuestLogQuests_Update(poiTable)
	local numEntries, numQuests = GetNumQuestLogEntries();

	OM_QuestScrollFrame.titleFramePool:ReleaseAll();
	OM_QuestScrollFrame.objectiveFramePool:ReleaseAll();
	OM_QuestScrollFrame.headerFramePool:ReleaseAll();

	local mapID = OM_QuestMapFrame:GetParent():GetMapID();

	local button, prevButton;

	QuestPOI_ResetUsage(OM_QuestScrollFrame.Contents);

	local storyAchievementID, storyMapID = C_QuestLog.GetZoneStoryInfo(mapID);
	local warCampaignID = C_CampaignInfo.GetCurrentCampaignID();
	local warCampaignShown = false;
	local warCampaignComplete = false;

	if ( warCampaignID ) then
		local warCampaignInfo = C_CampaignInfo.GetCampaignInfo(warCampaignID);
		if (warCampaignInfo and warCampaignInfo.visibilityConditionMatched) then
			local campaignHeader = OM_QuestScrollFrame.Contents.WarCampaignHeader;
			local campaignNextObj = OM_QuestScrollFrame.Contents.WarCampaignNextObjective;
			local separator = OM_QuestScrollFrame.Contents.Separator;
			SetupTextureKits(warCampaignInfo.uiTextureKitID, campaignHeader, WarCampaignTextureKitInfo);
			local campaignChapterID = C_CampaignInfo.GetCurrentCampaignChapterID();
			if ( warCampaignInfo.complete ) then
				warCampaignComplete = true;
				campaignHeader.Progress:SetText(WAR_CAMPAIGN_TO_BE_CONTINUED);
				campaignHeader.Progress:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB());
				campaignHeader.Background:SetDesaturated(true);
				campaignHeader.Text:SetTextColor(DISABLED_FONT_COLOR:GetRGB());
				campaignNextObj:Hide();
			elseif (campaignChapterID) then
				local campaignChapterInfo = C_CampaignInfo.GetCampaignChapterInfo(campaignChapterID);		
				if (campaignChapterInfo) then
					campaignHeader.Progress:SetText(campaignChapterInfo.name);
					campaignHeader.Progress:SetTextColor(NORMAL_FONT_COLOR:GetRGB());
				else
					campaignHeader.Progress:SetText("");
				end
				campaignNextObj:Hide();
				campaignHeader.Background:SetDesaturated(false);
				campaignHeader.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB());
			else
				campaignNextObj.Text:SetText(warCampaignInfo.playerConditionFailedReason);
				campaignNextObj.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB());
				campaignNextObj:Show();
				campaignNextObj:SetHeight(campaignNextObj.Text:GetHeight() + 12);
				campaignHeader.Progress:SetText("");
				campaignHeader.Background:SetDesaturated(false);
				campaignHeader.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB());
			end
			campaignHeader.Text:SetText(warCampaignInfo.name);
			campaignHeader:Show();
			warCampaignShown = true;
		end
	end

	if (warCampaignShown) then
		local separator = OM_QuestScrollFrame.Contents.Separator;
		if (warCampaignComplete) then
			separator:Hide();
		else
			if (storyAchievementID) then
				separator.Divider:SetAtlas("ZoneStory_Divider", true);
			else
				separator.Divider:SetAtlas("QuestLog_Divider", true);
			end
			separator:Show();
		end
	else
		OM_QuestScrollFrame.Contents.WarCampaignHeader:Hide();
		OM_QuestScrollFrame.Contents.WarCampaignNextObjective:Hide();
		OM_QuestScrollFrame.Contents.Separator:Hide();
	end

	if ( storyAchievementID ) then
		OM_QuestScrollFrame.Contents.StoryHeader:Show();
		local mapInfo = C_Map.GetMapInfo(storyMapID);
		OM_QuestScrollFrame.Contents.StoryHeader.Text:SetText(mapInfo and mapInfo.name or nil);
		local numCriteria = GetAchievementNumCriteria(storyAchievementID);
		local completedCriteria = 0;
		for i = 1, numCriteria do
			local _, _, completed = GetAchievementCriteriaInfo(storyAchievementID, i);
			if ( completed ) then
				completedCriteria = completedCriteria + 1;
			end
		end
		OM_QuestScrollFrame.Contents.StoryHeader.Progress:SetFormattedText(QUEST_STORY_STATUS, completedCriteria, numCriteria);
		prevButton = OM_QuestScrollFrame.Contents.StoryHeader;
	else
		OM_QuestScrollFrame.Contents.StoryHeader:Hide();
	end

	local headerCollapsed = false;
	local headerTitle, headerOnMap, headerShown, headerLogIndex, mapHeaderButtonIndex;
	local noHeaders = true;

	OM_QuestMapFrame:ResetLayoutIndexManager();

	for questLogIndex = 1, numEntries do
		local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(questLogIndex);
		if ( isHeader ) then
			headerTitle = title;
			headerOnMap = isOnMap;
			headerShown = false;
			headerLogIndex = questLogIndex;
			headerCollapsed = isCollapsed;
		elseif ( not isTask and not isHidden and (not isBounty or IsQuestComplete(questID))) then
			-- we have at least one valid entry, show the header for it
			if ( not headerShown and not C_CampaignInfo.IsCampaignQuest(questID) ) then
				headerShown = true;
				noHeaders = false;
				button = OM_QuestScrollFrame.headerFramePool:Acquire();
				if (headerCollapsed) then
					button:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
				else
					button:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
				end
				button:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight");
				if ( headerTitle ) then
					button:SetText(headerTitle);
					button:SetHitRectInsets(0, -button.ButtonText:GetWidth(), 0, 0);
				else
					button:SetText("");
					button:SetHitRectInsets(0, 0, 0, 0);
				end
				button:ClearAllPoints();
				if ( prevButton ) then
					button:SetPoint("TOPLEFT", prevButton, "BOTTOMLEFT", 0, 0);
				else
					button:SetPoint("TOPLEFT", 1, -6);
				end
				button.layoutIndex = OM_QuestMapFrame:GetManagedLayoutIndex("Other");
				button:Show();
				button.questLogIndex = headerLogIndex;
				prevButton = button;
			end

			if (not headerCollapsed or C_CampaignInfo.IsCampaignQuest(questID)) then
				local layoutKey = "Other";
				if (C_CampaignInfo.IsCampaignQuest(questID)) then
					layoutKey = "Campaign";
				end
				prevButton = OM_QuestLogQuests_AddQuestButton(prevButton, questLogIndex, poiTable, title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling, OM_QuestMapFrame:GetManagedLayoutIndex(layoutKey));
			end
		end
	end

	-- background
	if ( OM_QuestScrollFrame.titleFramePool:GetNumActive() == 0 and noHeaders ) then
		OM_QuestScrollFrame.Background:SetAtlas("NoQuestsBackground", true);
	else
		OM_QuestScrollFrame.Background:SetAtlas("QuestLogBackground", true);
	end

	QuestPOI_SelectButtonByQuestID(OM_QuestScrollFrame.Contents, GetSuperTrackedQuestID());

	-- clean up
	QuestPOI_HideUnusedButtons(OM_QuestScrollFrame.Contents);

	OM_QuestScrollFrame.Contents:Layout();
end

function OM_ToggleQuestLog()
	if ( OM_QuestMapFrame:IsShown() and OM_QuestMapFrame:IsVisible() ) then
		HideUIPanel(OM_QuestMapFrame:GetParent());
	else
		OM_OpenQuestLog();
	end
end

function OM_OpenQuestLog(mapID)
	OM_QuestMapFrame:GetParent():OnQuestLogOpen();
	ShowUIPanel(OM_QuestMapFrame:GetParent());
	OM_QuestMapFrame_Open();

	if mapID then
		OM_QuestMapFrame:GetParent():SetMapID(mapID);
	end
end

function OM_QuestMapLogHeaderButton_OnClick(self, button)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	if ( button == "LeftButton" ) then
		local _, _, _, _, isCollapsed = GetQuestLogTitle(self.questLogIndex);
		if (isCollapsed) then
			ExpandQuestHeader(self.questLogIndex);
		else
			CollapseQuestHeader(self.questLogIndex);
		end
	end
end

function OM_QuestMapLogTitleButton_OnEnter(self)
	--if (self.questLogIndex > GetNumQuestLogEntries()) then
	--	return;
	--end
	-- do block highlight
	local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(self.questLogIndex);
	local _, difficultyHighlightColor = GetQuestDifficultyColor(level, isScaling);
	if ( isHeader ) then
		_, difficultyHighlightColor = QuestDifficultyColors["header"];
	end
	self.Text:SetTextColor( difficultyHighlightColor.r, difficultyHighlightColor.g, difficultyHighlightColor.b );

	for line in OM_QuestScrollFrame.objectiveFramePool:EnumerateActive() do
		if ( line.questID == self.questID ) then
			line.Text:SetTextColor(1, 1, 1);
		end
	end

	OM_QuestMapFrame:GetParent():SetHighlightedQuestID(self.questID);
	
	GameTooltip:ClearAllPoints();
	GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 34, 0);
	GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
	GameTooltip:SetText(title);
	local tooltipWidth = 20 + max(231, GameTooltipTextLeft1:GetStringWidth());
	if ( tooltipWidth > UIParent:GetRight() - OM_QuestMapFrame:GetParent():GetRight() ) then
		GameTooltip:ClearAllPoints();
		GameTooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", -5, 0);
		GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
		GameTooltip:SetText(title);
	end

	-- quest tag
	local tagID, tagName, worldQuestType = GetQuestTagInfo(questID);
	if ( tagName ) then
		local factionGroup = GetQuestFactionGroup(questID);
		-- Faction-specific account quests have additional info in the tooltip
		if ( tagID == QUEST_TAG_ACCOUNT and factionGroup ) then
			local factionString = FACTION_ALLIANCE;
			if ( factionGroup == LE_QUEST_FACTION_HORDE ) then
				factionString = FACTION_HORDE;
			end
			tagName = format("%s (%s)", tagName, factionString);
		end

		local overrideQuestTag = tagID;
		if ( QUEST_TAG_TCOORDS[tagID] ) then
			if ( tagID == QUEST_TAG_ACCOUNT and factionGroup ) then
				overrideQuestTag = "ALLIANCE";
				if ( factionGroup == LE_QUEST_FACTION_HORDE ) then
					overrideQuestTag = "HORDE";
				end
			end
		end

		QuestUtils_AddQuestTagLineToTooltip(GameTooltip, tagName, overrideQuestTag, worldQuestType, NORMAL_FONT_COLOR);
	end

	if ( frequency == LE_QUEST_FREQUENCY_DAILY ) then
		QuestUtils_AddQuestTagLineToTooltip(GameTooltip, DAILY, "DAILY", nil, NORMAL_FONT_COLOR);
	elseif ( frequency == LE_QUEST_FREQUENCY_WEEKLY ) then
		QuestUtils_AddQuestTagLineToTooltip(GameTooltip, WEEKLY, "WEEKLY", nil, NORMAL_FONT_COLOR);
	end

	if ( isComplete and isComplete < 0 ) then
		QuestUtils_AddQuestTagLineToTooltip(GameTooltip, FAILED, "FAILED", nil, RED_FONT_COLOR);
	end

	GameTooltip:AddLine(" ");

	-- description
	if ( isComplete and isComplete > 0 ) then
		local completionText = GetQuestLogCompletionText(self.questLogIndex) or QUEST_WATCH_QUEST_READY;
		GameTooltip:AddLine(completionText, 1, 1, 1, true);
		GameTooltip:AddLine(" ");
	else
		local needsSeparator = false;
		local _, objectiveText = GetQuestLogQuestText(self.questLogIndex);
		GameTooltip:AddLine(objectiveText, 1, 1, 1, true);
		GameTooltip:AddLine(" ");
		local requiredMoney = GetQuestLogRequiredMoney(self.questLogIndex);
		local numObjectives = GetNumQuestLeaderBoards(self.questLogIndex);
		for i = 1, numObjectives do
			local text, objectiveType, finished = GetQuestLogLeaderBoard(i, self.questLogIndex);
			if ( text ) then
				local color = HIGHLIGHT_FONT_COLOR;
				if ( finished ) then
					color = GRAY_FONT_COLOR;
				end
				GameTooltip:AddLine(QUEST_DASH..text, color.r, color.g, color.b, true);
				needsSeparator = true;
			end
		end
		if ( requiredMoney > 0 ) then
			local playerMoney = GetMoney();
			local color = HIGHLIGHT_FONT_COLOR;
			if ( requiredMoney <= playerMoney ) then
				playerMoney = requiredMoney;
				color = GRAY_FONT_COLOR;
			end
			GameTooltip:AddLine(QUEST_DASH..GetMoneyString(playerMoney).." / "..GetMoneyString(requiredMoney), color.r, color.g, color.b);
			needsSeparator = true;
		end

		if ( needsSeparator ) then
			GameTooltip:AddLine(" ");
		end
	end

	GameTooltip:AddLine(CLICK_QUEST_DETAILS, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);

	local partyMembersOnQuest = 0;
	for i=1, GetNumSubgroupMembers() do
		if ( IsUnitOnQuestByQuestID(self.questID, "party"..i) ) then
			--Add the header line if this the first party member found that is on the quest.
			if ( partyMembersOnQuest == 0 ) then
				GameTooltip:AddLine(" ");
				GameTooltip:AddLine(PARTY_QUEST_STATUS_ON);
			end
			partyMembersOnQuest = partyMembersOnQuest + 1;
			GameTooltip:AddLine(LIGHTYELLOW_FONT_COLOR_CODE..GetUnitName("party"..i, true)..FONT_COLOR_CODE_CLOSE);
		end
	end

	GameTooltip:Show();
	tooltipButton = self;
end

function OM_QuestMapLogTitleButton_OnLeave(self)
	-- remove block highlight
	local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(self.questLogIndex);
	local difficultyColor = GetQuestDifficultyColor(level, isScaling);
	if ( isHeader ) then
		difficultyColor = QuestDifficultyColors["header"];
	end
	self.Text:SetTextColor( difficultyColor.r, difficultyColor.g, difficultyColor.b );
	for line in OM_QuestScrollFrame.objectiveFramePool:EnumerateActive() do
		if ( line.questID == self.questID ) then
			line.Text:SetTextColor(0.8, 0.8, 0.8);
		end
	end

	OM_QuestMapFrame:GetParent():ClearHighlightedQuestID();
	GameTooltip:Hide();
	tooltipButton = nil;
end

function OM_QuestMapLogTitleButton_OnClick(self, button)
	if ( ChatEdit_TryInsertQuestLinkForQuestID(self.questID) ) then
		return;
	end

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);

	if ( IsShiftKeyDown() ) then
		OM_QuestMapQuestOptions_TrackQuest(self.questID);
	else
		if ( button == "RightButton" ) then
			if ( self.questID ~= OM_QuestMapQuestOptionsDropDown.questID ) then
				CloseDropDownMenus();
			end
			OM_QuestMapQuestOptionsDropDown.questID = self.questID;
			ToggleDropDownMenu(1, nil, OM_QuestMapQuestOptionsDropDown, "cursor", 6, -6);
		else
			OM_QuestMapFrame_ShowQuestDetails(self.questID);
		end
	end
end

function OM_QuestMapLogTitleButton_OnMouseDown(self)
	local anchor, _, _, x, y = self.Text:GetPoint();
	self.Text:SetPoint(anchor, x + 1, y - 1);
	anchor, _, _, x, y = self.TagTexture:GetPoint(2);
	self.TagTexture:SetPoint(anchor, x + 1, y - 1);
end

function OM_QuestMapLogTitleButton_OnMouseUp(self)
	local anchor, _, _, x, y = self.Text:GetPoint();
	self.Text:SetPoint(anchor, x - 1, y + 1);
	anchor, _, _, x, y = self.TagTexture:GetPoint(2);
	self.TagTexture:SetPoint(anchor, x - 1, y + 1);
end

function OM_QuestMapLog_ShowStoryTooltip(self)
	local tooltip = OM_QuestScrollFrame.StoryTooltip;
	local mapID = OM_QuestMapFrame:GetParent():GetMapID();
	local storyAchievementID, storyMapID = C_QuestLog.GetZoneStoryInfo(mapID);
	local maxWidth = 0;
	local totalHeight = 0;

	local mapInfo = C_Map.GetMapInfo(OM_QuestMapFrame:GetParent():GetMapID());
	tooltip.Title:SetText(mapInfo.name);
	totalHeight = totalHeight + tooltip.Title:GetHeight();
	maxWidth = tooltip.Title:GetWidth();

	-- Clear out old quest criteria
	for i = 1, #tooltip.Lines do
		tooltip.Lines[i]:Hide();
	end
	for _, checkMark in pairs(tooltip.CheckMarks) do
		checkMark:Hide();
	end

	local numCriteria = GetAchievementNumCriteria(storyAchievementID);
	local completedCriteria = 0;
	for i = 1, numCriteria do
		local title, _, completed = GetAchievementCriteriaInfo(storyAchievementID, i);
		if ( completed ) then
			completedCriteria = completedCriteria + 1;
		end
		if ( not tooltip.Lines[i] ) then
			local fontString = tooltip:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
			fontString:SetPoint("TOP", tooltip.Lines[i-1], "BOTTOM", 0, -6);
			tooltip.Lines[i] = fontString;
		end
		if ( completed ) then
			tooltip.Lines[i]:SetText(GREEN_FONT_COLOR_CODE..title..FONT_COLOR_CODE_CLOSE);
			tooltip.Lines[i]:SetPoint("LEFT", 30, 0);
			if ( not tooltip.CheckMarks[i] ) then
				local texture = tooltip:CreateTexture(nil, "ARTWORK", "GreenCheckMarkTemplate");
				texture:ClearAllPoints();
				texture:SetPoint("RIGHT", tooltip.Lines[i], "LEFT", -4, -1);
				tooltip.CheckMarks[i] = texture;
			end
			tooltip.CheckMarks[i]:Show();
			maxWidth = max(maxWidth, tooltip.Lines[i]:GetWidth() + 20);
		else
			tooltip.Lines[i]:SetText(title);
			tooltip.Lines[i]:SetPoint("LEFT", 10, 0);
			if ( tooltip.CheckMarks[i] ) then
				tooltip.CheckMarks[i]:Hide();
			end
			maxWidth = max(maxWidth, tooltip.Lines[i]:GetWidth());
		end
		tooltip.Lines[i]:Show();
		totalHeight = totalHeight + tooltip.Lines[i]:GetHeight() + 6;
	end

	tooltip.ProgressCount:SetFormattedText(STORY_CHAPTERS, completedCriteria, numCriteria);
	maxWidth = max(maxWidth, tooltip.ProgressLabel:GetWidth(), tooltip.ProgressCount:GetWidth());
	totalHeight = totalHeight + tooltip.ProgressLabel:GetHeight() + tooltip.ProgressCount:GetHeight();

	tooltip:ClearAllPoints();
	local tooltipWidth = max(MIN_STORY_TOOLTIP_WIDTH, maxWidth + 20);
	if ( tooltipWidth > UIParent:GetRight() - OM_QuestMapFrame:GetParent():GetRight() ) then
		tooltip:SetPoint("TOPRIGHT", self:GetParent().StoryHeader, "TOPLEFT", -5, 0);
	else
		tooltip:SetPoint("TOPLEFT", self:GetParent().StoryHeader, "TOPRIGHT", 27, 0);
	end
	tooltip:SetSize(tooltipWidth, totalHeight + 42);
	tooltip:Show();
end

function OM_QuestMapLog_HideStoryTooltip(self)
	OM_QuestScrollFrame.StoryTooltip:Hide();
end

function OM_QuestMapLog_ShowWarCampaignTooltip(self)
	local tooltip = OM_QuestScrollFrame.WarCampaignTooltip;
	
	local warCampaignQuestID = C_CampaignInfo.GetCurrentCampaignID();

	tooltip:SetWarCampaign(warCampaignQuestID);
	tooltip:ClearAllPoints();
	if (tooltip:GetWidth() > UIParent:GetRight() - WorldMapFrame:GetRight()) then
		tooltip:SetPoint("TOPRIGHT", self:GetParent().WarCampaignHeader, "TOPLEFT", -5, 0);
	else
		tooltip:SetPoint("TOPLEFT", self:GetParent().WarCampaignHeader, "TOPRIGHT", 27, 0);
	end
	tooltip:Show();
end

function OM_QuestMapLog_HideWarCampaignTooltip(self)
	OM_QuestScrollFrame.WarCampaignTooltip:Hide();
end

-- *****************************************************************************************************
-- ***** POPUP DETAIL FRAME
-- *****************************************************************************************************

function OM_QuestLogPopupDetailFrame_OnLoad(self)
	self.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", self.ScrollFrame, "TOPRIGHT", 6, -14);
end

function OM_QuestLogPopupDetailFrame_OnHide(self)
	self.questID = nil;
	PlaySound(SOUNDKIT.IG_QUEST_LOG_CLOSE);
end

function OM_QuestLogPopupDetailFrame_Show(questLogIndex)

	local questID = select(8, GetQuestLogTitle(questLogIndex));
	if ( OM_QuestLogPopupDetailFrame.questID == questID and OM_QuestLogPopupDetailFrame:IsShown() ) then
		HideUIPanel(OM_QuestLogPopupDetailFrame);
		return;
	end

	OM_QuestLogPopupDetailFrame.questID = questID;

	local questLogIndex = GetQuestLogIndexByID(questID);

	SelectQuestLogEntry(questLogIndex);
	StaticPopup_Hide("ABANDON_QUEST");
	StaticPopup_Hide("ABANDON_QUEST_WITH_ITEMS");
	SetAbandonQuest();

	OM_QuestMapFrame_UpdateQuestDetailsButtons();

	QuestLogPopupDetailFrame_Update(true);
	ShowUIPanel(OM_QuestLogPopupDetailFrame);
	PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN);

	-- portrait
	local questPortrait, questPortraitText, questPortraitName, questPortraitMount = GetQuestLogPortraitGiver();
	if (questPortrait and questPortrait ~= 0 and QuestLogShouldShowPortrait()) then
		QuestFrame_ShowQuestPortrait(OM_QuestLogPopupDetailFrame, questPortrait, questPortraitMount, questPortraitText, questPortraitName, -3, -42);
	else
		QuestFrame_HideQuestPortrait();
	end
end

function QuestLogPopupDetailFrame_Update(resetScrollBar)
	QuestInfo_Display(QUEST_TEMPLATE_LOG, OM_QuestLogPopupDetailFrame.ScrollFrame.ScrollChild)
	if ( resetScrollBar ) then
		OM_QuestLogPopupDetailFrame.ScrollFrame.ScrollBar:SetValue(0);
	end
end