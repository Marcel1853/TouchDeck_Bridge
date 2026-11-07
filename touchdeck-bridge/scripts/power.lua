-- Strom des Netzes, in dem der Spieler steht: ein Mast in der Nähe, dessen Netzstatistik
-- (dieselben Zahlen wie unten im Strom-Fenster des Spiels). Kein Durchsuchen der Karte:
-- höchstens eine kleine Umkreissuche pro Sekunde, und nur wenn der gemerkte Mast weg ist.
local Store = require("scripts.store")

local Power = {}

local RADIUS = 32
local PRECISION = defines.flow_precision_index.five_seconds

local function far(a, b)
  local dx, dy = a.x - b.x, a.y - b.y
  return dx * dx + dy * dy > RADIUS * RADIUS
end

--- Mast in der Nähe der Ansicht (gemerkt in storage, damit alle Rechner gleich rechnen).
local function pole_for(view, pdata)
  local pole = pdata.pole
  local position = view.player and view.player.position or { x = 0, y = 0 }
  if pole and pole.valid and pole.surface == view.surface and not far(pole.position, position) then
    return pole
  end
  local found = view.surface.find_entities_filtered({
    type = "electric-pole", position = position, radius = RADIUS, force = view.force, limit = 1,
  })
  pdata.pole = found[1]
  return pdata.pole
end

-- Quelle je Erzeuger-Typ (Reihen im gestapelten Graphen). Turbinen getrennt von Dampfmaschinen,
-- weil sie meist an Kernkraft hängen. Rein aus den Prototypen → auf allen Rechnern gleich.
local SOURCE_BY_TYPE = {
  ["generator"] = "steam",
  ["burner-generator"] = "burner",
  ["solar-panel"] = "solar",
  ["accumulator"] = "accumulator",
  ["fusion-generator"] = "fusion",
  ["lightning-attractor"] = "lightning",
  ["electric-energy-interface"] = "interface",
}
local source_cache = {}

local function source_of(name)
  local source = source_cache[name]
  if not source then
    local proto = prototypes.entity[name]
    source = proto and SOURCE_BY_TYPE[proto.type] or "other"
    if source == "steam" and name:find("turbine", 1, true) then source = "turbine" end
    source_cache[name] = source
  end
  return source
end

--- Erzeugung je Quelle in Watt; nur Quellen, die gerade liefern.
local function sources(stats)
  local out = {}
  for name in pairs(stats.output_counts) do
    local watts = stats.get_flow_count({ name = name, category = "output", precision_index = PRECISION }) * 60
    if watts > 0 then
      local key = source_of(name)
      out[key] = (out[key] or 0) + watts
    end
  end
  return out
end

local CONSUMERS = 6

--- Verbrauch je Gebäude (Prototyp-Name) in Watt: die größten CONSUMERS, Rest unter "other".
local function consumers(stats)
  local list = {}
  for name in pairs(stats.input_counts) do
    local watts = stats.get_flow_count({ name = name, category = "input", precision_index = PRECISION }) * 60
    if watts > 0 then list[#list + 1] = { name = name, watts = watts } end
  end
  table.sort(list, function(a, b)
    if a.watts ~= b.watts then return a.watts > b.watts end
    return a.name < b.name
  end)
  local out = {}
  for i, e in ipairs(list) do
    if i <= CONSUMERS then
      out[e.name] = e.watts
    else
      out["other"] = (out["other"] or 0) + e.watts
    end
  end
  return out
end

local function sum(stats, counts, category)
  local total = 0
  for name in pairs(counts) do
    total = total + stats.get_flow_count({ name = name, category = category, precision_index = PRECISION })
  end
  return total * 60 -- Werte sind je Tick (Joule) → Watt
end

--- { production = W, consumption = W } oder nil, wenn kein Netz in der Nähe ist.
function Power.read(view)
  local pdata = Store.player(view.index)
  local pole = pole_for(view, pdata)
  if not (pole and pole.electric_network_id) then return nil end
  local stats = pole.electric_network_statistics
  return {
    network = pole.electric_network_id,
    -- Headless geprüft (2.1.22, Energie-Schnittstelle + Radar): output = Erzeugung, input = Verbrauch
    production = sum(stats, stats.output_counts, "output"),
    consumption = sum(stats, stats.input_counts, "input"),
    sources = sources(stats),
    consumers = consumers(stats),
  }
end

return Power
