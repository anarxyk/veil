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

idt:
    times 256 dq 0
idt_end:

idtr:
    dw idt_end - idt - 1
    dd idt

interrupt_message db "interrupt BAD - no handler", 0
exception_message db "exception BAD - cpu exception", 0
