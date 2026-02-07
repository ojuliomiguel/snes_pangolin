#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "Watching source files. Press Ctrl+C to stop."

build() {
  make
}

if command -v fswatch >/dev/null 2>&1; then
  build
  fswatch -o src assets Makefile | while read -r _; do
    echo "Change detected: rebuilding..."
    build || true
  done
  exit 0
fi

snapshot() {
  {
    find src assets -type f \( -name '*.asm' -o -name '*.inc' -o -name '*.cfg' -o -name '*.bin' -o -name '*.cgram' \) -print0 \
      | xargs -0 stat -f '%m %N' 2>/dev/null
    stat -f '%m %N' Makefile 2>/dev/null
  } | sort | shasum
}

last="$(snapshot)"
build

while true; do
  sleep 1
  now="$(snapshot)"
  if [[ "$now" != "$last" ]]; then
    last="$now"
    echo "Change detected: rebuilding..."
    build || true
  fi
done
