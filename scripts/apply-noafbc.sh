#!/usr/bin/env bash
# Back-compat wrapper — full fixes live in apply-android-fixes.sh
set -euo pipefail
bash "$(dirname "$0")/apply-android-fixes.sh"
