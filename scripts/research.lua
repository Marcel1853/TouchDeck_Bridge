-- Verfügbare Forschungen je Force: erforschbar, nicht versteckt, kein Auslöser-Tech (Space Age),
-- alle Voraussetzungen erforscht. Sortiert nach Kosten. Liegt in storage, damit Befehle wie
-- „research #1“ auf allen Rechnern gleich aufgelöst werden.
local Store = require("scripts.store")

local Research = {}

function Research.mark_dirty()
  Store.ensure()
  storage.research = {}
end

local function compute(force)
  local list = {}
  for name, tech in pairs(force.technologies) do
    local proto = tech.prototype
    if tech.enabled and not tech.researched and not proto.hidden and not proto.research_trigger then
      local ready = true
      for _, pre in pairs(tech.prerequisites) do
        if not pre.researched then
          ready = false
          break
        end
      end
      if ready then
        list[#list + 1] = { name = name, cost = tech.research_unit_count * tech.research_unit_energy }
      end
    end
  end
  table.sort(list, function(a, b)
    if a.cost ~= b.cost then return a.cost < b.cost end
    return a.name < b.name
  end)
  local names = {}
  for i, entry in ipairs(list) do
    names[i] = entry.name
  end
  return names
end

---@param force LuaForce
---@return string[]
function Research.available(force)
  Store.ensure()
  local names = storage.research[force.index]
  if not names then
    names = compute(force)
    storage.research[force.index] = names
  end
  return names
end

--- Die ersten `count` verfügbaren Forschungen, die nicht schon in der Warteschlange stehen.
---@param force LuaForce
function Research.suggestions(force, count)
  local queued = {}
  for _, tech in pairs(force.research_queue) do
    queued[tech.name] = true
  end
  local out = {}
  for _, name in ipairs(Research.available(force)) do
    if not queued[name] then
      out[#out + 1] = name
      if #out >= count then break end
    end
  end
  return out
end

return Research
