local cutils = require("common-utils")

-- A multi-output ACP profile stays available when only one HDMI port is connected.
-- Override profile selection so disconnected ports do not create phantom sinks.
SimpleEventHook {
  name = "device/select-nvidia-outputs",
  after = "device/find-best-profile",
  before = "device/apply-profile",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "select-profile" },
      Constraint { "device.name", "=", "alsa_card.pci-0000_01_00.1" },
    },
  },
  execute = function(event)
    local device = event:get_subject()
    local connected = {}
    for p in device:iterate_params("EnumRoute") do
      local route = cutils.parseParam(p, "EnumRoute")
      connected[route.name] = route.available == "yes"
    end

    local monitor = connected["hdmi-output-0"]
    local tv = connected["hdmi-output-1"]
    local name = monitor and (tv and "dual-stereo" or "monitor-stereo")
      or (tv and "tv-stereo" or "off")
    for p in device:iterate_params("EnumProfile") do
      local profile = cutils.parseParam(p, "EnumProfile")
      if profile.name == name then
        event:set_data("selected-profile", profile)
        return
      end
    end
  end,
}:register()

-- Hotplug can change EnumRoute without changing the dual profile's availability.
SimpleEventHook {
  name = "device/reselect-nvidia-outputs",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "device-params-changed" },
      Constraint { "event.subject.param-id", "=", "EnumRoute" },
      Constraint { "device.name", "=", "alsa_card.pci-0000_01_00.1" },
    },
  },
  execute = function(event)
    event:get_source():call("push-event", "select-profile", event:get_subject(), nil)
  end,
}:register()
