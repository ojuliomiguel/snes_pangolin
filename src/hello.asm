; hello.asm — BG1 texto + sprite xícara abaixo do nome
; Toolchain: ca65/ld65, LoROM, NTSC, sem chips
; Assumido: assets/font.bin (tiles 8x8 2bpp) e assets/cup_16x8_4bpp.bin (2 tiles 8x8 4bpp)

    .setcpu "65816"

; ==========================================
; HEADER LoROM
; ==========================================
    .segment "HEADER"
    .byte "HELLO JULIO MIGUEL   "  ; [21] título
    .byte $20                      ; LoROM
    .byte $00                      ; ROM only
    .byte $05                      ; ROM size = 32KB
    .byte $00                      ; RAM size
    .byte $01                      ; NTSC
    .byte $00                      ; developer (legacy)
    .byte $00                      ; version
    .word $0000                    ; checksum complement
    .word $0000                    ; checksum

; ==========================================
; VETORES (modo nativo)
; ==========================================
    .segment "VECTORS"
    .word $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000   ; $FFE0..$FFEF
    .word $0000,$0000,$0000,$0000                           ; $FFF0..$FFFB
    .word Reset                                             ; $FFFC/$FFFD (Reset)
    .word $0000                                             ; $FFFE/$FFFF (IRQ/BRK)

; ==========================================
; CÓDIGO
; ==========================================
    .segment "CODE"

; ------------------------------------------
; Constantes de posição
; ------------------------------------------
SCREEN_TILE_W    = 32
NAME_LEN_TILES   = 12
NAME_TILE_X      = ((SCREEN_TILE_W - NAME_LEN_TILES) / 2) ; coluna em tiles (BG1)
NAME_TILE_Y      = 10          ; linha  em tiles (BG1)
BG1_MAP_WORD     = $0400       ; VRAM word addr ($0800 bytes): tilemap BG1 fora da área OBJ

NAME_PIX_X       = (NAME_TILE_X * 8)
NAME_PIX_W       = (NAME_LEN_TILES * 8)
CUP_PIX_W        = 16
CUP_PIX_X_LEFT   = (NAME_PIX_X + ((NAME_PIX_W - CUP_PIX_W) / 2)) ; centralizado sob o texto
CUP_PIX_Y        = (NAME_TILE_Y*8 + 8)  ; logo abaixo do nome (px)
CUP_PIX_X_RIGHT  = (CUP_PIX_X_LEFT + 8) ; sprite direito
OBJ_VRAM_WORD    = $0000                ; VRAM word addr ($0000 bytes)
OBJ_OBSEL_BASE   = $00                  ; OBSEL base correspondente a $0000 bytes

; ------------------------------------------
; RESET
; ------------------------------------------
Reset:
    sei
    clc
    xce                  ; entra em nativo
    rep #$30             ; A,X,Y = 16-bit
    .a16
    .i16

    ldx #$1FFF
    txs
    phk
    plb                  ; DB = PB

; ----- PPU em forced blank -----
    sep #$20
    .a8
    lda #$8F             ; $2100 INIDISP = screen off, brilho máx
    sta $2100

; ----- Mode 0 / BG1 tilemap em $0800, tiles em $1000 -----
    stz $2105            ; $2105 BGMODE = Mode 0
    lda #$04
    sta $2107            ; $2107 BG1SC = tilemap @ VRAM $0800 (32x32)
    rep #$20
    .a16
    lda #$1000
    sta $2116            ; $2116 VMADDL/H = VRAM addr (word)
    sep #$20
    .a8
    lda #$01
    sta $210B            ; $210B BG12NBA: BG1 tiles base word=$1000 (byte=$2000)
    lda #$80
    sta $2115            ; $2115 VMAIN: inc 1 word por write a $2118/9

; ----- Limpa toda a VRAM (64KB) -----
    rep #$20
    .a16
    stz $2116            ; VRAM word addr = $0000
    ldx #$8000           ; 32768 words = 64KB
@clr_vram:
    stz $2118
    dex
    bne @clr_vram

; ----- Paleta BG (fundo verde, texto branco) -----
    sep #$20
    .a8
    stz $2121            ; CGRAM addr = 0
    lda #$E0
    sta $2122            ; cor 0 (BG) = verde (E0 03)
    lda #$03
    sta $2122
    lda #$01
    sta $2121            ; CGRAM addr = 1
    lda #$FF
    sta $2122            ; cor 1 (texto) = branco (FF 7F)
    lda #$7F
    sta $2122

; ----- Carrega fonte 2bpp em VRAM word $1000 -----
    rep #$20
    .a16
    lda #$1000
    sta $2116
    ldx #$0000
@load_font:
    lda CharacterData,x
    sta $2118
    inx
    inx
    cpx #(CharacterDataEnd-CharacterData)
    bne @load_font

; ----- Escreve "JULIO MIGUEL" em BG1 linha NAME_TILE_Y -----
    lda #(BG1_MAP_WORD + NAME_TILE_Y*32 + NAME_TILE_X)
    sta $2116

    sep #$20
    .a8
    ; (Escreve tile ID no low byte, atributos no high = 0)
    ; J(10) U(21) L(12) I(9) O(15) ' ' (0) M(13) I(9) G(7) U(21) E(5) L(12)
    lda #10
    sta $2118
    stz $2119
    lda #21
    sta $2118
    stz $2119
    lda #12
    sta $2118
    stz $2119
    lda #9
    sta $2118
    stz $2119
    lda #15
    sta $2118
    stz $2119
    lda #0
    sta $2118
    stz $2119
    lda #13
    sta $2118
    stz $2119
    lda #9
    sta $2118
    stz $2119
    lda #7
    sta $2118
    stz $2119
    lda #21
    sta $2118
    stz $2119
    lda #5
    sta $2118
    stz $2119
    lda #12
    sta $2118
    stz $2119

; ====== SPRITES (OBJ) ======
; OBJ são sempre 4bpp. Vamos:
; - colocar tiles da xícara em VRAM OBJ base $0000 (tile 0 e 1)
; - usar 2 sprites 8x8 lado a lado
; - paleta OBJ #0 (CGRAM 0x80..0x8F)

; ----- OBSEL: base OBJ = $0000, tamanho (8x8,16x16) -----
    lda #OBJ_OBSEL_BASE
    sta $2101            ; $2101 OBSEL = base index 0, size sel 0 (small=8x8)

; ----- Paleta OBJ #0 mínima (cor0=transp, cor1=branco) -----
    lda #$80
    sta $2121            ; CGRAM addr = $80 (OBJ pal 0, color 0)
    stz $2122            ; cor0 = 0000 (transparente)
    stz $2122
    lda #$FF
    sta $2122            ; cor1 = FFFF? não — SNES usa 15-bit: FF 7F (=branco)
    lda #$7F
    sta $2122
    ; (Opcional: escrever mais cores conforme sua arte usar)

; ----- Carrega tiles OBJ (xícara) em VRAM OBJ base (2 tiles = 64 bytes) -----
    rep #$20
    .a16
    lda #OBJ_VRAM_WORD
    sta $2116            ; VRAM word = base OBJ
    ldx #$0000
@load_cup:
    lda CupTiles,x
    sta $2118
    inx
    inx
    cpx #(CupTilesEnd-CupTiles)
    bne @load_cup

; ----- Limpa OAM (512 + 32 bytes) -----
    sep #$20
    .a8
    stz $2102            ; OAMADDL
    stz $2103            ; OAMADDH (endereço 0, e zera latch)
    ldx #$0080           ; 128 sprites
@hide_oam:
    stz $2104            ; X low
    lda #$F0
    sta $2104            ; Y = fora da tela
    stz $2104            ; tile
    stz $2104            ; atributos
    dex
    bne @hide_oam

    stz $2102            ; OAM word addr low = $00
    lda #$01
    sta $2103            ; OAM word addr high bit = 1 -> byte $0200 (high table)
    ldx #$0020
@clr_oam_hi:
    stz $2104            ; limpa 32 bytes (X MSB/size)
    dex
    bne @clr_oam_hi

; ----- Escreve 2 sprites (8x8 cada) para formar 16x8 -----
; Formato OAM 4 bytes por sprite: [X low] [Y] [TILE] [ATRIB]
; X high e tamanho ficam na high table; como X<256 e small, fica 0.

    ; Sprite 0 (tile 0) — esquerda
    stz $2102            ; volta OAM addr = 0 (sprite 0)
    stz $2103
    lda #CUP_PIX_X_LEFT  ; X low
    sta $2104
    lda #CUP_PIX_Y       ; Y
    sta $2104
    lda #$00             ; TILE = 0 (base OBJ $0000)
    sta $2104
    lda #$00             ; ATRIB: pal=0, prioridade=0, sem flip
    sta $2104

    ; Sprite 1 (tile 1) — direita
    lda #CUP_PIX_X_RIGHT ; X low
    sta $2104
    lda #CUP_PIX_Y       ; Y
    sta $2104
    lda #$01             ; TILE = 1
    sta $2104
    lda #$00             ; ATRIB
    sta $2104

; ----- Liga BG1 e OBJ no main screen -----
    lda #%00010001
    sta $212C            ; $212C TM: bit0=BG1, bit4=OBJ

; ----- Liga a tela -----
    lda #$0F
    sta $2100

Forever:
    jmp Forever

; ==========================================
; DADOS
; ==========================================
    .align 2
CharacterData:
    .incbin "../assets/font.bin"
CharacterDataEnd:

    .align 2
CupTiles:
    .incbin "../assets/cup_16x8_4bpp.bin"  ; 64 bytes = 2 tiles 8x8 4bpp
CupTilesEnd:
