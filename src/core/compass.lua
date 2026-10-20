local Compass = {}

Compass.LABELS = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }

function Compass.normalize(degrees)
  local value = degrees % 360
  if value < 0 then value = value + 360 end
  return value
end

function Compass.difference(a, b)
  local diff = math.abs(Compass.normalize(a) - Compass.normalize(b))
  return math.min(diff, 360 - diff)
end

function Compass.sector(bearing)
  return math.floor(Compass.normalize(bearing) / 45 + 0.5) % 8 + 1
end

function Compass.label(bearing)
  return Compass.LABELS[Compass.sector(bearing)]
end

function Compass.snap(bearing)
  return (Compass.sector(bearing) - 1) * 45
end

function Compass.stepBearing(dx, dz)
  if dx == 0 and dz == 0 then return nil end
  return Compass.normalize(math.deg(math.atan(dx, dz)))
end

function Compass.spriteRotation(bearing)
  return math.rad(Compass.normalize(-bearing))
end

function Compass.unpackColour(rgba)
  rgba = math.floor(rgba)
  return ((rgba >> 24) & 0xFF) / 255, ((rgba >> 16) & 0xFF) / 255, ((rgba >> 8) & 0xFF) / 255, (rgba & 0xFF) / 255
end

return Compass
