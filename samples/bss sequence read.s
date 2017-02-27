.globl _start
    b notmain
    b hang

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
   
notmain: //not main because assembler might put overhead (dwelch)
    bl hw_init

new:    
    ldr r2, =seq_count_idx
    ldrb r3, [r2]
    ldr r1, =seq
    ldrb r4, [r1, r3]
    mov r0, r4

    bl led_on

    mov r1, #0xF00
    asd:
        subs r1, #1
        bne asd
    
    bl led_toggle // shut led 
    
    mov r1, #0xF000
    asd2:
        subs r1, #1
        bne asd2
     
    ldr r1, =seq_count_idx //next led to load
    ldr r0, [r1]
    add r0, #1               //new index
    and r0, #0xF            //we have 15 states so just anding will do fine
    str r0, [r1]
     
    b new    
    
hang: b hang