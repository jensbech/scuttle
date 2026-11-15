#!/bin/zsh
set -euo pipefail

usage() {
  cat <<'TXT'
Usage: scripts/demo.sh [timeline] [--rebuild]

Builds build/Scuttle.app if it is missing (or with --rebuild), launches it with
the HUD on and plays a timeline hands-free. timeline is peek (default),
slow-open, tease, or a path to a timeline JSON file. The app quits by itself
when a non-looping timeline ends; stop a looping one with: scripts/lid quit
TXT
}

ROOT="${0:A:h:h}"
APP="$ROOT/build/Scuttle.app"
STATE="$HOME/Library/Application Support/Scuttle/state.json"
NAME="peek"
REBUILD=0
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --rebuild) REBUILD=1 ;;
    *) NAME="$arg" ;;
  esac
done

if [[ -f "$NAME" ]]; then
  FILE="${NAME:A}"
else
  FILE="$ROOT/scripts/timelines/$NAME.json"
fi
if [[ ! -f "$FILE" ]]; then
  echo "No such timeline: $NAME" >&2
  exit 1
fi

if (( REBUILD )) || [[ ! -x "$APP/Contents/MacOS/Scuttle" ]]; then
  "$ROOT/scripts/build-app.sh"
fi

if [[ -f "$STATE" ]]; then
  "$ROOT/scripts/lid" quit || true
  for i in {1..30}; do
    [[ -f "$STATE" ]] || break
    sleep 0.1
  done
fi

echo "Playing $FILE with the HUD on. Watch the built-in display."
exec "$APP/Contents/MacOS/Scuttle" --fresh --hud --timeline "$FILE" --quit-when-done
