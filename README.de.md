# TouchDeck Bridge

Zeigt dein Factorio-Spiel auf **[TouchDeck](https://github.com/Marcel1853/touchdeck)** – einer
kostenlosen Makro-Fernbedienung für den PC, die ein Handy oder Tablet zum Bedienfeld macht. Forschung,
Geschwindigkeit, Strom, Produktion, Evolution und (mit UTLogistics) deine Züge erscheinen live auf den
Buttons, und Buttons pausieren, beschleunigen, speichern oder reihen Forschung ein.

[English](https://github.com/Marcel1853/TouchDeck_Bridge/blob/main/README.md) · **Deutsch**

- Braucht Factorio 2.1. Space Age ist optional.
- **Arbeitet mit [UTLogistics](https://mods.factorio.com/mod/UTLogistics) zusammen**, wenn es installiert
  ist: Dann erscheinen auch deine Züge, Stationen, Netze und Warnungen auf dem TouchDeck (siehe unten).
  Ohne UTLogistics funktioniert alles andere genauso.
- Sprachen: Englisch und Deutsch. Französisch, Spanisch, Polnisch, brasilianisches Portugiesisch,
  Russisch und Chinesisch (vereinfacht) sind KI-Übersetzungen – Korrekturen sind willkommen.
- **Linux: getestet. Windows: noch nicht getestet** – Rückmeldungen sind willkommen.

## Was du brauchst

1. **TouchDeck** auf dem PC – Download: [github.com/Marcel1853/touchdeck/releases](https://github.com/Marcel1853/touchdeck/releases)
   (kostenlos, mit Android-App fürs Handy oder Tablet).
2. **Das TouchDeck-Plugin „Factorio“** – in TouchDeck: *Plugins › Marktplatz › Factorio › Installieren*.
   Es ist ein erweitertes Plugin, deshalb fragt TouchDeck vorher nach dem erweiterten Modus.
   Es bringt fertige Seiten mit (Factorio, Zeit, Forschung, Spiel, Produktion, Strom, UTLogistics).
3. **Diesen Mod** in Factorio. Einstellen musst du nichts: keine Startoptionen, kein Netzwerk, kein RCON.

## So funktioniert es

- Der Mod schreibt kleine Dateien nach `script-output/touchdeck-bridge/` in deinem
  Factorio-Benutzerordner (Linux: `~/.factorio/script-output/`). Das TouchDeck-Plugin achtet darauf.
- Befehle kommen über eigene Tastenkürzel des Mods (`Strg+Alt+Umschalt+…`). TouchDeck drückt sie im
  Factorio-Fenster und zeigt die Antwort des Spiels am Button. Die Tasten lassen sich unter
  Einstellungen › Steuerung ändern (dann auch in TouchDeck anpassen).

| Strg+Alt+Umschalt+… | Befehl |
| --- | --- |
| P | Pause umschalten |
| 1 / 2 / 3 / 4 | Geschwindigkeit 0,5× / 1× / 2× / 4× |
| N / M | langsamer (½) / schneller (×2) |
| S | Speichern (`_autosave-touchdeck`) |
| K | Screenshot nach `script-output/touchdeck-bridge/screenshots/` |
| Q / W / E | Forschungsvorschlag 1 / 2 / 3 einreihen (günstigste verfügbare Forschung) |
| X | Laufende Forschung abbrechen |
| H | Fernansicht verlassen, zurück zum Spieler |
| U | Alle Daten neu schreiben |
| G / A | UTL-Manager / UTL-Manager Warnungen (nur mit UTLogistics) |
| B | Befehlsfeld (zum Selbertippen) |

Befehle für das Befehlsfeld und `/touchdeck <Befehl>` im Chat: `pause [an|aus]`,
`speed <Zahl|up|down>`, `save [Name]`, `screenshot`, `research <Name oder #1..#3>`, `cancel`,
`center`, `refresh`, `utl [Reiter]`.

## UTLogistics (optional)

Ist UTLogistics aktiv, liest der Mod dessen Daten über die UTL-Schnittstelle (nur lesend, wie im
UTL-Wiki empfohlen) – je Planet: freie und fahrende Züge, Lieferungen, Stationen, Netze, Warnungen im
Volltext und Anfragen ohne Zug. Im UTL-**Stationsfenster** gibt es den Abschnitt **„TouchDeck“**:
„Auf dem TouchDeck zeigen“ anhaken und einen Platz 1–8 wählen, dann erscheint die Station auf der
TouchDeck-Seite „UTLogistics › Stationen“. Der UTL-**Manager** bekommt den Reiter **„TouchDeck“** mit
allen angehefteten Stationen.

## Gut zu wissen

- **Einzelspieler: Ist das Spiel pausiert, steht alles – auch im Esc-Menü und solange die Forschung
  (Technologiebaum) offen ist.** Dann läuft kein Mod-Code, und es wird nichts Neues geschrieben.
  TouchDeck behält die letzten Werte und zeigt „angehalten“. Wie man das umgehen könnte, weiß ich noch
  nicht – Ideen sind willkommen. Im Mehrspieler läuft das Spiel in diesen Fenstern weiter.
- Mehrspieler: Jeder Spieler bekommt die Dateien nur auf seinem eigenen Rechner. Pause, Tempo und
  Speichern brauchen Admin-Rechte. Die Spieler-Einstellung „Für TouchDeck schreiben“ schaltet es ab.
- Am Spielanfang gibt es nur „Auslöser-Forschungen“ (herstellen, abbauen, bauen …), die sich nicht
  einreihen lassen – deshalb gibt es dann noch keine Vorschläge.

## Beispiele, Lizenz und Ideen

Die Funktionen sind **Beispiele** dafür, was ein Spiel und TouchDeck zusammen können. Der Mod steht
unter der **MIT-Lizenz**: Du kannst daraus einen eigenen Mod oder ein eigenes TouchDeck-Plugin bauen,
ihn ändern oder Teile übernehmen – ganz wie du möchtest. Für mich funktioniert er so, wie er jetzt
ist, und ich nutze ihn gern; ob er für dich sinnvoll ist, entscheidest du. **Vorschläge sind
willkommen** – was man ändern könnte, was fehlt, wie es besser funktionieren könnte.
