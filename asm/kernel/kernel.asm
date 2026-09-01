bits 32
org 0x10000

start:
    mov edi, 0xb8000 + 160 * 6
    mov esi, message
    mov ah, 0x0a

.next:
    lodsb
    test al, al
    jz .halt
    stosw
    jmp .next

.halt:
    cli
.wait:
    hlt
    jmp .wait

message db "kernel OK in 0ms", 0
