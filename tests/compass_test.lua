local A = require("assert")
local Compass = require("src/core/compass")

local T = {}

local function near(actual, expected, message)
  if math.abs(actual - expected) > 1e-9 then error((message or "") .. ": expected " .. expected .. ", got " .. actual, 2) end
end

function T.all_eight_labels_at_exact_bearings()
  local expected = { [0] = "N", [45] = "NE", [90] = "E", [135] = "SE", [180] = "S", [225] = "SW", [270] = "W", [315] = "NW" }
  for bearing, label in pairs(expected) do A.eq(Compass.label(bearing), label, "bearing " .. bearing) end
end

function T.sector_boundaries_round_to_nearest()
  A.eq(Compass.label(22.4), "N"); A.eq(Compass.label(22.5), "NE"); A.eq(Compass.label(337.4), "NW")
  A.eq(Compass.label(337.5), "N"); A.eq(Compass.label(359.9), "N"); A.eq(Compass.label(67.6), "E")
end

function T.wraps_negative_and_large_bearings()
  A.eq(Compass.label(-90), "W"); A.eq(Compass.label(720 + 135), "SE"); near(Compass.normalize(-1), 359)
end

function T.snap()
  A.eq(Compass.snap(50), 45); A.eq(Compass.snap(350), 0); A.eq(Compass.snap(200), 180)
end

function T.difference_is_shortest_way_round()
  A.eq(Compass.difference(350, 10), 20); A.eq(Compass.difference(0, 180), 180); A.eq(Compass.difference(90, 90), 0)
end

function T.step_bearing_on_game_grid()
  -- x grows east, z grows north
  A.eq(Compass.stepBearing(0, 0), nil)
  near(Compass.stepBearing(0, 1), 0, "north"); near(Compass.stepBearing(1, 1), 45, "north-east")
  near(Compass.stepBearing(1, 0), 90, "east"); near(Compass.stepBearing(1, -1), 135, "south-east")
  near(Compass.stepBearing(0, -2), 180, "south (running)"); near(Compass.stepBearing(-1, -1), 225, "south-west")
  near(Compass.stepBearing(-1, 0), 270, "west"); near(Compass.stepBearing(-1, 1), 315, "north-west")
end

function T.sprite_rotation_is_counter_clockwise()
  near(Compass.spriteRotation(0), 0, "north = unrotated")
  near(Compass.spriteRotation(90), math.rad(270), "east = 270 deg counter-clockwise")
  near(Compass.spriteRotation(180), math.pi, "south")
  near(Compass.spriteRotation(270), math.rad(90), "west = 90 deg counter-clockwise")
end

function T.unpack_colour()
  local r, g, b, a = Compass.unpackColour(0xFF8000FF)
  near(r, 1); near(g, 128 / 255); near(b, 0); near(a, 1)
  r, g, b, a = Compass.unpackColour(0x00000000)
  near(r + g + b + a, 0)
end

return T
