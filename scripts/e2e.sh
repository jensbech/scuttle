#!/bin/zsh
set -uo pipefail
zmodload zsh/datetime

usage() {
  cat <<'TXT'
Usage: scripts/e2e.sh [--no-build]

End-to-end check that never touches the lid. Builds build/Scuttle.app, launches
it with a fixed seed and no saved preferences, drives lid angles through the
scuttle:// URL scheme and asserts on ~/Library/Application Support/Scuttle/state.json:

  nothing visible while the lid is open
  critters appear within APPEAR_WITHIN seconds at a low angle (default 12)
  after snapping open some are still visible at 0.5 s
  after snapping open all are gone within GONE_WITHIN seconds (default 12)
  off, on, hud, population, timeline play/stop and sensor commands work
  sleep/stage settles a full population into a frozen frame with the overlay
  ordered in (STAGED_AT_LEAST of 30 on screen, default 24), and sleep/wake
  starts the catch from the wake and they scatter
  idle/now starts an idle spell, figures creep in, idle/wake scatters them, and
  idle/<seconds> and idle/off change the setting
  rare/<name> brings a rare visitor that lands in the album (a throwaway album
  in build/e2e-album.json, never your own), album/reset clears it
  season and hemisphere commands set and resolve the season (auto follows today)
  style commands switch the art style (kawaii by default)
  weather and night commands set what state.json reports; live weather stays
  unknown because the run is --fresh (no location prompt, no network)
  surroundings (window tops and the pointer): on by default; ledge?x=&y=&w= and
  pointer?x=&y= add pretend ones that state.json counts, ledge/clear and
  pointer/clear remove them, surroundings/off empties everything, and
  --surroundings hands off; real windows are scanned while figures are out and
  never while idle or stopped (ledgeScans stays put)
  a second instance hands off and exits
  quit exits the process and removes the state file

The pack clears in about 3 s, but now and then one confused straggler stays
behind for roughly 3 to 7 s more before it finds the way out (seed 42 currently has one
on its first scatter), so GONE_WITHIN allows for that. Figures arrive a few at
a time (about 3 at first, the full population only after a minute of darkness),
so the checks only ask for a couple to be out. RARE_WITHIN (default 20) is how
long a summoned rare visitor may take to turn up.

The idle checks use idle/hold, which ignores real input, so typing during the
run does not break them. Launches pass --weather off and scuttle://idle/off so
nothing depends on the weather or on how long you have been away.

Prints PASS or FAIL per check and exits non-zero if any failed. A running
Scuttle is quit first. The app log is kept in build/e2e.log. If the display is
asleep or the screen is locked the app correctly pauses itself, so the script
checks that and reruns the remaining checks with --headless.
TXT
}

BUILD=1
for arg in "$@"; do
  case "$arg" in
    --no-build) BUILD=0 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

ROOT="${0:A:h:h}"
APP="$ROOT/build/Scuttle.app"
BIN="$APP/Contents/MacOS/Scuttle"
STATE="$HOME/Library/Application Support/Scuttle/state.json"
LOG="$ROOT/build/e2e.log"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
APPEAR_WITHIN="${APPEAR_WITHIN:-12}"
GONE_WITHIN="${GONE_WITHIN:-12}"
RARE_WITHIN="${RARE_WITHIN:-20}"
ALBUM="$ROOT/build/e2e-album.json"
STAGED_AT_LEAST="${STAGED_AT_LEAST:-24}"
HEADLESS=0
FAILS=0
PID=""

pass() { print -r -- "PASS  $1" }
fail() { print -r -- "FAIL  $1"; FAILS=$(( FAILS + 1 )) }
check() {
  if [[ "$1" == "$2" ]]; then pass "$3"; else fail "$3 (wanted $2, got ${1:-nothing})"; fi
}
get() { /usr/bin/plutil -extract "$1" raw -o - "$STATE" 2>/dev/null }
getjson() { /usr/bin/plutil -extract "$1" json -o - "$STATE" 2>/dev/null }
send() { /usr/bin/open -g "scuttle://$1" }
wait_for() {
  local key=$1 want=$2 limit=$3 start=$EPOCHREALTIME
  while (( EPOCHREALTIME - start < limit )); do
    [[ "$(get $key)" == "$want" ]] && return 0
    sleep 0.05
  done
  return 1
}
wait_json() {
  local key=$1 want=$2 limit=$3 start=$EPOCHREALTIME
  while (( EPOCHREALTIME - start < limit )); do
    [[ "$(getjson $key)" == "$want" ]] && return 0
    sleep 0.1
  done
  return 1
}
wait_gone() {
  local limit=$1 start=$EPOCHREALTIME
  while (( EPOCHREALTIME - start < limit )); do
    if [[ "$(get visibleCritters)" == 0 ]]; then
      printf '%.1f' $(( EPOCHREALTIME - start ))
      return 0
    fi
    sleep 0.05
  done
  return 1
}
wait_spotted() {
  local name=$1 limit=$2 start=$EPOCHREALTIME
  while (( EPOCHREALTIME - start < limit )); do
    [[ "$(getjson spotted)" == *"\"$name\""* ]] && return 0
    sleep 0.1
  done
  return 1
}
wait_visible() {
  local limit=$1 start=$EPOCHREALTIME v
  while (( EPOCHREALTIME - start < limit )); do
    v="$(get visibleCritters)"
    if [[ -n "$v" ]] && (( v > 0 )); then
      printf '%.1f' $(( EPOCHREALTIME - start ))
      return 0
    fi
    sleep 0.05
  done
  return 1
}
expected_season() {
  local m=$1 d=$2 hemi=$3
  if (( (m == 12 && d == 31) || (m == 1 && d == 1) )); then print newyear; return; fi
  if (( m == 12 && d <= 26 )); then print christmas; return; fi
  if (( m == 10 && d >= 24 )); then print halloween; return; fi
  if [[ "$hemi" == southern ]]; then m=$(( (m + 5) % 12 + 1 )); fi
  case $m in
    3|4|5) print spring ;;
    6|7|8) print summer ;;
    9|10|11) print autumn ;;
    *) print winter ;;
  esac
}
cleanup() {
  if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID" 2>/dev/null
    sleep 0.5
    kill -9 "$PID" 2>/dev/null
  fi
}
trap cleanup EXIT

if (( BUILD )); then
  if "$ROOT/scripts/build-app.sh" > "$ROOT/build-e2e.log" 2>&1; then
    rm -f "$ROOT/build-e2e.log"
    pass "build"
  else
    fail "build (see build-e2e.log)"
    exit 1
  fi
fi
if [[ ! -x "$BIN" ]]; then
  fail "no app at $APP"
  exit 1
fi

if /usr/bin/pgrep -x Scuttle >/dev/null; then
  print -r -- "note  quitting the Scuttle that is already running"
  /usr/bin/pkill -x Scuttle
  sleep 1
fi
rm -f "$STATE" "$ALBUM"
"$LSREGISTER" -f "$APP" 2>/dev/null

launch() {
  "$BIN" --fresh --no-status-item --seed 42 --population 30 --angle 110 --weather off --album "$ALBUM" "$@" scuttle://idle/off > "$LOG" 2>&1 &
  PID=$!
  wait_for pid "$PID" 5
}

if launch; then pass "launch writes state.json with its pid"; else fail "launch writes state.json with its pid"; exit 1; fi
sleep 0.5
if [[ "$(get paused)" == true ]]; then
  check "$(get pace)" stopped "paused and stopped while the display is asleep or locked"
  print -r -- "note  display is asleep or locked; rerunning the rest headless (timer-driven, no overlay window)"
  kill "$PID"
  for i in {1..30}; do
    kill -0 "$PID" 2>/dev/null || break
    sleep 0.1
  done
  if launch --headless; then pass "headless relaunch"; else fail "headless relaunch"; exit 1; fi
  HEADLESS=1
fi
check "$(get source)" manual "source is manual when started with --angle"
check "$(get enabled)" true "starts enabled"
check "$(get style)" kawaii "art style starts on kawaii"
check "$(get weatherSetting)" off "--weather off sets the weather setting"
check "$(get weather)" "" "no weather with --weather off"
check "$(get idleSetting)" 0 "idle trigger off for the run"
check "$(get idle)" false "not idle at launch"
check "$(getjson spotted)" "[]" "album starts empty"
check "$(get surroundings)" true "surroundings start on"
check "$(get ledges)" 0 "no ledges while nothing is out"
check "$(get pointer)" false "pointer not read while nothing is out"

sleep 1.5
check "$(get visibleCritters)" 0 "nothing visible with the lid open"
check "$(get pace)" idle "idles (no display link) with the lid open"
check "$(get ledgeScans)" 0 "no window scans while idle"

send angle/110
if wait_for angle 110 3; then pass "URL scheme reaches the app"; else fail "URL scheme reaches the app"; fi

send angle/20
if t=$(wait_visible "$APPEAR_WITHIN"); then
  pass "critters appear at 20 degrees (after ${t}s)"
else
  fail "critters appear at 20 degrees within ${APPEAR_WITHIN}s"
fi
sleep 6
OUT="$(get visibleCritters)"
if [[ -n "$OUT" ]] && (( OUT >= 2 )); then pass "several critters out after settling ($OUT)"; else fail "several critters out after settling (${OUT:-none})"; fi
SCANS="$(get ledgeScans)"
if [[ -n "$SCANS" ]] && (( SCANS >= 3 )); then pass "windows scanned about once a second while figures are out ($SCANS scans)"; else fail "windows scanned while figures are out (${SCANS:-none} scans)"; fi
LEDGES="$(get ledges)"
if [[ "$LEDGES" == <-> ]] && (( LEDGES <= 24 )); then pass "ledges counted while figures are out ($LEDGES)"; else fail "ledges counted while figures are out (${LEDGES:-none})"; fi

send angle/110
wait_for angle 110 3
T0=$EPOCHREALTIME
EARLY=""
GONE=""
while (( EPOCHREALTIME - T0 < GONE_WITHIN + 3 )); do
  v="$(get visibleCritters)"
  now=$(( EPOCHREALTIME - T0 ))
  if [[ -z "$EARLY" ]] && (( now >= 0.5 )); then EARLY="${v:-0}"; fi
  if [[ "$v" == 0 ]]; then GONE=$now; break; fi
  sleep 0.03
done
if [[ -z "$EARLY" ]]; then EARLY=0; fi
if (( EARLY > 0 )); then
  pass "not all gone 0.5s after snapping open ($EARLY of $OUT still visible)"
else
  fail "not all gone 0.5s after snapping open (all $OUT vanished in $(printf '%.2f' ${GONE:-0})s)"
fi
if [[ -n "$GONE" ]] && (( GONE <= GONE_WITHIN )); then
  pass "all gone after snapping open ($(printf '%.1f' $GONE)s)"
else
  fail "all gone within ${GONE_WITHIN}s of snapping open ($(get visibleCritters) left)"
fi
if wait_for pace idle 8; then pass "returns to idle once they are gone"; else fail "returns to idle once they are gone (pace $(get pace))"; fi
SCANS="$(get ledgeScans)"
sleep 2.5
check "$(get ledgeScans)" "$SCANS" "no window scans once idle again"
check "$(get ledges)" 0 "ledges cleared once idle again"

send sleep/stage
if wait_for sleep staged 3; then pass "sleep/stage stages the world for the way down"; else fail "sleep/stage stages the world (sleep $(get sleep))"; fi
STAGED="$(get visibleCritters)"
if [[ "$STAGED" == <-> ]] && (( STAGED >= STAGED_AT_LEAST )); then pass "staged frame holds a full on-screen population before the wake ($STAGED of 30)"; else fail "staged frame holds a full on-screen population (${STAGED:-none} of 30, wanted $STAGED_AT_LEAST)"; fi
check "$(get pace)" staged "staged pace holds the frame without ticking"
check "$(get catching)" false "nobody is caught while staged"
if [[ "$HEADLESS" == 0 ]]; then check "$(get overlayShown)" true "overlay window is ordered in with the staged frame"; fi
sleep 1
check "$(get visibleCritters)" "$STAGED" "staged figures hold still until the wake"
send sleep/wake
T0=$EPOCHREALTIME
if wait_for catching true 2; then pass "catch starts at the wake ($(printf '%.2f' $(( EPOCHREALTIME - T0 )))s after sleep/wake)"; else fail "catch starts at the wake (catching $(get catching), sleep $(get sleep))"; fi
check "$(get wakeCatches)" 1 "one wake catch counted"
check "$(get sleep)" awake "awake again once the catch starts"
if t=$(wait_gone "$GONE_WITHIN"); then
  pass "staged figures scatter after the wake (${t}s)"
else
  fail "staged figures scatter within ${GONE_WITHIN}s of the wake ($(get visibleCritters) left)"
fi
if wait_for pace idle 8; then pass "returns to idle after the wake catch"; else fail "returns to idle after the wake catch (pace $(get pace))"; fi

send idle/now
if wait_for idle true 3; then pass "idle/now starts an idle spell"; else fail "idle/now starts an idle spell"; fi
send idle/hold
if t=$(wait_visible $(( APPEAR_WITHIN + 4 ))); then
  pass "critters creep in while idle with the lid open (after ${t}s)"
else
  fail "critters creep in while idle within $(( APPEAR_WITHIN + 4 ))s"
fi
check "$(get angle)" 110 "idle leaves the lid angle alone"
sleep 2
send idle/wake
if wait_for idle false 3; then pass "idle/wake ends the idle spell"; else fail "idle/wake ends the idle spell"; fi
if t=$(wait_gone "$GONE_WITHIN"); then
  pass "they scatter when the idle spell ends (${t}s)"
else
  fail "they scatter within ${GONE_WITHIN}s when the idle spell ends ($(get visibleCritters) left)"
fi
wait_for pace idle 8
send idle/60
if wait_for idleSetting 60 3; then pass "idle/60 sets the idle threshold"; else fail "idle/60 sets the idle threshold"; fi
send idle/off
if wait_for idleSetting 0 3; then pass "idle/off"; else fail "idle/off"; fi
check "$(get idle)" false "idle/off leaves nothing idle"

send off
if wait_for enabled false 3; then pass "off disables"; else fail "off disables"; fi
send angle/20
sleep 3
check "$(get visibleCritters)" 0 "nothing appears while off"
check "$(get pace)" stopped "stopped while off"
SCANS="$(get ledgeScans)"
sleep 2
check "$(get ledgeScans)" "$SCANS" "no window scans while stopped"

send on
if wait_for enabled true 3; then pass "on enables"; else fail "on enables"; fi
if t=$(wait_visible "$APPEAR_WITHIN"); then
  pass "critters come back after on (after ${t}s)"
else
  fail "critters come back after on within ${APPEAR_WITHIN}s"
fi

send rare/polar-bear
if wait_spotted polarbear "$RARE_WITHIN"; then
  pass "rare/polar-bear turns up and lands in the album"
else
  fail "rare/polar-bear turns up and lands in the album within ${RARE_WITHIN}s (spotted $(getjson spotted))"
fi
if [[ -f "$ALBUM" ]] && /usr/bin/grep -q '"polarbear"' "$ALBUM"; then
  pass "album is written to the --album file"
else
  fail "album is written to the --album file"
fi
send album/reset
if wait_json spotted "[]" 3; then pass "album/reset empties the album"; else fail "album/reset empties the album (spotted $(getjson spotted))"; fi

send hud/on
if wait_for hud true 3; then pass "hud/on"; else fail "hud/on"; fi
send hud/off
if wait_for hud false 3; then pass "hud/off"; else fail "hud/off"; fi
send population/12
if wait_for population 12 3; then pass "population/12"; else fail "population/12"; fi

send play/peek
if wait_for timeline peek 3; then pass "play/peek starts the bundled timeline"; else fail "play/peek starts the bundled timeline"; fi
check "$(get source)" timeline "source is timeline while playing"
send "play?file=$ROOT/scripts/timelines/tease.json"
if wait_for timeline tease 3; then pass "play?file= loads a timeline by path"; else fail "play?file= loads a timeline by path"; fi
send stop
if wait_for source sensor 3; then pass "stop returns to the sensor"; else fail "stop returns to the sensor"; fi
send angle/90
wait_for source manual 3
send sensor
if wait_for source sensor 3; then pass "sensor command"; else fail "sensor command"; fi

MONTH=$(date +%-m)
DAY=$(date +%-d)
HEMI="$(get hemisphere)"
check "$(get seasonSetting)" auto "season setting starts on auto"
check "$(get season)" "$(expected_season $MONTH $DAY $HEMI)" "auto season matches today ($MONTH/$DAY, $HEMI)"
send season/winter
if wait_for season winter 3; then pass "season/winter"; else fail "season/winter (season $(get season))"; fi
check "$(get seasonSetting)" winter "season setting follows a fixed season"
send season/xmas
if wait_for season christmas 3; then pass "season/xmas alias picks christmas"; else fail "season/xmas alias picks christmas (season $(get season))"; fi
send season/bogus
sleep 1
check "$(get seasonSetting)" christmas "unknown season name is ignored"
send hemisphere/southern
if wait_for hemisphere southern 3; then pass "hemisphere/southern"; else fail "hemisphere/southern"; fi
send season/auto
if wait_for seasonSetting auto 3; then pass "season/auto"; else fail "season/auto (setting $(get seasonSetting))"; fi
check "$(get season)" "$(expected_season $MONTH $DAY southern)" "auto season flips for the southern hemisphere"
send hemisphere/northern
if wait_for hemisphere northern 3; then pass "hemisphere/northern"; else fail "hemisphere/northern"; fi
check "$(get season)" "$(expected_season $MONTH $DAY northern)" "auto season for the northern hemisphere"
"$BIN" --season halloween > /dev/null 2>&1
if wait_for season halloween 3; then pass "--season hands off to the running instance"; else fail "--season hands off to the running instance (season $(get season))"; fi
send season/auto
wait_for seasonSetting auto 3

send style/doodle
if wait_for style doodle 3; then pass "style/doodle"; else fail "style/doodle (style $(get style))"; fi
send style/rubber-hose
if wait_for style hose 3; then pass "style/rubber-hose alias picks hose"; else fail "style/rubber-hose alias picks hose (style $(get style))"; fi
send style/bogus
sleep 1
check "$(get style)" hose "unknown style name is ignored"
"$BIN" --style sticker > /dev/null 2>&1
if wait_for style sticker 3; then pass "--style hands off to the running instance"; else fail "--style hands off to the running instance (style $(get style))"; fi
send style/kawaii
wait_for style kawaii 3

send weather/rain
if wait_for weather rain 3; then pass "weather/rain"; else fail "weather/rain (weather $(get weather))"; fi
check "$(get weatherSetting)" rain "weather setting follows a fixed kind"
send weather/thunder
if wait_for weather storm 3; then pass "weather/thunder alias picks storm"; else fail "weather/thunder alias picks storm (weather $(get weather))"; fi
send weather/bogus
sleep 1
check "$(get weatherSetting)" storm "unknown weather name is ignored"
"$BIN" --weather fog > /dev/null 2>&1
if wait_for weather fog 3; then pass "--weather hands off to the running instance"; else fail "--weather hands off to the running instance (weather $(get weather))"; fi
send weather/live
if wait_for weatherSetting live 3; then pass "weather/live"; else fail "weather/live"; fi
sleep 1
check "$(get weather)" "" "live weather stays unknown in a --fresh run"
send weather/off
if wait_for weatherSetting off 3; then pass "weather/off"; else fail "weather/off"; fi
check "$(get weather)" "" "no weather when off"
send night/on
if wait_for night true 3; then pass "night/on"; else fail "night/on"; fi
send night/off
if wait_for night false 3; then pass "night/off"; else fail "night/off"; fi
HOUR=$(date +%-H)
if (( HOUR < 7 || HOUR >= 19 )); then NIGHT=true; else NIGHT=false; fi
send night/auto
if wait_for night $NIGHT 3; then pass "night/auto follows the clock ($HOUR:00 is night: $NIGHT)"; else fail "night/auto follows the clock (wanted $NIGHT, got $(get night))"; fi

send angle/110
wait_for pace idle 15
send "ledge?x=100&y=400&w=300"
if wait_for ledges 1 3; then pass "ledge?x=&y=&w= adds a pretend ledge"; else fail "ledge?x=&y=&w= adds a pretend ledge (ledges $(get ledges))"; fi
send "ledge?x=600&y=250&w=200&h=50"
if wait_for ledges 2 3; then pass "a second pretend ledge with a height"; else fail "a second pretend ledge with a height (ledges $(get ledges))"; fi
send "ledge?x=1&y=2"
sleep 0.5
check "$(get ledges)" 2 "ledge without a width is ignored"
send "pointer?x=320&y=240"
if wait_for pointer true 3; then pass "pointer?x=&y= pins the pointer"; else fail "pointer?x=&y= pins the pointer"; fi
send surroundings/off
if wait_for surroundings false 3; then pass "surroundings/off"; else fail "surroundings/off"; fi
check "$(get ledges)" 0 "no ledges with surroundings off"
check "$(get pointer)" false "no pointer with surroundings off"
send surroundings/toggle
if wait_for surroundings true 3; then pass "surroundings/toggle turns it back on"; else fail "surroundings/toggle turns it back on"; fi
check "$(get ledges)" 2 "pretend ledges come back with surroundings on"
"$BIN" --surroundings off > /dev/null 2>&1
if wait_for surroundings false 3; then pass "--surroundings hands off to the running instance"; else fail "--surroundings hands off to the running instance"; fi
send surroundings/on
wait_for surroundings true 3
send pointer/clear
if wait_for pointer false 3; then pass "pointer/clear"; else fail "pointer/clear"; fi
send ledge/clear
if wait_for ledges 0 3; then pass "ledge/clear"; else fail "ledge/clear (ledges $(get ledges))"; fi

"$BIN" scuttle://angle/77 > /dev/null 2>&1
if wait_for angle 77 3; then pass "second instance hands off and exits"; else fail "second instance hands off and exits"; fi
check "$(/usr/bin/pgrep -x Scuttle | wc -l | tr -d ' ')" 1 "still a single instance"

send quit
for i in {1..50}; do
  kill -0 "$PID" 2>/dev/null || break
  sleep 0.1
done
if kill -0 "$PID" 2>/dev/null; then fail "quit exits the process"; else pass "quit exits the process"; fi
if [[ -e "$STATE" ]]; then fail "quit removes state.json"; else pass "quit removes state.json"; fi

print
if (( FAILS )); then
  print -r -- "$FAILS check(s) failed"
  exit 1
fi
print -r -- "all checks passed"
