#!/bin/bash
set -e

# 1. Assemble startup code (include -g for assembly debugging if desired)
/opt/cr16-elf/bin/cr16-elf-as -g crt0.s -o crt0.o

# 2. Compile C application with optimizations AND debugging symbols
/opt/cr16-elf/bin/cr16-elf-gcc -O2 -g -c test_cr16.c -o test_cr16.o

# 3. Link into the final hardware-mapped ELF binary
/opt/cr16-elf/bin/cr16-elf-ld -T linker.ld crt0.o test_cr16.o -o firmware.elf

# 4. Generate the interleaved Source + Assembly disassembly file
/opt/cr16-elf/bin/cr16-elf-objdump -S firmware.elf > firmware.dis

echo "Build successful! Created firmware.elf and firmware.dis"
