#!/usr/bin/env bash

set -euo pipefail

export PATH="/usr/hla:$PATH"
export hlalib="/usr/hla/hlalib"
export hlainc="/usr/hla/include"

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
build="$root/build"

mkdir -p "$build"
nasm -f bin "$root/asm/boot/boot.asm" -o "$build/boot.bin"
nasm -f bin "$root/asm/boot/setup.asm" -o "$build/setup.bin"
nasm -f elf32 "$root/asm/kernel/kernel.asm" -o "$build/kernel.o"
gcc -m32 -ffreestanding -fno-pie -fno-stack-protector -fno-asynchronous-unwind-tables -fno-builtin -fomit-frame-pointer -c "$root/c/console.c" -o "$build/console.o"
zig_cmd="zig"
if ! command -v zig >/dev/null 2>&1; then
    zig_cmd="$root/tools/zig/zig"
fi
"$zig_cmd" build-obj "$root/zig/input.zig" -target x86-freestanding -O ReleaseSmall -fno-PIE -fno-stack-check -fno-stack-protector -fno-unwind-tables -femit-bin="$build/input.o"
ld -m elf_i386 -T "$root/linker.ld" -o "$build/kernel.elf" "$build/kernel.o" "$build/input.o" "$build/console.o"
objcopy -O binary "$build/kernel.elf" "$build/kernel.bin"
truncate -s 4096 "$build/setup.bin"
truncate -s 16384 "$build/kernel.bin"
cat "$build/boot.bin" "$build/setup.bin" "$build/kernel.bin" > "$build/veil.img"

exec qemu-system-i386 \
    -display curses \
    -monitor none \
    -drive format=raw,file="$build/veil.img"
