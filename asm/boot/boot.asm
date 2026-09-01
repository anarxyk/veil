bits 16
org 0x7c00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    mov [boot_drive], dl
    mov si, disk_address_packet
    mov dl, [boot_drive]
    mov ah, 0x42
    int 0x13
    jc halt
    mov dl, [boot_drive]
    jmp 0:0x8000

halt:
    cli
.wait:
    hlt
    jmp .wait

boot_drive db 0

disk_address_packet:
    db 0x10
    db 0
    dw 8
    dw 0
    dw 0x0800
    dq 1

times 510 - ($ - $$) db 0
dw 0xaa55
