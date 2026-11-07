-- Produktion und Verbrauch von Items und Flüssigkeiten pro Minute auf der Fläche des Spielers
-- (dieselben Zahlen wie im Produktionsfenster, Zeitraum 1 Minute). Alle 5 Sekunden neu gerechnet;
-- nur Einträge, die gerade laufen. Der Zwischenspeicher betrifft nur die Ausgabe (kein Spielzustand).
local Items = {}

local INTERVAL = 300   -- Ticks
local MAX = 300
local PRECISION = defines.flow_precision_index.one_minute

local cache = {}       -- ["force:surface"] = { tick, list, key }

local function round(n)
  return math.floor(n * 10 + 0.5) / 10
end

local function collect(stats, kind, out)
  local names = {}
  for name in pairs(stats.input_counts) do names[name] = true end
  for name in pairs(stats.output_counts) do names[name] = true end
  for name in pairs(names) do
    local made = stats.get_flow_count({ name = name, category = "input", precision_index = PRECISION })
    local used = stats.get_flow_count({ name = name, category = "output", precision_index = PRECISION })
    if made >= 0.05 or used >= 0.05 then
      out[#out + 1] = { n = name, k = kind, p = round(made), c = round(used) }
    end
  end
end

--- { tick, list, key }: list = { n = Name, k = "item"|"fluid", p = Produktion/min, c = Verbrauch/min }.
---@param force LuaForce
---@param surface LuaSurface
function Items.read(force, surface)
  local id = force.index .. ":" .. surface.index
  local entry = cache[id]
  if entry and game.tick - entry.tick < INTERVAL then
    return entry
  end
  local list = {}
  collect(force.get_item_production_statistics(surface), "item", list)
  collect(force.get_fluid_production_statistics(surface), "fluid", list)
  table.sort(list, function(a, b)
    if a.p ~= b.p then return a.p > b.p end
    return a.n < b.n
  end)
  while #list > MAX do
    table.remove(list)
  end
  local names = {}
  for i, e in ipairs(list) do
    names[i] = e.k .. "." .. e.n
  end
  table.sort(names)
  entry = { tick = game.tick, list = list, key = table.concat(names, ",") }
  cache[id] = entry
  return entry
end

return Items
