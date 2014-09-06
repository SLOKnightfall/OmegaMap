local function getEmbeddedFactionIcon()
	local factionGroup = UnitFactionGroup("player");
	if ( factionGroup == "Alliance" ) then
		return "|TInterface\\TargetingFrame\\UI-PVP-ALLIANCE:19:16:0:0:64:64:0:32:0:38|t";
	elseif ( factionGroup == "Horde" ) then
		return "|TInterface\\TargetingFrame\\UI-PVP-HORDE:18:19:0:0:64:64:0:38:0:36|t";
	else --Say what?
		return "";
	end
end

function OmegaMapBarFrame_OnLoad(self)
	self:RegisterEvent("WORLD_MAP_UPDATE");
	self:RegisterEvent("MAP_BAR_UPDATE");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self.Spark:ClearAllPoints();
	self.Spark:SetPoint("CENTER", self:GetStatusBarTexture(), "RIGHT", 0, 0);
	OmegaMapBarFrame_Update(self);
	OmegaMapBarFrame_UpdateLayout(self);

	self.BarTexture:SetDrawLayer("BORDER");
end

function OmegaMapBarFrame_OnEvent(self, event, ...)
	if ( event == "PLAYER_ENTERING_WORLD" or
		event == "WORLD_MAP_UPDATE" or
		event == "MAP_BAR_UPDATE" ) then
		OmegaMapBarFrame_Update(self);
	end
end

function OmegaMapBarFrame_OnEnter(self)
	local tag = C_MapBar.GetTag();
	local phase = C_MapBar.GetPhaseIndex();
	local participation = C_MapBar.GetParticipationPercentage();

	local title = OmegaMapBarFrame_GetString("TITLE", tag, phase);
	local tooltipText = OmegaMapBarFrame_GetString("TOOLTIP", tag, phase);
	local percentage = math.floor(100 * C_MapBar.GetCurrentValue() / C_MapBar.GetMaxValue());
	OmegaMapTooltip.MB_using = true;
	OmegaMapTooltip:SetOwner(self, "ANCHOR_RIGHT");
	OmegaMapTooltip:SetText(format(MAP_BAR_TOOLTIP_TITLE, title, percentage), 1, 1, 1);
	OmegaMapTooltip:AddLine(tooltipText, nil, nil, nil, true);
	OmegaMapTooltip:AddLine(format(MAP_BAR_PARTICIPATION, getEmbeddedFactionIcon(), participation), 1, 1, 1);
	OmegaMapTooltip:Show();
end

function OmegaMapBarFrame_OnLeave(self)
	OmegaMapTooltip.MB_using = false;
	OmegaMapTooltip:Hide();
end

function OmegaMapBarFrame_Update(self)
	if ( C_MapBar.BarIsShown() ) then
		local tag = C_MapBar.GetTag();
		local phase = C_MapBar.GetPhaseIndex();

		local title = OmegaMapBarFrame_GetString("TITLE", tag, phase);
		local desc = OmegaMapBarFrame_GetString("DESCRIPTION", tag, phase);
		if ( title and desc ) then
			self.Title:SetText(title);
			self.Description:SetText(desc);
			self:SetMinMaxValues(0, C_MapBar.GetMaxValue());
			self:SetValue(C_MapBar.GetCurrentValue());
			self:Show();
			return;
		end
	end
	self:Hide();
end

function OmegaMapBarFrame_UpdateLayout(self)
	self:SetFrameLevel(OmegaMapPOIFrame:GetFrameLevel() + 1);
		self:SetScale(1);
		self:SetPoint("TOPLEFT", OmegaMapButton, "TOPLEFT", 150, -70);
end

function OmegaMapBarFrame_GetString(stringType, tag, phase)
	local factionGroup = UnitFactionGroup("player");
	local str = _G["MAP_BAR_"..tag.."_"..strupper(factionGroup).."_"..stringType..phase];
	if ( str ) then
		return str;
	end
	return _G["MAP_BAR_"..tag.."_"..stringType..phase];
end
