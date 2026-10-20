local Store = require("src/core/store")
local App = require("src/app")
local Settings = require("src/ui/settings")

local store = Store.new()
local app = App.new(store)
local stopped = false

function PluginShutdown()
  if stopped then return end
  stopped = true
  Settings.stop()
  app:stop()
end

app:start()
Settings.start(store, app)

log("[where-am-i-facing] loaded")
