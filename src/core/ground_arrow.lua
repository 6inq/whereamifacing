local GroundArrow = {}

GroundArrow.TILE = 512

local SHAPE = {
  { forward = 0.30, side = -0.12 },
  { forward = 0.30, side = 0.12 },
  { forward = 1.00, side = 0.12 },
  { forward = 1.00, side = 0.36 },
  { forward = 1.55, side = 0.00 },
  { forward = 1.00, side = -0.36 },
  { forward = 1.00, side = -0.12 },
}

GroundArrow.TRIS = { 0, 1, 2, 0, 2, 6, 3, 4, 5 }

GroundArrow.LINES = { 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 0 }

function GroundArrow.points(bearing, scale)
  local radians = math.rad(bearing)
  local fx, fz = math.sin(radians), math.cos(radians)
  local rx, rz = math.cos(radians), -math.sin(radians)
  local size = GroundArrow.TILE * (scale or 1)
  local points = {}
  for index, p in ipairs(SHAPE) do
    points[index] = {
      x = (fx * p.forward + rx * p.side) * size,
      z = (fz * p.forward + rz * p.side) * size,
    }
  end
  return points
end

return GroundArrow
