.target "f256"

.section code

start {
    lda #$6f
    jsr console_set_color
    jsr console_clear

    lda #<event
    sta kernel_args_events_dest
    stz kernel_args_events_dest + 1 ; event is in zero page
    
    stz event
    stz kernel_args_events_pending

event_loop:
    lda kernel_args_events_pending
    bpl event_loop
    
    jsr kernel_NextEvent
    bcs event_loop
    
    jsr print_event
    
    bra event_loop
}  

print_event {
    jsr console_home
    lda #MMU_IO_CTRL_IO_PAGE_REGISTERS
    sta MMU_IO_CTRL
:   lda VKY_RAST_ROW
    bpl :-

    lda #MMU_IO_CTRL_IO_PAGE_TEXT_MATRIX
    sta MMU_IO_CTRL
    lda #$20
    ldx #0
:   sta TEXT_MATRIX,x
    sta TEXT_MATRIX + $100,x
    dex
    bne :-

    print_string raw
    ldx #0
:   lda event,x
    jsr print_hex_byte
    lda #$20
    jsr console_char_out
    inx
    cpx #8
    bcc :-

    jsr console_next_line

    print_string type
    stz tmp
    lda event + kernel_event_type 
    asl
    rol tmp
    asl
    rol tmp
    asl
    rol tmp
    tax
    clc
    lda #>type_names
    adc tmp
    tay
    jsr console_string_out

    jsr console_next_line

    ldx event + kernel_event_type
    cpx #$10
    bcs end
    
    lda type_dumpers,x
    sta dumper
    lda type_dumpers + 1,x
    sta dumper + 1
dumper = dumper_label + 1
dumper_label:
    jsr dump_none    

end:
    rts
}


print_hex_byte {
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

print_signed_hex_byte {
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

.macro print_string address {
    ldx #<address
    ldy #>address
    jsr console_string_out
}

dump_none {
    rts
}

dump_joystick {
    print_string joy0
    lda event + kernel_event_joystick_joy0
    jsr print_joystick

    jsr console_next_line
    print_string joy1
    lda event + kernel_event_joystick_joy1
    jsr print_joystick

    rts
}

print_joystick {
    sta tmp
    and #$0f
    asl
    asl
    clc
    adc #<joystick_dpad
    sta ptr
    lda #0
    adc #>joystick_dpad
    sta ptr + 1

    ldy #0
:   lda (ptr),y
    jsr console_char_out
    iny
    cpy #4
    bne :-

    lda #$20
    jsr console_char_out

    lda tmp
    and #$10
    beq no_1
    lda #$31
    jsr console_char_out
    bra button_2
no_1:
    lda #$20
    jsr console_char_out
button_2:
    lda tmp
    and #$20
    beq no_2
    lda #$32
    jsr console_char_out
    bra button_3
no_2:
    lda #$20
    jsr console_char_out
button_3:
    lda tmp
    and #$40
    beq no_3
    lda #$33
    jsr console_char_out
    bra end
no_3:
    lda #$20
    jsr console_char_out
end:
    rts
}

dump_device {
    rts
}

dump_key {
    print_string keyboard_id
    lda event + kernel_event_key_keyboard
    jsr print_hex_byte

    jsr console_next_line
    print_string key_id
    lda event + kernel_event_key_raw
    jsr print_hex_byte

    jsr console_next_line
    print_string ascii
    lda event + kernel_event_key_ascii
    cmp #$20
    bcc control_char
    lda #$27
    jsr console_char_out
    lda event + kernel_event_key_ascii
    jsr console_char_out
    lda #$27
    jsr console_char_out
    bra next
control_char:
    jsr print_hex_byte
next:
    jsr console_next_line
    print_string flags
    lda event + kernel_event_key_flags
    jsr print_hex_byte
    rts
}

dump_mouse_delta {
    print_string delta_x
    lda event + kernel_event_mouse_delta_x
    jsr print_signed_hex_byte
    print_string delta_y
    lda event + kernel_event_mouse_delta_y
    jsr print_signed_hex_byte
    print_string delta_z
    lda event + kernel_event_mouse_delta_z
    jsr print_signed_hex_byte

    jsr console_next_line
    print_string delta_buttons
    lda event + kernel_event_mouse_delta_buttons
    jsr print_hex_byte

    rts
}

dump_mouse_clicks {
    print_string buttons_inner
    lda event + kernel_event_mouse_clicks_inner
    jsr print_hex_byte

    jsr console_next_line
    print_string buttons_middle
    lda event + kernel_event_mouse_clicks_middle
    jsr print_hex_byte

    jsr console_next_line
    print_string buttons_outer
    lda event + kernel_event_mouse_clicks_outer
    jsr print_hex_byte

    rts
}


.section data

hex_digits {
    .data "0123456789abcdef"
}

flags {
    .data "Flags: ", 0
}

ascii {
    .data "ASCII value: ", 0
}

buttons_inner {
    .data "Innter: ", 0
}

buttons_middle {
    .data "Middle: ", 0
}

buttons_outer {
    .data "Outer: ", 0
}

key_id {
    .data "Raw Key ID: ", 0
}

keyboard_id {
    .data "Keyboard ID: ", 0
}

joy0 {
    .data "Joystick 0: ", 0
}

joy1 {
    .data "Joystick 1: ", 0
}

delta_x {
    .data "X: ", 0
}

delta_y {
    .data ", Y: ", 0
}

delta_z {
    .data ", Z: ", 0
}

delta_buttons {
    .data "Buttons: ", 0
}

raw {
    .data "Raw: ", 0
}

type {
    .data "Type: ", 0
}

type_dumpers {
    .data dump_none, dump_none
    .data dump_joystick
    .data dump_device
    .data dump_key
    .data dump_key
    .data dump_mouse_delta
    .data dump_mouse_clicks
}

joystick_dpad {
    .data "    "
    .data " ▲  "
    .data "  ▼ "
    .data " ▲▼ "
    .data "◀   "
    .data "◀▲  "
    .data "◀ ▼ "
    .data "◀▲▼ "
    .data "   ▶"
    .data " ▲ ▶"
    .data "  ▼▶"
    .data " ▲▼▶"
    .data "◀  ▶"
    .data "◀▲ ▶"
    .data "◀ ▼▶"
    .data "◀▲▼▶"
}

type_names .align $100 {
    ;     "0123456789abcde"
    .data "Type 0         ", 0
    .data "Type 2         ", 0
    .data "Joystick       ", 0
    .data "Device         ", 0
    .data "Key Pressed    ", 0
    .data "Key Released   ", 0
    .data "Mouse Delta    ", 0
    .data "Mouse Clicks   ", 0
    .data "Block Name     ", 0
    .data "Block Size     ", 0
    .data "Block Data     ", 0
    .data "Block Wrote    ", 0
    .data "Block Formatted", 0
    .data "Block Error    ", 0
    .data "FS Size        ", 0
    .data "FS Created     ", 0
    .data "FS Checked     ", 0
    .data "FS Data        ", 0
    .data "FS Wrote       ", 0
    .data "FS Error       ", 0
    .data "File Not Found ", 0
    .data "File Opened    ", 0
    .data "File Data      ", 0
    .data "File Wrote     ", 0
    .data "File EOF       ", 0
    .data "File Closed    ", 0
    .data "File Renamed   ", 0
    .data "File Deleted   ", 0
    .data "File Error     ", 0
    .data "File Seek      ", 0
    .data "Dir Opened     ", 0
    .data "Dir Volume     ", 0
    .data "Dir File       ", 0
    .data "Dir Free       ", 0
    .data "Dir EOF        ", 0
    .data "Dir Closed     ", 0
    .data "Dir Error      ", 0
    .data "Dir Created    ", 0
    .data "Dir Deleted    ", 0
    .data "Net TCP        ", 0
    .data "Net UDP        ", 0
    .data "Timer Expired  ", 0
    .data "Clock Tick     ", 0
}

.section reserved

tmp .reserve 1


.section zero_page

event .reserve 8 ; TODO: use constant

ptr .reserve 2