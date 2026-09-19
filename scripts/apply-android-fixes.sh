#!/usr/bin/env bash
# One-shot patches so this Lunarixus/24.0 tree can build OSMesa for Android.
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

# 1) Make Panfrost optional for OSMesa
SW_HELPER=src/gallium/auxiliary/target-helpers/inline_sw_helper.h
if [ -f "$SW_HELPER" ]; then
  if grep -q 'You forgot to include Panfrost' "$SW_HELPER"; then
    python3 - "$SW_HELPER" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1])
t = p.read_text()
if "#error You forgot to include Panfrost" in t:
    t = t.replace("#error You forgot to include Panfrost", "/* Panfrost not built — skip */")
    p.write_text(t)
    print("patched #error Panfrost")
else:
    print("sw_helper: #error not found")
PY
  else
    echo "sw_helper: already OK"
  fi
fi

# 2) Stub struct kbase_ if pan_base missing
DEV_H=src/panfrost/lib/pan_device.h
if [ -f "$DEV_H" ] && [ ! -f src/panfrost/base/pan_base.h ]; then
  if ! grep -q 'FEAR_KBASE_STUB' "$DEV_H"; then
    python3 - "$DEV_H" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1])
t = p.read_text()
stub = """
/* FEAR_KBASE_STUB: minimal kbase layout (pan_base missing in this tree) */
#ifndef FEAR_KBASE_STUB
#define FEAR_KBASE_STUB
struct kbase_ {
   unsigned setup_state;
   int fd;
   unsigned api;
   void *gpuprops;
   bool (*get_pan_gpuprop)(struct kbase_ *k, unsigned name, uint64_t *value);
   bool (*get_mali_gpuprop)(struct kbase_ *k, unsigned name, uint64_t *value);
   char _pad[512];
};
#endif
"""
marker = "#include <genxml/gen_macros.h>"
if marker in t:
    t = t.replace(marker, marker + "\n" + stub, 1)
else:
    t = stub + t
p.write_text(t)
print("inserted kbase stub into pan_device.h")
PY
  else
    echo "kbase stub already present"
  fi
fi

# 3) Default-disable AFBC on Android
SCREEN=src/gallium/drivers/panfrost/pan_screen.c
if [ -f "$SCREEN" ]; then
  if grep -q 'defined(__ANDROID__)' "$SCREEN"; then
    echo "noafbc: already patched"
  else
    python3 - "$SCREEN" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1])
t = p.read_text()
needle = 'debug_get_flags_option("PAN_MESA_DEBUG", panfrost_debug_options, 0);'
insert = (
    'debug_get_flags_option("PAN_MESA_DEBUG", panfrost_debug_options, 0);\n'
    '#if defined(__ANDROID__) || defined(ANDROID)\n'
    '   if (!(dev->debug & PAN_DBG_NO_AFBC))\n'
    '      dev->debug |= PAN_DBG_NO_AFBC;\n'
    '#endif'
)
if needle not in t:
    print("noafbc: context not found")
else:
    p.write_text(t.replace(needle, insert, 1))
    print("noafbc: patched")
PY
  fi
fi

echo "Android fixes applied OK"
