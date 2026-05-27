#!/usr/bin/env bash
#
# Debug helper for merlin-mockup.
#
# Builds the server, runs it with its logs captured, sends one or more requests
# over the socket, then prints each response followed by the full server log.
#
# Usage:
#   scripts/debug.sh                                   # default: tests/defs/math / all
#   scripts/debug.sh <defs> <completion>               # one request
#   scripts/debug.sh <defs> <completion> [<defs> <completion> ...]   # several
#
# Examples:
#   scripts/debug.sh tests/defs/math "part 4"
#   scripts/debug.sh tests/defs/math "part 1" tests/defs/fruits all
#
# <completion> is "all" or "part N". Paths are relative to the repo root.
#
# Verbosity is controlled by `debug_lvl` in src/debug.ml: a message logged at
# level L is shown when debug_lvl > L, so raise it there to see more (a rebuild
# is triggered automatically by this script).

set -uo pipefail

PORT=8453
HOST=localhost
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXE="_build/default/src/merlin_mockup.exe"
cd "$ROOT"

LOG="$(mktemp)"
cleanup() {
  [ -n "${SRV:-}" ] && kill "$SRV" 2>/dev/null
  rm -f "$LOG"
}
trap cleanup EXIT

echo "== Building =="
dune build src/merlin_mockup.exe || exit 1

# Default request when none is given on the command line.
if [ "$#" -eq 0 ]; then
  set -- tests/defs/math all
fi

echo "== Starting server (logs in $LOG) =="
# OCAMLRUNPARAM=b keeps backtraces in the captured exception logs.
OCAMLRUNPARAM=b "$EXE" >"$LOG" 2>&1 &
SRV=$!

# Wait until the listening socket is actually set up.
for _ in $(seq 1 50); do
  grep -q "server socket is setup" "$LOG" && break
  sleep 0.1
done

# Each request is a (defs, completion) pair.
while [ "$#" -ge 2 ]; do
  defs="$1"; compl="$2"; shift 2
  echo
  echo "== Request: $defs | $compl =="
  printf '%s\n%s' "$defs" "$compl" | nc -w1 "$HOST" "$PORT"
done

echo
echo "== Closing server =="
printf '.\nclose' | nc -w1 "$HOST" "$PORT"

# Let the server flush its final log lines.
sleep 0.3

echo
echo "== Server log =="
cat "$LOG"
