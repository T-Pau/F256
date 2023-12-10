.section code

.public print_hex_byte {
    phx
    sta tmp
    lsr
    lsr
    lsr
    lsr
    tax
    lda hex_digits,x
    jsr console_char_out
    lda tmp
    and #$f
    tax
    lda hex_digits,x
    jsr console_char_out
    lda tmp
    plx
    rts
}


.public print_signed_hex_byte {
    pha
    sta tmp
    bpl positive
    lda #$2d
    jsr console_char_out
    lda tmp
    eor #$ff
    clc
    adc #1
    bra both
positive:
    lda #$20
    jsr console_char_out
    lda tmp
both:
    jsr print_hex_byte
    pla
    rts
}


.section data

hex_digits {
    .data "0123456789abcdef"
}


.section reserved

tmp .reserve 1
