local A = require("assert")
local GroundArrow = require("src/core/ground_arrow")

local T = {}
local TILE = GroundArrow.TILE

local function near(a, b, message)
  if math.abs(a - b) > 1e-6 then error((message or "") .. ": expected " .. b .. ", got " .. a, 2) end
end

local TIP, TAIL_LEFT, HEAD_RIGHT = 5, 1, 4

function T.north_arrow_points_up_the_z_axis()
  local p = GroundArrow.points(0)
  near(p[TIP].x, 0, "tip x"); near(p[TIP].z, 1.55 * TILE, "tip z")
  near(p[TAIL_LEFT].x, -0.12 * TILE, "left is west"); near(p[TAIL_LEFT].z, 0.30 * TILE)
end

function T.each_direction_tip_goes_the_right_way()
  local expect = { [0] = { 0, 1 }, [90] = { 1, 0 }, [180] = { 0, -1 }, [270] = { -1, 0 } }
  for bearing, dir in pairs(expect) do
    local tip = GroundArrow.points(bearing)[TIP]
    near(tip.x, dir[1] * 1.55 * TILE, bearing .. " x"); near(tip.z, dir[2] * 1.55 * TILE, bearing .. " z")
  end
  local ne = GroundArrow.points(45)[TIP]
  A.truthy(ne.x > 0 and ne.z > 0 and math.abs(ne.x - ne.z) < 1e-6, "NE tip is diagonal")
end

function T.right_side_is_clockwise_of_forward()
  near(GroundArrow.points(90)[HEAD_RIGHT].z, -0.36 * TILE)
end

function T.starts_ahead_of_the_feet()
  for bearing = 0, 315, 45 do
    for _, p in ipairs(GroundArrow.points(bearing)) do
      A.truthy(math.sqrt(p.x * p.x + p.z * p.z) >= 0.30 * TILE - 1e-6, "no point under the character")
    end
  end
end

function T.scale()
  near(GroundArrow.points(0, 2)[TIP].z, 3.10 * TILE)
end

function T.indices_are_valid_and_zero_based()
  local count = #GroundArrow.points(0)
  A.eq(#GroundArrow.TRIS % 3, 0); A.eq(#GroundArrow.LINES % 2, 0)
  for _, list in ipairs({ GroundArrow.TRIS, GroundArrow.LINES }) do
    for _, index in ipairs(list) do A.truthy(index >= 0 and index < count, "index " .. index) end
  end
  local used = {}
  for _, index in ipairs(GroundArrow.LINES) do used[index] = true end
  for index = 0, count - 1 do A.truthy(used[index], "outline visits point " .. index) end
end

return T
