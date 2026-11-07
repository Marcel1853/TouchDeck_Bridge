-- Tastenkürzel, die TouchDeck auslöst. Alle mit Strg+Alt+Umschalt, damit sie nicht mit
-- Vanilla-Tasten kollidieren. Spieler können sie unter Einstellungen › Steuerung ändern.
-- Nicht R (Strg+Alt+Umschalt+R = Bildschirmaufnahme unter Cinnamon, geprüft), nicht T (Strg+Alt+T
-- = Terminal), keine Pfeiltasten (Arbeitsfläche wechseln), kein Y/Z (Tastaturlayout).
local keys = {
  { "touchdeck-bridge-command", "B" },
  { "touchdeck-bridge-pause", "P" },
  { "touchdeck-bridge-speed-1", "1" },
  { "touchdeck-bridge-speed-2", "2" },
  { "touchdeck-bridge-speed-3", "3" },
  { "touchdeck-bridge-speed-4", "4" },
  { "touchdeck-bridge-slower", "N" },
  { "touchdeck-bridge-faster", "M" },
  { "touchdeck-bridge-save", "S" },
  { "touchdeck-bridge-screenshot", "K" },
  { "touchdeck-bridge-cancel-research", "X" },
  { "touchdeck-bridge-research-1", "Q" },
  { "touchdeck-bridge-research-2", "W" },
  { "touchdeck-bridge-research-3", "E" },
  { "touchdeck-bridge-center", "H" },
  { "touchdeck-bridge-refresh", "U" },
  { "touchdeck-bridge-utl-manager", "G" },
  { "touchdeck-bridge-utl-alerts", "A" },
}

local inputs = {}
for i, k in pairs(keys) do
  inputs[#inputs + 1] = {
    type = "custom-input",
    name = k[1],
    key_sequence = "CONTROL + ALT + SHIFT + " .. k[2],
    consuming = "game-only",
    -- Sonst gehen die Tasten während der Zwischensequenz am Spielanfang verloren.
    enabled_while_in_cutscene = true,
    order = string.format("a%02d", i),
  }
end
data:extend(inputs)
