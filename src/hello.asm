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
    .segment "ZEROPAGE"
FadeLevel:      .res 1
FadeCounter:    .res 1
SteamCounter:   .res 1

    .segment "CODE"

; ------------------------------------------
; Constantes de posição
; ------------------------------------------
SCREEN_TILE_W    = 32
NAME_LEN_TILES   = 12
NAME_TILE_X      = ((SCREEN_TILE_W - NAME_LEN_TILES) / 2) ; coluna em tiles (BG1)
NAME_TILE_Y      = 10          ; linha  em tiles (BG1)
BG1_MAP_WORD     = $0400       ; VRAM word addr ($0800 bytes): tilemap BG1 fora da área OBJ
NAME_BG_WORD     = (BG1_MAP_WORD + NAME_TILE_Y*32 + NAME_TILE_X)

NAME_PIX_X       = (NAME_TILE_X * 8)
NAME_PIX_W       = (NAME_LEN_TILES * 8)
CUP_PIX_W        = 16
CUP_PIX_X_LEFT   = (NAME_PIX_X + ((NAME_PIX_W - CUP_PIX_W) / 2)) ; centralizado sob o texto
CUP_PIX_Y        = (NAME_TILE_Y*8 + 24) ; mais abaixo do nome (px)
CUP_PIX_X_RIGHT  = (CUP_PIX_X_LEFT + 8) ; sprite direito
CUP_PIX_Y_BOTTOM = (CUP_PIX_Y + 8)      ; segunda linha alinhada para sprite 16x16 nítido
CUP_STEAM_X      = (CUP_PIX_X_LEFT + 5)
CUP_STEAM_Y0     = (CUP_PIX_Y - 8)
CUP_STEAM_Y1     = (CUP_PIX_Y - 10)
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

; ----- Paleta BG colorida (céu e texto claro) -----
    sep #$20
    .a8
    stz $2121            ; palette 0, color 0
    lda #$E0             ; cor 0 = ciano claro (backdrop)
    sta $2122
    lda #$5F
    sta $2122
    lda #$FF             ; cor 1 = branco
    sta $2122
    lda #$7F
    sta $2122
    lda #$DA             ; cor 2 = verde água
    sta $2122
    lda #$56
    sta $2122
    lda #$84             ; cor 3 = azul mais escuro
    sta $2122
    lda #$31
    sta $2122

    lda #$04             ; palette 1 (sombra)
    sta $2121
    lda #$E0             ; cor 0 igual ao backdrop
    sta $2122
    lda #$5F
    sta $2122
    lda #$A2             ; cor 1 = sombra escura
    sta $2122
    lda #$14
    sta $2122

    lda #$08             ; palette 2 (texto principal)
    sta $2121
    lda #$E0             ; cor 0 igual ao backdrop
    sta $2122
    lda #$5F
    sta $2122
    lda #$FF             ; cor 1 = branco
    sta $2122
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

; ----- Escreve texto "JULIO MIGUEL" -----
    rep #$20
    .a16
    lda #NAME_BG_WORD
    sta $2116
    sep #$20
    .a8
    ldx #$0000
@name_main:
    lda NameTiles,x
    sta $2118
    lda #$08             ; palette 2
    sta $2119
    inx
    cpx #NAME_LEN_TILES
    bne @name_main

; ====== SPRITES (OBJ) ======
; OBJ são sempre 4bpp. Vamos:
; - colocar tiles da xícara + vapor em VRAM OBJ base $0000 (tiles 0..5)
; - usar 5 sprites 8x8 (4 da xícara + 1 vapor animado)
; - paleta OBJ #0 (CGRAM 0x80..0x8F)

; ----- OBSEL: base OBJ = $0000, tamanho (8x8,16x16) -----
    lda #OBJ_OBSEL_BASE
    sta $2101            ; $2101 OBSEL = base index 0, size sel 0 (small=8x8)

; ----- Paleta OBJ #0 (xícara marrom) -----
    lda #$80
    sta $2121            ; CGRAM addr = $80 (OBJ pal 0, color 0)
    stz $2122            ; cor0 = 0000 (transparente)
    stz $2122
    lda #$98             ; cor1 = corpo da caneca (bege)
    sta $2122
    lda #$32
    sta $2122
    lda #$CA             ; cor2 = contorno escuro
    sta $2122
    lda #$08
    sta $2122
    lda #$7E             ; cor3 = brilho da borda
    sta $2122
    lda #$53
    sta $2122

    ; palette 1 para vapor branco
    lda #$90
    sta $2121            ; CGRAM addr = $90 (OBJ pal 1, color 0)
    stz $2122
    stz $2122
    lda #$FF
    sta $2122
    lda #$7F
    sta $2122

; ----- Carrega tiles OBJ (xícara + vapor + base estendida) -----
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

; ----- Estado inicial de fade e animação -----
    stz FadeLevel
    stz FadeCounter
    stz SteamCounter
    jsr WriteCupSprites

; ----- Liga BG1 e OBJ no main screen -----
    lda #%00010001
    sta $212C            ; $212C TM: bit0=BG1, bit4=OBJ

; ----- Liga a tela com brilho 0 (fade-in no loop) -----
    stz $2100

Forever:
    jsr WaitFrameStart
    jsr UpdateFade
    jsr UpdateSteam
    jmp Forever

; ------------------------------------------
; Aguarda próximo VBlank (uma iteração por frame)
; ------------------------------------------
WaitFrameStart:
@wait_visible:
    lda $4212
    bmi @wait_visible
@wait_vblank:
    lda $4212
    bpl @wait_vblank
    rts

; ------------------------------------------
; Fade-in de brilho global ($2100 0..F)
; ------------------------------------------
UpdateFade:
    lda FadeLevel
    cmp #$0F
    bcs @fade_done
    inc FadeCounter
    lda FadeCounter
    cmp #$03             ; sobe 1 nível a cada 3 frames
    bcc @fade_done
    stz FadeCounter
    inc FadeLevel
    lda FadeLevel
    sta $2100
@fade_done:
    rts

; ------------------------------------------
; Alterna frame do vapor e reescreve os sprites
; ------------------------------------------
UpdateSteam:
    inc SteamCounter
    jsr WriteCupSprites
    rts

; ------------------------------------------
; Escreve 5 sprites (xícara 16x16 + vapor)
; ------------------------------------------
WriteCupSprites:
    stz $2102            ; OAM addr = 0
    stz $2103

    ; Sprite 0 (tile 0) — esquerda
    lda #CUP_PIX_X_LEFT
    sta $2104
    lda #CUP_PIX_Y
    sta $2104
    lda #$00
    sta $2104
    lda #$00
    sta $2104

    ; Sprite 1 (tile 1) — direita (linha de cima)
    lda #CUP_PIX_X_RIGHT
    sta $2104
    lda #CUP_PIX_Y
    sta $2104
    lda #$01
    sta $2104
    lda #$00
    sta $2104

    ; Sprite 2 (tile 4) — esquerda (base estendida)
    lda #CUP_PIX_X_LEFT
    sta $2104
    lda #CUP_PIX_Y_BOTTOM
    sta $2104
    lda #$04
    sta $2104
    lda #$00
    sta $2104

    ; Sprite 3 (tile 5) — direita (base estendida)
    lda #CUP_PIX_X_RIGHT
    sta $2104
    lda #CUP_PIX_Y_BOTTOM
    sta $2104
    lda #$05
    sta $2104
    lda #$00
    sta $2104

    ; Sprite 4 (tile 2/3) — vapor animado (palette 1)
    lda #CUP_STEAM_X
    sta $2104
    lda SteamCounter
    and #$08
    beq @steam_frame0
@steam_frame1:
    lda #CUP_STEAM_Y1
    sta $2104
    lda #$03
    sta $2104
    lda #$02
    sta $2104
    rts
@steam_frame0:
    lda #CUP_STEAM_Y0
    sta $2104
    lda #$02
    sta $2104
    lda #$02
    sta $2104
    rts

; ==========================================
; DADOS
; ==========================================
    .align 2
CharacterData:
    .incbin "../assets/font.bin"
CharacterDataEnd:

NameTiles:
    .byte 10,21,12,9,15,0,13,9,7,21,5,12

    .align 2
CupTiles:
    ; tile 0: xícara topo-esquerda (contorno + preenchimento)
    .byte $00,$3F,$1F,$7F,$1F,$60,$1F,$60
    .byte $1F,$60,$1F,$60,$1F,$60,$1F,$60
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00

    ; tile 1: xícara topo-direita (com alça)
    .byte $00,$F0,$E0,$F8,$E0,$18,$E0,$1E
    .byte $E0,$1B,$E0,$1B,$E0,$1B,$E0,$1E
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00

    ; tile 2: vapor frame A (8x8, 4bpp, usa cor 1)
    .byte $18,$00,$24,$00,$18,$00,$08,$00
    .byte $10,$00,$20,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00

    ; tile 3: vapor frame B (8x8, 4bpp, usa cor 1)
    .byte $30,$00,$48,$00,$30,$00,$10,$00
    .byte $08,$00,$04,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00

    ; tile 4: xícara base-esquerda (corpo + pé)
    .byte $1F,$60,$1F,$60,$1F,$60,$0F,$30
    .byte $00,$3F,$00,$1F,$00,$0F,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00

    ; tile 5: xícara base-direita
    .byte $E0,$18,$E0,$18,$E0,$18,$E0,$18
    .byte $00,$F0,$00,$E0,$00,$C0,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
CupTilesEnd:
