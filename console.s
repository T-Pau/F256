.section code

COLUMNS = 80
ROWS = 60

.public console_set_color {
    sta text_color
    rts
}

.public console_home {
    pha
    stz screen_x
    stz screen_y
    stz screen_ptr
    lda #>TEXT_MATRIX
    sta screen_ptr + 1
    pla
    rts
}

.public console_clear {
    jsr console_home
    pha
    phx
    phy
    lda MMU_IO_CTRL
    pha

    lda #MMU_IO_CTRL_IO_PAGE_TEXT_MATRIX
    sta MMU_IO_CTRL
    lda #$20
    jsr fill_screen

    lda #MMU_IO_CTRL_IO_PAGE_COLOR_MATRIX
    sta MMU_IO_CTRL
    lda text_color
    jsr fill_screen

    pla
    sta MMU_IO_CTRL
    ply
    plx
    pla
    rts
}

.public console_next_line {
    pha
    stz screen_x
    inc screen_y
    clc
    lda #COLUMNS
    adc screen_ptr
    sta screen_ptr
    bcc :+
    inc screen_ptr + 1
:   pla
    rts
}

.public console_string_out {
    stx ptr
    sty ptr + 1
    pha
    phy

    ldy #0
:   lda (ptr),y
    beq end
    jsr console_char_out
    iny
    bne :-

end:
    ply
    pla
    rts
}

.public console_char_out {
    phy
    pha
    ldy MMU_IO_CTRL
    phy

    ldy #MMU_IO_CTRL_IO_PAGE_TEXT_MATRIX
    sty MMU_IO_CTRL
    ldy screen_x
    sta (screen_ptr),y
    lda #MMU_IO_CTRL_IO_PAGE_COLOR_MATRIX
    sta MMU_IO_CTRL
    lda text_color
    sta (screen_ptr),y
    iny
    cpy #COLUMNS
    bcc :+
    inc screen_y
    clc
    ldy #0
    lda screen_ptr
    adc #COLUMNS
    sta screen_ptr
    bcc :+
    inc screen_ptr + 1
:   sty screen_x

    pla
    sta MMU_IO_CTRL
    pla
    ply
    rts
}

.public console_goto {
    stx screen_x
    sty screen_y
    jmp calculate_ptr
}

.public console_goto_column {
    stx screen_x
    rts
}

.public console_goto_line {
    stz screen_x
    sty screen_y
    jmp calculate_ptr
}

calculate_ptr {
    pha
    stz MATH_MULU_A_H
    lda screen_y
    sta MATH_MULU_A_L
    stz MATH_MULU_B_H
    lda #COLUMNS
    sta MATH_MULU_B_L
    lda MATH_MULU_LL
    sta screen_ptr
    lda MATH_MULU_LH
    ora #>TEXT_MATRIX
    sta screen_ptr + 1
    pla
    rts
}

fill_screen {
    ldy #0
    ldx #>(COLUMNS * ROWS)

:   sta (screen_ptr),y
    iny
    bne :-
    inc screen_ptr + 1
    dex
    bpl :-
    lda #>TEXT_MATRIX
    sta screen_ptr + 1
    rts
}

.public console_integer_out {
    pha
    phx
    phy
    lda MMU_IO_CTRL
    pha

    stz MMU_IO_CTRL

    stx MATH_DIVU_NUM_L
    sty MATH_DIVU_NUM_H
    stz MATH_DIVU_DEN_H
    lda #10
    sta MATH_DIVU_DEN_L

    ldx #0
:   lda MATH_REMU_HL
    sta buf,x
    lda MATH_QUOU_LL
    tay
    ora MATH_QUOU_LH
    beq output
    lda MATH_QUOU_LH
    sty MATH_DIVU_NUM_L
    sta MATH_DIVU_NUM_H
    inx
    bra :-

output:
    lda buf,x
    ora #$30
    jsr console_char_out
    dex
    bpl output

    pla
    sta MMU_IO_CTRL
    ply
    plx
    pla
    rts
}

.section data

text_color {
    .data $10
}

.section zero_page

screen_ptr .reserve 2 ; pointer to beginning of current line in text/color matrix
ptr .reserve 2 ; temporary pointer

.section reserved

screen_x .reserve 1 ; current x position
screen_y .reserve 1 ; current y position

buf .reserve 5 ; for converting to decimal