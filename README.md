# TouchDeck Bridge

Shows your Factorio game on **[TouchDeck](https://github.com/Marcel1853/touchdeck)** – a free macro
remote for your PC that turns a phone or tablet into a control panel. Research, speed, power,
production, evolution and (with UTLogistics) your trains appear live on the buttons, and buttons
pause, speed up, save or queue research.

**English** · [Deutsch](README.de.md)

- Needs Factorio 2.1. Space Age is optional.
- **Works together with [UTLogistics](https://mods.factorio.com/mod/UTLogistics)** if it is installed:
  then your trains, stations, networks and alerts appear on the TouchDeck too (see below). Without it
  everything else works the same.
- Languages: English and German. French, Spanish, Polish, Brazilian Portuguese, Russian and Chinese
  (simplified) are AI translations – corrections are welcome.
- **Linux: tested. Windows: not tested yet** – feedback is welcome.

## What you need

1. **TouchDeck** on your PC – download: [github.com/Marcel1853/touchdeck/releases](https://github.com/Marcel1853/touchdeck/releases)
   (free, with an Android app for the phone or tablet).
2. **The TouchDeck plugin “Factorio”** – in TouchDeck: *Plugins › Marketplace › Factorio › Install*.
   It is an advanced plugin, so TouchDeck asks you to switch on advanced mode first.
   It also brings ready-made pages (Factorio, Time, Research, Game, Production, Power, UTLogistics).
3. **This mod** in Factorio. Nothing to set up: no launch options, no network, no RCON.

## How it works

- The mod writes small files to `script-output/touchdeck-bridge/` in your Factorio user folder
  (Linux: `~/.factorio/script-output/`). The TouchDeck plugin watches them.
- Commands come in through the mod's own key bindings (`Ctrl+Alt+Shift+…`). TouchDeck presses them
  in the Factorio window and shows the game's answer on the button. You can change the keys in
  Settings › Controls (then change them in TouchDeck as well).

| Ctrl+Alt+Shift+… | Command |
| --- | --- |
| P | Toggle pause |
| 1 / 2 / 3 / 4 | Speed 0.5× / 1× / 2× / 4× |
| N / M | Slower (½) / faster (×2) |
| S | Save (`_autosave-touchdeck`) |
| K | Screenshot to `script-output/touchdeck-bridge/screenshots/` |
| Q / W / E | Queue research suggestion 1 / 2 / 3 (cheapest available research) |
| X | Cancel the current research |
| H | Leave remote view, back to the player |
| U | Write all data again |
| G / A | UTL manager / UTL manager alerts (only with UTLogistics) |
| B | Command field (for typing yourself) |

Commands for the command field and `/touchdeck <command>` in the chat: `pause [on|off]`,
`speed <number|up|down>`, `save [name]`, `screenshot`, `research <name or #1..#3>`, `cancel`,
`center`, `refresh`, `utl [tab]`.

## UTLogistics (optional)

With UTLogistics active, the mod reads its data through UTL's interface (read only, as the UTL wiki
recommends) – per planet: trains idle and on the way, deliveries, stations, networks, alerts in full
text and requests without a train. In the UTL **station window** there is a section **“TouchDeck”**:
tick “Show on the TouchDeck” and pick a slot 1–8 to see that station on the TouchDeck page
“UTLogistics › Stations”. The UTL **manager** gets a tab **“TouchDeck”** with all pinned stations.

## Good to know

- **Single player: the game stops while it is paused – also in the Esc menu and while the research
  screen (technology tree) is open.** Then no mod code runs and nothing new is written. TouchDeck keeps
  the last values and shows “halted”. I do not know a way around this yet – ideas are welcome.
  In multiplayer the game keeps running in those screens.
- Multiplayer: every player gets the files only on their own computer. Pause, speed and save need
  admin rights. The per-player setting “Write files for TouchDeck” turns it off.
- At the start of a game all research is “trigger research” (craft, mine, build …), which cannot be
  queued – so there are no suggestions yet.

## Examples, license and ideas

The features are **examples** of what a game and TouchDeck can do together. The mod is under the
**MIT license**: build your own mod or TouchDeck plugin from it, change it, use parts of it – however
you like. It works for me the way it is now, and I like using it; whether it is useful for you, you
decide. **Suggestions are welcome** – what to change, what is missing, how it could work better.
