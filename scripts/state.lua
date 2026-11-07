-- Baut den Inhalt von state.json und names.txt für eine „Ansicht“.
-- Eine Ansicht ist ein Spieler oder (für Tests ohne Spieler) eine Force mit Fläche.
local Store = require("scripts.store")
local Research = require("scripts.research")
local Power = require("scripts.power")
local Util = require("scripts.util")

local State = {}

State.VERSION = 1
State.SUGGESTIONS = 3

---@param player LuaPlayer
function State.view_of(player)
  return {
    index = player.index,
    for_player = player.index,
    player = player,
    name = player.name,
    admin = player.admin,
    force = player.force --[[@as LuaForce]],
    surface = player.physical_surface,
  }
end

--- Ansicht ohne Spieler (Headless-Tests, Server). Schreibt auf jedem Rechner.
function State.test_view()
  return {
    index = 0,
    for_player = nil,
    player = nil,
    name = "",
    admin = true,
    force = game.forces["player"],
    surface = game.get_surface(1),
  }
end

local function surface_info(surface)
  local info = { index = surface.index, name = surface.name, kind = "surface" }
  if surface.platform then
    info.kind = "platform"
    info.platform = surface.platform.name
  elseif surface.planet then
    info.kind = "planet"
    info.planet = surface.planet.name
  end
  return info
end

local function evolution(surface)
  local enemy = game.forces["enemy"]
  if not enemy or surface.platform then return -1 end
  return enemy.get_evolution_factor(surface)
end

function State.build(view)
  local pdata = Store.player(view.index)
  local force = view.force
  local tech = force.current_research
  return {
    v = State.VERSION,
    mod = script.active_mods["touchdeck-bridge"],
    session = storage.session,
    tick = game.tick,
    played = game.ticks_played,
    speed = game.speed,
    paused = game.tick_paused,
    multiplayer = game.is_multiplayer(),
    admin = view.admin,
    player = view.name,
    players = #game.connected_players,
    research = tech and tech.name or "",
    progress = tech and force.research_progress or 0,
    queue = #force.research_queue,
    rockets = force.rockets_launched,
    evolution = evolution(view.surface),
    surface = surface_info(view.surface),
    space_age = script.active_mods["space-age"] ~= nil,
    suggest = Research.suggestions(force, State.SUGGESTIONS),
    power = Power.read(view),
    seq = pdata.seq,
    events = pdata.events,
  }
end


local function place_name(surface)
  if surface.platform then return surface.platform.name end
  if surface.planet then return surface.planet.prototype.localised_name end
  return surface.localised_name or surface.name
end

--- names.txt: Namen in der Sprache des Spielers (Factorio übersetzt beim Schreiben).
--- Liefert einen Schlüssel (ändert er sich, wird neu geschrieben) und den Text.
function State.names(view)
  local force = view.force
  local pdata = Store.player(view.index)
  local current = force.current_research
  local finished = pdata.finished and force.technologies[pdata.finished]
  local parts = {}
  local key = {}
  local function add(label, tech)
    parts[#parts + 1] = label .. "="
    parts[#parts + 1] = tech and tech.localised_name or ""
    parts[#parts + 1] = "\n"
    key[#key + 1] = tech and tech.name or ""
  end
  add("research", current)
  add("finished", finished)
  parts[#parts + 1] = "place="
  parts[#parts + 1] = place_name(view.surface)
  parts[#parts + 1] = "\n"
  key[#key + 1] = tostring(view.surface.index)
  for _, name in ipairs(Research.available(force)) do
    add("tech." .. name, force.technologies[name])
  end
  return table.concat(key, ","), Util.concat(parts)
end

return State
