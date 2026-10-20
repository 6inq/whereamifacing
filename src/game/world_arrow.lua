local Compass = require("src/core/compass")
local GroundArrow = require("src/core/ground_arrow")

local WorldArrow = {}
WorldArrow.__index = WorldArrow

local HEIGHT_OFFSET = 30
local OUTLINE_RGBA = 0x141414FF
local LINE_WIDTH = 2.0

function WorldArrow.new()
  return setmetatable({ shape = nil, signature = nil }, WorldArrow)
end

function WorldArrow.available()
  return rawget(_G, "ShapeList") ~= nil and rawget(_G, "ShapeData") ~= nil
    and rawget(_G, "World") ~= nil and rawget(_G, "Vector3") ~= nil
end

local function groundHeight(level, x, z)
  local ok, height, available = pcall(function() return World.GetGroundHeight(level, math.floor(x + 0.5), math.floor(z + 0.5)) end)
  if ok and available ~= false and type(height) == "number" then return height end
  return nil
end

local function buildShape(points, anchor, level, rgba)
  local data = ShapeData.new()
  local positions, colours = {}, {}
  for index, p in ipairs(points) do
    local height = groundHeight(level, anchor.x + p.x, anchor.z + p.z) or anchor.y
    positions[index] = Vector3.new(p.x, height - anchor.y + HEIGHT_OFFSET, p.z)
    colours[index] = rgba
  end
  local count = #positions
  local lines = {}
  for index = 1, count do
    positions[count + index] = positions[index]
    colours[count + index] = OUTLINE_RGBA
  end
  for index, value in ipairs(GroundArrow.LINES) do lines[index] = value + count end
  data.positions, data.rgba, data.tris, data.lines = positions, colours, GroundArrow.TRIS, lines
  return data
end

function WorldArrow:render(grid, bearing, rgba)
  if bearing == nil or grid == nil then
    self:clear()
    return false
  end
  local snapped = Compass.snap(bearing)
  local signature = table.concat({ grid.level, grid.x, grid.z, snapped, rgba }, ":")
  if signature == self.signature and self.shape then return true end

  local centre = grid:ToCoordFine(true).position
  local height = groundHeight(grid.level, centre.x, centre.z)
  if not height then return false end
  local anchor = Vector3.new(centre.x, height, centre.z)

  if not self.shape then
    self.shape = ShapeList.CreateInstance("where-am-i-facing:arrow")
    if not self.shape then return false end
  end
  if not self.shape:SetShapeData(buildShape(GroundArrow.points(snapped), anchor, grid.level, rgba)) then
    self:clear()
    return false
  end
  self.shape.translation = anchor
  self.shape.lineWidth = LINE_WIDTH
  self.shape.colour = 0xFFFFFFFF
  self.shape.ignoreDepth = false
  self.signature = signature
  return true
end

function WorldArrow:clear()
  if self.shape then pcall(function() return self.shape:Destroy() end) end
  self.shape, self.signature = nil, nil
end

return WorldArrow
