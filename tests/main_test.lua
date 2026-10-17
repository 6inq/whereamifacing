-- Boots main.lua with a stubbed client + PrettyUI and checks what the player would see.
local A = require("assert")
local Store = require("src/core/store")
local Compass = require("src/core/compass")

local T = {}

local function memoryDb()
  local db = { data = {} }
  function db:GetStructuredData(key) return self.data[key] end
  function db:SetStructuredData(key, value) self.data[key] = value end
  return db
end

local function boot(opts)
  opts = opts or {}
  local env = { events = {}, windows = {}, settings = {}, created = {}, player = opts.player }
  local function component(kind)
    local c = { kind = kind, hidden = false }
    function c:SetPos(x, y) self.x, self.y = x, y end
    function c:SetSize(w, h) self.width, self.height = w, h end
    function c:AlignTo() end
    env.created[#env.created + 1] = c
    return c
  end
  local function bus(name)
    return { Subscribe = function(k, f) env.events[name .. ":" .. k] = f end,
      Unsubscribe = function(k) env.events[name .. ":" .. k] = nil end }
  end
  _G.Event = { Logic = bus("Logic"), SettingsLayerReady = bus("Settings") }
  _G.ui = {
    Sprite = { new = function() return component("sprite") end },
    Text = { new = function() return component("text") end },
    Interfaces = { GetComponent = function() return { kind = "host" } end },
    AlignMode = { CENTRE = 1 },
  }
  _G.id = { Component = { TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP = 1 }, Font = { MUSEO_SANS_15PT_REGULAR = 1 } }
  _G.Vector4 = { new = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end }
  _G.Plugin = { resources = { arrow = "arrow-resource" } }
  _G.log = function() end
  _G.Player = {
    IsAvailable = function() return env.player ~= nil end,
    GetEntity = function()
      local x, z = env.player.x, env.player.z
      local grid = { x = x, z = z, level = 0 }
      function grid:ToCoordFine() return { position = { x = x * 512 + 256, z = z * 512 + 256 } } end
      return { coordGrid = grid, facing = env.player.facing }
    end,
  }
  _G.ShapeList, _G.ShapeData, _G.World, _G.Vector3 = nil, nil, nil, nil
  env.shapes = {}
  if opts.world then
    _G.Vector3 = { new = function(x, y, z) return { x = x, y = y, z = z } end }
    _G.ShapeData = { new = function() return {} end }
    _G.World = { GetGroundHeight = function(_, x, z) return (opts.slope or 0) * x, true end }
    _G.ShapeList = { CreateInstance = function(name)
      local shape = { name = name, destroyed = false }
      function shape:SetShapeData(data) self.data = data; return true end
      function shape:Destroy() self.destroyed = true end
      env.shapes[#env.shapes + 1] = shape
      return shape
    end }
  end
  _G.PersistentDB = memoryDb()
  if opts.saved then PersistentDB:SetStructuredData(Store.KEY, opts.saved) end
  _G.prettyui = {
    Window = { new = function(_, o)
      local w = { options = o, content = { kind = "content" }, destroyed = false }
      function w:Destroy() self.destroyed = true end
      env.windows[#env.windows + 1] = w
      return w
    end },
    SimpleView = { new = function()
      return setmetatable({}, { __index = function(_, method)
        if method == "Destroy" then return function() end end
        return function(_, ...)
          local call = { method = method, args = { ... } }
          env.settings[#env.settings + 1] = call
          return call
        end
      end })
    end },
  }
  for key in pairs(package.loaded) do if key:match("^src/") then package.loaded[key] = nil end end
  dofile("main.lua")
  return env
end

local function tick(env) env.events["Logic:where-am-i-facing:tick"]() end

-- The widget creates: arrow sprite, direction label, calibration hint (in that order).
local function view(env)
  local sprite, texts = nil, {}
  for _, c in ipairs(env.created) do
    if c.kind == "sprite" then sprite = c elseif c.kind == "text" then texts[#texts + 1] = c end
  end
  return { arrow = sprite, label = texts[#texts - 1], hint = texts[#texts], window = env.windows[#env.windows] }
end

local function near(a, b) return math.abs(a - b) < 1e-9 end

function T.opens_with_question_mark_and_hint_before_moving()
  local env = boot({ player = { x = 5, z = 5, facing = 0 } })
  tick(env)
  local v = view(env)
  A.truthy(v.window and not v.window.destroyed, "compass window open")
  A.eq(v.window.options.title, "Facing")
  A.eq(v.arrow.sprite, "arrow-resource"); A.eq(v.arrow.hidden, true, "no arrow until a direction is known")
  A.eq(v.label.content, "?"); A.truthy(v.hint.content:find("Walk a few steps", 1, true))
  PluginShutdown()
end

function T.walking_points_arrow_and_shows_label_in_chosen_colour()
  local env = boot({ player = { x = 0, z = 0, facing = 0 } })
  tick(env)
  env.player.x, env.player.z = 1, 1 -- north-east step
  tick(env)
  local v = view(env)
  A.eq(v.arrow.hidden, false); A.eq(v.label.content, "NE")
  A.truthy(near(v.arrow.rotationRadians, Compass.spriteRotation(45)), "arrow rotated to NE")
  local r, g, b = Compass.unpackColour(Store.DEFAULT_COLOUR)
  A.truthy(near(v.arrow.colour.r, r) and near(v.arrow.colour.g, g) and near(v.arrow.colour.b, b), "default gold tint")
  PluginShutdown()
end

function T.saved_calibration_uses_facing_without_walking()
  local env = boot({ player = { x = 0, z = 0, facing = 1024 }, saved = { convention = { unit = 2048, sign = 1, offset = 180 } } })
  tick(env)
  local v = view(env)
  A.eq(v.label.content, "N"); A.eq(v.hint.content, "", "no calibration hint once calibrated")
  env.player.facing = 1536
  tick(env)
  A.eq(view(env).label.content, "E", "turning in place updates the arrow")
  PluginShutdown()
end

function T.calibration_learned_in_game_is_saved()
  local env = boot({ player = { x = 0, z = 0, facing = 0 } })
  local raw = { N = 1024, E = 1536, S = 0, W = 512 }
  local step = { N = { 0, 1 }, E = { 1, 0 }, S = { 0, -1 }, W = { -1, 0 } }
  tick(env)
  for _, dir in ipairs({ "N", "E", "S", "W" }) do
    for _ = 1, 3 do
      env.player.x, env.player.z = env.player.x + step[dir][1], env.player.z + step[dir][2]
      env.player.facing = raw[dir]
      tick(env)
    end
  end
  local saved = PersistentDB:GetStructuredData(Store.KEY)
  A.truthy(saved and saved.convention, "convention persisted")
  A.eq(saved.convention.unit, 2048); A.eq(saved.convention.sign, 1); A.eq(saved.convention.offset, 180)
  PluginShutdown()
end

function T.settings_panel_controls()
  local env = boot({ player = { x = 0, z = 0, facing = 0 } })
  env.events["Settings:where-am-i-facing:settings"]({ component = { width = 300, height = 500 } })
  local methods = {}
  for _, call in ipairs(env.settings) do methods[call.method] = call end
  A.truthy(methods.AddColourPicker, "arrow colour picker"); A.truthy(methods.AddCheckboxButton)
  A.eq(methods.AddSimpleButton.args[1], "Recalibrate")
  PluginShutdown()
end

function T.changing_colour_retints_immediately()
  local env = boot({ player = { x = 0, z = 0, facing = 0 } })
  tick(env); env.player.z = 1; tick(env)
  env.events["Settings:where-am-i-facing:settings"]({ component = { width = 300, height = 500 } })
  for _, call in ipairs(env.settings) do
    if call.method == "AddColourPicker" then call.args[1].onChange(nil, 0x4A90E2FF) end
  end
  local arrow = view(env).arrow
  A.truthy(near(arrow.colour.r, 0x4A / 255) and near(arrow.colour.b, 0xE2 / 255), "blue tint applied")
  A.eq(Store.new(PersistentDB):get("arrowColour"), 0x4A90E2FF, "colour saved")
  PluginShutdown()
end

function T.hiding_and_closing_the_compass()
  local env = boot({ player = { x = 0, z = 0, facing = 0 } })
  tick(env)
  local first = view(env).window
  first.options.onClose()
  A.eq(Store.new(PersistentDB):get("showCompass"), false, "closing with X remembers it")
  tick(env)
  A.eq(#env.windows, 1, "stays closed")
  env.events["Settings:where-am-i-facing:settings"]({ component = { width = 300, height = 500 } })
  env.settings[3].args[2].onChange(nil, nil, "showCompass", true)
  A.eq(#env.windows, 2, "reopened from settings")
  env.settings[3].args[2].onChange(nil, nil, "showCompass", false)
  A.eq(env.windows[2].destroyed, true, "hidden from settings")
  PluginShutdown()
end

function T.recalibrate_clears_saved_convention()
  local env = boot({ player = { x = 0, z = 0, facing = 0 }, saved = { convention = { unit = 2048, sign = 1, offset = 0 } } })
  env.events["Settings:where-am-i-facing:settings"]({ component = { width = 300, height = 500 } })
  for _, call in ipairs(env.settings) do
    if call.method == "AddSimpleButton" then call.args[2]() end
  end
  A.eq(Store.new(PersistentDB).convention, nil)
  A.truthy(view(env).hint.content:find("Walk a few steps", 1, true))
  PluginShutdown()
end

function T.player_unavailable_does_not_crash()
  local env = boot({ player = nil })
  tick(env); tick(env)
  A.eq(view(env).label.content, "?")
  PluginShutdown()
end

function T.shutdown_cleans_up()
  local env = boot({ player = { x = 0, z = 0, facing = 0 } })
  tick(env)
  PluginShutdown(); PluginShutdown()
  A.eq(next(env.events), nil); A.eq(view(env).window.destroyed, true)
end

local function liveShape(env)
  for _, s in ipairs(env.shapes) do if not s.destroyed then return s end end
end

function T.ground_arrow_drawn_at_feet_instead_of_window()
  local env = boot({ world = true, player = { x = 10, z = 20, facing = 0 } })
  tick(env)
  A.eq(liveShape(env), nil, "nothing to draw before a direction is known")
  env.player.x = 11 -- step east
  tick(env)
  local shape = liveShape(env)
  A.truthy(shape, "ground arrow drawn"); A.eq(#env.windows, 0, "no window by default")
  A.eq(shape.translation.x, 11 * 512 + 256); A.eq(shape.translation.z, 20 * 512 + 256)
  local data = shape.data
  A.eq(#data.positions, 14, "7 fill + 7 outline vertices"); A.eq(#data.tris, 9); A.eq(#data.lines, 14)
  A.eq(data.rgba[1], Store.DEFAULT_COLOUR, "fill uses the arrow colour")
  local tip = data.positions[5]
  A.truthy(tip.x > 700 and math.abs(tip.z) < 1e-6, "tip points east")
  PluginShutdown()
  A.eq(shape.destroyed, true, "removed on shutdown")
end

function T.ground_arrow_follows_terrain()
  local env = boot({ world = true, slope = 0.5, player = { x = 0, z = 0, facing = 0 } })
  tick(env); env.player.x = 1; tick(env)
  local data = liveShape(env).data
  local tip, tail = data.positions[5], data.positions[1]
  A.truthy(tip.y > tail.y, "tip sits higher on an uphill slope")
  PluginShutdown()
end

function T.ground_arrow_redrawn_only_on_change()
  local env = boot({ world = true, player = { x = 0, z = 0, facing = 0 } })
  tick(env); env.player.z = 1; tick(env)
  local shape = liveShape(env)
  local data = shape.data
  tick(env); tick(env)
  A.eq(shape.data, data, "standing still reuses the shape")
  env.player.x = 1; env.player.z = 1; tick(env)
  A.truthy(shape.data ~= data, "turning NE rebuilds it")
  PluginShutdown()
end

function T.ground_arrow_recolours_and_can_be_hidden()
  local env = boot({ world = true, player = { x = 0, z = 0, facing = 0 } })
  tick(env); env.player.z = 1; tick(env)
  env.events["Settings:where-am-i-facing:settings"]({ component = { width = 300, height = 500 } })
  local checkbox, picker
  for _, call in ipairs(env.settings) do
    if call.method == "AddCheckboxButton" then checkbox = call end
    if call.method == "AddColourPicker" then picker = call end
  end
  picker.args[1].onChange(nil, 0x4A90E2FF)
  A.eq(liveShape(env).data.rgba[1], 0x4A90E2FF)
  checkbox.args[2].onChange(nil, nil, "showGroundArrow", false)
  A.eq(liveShape(env), nil, "hidden")
  checkbox.args[2].onChange(nil, nil, "showCompass", true)
  A.eq(#env.windows, 1, "window available as an option")
  PluginShutdown()
end

function T.window_stands_in_when_world_drawing_is_missing()
  local env = boot({ player = { x = 0, z = 0, facing = 0 } })
  tick(env)
  A.eq(#env.windows, 1, "fallback window")
  PluginShutdown()
end

return T
