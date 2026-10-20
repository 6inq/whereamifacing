-- Small draggable window with a tinted arrow and the 8-point direction label.
local Compass = require("src/core/compass")

local Widget = {}
Widget.__index = Widget

local WIDTH, HEIGHT, ARROW = 132, 150, 56
Widget.CALIBRATING = "Walk a few steps in different directions to calibrate."

local function host()
  local ok, layer = pcall(function()
    return ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP)
  end)
  if ok then return layer end
  return nil
end

local function text(parent, y, height)
  local label = ui.Text.new(parent)
  label:SetPos(0, y)
  label:SetSize(WIDTH - 16, height)
  label.font = id.Font.MUSEO_SANS_15PT_REGULAR
  label.clickthrough = true
  pcall(function() label:AlignTo(ui.AlignMode.CENTRE) end)
  return label
end

---@param onClosed fun() called when the player closes the window with its X
function Widget.new(onClosed)
  return setmetatable({ onClosed = onClosed, window = nil }, Widget)
end

function Widget:_build()
  local layer = host()
  if not layer then return false end
  self.window = prettyui.Window.new(layer, {
    title = "Facing", width = WIDTH, height = HEIGHT, x = 24, y = 120,
    onClose = function() self.window = nil; self.onClosed() end, destroyOnClose = true,
  })
  local content = self.window.content
  self.arrow = ui.Sprite.new(content)
  self.arrow:SetSize(ARROW, ARROW)
  self.arrow:SetPos((WIDTH - 16 - ARROW) / 2, 4)
  self.arrow.sprite = Plugin.resources.arrow
  self.arrow.clickthrough = true
  self.label = text(content, ARROW + 8, 22)
  self.hint = text(content, ARROW + 30, 34)
  self.hint.maxLines = 0
  return true
end

function Widget:isOpen()
  return self.window ~= nil
end

---@param state table { bearing, source, calibrated, colour, showLabel }
function Widget:render(state)
  if not self.window and not self:_build() then return end
  local hasBearing = state.bearing ~= nil
  self.arrow.hidden = not hasBearing
  if hasBearing then
    self.arrow.rotationRadians = Compass.spriteRotation(Compass.snap(state.bearing))
    self.arrow.colour = Vector4.new(Compass.unpackColour(state.colour))
  end
  self.label.hidden = not state.showLabel
  self.label.content = hasBearing and Compass.label(state.bearing) or "?"
  self.hint.content = state.calibrated and "" or Widget.CALIBRATING
end

function Widget:close()
  if self.window then
    local window = self.window
    self.window = nil
    pcall(function() return window:Destroy() end)
  end
end

return Widget
