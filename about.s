.target "f256"

.macro print_string address {
    ldx #<address
    ldy #>address
    jsr console_string_out
}

BLOCK_START = $8000

BLOCK_SIZE = 8 * 1024

FIRST_BLOCK      =  $80000 / BLOCK_SIZE
END_FLASH_BLOCK = $100000 / BLOCK_SIZE
END_BLOCK       = $140000 / BLOCK_SIZE
BLOCK_BANK = BLOCK_START / BLOCK_SIZE

.section code

start {
    jsr console_clear

    lda #MMU_IO_CTRL_IO_PAGE_REGISTERS
    sta MMU_IO_CTRL

    print_string machine_id
    lda SYS_MID
    jsr print_hex_byte
    jsr console_next_line
    print_string machine
    cmp #$13
    bcc :+
    lda #0
:   asl
    tax
    lda machine_names,x
    ldy machine_names + 1,x
    tax
    jsr console_string_out
    jsr console_next_line

    print_string pcb
    lda SYS_PCBID0
    jsr console_char_out
    lda SYS_PCBID1
    jsr console_char_out
    lda #$20
    jsr console_char_out
    lda SYS_PCBMA
    jsr console_char_out
    lda SYS_PCBMI
    jsr console_char_out
    lda #$20
    jsr console_char_out
    lda #$32
    jsr console_char_out
    lda #$30
    jsr console_char_out
    lda SYS_PCBY
    jsr print_hex_byte
    lda #$2d
    jsr console_char_out
    lda SYS_PCBM
    jsr print_hex_byte
    lda #$2d
    jsr console_char_out
    lda SYS_PCBD
    jsr print_hex_byte
    jsr console_next_line

    print_string tinyvicky
    ldy SYS_CHN1
    ldx SYS_CHN0
    jsr console_integer_out
    lda #$2e
    jsr console_char_out
    ldy SYS_CHV1
    ldx SYS_CHV0
    jsr console_integer_out
    lda #$2e
    jsr console_char_out
    ldy SYS_CHSV1
    ldx SYS_CHSV0
    jsr console_integer_out
    jsr console_next_line

    lda MMU_MEM
    ora #$80
    sta MMU_MEM

    print_string expansion
    lda #$100000 / BLOCK_SIZE
    sta MMU_MEM_BANK + BLOCK_BANK

    lda BLOCK_START
    tax
    eor #$ff
    sta BLOCK_START
    cmp BLOCK_START
    stx BLOCK_START
    bne not_ram
    ldx #<expansion_ram
    ldy #>expansion_ram
    lda #END_BLOCK
    bra expansion_print
not_ram:
    ldx #0
:   lda BLOCK_START,x
    cmp #$80
    bne not_empty
    inx
    bne :-
    ldx #<empty
    ldy #>empty
    lda #END_FLASH_BLOCK
    bra expansion_print
not_empty:
    ldx #<expansion_rom
    ldy #>expansion_rom
    lda #END_BLOCK
expansion_print:
    sta end_block
    jsr console_string_out
    jsr console_next_line

kups:
    jsr console_next_line
    print_string kups_title
    jsr console_next_line
    print_string kups_header
    jsr console_next_line

    stz empty_blocks
    ldx #FIRST_BLOCK
:   jsr list_kup
    cpx end_block
    bcc :-
    jsr print_empty_blocks

;    ldx #0
;:   lda BLOCK_START,x
;    jsr print_hex_byte
;    inx
;    bne :-

loop:
       jmp loop
}

list_kup {
    stx MMU_MEM_BANK + BLOCK_BANK
    lda BLOCK_START
    cmp #$F2
    bne empty
    lda BLOCK_START + 1
    cmp #$56
    bne empty

    jsr print_empty_blocks
    lda #$20
    jsr console_char_out
    lda #$24
    jsr console_char_out
    txa
    jsr print_hex_byte
    lda #$20
    jsr console_char_out
    ldx #7
    jsr console_goto_column
    ldx BLOCK_START + 2
    ldy #0
    jsr console_integer_out
    ldx #11
    jsr console_goto_column
    lda #$24
    jsr console_char_out
    lda BLOCK_START + 3
    asl
    asl
    asl
    asl
    asl
    jsr print_hex_byte
    lda #$30
    jsr console_char_out
    jsr console_char_out
    lda #$20
    jsr console_char_out
    lda #$24
    jsr console_char_out
    lda BLOCK_START + 5
    jsr print_hex_byte
    lda BLOCK_START + 4
    jsr print_hex_byte
    lda #$20
    jsr console_char_out
    ldx #10
    ldy #>BLOCK_START
    jsr console_string_out
    jsr console_next_line
    clc
    lda MMU_MEM_BANK + BLOCK_BANK
    adc BLOCK_START + 2
    tax
    rts

empty:
    inc empty_blocks
    inx
    rts
}

print_empty_blocks {
    lda empty_blocks
    beq end
    phx

    lda #$20
    jsr console_char_out
    lda #$24
    jsr console_char_out
    txa
    sec
    sbc empty_blocks
    jsr print_hex_byte
    ldx #7
    jsr console_goto_column
    ldx empty_blocks
    ldy #0
    jsr console_integer_out
    jsr console_next_line

    stz empty_blocks
    plx
end:
    rts
}

.section data

kups_title {
    .data "Kernel User Programs:", 0
}
kups_header {
    .data "Block Size Start Entry Name", 0
}
pcb {
    .data "PCB:        ", 0
}
tinyvicky {
    .data "TinyVicky:  ", 0
}
machine_id {
    .data "Machine ID: $", 0
}
machine {
    .data "Machine:    ", 0
}
expansion {
    .data "Expansion:  ", 0
}
expansion_ram {
    .data "RAM", 0
}
expansion_rom {
    .data "ROM", 0
}
empty {
    .data "empty", 0
}
machine_names {
    .data machine_0, machine_1, machine_2, machine_3
    .data machine_4, machine_5, machine_unknown, machine_unknown
    .data machine_8, machine_9, machine_a, machine_b
    .data machine_unknown, machine_unknown, machine_unknown, machine_unknown
    .data machine_unknown, machine_unknown, machine_12
}

machine_0 {
    .data "C256 FMX", 0
}
machine_1 {
    .data "C256 U", 0
}
machine_2 {
    .data "F256", 0
}
machine_3 {
    .data "A2560 Dev", 0
}
machine_4 {
    .data "Gen X", 0
}
machine_5 {
    .data "C256 U+", 0
}
machine_8 {
    .data "A2560 X", 0
}
machine_9 {
    .data "A2560 U", 0
}
machine_a {
    .data "A2560 M", 0
}
machine_b {
    .data "A2560 K", 0
}
machine_12 {
    .data "F256k", 0
}
machine_unknown {
    .data "unknown", 0
}

.section reserved

empty_blocks .reserve 1
end_block .reserve 1