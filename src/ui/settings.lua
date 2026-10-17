-- Settings panel: show/hide, arrow colour, direction text, recalibrate.
local Settings = {}

local EVENT_ID = "where-am-i-facing:settings"
local view

local function mount(parent, store, app)
  Settings.destroy()
  view = prettyui.SimpleView.new(parent, { width = parent.width, height = parent.height })
  view:AddTitle("WhereAmIFacing")
  view:AddText("by 6ing")
  view:AddCheckboxButton({
    { text = "Show compass", value = "showCompass", selected = store:get("showCompass") },
    { text = "Show direction text (N, NE, E...)", value = "showLabel", selected = store:get("showLabel") },
  }, {
    onChange = function(_, _, changed, selected) store:set(changed, selected); app:redraw(true) end,
  })
  view:AddTitle("Arrow colour")
  view:AddColourPicker({
    value = store:get("arrowColour"),
    onChange = function(_, colour) store:set("arrowColour", colour); app:redraw(true) end,
  })
  view:AddTitle("Calibration")
  view:AddText({ text = "The arrow learns your client's facing data from a few steps of walking. Recalibrate if it ever points the wrong way.", height = 60 })
  view:AddSimpleButton("Recalibrate", function() app:recalibrate() end)
end

function Settings.start(store, app)
  Event.SettingsLayerReady.Subscribe(EVENT_ID, function(event)
    local ok, err = pcall(mount, event.component, store, app)
    if not ok and log then log("[where-am-i-facing] settings failed: " .. tostring(err)) end
  end)
end

function Settings.destroy()
  if view then pcall(view.Destroy, view) end
  view = nil
end

function Settings.stop()
  pcall(Event.SettingsLayerReady.Unsubscribe, EVENT_ID)
  Settings.destroy()
end

return Settings
