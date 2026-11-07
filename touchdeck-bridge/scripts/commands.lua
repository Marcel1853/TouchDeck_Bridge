-- Befehle von TouchDeck (über Tastenkürzel, das Befehlsfeld oder /touchdeck).
-- Jeder Befehl hängt eine Bestätigung („ack“) an die Ereignisse und schreibt state.json sofort,
-- auch bei angehaltenem Spiel (dann laufen keine Takt-Handler).
local Store = require("scripts.store")
local Research = require("scripts.research")
local State = require("scripts.state")
local Output = require("scripts.output")
local Utl = require("scripts.utl")

local Commands = {}

local ALIASES = {
  pause = "pause", pausieren = "pause",
  speed = "speed", tempo = "speed", geschwindigkeit = "speed",
  save = "save", speichern = "save",
  screenshot = "screenshot", foto = "screenshot",
  research = "research", forschung = "research", forschen = "research",
  cancel = "cancel", abbrechen = "cancel",
  center = "center", zentrieren = "center",
  refresh = "refresh", aktualisieren = "refresh",
  utl = "utl", manager = "utl",
}

local ADMIN_ONLY = { pause = true, speed = true, save = true }

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local handlers = {}

function handlers.pause(view, arg)
  local want
  local a = arg:lower()
  if a == "" or a == "toggle" or a == "umschalten" then
    want = not game.tick_paused
  elseif a == "on" or a == "an" or a == "ein" then
    want = true
  elseif a == "off" or a == "aus" then
    want = false
  else
    return false, "bad-value", { value = arg }
  end
  game.tick_paused = want
  return true, want and "paused" or "resumed", {}
end

local SPEED_STEPS = { up = 2, faster = 2, schneller = 2, down = 0.5, slower = 0.5, langsamer = 0.5 }

function handlers.speed(view, arg)
  local step = SPEED_STEPS[arg:lower()]
  if step then
    local n = math.max(0.125, math.min(64, game.speed * step))
    game.speed = n
    return true, "speed", { value = n }
  end
  local n = tonumber((arg:gsub(",", ".")))
  if not n or n < 0.01 or n > 100 then
    return false, "bad-speed", { value = arg }
  end
  game.speed = n
  return true, "speed", { value = n }
end

function handlers.save(view, arg)
  local name = arg:gsub("[^%w_-]", "")
  if name == "" then name = "touchdeck" end
  name = name:sub(1, 40)
  game.auto_save(name)
  return true, "saved", { name = "_autosave-" .. name }
end

function handlers.screenshot(view, arg)
  if not view.player then
    return false, "no-player", {}
  end
  local path = "touchdeck-bridge/screenshots/" .. tostring(game.ticks_played) .. ".png"
  game.take_screenshot({ player = view.player, by_player = view.player, path = path, show_entity_info = true })
  return true, "screenshot", { path = path }
end

local function find_tech(force, arg)
  if arg:sub(1, 1) == "#" then
    local n = tonumber(arg:sub(2))
    local list = Research.suggestions(force, State.SUGGESTIONS)
    return n and list[n] and force.technologies[list[n]]
  end
  local tech = force.technologies[arg]
  if tech then return tech end
  local wanted = arg:lower():gsub("%s+", "-")
  return force.technologies[wanted]
end

function handlers.research(view, arg)
  local force = view.force
  if arg == "" then
    return false, "bad-value", { value = arg }
  end
  local tech = find_tech(force, arg)
  if not tech and arg:sub(1, 1) == "#" then
    return false, "no-suggestion", { value = arg }
  elseif not tech then
    return false, "research-unknown", { value = arg }
  end
  if tech.researched then
    return false, "research-done", { name = tech.name }
  end
  if not force.add_research(tech) then
    return false, "research-failed", { name = tech.name }
  end
  Research.mark_dirty()
  return true, "research-queued", { name = tech.name }
end

function handlers.cancel(view, arg)
  local tech = view.force.current_research
  if not tech then
    return false, "no-research", {}
  end
  view.force.cancel_current_research()
  Research.mark_dirty()
  return true, "research-cancelled", { name = tech.name }
end

function handlers.center(view, arg)
  if not view.player then
    return false, "no-player", {}
  end
  view.player.exit_remote_view()
  return true, "centered", {}
end

local UTL_TABS = { depots = true, stations = true, networks = true, inventory = true, history = true, alerts = true }

--- UTL-Manager öffnen (nur mit dem Mod UTLogistics), optional mit Reiter.
function handlers.utl(view, arg)
  if not Utl.available() then
    return false, "utl-missing", {}
  end
  if not view.player then
    return false, "no-player", {}
  end
  local tab = arg:lower()
  if tab ~= "" and not UTL_TABS[tab] then
    return false, "bad-value", { value = arg }
  end
  if not Utl.open_manager(view.player, tab ~= "" and tab or nil) then
    return false, "utl-failed", {}
  end
  return true, "utl-opened", {}
end

function handlers.refresh(view, arg)
  Research.mark_dirty()
  Output.forget(view.index)
  return true, "refreshed", {}
end

-- Text für die fliegende Meldung im Spiel (eigene Übersetzung je Ergebnis).
local function flying_text(view, ok, code, args)
  if not view.player then return end
  local param = args.value or args.path or args.text or ""
  if args.name and view.force.technologies[args.name] then
    param = view.force.technologies[args.name].localised_name
  elseif args.name then
    param = args.name
  end
  view.player.create_local_flying_text({
    text = { "touchdeck-bridge-msg." .. code, param },
    create_at_cursor = true,
    color = ok and { 0.6, 1, 0.6 } or { 1, 0.5, 0.4 },
  })
end

--- Führt einen Befehl als Text aus („speed 2“, „research #1“, „pause“ …).
---@return boolean ok, string code
function Commands.run(view, text)
  text = trim(text or "")
  local word, rest = text:match("^(%S+)%s*(.*)$")
  local cmd = word and ALIASES[word:lower()]
  local ok, code, args
  if not cmd then
    ok, code, args = false, "unknown-command", { value = word or "" }
  elseif ADMIN_ONLY[cmd] and game.is_multiplayer() and not view.admin then
    ok, code, args = false, "not-admin", {}
  else
    ok, code, args = handlers[cmd](view, trim(rest))
  end
  local event = { type = "ack", cmd = cmd or (word or ""), ok = ok, code = code }
  for k, v in pairs(args) do
    event[k] = v
  end
  Store.push(view.index, event)
  flying_text(view, ok, code, args)
  if cmd == "pause" or cmd == "speed" then
    -- betrifft alle: Zustand bei allen Spielern sofort aktualisieren
    Output.write_all()
    if not view.player then Output.write(view) end
  else
    Output.write(view)
  end
  return ok, code
end

return Commands
