-- Geometry for the arrow drawn on the ground at the player's feet. Pure.
-- World units: 512 per tile; x grows east, z grows north.
local GroundArrow = {}

GroundArrow.TILE = 512

-- Arrow outline in tile units: forward = along the facing, side = to the right of it.
-- Starts a little in front of the feet so the character does not hide the shaft.
local SHAPE = {
  { forward = 0.30, side = -0.12 }, -- 1 tail left
  { forward = 0.30, side = 0.12 },  -- 2 tail right
  { forward = 1.00, side = 0.12 },  -- 3 shaft end right
  { forward = 1.00, side = 0.36 },  -- 4 head base right
  { forward = 1.55, side = 0.00 },  -- 5 tip
  { forward = 1.00, side = -0.36 }, -- 6 head base left
  { forward = 1.00, side = -0.12 }, -- 7 shaft end left
}

-- Fill: shaft quad (1,2,3,7) + head triangle (4,5,6). Zero-based indices for ShapeData.
GroundArrow.TRIS = { 0, 1, 2, 0, 2, 6, 3, 4, 5 }

-- Closed outline around all seven points, as zero-based index pairs.
GroundArrow.LINES = { 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 0 }

---@param bearing number degrees clockwise from north
---@param scale number? size multiplier (1 = default)
---@return table[] points { x, z } offsets from the player's tile centre, in world units
function GroundArrow.points(bearing, scale)
  local radians = math.rad(bearing)
  local fx, fz = math.sin(radians), math.cos(radians)  -- forward
  local rx, rz = math.cos(radians), -math.sin(radians) -- right
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
