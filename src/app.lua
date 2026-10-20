local Tracker = require("src/core/tracker")
local Widget = require("src/ui/compass_widget")
local WorldArrow = require("src/game/world_arrow")

local App = {}
App.__index = App

local EVENT_ID = "where-am-i-facing:tick"

function App.new(store)
  local self = setmetatable({ store = store, signature = nil }, App)
  self.tracker = Tracker.new(store.convention, function(convention) store:setConvention(convention) end)
  self.widget = Widget.new(function()
    store:set("showCompass", false)
    if not WorldArrow.available() then store:set("showGroundArrow", false) end
  end)
  self.worldArrow = WorldArrow.new()
  return self
end

local function readPlayer()
  local ok, sample = pcall(function()
    if not Player.IsAvailable() then return nil end
    local entity = Player.GetEntity()
    local grid = entity and entity.coordGrid
    if not grid then return nil end
    return { x = grid.x, z = grid.z, facing = entity.facing, grid = grid }
  end)
  if ok then return sample end
  return nil
end

function App:state()
  local bearing, source = self.tracker:current()
  return {
    bearing = bearing, source = source, calibrated = self.tracker:isCalibrated(),
    colour = self.store:get("arrowColour"), showLabel = self.store:get("showLabel"),
  }
end

function App:wantsWindow()
  return self.store:get("showCompass") or (self.store:get("showGroundArrow") and not WorldArrow.available())
end

function App:drawGround()
  if not self.store:get("showGroundArrow") or not WorldArrow.available() then
    self.worldArrow:clear()
    return
  end
  local bearing = self.tracker:current()
  local ok, err = pcall(function() return self.worldArrow:render(self.grid, bearing, self.store:get("arrowColour")) end)
  if not ok and log then log("[where-am-i-facing] ground arrow failed: " .. tostring(err)) end
end

function App:redraw(force)
  self:drawGround()
  if not self:wantsWindow() then
    self.widget:close()
    self.signature = nil
    return
  end
  local state = self:state()
  local snapped = state.bearing and math.floor(state.bearing / 45 + 0.5) % 8 or "-"
  local signature = table.concat({ tostring(snapped), tostring(state.calibrated), tostring(state.colour),
    tostring(state.showLabel), tostring(self.widget:isOpen()) }, "|")
  if force or signature ~= self.signature then
    self.signature = signature
    local ok, err = pcall(function() return self.widget:render(state) end)
    if not ok and log then log("[where-am-i-facing] render failed: " .. tostring(err)) end
  end
end

function App:tick()
  local sample = readPlayer()
  self.grid = sample and sample.grid or self.grid
  self.tracker:update(sample)
  self:redraw(false)
end

function App:recalibrate()
  self.tracker:recalibrate()
  self.store:setConvention(nil)
  self:redraw(true)
end

function App:start()
  Event.Logic.Subscribe(EVENT_ID, function() self:tick() end)
end

function App:stop()
  pcall(function() return Event.Logic.Unsubscribe(EVENT_ID) end)
  self.widget:close()
  self.worldArrow:clear()
end

return App
