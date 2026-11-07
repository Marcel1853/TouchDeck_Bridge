-- TouchDeck Bridge: verdrahtet nur Ereignisse, die Logik liegt in scripts/.
local Store = require("scripts.store")
local Research = require("scripts.research")
local State = require("scripts.state")
local Output = require("scripts.output")
local Commands = require("scripts.commands")
local Gui = require("scripts.gui")
local Utl = require("scripts.utl")
local UtlGui = require("scripts.utl_gui")

local RESCAN_TICKS = 600 -- Forschungsliste und Evolution alle 10 s prüfen

-- ---------------------------------------------------------------- Takt

local function check_evolution()
  local enemy = game.forces["enemy"]
  if not enemy then return end
  for _, surface in pairs(game.surfaces) do
    if surface.planet and not surface.platform then
      local step = math.floor(enemy.get_evolution_factor(surface) * 10)
      local before = storage.evolution[surface.index]
      storage.evolution[surface.index] = step
      if before and step > before then
        for _, player in pairs(game.connected_players) do
          Store.push(player.index, { type = "evolution_step", percent = step * 10, surface = surface.name })
        end
      end
    end
  end
end

local function heartbeat(event)
  Store.ensure()
  Utl.tick(event.tick)
  if event.tick - (storage.last_rescan or 0) >= RESCAN_TICKS then
    storage.last_rescan = event.tick
    Research.mark_dirty()
    check_evolution()
  end
  Output.write_all()
end

local function register_heartbeat()
  script.on_nth_tick(nil)
  script.on_nth_tick(settings.global["touchdeck-bridge-interval"].value --[[@as uint32]], heartbeat)
end

register_heartbeat()

-- ---------------------------------------------------------------- Lebenszyklus

script.on_init(function()
  Store.ensure()
  Research.mark_dirty()
  Utl.listen()
  Utl.register()   -- UTL-Add-on: Abschnitt im Stationsfenster, Reiter im Manager (Wiki: on_init + on_configuration_changed)
end)

-- UTL-Ereignisse (optional): IDs entstehen bei jedem Laden neu → auch in on_load anmelden (Wiki).
script.on_load(function()
  Utl.listen()
end)

script.on_configuration_changed(function()
  Store.ensure()
  Research.mark_dirty()
  Utl.register()
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting == "touchdeck-bridge-interval" then
    register_heartbeat()
  end
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  Output.forget(event.player_index)
  local player = game.get_player(event.player_index)
  if player then Output.write_player(player) end
end)

script.on_event(defines.events.on_player_removed, function(event)
  Store.ensure()
  storage.players[event.player_index] = nil
end)

-- ---------------------------------------------------------------- Spielereignisse

script.on_event(defines.events.on_research_finished, function(event)
  Research.mark_dirty()
  if event.by_script then return end
  local tech = event.research
  local force = tech.force
  for _, player in pairs(force.connected_players) do
    Store.player(player.index).finished = tech.name
    Store.push(player.index, { type = "research_finished", name = tech.name })
  end
  Output.write_force(force)
end)

script.on_event(defines.events.on_research_started, function(event)
  Research.mark_dirty()
  local force = event.research.force
  for _, player in pairs(force.connected_players) do
    Store.push(player.index, { type = "research_started", name = event.research.name })
  end
  Output.write_force(force)
end)

script.on_event({ defines.events.on_research_queued, defines.events.on_research_cancelled }, function()
  Research.mark_dirty()
end)

script.on_event(defines.events.on_rocket_launched, function(event)
  local source = event.rocket_silo or event.rocket
  if not (source and source.valid) then return end
  local force = source.force --[[@as LuaForce]]
  for _, player in pairs(force.connected_players) do
    Store.push(player.index, { type = "rocket_launched", count = force.rockets_launched })
  end
  Output.write_force(force)
end)

script.on_event(defines.events.on_player_died, function(event)
  local dead = game.get_player(event.player_index)
  if not dead then return end
  local force = dead.force --[[@as LuaForce]]
  for _, player in pairs(force.connected_players) do
    Store.push(player.index, { type = "player_died", player = dead.name, me = player.index == dead.index })
    Output.write_player(player)
  end
end)

-- ---------------------------------------------------------------- Befehle (Tastenkürzel)

local function on_key(command)
  ---@param event EventData.CustomInputEvent
  return function(event)
    local player = game.get_player(event.player_index)
    if player then Commands.run(State.view_of(player), command) end
  end
end

script.on_event("touchdeck-bridge-pause", on_key("pause"))
script.on_event("touchdeck-bridge-speed-1", on_key("speed 0.5"))
script.on_event("touchdeck-bridge-speed-2", on_key("speed 1"))
script.on_event("touchdeck-bridge-speed-3", on_key("speed 2"))
script.on_event("touchdeck-bridge-speed-4", on_key("speed 4"))
script.on_event("touchdeck-bridge-slower", on_key("speed down"))
script.on_event("touchdeck-bridge-faster", on_key("speed up"))
for i = 1, 3 do
  script.on_event("touchdeck-bridge-research-" .. i, on_key("research #" .. i))
end
script.on_event("touchdeck-bridge-save", on_key("save"))
script.on_event("touchdeck-bridge-screenshot", on_key("screenshot"))
script.on_event("touchdeck-bridge-cancel-research", on_key("cancel"))
script.on_event("touchdeck-bridge-center", on_key("center"))
script.on_event("touchdeck-bridge-refresh", on_key("refresh"))
script.on_event("touchdeck-bridge-utl-manager", on_key("utl"))
script.on_event("touchdeck-bridge-utl-alerts", on_key("utl alerts"))

---@param event EventData.CustomInputEvent
script.on_event("touchdeck-bridge-command", function(event)
  local player = game.get_player(event.player_index)
  if player then Gui.open(player) end
end)

script.on_event(defines.events.on_gui_confirmed, function(event)
  local text = Gui.confirmed_text(event.element)
  if not text then return end
  local player = game.get_player(event.player_index)
  if not player then return end
  Gui.close(player)
  Commands.run(State.view_of(player), text)
end)

script.on_event(defines.events.on_gui_checked_state_changed, UtlGui.on_checked)
script.on_event(defines.events.on_gui_selection_state_changed, UtlGui.on_selected)
script.on_event(defines.events.on_gui_click, UtlGui.on_click)

script.on_event(defines.events.on_gui_closed, function(event)
  if Gui.is_frame(event.element) then
    event.element.destroy()
  end
end)

commands.add_command("touchdeck", { "touchdeck-bridge.command-help" }, function(cmd)
  local player = cmd.player_index and game.get_player(cmd.player_index)
  if player then
    Commands.run(State.view_of(player), cmd.parameter or "")
  end
end)

-- ---------------------------------------------------------------- Schnittstelle (Tests, andere Mods)

remote.add_interface("touchdeck_bridge", {
  --- Von UTL aufgerufen (Add-on): Abschnitt „TouchDeck“ im Stationsfenster und Reiter im Manager.
  utl_section = function(flow, unit, player_index)
    UtlGui.section(flow, unit, player_index)
  end,
  utl_tab = function(flow, player_index)
    UtlGui.tab(flow, player_index)
  end,
  --- Station auf einen TouchDeck-Platz heften (nil = lösen), z. B. für Tests und Szenarien.
  utl_pin = function(unit, slot)
    Utl.pin(unit, slot)
  end,
  --- Befehl ausführen; player_index 0 = Testansicht ohne Spieler (schreibt auf jedem Rechner).
  run = function(player_index, text)
    local player = player_index and player_index > 0 and game.get_player(player_index)
    local view = player and State.view_of(player) or State.test_view()
    return Commands.run(view, text)
  end,
  --- Zustand sofort schreiben; ohne Spieler für die Testansicht.
  write = function(player_index)
    local player = player_index and player_index > 0 and game.get_player(player_index)
    Output.write(player and State.view_of(player) or State.test_view())
  end,
})
