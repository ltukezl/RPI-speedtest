arm-none-eabi-as start.s -o start.o
arm-none-eabi-ld -T memmap.txt start.o -o hello.elf
arm-none-eabi-objdump -D hello.elf > dump.txt
arm-none-eabi-objcopy hello.elf -O binary kernel.img