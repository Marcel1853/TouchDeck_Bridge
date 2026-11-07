local list = {
  {
    type = "int-setting",
    name = "touchdeck-bridge-interval",
    setting_type = "runtime-global",
    default_value = 60,
    minimum_value = 30,
    maximum_value = 600,
    order = "a",
  },
  {
    type = "bool-setting",
    name = "touchdeck-bridge-enabled",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "b",
  },
}
data:extend(list)
