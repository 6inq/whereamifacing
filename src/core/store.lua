-- Persistent settings and the learned facing convention. The db is injectable for tests.
local Calibration = require("src/core/calibration")

local Store = {}
Store.__index = Store

Store.KEY = "where-am-i-facing-settings"
Store.DEFAULT_COLOUR = 0xFFD24AFF -- gold

local function isBool(v) return type(v) == "boolean" end
local function isColour(v) return type(v) == "number" and v == math.floor(v) and v >= 0 and v <= 0xFFFFFFFF end

local SETTINGS = {
  showGroundArrow = { default = true, valid = isBool },
  showCompass = { default = false, valid = isBool },
  showLabel = { default = true, valid = isBool },
  arrowColour = { default = Store.DEFAULT_COLOUR, valid = isColour },
}

function Store.new(db)
  local self = setmetatable({ settings = {} }, Store)
  self.db = db or rawget(_G, "PersistentDB")
  local raw
  if self.db then
    local ok, value = pcall(function() return self.db:GetStructuredData(Store.KEY) end)
    raw = ok and value or nil
  end
  raw = type(raw) == "table" and raw or {}
  for name, spec in pairs(SETTINGS) do
    -- Not `valid and value or default`: that idiom turns a saved `false` back into the default.
    if spec.valid(raw[name]) then self.settings[name] = raw[name] else self.settings[name] = spec.default end
  end
  self.settings.arrowColour = math.floor(self.settings.arrowColour)
  self.convention = Calibration.isConvention(raw.convention) and raw.convention or nil
  return self
end

function Store:_save()
  if self.db == nil then return end
  local data = {}
  for name, value in pairs(self.settings) do data[name] = value end
  data.convention = self.convention
  local ok, err = pcall(function() return self.db:SetStructuredData(Store.KEY, data) end)
  if not ok and log then log("[where-am-i-facing] save failed: " .. tostring(err)) end
end

function Store:get(name)
  return self.settings[name]
end

function Store:set(name, value)
  local spec = SETTINGS[name]
  if not spec or not spec.valid(value) then return false end
  self.settings[name] = value
  self:_save()
  return true
end

function Store:setConvention(convention)
  self.convention = Calibration.isConvention(convention) and convention or nil
  self:_save()
end

return Store
