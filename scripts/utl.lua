-- Optional: Daten aus dem Mod „UTLogistics“ über seine Schnittstelle „utl“ (Wiki „Für Mod-Autoren“).
-- Kein Muss: Fehlt der Mod oder eine Funktion/ein Ereignis, wird das übersprungen (Aufrufe in pcall).
-- Kein Add-on (keine Rollen, Fahrten, Fenster) – nur lesen, wie das Wiki es empfiehlt:
--   * Listen (Stationen, Lieferungen, freie Züge) einmal holen und alle 10 Minuten neu abgleichen,
--     dazwischen mit Ereignissen aktuell halten – so lässt sich alles je Fläche (Planet) und Team zählen,
--   * Netze nur nach Stations-Ereignissen neu, Statistik (Auslastung) höchstens alle 5 Minuten,
--   * Lieferungen, Waren pro Stunde, Warnungen und Anfragen ohne Zug aus Ereignissen.
-- Was storage ändert, läuft nur in Ereignissen und in Utl.tick (fester Takt, auf allen Rechnern gleich).
-- Utl.read liest nur und hat einen Zwischenspeicher, der allein die Ausgabe betrifft.
local Utl = {}

local MOD = "UTLogistics"
local SELF = "touchdeck-bridge"  -- unser Mod-Name für Stationsdaten und Add-on-Anmeldung
local PIN_SLOTS = 8
local VERSION = 2              -- Aufbau von storage.utl
local MINUTE = 3600
local RESYNC_TICKS = 10 * MINUTE
local STATS_TICKS = 5 * MINUTE
local HOUR_MINUTES = 60
local ALERTS_KEPT = 10
local UNSERVED_TTL = 3 * MINUTE  -- UTL meldet eine wartende Anfrage höchstens einmal pro Minute

function Utl.available()
  return script.active_mods[MOD] ~= nil and remote.interfaces["utl"] ~= nil
end

--- Funktion der Schnittstelle aufrufen; nil, wenn es sie nicht gibt oder sie einen Fehler wirft.
local function call(name, ...)
  local api = remote.interfaces["utl"]
  if not (api and api[name]) then return nil end
  local ok, result = pcall(remote.call, "utl", name, ...)
  if ok then return result end
  return nil
end

-- ---------------------------------------------------------------- Speicher (storage.utl)

local function data()
  local d = storage.utl
  if not d or d.v ~= VERSION then
    -- Aufbau 1 (0.4.0) hatte Minuten ohne Fläche: neu beginnen, Warnungen übernehmen
    d = { v = VERSION, alerts = d and d.alerts or {} }
    storage.utl = d
  end
  d.stations = d.stations or {}   -- [Station] = { s = Fläche, f = Team }
  d.active = d.active or {}       -- [Lieferung] = { s, f }
  d.idle = d.idle or {}           -- [Zug-ID] = { s, f }  frei im Depot
  d.minutes = d.minutes or {}     -- [Minute] = { ["Team|Fläche"] = { count, goods = { [Ware] = Menge } } }
  d.alerts = d.alerts or {}       -- [Team] = { { tick, icon, group, message, surface }, … } neueste zuerst
  d.unserved = d.unserved or {}   -- ["Station|Ware"] = { key, network, since, reason, tick, s, f }
  d.networks = d.networks or {}   -- ["Team|Fläche"] = Anzahl (fehlt = neu holen)
  d.total = d.total or {}         -- [Team] = abgeschlossene Lieferungen, seit mitgezählt wird
  d.pins = d.pins or {}           -- [Station] = Platz 1–8 auf dem TouchDeck (aus den Stationsdaten)
  return d
end

local function where(station)
  return data().stations[station]
end

--- Station (aus einem Ereignis) merken: Fläche und Team von der Haltestelle.
local function remember_station(unit, stop, network)
  if unit == nil then return end
  if stop and stop.valid then
    data().stations[unit] = { s = stop.surface_index, f = stop.force.name, n = network }
  end
end

--- Platz auf dem TouchDeck aus den Stationsdaten (reisen mit Blaupausen und beim Kopieren mit).
local function read_pin(unit)
  local own = call("get_station_data", unit, SELF)
  local slot = type(own) == "table" and tonumber(own.slot) or nil
  data().pins[unit] = slot and slot >= 1 and slot <= PIN_SLOTS and slot or nil
end

--- Einmal alles holen (beim Start und alle 10 Minuten): korrigiert verpasste Ereignisse.
local function resync(tick)
  local d = data()
  d.snap_tick = tick
  local stations = call("get_stations")
  if type(stations) == "table" then
    d.stations = {}
    for _, s in pairs(stations) do
      if s.unit and s.surface then d.stations[s.unit] = { s = s.surface, f = s.force or "player", n = s.network } end
    end
    d.pins = {}
    if remote.interfaces["utl"].get_station_data then
      for unit in pairs(d.stations) do read_pin(unit) end
    end
  end
  local deliveries = call("get_deliveries")
  if type(deliveries) == "table" then
    d.active = {}
    for _, del in pairs(deliveries) do
      local at = d.stations[del.provider] or d.stations[del.requester]
      if del.id and at then d.active[del.id] = { s = at.s, f = at.f, n = del.network or at.n } end
    end
  end
  local idle = call("get_idle_trains")
  if type(idle) == "table" then
    d.idle = {}
    for _, t in pairs(idle) do
      if t.id and t.surface then d.idle[t.id] = { s = t.surface, f = t.force or "player", n = t.network } end
    end
  end
  d.networks = {}
end

-- ---------------------------------------------------------------- Ereignisse

local function on_station(event)
  remember_station(event.station, event.stop, event.network)
  if event.station ~= nil and remote.interfaces["utl"].get_station_data then read_pin(event.station) end
  data().networks = {}
end

local function on_station_removed(event)
  local d = data()
  if event.station ~= nil then
    d.stations[event.station] = nil
    d.pins[event.station] = nil
  end
  d.networks = {}
end

local function on_created(event)
  local d = data()
  local at = where(event.provider) or where(event.requester)
  if event.id and at then d.active[event.id] = { s = at.s, f = at.f, n = event.network or at.n } end
  if event.train_id then d.idle[event.train_id] = nil end
end

local function on_ended(event)
  if event.id then data().active[event.id] = nil end
end

local function on_completed(event)
  local d = data()
  if event.id then d.active[event.id] = nil end
  local at = where(event.requester) or where(event.provider)
  if not at then return end
  local minute = math.floor(event.tick / MINUTE)
  local bucket = d.minutes[minute]
  if not bucket then
    bucket = {}
    d.minutes[minute] = bucket
  end
  local id = at.f .. "|" .. at.s
  local entry = bucket[id] or { count = 0, goods = {}, nets = {} }
  bucket[id] = entry
  entry.count = entry.count + 1
  local net = event.network or at.n
  if net then
    entry.nets = entry.nets or {}
    entry.nets[net] = (entry.nets[net] or 0) + 1
  end
  d.total[at.f] = (d.total[at.f] or 0) + 1
  if type(event.manifest) == "table" then
    for key, amount in pairs(event.manifest) do
      if type(amount) == "number" then entry.goods[key] = (entry.goods[key] or 0) + amount end
    end
  end
end

local function on_idle(event)
  if not event.train_id then return end
  local at = where(event.station)
  local s = at and at.s or (event.stop and event.stop.valid and event.stop.surface_index)
  local f = at and at.f or (event.stop and event.stop.valid and event.stop.force.name)
  if s and f then data().idle[event.train_id] = { s = s, f = f, n = event.network or (at and at.n) } end
end

local function on_departed(event)
  if event.train_id then data().idle[event.train_id] = nil end
end

local function on_rebuilt(event)
  local d = data()
  for _, old in pairs(type(event.old_train_ids) == "table" and event.old_train_ids or {}) do
    d.idle[old] = nil
  end
end

local function on_alert(event)
  local d = data()
  local force = type(event.force) == "string" and event.force or "player"
  local list = d.alerts[force] or {}
  table.insert(list, 1, { tick = event.tick, icon = event.icon, group = event.group, message = event.message,
    surface = event.surface })
  for i = #list, ALERTS_KEPT + 1, -1 do
    list[i] = nil
  end
  d.alerts[force] = list
end

local function on_unserved(event)
  if event.station == nil or event.key == nil then return end
  local at = where(event.station)
  data().unserved[tostring(event.station) .. "|" .. tostring(event.key)] = {
    key = event.key, network = event.network, since = event.since, reason = event.reason, tick = event.tick,
    s = at and at.s, f = at and at.f,
  }
end

--- In on_init und on_load aufrufen. Meldet nur Ereignisse an, die die installierte UTL-Version kennt.
function Utl.listen()
  if not Utl.available() or not remote.interfaces["utl"].get_event_ids then return end
  local ok, ids = pcall(remote.call, "utl", "get_event_ids")
  if not (ok and type(ids) == "table") then return end
  local handlers = {
    on_delivery_created = on_created,
    on_delivery_completed = on_completed,
    on_delivery_canceled = on_ended,
    on_train_idle = on_idle,
    on_train_departed = on_departed,
    on_train_rebuilt = on_rebuilt,
    on_alert = on_alert,
    on_request_unserved = on_unserved,
    on_station_created = on_station,
    on_station_changed = on_station,
    on_station_removed = on_station_removed,
  }
  for name, handler in pairs(handlers) do
    if ids[name] then script.on_event(ids[name], handler) end
  end
end

-- ---------------------------------------------------------------- Takt (ändert storage)

--- Im Heartbeat aufrufen: Abgleich, Netze, Statistik, alte Einträge aufräumen.
function Utl.tick(tick)
  if not Utl.available() then return end
  local d = data()
  if not d.snap_tick or tick - d.snap_tick >= RESYNC_TICKS then
    resync(tick)
  end
  -- Netze je Team und Fläche, nur wenn eine Station sich geändert hat (dann ist die Tabelle leer)
  local seen = {}
  for _, at in pairs(d.stations) do
    local id = at.f .. "|" .. at.s
    if not seen[id] and d.networks[id] == nil then
      seen[id] = true
      local list = call("get_networks", at.s, at.f)
      d.networks[id] = type(list) == "table" and #list or false
    end
  end
  if not d.stats_tick or tick - d.stats_tick >= STATS_TICKS then
    d.stats_tick = tick
    local stats = call("get_statistics")
    d.utilization = nil
    if type(stats) == "table" then
      local sum, n = 0, 0
      for _, t in pairs(type(stats.trains) == "table" and stats.trains or {}) do
        if type(t.utilization) == "number" then sum, n = sum + t.utilization, n + 1 end
      end
      d.utilization = n > 0 and sum / n or nil
    end
  end
  for id, u in pairs(d.unserved) do
    if tick - u.tick > UNSERVED_TTL then d.unserved[id] = nil end
  end
  local now = math.floor(tick / MINUTE)
  for minute in pairs(d.minutes) do
    if minute <= now - HOUR_MINUTES then d.minutes[minute] = nil end
  end
end

-- Lesen: scripts/utl_read.lua (ändert nichts)
local read, clear_cache = require("scripts.utl_read")(Utl, data, call)
Utl.read = read

-- ---------------------------------------------------------------- Add-on: anheften, anmelden

Utl.PIN_SLOTS = PIN_SLOTS
Utl.SELF = SELF
Utl.call = call

--- Station auf einen Platz heften (nil = lösen). Ein Platz gehört genau einer Station des Teams.
---@param unit uint32
---@param slot integer?
function Utl.pin(unit, slot)
  local d = data()
  local at = d.stations[unit]
  if slot and at then
    for other, other_slot in pairs(d.pins) do
      local o = d.stations[other]
      if other ~= unit and other_slot == slot and o and o.f == at.f then
        call("set_station_data", other, SELF, "slot", nil)
        d.pins[other] = nil
      end
    end
  end
  call("set_station_data", unit, SELF, "slot", slot)
  d.pins[unit] = slot
  clear_cache()
end

--- Entity der Station (Haltestelle bzw. Kombinator) für „auf der Karte zeigen“, nil wenn weg.
function Utl.stop_of(unit)
  local entity = game.get_entity_by_unit_number(unit)
  return entity and entity.valid and entity or nil
end

function Utl.pin_of(unit)
  return data().pins[unit]
end

--- Angeheftete Stationen eines Teams: Liste { slot, unit } nach Platz.
function Utl.pinned(force_name)
  local d, list = data(), {}
  for unit, slot in pairs(d.pins) do
    local at = d.stations[unit]
    if at and at.f == force_name then list[#list + 1] = { slot = slot, unit = unit, surface = at.s, network = at.n } end
  end
  table.sort(list, function(a, b) return a.slot < b.slot end)
  return list
end

--- Als UTL-Add-on anmelden (on_init, on_configuration_changed): Abschnitt im Stationsfenster und
--- Reiter im UTL-Manager. Nur mit Add-on-Schnittstelle (api_version, ab UTL 0.0.20).
function Utl.register()
  if not (Utl.available() and remote.interfaces["utl"].api_version) then return end
  call("register_gui_section", { mod = SELF, interface = "touchdeck_bridge", build = "utl_section" })
  call("register_manager_tab", { mod = SELF, interface = "touchdeck_bridge", build = "utl_tab",
    caption = { "touchdeck-bridge.utl-tab" } })
end

--- Warnungstexte des Teams (neueste zuerst) für utl-alerts.txt.
---@param force LuaForce
function Utl.alerts(force)
  if not Utl.available() then return {} end
  return data().alerts[force.name] or {}
end

--- UTL-Manager für einen Spieler öffnen (optional mit Reiter, z. B. "alerts").
---@param player LuaPlayer
function Utl.open_manager(player, tab)
  if not Utl.available() then return false end
  return call("open_manager", player.index, tab) == true
end

return Utl
