bits 32

global init_serial
global serial_put

%macro outb 2
    mov dx, %1
    mov al, %2
    out dx, al
%endmacro

init_serial:
    outb 0x3f9, 0
    outb 0x3fb, 0x80
    outb 0x3f8, 3
    outb 0x3f9, 0
    outb 0x3fb, 3
    outb 0x3fa, 0xc7
    outb 0x3fc, 0x0b
    ret

serial_put:
    push eax
    push edx
    mov ah, al
.wait:
    mov dx, 0x3fd
    in al, dx
    test al, 0x20
    jz .wait
    mov al, ah
    mov dx, 0x3f8
    out dx, al
    pop edx
    pop eax
    ret
