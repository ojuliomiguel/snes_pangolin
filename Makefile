AS=ca65
LD=ld65

SRC_DIR=src
ASSETS_DIR=assets
BUILD_DIR=build
SCRIPTS_DIR=scripts
ROM_NAME=hello

OBJ=$(BUILD_DIR)/$(ROM_NAME).o
ROM=$(BUILD_DIR)/$(ROM_NAME).sfc
ROOT_ROM=$(ROM_NAME).sfc

.PHONY: all compile run watch clean help

all: $(ROOT_ROM)

compile: $(ROOT_ROM)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(OBJ): $(SRC_DIR)/hello.asm | $(BUILD_DIR)
	$(AS) -o $@ $<

$(ROM): $(OBJ)
	$(LD) -C $(SRC_DIR)/snes.cfg -o $@ $<

$(ROOT_ROM): $(ROM)
	cp $(ROM) $(ROOT_ROM)

run: $(ROOT_ROM)
	$(SCRIPTS_DIR)/run_emulator.sh "$(abspath $(ROOT_ROM))"

watch:
	$(SCRIPTS_DIR)/watch.sh

clean:
	rm -rf $(BUILD_DIR) $(ROOT_ROM) *.o *.sfc $(SRC_DIR)/*.o $(SRC_DIR)/*.sfc

help:
	@echo "Targets disponíveis:"
	@echo "  make        -> compila ROM (gera $(ROOT_ROM) e $(ROM))"
	@echo "  make run    -> compila e abre no emulador"
	@echo "  make watch  -> recompila automaticamente ao salvar"
	@echo "  make clean  -> limpa artefatos"
	@echo ""
	@echo "Opcional: defina EMULATOR com o binário do emulador"
	@echo "Exemplo: EMULATOR=\"/Applications/Mesen.app/Contents/MacOS/Mesen\" make run"
