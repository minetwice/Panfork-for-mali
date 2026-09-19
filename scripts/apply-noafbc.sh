#!/usr/bin/env bash
set -euo pipefail
FILE=src/gallium/drivers/panfrost/pan_screen.c
if ! grep -q 'PAN_MESA_DEBUG' "$FILE"; then
  echo "PAN_MESA_DEBUG not found in $FILE"
  exit 1
fi
if grep -q 'defined(__ANDROID__)' "$FILE"; then
  echo "already patched"
  exit 0
fi
python3 << 'PY'
from pathlib import Path
p = Path("src/gallium/drivers/panfrost/pan_screen.c")
t = p.read_text()
needle = 'debug_get_flags_option("PAN_MESA_DEBUG", panfrost_debug_options, 0);'
insert = '''debug_get_flags_option("PAN_MESA_DEBUG", panfrost_debug_options, 0);
#if defined(__ANDROID__) || defined(ANDROID)
   if (!(dev->debug & PAN_DBG_NO_AFBC))
      dev->debug |= PAN_DBG_NO_AFBC;
#endif'''
if needle not in t:
    raise SystemExit("patch context not found")
p.write_text(t.replace(needle, insert, 1))
print("patched ok")
PY
