bits 32

global keyboard_read

init_keyboard:
    mov byte [key_head], 0
    mov byte [key_tail], 0
    mov byte [keyboard_scancode], 0
    mov byte [key_flags], 0
    mov byte [extended], 0
    ret

keyboard_irq:
    mov [keyboard_scancode], al
    cmp al, 0xe0
    jne .key
    mov byte [extended], 1
    ret
.key:
    mov bl, al
    xor dl, dl
    test bl, 0x80
    jz .press
    mov dl, 1
.press:
    and bl, 0x7f
    call update_modifiers
    call map_key
    mov ah, [extended]
    shl ah, 7
    or bl, ah
    mov byte [extended], 0
    mov [last_ascii], al
    movzx edi, byte [key_head]
    mov eax, edi
    inc al
    and al, 31
    cmp al, [key_tail]
    je .full
    mov [key_head], al
    mov al, [last_ascii]
    mov byte [key_queue + edi * 4], al
    mov byte [key_queue + edi * 4 + 1], bl
    mov byte [key_queue + edi * 4 + 2], dl
    mov al, [key_flags]
    mov byte [key_queue + edi * 4 + 3], al
.full:
    ret

update_modifiers:
    cmp bl, 0x2a
    je .shift
    cmp bl, 0x36
    je .shift
    cmp bl, 0x1d
    je .ctrl
    cmp bl, 0x38
    je .alt
    cmp bl, 0x3a
    je .caps
    ret
.shift:
    test dl, dl
    jnz .clear_shift
    or byte [key_flags], 1
    ret
.clear_shift:
    and byte [key_flags], 0xfe
    ret
.ctrl:
    test dl, dl
    jnz .clear_ctrl
    or byte [key_flags], 2
    ret
.clear_ctrl:
    and byte [key_flags], 0xfd
    ret
.alt:
    test dl, dl
    jnz .clear_alt
    or byte [key_flags], 4
    ret
.clear_alt:
    and byte [key_flags], 0xfb
    ret
.caps:
    test dl, dl
    jnz .done
    xor byte [key_flags], 8
.done:
    ret

map_key:
    xor eax, eax
    cmp bl, 0x1d
    je .done
    cmp bl, 0x2a
    je .done
    cmp bl, 0x36
    je .done
    cmp bl, 0x38
    je .done
    cmp bl, 0x3a
    je .done
    cmp bl, 2
    jb .done
    cmp bl, 0x30
    ja .special
    movzx esi, bl
    sub esi, 2
    mov al, [keymap_normal + esi]
    cmp al, 'a'
    jb .symbol
    cmp al, 'z'
    ja .symbol
    mov ah, [key_flags]
    test ah, 9
    jz .done
    mov al, [keymap_shift + esi]
    ret
.symbol:
    test byte [key_flags], 1
    jz .done
    mov al, [keymap_shift + esi]
    ret
.special:
    cmp bl, 0x31
    je .n
    cmp bl, 0x32
    je .m
    cmp bl, 0x33
    je .comma
    cmp bl, 0x34
    je .period
    cmp bl, 0x35
    je .slash
    cmp bl, 0x39
    je .space
    cmp bl, 0x1c
    je .enter
    cmp bl, 0x0e
    je .backspace
    cmp bl, 0x0f
    je .tab
    ret
.n:
    mov al, 'n'
    jmp .letter
.m:
    mov al, 'm'
    jmp .letter
.comma:
    mov al, ','
    mov ah, '<'
    jmp .punctuation
.period:
    mov al, '.'
    mov ah, '>'
    jmp .punctuation
.slash:
    mov al, '/'
    mov ah, '?'
    jmp .punctuation
.space:
    mov al, ' '
    ret
.enter:
    mov al, 10
    ret
.backspace:
    mov al, 8
    ret
.tab:
    mov al, 9
    ret
.letter:
    test byte [key_flags], 9
    jz .done
    sub al, 32
    ret
.punctuation:
    test byte [key_flags], 1
    jz .normal
    mov al, ah
    ret
.normal:
    ret
.done:
    ret

keyboard_next:
    pushf
    cli
    mov al, [key_tail]
    cmp al, [key_head]
    je .empty
    movzx edi, al
    mov al, [key_queue + edi * 4]
    mov [last_ascii], al
    mov al, [key_queue + edi * 4 + 1]
    mov [last_key], al
    mov al, [key_queue + edi * 4 + 2]
    mov [last_state], al
    mov al, [key_queue + edi * 4 + 3]
    mov [last_flags], al
    inc byte [key_tail]
    and byte [key_tail], 31
    popf
    clc
    mov al, [last_ascii]
    mov ah, [last_state]
    ret
.empty:
    popf
    stc
    ret

keyboard_read:
    push edi
    call keyboard_next
    jc .empty
    mov edi, [esp + 8]
    mov [edi], al
    mov al, [last_key]
    mov [edi + 1], al
    mov al, [last_state]
    mov [edi + 2], al
    mov al, [last_flags]
    mov [edi + 3], al
    pop edi
    mov eax, 1
    ret
.empty:
    pop edi
    xor eax, eax
    ret

key_head db 0
key_tail db 0
keyboard_scancode db 0
key_flags db 0
extended db 0
last_ascii db 0
last_key db 0
last_state db 0
last_flags db 0
key_queue times 128 db 0
;bottom row keymap had two backslash bytes instead of one shifting uppercase letters
keymap_normal db "1234567890-=", 8, 9, "qwertyuiop[]", 10, 0, "asdfghjkl;'", 0, 92, "zxcvb"
keymap_shift db "!@#$%^&*()_+", 8, 9, "QWERTYUIOP{}", 10, 0, "ASDFGHJKL:", 34, 0, "|ZXCVB"
