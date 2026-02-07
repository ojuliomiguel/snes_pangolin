; test_minimal.asm - Teste mínimo SNES (apenas cor de fundo)

    .setcpu "65816"
    
    .segment "HDR"
    .org $FFC0
    .byte "MINIMAL TEST         "  ; 21 bytes
    .byte $20                       ; LoROM
    .byte $00                       ; ROM only
    .byte $08                       ; ROM size
    .byte $00                       ; RAM size
    .byte $01                       ; NTSC
    .byte $33                       ; Dev
    .byte $00                       ; Version
    .word $0000                     ; Checksum complement
    .word $FFFF                     ; Checksum
    
    ; Vetores
    .org $FFE4
    .word 0,0,0,0,0,0              ; Native mode (não usado)
    .word 0,0,0,0                  ; Emulation mode (parcial)
    .word RESET                     ; RESET vector
    .word 0                         ; IRQ

    .segment "CODE"
    .org $8000

RESET:
    ; Inicialização básica
    sei                 ; Desabilita IRQs
    clc                 
    xce                 ; Modo nativo
    
    sep #$20            ; A = 8-bit
    .a8
    
    lda #$8F            ; Force blank ON, brightness 15
    sta $2100
    
    ; Muda cor de fundo para azul
    stz $2121           ; CGRAM address = 0
    lda #$E0            ; Azul claro (low byte)
    sta $2122           
    lda #$03            ; Azul claro (high byte) 
    sta $2122
    
    ; Liga a tela
    lda #$0F            ; Force blank OFF, brightness 15
    sta $2100
    
Loop:
    jmp Loop