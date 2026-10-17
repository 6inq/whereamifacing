local A = require("assert")
local Calibration = require("src/core/calibration")
local Compass = require("src/core/compass")

local T = {}

-- Inverse of toBearing: the raw value a client using `convention` would report.
local function rawFor(bearing, c)
  local turns = ((bearing - c.offset) * c.sign / 360) % 1
  return turns * c.unit
end

local WALK = { 0, 90, 180, 270, 45, 225, 135, 315, 0, 90 }

local function same(a, b)
  return math.abs(a.unit - b.unit) < 1e-6 and a.sign == b.sign and a.offset == b.offset
end

function T.recovers_every_plausible_convention()
  for _, truth in ipairs(Calibration.CANDIDATES) do
    local cal = Calibration.new()
    local done = false
    for _, bearing in ipairs(WALK) do
      if cal:observe(rawFor(bearing, truth), bearing) then done = true; break end
    end
    A.truthy(done, "calibrated for unit " .. truth.unit .. " sign " .. truth.sign .. " offset " .. truth.offset)
    A.truthy(same(cal.convention, truth), "picked the true convention")
    for bearing = 0, 315, 45 do
      A.eq(Compass.label(cal:bearing(rawFor(bearing, truth))), Compass.label(bearing))
    end
  end
end

function T.osrs_style_convention_example()
  -- RS2/OSRS orientation: 2048 units, 0 = south, 512 = west (clockwise as a compass bearing).
  local truth = { unit = 2048, sign = 1, offset = 180 }
  A.eq(Compass.label(Calibration.toBearing(0, truth)), "S")
  A.eq(Compass.label(Calibration.toBearing(512, truth)), "W")
  A.eq(Compass.label(Calibration.toBearing(1024, truth)), "N")
  A.eq(Compass.label(Calibration.toBearing(1536, truth)), "E")
end

function T.waits_for_enough_samples()
  local truth = { unit = 16384, sign = 1, offset = 0 }
  local cal = Calibration.new()
  for index = 1, Calibration.MIN_SAMPLES - 1 do cal:observe(rawFor(WALK[index], truth), WALK[index]) end
  A.eq(cal:isCalibrated(), false); A.eq(cal:bearing(123), nil)
end

function T.waits_for_direction_variety()
  local cal = Calibration.new()
  for _ = 1, 20 do cal:observe(rawFor(90, Calibration.CANDIDATES[1]), 90) end
  for _ = 1, 20 do cal:observe(rawFor(270, Calibration.CANDIDATES[1]), 270) end
  A.eq(cal:isCalibrated(), false, "walking back and forth on one axis is ambiguous")
end

function T.tolerates_noisy_samples()
  local truth = { unit = 2048, sign = 1, offset = 180 }
  local cal = Calibration.new()
  local bearings = { 0, 90, 180, 270, 45, 225, 135, 315, 0, 90, 180, 270 }
  for index, bearing in ipairs(bearings) do
    local raw = rawFor(bearing, truth)
    if index == 3 then raw = rawFor(bearing + 120, truth) end -- facing an NPC mid-walk
    raw = raw + (index % 2 == 0 and 30 or -30)                -- small turn lag
    cal:observe(raw, bearing)
  end
  A.truthy(cal:isCalibrated()); A.truthy(same(cal.convention, truth))
end

function T.rejects_garbage_and_never_guesses()
  local cal = Calibration.new()
  for index = 1, 30 do cal:observe((index * 7919) % 16384, WALK[(index % #WALK) + 1]) end
  A.eq(cal:isCalibrated(), false, "random facing data explains nothing")
  A.eq(cal:observe("x", 10), false); A.eq(cal:observe(10, nil), false)
end

function T.saved_convention_is_used_and_validated()
  A.eq(Calibration.new({ unit = 2048, sign = 1, offset = 180 }):isCalibrated(), true)
  A.eq(Calibration.new({ unit = 999, sign = 1, offset = 0 }):isCalibrated(), false)
  A.eq(Calibration.new({ unit = 2048, sign = 3, offset = 0 }):isCalibrated(), false)
  A.eq(Calibration.new("junk"):isCalibrated(), false)
end

function T.reset_forgets()
  local cal = Calibration.new({ unit = 2048, sign = 1, offset = 0 })
  cal:reset()
  A.eq(cal:isCalibrated(), false); A.eq(#cal.samples, 0)
end

return T
