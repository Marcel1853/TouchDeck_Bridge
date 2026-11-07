#!/usr/bin/env bash
# Headless-Selbsttest (eigener Datenordner, berührt keine Spielstände).
# Aufruf: tools/run-selftest.sh <arbeitsordner> <mit-space-age: ja|nein> [utl]
#   utl = UTLogistics und flib aus ~/.factorio/mods nur verlinken (nie verändern)
# Vorher prüfen, dass Factorio nicht läuft.
set -euo pipefail
MOD="$(cd "$(dirname "$0")/.." && pwd)"
F=${FACTORIO:-/mnt/6459bc3a-dd91-42e5-8723-71427d99d0ba/SteamLibrary/steamapps/common/Factorio/bin/x64/factorio}
W="$1"; rm -rf "$W"; mkdir -p "$W/mods" "$W/data"
ln -s "$MOD" "$W/mods/touchdeck-bridge"
cp -r "$MOD/tools/selftest/td-selftest" "$W/mods/"
if [ "${3:-}" = utl ]; then
  ln -s "$HOME/.factorio/mods/UTLogistics" "$W/mods/UTLogistics"
  ln -s "$(ls -d "$HOME"/.factorio/mods/flib_*.zip | sort -V | tail -1)" "$W/mods/"
fi
if [ "$2" = nein ]; then
  printf '{"mods":[{"name":"base","enabled":true},{"name":"space-age","enabled":false},{"name":"quality","enabled":false},{"name":"elevated-rails","enabled":false},{"name":"recycler","enabled":false},{"name":"touchdeck-bridge","enabled":true},{"name":"td-selftest","enabled":true}]}' > "$W/mods/mod-list.json"
fi
printf '[path]\nread-data=__PATH__executable__/../../data\nwrite-data=%s/data\n' "$W" > "$W/config.ini"
"$F" -c "$W/config.ini" --mod-directory "$W/mods" --create "$W/t.zip" > /dev/null
"$F" -c "$W/config.ini" --mod-directory "$W/mods" --benchmark "$W/t.zip" --benchmark-ticks 700 > /dev/null || true
LOG="$W/data/factorio-current.log"
grep -o "\[SELFTEST\].*" "$LOG" | grep -v PASS || true
grep -E "Error|Failed to load|doesn't contain key" "$LOG" | head -10 || true
echo "PASS: $(grep -c '\[SELFTEST\] PASS' "$LOG" || true)  FAIL: $(grep -c '\[SELFTEST\] FAIL' "$LOG" || true)"
O="$W/data/script-output/touchdeck-bridge"
python3 -c "import json;d=json.load(open('$O/state.json'));print('power',d.get('power'))"
python3 -c "import json;d=json.load(open('$O/items.json'));print('items',d['items'][:3])"
echo "utl.json: $(cat "$O/utl.json")"
[ -f "$O/utl-alerts.txt" ] && { echo "utl-alerts.txt:"; cat "$O/utl-alerts.txt"; } || true
grep '^surface\.' "$O/labels.txt" 2>/dev/null || true
