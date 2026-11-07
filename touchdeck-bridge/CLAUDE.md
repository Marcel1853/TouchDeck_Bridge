# TouchDeck Bridge (touchdeck-bridge) – Projektregeln

Factorio-2.1-Mod (mit und ohne Space Age). Gegenstück: TouchDeck-Plugin `factorio` in
`/home/marcel/projects/test/touchdeck-plugins/plugins/factorio` (Plugin-Repo, Marktplatz; `docs/touchdeck-factorio` ist alter Stand).

## Quellen

- API-Doku zur installierten Version liegt lokal: `<Factorio>/doc-html/runtime-api.json`
  (Spielordner in `.vscode/settings.json`). Jede API dort prüfen, nichts aus dem Gedächtnis.
- Skill: `~/.factorio/mods/UTLogistics/docs/factorio-modding-skill` (zuerst `references/15-pitfalls.md`).

## Aufbau

- Weg nach außen: nur `helpers.write_file` nach `script-output/touchdeck-bridge/` (state.json,
  names.txt). Kein UDP, keine Startoption – ausdrücklicher Wunsch.
- Weg nach innen: `custom-input` (Strg+Alt+Umschalt+…), Befehlsfeld, `/touchdeck`.
- Dateiformat ist die Schnittstelle zum Plugin: Felder nur ergänzen, nie umbenennen; bei
  Bruch `State.VERSION` erhöhen und das Plugin anpassen.
- Strom (`scripts/power.lua`): Netzstatistik eines Masts im Umkreis von 32 Feldern um den
  Spieler; `output_counts` = Erzeugung, `input_counts` = Verbrauch (headless geprüft).
- Tasten: Strg+Alt+Umschalt+R startet unter Cinnamon die Bildschirmaufnahme (geprüft), Pfeile
  wechseln die Arbeitsfläche – nicht belegen.
- UTL-Add-on (nur Fenster): `Utl.register()` in on_init + on_configuration_changed meldet Abschnitt im
  Stationsfenster und Reiter im Manager an (`scripts/utl_gui.lua`); Anheften als Stationsdaten
  (`set_station_data(unit, "touchdeck-bridge", "slot", n)`), reist mit Blaupausen.
- UTLogistics ist optional (`? UTLogistics`): Vor jedem Zugriff `Utl.available()` und je Funktion
  `remote.interfaces.utl[name]`, jeder Aufruf in `pcall`. Kein Add-on – nur lesen, wie im UTL-Wiki
  „Für Mod-Autoren“ (`UTLogistics/docs/wiki/repo/de/API-*.md`) beschrieben: Zähler im Takt, Listen
  nie im Takt, Rest aus Ereignissen (`get_event_ids` in `on_init` und `on_load`, nur vorhandene IDs).
  Listen einmal holen + alle 10 min abgleichen, dazwischen Ereignisse → Zählung je Fläche und Team.
  storage nur in Ereignissen und `Utl.tick` (Heartbeat) ändern; `Utl.read` liest nur.
- Kein Text in Factorio-Textfelder tippen lassen: Mit IBus kommen erzeugte Tasten dort nicht an
  (im Spiel geprüft). Alles, was TouchDeck auslöst, bekommt ein eigenes Tastenkürzel.
- `control.lua` verdrahtet nur, Logik in `scripts/`. Kein `on_tick`, ein `on_nth_tick`.
- Alles, was `storage` ändert, muss auf allen Rechnern gleich laufen. Nur der Merker
  `names_written` in `output.lua` ist lokal (betrifft nur das Schreiben der Datei).

## Tests

- Selbsttest liegt im Mod: `tools/run-selftest.sh <ordner> ja|nein [utl]` (Testmod in
  `tools/selftest/`, mit UTL: echte UTL-Stationen auf zwei Flächen, nachgebildete UTL-Ereignisse).
  Vorher prüfen, dass Factorio nicht läuft.

- `scripts/lint.sh .` aus dem Skill.
- Headless-Selbsttest mit Testmod über die Schnittstelle `touchdeck_bridge.run(0, text)`.
  Mit Spieler (Tastenkürzel, Befehlsfeld, names.txt je Spieler) geht nur im echten Spiel.
- `changelog.txt` englisch, strenges Format, Eintrag sofort nach jeder Änderung.
