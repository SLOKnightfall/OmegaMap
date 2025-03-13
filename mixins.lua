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

	--self:2();
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
function OmegaMapNavBarMixin:OnLoad()
	local homeData = {
		name = WORLD,
		OnClick = function(button)
			local TOPMOST = true;
			local cosmicMapInfo = MapUtil.GetMapParentInfo(self:GetParent():GetMapID(), Enum.UIMapType.Cosmic, TOPMOST);
			if cosmicMapInfo then
				self:GoToMap(cosmicMapInfo.mapID)
			end
		end,
	}
	OM_NavBar_Initialize(self, "OM_NavButtonTemplate", homeData, self.home, self.overflow);
end
function OmegaMapNavBarMixin:OnMouseUp()
	OmegaMapFrame:StopMovingOrSizing() 
end
function OmegaMapNavBarMixin:OnMouseDown()
	OmegaMapFrame:StartMoving()
	OmegaMapFrame:SetUserPlaced(true);
end


function OmegaMapNavBarMixin:Refresh()
	local hierarchy = { };
	local mapInfo = C_Map.GetMapInfo(self:GetParent():GetMapID());
	while mapInfo and mapInfo.parentMapID > 0 do
		local buttonData = {
			name = mapInfo.name,
			id = mapInfo.mapID,
			OnClick = WorldMapNavBarButtonMixin.OnClick,
		};
		-- Check if we are on a multifloor map belonging to a UIMapGroup, and if any map within the group should populate a dropdown
		local mapGroupID = C_Map.GetMapGroupID(mapInfo.mapID);
		if ( mapGroupID ) then
			local mapGroupMembersInfo = C_Map.GetMapGroupMembersInfo(mapGroupID);
			if ( mapGroupMembersInfo ) then
				for i, mapGroupMemberInfo in ipairs(mapGroupMembersInfo) do
					if ( C_Map.IsMapValidForNavBarDropDown(mapGroupMemberInfo.mapID) ) then
						buttonData.listFunc = WorldMapNavBarButtonMixin.GetDropDownList;
						break;
					end
				end
			end	
		elseif ( C_Map.IsMapValidForNavBarDropDown(mapInfo.mapID) ) then
			buttonData.listFunc = WorldMapNavBarButtonMixin.GetDropDownList;
		end
		tinsert(hierarchy, 1, buttonData);
		mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID);
	end

	OM_NavBar_Reset(self);
	for i, buttonData in ipairs(hierarchy) do
		OM_NavBar_AddButton(self, buttonData);
	end
end
