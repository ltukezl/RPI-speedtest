.globl _start
    //interupt vector table (IVT), these values are relative jumps.
    ldr pc,reset_handler
    ldr pc,undefined_handler
    ldr pc,swi_handler
    ldr pc,prefetch_handler
    ldr pc,data_handler
    ldr pc,unused_handler
    ldr pc,irq_handler
    ldr pc,fiq_handler
    
//previous IVT jumps to these labels. Since labels are relative we need to copy
//them to addr 0 with our IVT. These labels have value of absolute addresses of our
//IRQ handler
reset_handler:       .word reset_routine
undefined_handler:  .word hang
swi_handler:         .word hang
prefetch_handler:   .word hang
data_handler:        .word hang
unused_handler:     .word hang
irq_handler:         .word irq_routine
fiq_handler:         .word hang

irq_routine:
    b .
    
.align 4

waitCycles:
    //param:   int r0
    //returns: void
    //wait N cycles, changes flags
    wait:
        subs r0, #1
        bne wait
        
    bx lr

hw_init:
    //param:   void 
    //returns: void
    //GPIO 12 and 13 are PWM needed for buzzer and display
    //pins are input by default so we need to specify them as pull up
    push {lr} //push lr to stack since there are nested function calls
    ldr r5, =0x20200000 //gpio base register
    mov r1, #2             //pullup
    str r1, [r5, #0x94]

    //wait period of 150 cycles needed as per doc
    mov r0, #150
    bl waitCycles
    
    //set pins 4, 17, 18, 27 as button input pins
    //give the input pins clock so we can read them.
    ldr r1, =0x8060010
    str r1, [r5, #0x98]
    
    //wait period of 150 cycles needed as per doc
    mov r0, #150
    bl waitCycles
    
    //set pins 22, 23, 24, 25 as button LED pins (output)
    ldr r1, =0x9240
    str r1, [r5, #0x8]
    
    pop {lr} 
    bx lr
    
led_on:
    //param:  gpio number of the output pin (r0)
    //return: void
    ldr r1, =0x20200000 //gpio base register
    mov r2, #1
    lsl r2, r0             //idx of led
    str r2, [r1, #0x1c]   //set register
    bx lr
    
led_off:
    //param:  gpio number of the output pin (r0)
    //return: void
    ldr r1, =0x20200000 //gpio base register
    mov r2, #1
    lsl r2, r0             //idx of led
    str r2, [r1, #0x28]   //set register
    bx lr
    
led_toggle:
    //param:  gpio number of the output pin (r0)
    //return: void
    ldr r1, =0x20200000 //gpio base register
    mov r2, #1
    lsl r2, r0            //idx of led
    ldr r3, [r1, #0x34]
    tst r2, r3            //mask with our shift to see if the pin is high or low
    //both functions take gpio num as r0, it's already there
    //not sure if unsafe none of the opcodes should have sideeffects with flags
    beq led_on          //was low    
    bne led_off         //Was high
    bx lr
    
reset_routine:
    mov r0, #0x08000//000 //for purpose of my emulator, would be linked at 0x8000 on rpi
    mov r1, #0 //location for interrupt vectors
    ldmia r0!, {r2-r9} // load IVT to stack
    stmia r1!, {r2-r9} // store IVT from stack to 0 addr
    ldmia r0!, {r2-r9} // load absolute addresses to stack
    stmia r1!, {r2-r9} // store absolute addresses from stack to 0 addr
    mov sp,#0x8000 //stack init is required
    bl notmain
   
notmain: //not main because assembler might put overhead (dwelch)
    bl hw_init

    mov r0, #22
    bl led_toggle
    
    
hang: b hang
