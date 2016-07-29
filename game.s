.globl _start
_start:
    mov sp,#0x8000 //stack init is required
    bl notmain
	b hang

seq:
	.byte	3
	.byte	2
	.byte	1
	.byte	2
	.byte	3
	.byte	0
	.byte	2
	.byte	0
	.text
	.align 2

//could be bytes but shouldnt risk misalignment
expected_idx:
	.word 1
	
seq_count_idx:
	.word 1
	
.align 4
hw_init:
//param void 
//returns void
	bx lr

notmain:
    bl btn_press
	b notmain	

hang: b hang

.thumb
.thumb_func
//my emulator didnt support co processors yet, needed to put this to thumb since
//thumb supports direct byte transfers
btn_press:
    //param button pressed index (r0)
	//returns bool if corresponds next in seq
	ldr r1, =seq
	ldr r2, =seq_count_idx
	ldrb r3, [r2, #0] //better asm for this 2?
	ldrb r1, [r1, r3]
	add r3, #1
	mov r4, #7
	and r3, r4
	strb r3, [r2, #0]
	mov r0, r1
	bx lr




