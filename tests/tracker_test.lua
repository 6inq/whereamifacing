local A = require("assert")
local Tracker = require("src/core/tracker")
local Calibration = require("src/core/calibration")
local Compass = require("src/core/compass")

local T = {}

local OSRS = { unit = 2048, sign = 1, offset = 180 }
local function rawFor(bearing, c) return (((bearing - c.offset) * c.sign / 360) % 1) * c.unit end

local STEPS = { -- dx, dz per tick
  N = { 0, 1 }, NE = { 1, 1 }, E = { 1, 0 }, SE = { 1, -1 }, S = { 0, -1 }, SW = { -1, -1 }, W = { -1, 0 }, NW = { -1, 1 },
}
local BEARING = { N = 0, NE = 45, E = 90, SE = 135, S = 180, SW = 225, W = 270, NW = 315 }

-- Walk `ticks` steps in `dir`, reporting the true facing in the given convention.
local function walk(tracker, pos, dir, ticks, convention)
  local bearing, source
  for _ = 1, ticks do
    pos.x, pos.z = pos.x + STEPS[dir][1], pos.z + STEPS[dir][2]
    bearing, source = tracker:update({ x = pos.x, z = pos.z, facing = rawFor(BEARING[dir], convention or OSRS) })
  end
  return bearing, source
end

function T.unknown_before_any_movement()
  local tracker = Tracker.new()
  local bearing, source = tracker:update({ x = 10, z = 10, facing = 5 })
  A.eq(bearing, nil); A.eq(source, nil)
end

function T.walking_direction_used_until_calibrated()
  local tracker = Tracker.new()
  local pos = { x = 0, z = 0 }
  tracker:update({ x = 0, z = 0, facing = 0 })
  for dir in pairs(STEPS) do
    local bearing, source = walk(tracker, pos, dir, 1)
    A.eq(Compass.label(bearing), dir); A.eq(source, Tracker.SOURCE_WALKING)
    tracker:recalibrate()
  end
end

function T.keeps_last_direction_while_standing_still()
  local tracker = Tracker.new()
  local pos = { x = 0, z = 0 }
  tracker:update({ x = 0, z = 0 })
  walk(tracker, pos, "SW", 1)
  local bearing = tracker:update({ x = pos.x, z = pos.z })
  A.eq(Compass.label(bearing), "SW")
end

function T.calibrates_from_a_short_walk_then_uses_facing()
  local learned
  local tracker = Tracker.new(nil, function(c) learned = c end)
  local pos = { x = 0, z = 0 }
  tracker:update({ x = 0, z = 0, facing = 0 })
  for _, dir in ipairs({ "N", "E", "S", "W" }) do walk(tracker, pos, dir, 3) end
  A.truthy(tracker:isCalibrated(), "calibrated after a lap"); A.eq(learned.unit, 2048)
  -- Standing still and turning (e.g. to face an NPC): facing wins over the last walk.
  local bearing, source = tracker:update({ x = pos.x, z = pos.z, facing = rawFor(135, OSRS) })
  A.eq(Compass.label(bearing), "SE"); A.eq(source, Tracker.SOURCE_FACING)
end

function T.first_step_after_a_turn_is_not_a_sample()
  local tracker = Tracker.new()
  local pos = { x = 0, z = 0 }
  tracker:update({ x = 0, z = 0, facing = 0 })
  for _, dir in ipairs({ "N", "E", "S", "W", "NE", "SW", "N", "E" }) do walk(tracker, pos, dir, 1) end
  A.eq(#tracker.calibration.samples, 0, "zig-zag single steps never calibrate")
end

function T.saved_convention_applies_immediately()
  local tracker = Tracker.new(OSRS)
  local bearing, source = tracker:update({ x = 1, z = 1, facing = 1024 })
  A.eq(Compass.label(bearing), "N"); A.eq(source, Tracker.SOURCE_FACING)
end

function T.missing_facing_still_works_from_walking()
  local tracker = Tracker.new()
  local pos = { x = 0, z = 0 }
  tracker:update({ x = 0, z = 0 })
  for _ = 1, 5 do
    pos.x = pos.x + 1
    tracker:update({ x = pos.x, z = pos.z, facing = nil })
  end
  local bearing, source = tracker:current()
  A.eq(Compass.label(bearing), "E"); A.eq(source, Tracker.SOURCE_WALKING)
end

function T.unavailable_player_keeps_state()
  local tracker = Tracker.new(OSRS)
  tracker:update({ x = 0, z = 0, facing = 512 })
  local bearing = tracker:update(nil)
  A.eq(Compass.label(bearing), "W")
end

function T.every_convention_end_to_end()
  for _, truth in ipairs(Calibration.CANDIDATES) do
    local tracker = Tracker.new()
    local pos = { x = 0, z = 0 }
    tracker:update({ x = 0, z = 0, facing = 0 })
    for _, dir in ipairs({ "N", "E", "S", "W", "NE", "SW" }) do walk(tracker, pos, dir, 3, truth) end
    A.truthy(tracker:isCalibrated())
    local bearing = tracker:update({ x = pos.x, z = pos.z, facing = rawFor(315, truth) })
    A.eq(Compass.label(bearing), "NW")
  end
end

return T
