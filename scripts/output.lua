-- Schreibt state.json und names.txt nach script-output/touchdeck-bridge/.
-- Mit for_player schreibt Factorio nur auf dem Rechner dieses Spielers (Mehrspieler-sicher).
local State = require("scripts.state")
local Items = require("scripts.items")
local Utl = require("scripts.utl")
local Util = require("scripts.util")

local Output = {}

local DIR = "touchdeck-bridge/"

-- Nur für das Schreiben der Datei (kein Spielzustand): welcher names.txt-Stand schon auf
-- der Platte liegt. Bewusst nicht in storage, damit nach dem Laden neu geschrieben wird.
local names_written = {}
local labels_written = {}
local items_written = {}   -- [Spieler] = Tick des geschriebenen Stands
local utl_written = {}     -- [Spieler] = zuletzt geschriebener Inhalt von utl.json
local alerts_written = {}  -- [Spieler] = Tick der neuesten geschriebenen UTL-Warnung

function Output.forget(index)
  names_written[index] = nil
  labels_written[index] = nil
  items_written[index] = nil
  utl_written[index] = nil
  alerts_written[index] = nil
end

--- Waren-Einträge { k, n } aus den UTL-Daten (gelieferte Waren und Anfragen ohne Zug, alle Flächen).
local function utl_goods(utl)
  local out = {}
  local blocks = { utl.all }
  for _, b in ipairs(utl.surfaces or {}) do blocks[#blocks + 1] = b end
  for _, b in ipairs(blocks) do
    for _, g in ipairs(b.goods or {}) do out[#out + 1] = g end
    for _, u in ipairs(b.unserved or {}) do
      if u.k then out[#out + 1] = u end
    end
  end
  return out
end

--- Anzeigename einer Fläche: Planet in Spielsprache, Raumplattform mit Namen, sonst der Name.
local function surface_label(index)
  local surface = game.get_surface(index)
  if not surface then return nil end
  if surface.platform then return surface.platform.name end
  if surface.planet then return surface.planet.prototype.localised_name end
  return surface.localised_name or surface.name
end

--- utl-alerts.txt: volle UTL-Warnungen des Teams in der Sprache des Spielers, je Zeile „Tick<TAB>Text“.
local function write_alerts(view)
  local alerts = Utl.alerts(view.force)
  local newest = alerts[1] and alerts[1].tick or 0
  if alerts_written[view.index] == newest then return end
  alerts_written[view.index] = newest
  local parts = {}
  for _, a in ipairs(alerts) do
    parts[#parts + 1] = tostring(a.tick) .. "\t"
    parts[#parts + 1] = a.message or ""
    parts[#parts + 1] = "\n"
  end
  helpers.write_file(DIR .. "utl-alerts.txt", #parts > 0 and Util.concat(parts) or "", false, view.for_player)
end


--- labels.txt: Namen von Items, Flüssigkeiten und Stromverbrauchern in der Sprache des Spielers.
local function write_labels(view, items, power, utl)
  local goods = {}
  for _, g in ipairs(utl_goods(utl)) do
    goods[#goods + 1] = g.k .. "." .. g.n
  end
  table.sort(goods)
  local surfaces = {}
  for _, b in ipairs(utl.surfaces or {}) do surfaces[#surfaces + 1] = tostring(b.index) end
  local keys = { items.key, table.concat(goods, ","), "", table.concat(surfaces, ",") }
  local entities = {}
  for name in pairs(power and power.consumers or {}) do
    if name ~= "other" then entities[#entities + 1] = name end
  end
  table.sort(entities)
  keys[3] = table.concat(entities, ",")
  local key = table.concat(keys, "|")
  if labels_written[view.index] == key then return end
  labels_written[view.index] = key
  local parts = {}
  local function add(label, proto)
    if proto then
      parts[#parts + 1] = label .. "="
      parts[#parts + 1] = proto.localised_name
      parts[#parts + 1] = "\n"
    end
  end
  for _, e in ipairs(items.list) do
    add(e.k .. "." .. e.n, e.k == "item" and prototypes.item[e.n] or prototypes.fluid[e.n])
  end
  local seen = {}
  for _, e in ipairs(items.list) do seen[e.k .. "." .. e.n] = true end
  for _, g in ipairs(utl_goods(utl)) do
    if not seen[g.k .. "." .. g.n] then
      seen[g.k .. "." .. g.n] = true
      add(g.k .. "." .. g.n, g.k == "item" and prototypes.item[g.n] or g.k == "fluid" and prototypes.fluid[g.n] or nil)
    end
  end
  for _, name in ipairs(entities) do
    add("entity." .. name, prototypes.entity[name])
  end
  for _, b in ipairs(utl.surfaces or {}) do
    local label = surface_label(b.index)
    if label then
      parts[#parts + 1] = "surface." .. b.index .. "="
      parts[#parts + 1] = label
      parts[#parts + 1] = "\n"
    end
  end
  helpers.write_file(DIR .. "labels.txt", #parts > 0 and Util.concat(parts) or "", false, view.for_player)
end

function Output.write(view)
  local state = State.build(view)
  helpers.write_file(DIR .. "state.json", helpers.table_to_json(state), false, view.for_player)
  local items = Items.read(view.force, view.surface)
  if items_written[view.index] ~= items.tick then
    items_written[view.index] = items.tick
    helpers.write_file(DIR .. "items.json", helpers.table_to_json({
      v = 1, tick = items.tick, surface = view.surface.name, items = items.list,
    }), false, view.for_player)
  end
  local utl = Utl.read(view.force)
  utl.v = 1
  local json = helpers.table_to_json(utl)
  if utl_written[view.index] ~= json then   -- nur bei Änderung schreiben
    utl_written[view.index] = json
    helpers.write_file(DIR .. "utl.json", json, false, view.for_player)
  end
  if utl.active then write_alerts(view) end
  write_labels(view, items, state.power, utl)
  local key, names = State.names(view)
  if names_written[view.index] ~= key then
    names_written[view.index] = key
    helpers.write_file(DIR .. "names.txt", names, false, view.for_player)
  end
end

local function enabled(player)
  local setting = player.mod_settings["touchdeck-bridge-enabled"]
  return not setting or setting.value == true
end

---@param player LuaPlayer
function Output.write_player(player)
  if player.valid and player.connected and enabled(player) then
    Output.write(State.view_of(player))
  end
end

function Output.write_all()
  for _, player in pairs(game.connected_players) do
    Output.write_player(player)
  end
end

---@param force LuaForce
function Output.write_force(force)
  for _, player in pairs(force.connected_players) do
    Output.write_player(player)
  end
end

return Output
