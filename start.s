.globl _start
_start:
    mov sp,#0x8000
    bl notmain
hang: b hang

_regSelect:
	cmp r0, #10
	blt asd1
	cmp r0, #20
	blt asd2
	cmp r0, #30
	blt asd3
	mov r0, #0
	bx lr

	asd1:
		ldr r1, =0x20200000
		mov r2, #3
		mul r5, r0, r2
		bx lr

	asd2:
		ldr r1, =0x20200004
		sub r3, r0, #10
		mov r2, #3
		mul r5, r3, r2
		bx lr

	asd3:
		ldr r1, =0x20200008
		sub r3, r0, #20
		mov r2, #3
		mul r5, r3, r2
		bx lr

configurePinOutputOn:

	push {lr}
	bl _regSelect
	ldr r2, [r1]
	mov r3, #7
	lsl r3, r3, r5
	neg r3, r3
	and r3, r3, r2
	mov r4, #1
	lsl r4, r4, r5
	orr r4, r4, r3
	str r4, [r1]

	ldr r1, =0x2020001c
	mov r3, #1
	lsl r3, r3, r0
	str r3, [r1]
	pop {lr}
	bx lr

configurePinOutputOff:

	push {lr}
	bl _regSelect
	ldr r2, [r1]
	mov r3, #7
	lsl r3, r3, r5
	neg r3, r3
	and r3, r3, r2
	mov r4, #1
	lsl r4, r4, r5
	orr r4, r4, r3
	str r4, [r1]

	ldr r1, =0x20200028
	mov r3, #1
	lsl r3, r3, r0
	str r3, [r1]
	pop {lr}
	bx lr

configurePinPullUp:
	ldr r1, =0x20200094
	ldr r2, [r1] 
	orr r2, r2, #2
	str r2, [r1]

	mov r1, #0x100
	lopa:
	sub r1, r1, #1
	cmp r1, #0
	bne lopa

	ldr r1, =0x20200098
	ldr r2, [r1]
	mov r3, #1
	lsl r3, r3, r0
	orr r3, r3, r2
	str r3, [r1]

	mov r1, #0x100
	lopb:
	sub r1, r1, #1
	cmp r1, #0
	bne lopb

	push {lr}
	bl _regSelect
	ldr r2, [r1]
	mov r3, #7
	lsl r3, r3, r5
	neg r3, r3
	and r3, r3, r2

	pop {lr}
	bx lr

turnOnAct:
	ldr r1, =0x20200010
	ldr r2, [r1]
	mov r3, #7
	lsl r3, r3, #21
	neg r3, r3
	orr r3, r3, r2
	str r3, [r1]

	ldr r1, =0x20200020
	ldr r2, [r1]
	mov r3, #1
	lsl r3, r3, #15
	orr r3, r3, r2
	str r3, [r1]
	bx lr

turnOffAct:
	ldr r1, =0x20200010
	ldr r2, [r1]
	mov r3, #7
	lsl r3, r3, #21
	neg r3, r3
	orr r3, r3, r2
	str r3, [r1]

	ldr r1, =0x2020002C
	ldr r2, [r1]
	mov r3, #1
	lsl r3, r3, #15
	orr r3, r3, r2
	str r3, [r1]
	bx lr

checkConnection:
	ldr r1, =0x20200034
	ldr r2, [r1]
	asr r2, r2, r0
	and r0, r2, #1
	bx lr

notmain:
	push {lr}
	mov r0, #17
	bl configurePinPullUp
	tmp:
		mov r0, #17
		bl checkConnection
		cmp r0, #0
		bne off
		mov r0, #23
		bl configurePinOutputOn
		b tmp
	off:
		mov r0, #23
		bl configurePinOutputOff
		b tmp
	
	loop: b loop
	