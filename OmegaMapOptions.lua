--	///////////////////////////////////////////////////////////////////////////////////////////

--Omega Map Options Frame & Controls
--Omega Map Minimap & Hotspot Code

--	///////////////////////////////////////////////////////////////////////////////////////////

OmegaMapOptionsFrame = {}
local spacingX = 225
local spacingY = -19
local minScale = 25
local maxScale = 125

--Function to Toggle the display of the Options frame
function OmegaMapOptionsFrame.Toggle()
	if (OmegaMapOptionsFrame.Frame:IsShown()) then
		OmegaMapOptionsFrame.Frame:Hide()
	else
		OmegaMapOptionsFrame.Frame:Show()
	end
end

--Sets up the checkboxes for the plugin modules
function OmegaMapOptionsFrame.ButtonInit(Module, Frame)
	local Button = OmegaMapOptionsFrame[Module]
	local enabledText = _G["OMEGAMAP_OPTIONS_"..string.upper(Module)]
	local disabledText =_G["OMEGAMAP_OPTIONS_"..string.upper(Module).."_DISABLED"]
	local tooltipText = _G["OMEGAMAP_OPTIONS_"..string.upper(Module).."_TOOLTIP"]
	local optionText = "show"..Module
	Button.tooltip = tooltipText;

	if Frame then
		Button:Enable()
		getglobal(Button:GetName() .. 'Text'):SetText(enabledText);
	else
		Button:Disable()
		getglobal(Button:GetName() .. 'Text'):SetTextColor(1.0, 0, 0)
		getglobal(Button:GetName() .. 'Text'):SetText(disabledText);
		--Button:SetDisabledCheckedTexture("Interface/BUTTONS/UI-GroupLoot-Pass-Down")
		--Button:SetDisabledTexture("Interface/BUTTONS/UI-GroupLoot-Pass-Down")
	end

	Button:SetChecked(OmegaMapConfig[optionText])
	Button:SetScript("OnClick", 
	  function()
		if (Button:GetChecked() ) then
			PlaySound("igMainMenuOptionCheckBoxOn");
			OmegaMapConfig[optionText] = true;
			--if (Frame) then
				--Frame:Show();
			--end
		else
			PlaySound("igMainMenuOptionCheckBoxOff");
			OmegaMapConfig[optionText] = false;
			if (Frame) then
				Frame:Hide();
			end
		end
		OmegaMapFrame_Update()
	  end
	);
end

OmegaMapOptionsFrame.Frame = CreateFrame("Frame", "OmegaMapOptionsFrames", UIParent)

--Sets up the Options frame and items in it
function OmegaMapOptionsFrame_init()
	--Frames
	OmegaMapOptionsFrame.Frame:SetClampedToScreen( true )
	OmegaMapOptionsFrame.Frame:Hide()
	OmegaMapOptionsFrame.Frame:ClearAllPoints()
	OmegaMapOptionsFrame.Frame:SetPoint("CENTER");
	OmegaMapOptionsFrame.Frame:SetWidth(600)
	OmegaMapOptionsFrame.Frame:SetHeight(600)
	OmegaMapOptionsFrame.Frame:SetFrameStrata("DIALOG")
	OmegaMapOptionsFrame.Frame:SetMovable(true)

	tinsert(UISpecialFrames, "OmegaMapOptionsFrames") -- make Frames Esc Sensitive by default

	OmegaMapOptionsFrame.Frame:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true, tileSize = 32, edgeSize = 16,
			insets = { left = 5, right = 5, top = 5, bottom = 5 }
		})
	OmegaMapOptionsFrame.Frame:SetBackdropColor(0,0,0, 0.95)

	--OmegaMapOptionsFrame.Frame:Show()
--DragBar
	OmegaMapOptionsFrame.Drag = CreateFrame("Button", "OmegaMapOptionsDragBar", OmegaMapOptionsFrame.Frame)
	OmegaMapOptionsFrame.Drag:SetPoint("TOPLEFT", OmegaMapOptionsFrame.Frame, "TOPLEFT", 10,25)
	OmegaMapOptionsFrame.Drag:SetPoint("TOPRIGHT", OmegaMapOptionsFrame.Frame, "TOPRIGHT", -10,25)
	OmegaMapOptionsFrame.Drag:SetHeight(22)
	OmegaMapOptionsFrame.Drag:SetNormalTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")
	OmegaMapOptionsFrame.Drag:SetHighlightTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")
	OmegaMapOptionsFrame.Drag:SetScript("OnMouseDown", function() OmegaMapOptionsFrame.Frame:StartMoving() end)
	OmegaMapOptionsFrame.Drag:SetScript("OnMouseUp", function() OmegaMapOptionsFrame.Frame:StopMovingOrSizing() end)
	--OmegaMapOptionsFrame.Drag:SetText(" Items Found.")
	--OmegaMapOptionsFrame.Frame.Drag:SetNormalFontObject("GameFontHighlightHuge")
--Done Button
	OmegaMapOptionsFrame.Done = CreateFrame("Button", "OmegaMapOptionsDoneButton", OmegaMapOptionsFrame.Frame, "OptionsButtonTemplate")
	OmegaMapOptionsFrame.Done:SetPoint("BOTTOMRIGHT", OmegaMapOptionsFrame.Frame, "BOTTOMRIGHT", -10, 10)
	OmegaMapOptionsFrame.Done:SetScript("OnClick", function() OmegaMapOptionsFrame.Frame:Hide() end)
	OmegaMapOptionsFrame.Done:SetText(DONE)
--Title
	OmegaMapOptionsFrame.Title = OmegaMapOptionsFrame.Frame:CreateFontString("Title")
	OmegaMapOptionsFrame.Title:SetPoint("Center", OmegaMapOptionsFrame.Frame, "TOP", 0, -25)
	OmegaMapOptionsFrame.Title:SetFontObject("GameFontHighlight")
	OmegaMapOptionsFrame.Title:SetText("Omega Map Options")
--Ruled Line
	OmegaMapOptionsFrame.Line1 = OmegaMapOptionsFrame.Frame:CreateTexture("Line1")
	OmegaMapOptionsFrame.Line1:SetTexture(1,1,1,0.2)
	OmegaMapOptionsFrame.Line1:SetHeight(2)
	OmegaMapOptionsFrame.Line1:SetWidth(300)
	OmegaMapOptionsFrame.Line1:SetPoint("Center", OmegaMapOptionsFrame.Title, "TOP", 0, -20)
--Coordinates Checbox
	OmegaMapOptionsFrame.Coords = CreateFrame("CheckButton", "OmegaMapOptionsCoordsCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.Coords:SetPoint("TOPLEFT", 75, -65);
	getglobal(OmegaMapOptionsFrame.Coords:GetName() .. 'Text'):SetText(OMEGAMAP_OPTIONS_COORDS);
	OmegaMapOptionsFrame.Coords.tooltip = OMEGAMAP_OPTIONS_COORDS_TOOLTIP;
	OmegaMapOptionsFrame.Coords:SetChecked(OmegaMapConfig.showCoords)
	OmegaMapOptionsFrame.Coords:SetScript("OnClick", 
	  function()
		if (OmegaMapOptionsFrame.Coords:GetChecked() ) then
			PlaySound("igMainMenuOptionCheckBoxOn");
			OmegaMapConfig.showCoords = true;
			OmegaMapCoordinates:Show()
		else
			PlaySound("igMainMenuOptionCheckBoxOff");
			OmegaMapConfig.showCoords = false;
			OmegaMapCoordinates:Hide()
		end					
	  end
	);
--Alpha Slider Checkbox
	OmegaMapOptionsFrame.AlphaSliderTog = CreateFrame("CheckButton", "OmegaMapOptionsAphaCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.AlphaSliderTog:SetPoint("TOPLEFT", OmegaMapOptionsFrame.Coords, "TOPRIGHT", spacingX ,0 );
	getglobal(OmegaMapOptionsFrame.AlphaSliderTog:GetName() .. 'Text'):SetText(OMEGAMAP_OPTIONS_ALPHA);
	OmegaMapOptionsFrame.AlphaSliderTog.tooltip = OMEGAMAP_OPTIONS_ALPHA_TOOLTIP;
	OmegaMapOptionsFrame.AlphaSliderTog:SetChecked(OmegaMapConfig.showAlpha)
	OmegaMapOptionsFrame.AlphaSliderTog:SetScript("OnClick", 
	  function()
		if (OmegaMapOptionsFrame.AlphaSliderTog:GetChecked() ) then
			PlaySound("igMainMenuOptionCheckBoxOn");
			OmegaMapConfig.showAlpha = true;
			OmegaMapSliderFrame:Show()
		else
			PlaySound("igMainMenuOptionCheckBoxOff");
			OmegaMapConfig.showAlpha = false;
			OmegaMapSliderFrame:Hide()
		end
	  end
	);
--Exteriors Checkbox
	OmegaMapOptionsFrame.ExteriorsTog = CreateFrame("CheckButton", "OmegaMapOptionsExteriorCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.ExteriorsTog:SetPoint("TOPLEFT", OmegaMapOptionsFrame.Coords, "BOTTOMLEFT", 0, spacingY );
	getglobal(OmegaMapOptionsFrame.ExteriorsTog:GetName() .. 'Text'):SetText(OMEGAMAP_OPTIONS_ALTMAP);
	OmegaMapOptionsFrame.ExteriorsTog.tooltip = OMEGAMAP_OPTIONS_ALTMAP_TOOLTIP;
	OmegaMapOptionsFrame.ExteriorsTog:SetChecked(OmegaMapConfig.showExteriors)
	OmegaMapOptionsFrame.ExteriorsTog:SetScript("OnClick", 
	  function()
		if (OmegaMapOptionsFrame.ExteriorsTog:GetChecked() ) then
			PlaySound("igMainMenuOptionCheckBoxOn");
			OmegaMapConfig.showExteriors = true;
			OmegaMap_LoadAltMapNotes()

		else
			PlaySound("igMainMenuOptionCheckBoxOff");
			OmegaMapConfig.showExteriors = false;
			OmegaMap_HideAltMap()
		end
	  end
	);
--Battlegrounds Checkbox
	OmegaMapOptionsFrame.BG = CreateFrame("CheckButton", "OmegaMapOptionsBattlegroundCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.BG:SetPoint("TOPLEFT", OmegaMapOptionsFrame.AlphaSliderTog , "BOTTOMLEFT", 0,spacingY );
	getglobal(OmegaMapOptionsFrame.BG:GetName() .. 'Text'):SetText(OMEGAMAP_OPTIONS_BG);
	OmegaMapOptionsFrame.BG.tooltip = OMEGAMAP_OPTIONS_BG_TOOLTIP;
	OmegaMapOptionsFrame.BG:SetChecked(OmegaMapConfig.showBattlegrounds)
	OmegaMapOptionsFrame.BG:SetScript("OnClick", 
	  function()
		if (OmegaMapOptionsFrame.BG:GetChecked() ) then
			PlaySound("igMainMenuOptionCheckBoxOn");
			OmegaMapConfig.showBattlegrounds = true;
			OmegaMap_LoadAltMapNotes()
		else
			PlaySound("igMainMenuOptionCheckBoxOff");
			OmegaMapConfig.showBattlegrounds = false;
			OmegaMapFrame_UpdateMap()
		end
	  end
	);
--Escape Close Checkbox
	OmegaMapOptionsFrame.EscapeClose = CreateFrame("CheckButton", "OmegaMapOptionsEscapeCloseCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.EscapeClose:SetPoint("TOPLEFT", OmegaMapOptionsFrame.ExteriorsTog, "BOTTOMLEFT", 0, spacingY );
	getglobal(OmegaMapOptionsFrame.EscapeClose:GetName() .. 'Text'):SetText(OMEGAMAP_OPTIONS_ESCAPECLOSE);
	OmegaMapOptionsFrame.EscapeClose.tooltip = OMEGAMAP_OPTIONS_ESCAPECLOSE_TOOLTIP;
	OmegaMapOptionsFrame.EscapeClose:SetChecked(OmegaMapConfig.escapeClose)
	OmegaMapOptionsFrame.EscapeClose:SetScript("OnClick", 
	  function()
		if (OmegaMapOptionsFrame.EscapeClose:GetChecked() ) then
			PlaySound("igMainMenuOptionCheckBoxOn");
			OmegaMapConfig.escapeClose = true;
		else
			PlaySound("igMainMenuOptionCheckBoxOff");
			OmegaMapConfig.escapeClose = false;

		end
		OmegaMapSetEscPress()
	  end
	);
--Minimap Icon Checkbox
	OmegaMapOptionsFrame.MiniMapIcon = CreateFrame("CheckButton", "OmegaMapOptionsMiniMapIconCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.MiniMapIcon:SetPoint("TOPLEFT", OmegaMapOptionsFrame.BG, "BOTTOMLEFT", 0, spacingY );
	getglobal(OmegaMapOptionsFrame.MiniMapIcon:GetName() .. 'Text'):SetText(OMEGAMAP_OPTIONS_MINIMAP);
	OmegaMapOptionsFrame.MiniMapIcon.tooltip = OMEGAMAP_OPTIONS_MINIMAP_TOOLTIP;
	OmegaMapOptionsFrame.MiniMapIcon:SetChecked(OmegaMapConfig.showMiniMapIcon)
	OmegaMapOptionsFrame.MiniMapIcon:SetScript("OnClick", 
	  function()
		if (OmegaMapOptionsFrame.MiniMapIcon:GetChecked() ) then
			PlaySound("igMainMenuOptionCheckBoxOn");
			OmegaMapMiniMap:Show("OmegaMapMini")
			OmegaMapConfig.MMDB.hide = false;
			OmegaMapConfig.showMiniMapIcon = true;
		else
			PlaySound("igMainMenuOptionCheckBoxOff");
			OmegaMapMiniMap:Hide("OmegaMapMini")
			OmegaMapConfig.MMDB.hide = true;
			OmegaMapConfig.showMiniMapIcon = false;
		end
	  end
	);
--HotSpot Checkbox
	OmegaMapOptionsFrame.showHotSpot = CreateFrame("CheckButton", "OmegaMapOptionsHotSpotCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.showHotSpot:SetPoint("TOPLEFT", OmegaMapOptionsFrame.EscapeClose, "BOTTOMLEFT", 0, spacingY );
	getglobal(OmegaMapOptionsFrame.showHotSpot:GetName() .. 'Text'):SetText(OMEGAMAP_OPTIONS_HOTSPOT);
	OmegaMapOptionsFrame.showHotSpot.tooltip = OMEGAMAP_OPTIONS_HOTSPOT_TOOLTIP;
	OmegaMapOptionsFrame.showHotSpot:SetChecked(OmegaMapConfig.showHotSpot)
	OmegaMapOptionsFrame.showHotSpot:SetScript("OnClick", 
	  function()
		if (OmegaMapOptionsFrame.showHotSpot:GetChecked() ) then
			PlaySound("igMainMenuOptionCheckBoxOn");
			OmegaMapConfig.showHotSpot = true;
			OmegaMapHotSpotFrame:Show()
		else
			PlaySound("igMainMenuOptionCheckBoxOff");
			OmegaMapConfig.showHotSpot = false;
			OmegaMapHotSpotFrame:Hide()

		end
	  end
	);
--CompactMode Checkbox
	OmegaMapOptionsFrame.showCompactMode = CreateFrame("CheckButton", "OmegaMapOptionsCompactModeCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.showCompactMode:SetPoint("TOPLEFT", OmegaMapOptionsFrame.MiniMapIcon, "BOTTOMLEFT",  0,spacingY );
	getglobal(OmegaMapOptionsFrame.showCompactMode:GetName() .. 'Text'):SetText(OMEGAMAP_OPTIONS_COMPACT);
	OmegaMapOptionsFrame.showCompactMode.tooltip = OMEGAMAP_OPTIONS_COMPACT_TOOLTIP;
	OmegaMapOptionsFrame.showCompactMode:SetChecked(OmegaMapConfig.showCompactMode)
	OmegaMapOptionsFrame.showCompactMode:SetScript("OnClick", 
	  function()
		if (OmegaMapOptionsFrame.showCompactMode:GetChecked() ) then
			PlaySound("igMainMenuOptionCheckBoxOn");
			OmegaMapConfig.showCompactMode = true;
		else
			PlaySound("igMainMenuOptionCheckBoxOff");
			OmegaMapConfig.showCompactMode = false;
		end
		OmegaMapFrame_Update()
	  end
	);
--Interactive lock checkbox
	OmegaMapOptionsFrame.Interactive = CreateFrame("CheckButton", "OmegaMapOptionsInteractiveCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.Interactive:SetPoint("TOPLEFT", OmegaMapOptionsFrame.showHotSpot, "BOTTOMLEFT", 0, spacingY );
	getglobal(OmegaMapOptionsFrame.Interactive:GetName() .. 'Text'):SetText(OMEGAMAP_OPTIONS_INTERACTIVE);
	OmegaMapOptionsFrame.Interactive.tooltip = OMEGAMAP_OPTIONS_INTERACTIVE_TOOLTIP;
	OmegaMapOptionsFrame.Interactive:SetChecked(OmegaMapConfig.keepInteractive)
	OmegaMapOptionsFrame.Interactive:SetScript("OnClick", 
	  function()
		if (OmegaMapOptionsFrame.Interactive:GetChecked() ) then
			PlaySound("igMainMenuOptionCheckBoxOn");
			OmegaMapConfig.keepInteractive = true;
		else
			PlaySound("igMainMenuOptionCheckBoxOff");
			OmegaMapConfig.keepInteractive = false;
		end
	  end
	);

--Title
	OmegaMapOptionsFrame.HotKeyText = OmegaMapOptionsFrame.Frame:CreateFontString("HotKeyTitle")
		OmegaMapOptionsFrame.HotKeyText:SetPoint("TOPLEFT", OmegaMapOptionsFrame.showCompactMode , "BOTTOMLEFT", 0,spacingY )

	OmegaMapOptionsFrame.HotKeyText:SetFontObject("GameFontHighlight")
	OmegaMapOptionsFrame.HotKeyText:SetText("HotKey")
--Interactive Hotkey info
	local function setHotKeyText()
		local text = OmegaMapConfig.interactiveHotKey
		getglobal(OmegaMapOptionsFrame.HotKey:GetName() .. 'Text'):SetText(text);
	end

	local menu = { 
	    { text = "Select Map Interaction Hotkey", isTitle = true},
	    { text = "None", func = function() OmegaMapConfig.interactiveHotKey = "None"; setHotKeyText();  end },
	    { text = "Shift", func = function() OmegaMapConfig.interactiveHotKey = "Shift"; setHotKeyText(); end },
	    { text = "Ctrl", func = function() OmegaMapConfig.interactiveHotKey = "Ctrl"; setHotKeyText(); end },
	    { text = "Alt", func = function() OmegaMapConfig.interactiveHotKey = "Alt"; setHotKeyText(); end },
	    }

	OmegaMapOptionsFrame.HotKey = CreateFrame("Frame", "HotKey", OmegaMapOptionsFrame.Frame, "UIDropDownMenuTemplate")
	--getglobal(OmegaMapOptionsFrame.HotKey:GetName() .. 'Text'):SetText(OmegaMapConfig.interactiveHotKey);
	setHotKeyText()
	OmegaMapOptionsFrame.HotKeyButton = HotKeyButton
	OmegaMapOptionsFrame.HotKey:SetPoint("LEFT", OmegaMapOptionsFrame.HotKeyText , "RIGHT", -5,0 );

	OmegaMapOptionsFrame.HotKeyButton:SetScript("OnClick", function(self, button, down)
		EasyMenu(menu, OmegaMapOptionsFrame.HotKey, OmegaMapOptionsFrame.HotKey, 0 , 0, nil);
		end
		);

--Scale Slider Checkbox
	OmegaMapOptionsFrame.ScaleSliderTog = CreateFrame("CheckButton", "OmegaMapOptionsScaleCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.ScaleSliderTog:SetPoint("TOPRIGHT", OmegaMapOptionsFrame.Interactive, "BOTTOMLEFT", spacingX +50,  spacingY);
	getglobal(OmegaMapOptionsFrame.ScaleSliderTog:GetName() .. 'Text'):SetText(OMEGAMAP_OPTIONS_SCALESLIDER);
	OmegaMapOptionsFrame.ScaleSliderTog.tooltip = OMEGAMAP_OPTIONS_SCALESLIDER_TOOLTIP;
	OmegaMapOptionsFrame.ScaleSliderTog:SetChecked(OmegaMapConfig.showScale)
	OmegaMapOptionsFrame.ScaleSliderTog:SetScript("OnClick", 
	  function()
		if (OmegaMapOptionsFrame.ScaleSliderTog:GetChecked() ) then
			PlaySound("igMainMenuOptionCheckBoxOn");
			OmegaMapConfig.showScale = true;
			OmegaMapZoomSliderFrame:Show()
		else
			PlaySound("igMainMenuOptionCheckBoxOff");
			OmegaMapConfig.showScale = false;
			OmegaMapZoomSliderFrame:Hide()
		end
	  end
	);
--Scale Slider
	OmegaMapOptionsFrame.ScaleSlider = CreateFrame("Slider", "OmegaMapOptionsScaleSlider", OmegaMapOptionsFrame.Frame, "OptionsSliderTemplate");
	OmegaMapOptionsFrame.ScaleSlider:SetPoint("TOPRIGHT", OmegaMapOptionsFrame.Interactive, "BOTTOMLEFT", spacingX ,  spacingY);
	getglobal(OmegaMapOptionsFrame.ScaleSlider:GetName() .. 'Text'):SetText(OMEGAMAP_OPTIONS_SCALE);
	OmegaMapOptionsFrame.ScaleSlider.tooltip = OMEGAMAP_OPTIONS_SCALE_TOOLTIP;
	getglobal(OmegaMapOptionsFrame.ScaleSlider:GetName().."High"):SetText(maxScale);
	getglobal(OmegaMapOptionsFrame.ScaleSlider:GetName().."Low"):SetText(minScale);
	OmegaMapOptionsFrame.ScaleSlider:SetMinMaxValues(minScale/100,maxScale/100);
	OmegaMapOptionsFrame.ScaleSlider:SetValue(OmegaMapConfig.scale);
	OmegaMapOptionsFrame.ScaleSlider:SetValueStep(.01);
	OmegaMapOptionsFrame.ScaleSlider:SetScript("OnValueChanged",   
	  function()
		OmegaMapConfig.scale = OmegaMapOptionsFrame.ScaleSlider:GetValue();
		--OmegaMapFrame_SetOpacity(OMEGAMAP_SETTINGS.opacity);
		--AM_CurrentScale:SetText( math.floor( scale * 100 ).."%" );
		OmegaMapMasterFrame:SetScale( OmegaMapConfig.scale );
		OmegaMapZoomSliderFrame:SetValue(OmegaMapConfig.scale);
	  end
	);
		OmegaMapOptionsFrame.ScaleSlider:SetScript("OnEnter",   
	  function()
		OmegaMapBlobFrame:DrawBlob(GetSuperTrackedQuestID(), false);
	  end
	);
		OmegaMapOptionsFrame.ScaleSlider:SetScript("OnLeave",   
	  function()
		OmegaMapBlobFrame:DrawBlob(GetSuperTrackedQuestID(), true);
	  end
	);
--Plugin Subtitle
	OmegaMapOptionsFrame.SubTitle = OmegaMapOptionsFrame.Frame:CreateFontString("Title")
	OmegaMapOptionsFrame.SubTitle:SetPoint("Center", OmegaMapOptionsFrame.ScaleSlider, "TOP", 0, 3 *spacingY)
	OmegaMapOptionsFrame.SubTitle:SetFontObject("GameFontHighlight")
	OmegaMapOptionsFrame.SubTitle:SetText("Omega Map Plugin Options")
--Ruled Line
	OmegaMapOptionsFrame.Line2 = OmegaMapOptionsFrame.Frame:CreateTexture("Line2")
	OmegaMapOptionsFrame.Line2:SetTexture(1,1,1,0.2)
	OmegaMapOptionsFrame.Line2:SetHeight(2)
	OmegaMapOptionsFrame.Line2:SetWidth(300)
	OmegaMapOptionsFrame.Line2:SetPoint("Center", OmegaMapOptionsFrame.SubTitle, "TOP", 0, -20)
--Checkbox for the Gatherer Plugin Module
	OmegaMapOptionsFrame.Gatherer = CreateFrame("CheckButton", "OmegaMapOptionsGathererCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.Gatherer:SetPoint("TOPLEFT", OmegaMapOptionsFrame.Interactive, "BOTTOMLEFT", 0, spacingY *5 );
	OmegaMapOptionsFrame.ButtonInit("Gatherer", GathererOmegaMapOverlayParent)
--Checkbox for the GetherMate Plugin Module
	OmegaMapOptionsFrame.GatherMate = CreateFrame("CheckButton", "OmegaMapOptionsGatherMateCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.GatherMate:SetPoint("TOPLEFT", OmegaMapOptionsFrame.Gatherer, "TOPRIGHT", 225 ,0);
	OmegaMapOptionsFrame.ButtonInit("GatherMate", GatherMateOmegaMapOverlay)
--Checkbox for the Routes Plugin Module
	OmegaMapOptionsFrame.Routes = CreateFrame("CheckButton", "OmegaMapOptionsRoutesCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.Routes:SetPoint("TOPLEFT", OmegaMapOptionsFrame.Gatherer, "BOTTOMLEFT", 0, spacingY );
	OmegaMapOptionsFrame.ButtonInit("Routes", RoutesOmegaMapOverlay)
--Checkbox for the  NPCScan.Overlay  / NPCScanner Plugin Module
	OmegaMapOptionsFrame.NPCScanOverlay = CreateFrame("CheckButton", "OmegaMapOptionsNPCScanOverlayCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.NPCScanOverlay:SetPoint("TOPLEFT", OmegaMapOptionsFrame.Routes, "TOPRIGHT", 225 ,0 );
	OmegaMapOptionsFrame.ButtonInit("NPCScanOverlay", NPCScanOmegaMapOverlay)
--Checkbox for the TomTom Plugin Module
	OmegaMapOptionsFrame.TomTom = CreateFrame("CheckButton", "OmegaMapOptionsTomTomCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.TomTom:SetPoint("TOPLEFT", OmegaMapOptionsFrame.Routes, "BOTTOMLEFT", 0, spacingY );
	OmegaMapOptionsFrame.ButtonInit("TomTom", TomTomOmegaMapOverlay)
--Checkbox for the CTMap Mod Plugin Module
	OmegaMapOptionsFrame.CTMap = CreateFrame("CheckButton", "OmegaMapOptionsCTMapCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.CTMap:SetPoint("TOPLEFT", OmegaMapOptionsFrame.TomTom, "TOPRIGHT", 225 ,0 );
	OmegaMapOptionsFrame.ButtonInit("CTMap", CTMapOmegaMapOverlay)
--Checkbox for the MapNotes Plugin Module
	OmegaMapOptionsFrame.MapNotes = CreateFrame("CheckButton", "OmegaMapOptionsMapNotesCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.MapNotes:SetPoint("TOPLEFT", OmegaMapOptionsFrame.TomTom, "BOTTOMLEFT", 0, spacingY );
	OmegaMapOptionsFrame.ButtonInit("MapNotes", MapNotesOmegaMapOverlay)
--Checkbox for the QuestHelperLight Plugin Module
	OmegaMapOptionsFrame.QuestHelperLite = CreateFrame("CheckButton", "OmegaMapOptionsQuestHelperLiteCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.QuestHelperLite:SetPoint("TOPLEFT", OmegaMapOptionsFrame.MapNotes, "TOPRIGHT", 225, 0 );
	OmegaMapOptionsFrame.ButtonInit("QuestHelperLite", QHLOmegaMapOverlay)
--Checkbox for the HandyNotes Plugin Module
	OmegaMapOptionsFrame.HandyNotes = CreateFrame("CheckButton", "OmegaMapOptionsHandyNotesCheckbox", OmegaMapOptionsFrame.Frame, "ChatConfigCheckButtonTemplate");
	OmegaMapOptionsFrame.HandyNotes:SetPoint("TOPLEFT", OmegaMapOptionsFrame.MapNotes, "BOTTOMLEFT", 0, spacingY );
	OmegaMapOptionsFrame.ButtonInit("HandyNotes", HandyNotesOmegaMapOverlay)

	OmegaMapOptionsFrame.Frame:SetFrameStrata("FULLSCREEN_DIALOG")
	OmegaMapOptionsFrame.Frame:SetFrameLevel(100)
end


--Code to add Options toggle to Blizzard Interface menu

OmegaMapOptionsFrame.panel = CreateFrame( "Frame", "OmegaMapPanel", UIParent );
-- Register in the Interface Addon Options GUI
-- Set the name for the Category for the Options Panel
OmegaMapOptionsFrame.panel.name = "OmegaMap";
-- Add the panel to the Interface Options
InterfaceOptions_AddCategory(OmegaMapOptionsFrame.panel);
OmegaMapOptionsFrame.panel:SetScript("OnHide", function()  OmegaMapOptionsFrame.Frame:Hide() end)
-- Menu Title
OmegaMapOptionsFrame.IntOptionsSubTitle = OmegaMapOptionsFrame.panel:CreateFontString("Title")
OmegaMapOptionsFrame.IntOptionsSubTitle:SetPoint("TOPLEFT", OmegaMapOptionsFrame.panel, "TOPLEFT", 15, 2 *spacingY)
OmegaMapOptionsFrame.IntOptionsSubTitle:SetFontObject("GameFontHighlight")
OmegaMapOptionsFrame.IntOptionsSubTitle:SetText("Omega Map Options")
-- Menu button
OmegaMapOptionsFrame.IntOptions = CreateFrame("Button", "OmegaMapInterfaceOptionsButton", OmegaMapOptionsFrame.panel, "OptionsButtonTemplate")
OmegaMapOptionsFrame.IntOptions:SetPoint("TOPLEFT", OmegaMapOptionsFrame.IntOptionsSubTitle, "BOTTOMLEFT", 0, spacingY)
OmegaMapOptionsFrame.IntOptions:SetScript("OnClick", function() OmegaMapOptionsFrame.Toggle() end)
OmegaMapOptionsFrame.IntOptions:SetText("Config")
