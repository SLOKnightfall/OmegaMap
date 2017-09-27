
local MIN_STORY_TOOLTIP_WIDTH = 240;

local OM_tooltipButton;

function OmegaMapQuestFrame_OnLoad(self)
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
	self:RegisterEvent("WORLD_MAP_UPDATE");

	self.completedCriteria = {};
	QuestPOI_Initialize(OM_QuestScrollFrame.Contents);
	OmegaMapQuestOptionsDropDown.questID = 0;		-- for OmegaMapQuestOptionsDropDown_Initialize
	Lib_UIDropDownMenu_Initialize(OmegaMapQuestOptionsDropDown, OmegaMapQuestOptionsDropDown_Initialize, "MENU");
end

function OmegaMapQuestFrame_OnEvent(self, event, ...)
	if not ( OmegaMapQuestFrame:IsShown() and OmegaMapQuestFrame:IsVisible() ) then
		return
	end
	local arg1 = ...;
	if ( (event == "QUEST_LOG_UPDATE" or (event == "UNIT_QUEST_LOG_CHANGED" and arg1 == "player")) and not self.ignoreQuestLogUpdate ) then
		if (not IsTutorialFlagged(55) and TUTORIAL_QUEST_TO_WATCH) then
			local isComplete = select(6, GetQuestLogTitle(GetQuestLogIndexByID(TUTORIAL_QUEST_TO_WATCH)));
			if (isComplete) then
				TriggerTutorial(55);
			end
		end

		if ( OM_tooltipButton ) then
			OmegaMapQuestLogTitleButton_OnEnter(OM_tooltipButton);
		end

		local updateButtons = false;
		if ( OM_QuestLogPopupDetailFrame.questID ) then
			if ( GetQuestLogIndexByID(OM_QuestLogPopupDetailFrame.questID) == 0 ) then
				HideUIPanel(OM_QuestLogPopupDetailFrame);
			else
				OM_QuestLogPopupDetailFrame_Update();
				updateButtons = true;
			end
		end		
		local questDetailID = OmegaMapQuestFrame.DetailsFrame.questID;
		if ( questDetailID ) then
			if ( GetQuestLogIndexByID(questDetailID) == 0 ) then
				-- this will call OmegaMapQuestFrame_UpdateAll
				OmegaMapQuestFrame_ReturnFromQuestDetails();
				return;
			else
				updateButtons = true;
			end
		end
		if ( updateButtons ) then
			OmegaMapQuestFrame_UpdateQuestDetailsButtons();
		end
		OmegaMapQuestFrame_UpdateAll();
		OmegaMapQuestFrame_UpdateAllQuestCriteria();
		if ( tooltipButton ) then
			OmegaMapQuestLogTitleButton_OnEnter(tooltipButton);
		end
	elseif ( event == "QUEST_LOG_CRITERIA_UPDATE" ) then
		local questID, criteriaID, description, fulfilled, required = ...;

		if (OmegaMapQuestFrame_CheckQuestCriteria(questID, criteriaID, description, fulfilled, required)) then
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
		OmegaMapQuestFrame_UpdateQuestDetailsButtons();
		OmegaMapQuestFrame_UpdateAll();
	elseif ( event == "SUPER_TRACKED_QUEST_CHANGED" ) then
		local questID = ...;
		QuestPOI_SelectButtonByQuestID(OM_QuestScrollFrame.Contents, questID);
	elseif ( event == "GROUP_ROSTER_UPDATE" ) then
		if ( OmegaMapQuestFrame.DetailsFrame.questID ) then
			OmegaMapQuestFrame_UpdateQuestDetailsButtons();
		end

		if ( self:IsVisible() ) then
			OmegaMapQuestFrame_UpdateAll();
		end
	elseif ( event == "QUEST_POI_UPDATE" ) then
		OmegaMapQuestFrame_UpdateAll();
	elseif ( event == "PARTY_MEMBER_ENABLE" or event == "PARTY_MEMBER_DISABLE" ) then
		if ( self:IsVisible() ) then
			OmegaMapQuestFrame_UpdateAll();
		end	
	elseif ( event == "QUEST_ACCEPTED" ) then
		TUTORIAL_QUEST_ACCEPTED = arg2;
	elseif ( event == "AJ_QUEST_LOG_OPEN" ) then
		OM_ShowQuestLog();
		local questIndex = GetQuestLogIndexByID(arg1)
		local mapID, floorNumber = GetQuestWorldMapAreaID(arg1);
		if ( questIndex > 0 ) then
			QuestMapFrame_OpenToQuestDetails(arg1);
		elseif ( mapID ~= 0 ) then
			SetMapByID(mapID);
			if ( floorNumber ~= 0 ) then
				SetDungeonMapLevel(floorNumber);
			end
		elseif ( arg2 and arg2 > 0) then
			SetMapByID(arg2);
		end
	elseif ( event == "PLAYER_ENTERING_WORLD" or event == "WORLD_MAP_UPDATE" ) then
		SortQuestSortTypes();
		SortQuests();
		OmegaMapQuestFrame_ResetFilters();
		OmegaMapQuestFrame_UpdateAll();
	end
end

-- opening/closing the quest frame is different from showing/hiding because of fullscreen map mode
-- opened indicates the quest frame should show in windowed map mode
-- in fullscreen map mode the quest frame could be opened but hidden
function OmegaMapQuestFrame_Open(userAction)
	if ( userAction ) then
	OmegaMapConfig.showQuestList = true;
		--SetCVar("questLogOpen", 1);
	end
	--if ( OmegaMapFrame_InWindowedMode() ) then
		OmegaMapQuestFrame_Show();
	--end
end

function OmegaMapQuestFrame_Close(userAction)
	if ( userAction ) then
		--SetCVar("questLogOpen", 0);
		OmegaMapConfig.showQuestList = false;
	end
	OmegaMapQuestFrame_Hide();
end

function OmegaMapQuestFrame_Show()
	if ( not OmegaMapQuestFrame:IsShown() ) then
		--OmegaMapFrame:SetWidth(992);
		--OmegaMapFrame.BorderFrame:SetWidth(992);
		
		OmegaMapQuestFrame_UpdateAll();
		
		OmegaMapQuestFrame:Show();
	
		OmegaMapFrame.UIElementsFrame.OpenQuestPanelButton:Hide();
		OmegaMapFrame.UIElementsFrame.CloseQuestPanelButton:Show();
		OmegaMapFrame.UIElementsFrame.TrackingOptionsButton:Hide();
		
		if ( TutorialFrame.id == 1 or TutorialFrame.id == 55 or TutorialFrame.id == 57 ) then
			TutorialFrame_Hide();
		end
	end
end

function OmegaMapQuestFrame_Hide()
	if ( OmegaMapQuestFrame:IsShown() ) then
		--OmegaMapFrame:SetWidth(702);
		--OmegaMapFrame.BorderFrame:SetWidth(702);
		OmegaMapQuestFrame:Hide();
		OmegaMapQuestFrame_UpdateAll();

		OmegaMapFrame.UIElementsFrame.OpenQuestPanelButton:Show();
		OmegaMapFrame.UIElementsFrame.CloseQuestPanelButton:Hide();
		OmegaMapFrame.UIElementsFrame.TrackingOptionsButton:Show();
	end
end

function OmegaMapQuestFrame_IsQuestWorldQuest(questID)
	local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = GetQuestTagInfo(questID);
	return worldQuestType ~= nil;
end

function OmegaMapQuestFrame_UpdateAll()
	local numPOIs = QuestMapUpdateAllQuests();
	--QuestPOIUpdateIcons();
	--QuestObjectiveTracker_UpdatePOIs();
	if ( OmegaMapFrame:IsShown() ) then	
		local poiTable = { };
		if ( numPOIs > 0 and GetCVarBool("questPOI") ) then
			GetQuestPOIs(poiTable);
		end
		local questDetailID = OmegaMapQuestFrame.DetailsFrame.questID;
		if ( questDetailID ) then
			-- update rewards
			SelectQuestLogEntry(GetQuestLogIndexByID(questDetailID));	
			QuestInfo_Display(QUEST_TEMPLATE_MAP_REWARDS, OmegaMapQuestFrame.DetailsFrame.RewardsFrame, nil, nil, true);
		else
			OM_QuestLogQuests_Update(poiTable);
		end
		OmegaMapPOIFrame_Update(poiTable);
	end
end

function OmegaMapQuestFrame_ResetFilters()
	local numEntries, numQuests = GetNumQuestLogEntries();
	OmegaMapQuestFrame.ignoreQuestLogUpdate = true;
	for questLogIndex = 1, numEntries do
		local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory = GetQuestLogTitle(questLogIndex);	
		local difficultyColor = GetQuestDifficultyColor(level);
		if ( isHeader ) then
			if (isOnMap) then
				ExpandQuestHeader(questLogIndex, true);
			else
				CollapseQuestHeader(questLogIndex, true);
			end
		end
	end
	OmegaMapQuestFrame.ignoreQuestLogUpdate = nil;
end

function OmegaMapQuestFrame_ShowQuestDetails(questID)
	local questLogIndex = GetQuestLogIndexByID(questID);
	SelectQuestLogEntry(questLogIndex);
	OmegaMapQuestFrame.DetailsFrame.questID = questID;
	QuestInfo_Display(QUEST_TEMPLATE_MAP_DETAILS, OmegaMapQuestFrame.DetailsFrame.ScrollFrame.Contents);
	QuestInfo_Display(QUEST_TEMPLATE_MAP_REWARDS, OmegaMapQuestFrame.DetailsFrame.RewardsFrame, nil, nil, true);
	OmegaMapQuestFrame.DetailsFrame.ScrollFrame.ScrollBar:SetValue(0);
		
	local questPortrait, questPortraitText, questPortraitName = GetQuestLogPortraitGiver();
	if (questPortrait and questPortrait ~= 0 and QuestLogShouldShowPortrait() and (UIParent:GetRight() - OmegaMapFrame:GetRight() > QuestNPCModel:GetWidth() + 6)) then
		QuestFrame_ShowQuestPortrait(OmegaMapFrame, questPortrait, questPortraitText, questPortraitName, -2, -43);
		QuestNPCModel:SetFrameLevel(OmegaMapFrame:GetFrameLevel() + 2);
		QuestNPCModel:ClearAllPoints();
		QuestNPCModel:SetPoint("TOPRIGHT", OmegaMapQuestFrame, "TOPLEFT",0,0); 
		--QuestNPCModel:SetPoint("BOTTOMLEFT", OmegaMapFrame, "BOTTOMRIGHT",0,0); 
		QuestNPCModel:SetScale(.8)
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
	OmegaMapQuestFrame.DetailsFrame.RewardsFrame:SetHeight(height);
	OmegaMapQuestFrame.DetailsFrame.RewardsFrame.Background:SetTexCoord(0, 1, 0, height / 275);

	OmegaMapQuestFrame.QuestsFrame:Hide();
	OmegaMapQuestFrame.DetailsFrame:Show();
	
	-- save current view
	OmegaMapQuestFrame.DetailsFrame.continent = GetCurrentMapContinent();
	OmegaMapQuestFrame.DetailsFrame.OmegaMapQuestID = nil;	-- doing it now because GetQuestWorldMapAreaID will do a SetMap to current zone
	OmegaMapQuestFrame.DetailsFrame.dungeonFloor = GetCurrentMapDungeonLevel();
	
	local mapID, floorNumber = GetQuestWorldMapAreaID(questID);
	if ( mapID ~= 0 ) then
		SetMapByID(mapID, floorNumber);
		if ( floorNumber ~= 0 ) then
			OmegaMapQuestFrame.DetailsFrame.dungeonFloor = floorNumber;
		end
		OmegaMapQuestFrame.DetailsFrame.mapID = mapID;
	end
	
	OmegaMapQuestFrame_UpdateQuestDetailsButtons();
	OmegaMapQuestFrame.DetailsFrame.OmegaMapQuestID = GetCurrentMapAreaID();

	if ( IsQuestComplete(questID) and GetQuestLogIsAutoComplete(questLogIndex) ) then
		OmegaMapQuestFrame.DetailsFrame.CompleteQuestFrame:Show();
		OmegaMapQuestFrame.DetailsFrame.RewardsFrame:SetPoint("BOTTOMLEFT", 0, 44);
	else
		OmegaMapQuestFrame.DetailsFrame.CompleteQuestFrame:Hide();
		OmegaMapQuestFrame.DetailsFrame.RewardsFrame:SetPoint("BOTTOMLEFT", 0, 20);
	end
	
	StaticPopup_Hide("ABANDON_QUEST");
	StaticPopup_Hide("ABANDON_QUEST_WITH_ITEMS");
end

function OmegaMapQuestFrame_CloseQuestDetails(optPortraitOwnerCheckFrame)
	OmegaMapQuestFrame.QuestsFrame:Show();
	OmegaMapQuestFrame.DetailsFrame:Hide();
	OmegaMapQuestFrame.DetailsFrame.questID = nil;
	OmegaMapQuestFrame.DetailsFrame.OmegaMapQuestID = nil;
	OmegaMapQuestFrame_UpdateAll();
	QuestFrame_HideQuestPortrait(optPortraitOwnerCheckFrame);

	StaticPopup_Hide("ABANDON_QUEST");
	StaticPopup_Hide("ABANDON_QUEST_WITH_ITEMS");	
end

function OmegaMapQuestFrame_UpdateQuestDetailsButtons()
	local questLogSelection = GetQuestLogSelection();
	local _, _, _, _, _, _, _, questID = GetQuestLogTitle(questLogSelection);
	if ( CanAbandonQuest(questID)) then
		OmegaMapQuestFrame.DetailsFrame.AbandonButton:Enable();
		OM_QuestLogPopupDetailFrame.AbandonButton:Enable();
	else
		OmegaMapQuestFrame.DetailsFrame.AbandonButton:Disable();
		OM_QuestLogPopupDetailFrame.AbandonButton:Disable();
	end

	if ( IsQuestWatched(questLogSelection) ) then
		OmegaMapQuestFrame.DetailsFrame.TrackButton:SetText(UNTRACK_QUEST_ABBREV);
		OM_QuestLogPopupDetailFrame.TrackButton:SetText(UNTRACK_QUEST_ABBREV);
	else
		OmegaMapQuestFrame.DetailsFrame.TrackButton:SetText(TRACK_QUEST_ABBREV);
		OM_QuestLogPopupDetailFrame.TrackButton:SetText(TRACK_QUEST_ABBREV);
	end

	if ( GetQuestLogPushable() and IsInGroup() ) then
		OmegaMapQuestFrame.DetailsFrame.ShareButton:Enable();
		OM_QuestLogPopupDetailFrame.ShareButton:Enable();
	else
		OmegaMapQuestFrame.DetailsFrame.ShareButton:Disable();
		OM_QuestLogPopupDetailFrame.ShareButton:Disable();
	end
end

function OmegaMapQuestFrame_ReturnFromQuestDetails()
	if ( OmegaMapQuestFrame.DetailsFrame.mapID == -1 ) then
		SetMapZoom(OmegaMapQuestFrame.DetailsFrame.continent);
	elseif ( OmegaMapQuestFrame.DetailsFrame.mapID ) then
		SetMapByID(OmegaMapQuestFrame.DetailsFrame.mapID, OmegaMapQuestFrame.DetailsFrame.dungeonFloor);
		if ( OmegaMapQuestFrame.DetailsFrame.dungeonFloor ~= 0 ) then
			SetDungeonMapLevel(OmegaMapQuestFrame.DetailsFrame.dungeonFloor);
		end
	end
	OmegaMapQuestFrame_CloseQuestDetails();
end

function OmegaMapQuestFrame_OpenToQuestDetails(questID)
	OM_ShowQuestLog();
	OmegaMapQuestFrame_ShowQuestDetails(questID);
end

function OmegaMapQuestFrame_GetDetailQuestID()
	return OmegaMapQuestFrame.DetailsFrame.questID;
end

function OmegaMapQuestFrameViewAllButton_Update()
	local self = OmegaMapQuestFrame.QuestsFrame.ViewAll;
	local _, numQuests = GetNumQuestLogEntries();
	self:SetText(QUEST_MAP_VIEW_ALL_FORMAT:format(numQuests, MAX_QUESTLOG_QUESTS));
end

function OmegaMapQuestFrameViewAllButton_OnClick(self)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	SetMapZoom(WORLDMAP_COSMIC_ID);
end


function OmegaMapQuestFrame_UpdateAllQuestCriteria()
	for questID, _ in pairs(OmegaMapQuestFrame.completedCriteria) do
		if (not IsQuestTask(questID) and GetQuestLogIndexByID(questID) == 0) then
			OmegaMapQuestFrame.completedCriteria[questID] = nil;
		end
	end
end

function OmegaMapQuestFrame_CheckQuestCriteria(questID, criteriaID, description, fulfilled, required)
	if (fulfilled == required) then
		if (OmegaMapQuestFrame.completedCriteria[questID] and OmegaMapQuestFrame.completedCriteria[questID][criteriaID]) then
			return false;
		end
		if (not OmegaMapQuestFrame.completedCriteria[questID]) then
			OmegaMapQuestFrame.completedCriteria[questID] = {};
		end
		OmegaMapQuestFrame.completedCriteria[questID][criteriaID] = true;
	end

	return true;
end

-- *****************************************************************************************************
-- ***** QUEST OPTIONS DROPDOWN
-- *****************************************************************************************************

function OmegaMapQuestOptionsDropDown_Initialize(self)
	local questLogIndex = GetQuestLogIndexByID(self.questID);
	local info = Lib_UIDropDownMenu_CreateInfo();
	info.isNotRadio = true;
	info.notCheckable = true;

	info.text = TRACK_QUEST;
	if ( IsQuestWatched(questLogIndex) ) then
		info.text = UNTRACK_QUEST;
	end
	info.func =function(_, questID) OmegaMapQuestQuestOptions_TrackQuest(questID) end;
	info.arg1 = self.questID;
	Lib_UIDropDownMenu_AddButton(info, Lib_UIDROPDOWNMENU_MENU_LEVEL);
	
	info.text = SHARE_QUEST;
	info.func = function(_, questID) OmegaMapQuestQuestOptions_ShareQuest(questID) end;
	info.arg1 = self.questID;
	if ( not GetQuestLogPushable(questLogIndex) or not IsInGroup() ) then
		info.disabled = 1;
	end
	Lib_UIDropDownMenu_AddButton(info, Lib_UIDROPDOWNMENU_MENU_LEVEL);
	
	if CanAbandonQuest(self.questID) then
		info.text = ABANDON_QUEST;
		info.func = function(_, questID) QuestMapQuestOptions_AbandonQuest(questID) end;
		info.arg1 = self.questID;
		info.disabled = nil;
		Lib_UIDropDownMenu_AddButton(info, Lib_UIDROPDOWNMENU_MENU_LEVEL);
	end
end

function OmegaMapQuestQuestOptions_TrackQuest(questID)
	local questLogIndex = GetQuestLogIndexByID(questID);
	if ( IsQuestWatched(questLogIndex) ) then
		QuestObjectiveTracker_UntrackQuest(nil, questID);
	else
		AddQuestWatch(questLogIndex, true);
		QuestSuperTracking_OnQuestTracked(questID);
	end
end

function OmegaMapQuestQuestOptions_ShareQuest(questID)
	local questLogIndex = GetQuestLogIndexByID(questID);
	QuestLogPushQuest(questLogIndex);
	PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN);
end

function OmegaMapQuestQuestOptions_AbandonQuest(questID)
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

function OM_QuestLogQuests_GetHeaderButton(index)
	local headers = OmegaMapQuestFrame.QuestsFrame.Contents.Headers;
	if ( not headers[index] ) then
		local header = CreateFrame("BUTTON", nil, OmegaMapQuestFrame.QuestsFrame.Contents, "QuestLogHeaderTemplate");
		headers[index] = header;
	end
	return headers[index];
end

function OM_QuestLogQuests_GetTitleButton(index)
	local titles = OmegaMapQuestFrame.QuestsFrame.Contents.Titles;
	if ( not titles[index] ) then
		local title = CreateFrame("BUTTON", nil, OmegaMapQuestFrame.QuestsFrame.Contents, "OM_QuestLogTitleTemplate");
		titles[index] = title;
	end
	return titles[index];
end

local OBJECTIVE_FRAMES = { };
function OM_QuestLog_GetObjectiveFrame(index)
	if ( not OBJECTIVE_FRAMES[index] ) then
		local frame = CreateFrame("FRAME", "QLOF"..index, OmegaMapQuestFrame.QuestsFrame.Contents, "QuestLogObjectiveTemplate");
		OBJECTIVE_FRAMES[index] = frame;
	end
	return OBJECTIVE_FRAMES[index];
end

function OM_QuestLogQuests_Update(poiTable)
	local playerMoney = GetMoney();
    local numEntries, numQuests = GetNumQuestLogEntries();
	local showPOIs = GetCVarBool("questPOI");

	local mapID, isContinent = GetCurrentMapAreaID();

	local button, prevButton;
	
	QuestPOI_ResetUsage(OM_QuestScrollFrame.Contents);

	local poiFrameLevel = OM_QuestLogQuests_GetHeaderButton(1):GetFrameLevel() + 2;

	local storyID, storyMapID = GetZoneStoryID();
	if ( storyID ) then
		OM_QuestScrollFrame.Contents.StoryHeader:Show();
		OM_QuestScrollFrame.Contents.StoryHeader.Text:SetText(GetMapNameByID(storyMapID));
		local numCriteria = GetAchievementNumCriteria(storyID);
		local completedCriteria = 0;
		for i = 1, numCriteria do
			local _, _, completed = GetAchievementCriteriaInfo(storyID, i);
			if ( completed ) then
				completedCriteria = completedCriteria + 1;
			end
		end
		local numPoints = select(3, GetAchievementInfo(storyID));
		OM_QuestScrollFrame.Contents.StoryHeader.Points:SetText(numPoints);
		OM_QuestScrollFrame.Contents.StoryHeader.Progress:SetFormattedText(QUEST_STORY_STATUS, completedCriteria, numCriteria);
		prevButton = OM_QuestScrollFrame.Contents.StoryHeader;
	else
		OM_QuestScrollFrame.Contents.StoryHeader:Hide();
	end

	local headerIndex = 0;
	local titleIndex = 0;
	local objectiveIndex = 0;
	local headerCollapsed = false;
	local headerTitle, headerOnMap, headerShown, headerLogIndex, mapHeaderButtonIndex, firstMapHeaderQuestButtonIndex;
	local noHeaders = true;
	for questLogIndex = 1, numEntries do
		local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory = GetQuestLogTitle(questLogIndex);
		local difficultyColor = GetQuestDifficultyColor(level);
		if ( isHeader ) then
			headerTitle = title;
			headerOnMap = isOnMap;
			headerShown = false;
			headerLogIndex = questLogIndex;
			headerCollapsed = isCollapsed;
			difficultyColor = QuestDifficultyColors["header"];
		elseif ( not isTask and (not isBounty or IsQuestComplete(questID))) then
			-- we have at least one valid entry, show the header for it
			if ( not headerShown ) then
				headerShown = true;
				noHeaders = false
				headerIndex = headerIndex + 1;
				button = OM_QuestLogQuests_GetHeaderButton(headerIndex);
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
				button:Show();				
				button.questLogIndex = headerLogIndex;
				prevButton = button;
			end

			if (not headerCollapsed) then
				local totalHeight = 8;
				titleIndex = titleIndex + 1;
				button = OM_QuestLogQuests_GetTitleButton(titleIndex);
				button.questID = questID;

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
						tagID = "ALLIANCE";
						if ( factionGroup == LE_QUEST_FACTION_HORDE ) then
							tagID = "HORDE";
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
					end
				else
					button.TagTexture:Hide();
				end
				
			
			-- POI/objectives
				local requiredMoney = GetQuestLogRequiredMoney(questLogIndex);
				local numObjectives = GetNumQuestLeaderBoards(questLogIndex);
				-- complete?
				if ( isComplete and isComplete < 0 ) then
					isComplete = false;
				elseif ( numObjectives == 0 and playerMoney >= requiredMoney and not startEvent) then
					isComplete = true;
				end
				-- objectives
				if ( isComplete ) then
					objectiveIndex = objectiveIndex + 1;
					local objectiveFrame = OM_QuestLog_GetObjectiveFrame(objectiveIndex);
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
							objectiveIndex = objectiveIndex + 1;
							local objectiveFrame = OM_QuestLog_GetObjectiveFrame(objectiveIndex);
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
						objectiveIndex = objectiveIndex + 1;
						local objectiveFrame = OM_QuestLog_GetObjectiveFrame(objectiveIndex);
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
				if ( hasLocalPOI and showPOIs ) then			
					local poiButton;
					if ( isComplete ) then
						poiButton = QuestPOI_GetButton(OM_QuestScrollFrame.Contents, questID, "normal", nil, isStory);
					else
						for i = 1, #poiTable do
							if ( poiTable[i] == questID ) then
								poiButton = QuestPOI_GetButton(OM_QuestScrollFrame.Contents, questID, "numeric", i, isStory);
								break;
							end
						end
					end
					if ( poiButton ) then
						poiButton:SetPoint("TOPLEFT", button, 6, -4);
						poiButton:SetFrameLevel(poiFrameLevel);
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
				button:Show();
				prevButton = button;
			end
		end
	end

	-- background
	if ( titleIndex == 0 and noHeaders ) then
		OM_QuestScrollFrame.Background:SetAtlas("NoQuestsBackground", true);
	else
		OM_QuestScrollFrame.Background:SetAtlas("QuestLogBackground", true);
	end
	
	QuestPOI_SelectButtonByQuestID(OM_QuestScrollFrame.Contents, GetSuperTrackedQuestID());

	-- clean up
	for i = headerIndex + 1, #OmegaMapQuestFrame.QuestsFrame.Contents.Headers do
		OmegaMapQuestFrame.QuestsFrame.Contents.Headers[i]:Hide();
	end
	for i = titleIndex + 1, #OmegaMapQuestFrame.QuestsFrame.Contents.Titles do
		OmegaMapQuestFrame.QuestsFrame.Contents.Titles[i]:Hide();
	end
	for i = objectiveIndex + 1, #OBJECTIVE_FRAMES do
		OBJECTIVE_FRAMES[i]:Hide();
	end
	QuestPOI_HideUnusedButtons(OM_QuestScrollFrame.Contents);
end

function OM_ToggleQuestLog()
	if ( OmegaMapQuestFrame:IsShown() and OmegaMapQuestFrame:IsVisible() ) then
		HideUIPanel(OmegaMapFrame);
	else
		OM_ShowQuestLog();
	end
end

function OM_ShowQuestLog()
	OmegaMapFrame.questLogMode = true;
	ShowUIPanel(OmegaMapFrame);
	--if ( not OmegaMapFrame_InWindowedMode() ) then
		--OmegaMapFrame_ToggleWindowSize();
	--end
	OmegaMapQuestFrame_Open();
end

function OmegaMapQuestLogHeaderButton_OnClick(self, button)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	if ( button == "LeftButton" ) then
		local _, _, _, _, isCollapsed = GetQuestLogTitle(self.questLogIndex);	
		if (isCollapsed) then
			ExpandQuestHeader(self.questLogIndex);
		else
			CollapseQuestHeader(self.questLogIndex);
		end
	else
		OmegaMapZoomOutButton_OnClick();
	end
end

function OmegaMapQuestLogTitleButton_OnEnter(self)
	-- do block highlight
	local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI = GetQuestLogTitle(self.questLogIndex);
	local _, difficultyHighlightColor = GetQuestDifficultyColor(level);
	if ( isHeader ) then
		_, difficultyHighlightColor = QuestDifficultyColors["header"];
	end
	self.Text:SetTextColor( difficultyHighlightColor.r, difficultyHighlightColor.g, difficultyHighlightColor.b );
	for _, line in pairs(OBJECTIVE_FRAMES) do
		if ( line.questID == self.questID ) then
			line.Text:SetTextColor(1, 1, 1);
		end
	end

	if ( not IsQuestComplete(self.questID) ) then
		OmegaMapBlobFrame:DrawBlob(self.questID, true);
	end
	

	GameTooltip:ClearAllPoints();
	GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 34, 0);
	GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
	GameTooltip:SetText(title);
	local tooltipWidth = 20 + max(231, GameTooltipTextLeft1:GetStringWidth());
	if ( tooltipWidth > UIParent:GetRight() - OmegaMapFrame:GetRight() ) then
		GameTooltip:ClearAllPoints();
		GameTooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", -5, 0);
		GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
		GameTooltip:SetText(title);
	end
	
	-- quest tag
	local tagID, tagName = GetQuestTagInfo(questID);
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
		GameTooltip:AddLine(tagName, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
		if ( QUEST_TAG_TCOORDS[tagID] ) then
			local questTypeIcon;
			if ( tagID == QUEST_TAG_ACCOUNT and factionGroup ) then
				questTypeIcon = QUEST_TAG_TCOORDS["ALLIANCE"];
				if ( factionGroup == LE_QUEST_FACTION_HORDE ) then
					questTypeIcon = QUEST_TAG_TCOORDS["HORDE"];
				end
			else
				questTypeIcon = QUEST_TAG_TCOORDS[tagID];
			end
			GameTooltip:AddTexture("Interface\\QuestFrame\\QuestTypeIcons", unpack(questTypeIcon));
		end
	end
	if ( frequency == LE_QUEST_FREQUENCY_DAILY ) then
		GameTooltip:AddLine(DAILY, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
		GameTooltip:AddTexture("Interface\\QuestFrame\\QuestTypeIcons", unpack(QUEST_TAG_TCOORDS["DAILY"]));
	elseif ( frequency == LE_QUEST_FREQUENCY_WEEKLY ) then
		GameTooltip:AddLine(WEEKLY, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
		GameTooltip:AddTexture("Interface\\QuestFrame\\QuestTypeIcons", unpack(QUEST_TAG_TCOORDS["WEEKLY"]));
	end
	if ( isComplete and isComplete < 0 ) then
		GameTooltip:AddLine(FAILED, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
		GameTooltip:AddTexture("Interface\\QuestFrame\\QuestTypeIcons", unpack(QUEST_TAG_TCOORDS["FAILED"]));	
	end
	GameTooltip:AddLine(" ");

	-- description
	if ( isComplete and isComplete > 0 ) then
		local completionText = GetQuestLogCompletionText(self.questLogIndex) or QUEST_WATCH_QUEST_READY;
		GameTooltip:AddLine(completionText, 1, 1, 1, true);
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
				GameTooltip:AddLine("Nearby party members that are on this quest: ");
			end
			partyMembersOnQuest = partyMembersOnQuest + 1;
			GameTooltip:AddLine(LIGHTYELLOW_FONT_COLOR_CODE..GetUnitName("party"..i, true)..FONT_COLOR_CODE_CLOSE);
		end
	end
	
	GameTooltip:Show();
	OM_tooltipButton = self;
end

function OmegaMapQuestLogTitleButton_OnLeave(self)
	-- remove block highlight
	local title, level, suggestedGroup, isHeader = GetQuestLogTitle(self.questLogIndex);
	local difficultyColor = GetQuestDifficultyColor(level);
	if ( isHeader ) then
		difficultyColor = QuestDifficultyColors["header"];
	end
	self.Text:SetTextColor( difficultyColor.r, difficultyColor.g, difficultyColor.b );
	for _, line in pairs(OBJECTIVE_FRAMES) do
		if ( line.questID == self.questID ) then
			line.Text:SetTextColor(0.8, 0.8, 0.8);
		end
	end
	
	if ( GetSuperTrackedQuestID() ~= self.questID and not IsQuestComplete(self.questID) ) then
		OmegaMapBlobFrame:DrawBlob(self.questID, false);
	end
	GameTooltip:Hide();
	OM_tooltipButton = nil;

end

function OmegaMapQuestLogTitleButton_OnClick(self, button)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	if ( IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow() ) then
		local questLink = GetQuestLink(GetQuestLogIndexByID(self.questID));
		if ( questLink ) then
			ChatEdit_InsertLink(questLink);
		end
	elseif ( IsShiftKeyDown() ) then
		OmegaMapQuestQuestOptions_TrackQuest(self.questID);
	else
		if ( button == "RightButton" ) then
			if ( self.questID ~= OmegaMapQuestOptionsDropDown.questID ) then
				CloseDropDownMenus();
			end
			OmegaMapQuestOptionsDropDown.questID = self.questID;
			ToggleDropDownMenu(1, nil, OmegaMapQuestOptionsDropDown, "cursor", 6, -6);		
		else
			OmegaMapQuestFrame_ShowQuestDetails(self.questID);
		end
	end
end

function OmegaMapQuestLogTitleButton_OnMouseDown(self)
	local anchor, _, _, x, y = self.Text:GetPoint();
	self.Text:SetPoint(anchor, x + 1, y - 1);
	anchor, _, _, x, y = self.TagTexture:GetPoint(2);
	self.TagTexture:SetPoint(anchor, x + 1, y - 1);
end

function OmegaMapQuestLogTitleButton_OnMouseUp(self)
	local anchor, _, _, x, y = self.Text:GetPoint();
	self.Text:SetPoint(anchor, x - 1, y + 1);
	anchor, _, _, x, y = self.TagTexture:GetPoint(2);
	self.TagTexture:SetPoint(anchor, x - 1, y + 1);
end

function OmegaMapQuestLog_ShowStoryTooltip(self)
	local tooltip = OM_QuestScrollFrame.StoryTooltip;
	local storyID = GetZoneStoryID();
	local maxWidth = 0;
	local totalHeight = 0;
	
	tooltip.Title:SetText(GetMapNameByID(GetCurrentMapAreaID()));
	totalHeight = totalHeight + tooltip.Title:GetHeight();	
	maxWidth = tooltip.Title:GetWidth();
	
	-- Clear out old quest criteria
	for i = 1, #tooltip.Lines do
		tooltip.Lines[i]:Hide();
	end
	
	local numCriteria = GetAchievementNumCriteria(storyID);
	local completedCriteria = 0;
	for i = 1, numCriteria do
		local title, _, completed = GetAchievementCriteriaInfo(storyID, i);
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
	if ( tooltipWidth > UIParent:GetRight() - OmegaMapFrame:GetRight() ) then
		tooltip:SetPoint("TOPRIGHT", self:GetParent().StoryHeader, "TOPLEFT", -5, 0);
	else
		tooltip:SetPoint("TOPLEFT", self:GetParent().StoryHeader, "TOPRIGHT", 27, 0);
	end
	tooltip:SetSize(tooltipWidth, totalHeight + 42);
	tooltip:Show();
end

function OmegaMapQuestLog_HideStoryTooltip(self)
	OM_QuestScrollFrame.StoryTooltip:Hide();
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

	if ( OM_QuestLogPopupDetailFrame.questID == questID ) then
		HideUIPanel(OM_QuestLogPopupDetailFrame);
		return;
	end
	
	OM_QuestLogPopupDetailFrame.questID = questID;

	local questLogIndex = GetQuestLogIndexByID(questID);
	
	SelectQuestLogEntry(questLogIndex);
	StaticPopup_Hide("ABANDON_QUEST");
	StaticPopup_Hide("ABANDON_QUEST_WITH_ITEMS");
	SetAbandonQuest();

	OmegaMapQuestFrame_UpdateQuestDetailsButtons();

	OM_QuestLogPopupDetailFrame_Update(true);
	ShowUIPanel(OM_QuestLogPopupDetailFrame);
	PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN);
	
	-- portrait
	local questPortrait, questPortraitText, questPortraitName = GetQuestLogPortraitGiver();
	if (questPortrait and questPortrait ~= 0 and QuestLogShouldShowPortrait()) then
		QuestFrame_ShowQuestPortrait(OM_QuestLogPopupDetailFrame, questPortrait, questPortraitText, questPortraitName, -3, -42);
	else
		QuestFrame_HideQuestPortrait();
	end
end

function OM_QuestLogPopupDetailFrame_Update(resetScrollBar)
	QuestInfo_Display(QUEST_TEMPLATE_LOG, OM_QuestLogPopupDetailFrame.ScrollFrame.ScrollChild)
	if ( resetScrollBar ) then
		OM_QuestLogPopupDetailFrame.ScrollFrame.ScrollBar:SetValue(0);
	end
end