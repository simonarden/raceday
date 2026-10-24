#!/usr/bin/env bash
# Builds the passcode-gated site. Publishes ONLY: index.html (gate), vault.bin (ciphertext), icons, manifest.
# Usage: RACEDAY_PASSCODE=xxxx ./build.sh  (the code is read from the environment; never pass it as an argument)
# Team bots: edit src/data.json (picks, alerts, bet status), then rerun this script.
set -euo pipefail
cd "$(dirname "$0")"
OUT="${OUT_DIR:-.}"
ITER="${RACEDAY_ITER:-600000}"
[ -f src/data.json ] || python3 src/build_data.py
python3 tools/bundle.py src build/app.html
if [ -z "${RACEDAY_PASSCODE:-}" ]; then
  echo "RACEDAY_PASSCODE is not set: built build/app.html (plain, not published) and stopped before encrypting." >&2
  exit 3
fi
if ! [[ "$RACEDAY_PASSCODE" =~ ^[0-9]{4}$ ]]; then echo "RACEDAY_PASSCODE must be exactly 4 digits." >&2; exit 4; fi
mkdir -p "$OUT"
node tools/encrypt.mjs build/app.html "$OUT/vault.bin" tools/salt.hex "$ITER"
sed "s/@@ITER@@/$ITER/" tools/gate.html > "$OUT/index.html"
if [ "$OUT" != "." ]; then cp apple-touch-icon.png icon-512.png icon.svg manifest.webmanifest .nojekyll "$OUT/"; fi
# Safety check: no plain-text race data (runner, race and meeting names from src/data.json) may appear in published files.
python3 - "$OUT/index.html" "$OUT/vault.bin" <<'PY'
import json, sys
d = json.load(open("src/data.json"))
words = {m["name"] for m in d["meetings"]} | {r["name"] for r in d["races"]} | {x["name"] for r in d["races"] for x in r["runners"]}
blob = b"".join(open(f, "rb").read() for f in sys.argv[1:])
hits = [w for w in words if len(w) > 4 and w.encode() in blob]
if hits: sys.exit("Plain race data found in output (%d names), aborting." % len(hits))
PY
echo "Built gated site in $OUT"
