.target "f256"

.section code

start {
    jsr console_clear
    ldx #<message
    ldy #>message
    jsr console_string_out

loop:
       jmp loop
}

.section data

message {
    .data "Hello, world!", 0
}
