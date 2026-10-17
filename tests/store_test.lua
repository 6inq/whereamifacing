local A = require("assert")
local Store = require("src/core/store")

local T = {}

local function memoryDb()
  local db = { data = {} }
  function db:GetStructuredData(key) return self.data[key] end
  function db:SetStructuredData(key, value) self.data[key] = value end
  return db
end

function T.defaults()
  local s = Store.new(memoryDb())
  A.eq(s:get("showCompass"), true); A.eq(s:get("showLabel"), true); A.eq(s:get("arrowColour"), Store.DEFAULT_COLOUR)
  A.eq(s.convention, nil)
end

function T.switches_turned_off_stay_off_after_restart()
  local db = memoryDb()
  local s = Store.new(db)
  s:set("showCompass", false); s:set("showLabel", false)
  local reloaded = Store.new(db)
  A.eq(reloaded:get("showCompass"), false); A.eq(reloaded:get("showLabel"), false)
end

function T.any_colour_accepted_and_saved()
  local db = memoryDb()
  local s = Store.new(db)
  for _, colour in ipairs({ 0x000000FF, 0xFF00FF80, 0xFFFFFFFF, 0x12345678 }) do
    A.eq(s:set("arrowColour", colour), true)
    A.eq(Store.new(db):get("arrowColour"), colour)
  end
  A.eq(s:set("arrowColour", -1), false); A.eq(s:set("arrowColour", 0x1FFFFFFFF), false); A.eq(s:set("arrowColour", "red"), false)
end

function T.convention_saved_and_validated()
  local db = memoryDb()
  local s = Store.new(db)
  s:setConvention({ unit = 2048, sign = 1, offset = 180 })
  A.eq(Store.new(db).convention.unit, 2048)
  s:setConvention(nil)
  A.eq(Store.new(db).convention, nil)
  db.data[Store.KEY] = { convention = { unit = 7, sign = 1, offset = 0 }, showCompass = "yes", arrowColour = 12.0 }
  local loaded = Store.new(db)
  A.eq(loaded.convention, nil); A.eq(loaded:get("showCompass"), true); A.eq(loaded:get("arrowColour"), 12)
end

function T.throwing_db_tolerated()
  local db = {}
  function db:GetStructuredData() error("boom") end
  function db:SetStructuredData() error("boom") end
  local s = Store.new(db)
  A.eq(s:set("showLabel", false), true); A.eq(s:get("showLabel"), false)
end

return T
