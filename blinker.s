.globl _start
_start:
    mov sp,#0x8000
    bl notmain
	b hang

notmain:
	ldr r0, =0x20200004
	ldr r2, [r0] 
	mov r1, #7 
	lsl r1, r1, #24 
	neg r1, r1 
	and r2, r2, r1
	mov r1, #1
	lsl r1, r1, #24
	orr r2, r2, r1
	str r2, [r0]

	ldr r0, =0x2020001c
	mov r2, #1
	lsl r2, r2, #18
	str r2, [r0]

	mov r3, #0x1000000
lopa:
	sub r3, r3, #1
	cmp r3, #0
	bne lopa

	ldr r0, =0x20200028
	mov r2, #1
	lsl r2, r2, #18
	str r2, [r0]

	mov r3, #0x1000000
lopb:
	sub r3, r3, #1
	cmp r3, #0
	bne lopb

	b notmain

hang: b hang

