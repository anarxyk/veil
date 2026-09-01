bits 32
org 0x10000

start:
    cli
    cld
    call init_timer
    mov edi, 0xb8000 + 160 * 6
    mov esi, idt_label
    call timer_start
    call init_idt
    lidt [idtr]
    sidt [idtr_check]
    call check_idt
    jc idt_bad
    mov edi, 0xb8000 + 160 * 6
    mov esi, idt_label
    call status_ok
    mov edi, 0xb8000 + 160 * 7
    mov esi, kernel_label
    call timer_start
    call status_ok
    mov edi, 0xb8000 + 160 * 8
    mov esi, pic_label
    call timer_start
    call init_pic
    call status_ok
    mov edi, 0xb8000 + 160 * 9
    mov esi, irq_label
    call timer_start
    call status_ok
    call enable_pic
    sti
    jmp hang ;skip fail path after a successful setup
             ;ouu shii it works in ~600ms

idt_bad:
    mov edi, 0xb8000 + 160 * 6
    mov esi, idt_label
    call status_bad
    cli
    jmp hang

hang:
    pause
    hlt
    jmp hang

init_timer:
    mov al, 0x34
    out 0x43, al
    mov ax, 1193
    out 0x40, al
    mov al, ah
    out 0x40, al
    ret

timer_start:
    mov al, 0
    out 0x43, al
    in al, 0x40
    mov ah, al
    in al, 0x40
    xchg al, ah
    mov [timer_value], ax
    ret

timer_elapsed:
    mov al, 0
    out 0x43, al
    in al, 0x40
    mov ah, al
    in al, 0x40
    xchg al, ah
    movzx edx, ax
    movzx eax, word [timer_value]
    sub eax, edx
    ret

status_ok:
    call timer_elapsed
    push eax
    mov byte [color], 0x0a
    call write
    mov esi, ok_text
    call write
    pop eax
    call number
    mov esi, ms_text
    call write
    call newline
    ret

status_bad:
    call timer_elapsed
    push eax
    mov byte [color], 0x0c
    call write
    mov esi, bad_text
    call write
    mov esi, idt_reason
    call write
    mov esi, in_text
    call write
    pop eax
    call number
    mov esi, ms_text
    call write
    ret

check_idt:
    mov ax, [idtr_check]
    cmp ax, [idtr]
    jne .bad
    mov eax, [idtr_check + 2]
    cmp eax, [idtr + 2]
    jne .bad
    clc
    ret
.bad:
    stc
    ret

write:
    cld
.next:
    lodsb
    test al, al
    jz .done
    mov ah, [color]
    stosw
    jmp .next
.done:
    ret

number:
    test eax, eax
    jnz .convert
    mov al, '0'
    mov ah, [color]
    stosw
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
.output:
    pop dx
    mov al, dl
    add al, '0'
    mov ah, [color]
    stosw
    loop .output
    ret

newline:
    ret

timer_value dw 0
timer_ticks dd 0
keyboard_scancode db 0
color db 0x0f
idt_label db "idt 256 entries 32 exceptions", 0
kernel_label db "kernel", 0
pic_label db "pic 32-47", 0
irq_label db "irq 16 handlers", 0
ok_text db " OK in ", 0
bad_text db " BAD - ", 0
idt_reason db "load check failed", 0
in_text db " in ", 0
ms_text db "ms", 0
idtr_check times 6 db 0

%include "asm/kernel/idt.asm"
%include "asm/kernel/pic.asm"
