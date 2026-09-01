#!/usr/bin/env bash

set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
build="$root/build"

mkdir -p "$build"
nasm -f bin "$root/asm/boot/boot.asm" -o "$build/boot.bin"
nasm -f bin "$root/asm/boot/setup.asm" -o "$build/setup.bin"
nasm -f bin "$root/asm/kernel/kernel.asm" -o "$build/kernel.bin"
truncate -s 4096 "$build/setup.bin"
truncate -s 4096 "$build/kernel.bin"
cat "$build/boot.bin" "$build/setup.bin" "$build/kernel.bin" > "$build/veil.img"

exec qemu-system-i386 \
    -display curses \
    -monitor none \
    -drive format=raw,file="$build/veil.img"
