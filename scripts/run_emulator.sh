#!/usr/bin/env bash
set -euo pipefail

ROM_PATH="${1:-}"
if [[ -z "$ROM_PATH" ]]; then
  echo "Usage: $0 /absolute/path/to/rom.sfc"
  exit 1
fi

if [[ ! -f "$ROM_PATH" ]]; then
  echo "ROM not found: $ROM_PATH"
  exit 1
fi

find_emulator() {
  if [[ -n "${EMULATOR:-}" ]]; then
    echo "$EMULATOR"
    return 0
  fi

  if [[ -d "/Applications/OpenEmu.app" ]]; then
    echo "OpenEmu.app"
    return 0
  fi

  if command -v mesen >/dev/null 2>&1; then
    echo "mesen"
    return 0
  fi

  if command -v snes9x >/dev/null 2>&1; then
    echo "snes9x"
    return 0
  fi

  local mac_mesen="/Applications/Mesen.app/Contents/MacOS/Mesen"
  local mac_snes9x="/Applications/Snes9x.app/Contents/MacOS/snes9x"

  if [[ -x "$mac_mesen" ]]; then
    echo "$mac_mesen"
    return 0
  fi

  if [[ -x "$mac_snes9x" ]]; then
    echo "$mac_snes9x"
    return 0
  fi

  return 1
}

EMU="$(find_emulator || true)"
if [[ -z "$EMU" ]]; then
  cat <<MSG
No SNES emulator found.

Install one of these or set EMULATOR explicitly:
- OpenEmu
- Mesen 2
- Snes9x

Example:
  EMULATOR="OpenEmu.app" make run
MSG
  exit 2
fi

if [[ "$EMU" == "OpenEmu.app" ]]; then
  open -a "OpenEmu.app" "$ROM_PATH"
  exit 0
fi

if [[ "$EMU" == *.app ]]; then
  open -a "$EMU" "$ROM_PATH"
  exit 0
fi

"$EMU" "$ROM_PATH"
