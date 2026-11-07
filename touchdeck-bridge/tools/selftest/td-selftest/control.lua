---@diagnostic disable: need-check-nil, undefined-field, param-type-mismatch
-- (Testmod: remote.call-Ergebnisse und Testgebäude sind für den Lint untypisiert)
-- Selbsttest für touchdeck-bridge (headless, über die Schnittstelle „touchdeck_bridge“).
-- Mit UTLogistics: baut eine echte UTL-Station und bildet UTL-Ereignisse nach.
local function check(name, cond, extra)
  log("[SELFTEST] " .. (cond and "PASS " or "FAIL ") .. name .. (extra ~= nil and (" " .. tostring(extra)) or ""))
end
local function run(text) return remote.call("touchdeck_bridge", "run", 0, text) end

script.on_nth_tick(30, function(e)
  local s = game.get_surface(1)
  if e.tick == 30 then
    check("interface", remote.interfaces["touchdeck_bridge"] ~= nil)
    local ok, code = run("speed 2"); check("speed 2", ok and game.speed == 2, code)
    ok, code = run("tempo 0,5"); check("tempo 0,5 (Komma)", ok and game.speed == 0.5, code)
    ok, code = run("speed 0"); check("speed 0 abgelehnt", not ok and code == "bad-speed", code)
    run("speed 1")
    ok, code = run("speed up"); check("speed up", ok and game.speed == 2, game.speed)
    ok, code = run("speed langsamer"); check("speed langsamer", ok and game.speed == 1, game.speed)
    ok, code = run("research #1"); check("research #1 am Anfang", not ok and code == "no-suggestion", code)
    local n = 0
    for _, tech in pairs(game.forces.player.technologies) do
      if tech.prototype.research_trigger and tech.enabled then tech.researched = true; n = n + 1 end
    end
    run("refresh")
    log("[SELFTEST] Auslöser-Forschungen freigeschaltet: " .. n)
    ok, code = run("research #1"); check("research #1", ok and code == "research-queued", code)
    check("Forschung läuft", game.forces.player.current_research ~= nil)
    ok, code = run("forschung gibt-es-nicht"); check("unbekannte Forschung", not ok and code == "research-unknown", code)
    ok, code = run("save selftest"); check("save", ok and code == "saved", code)
    ok, code = run("screenshot"); check("screenshot ohne Spieler", not ok and code == "no-player", code)
    ok, code = run("chat Hallo"); check("chat gibt es nicht mehr", not ok and code == "unknown-command", code)
    ok, code = run("quatsch"); check("unbekannter Befehl", not ok and code == "unknown-command", code)
    ok, code = run("abbrechen"); check("cancel", ok, code)
    ok, code = run("pause an"); check("pause an", ok and game.tick_paused == true, code)
    ok, code = run("pause"); check("pause umschalten", ok and game.tick_paused == false, code)
    ok, code = run("utl"); check("utl ohne Spieler bzw. ohne UTL", not ok, code)
    local gen = s.create_entity({ name = "electric-energy-interface", position = { 3, 0 }, force = "player" })
    gen.power_production = 10e6 / 60; gen.power_usage = 0; gen.electric_buffer_size = 1e9
    local use = s.create_entity({ name = "radar", position = { -3, 0 }, force = "player" })
    s.create_entity({ name = "medium-electric-pole", position = { 0, 2 }, force = "player" })
    s.create_entity({ name = "solar-panel", position = { 0, 5 }, force = "player" })
    check("Testnetz gebaut", gen.valid and use.valid)
    -- Echte UTL-Station bauen (nur mit UTLogistics): Gleis + UTL-Haltestelle
    if remote.interfaces["utl"] then
      local function build_stop(surface)
        surface.request_to_generate_chunks({ 21, 21 }, 1)
        surface.force_generate_chunk_requests()
        -- Bauplatz frei machen: zufällige Karte (Wasser, Bäume, Felsen) darf den Test nicht stören
        local tiles = {}
        for x = 10, 32 do
          for y = 10, 32 do tiles[#tiles + 1] = { name = "landfill", position = { x, y } } end
        end
        surface.set_tiles(tiles)
        for _, ent in pairs(surface.find_entities_filtered({ area = { { 10, 10 }, { 33, 33 } } })) do
          if ent.valid and ent.type ~= "character" then ent.destroy() end
        end
        surface.create_entity({ name = "straight-rail", position = { 21, 21 }, direction = defines.direction.north, force = "player" })
        for _, off in ipairs({ { 2, 0 }, { -2, 0 }, { 2, 1 }, { -2, -1 }, { 2, -1 }, { -2, 1 } }) do
          for _, dir in ipairs({ defines.direction.north, defines.direction.south }) do
            local pos = { 21 + off[1], 21 + off[2] }
            if surface.can_place_entity({ name = "utl-train-stop", position = pos, direction = dir, force = "player" }) then
              return surface.create_entity({ name = "utl-train-stop", position = pos, direction = dir, force = "player", raise_built = true })
            end
          end
        end
      end
      storage.stop = build_stop(s)
      storage.stop2 = build_stop(game.create_surface("td-zweite"))
      check("UTL-Haltestellen gebaut", storage.stop ~= nil and storage.stop2 ~= nil)
      check("UTL kennt beide Stationen", remote.call("utl", "station_count") == 2, remote.call("utl", "station_count"))
    end
  elseif e.tick == 90 and remote.interfaces["utl"] and storage.stop then
    -- nach dem ersten Abgleich (Heartbeat Tick 60): UTL-Ereignisse zu dieser Station nachbilden
    local unit = storage.stop.unit_number
    local ids = remote.call("utl", "get_event_ids")
    script.raise_event(ids.on_delivery_created, { id = 7, provider = unit, requester = unit, train_id = 55 })
    script.raise_event(ids.on_train_idle, { train_id = 56, station = unit, stop = storage.stop })
    script.raise_event(ids.on_delivery_completed, { id = 1, provider = unit, requester = unit,
      manifest = { ["item|iron-plate|normal"] = 40 } })
    script.raise_event(ids.on_delivery_completed, { id = 2, provider = unit, requester = unit,
      manifest = { ["item|iron-plate|normal"] = 10, ["fluid|water|normal"] = 500 } })
    script.raise_event(ids.on_alert, { group = "train", icon = "stuck", key = "t1", force = "player", surface = 1,
      message = { "", "Testwarnung: Zug ", "5", " steckt fest" } })
    script.raise_event(ids.on_request_unserved, { station = unit, key = "item|copper-plate|normal", network = "Eisen",
      since = 0, reason = "no-free-train" })
    if storage.stop2 then
      local unit2 = storage.stop2.unit_number
      script.raise_event(ids.on_delivery_created, { id = 8, provider = unit2, requester = unit2, train_id = 57 })
      script.raise_event(ids.on_delivery_created, { id = 9, provider = unit2, requester = unit2, train_id = 58 })
    end
    -- Add-on: Stationen anheften (Stationsdaten bei UTL), ein Platz gehört genau einer Station
    remote.call("touchdeck_bridge", "utl_pin", unit, 3)
    local own = remote.call("utl", "get_station_data", unit, "touchdeck-bridge")
    check("Station angeheftet (Stationsdaten bei UTL)", own and own.slot == 3, own and own.slot)
    if storage.stop2 then
      local unit2 = storage.stop2.unit_number
      remote.call("touchdeck_bridge", "utl_pin", unit2, 3)
      local first = remote.call("utl", "get_station_data", unit, "touchdeck-bridge")
      check("gleicher Platz löst die vorige Station", (first == nil or first.slot == nil), first and first.slot)
      remote.call("touchdeck_bridge", "utl_pin", unit, 1)
    end
    log("[SELFTEST] UTL-Ereignisse ausgelöst")
  elseif e.tick < 600 then
    local stats = game.forces.player.get_item_production_statistics(s)
    stats.on_flow("iron-plate", 20)
    stats.on_flow("iron-plate", -8)
    game.forces.player.get_fluid_production_statistics(s).on_flow("water", 100)
  elseif e.tick == 600 then
    remote.call("touchdeck_bridge", "write", 0)
    log("[SELFTEST] DONE")
  end
end)
