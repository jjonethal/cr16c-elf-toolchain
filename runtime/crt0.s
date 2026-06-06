    .text
    .align  2
    .global _start

_start:
    /* 1. Disable global interrupts during early initialization */
    di

    /* 2. Initialize the Stack Pointer (sp) */
    /* The GNU CR16 assembler expects the macro notation '(sp)' for 32-bit immediate loads */
    movd    $__stack_top, (sp)

    /* 3. Clear the .bss section (uninitialized global variables) to zero */
    movd    $__bss_start, (r3,r2)       /* Source tracking pointer */
    movd    $__bss_end, (r5,r4)         /* End boundary tracking pointer */
    movw    $0, r0

.L_clear_bss:
    /* Compare the 32-bit pointer pairs */
    cmpd    (r5,r4), (r3,r2)
    beq     .L_copy_data
    
    /* Store byte: clearing memory at address located inside r3_r2 pointer */
    storb   r0, 0(r3,r2)
    addd    $1, (r3,r2)
    br      .L_clear_bss

    /* 4. Copy the .data section from Flash (LMA) to RAM (VMA) */
.L_copy_data:
    movd    $__data_load, (r3,r2)       /* r3_r2 = Load address (Flash source) */
    movd    $__data_start, (r5,r4)      /* r5_r4 = Destination address (RAM) */
    movd    $__data_end, (r7,r6)        /* r7_r6 = End tracking boundary marker */

.L_copy_loop:
    cmpd    (r7,r6), (r5,r4)
    beq     .L_call_main
    
    loadb   0(r3,r2), r0                /* Read 1 byte from Flash */
    storb   r0, 0(r5,r4)                /* Write 1 byte to RAM */
    addd    $1, (r3,r2)
    addd    $1, (r5,r4)
    br      .L_copy_loop

    /* 5. Jump to the C/C++ main application entry point */
.L_call_main:
    bal     (ra), _main

    /* 6. Catch execution loop if main ever returns */
_exit:
    di
.L_park:
    br      .L_park
