-- Compass math. Bearings are degrees clockwise from north, in [0, 360).
local Compass = {}

Compass.LABELS = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }

function Compass.normalize(degrees)
  local value = degrees % 360
  if value < 0 then value = value + 360 end
  return value
end

-- Smallest absolute difference between two bearings, 0..180.
function Compass.difference(a, b)
  local diff = math.abs(Compass.normalize(a) - Compass.normalize(b))
  return math.min(diff, 360 - diff)
end

-- Index into LABELS (1..8) of the nearest of the 8 directions.
function Compass.sector(bearing)
  return math.floor(Compass.normalize(bearing) / 45 + 0.5) % 8 + 1
end

function Compass.label(bearing)
  return Compass.LABELS[Compass.sector(bearing)]
end

-- Bearing snapped to the nearest of the 8 directions.
function Compass.snap(bearing)
  return (Compass.sector(bearing) - 1) * 45
end

-- Bearing of a step on the game grid (x grows east, z grows north). nil if no movement.
function Compass.stepBearing(dx, dz)
  if dx == 0 and dz == 0 then return nil end
  return Compass.normalize(math.deg(math.atan(dx, dz)))
end

-- Sprite rotation for an arrow image that points north (up) at rotation 0.
-- Engine rotation is counter-clockwise on screen (inferred from Quest Helper's arrow code),
-- while bearings are clockwise, hence the negation.
function Compass.spriteRotation(bearing)
  return math.rad(Compass.normalize(-bearing))
end

-- 0xRRGGBBAA -> r, g, b, a in 0..1 (for a sprite's Vector4 colour tint).
function Compass.unpackColour(rgba)
  rgba = math.floor(rgba)
  return ((rgba >> 24) & 0xFF) / 255, ((rgba >> 16) & 0xFF) / 255, ((rgba >> 8) & 0xFF) / 255, (rgba & 0xFF) / 255
end

return Compass
