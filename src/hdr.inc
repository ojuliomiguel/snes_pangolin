; hdr.inc - Header LoROM para SNES

.segment "HDR"
    ; Título (21 bytes)
    .byte "HELLO WORLD SNES     "
    
    ; Mapeamento
    .byte $20       ; LoROM
    
    ; Tipo
    .byte $00       ; ROM only
    
    ; Tamanho ROM
    .byte $08       ; 256KB
    
    ; Tamanho RAM
    .byte $00       ; No RAM
    
    ; País
    .byte $01       ; NTSC
    
    ; Desenvolvedor
    .byte $33
    
    ; Versão
    .byte $00
    
    ; Checksum complement
    .word $0000
    
    ; Checksum
    .word $FFFF
    
    ; Vetores Native Mode (não usados)
    .word 0         ; COP   ($FFE4)
    .word 0         ; BRK   ($FFE6)
    .word 0         ; ABORT ($FFE8)
    .word 0         ; NMI   ($FFEA)
    .word 0         ; RST   ($FFEC)
    .word 0         ; IRQ   ($FFEE)
    
    ; Vetores Emulation Mode
    .word 0         ; COP   ($FFF4)
    .word 0         ; -     ($FFF6)
    .word 0         ; ABORT ($FFF8)
    .word 0         ; NMI   ($FFFA)
    .word RESET     ; RESET ($FFFC)
    .word 0         ; IRQ   ($FFFE)