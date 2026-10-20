local Compass = require("src/core/compass")

local Calibration = {}
Calibration.__index = Calibration

Calibration.UNITS = { 2 * math.pi, 2048, 16384 }
Calibration.TOLERANCE = 22.5
Calibration.MIN_SAMPLES = 6
Calibration.MIN_DIRECTIONS = 3
Calibration.MIN_AGREEMENT = 0.8
Calibration.MAX_SAMPLES = 40

local function candidates()
  local list = {}
  for _, unit in ipairs(Calibration.UNITS) do
    for _, sign in ipairs({ 1, -1 }) do
      for _, offset in ipairs({ 0, 90, 180, 270 }) do
        list[#list + 1] = { unit = unit, sign = sign, offset = offset }
      end
    end
  end
  return list
end

Calibration.CANDIDATES = candidates()

function Calibration.isConvention(c)
  if type(c) ~= "table" or (c.sign ~= 1 and c.sign ~= -1) then return false end
  local knownUnit, knownOffset = false, false
  for _, unit in ipairs(Calibration.UNITS) do
    if type(c.unit) == "number" and math.abs(c.unit - unit) < 1e-6 then knownUnit = true end
  end
  for _, offset in ipairs({ 0, 90, 180, 270 }) do
    if c.offset == offset then knownOffset = true end
  end
  return knownUnit and knownOffset
end

function Calibration.toBearing(raw, convention)
  return Compass.normalize(convention.offset + convention.sign * (raw / convention.unit) * 360)
end

function Calibration.new(saved)
  local self = setmetatable({ samples = {}, convention = nil }, Calibration)
  if Calibration.isConvention(saved) then self.convention = saved end
  return self
end

function Calibration:isCalibrated()
  return self.convention ~= nil
end

function Calibration:reset()
  self.samples, self.convention = {}, nil
end

local function distinctDirections(samples)
  local seen, count = {}, 0
  for _, sample in ipairs(samples) do
    local sector = Compass.sector(sample.bearing)
    if not seen[sector] then seen[sector], count = true, count + 1 end
  end
  return count
end

local function score(convention, samples)
  local hits = 0
  for _, sample in ipairs(samples) do
    if Compass.difference(Calibration.toBearing(sample.raw, convention), sample.bearing) <= Calibration.TOLERANCE then
      hits = hits + 1
    end
  end
  return hits
end

function Calibration:_solve()
  local samples = self.samples
  if #samples < Calibration.MIN_SAMPLES or distinctDirections(samples) < Calibration.MIN_DIRECTIONS then return nil end
  local best, bestScore, runnerUp = nil, -1, -1
  for _, convention in ipairs(Calibration.CANDIDATES) do
    local s = score(convention, samples)
    if s > bestScore then
      best, runnerUp, bestScore = convention, bestScore, s
    elseif s > runnerUp then
      runnerUp = s
    end
  end
  if bestScore < #samples * Calibration.MIN_AGREEMENT or bestScore == runnerUp then return nil end
  return best
end

function Calibration:observe(raw, bearing)
  if self.convention or type(raw) ~= "number" or type(bearing) ~= "number" then return false end
  self.samples[#self.samples + 1] = { raw = raw, bearing = bearing }
  if #self.samples > Calibration.MAX_SAMPLES then table.remove(self.samples, 1) end
  self.convention = self:_solve()
  return self.convention ~= nil
end

function Calibration:bearing(raw)
  if not self.convention or type(raw) ~= "number" then return nil end
  return Calibration.toBearing(raw, self.convention)
end

return Calibration
