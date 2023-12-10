.target "f256"

.macro print_string address {
    ldx #<address
    ldy #>address
    jsr console_string_out
}

.section code

start {
    jsr console_clear

    print_string machine

    stz MMU_IO_CTRL
    lda SYS_MID
    jsr print_hex_byte
    cmp #$13
    bcc :+
    lda #0
:   asl
    tax
    lda #$20
    jsr console_char_out
    lda machine_names,x
    ldy machine_names + 1,x
    tax
    jsr console_string_out

loop:
       jmp loop
}

.section data

machine {
    .data "Machine: ", 0
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
