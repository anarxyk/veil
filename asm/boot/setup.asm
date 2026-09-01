bits 16
org 0x8000

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    mov [boot_drive], dl
    mov ax, 3
    int 0x10
    mov ax, 0xb800
    mov es, ax
    mov si, real_mode_label
    call start_timer
    call status_ok
    mov si, disk_label
    call start_timer
    push si
    call load_kernel
    pop si
    jc disk_bad
    call status_ok
    jmp a20_step

disk_bad:
    mov di, disk_reason
    call status_bad
    jmp halt

a20_step:
    mov si, a20_label
    call start_timer
    call enable_a20
    call check_a20
    jc a20_bad
    call status_ok
    jmp gdt_step

a20_bad:
    mov di, a20_reason
    call status_bad
    jmp halt

gdt_step:
    mov si, gdt_label
    call start_timer
    lgdt [gdt_descriptor]
    call status_ok
    mov si, protected_label
    call start_timer
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:protected_mode

load_kernel:
    mov si, disk_address_packet
    mov dl, [boot_drive]
    mov ah, 0x42
    int 0x13
    ret

enable_a20:
    in al, 0x92
    or al, 2
    and al, 0xfe
    out 0x92, al
    ret

check_a20:
    push ds
    push es
    push si
    push di
    cli
    xor ax, ax
    mov ds, ax
    mov si, 0x0500
    mov ax, 0xffff
    mov es, ax
    mov di, 0x0510
    mov ax, [ds:si]
    push ax
    mov bx, [es:di]
    push bx
    mov word [ds:si], 0x1234
    mov word [es:di], 0x5678
    cmp word [ds:si], 0x1234
    pop bx
    pop ax
    mov [es:di], bx
    mov [ds:si], ax
    pop di
    pop si
    pop es
    pop ds
    jne .bad
    clc
    ret
.bad:
    stc
    ret

start_timer:
    xor ah, ah
    int 0x1a
    movzx eax, dx
    movzx edx, cx
    shl edx, 16
    or eax, edx
    mov [start_ticks], eax
    ret

elapsed:
    xor ah, ah
    int 0x1a
    movzx eax, dx
    movzx edx, cx
    shl edx, 16
    or eax, edx
    sub eax, [start_ticks]
    mov ebx, 55
    mul ebx
    ret

status_ok:
    call elapsed
    push eax
    mov byte [color], 0x0a
    call put_string
    mov si, ok_text
    call put_string
    pop eax
    call print_number
    mov si, ms_text
    call put_string
    call newline
    ret

status_bad:
    mov [reason], di
    call elapsed
    push eax
    mov byte [color], 0x0c
    call put_string
    mov si, bad_text
    call put_string
    mov si, [reason]
    call put_string
    mov si, in_text
    call put_string
    pop eax
    call print_number
    mov si, ms_text
    call put_string
    call newline
    ret

put_string:
.next:
    lodsb
    test al, al
    jz .done
    call put_char
    jmp .next
.done:
    ret

put_char:
    mov di, [cursor]
    mov ah, [color]
    mov [es:di], ax
    add di, 2
    mov [cursor], di
    ret

newline:
    mov ax, [cursor]
    add ax, 160
    xor dx, dx
    mov bx, 160
    div bx
    mul bx
    mov [cursor], ax
    ret

print_number:
    test eax, eax
    jnz .convert
    mov al, '0'
    call put_char
    ret
.convert:
    xor ecx, ecx
    mov ebx, 10
.divide:
    xor edx, edx
    div ebx
    push dx
    inc ecx
    test eax, eax
    jnz .divide
.write:
    pop dx
    mov al, dl
    add al, '0'
    call put_char
    loop .write
    ret

bits 32

protected_mode:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000
    mov edi, 0xb8000 + 160 * 4
    mov esi, protected_label_32
    mov ah, 0x0a
    call put_string_32
    mov edi, 0xb8000 + 160 * 5
    mov esi, stack_label_32
    call put_string_32
    jmp 0x10000

put_string_32:
.next:
    lodsb
    test al, al
    jz .done
    stosw
    jmp .next
.done:
    ret

bits 16

halt:
    cli
.wait:
    hlt
    jmp .wait

boot_drive db 0
color db 0x0f
cursor dw 0
reason dw 0
start_ticks dd 0
real_mode_label db "real mode", 0
disk_label db "kernel load", 0
a20_label db "a20", 0
gdt_label db "gdt", 0
protected_label db "protected mode", 0
protected_label_32 db "protected mode OK in 0ms", 0
stack_label_32 db "stack OK in 0ms", 0
disk_reason db "disk read failed", 0
a20_reason db "gate did not open", 0
ok_text db " OK in ", 0
bad_text db " BAD - ", 0
in_text db " in ", 0
ms_text db "ms", 0

disk_address_packet:
    db 0x10
    db 0
    dw 8
    dw 0
    dw 0x1000
    dq 9

gdt:
    dq 0
    dw 0xffff, 0
    db 0, 0x9a, 0xcf, 0
    dw 0xffff, 0
    db 0, 0x92, 0xcf, 0
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt - 1
    dd gdt
