if IsAddOnLoaded("HandyNotes") then

HandyNotes = LibStub("AceAddon-3.0"):GetAddon("HandyNotes")
local HandyNotes = HandyNotes

local pinsHandler = {}
--custom function to interact with OmegaMap frame
function pinsHandler:OnClick(self, button, down)
local mapID = self.mapFile or self.uiMapID
local coord = self.coord
local parent = self:GetName()
	if button == "RightButton" and not down then
			--HandyNotes.plugins[self.pluginName].OnClick( self,button, down, self.mapFile, self.coord)

			HandyNotes.plugins[self.pluginName].OnClick( self, button, down, self.mapFile or self.uiMapID, self.coord)
			clickedMapID = mapID
			clickedCoord = coord
		elseif button == "LeftButton" and down and IsControlKeyDown() and IsShiftKeyDown() then
			-- Only move if we're viewing the same map as the icon's map
			if (mapID == OmegaMapFrame:GetMapID()) or (mapID == WorldMapFrame:GetMapID()) then
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
			local s = self:GetEffectiveScale() / parent.ScrollContainer.Child:GetEffectiveScale()
			x = x * s - parent.ScrollContainer.Child:GetLeft()
			y = y * s - parent.ScrollContainer.Child:GetTop()
			self:ClearAllPoints()
			self:SetParent(OmegaMapFrame.ScrollContainer.Child)
			self:SetPoint("CENTER", parent.ScrollContainer.Child, "TOPLEFT", x / self:GetScale(), y / self:GetScale())
			self:SetFrameStrata("TOOLTIP")
			self:SetUserPlaced(false)

			-- Get the new coordinate
			x = x / parent.ScrollContainer.Child:GetWidth()
			y = -y / parent.ScrollContainer.Child:GetHeight()
			-- Move the button back into the map if it was dragged outside
			if x < 0.001 then x = 0.001 end
			if x > 0.999 then x = 0.999 end
			if y < 0.001 then y = 0.001 end
			if y > 0.999 then y = 0.999 end
			local newCoord = HandyNotes:getCoord(x, y)
			-- Search in 4 directions till we find an unused coord
			local count = 0
			local zoneData = dbdata[mapID]
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
			dbdata[mapID][coord] = nil
			HN:SendMessage("HandyNotes_NotifyUpdate", "HandyNotes")
		end

end

--[[ Handy Notes WorldMap Pin ]]--
--OM_HandyNotesWorldMapPinMixin = CreateFromMixins(HandyNotesWorldMapPinMixin)
OM_HandyNotesWorldMapDataProvider = CreateFromMixins(HandyNotes.WorldMapDataProvider )

OmegaMapFrame:AddDataProvider(OM_HandyNotesWorldMapDataProvider)
--OmegaMapFrame:AddDataProvider(Display.OmegaMapDataProvider)


function HandyNotesWorldMapPinMixin:OnMouseDown(button)
	pinsHandler:OnClick(self, button, true)
end

function HandyNotesWorldMapPinMixin:OnMouseUp(button)
	pinsHandler:OnClick(self, button, false)
end


end