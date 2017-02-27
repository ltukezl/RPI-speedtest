.globl _start
    b notmain
    b hang
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
    
    mov r1, #0x100 // alt0 function for gpio12 pin (for pwm enable)
    str r1, [r5, #0x4]
    
    ldr r2, =0x201010a0 //PWM clock base, this is in addendum for whatever reason
    ldr r1, =0x5A000020 // password + shut the clock
    str r1, [r2]    
    busy:
        ldr r1, [r2]
        tst r1, #0x8 //test for busyflag to avoid glitching
        bne busy
        
    ldr r1, =0x5A0FF000 //use divisor of 0xFF (to what base freq? not documented?)
    str r1, [r2, #0x4]
    
    ldr r1, =0x5A000011 //enable clock
    str r1, [r2]
    
    ldr r2, =0x2020C000 //PWM base register. Why this is in errata :(
    mov r1, #100 //amount of ticks (period)
    str r1, [r2, #0x10]

    mov r1, #50  //amount of ticks keeping signal up (duty cycle)
    str r1, [r2, #0x14]

    mov r1, #0x81 //enable pwm (bit 0) m/s mode
    str r1, [r2]
    
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
    
   
notmain: //not main because assembler might put overhead (dwelch)
    bl hw_init   
    mov r0, #22
    bl led_toggle
    
    
hang: b hang
