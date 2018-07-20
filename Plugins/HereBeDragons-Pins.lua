-- HereBeDragons-Pins is a library to show pins/icons on the world map and minimap

-- HereBeDragons-Pins-2.0 is not supported on WoW 7.x
local OmegaMap = select(2, ...)
OmegaMap = LibStub("AceAddon-3.0"):GetAddon("OmegaMap")

local MAJOR, MINOR = "HereBeDragons-Pins-2.0", 5
assert(LibStub, MAJOR .. " requires LibStub")

local pins, oldversion = LibStub:GetLibrary(MAJOR, MINOR)
if not pins then return end

local HBD = LibStub("HereBeDragons-2.0")

-- upvalue data tables
local minimapPins         = pins.minimapPins
local activeMinimapPins   = pins.activeMinimapPins
local minimapPinRegistry  = pins.minimapPinRegistry

local worldmapPins        = pins.worldmapPins
local worldmapPinRegistry = pins.worldmapPinRegistry
local worldmapPinsPool    = pins.worldmapPinsPool
local worldmapProvider    = pins.worldmapProvider
local worldmapProviderPin = pins.worldmapProviderPin


-- and worldmap pins
pins.omegamapPins         = pins.omegamapPins or {}
pins.omegamapPinRegistry  = pins.omegamapPinRegistry or {}
pins.omegamapPinsPool     = pins.omegamapPinsPool or CreateFramePool("FRAME")
pins.omegamapProvider     = pins.omegamapProvider or CreateFromMixins(worldmapProvider)
pins.omegamapProviderPin  = pins.omegamapProviderPin or CreateFromMixins(worldmapProviderPin)


-- upvalue data tables
local omegamapPins        = pins.omegamapPins
local omegamapPinRegistry = pins.omegamapPinRegistry
local omegamapPinsPool    = pins.omegamapPinsPool
local omegamapProvider    = pins.omegamapProvider
local omegamapProviderPin = pins.omegamapProviderPin


local tableCache = setmetatable({}, {__mode='k'})

local function newCachedTable()
    local t = next(tableCache)
    if t then
        tableCache[t] = nil
    else
        t = {}
    end
    return t
end

local function recycle(t)
    tableCache[t] = true
end


-- WorldMap data provider

-- setup pin pool
omegamapPinsPool.parent = OmegaMapFrame:GetCanvas()
omegamapPinsPool.creationFunc = function(framePool)
    local frame = CreateFrame(framePool.frameType, nil, framePool.parent)
    frame:SetSize(1, 1)
    return Mixin(frame, omegamapProviderPin)
end

-- register pin pool with the world map
OmegaMapFrame.pinPools["HereBeDragonsPinsTemplate"] = omegamapPinsPool


-- register with the world map
OmegaMap.Plugins["showTomTom"] = pins.omegamapProvider
--OmegaMapFrame:AddDataProvider(pins.omegamapProvider)
