.globl _start
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
    .byte    3
    .byte    2
    .byte    1
    .byte    2
    .byte    3
    .byte    0
    .byte    2
    .byte    0
    .byte    2
    .byte    3
    .byte    1
    .byte    2
    .byte    0
    .byte    3
    .byte    2
    .byte    1
    .text
    .align 2

//could be bytes but shouldnt risk misalignment
expected_idx:
    .word 0
    
seq_count_idx:
    .word 0
    
.align 4
hw_init:
    //param:   void 
    //returns: void
    //GPIO 12 and 13 are PWM needed for buzzer and display
    //set pins 11, 15, 16, 18 as button input pins
    //pins are input by default so we need to specify them as pull up
    ldr r0, =0x20200000 //gpio base register
    mov r1, #2             //pullup
    strb r1, [r0, #0x94]

    //wait period of 150 cycles needed as per doc
    mov r1, #150
wait1:
    subs r1, #1
    bne wait1
    
    //give the input pins clock so we can read them.
    ldr r1, =0x58800
    str r1, [r0, #0x98]
    
    //wait period of 150 cycles needed as per doc
    mov r1, #150
wait2:
    subs r1, #1
    bne wait2
    
    bx lr

    
reset_routine:
    mov sp,#0x8000 //stack init is required
    mov r0, #0x08000000 //for purpose of my emulator, would be linked at 0x8000 on rpi
    mov r1, #0 //location for interrupt vectors
    ldmia r0!, {r2-r9} // load IVT to stack
    stmia r1!, {r2-r9} // store IVT from stack to 0 addr
    ldmia r0!, {r2-r9} // load absolute addresses to stack
    stmia r1!, {r2-r9} // store absolute addresses from stack to 0 addr
    bl notmain
    b hang
    
notmain: //not main because assembler might put overhead
    bl hw_init
    mov r0, #3 //btn test
game_loop:
    bl btn_press
    beq .  
sub r0, #1    
b game_loop
hang: b hang

.thumb
.thumb_func
/*
my emulator didnt support co processors yet, needed to put this to thumb since
thumb supports direct byte transfers (wtf arm?)
*/
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
    bne fail    //also presetting r0 to anything messes with with conditional flags when imm offset
success:
    mov r0, #1
    b done
fail:
    mov r0, #0
done:
    bx lr




