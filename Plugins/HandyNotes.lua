--	///////////////////////////////////////////////////////////////////////////////////////////

-- Code for HandyNotes Integration 
-- Code is a modified version of HandyNotes.lua from HandyNotes (v1.3.0)
-- HandyNotes is written by Xinhuan	@ http://www.curse.com/addons/wow/handynotes

--	///////////////////////////////////////////////////////////////////////////////////////////

if IsAddOnLoaded("HandyNotes") then

if not HandyNotesOmegaMapOverlay then
	local overlay = CreateFrame("Frame", "HandyNotesOmegaMapOverlay", OmegaMapNoteFrame)
	overlay:SetAllPoints(true)
end 

		
---------------------------------------------------------
-- Addon declaration
local HandyNotes = HandyNotes
local L = LibStub("AceLocale-3.0"):GetLocale("HandyNotes", false)
local HBD = LibStub("HereBeDragons-1.0")
local HBDPins = LibStub("HereBeDragons-Pins-1.0")


---------------------------------------------------------
-- Our db upvalue and db defaults
local hnotes = LibStub("AceAddon-3.0"):GetAddon("HandyNotes")
local db = hnotes.db.profile
local HN = hnotes:GetModule(("HandyNotes"))
local dbdata = HN.db.global
--[[
local db
local options
local defaults = {
	profile = {
		enabled       = true,
		icon_scale    = 1.0,
		icon_alpha    = 1.0,
		icon_scale_minimap = 1.0,
		icon_alpha_minimap = 1.0,
		enabledPlugins = {
			['*'] = true,
		},
	},
}
]]--
---------------------------------------------------------
-- Localize some globals
local floor = floor
local tconcat = table.concat
local pairs, next, type = pairs, next, type
local CreateFrame = CreateFrame
local GetCurrentMapContinent, GetCurrentMapZone = GetCurrentMapContinent, GetCurrentMapZone
local GetCurrentMapDungeonLevel = GetCurrentMapDungeonLevel
local GetRealZoneText = GetRealZoneText
local WorldMapButton, Minimap, OmegaMapOverlay = WorldMapButton, Minimap, HandyNotesOmegaMapOverlay

---------------------------------------------------------
-- xpcall safecall implementation, copied from AceAddon-3.0.lua
-- (included in distribution), with permission from nevcairiel
local xpcall = xpcall

local function errorhandler(err)
	return geterrorhandler()(err)
end

local function CreateDispatcher(argCount)
	local code = [[
		local xpcall, eh = ...
		local method, ARGS
		local function call() return method(ARGS) end
	
		local function dispatch(func, ...)
			 method = func
			 if not method then return end
			 ARGS = ...
			 return xpcall(call, eh)
		end
	
		return dispatch
	]]
	
	local ARGS = {}
	for i = 1, argCount do ARGS[i] = "arg"..i end
	code = code:gsub("ARGS", tconcat(ARGS, ", "))
	return assert(loadstring(code, "safecall Dispatcher["..argCount.."]"))(xpcall, errorhandler)
end

local Dispatchers = setmetatable({}, {__index=function(self, argCount)
	local dispatcher = CreateDispatcher(argCount)
	rawset(self, argCount, dispatcher)
	return dispatcher
end})
Dispatchers[0] = function(func)
	return xpcall(func, errorhandler)
end

local function safecall(func, ...)
	-- we check to see if the func is passed is actually a function here and don't error when it isn't
	-- this safecall is used for optional functions like OnInitialize OnEnable etc. When they are not
	-- present execution should continue without hinderance
	if type(func) == "function" then
		return Dispatchers[select('#', ...)](func, ...)
	end
end


---------------------------------------------------------
-- Our frames recycling code
local pinCache = {}
local minimapPins = {}
local worldmapPins = {}
local omegamapPins = {}
local pinCount = 0

local function recyclePin(pin)
	pin:Hide()
	pinCache[pin] = true
end

local function clearAllPins(t)
	for coord, pin in pairs(t) do
		recyclePin(pin)
		t[coord] = nil
	end
end

local function getNewPin()
	local pin = next(pinCache)
	if pin then
		pinCache[pin] = nil -- remove it from the cache
		return pin
	end
	-- create a new pin
	pinCount = pinCount + 1
	pin = CreateFrame("Button", "HandyNotesPin"..pinCount, OmegaMapOverlay)
	
	pin:SetFrameLevel(5)
	pin:EnableMouse(true)
	pin:SetWidth(12)
	pin:SetHeight(12)
	pin:SetPoint("CENTER", OmegaMapOverlay, "CENTER")
	local texture = pin:CreateTexture(nil, "OVERLAY")
	pin.texture = texture
	texture:SetAllPoints(pin)
	pin:RegisterForClicks("LeftButtonDown", "LeftButtonUp", "RightButtonDown", "RightButtonUp")
	pin:SetMovable(true)
	pin:Hide()
	return pin
end


---------------------------------------------------------
local pluginsOptionsText = {}
local pinsHandler = {}

 function pinsHandler:OnEnter(motion)
	OmegaMapBlobFrame:SetScript("OnUpdate", nil) -- override default UI to hide the tooltip
	safecall(HandyNotes.plugins[self.pluginName].OnEnter, self, self.mapFile, self.coord)

end

 function pinsHandler:OnLeave(motion)
	OmegaMapBlobFrame:SetScript("OnUpdate", OmegaMapBlobFrame_OnUpdate) -- restore default UI
	safecall(HandyNotes.plugins[self.pluginName].OnLeave, self, self.mapFile, self.coord)
end

--custom function to interact with OmegaMap frame
function pinsHandler:OnClick(button, down)
	if button == "RightButton" and not down then
			HandyNotes.plugins[self.pluginName].OnClick( self,button, down, self.mapFile, self.coord)
		elseif button == "LeftButton" and down and IsControlKeyDown() and IsShiftKeyDown() then
			-- Only move if we're viewing the same map as the icon's map
			if self.mapFile == HandyNotes:WhereAmI() or self.mapFile == "World" or self.mapFile == "Cosmic" then
				isMoving = true
				self:StartMoving()
			end
		elseif isMoving and not down then
			isMoving = false
			self:StopMovingOrSizing()
			-- Get the new coordinate
			local x, y = self:GetCenter()
			x = (x - OmegaMapOverlay:GetLeft()) / OmegaMapOverlay:GetWidth()
			y = (OmegaMapOverlay:GetTop() - y) / OmegaMapOverlay:GetHeight()
			-- Move the button back into the map if it was dragged outside
			if x < 0.001 then x = 0.001 end
			if x > 0.999 then x = 0.999 end
			if y < 0.001 then y = 0.001 end
			if y > 0.999 then y = 0.999 end
			local newCoord = HandyNotes:getCoord(x, y)
			-- Search in 4 directions till we find an unused coord
			local count = 0
			local zoneData = dbdata[self.mapFile]
			while true do
				if not zoneData[newCoord + count] then
					zoneData[newCoord + count] = zoneData[self.coord]
					break
				elseif not zoneData[newCoord - count] then
					zoneData[newCoord - count] = zoneData[self.coord]
					break
				elseif not zoneData[newCoord + count * 10000] then
					zoneData[newCoord + count*10000] = zoneData[self.coord]
					break
				elseif not zoneData[newCoord - count * 10000] then
					zoneData[newCoord - count*10000] = zoneData[self.coord]
					break
				end
				count = count + 1
			end
			dbdata[self.mapFile][self.coord] = nil
			HN:SendMessage("HandyNotes_NotifyUpdate", "HandyNotes")
		end

end


-- Build data
local reverseZoneC = {}
local reverseZoneZ = {}
local zonetoMapID = {}
local allMapIDs = HBD:GetAllMapIDs()
for _, mapID in pairs(allMapIDs) do
	local C, Z = HBD:GetCZFromMapID(mapID)
	local name = HBD:GetLocalizedMap(mapID)

	if name and C > 0 and Z >= 0 then
		reverseZoneC[name] = C
		reverseZoneZ[name] = Z

		-- always set here to prefer zones with valid C/Z
		zonetoMapID[name] = mapID
	end

	if name and not zonetoMapID[name] then
		zonetoMapID[name] = mapID
	end
end
allMapIDs = nil

local continentMapFile = {
	["Kalimdor"]              = HBD.continentZoneMap[1],
	["Azeroth"]               = HBD.continentZoneMap[2],
	["Expansion01"]           = HBD.continentZoneMap[3],
	["Northrend"]             = HBD.continentZoneMap[4],
	["TheMaelstromContinent"] = HBD.continentZoneMap[5],
	["Vashjir"]               = {[0] = 613, 614, 615, 610}, -- Vashjir isn't an actual continent, but the map treats it like one, so hardcode its 3 zones (+ continent map)
	["Pandaria"]              = HBD.continentZoneMap[6],
	["Draenor"]               = HBD.continentZoneMap[7],
}
--[[
-- Public function to get a list of zones in a continent
-- Note: This list is not an array, it uses the Z value as a key, which is not continous
function HandyNotes:GetContinentZoneList(mapFile)
	return continentMapFile[mapFile]
end

-- Public functions for plugins to convert between MapFile <-> C,Z
function HandyNotes:GetMapFile(C, Z)
	return HBD:GetMapFileFromID(HBD:GetMapIDFromCZ(C, Z))
end
function HandyNotes:GetCZ(mapFile)
	return HBD:GetCZFromMapID(HBD:GetMapIDFromFile(mapFile))
end

-- Public functions for plugins to convert between coords <--> x,y
function HandyNotes:getCoord(x, y)
	return floor(x * 10000 + 0.5) * 10000 + floor(y * 10000 + 0.5)
end
function HandyNotes:getXY(id)
	return floor(id / 10000) / 10000, (id % 10000) / 10000
end

-- Public functions for plugins to convert between GetRealZoneText() <-> C,Z
function HandyNotes:GetZoneToCZ(zone)
	return reverseZoneC[zone], reverseZoneZ[zone]
end
function HandyNotes:GetCZToZone(C, Z)
	return HBD:GetLocalizedMap(HBD:GetMapIDFromCZ(C, Z))
end

-- Public functions for plugins to convert between MapFile <-> Map ID
function HandyNotes:GetMapFiletoMapID(mapFile)
	return mapFile and HBD:GetMapIDFromFile(mapFile)
end
function HandyNotes:GetMapIDtoMapFile(mapID)
	return mapID and HBD:GetMapFileFromID(mapID)
end

-- Public function for plugins to convert between GetRealZoneText() <-> Map ID
function HandyNotes:GetZoneToMapID(zone)
	return zonetoMapID[zone]
end
--]]

---------------------------------------------------------
-- Core functions

-- This function updates all the icons of one plugin on the world map
local function UpdateOmegaMapPlugin(pluginName)
	if not OmegaMapOverlay:IsVisible() then return end
	--if not omegamapPins[pluginName] then return end
	HBDPins:RemoveAllWorldMapIcons("HandyNotes" .. pluginName)
	clearAllPins(omegamapPins[pluginName])
	if not db.enabledPlugins[pluginName] then return end
	local ourScale, ourAlpha = 12 * db.icon_scale, db.icon_alpha
	local mapFile, mapID, level = HandyNotes:WhereAmI()
	local pluginHandler = HandyNotes.plugins[pluginName]
	local frameLevel = OmegaMapOverlay:GetFrameLevel() + 5
	local frameStrata = OmegaMapOverlay:GetFrameStrata()
	for coord, mapFile2, iconpath, scale, alpha, level2 in pluginHandler:GetNodes(mapFile, false, level) do
		-- Scarlet Enclave check, only do stuff if we're on that map, since we have no zone translation for it yet in Astrolabe
		if mapFile2 ~= "ScarletEnclave" or mapFile2 == mapFile then
		local icon = getNewPin()
		icon:SetParent(OmegaMapOverlay)
		icon:SetFrameStrata(frameStrata)
		icon:SetFrameLevel(frameLevel)
		scale = ourScale * scale
		icon:SetHeight(scale) -- Can't use :SetScale as that changes our positioning scaling as well
		icon:SetWidth(scale)
		icon:SetAlpha(ourAlpha * alpha)
		local t = icon.texture
		if type(iconpath) == "table" then
			if iconpath.tCoordLeft then
				t:SetTexCoord(iconpath.tCoordLeft, iconpath.tCoordRight, iconpath.tCoordTop, iconpath.tCoordBottom)
			else
				t:SetTexCoord(0, 1, 0, 1)
			end
			if iconpath.r then
				t:SetVertexColor(iconpath.r, iconpath.g, iconpath.b, iconpath.a)
			else
				t:SetVertexColor(1, 1, 1, 1)
			end
			t:SetTexture(iconpath.icon)
		else
			t:SetTexCoord(0, 1, 0, 1)
			t:SetVertexColor(1, 1, 1, 1)
			t:SetTexture(iconpath)
		end
		icon:SetScript("OnClick", pinsHandler.OnClick)
		icon:SetScript("OnEnter", pinsHandler.OnEnter)
		icon:SetScript("OnLeave", pinsHandler.OnLeave)
		local x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000
		local mapID2 = HandyNotes:GetMapFiletoMapID(mapFile2 or mapFile)
		if not mapID2 then
			icon:ClearAllPoints()
			icon:SetPoint("CENTER", OmegaMapOverlay, "TOPLEFT", x*OmegaMapOverlay:GetWidth(), -y*OmegaMapOverlay:GetHeight())
			icon:Show()
		else
			HBDPins:AddWorldMapIconMF("HandyNotes" .. pluginName, icon, mapID2, level2 or level, x, y)
		end
		t:ClearAllPoints()
		t:SetAllPoints(icon) -- Not sure why this is necessary, but people are reporting weirdly sized textures
		omegamapPins[pluginName][(mapID2 or 0)*1e8 + coord] = icon
		icon.pluginName = pluginName
		icon.coord = coord
		icon.mapFile = mapFile2 or mapFile
		end
	end
end

--Hooking HandyNotes:UpdateWorldMap()
-- This function updates all the icons on the world map for every plugin
function HandyNotes:UpdateOmegaMap()
	if not OmegaMapOverlay:IsVisible() then return end
	for pluginName, pluginHandler in pairs(HandyNotes.plugins) do
		UpdateOmegaMapPlugin(pluginName)
--safecall(UpdateOmegaMapPlugin, HandyNotes, pluginName)
	end
end
hooksecurefunc(HandyNotes,"UpdateWorldMap", HandyNotes.UpdateOmegaMap);

--Hooking HandyNotes:UpdatePluginMap()
local function UpdatePluginMap(self ,message, pluginName)
	if HandyNotes.plugins[pluginName] then
		UpdateOmegaMapPlugin(pluginName)
	end

end
hooksecurefunc(HandyNotes,"UpdatePluginMap", UpdatePluginMap);


local function HandyNotes_OnClick(button, mouseButton,...)
	if mouseButton == "RightButton" and IsAltKeyDown() then
		local C, Z, L = GetCurrentMapContinent(), GetCurrentMapZone(), GetCurrentMapDungeonLevel()
		local mapFile = HandyNotes:WhereAmI()

		-- Get the coordinate clicked on
		local x, y = GetCursorPosition()
		local scale = button:GetEffectiveScale()
		x = (x/scale - button:GetLeft()) / button:GetWidth()
		y = (button:GetTop() - y/scale) / button:GetHeight()
		local coord = HandyNotes:getCoord(x, y)
		x, y = HandyNotes:getXY(coord)

		-- Pass the data to the edit note frame
		local HNEditFrame = HN.HNEditFrame
		HNEditFrame.x = x
		HNEditFrame.y = y
		HNEditFrame.coord = coord
		HNEditFrame.mapFile = mapFile
		HNEditFrame.level = L
		HN:FillDungeonLevelData()
		HNEditFrame:Hide() -- Hide first to trigger the OnShow handler
		HNEditFrame:Show()
	else
		return OmegaMapButton_OnClick(button, mouseButton,...)
	end
end

--Hooking HandyNotes:OnEnable()
local function OnEnable()
	HandyNotes:UpdateOmegaMap()
	OmegaMapButton:SetScript("OnClick",HandyNotes_OnClick)
end
hooksecurefunc(HandyNotes,"OnEnable", OnEnable); 

--Hooking HandyNotes:OnDisable()
local function OnDisable()
	-- Remove all the pins
	for pluginName, pluginHandler in pairs(HandyNotes.plugins) do
		clearAllPins(omegamapPins[pluginName])
	end
	OmegaMapButton:SetScript("OnClick",OmegaMapButton_OnClick)
end
hooksecurefunc(HandyNotes,"OnDisable", OnDisable); 

--Hooking HandyNotes:OnProfileChanged()
local function OnProfileChanged()
	HandyNotes:UpdateOmegaMap()
end
hooksecurefunc(HandyNotes,"OnProfileChanged", OnProfileChanged); 

--Hooking HandyNotes:RegisterPluginDB()
local function RegisterPluginDB(self, pluginName, pluginHandler, optionsTable)
	omegamapPins[pluginName] = {}
end
hooksecurefunc(HandyNotes,"RegisterPluginDB", RegisterPluginDB);

RegisterPluginDB("HandyNotes","HandyNotes", HNHandler, options)


print(OMEGAMAP_HANDYNOTES_LOADED_MESSAGE)

end