-- Turns per-tick player samples (tile position + raw facing) into a compass bearing.
-- Uses the calibrated facing when known, otherwise the last walking direction. Pure.
local Compass = require("src/core/compass")
local Calibration = require("src/core/calibration")

local Tracker = {}
Tracker.__index = Tracker

Tracker.SOURCE_FACING = "facing"
Tracker.SOURCE_WALKING = "walking"

---@param savedConvention table? learned facing convention from a previous session
---@param onCalibrated fun(convention: table)? called once when calibration completes
function Tracker.new(savedConvention, onCalibrated)
  return setmetatable({
    calibration = Calibration.new(savedConvention), onCalibrated = onCalibrated,
    last = nil, lastStep = nil, walkBearing = nil,
  }, Tracker)
end

-- Only straight-line steps calibrate: the character may still be turning on the first step.
function Tracker:_onStep(bearing, facing)
  if self.lastStep == bearing and self.calibration:observe(facing, bearing) and self.onCalibrated then
    self.onCalibrated(self.calibration.convention)
  end
  self.lastStep = bearing
end

---@param sample table? { x, z, facing } or nil when the player is unavailable
---@return number? bearing, string? source
function Tracker:update(sample)
  if not sample or type(sample.x) ~= "number" or type(sample.z) ~= "number" then return self:current() end
  local last = self.last
  self.last = { x = sample.x, z = sample.z }
  if last then
    local bearing = Compass.stepBearing(sample.x - last.x, sample.z - last.z)
    if bearing then
      self.walkBearing = bearing
      self:_onStep(bearing, sample.facing)
    else
      self.lastStep = nil
    end
  end
  self.facing = sample.facing
  return self:current()
end

function Tracker:current()
  local fromFacing = self.calibration:bearing(self.facing)
  if fromFacing then return fromFacing, Tracker.SOURCE_FACING end
  if self.walkBearing then return self.walkBearing, Tracker.SOURCE_WALKING end
  return nil, nil
end

function Tracker:isCalibrated()
  return self.calibration:isCalibrated()
end

function Tracker:recalibrate()
  self.calibration:reset()
  self.lastStep = nil
end

return Tracker
