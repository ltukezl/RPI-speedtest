b _start
.globl _start

_start:
    mov sp,#0x8000 //stack init is required
    bl notmain
    b hang

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

notmain: //not main because assembler might put overhead
    mov r0, #3
    bl btn_press
    beq .  
sub r0, #1    
b notmain
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




