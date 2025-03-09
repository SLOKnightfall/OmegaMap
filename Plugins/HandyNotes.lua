if C_AddOns.IsAddOnLoaded("HandyNotes") then


local HandyNotes = LibStub("AceAddon-3.0"):GetAddon("HandyNotes")
local HN = HandyNotes:GetModule("HandyNotes")
local L = LibStub("AceLocale-3.0"):GetLocale("HandyNotes", false)
local HandyNotes = HandyNotes

local OmegaMap = select(2, ...)
OmegaMap = LibStub("AceAddon-3.0"):GetAddon("OmegaMap")
local PIN_DRAG_SCALE = 1.2
local pinsHandler = {}
local db = HandyNotes.db.profile


local hh = HandyNotes.plugins["HandyNotes"]

local HBD = LibStub("HereBeDragons-2.0")
local HBDPins = LibStub("HereBeDragons-Pins-2.0")
local HBDMigrate = LibStub("HereBeDragons-Migrate")

--[[ Handy Notes WorldMap Pin ]]--
HandyNotesOmegaMapPinMixin = CreateFromMixins(HandyNotesWorldMapPinMixin)
OM_HandyNotesWorldMapDataProvider = CreateFromMixins(HandyNotes.WorldMapDataProvider )

OmegaMap.Plugins["showHandyNotes"] = OM_HandyNotesWorldMapDataProvider




--OmegaMapFrame:AddDataProvider(OM_HandyNotesWorldMapDataProvider)



function HandyNotes:UpdateWorldMapPlugin(pluginName)
	HandyNotes.WorldMapDataProvider:RefreshPlugin(pluginName)
	if OmegaMapFrame.dataProviders[OM_HandyNotesWorldMapDataProvider] then 
		OM_HandyNotesWorldMapDataProvider:RefreshPlugin(pluginName)
	end
	
end

local function LegacyNodeIterator(t, state)
	local coord, mapFile2, iconpath, scale, alpha, level2 = t.iter(t.data, state)
	local uiMapID = HBDMigrate:GetUIMapIDFromMapFile(mapFile2 or t.mapFile, level2 or t.level)
	return coord, uiMapID, iconpath, scale, alpha
end

local emptyTbl = {}
local function IterateNodes(pluginName, uiMapID, minimap)
	local handler = HandyNotes.plugins[pluginName]
	assert(handler)
	if handler.GetNodes2 then
		return handler:GetNodes2(uiMapID, minimap)
	elseif handler.GetNodes then
		local mapID, level, mapFile = HBDMigrate:GetLegacyMapInfo(uiMapID)
		if not mapFile then
			return next, emptyTbl
		end
		local iter, data, state = handler:GetNodes(mapFile, minimap, level)
		local t = { mapFile = mapFile, level, iter = iter, data = data }
		return LegacyNodeIterator, t, state
	else
		error(("Plugin %s does not have GetNodes or GetNodes2"):format(pluginName))
	end
end



function OM_HandyNotesWorldMapDataProvider:RefreshPlugin(pluginName)
	for pin in self:GetMap():EnumeratePinsByTemplate("HandyNotesOmegaMapPinTemplate") do
		if pin.pluginName == pluginName then
			self:GetMap():RemovePin(pin)
		end
	end
	
	if not db.enabledPlugins[pluginName] then return end
	local uiMapID = self:GetMap():GetMapID()
	if not uiMapID then return end
	
	for coord, uiMapID2, iconpath, scale, alpha in IterateNodes(pluginName, uiMapID, false) do
		local x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000
		if uiMapID2 and uiMapID ~= uiMapID2 then
			x, y = HBD:TranslateZoneCoordinates(x, y, uiMapID2, uiMapID)
		end
		local mapFile
		if not HandyNotes.plugins[pluginName].GetNodes2 then
			mapFile = select(3, HBDMigrate:GetLegacyMapInfo(uiMapID2 or uiMapID))
		end
		self:GetMap():AcquirePin("HandyNotesOmegaMapPinTemplate", pluginName, x, y, iconpath, scale, alpha, coord, uiMapID2 or uiMapID, mapFile)
	end
end

function OM_HandyNotesWorldMapDataProvider:RemoveAllData()
	self:GetMap():RemoveAllPinsByTemplate("HandyNotesOmegaMapPinTemplate")
end

local click = {}
--custom function to interact with OmegaMap frame
function click:OnClick(self, button, down)
local mapID = self.mapFile or self.uiMapID
local coord = self.coord

	if button == "RightButton" and not down then
			--HandyNotes.plugins[self.pluginName].OnClick( self,button, down, self.mapFile, self.coord)

			HandyNotes.plugins[self.pluginName].OnClick( self, button, down, self.mapFile or self.uiMapID, self.coord)
			clickedMapID = mapID
			clickedCoord = coord
		elseif button == "LeftButton" and down and IsControlKeyDown() and IsShiftKeyDown() then
			-- Only move if we're viewing the same map as the icon's map
			if mapID == OmegaMapFrame:GetMapID() then
				isMoving = true
				movingPinScale = self:GetScale()
				local x, y = self:GetCenter()
				local s = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
				self:ClearAllPoints()
				self:SetParent(UIParent)
				self:SetScale(PIN_DRAG_SCALE)
				self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x * s / PIN_DRAG_SCALE, y * s / PIN_DRAG_SCALE)
				self:SetFrameStrata("TOOLTIP")
				self:StartMoving()
			end
		elseif isMoving and not down then
			isMoving = false
			self:StopMovingOrSizing()
			local x, y = self:GetCenter()
			if movingPinScale then
				x = x * PIN_DRAG_SCALE / movingPinScale
				y = y * PIN_DRAG_SCALE / movingPinScale
				self:SetScale(movingPinScale)
				movingPinScale = nil
			end
			local s = self:GetEffectiveScale() / OmegaMapFrame.ScrollContainer.Child:GetEffectiveScale()
			x = x * s - OmegaMapFrame.ScrollContainer.Child:GetLeft()
			y = y * s - OmegaMapFrame.ScrollContainer.Child:GetTop()
			self:ClearAllPoints()
			self:SetParent(OmegaMapFrame.ScrollContainer.Child)
			self:SetPoint("CENTER", OmegaMapFrame.ScrollContainer.Child, "TOPLEFT", x / self:GetScale(), y / self:GetScale())
			self:SetFrameStrata("TOOLTIP")
			self:SetUserPlaced(false)

			-- Get the new coordinate
			x = x / OmegaMapFrame.ScrollContainer.Child:GetWidth()
			y = -y / OmegaMapFrame.ScrollContainer.Child:GetHeight()
			-- Move the button back into the map if it was dragged outside
			if x < 0.001 then x = 0.001 end
			if x > 0.999 then x = 0.999 end
			if y < 0.001 then y = 0.001 end
			if y > 0.999 then y = 0.999 end
			local newCoord = HandyNotes:getCoord(x, y)
			-- Search in 4 directions till we find an unused coord
			local count = 0
			local zoneData = HNData[mapID]
			while true do
				if not zoneData[newCoord + count] then
					zoneData[newCoord + count] = zoneData[coord]
					break
				elseif not zoneData[newCoord - count] then
					zoneData[newCoord - count] = zoneData[coord]
					break
				elseif not zoneData[newCoord + count * 10000] then
					zoneData[newCoord + count*10000] = zoneData[coord]
					break
				elseif not zoneData[newCoord - count * 10000] then
					zoneData[newCoord - count*10000] = zoneData[coord]
					break
				end
				count = count + 1
			end
			HNData[mapID][coord] = nil
			HN:SendMessage("HandyNotes_NotifyUpdate", "HandyNotes")
		end
end

function HandyNotesOmegaMapPinMixin:OnMouseDown(button)
	click:OnClick(self, button, true)
end

function HandyNotesOmegaMapPinMixin:OnMouseUp(button)
	click:OnClick(self, button, false)
end


	--OmegaMapFrame:AddCanvasClickHandler(HandyNotes.OnCanvasClicked)

end