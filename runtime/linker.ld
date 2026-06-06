/* Define the hardware memory layout blocks */
MEMORY
{
    FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
    RAM   (rwx) : ORIGIN = 0x00010000, LENGTH = 16K
}

/* Set the entry point symbol defined in crt0.s */
ENTRY(_start)

SECTIONS
{
    /* Code and read-only data go straight into Flash memory */
    .text :
    {
        . = ALIGN(4);
        KEEP(*(.vectors))   /* Interrupt/Reset vectors if required by the chip */
        *(.text)            /* Program code instructions */
        *(.text.*)
        *(.rodata)          /* Constant variables, strings */
        *(.rodata.*)
        . = ALIGN(4);
    } > FLASH

    /* Used for tracking load memory addresses for runtime initialized data */
    __data_load = LOADADDR(.data);

    /* Initialized data layout (Lives in Flash, copied into RAM at boot) */
    .data :
    {
        . = ALIGN(4);
        __data_start = .;
        *(.data)
        *(.data.*)
        . = ALIGN(4);
        __data_end = .;
    } > RAM AT > FLASH

    /* Uninitialized variables initialized to zero at boot */
    .bss :
    {
        . = ALIGN(4);
        __bss_start = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > RAM

    /* Set the stack pointer origin directly to the highest address of RAM */
    __stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
