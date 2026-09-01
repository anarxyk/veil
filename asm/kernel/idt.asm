bits 32

init_idt:
    mov edi, idt
    mov eax, default_handler
    mov ecx, 256
    mov dx, 0x08

.next:
    mov word [edi], ax
    mov word [edi + 2], dx
    mov byte [edi + 4], 0
    mov byte [edi + 5], 0x8e
    mov edx, eax
    shr edx, 16
    mov word [edi + 6], dx
    mov edx, 0x08
    add edi, 8
    loop .next
    ret

default_handler:
    cli
    mov edi, 0xb8000 + 160 * 8
    mov esi, fault_message
    mov byte [color], 0x0c
    call write
.halt:
    hlt
    jmp .halt

idt:
    times 256 dq 0
idt_end:

idtr:
    dw idt_end - idt - 1
    dd idt

idt_message db "idt OK 256 entries", 0
fault_message db "interrupt received by default handler", 0
