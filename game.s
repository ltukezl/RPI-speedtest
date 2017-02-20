.globl _start
    //b notmain
    //b hang
_start:
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

seq:
    .byte    25
    .byte    24
    .byte    23
    .byte    24
    .byte    25
    .byte    22
    .byte    24
    .byte    22
    .byte    24
    .byte    25
    .byte    23
    .byte    24
    .byte    22
    .byte    25
    .byte    24
    .byte    23
    .align 2

//could be bytes but shouldnt risk misalignment
.data
expected_idx:
    .word 0

.data //data is neede so .bss gets initialized properly. (cannot access seq properly)
seq_count_idx:
    .word 0
    
.align 4

hw_init:
    //param:   void 
    //returns: void
    //GPIO 12 and 13 are PWM needed for buzzer and display
    //pins are input by default so we need to specify them as pull up
    ldr r0, =0x20200000 //gpio base register
    mov r1, #2             //pullup
    str r1, [r0, #0x94]

    //wait period of 150 cycles needed as per doc
    mov r1, #150
wait1:
    subs r1, #1
    bne wait1
    
    //set pins 4, 17, 18, 27 as button input pins
    //give the input pins clock so we can read them.
    ldr r1, =0x8060010
    str r1, [r0, #0x98]
    
    //wait period of 150 cycles needed as per doc
    mov r1, #150
wait2:
    subs r1, #1
    bne wait2
    
    //set pins 22, 23, 24, 25 as button LED pins (output)
    ldr r1, =0x9240
    str r1, [r0, #0x8]
    
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
    
led_level:
    //param:  gpio number of the output pin (r0)
    //return: int (0 for low, != 0 for high)
    ldr r1, =0x20200000 //gpio base register
    ldr r2, [r1, #0x34]    //load current status of pin levels
    mov r3, #1              
    lsl r3, r0              //shift 1 to correct place
    and r0, r2, r3          //and to see if it's up or down and return it
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

new:    
    ldr r2, =seq_count_idx
    ldrb r3, [r2]
    ldr r1, =seq
    ldrb r4, [r1, r3]
    mov r0, r4

    bl led_on

    mov r1, #0xFFFFFF
    asd:
        subs r1, #1
        bne asd
    
    bl led_toggle // shut led 
    
    mov r1, #0xFFFFFF
    asd2:
        subs r1, #1
        bne asd2
     
    ldr r1, =seq_count_idx //next led to load
    ldr r0, [r1]
    add r0, #1               //new index
    and r0, #0xF            //we have 15 states so just anding will do fine
    str r0, [r1]
     
    b new
    
    mov r0, #22
    bl led_toggle
    
    
hang: b hang


/*
my emulator didnt support co processors yet, needed to put this to thumb since
thumb supports direct byte transfers (wtf arm?)
*/
/*
.thumb
.thumb_func
btn_press:
    //param:   button pressed index (r0)
    //returns: bool if corresponds next in seq
    //todo increment score
    ldr r1, =expected_idx
    ldrb r2, [r1] //arr is 16 bits long so we can use byte load for nice overflow
    ldr r3, =seq
    ldrb r3, [r3, r2]
    
    add r2, #1
    strb r2, [r1] //increment the index to next position
    
    cmp r0, r3 
    beq success //would rather use arm mode for moveq and movne so no need to branch
    bne fail    //also presetting r0 to anything messes with conditional flags when imm offset (because of thumb mode)
success:
    mov r0, #1
    b done
fail:
    mov r0, #0
done:
    bx lr
    .align 4 //align needed for some hard values
*/