_aos_compute_forces:
	cbz	x1, LBB0_9
	stp	x29, x30, [sp, #-16]!
	mov	x29, sp
	mov	x8, #0
	sub	x9, x0, #64
	mov	w10, #52429
	movk	w10, #15692, lsl #16
	fmov	s0, #1.00000000
	b	LBB0_3
LBB0_2:
	add	x8, x8, #1
	stur	d1, [x11, #28]
	str	s4, [x11, #36]
	cmp	x8, x1
	b.eq	LBB0_8
LBB0_3:
	mov	x12, #0
	add	x11, x0, x8, lsl #6
	ldr	d2, [x11]
	ldr	s3, [x11, #8]
	add	x13, x8, #1
	movi	d1, #0000000000000000
	movi	d4, #0000000000000000
LBB0_4:
	cmp	x12, x1
	csel	x15, x12, x1, hi
	add	x14, x9, x12, lsl #6
LBB0_5:
	cmp	x15, x12
	b.eq	LBB0_2
	add	x12, x12, #1
	add	x14, x14, #64
	cmp	x13, x12
	b.eq	LBB0_5
	ldp	s5, s6, [x14, #8]
	fsub	s5, s5, s3
	fmul	s7, s5, s5
	ldr	d16, [x14]
	fsub.2s	v16, v16, v2
	fmul.2s	v17, v16, v16
	faddp.2s	s17, v17
	fadd	s7, s17, s7
	fmov	s17, w10
	fadd	s7, s7, s17
	fsqrt	s7, s7
	fdiv	s7, s0, s7
	fmul	s6, s6, s7
	fmul	s6, s7, s6
	fmul	s6, s7, s6
	fmul.2s	v7, v16, v6[0]
	fmul	s5, s5, s6
	fadd.2s	v1, v1, v7
	fadd	s4, s4, s5
	b	LBB0_4
LBB0_8:
	ldp	x29, x30, [sp], #16
LBB0_9:
	ret
