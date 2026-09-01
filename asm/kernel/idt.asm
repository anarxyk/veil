bits 32

init_idt:
    mov edi, idt
    mov eax, default_handler
    mov ecx, 256

.default:
    call set_gate
    add edi, 8
    loop .default

    mov edi, idt
    mov esi, exception_table
    mov ecx, 32

.exceptions:
    mov eax, [esi]
    call set_gate
    add edi, 8
    add esi, 4
    loop .exceptions

    mov edi, idt + 32 * 8
    mov esi, irq_table
    mov ecx, 16

.irqs:
    mov eax, [esi]
    call set_gate
    add edi, 8
    add esi, 4
    loop .irqs
    ret

set_gate:
    mov word [edi], ax
    mov word [edi + 2], 0x08
    mov byte [edi + 4], 0
    mov byte [edi + 5], 0x8e
    mov edx, eax
    shr edx, 16
    mov word [edi + 6], dx
    ret

default_handler:
    cli
    mov edi, 0xb8000 + 160 * 10
    mov esi, interrupt_message
    mov byte [color], 0x0c
    call write
.halt:
    hlt
    jmp .halt

exception_common:
    cli
    mov edi, 0xb8000 + 160 * 10
    mov esi, exception_message
    mov byte [color], 0x0c
    call write
    hlt
    jmp $

irq_common:
    pushad
    mov eax, [esp + 32]
    cmp eax, 40
    jb .master
    mov al, 0x20
    out 0xa0, al
.master:
    mov al, 0x20
    out 0x20, al
    popad
    add esp, 4
    iretd

%macro no_error 1
exception_%1:
    push dword 0
    push dword %1
    jmp exception_common
%endmacro

%macro has_error 1
exception_%1:
    push dword %1
    jmp exception_common
%endmacro

no_error 0
no_error 1
no_error 2
no_error 3
no_error 4
no_error 5
has_error 8
no_error 6
no_error 7
no_error 9
has_error 10
has_error 11
has_error 12
has_error 13
has_error 14
no_error 15
no_error 16
has_error 17
no_error 18
no_error 19
no_error 20
no_error 21
no_error 22
no_error 23
no_error 24
no_error 25
no_error 26
no_error 27
no_error 28
no_error 29
has_error 30
no_error 31

exception_table:
    dd exception_0, exception_1, exception_2, exception_3
    dd exception_4, exception_5, exception_6, exception_7
    dd exception_8, exception_9, exception_10, exception_11
    dd exception_12, exception_13, exception_14, exception_15
    dd exception_16, exception_17, exception_18, exception_19
    dd exception_20, exception_21, exception_22, exception_23
    dd exception_24, exception_25, exception_26, exception_27
    dd exception_28, exception_29, exception_30, exception_31

%macro irq 1
irq_%1:
    push dword 32 + %1
    jmp irq_common
%endmacro

irq_0:
    inc dword [timer_ticks]
    push dword 32
    jmp irq_common

irq_1:
    push eax ;saves original eax cs i forgot to do that
    in al, 0x60
    mov [keyboard_scancode], al
    pop eax ;restores it
    push dword 33
    jmp irq_common
irq 2
irq 3
irq 4
irq 5
irq 6
irq 7
irq 8
irq 9
irq 10
irq 11
irq 12
irq 13
irq 14
irq 15

irq_table:
    dd irq_0, irq_1, irq_2, irq_3
    dd irq_4, irq_5, irq_6, irq_7
    dd irq_8, irq_9, irq_10, irq_11
    dd irq_12, irq_13, irq_14, irq_15

idt:
    times 256 dq 0
idt_end:

idtr:
    dw idt_end - idt - 1
    dd idt

interrupt_message db "interrupt BAD - no handler", 0
exception_message db "exception BAD - cpu exception", 0
