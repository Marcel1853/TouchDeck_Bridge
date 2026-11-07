-- Alles, was im Spielstand liegt (storage). Nur fehlende Tabellen anlegen, nie umbauen.
local Store = {}

local MAX_EVENTS = 20

function Store.ensure()
  storage.players = storage.players or {}       -- [player_index] = { seq, events, finished }
  storage.evolution = storage.evolution or {}   -- [surface_index] = zuletzt gemeldete Zehnerstufe
  storage.research = storage.research or {}     -- [force_index] = verfügbare Forschungen (sortiert)
  if not storage.session then
    local nauvis = game.get_surface(1)
    local seed = nauvis and nauvis.map_gen_settings.seed or 0
    storage.session = tostring(seed) .. "-" .. tostring(game.tick)
  end
end

---@param index uint32  Spieler-Index, 0 = Testansicht ohne Spieler
function Store.player(index)
  Store.ensure()
  local p = storage.players[index]
  if not p then
    p = { seq = 0, events = {} }
    storage.players[index] = p
  end
  return p
end

--- Ereignis an einen Spieler anhängen (die letzten MAX_EVENTS bleiben in state.json).
function Store.push(index, event)
  local p = Store.player(index)
  p.seq = p.seq + 1
  event.seq = p.seq
  event.tick = game.tick
  p.events[#p.events + 1] = event
  while #p.events > MAX_EVENTS do
    table.remove(p.events, 1)
  end
  return event
end

return Store
