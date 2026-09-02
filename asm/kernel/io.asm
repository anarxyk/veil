bits 32

global inb
global inw
global inl
global outb
global outw
global outl
global io_wait
global insb
global outsb
global mmio_read8
global mmio_read16
global mmio_read32
global mmio_write8
global mmio_write16
global mmio_write32
global memory_barrier
global irq_save
global irq_restore

inb:
    mov edx, [esp + 4]
    xor eax, eax
    in al, dx
    ret

inw:
    mov edx, [esp + 4]
    xor eax, eax
    in ax, dx
    ret

inl:
    mov edx, [esp + 4]
    in eax, dx
    ret

outb:
    mov edx, [esp + 4]
    mov eax, [esp + 8]
    out dx, al
    ret

outw:
    mov edx, [esp + 4]
    mov eax, [esp + 8]
    out dx, ax
    ret

outl:
    mov edx, [esp + 4]
    mov eax, [esp + 8]
    out dx, eax
    ret

io_wait:
    xor eax, eax
    out 0x80, al
    ret

insb:
    push edi
    mov edx, [esp + 8]
    mov edi, [esp + 12]
    mov ecx, [esp + 16]
    cld
    rep insb
    pop edi
    ret

outsb:
    push esi
    mov edx, [esp + 8]
    mov esi, [esp + 12]
    mov ecx, [esp + 16]
    cld
    rep outsb
    pop esi
    ret

mmio_read8:
    mov edx, [esp + 4]
    xor eax, eax
    mov al, [edx]
    ret

mmio_read16:
    mov edx, [esp + 4]
    xor eax, eax
    mov ax, [edx]
    ret

mmio_read32:
    mov edx, [esp + 4]
    mov eax, [edx]
    ret

mmio_write8:
    mov edx, [esp + 4]
    mov eax, [esp + 8]
    mov [edx], al
    ret

mmio_write16:
    mov edx, [esp + 4]
    mov eax, [esp + 8]
    mov [edx], ax
    ret

mmio_write32:
    mov edx, [esp + 4]
    mov eax, [esp + 8]
    mov [edx], eax
    ret

memory_barrier:
    lock or dword [esp], 0
    ret

irq_save:
    pushfd
    pop eax
    cli
    ret

irq_restore:
    push dword [esp + 4]
    popfd
    ret
