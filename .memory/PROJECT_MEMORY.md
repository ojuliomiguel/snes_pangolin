# Project Memory: snes_pangolin

## What this project is
A Super Nintendo (SNES) ROM template/project using 65816 assembly with the `ca65/ld65` (cc65) toolchain.
The project goal is exploratory and can evolve over time.
It started as a simple LoROM (`hello.sfc`) / hello-world style baseline with:
- BG1 text ("JULIO MIGUEL");
- A cup sprite below the text;
- Local build and execution via `make`.
From here, scope can expand incrementally as new experiments are added.

## Stack and architecture
- Language: 65816 Assembly (`.asm`, `.inc`).
- Link/config files: `.cfg` files in `src/` (`snes.cfg`, `minimal.cfg`).
- Binary assets for VRAM/CGRAM in `assets/`.
- Main build entrypoint: root `Makefile`.
- Utility scripts: `scripts/run_emulator.sh` and `scripts/watch.sh`.

## Main workflow
1. `make`:
   - Assembles `src/hello.asm` into `build/hello.o` via `ca65`.
   - Links with `src/snes.cfg` into `build/hello.sfc` via `ld65`.
   - Copies ROM to root as `hello.sfc`.
2. `make run`:
   - Calls `scripts/run_emulator.sh` with the absolute ROM path.
   - Script tries `OpenEmu`, `mesen`, `snes9x`, or app binaries under `/Applications/...`.
3. `make watch`:
   - Automatic rebuild with `fswatch` (if available), or hash/snapshot polling fallback.

## Key files
- `README.md`: quick build/run/watch flow and emulator setup.
- `Makefile`: targets `all`, `run`, `watch`, `clean`.
- `src/hello.asm`: main ROM implementation (header, vectors, PPU init, BG, OAM/sprite).
- `src/snes.cfg`: memory/segment map for the main build.
- `src/test_minimal.asm` and `src/minimal.cfg`: minimal alternative experiment.
- `assets/font.bin`: font tiles.
- `assets/cup_16x8_4bpp.bin` and `assets/cup_16x8_palette.cgram`: cup art/palette.

## Conventions and notes
- Expected final ROM outputs: `build/hello.sfc` and root copy `hello.sfc`.
- Project focus is low-level SNES prototyping (PPU/VRAM/OAM) with fast iteration and evolving goals.
- `clean` target removes build artifacts and generated `.sfc` files.

## Useful commands
- `make`
- `make run`
- `make watch`
- `make clean`
