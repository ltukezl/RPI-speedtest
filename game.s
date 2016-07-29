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
//param void 
//returns void
    bx lr

notmain:
    mov r0, #3
    bl btn_press
    b .    

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
    ldr r1, =expected_idx
    ldrb r2, [r1] //arr is 16 bits long so we can use byte load for nice overflow
    ldr r3, =seq
    ldrb r3, [r3, r2]
    
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




