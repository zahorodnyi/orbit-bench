_soa_compute_forces:
	stp	x29, x30, [sp, #-16]!
	mov	x29, sp
	ldr	x2, [x0, #16]
	ldr	x8, [x0, #40]
	cmp	x2, x8
	b.hi	LBB1_19
	ldr	x8, [x0, #64]
	cmp	x2, x8
	b.hi	LBB1_20
	ldr	x8, [x0, #88]
	cmp	x2, x8
	b.hi	LBB1_21
	ldr	x8, [x0, #112]
	cmp	x2, x8
	b.hi	LBB1_22
	ldr	x8, [x0, #136]
	cmp	x2, x8
	b.hi	LBB1_23
	ldr	x8, [x0, #160]
	cmp	x2, x8
	b.hi	LBB1_24
	ldr	x8, [x0, #8]
	ldr	x9, [x0, #32]
	ldr	x10, [x0, #56]
	ldr	x11, [x0, #80]
	ldr	x12, [x0, #104]
	ldr	x13, [x0, #128]
	ldr	x14, [x0, #152]
	cmp	x2, #8
	b.lo	LBB1_12
	mov	x0, #0
	lsr	x15, x2, #3
	mov	w16, #52429
	movk	w16, #15692, lsl #16
	dup.4s	v0, w16
	fmov.4s	v1, #1.00000000
LBB1_8:
	add	x1, x0, #8
	orr	x16, x0, #0x7
	cmp	x16, x2
	b.hs	LBB1_18
	sub	x15, x15, #1
	lsl	x16, x0, #2
	add	x17, x8, x16
	add	x0, x9, x16
	add	x3, x10, x16
	ldp	q2, q3, [x17]
	ldp	q4, q5, [x0]
	ldp	q17, q18, [x3]
	movi.2d	v6, #0000000000000000
	mov	x17, x2
	mov	x0, x11
	mov	x3, x8
	mov	x4, x9
	mov	x5, x10
	movi.2d	v21, #0000000000000000
	movi.2d	v19, #0000000000000000
	movi.2d	v20, #0000000000000000
	movi.2d	v7, #0000000000000000
	movi.2d	v16, #0000000000000000
LBB1_10:
	ld1r.4s	{ v22 }, [x3], #4
	ld1r.4s	{ v23 }, [x4], #4
	fsub.4s	v24, v22, v2
	fsub.4s	v25, v23, v4
	ld1r.4s	{ v26 }, [x5], #4
	mov.16b	v27, v0
	fsub.4s	v28, v26, v17
	fmla.4s	v27, v24, v24
	fmla.4s	v27, v25, v25
	fmla.4s	v27, v28, v28
	fsqrt.4s	v27, v27
	fdiv.4s	v27, v1, v27
	fmul.4s	v29, v27, v27
	fmul.4s	v27, v27, v29
	ld1r.4s	{ v29 }, [x0], #4
	fmul.4s	v27, v29, v27
	fmla.4s	v6, v27, v24
	fsub.4s	v22, v22, v3
	fsub.4s	v23, v23, v5
	fsub.4s	v24, v26, v18
	mov.16b	v26, v0
	fmla.4s	v26, v22, v22
	fmla.4s	v19, v27, v25
	fmla.4s	v26, v23, v23
	fmla.4s	v26, v24, v24
	fsqrt.4s	v25, v26
	fdiv.4s	v25, v1, v25
	fmul.4s	v26, v25, v25
	fmla.4s	v7, v27, v28
	fmul.4s	v25, v25, v26
	fmul.4s	v25, v29, v25
	fmla.4s	v21, v25, v22
	fmla.4s	v20, v25, v23
	fmla.4s	v16, v25, v24
	subs	x17, x17, #1
	b.ne	LBB1_10
	add	x17, x12, x16
	stp	q6, q21, [x17]
	add	x17, x13, x16
	stp	q19, q20, [x17]
	add	x16, x14, x16
	mov	x0, x1
	stp	q7, q16, [x16]
	cbnz	x15, LBB1_8
LBB1_12:
	and	x15, x2, #0x1ffffffffffffff8
	cmp	x15, x2
	b.eq	LBB1_17
	cmp	x2, #1
	csinc	x16, x2, xzr, hi
	mov	w17, #52429
	movk	w17, #15692, lsl #16
	fmov	s0, w17
	fmov	s1, #1.00000000
LBB1_14:
	ldr	s3, [x8, x15, lsl #2]
	ldr	s4, [x9, x15, lsl #2]
	movi	d2, #0000000000000000
	mov	x17, x16
	ldr	s5, [x10, x15, lsl #2]
	mov	x0, x8
	mov	x1, x9
	mov	x3, x10
	mov	x4, x11
	movi	d6, #0000000000000000
	movi	d7, #0000000000000000
LBB1_15:
	ldr	s16, [x0], #4
	fsub	s16, s16, s3
	ldr	s17, [x1], #4
	fsub	s17, s17, s4
	ldr	s18, [x3], #4
	fmadd	s19, s16, s16, s0
	fmadd	s19, s17, s17, s19
	fsub	s18, s18, s5
	fmadd	s19, s18, s18, s19
	fsqrt	s19, s19
	fdiv	s19, s1, s19
	fmul	s20, s19, s19
	ldr	s21, [x4], #4
	fmul	s19, s19, s20
	fmul	s19, s21, s19
	fmadd	s7, s16, s19, s7
	fmadd	s6, s17, s19, s6
	fmadd	s2, s18, s19, s2
	subs	x17, x17, #1
	b.ne	LBB1_15
	str	s7, [x12, x15, lsl #2]
	str	s6, [x13, x15, lsl #2]
	str	s2, [x14, x15, lsl #2]
	add	x15, x15, #1
	cmp	x15, x2
	b.lo	LBB1_14
LBB1_17:
	ldp	x29, x30, [sp], #16
	ret
LBB1_18:
Lloh0:
	adrp	x3, l_anon.7694ead2345f98dee47a813f5dd44bac.7@PAGE
Lloh1:
	add	x3, x3, l_anon.7694ead2345f98dee47a813f5dd44bac.7@PAGEOFF
	bl	__ZN4core5slice5index16slice_index_fail17hadaab6fd6d0d9c6dE
LBB1_19:
Lloh2:
	adrp	x3, l_anon.7694ead2345f98dee47a813f5dd44bac.1@PAGE
Lloh3:
	add	x3, x3, l_anon.7694ead2345f98dee47a813f5dd44bac.1@PAGEOFF
	mov	x0, #0
	mov	x1, x2
	mov	x2, x8
	bl	__ZN4core5slice5index16slice_index_fail17hadaab6fd6d0d9c6dE
LBB1_20:
Lloh4:
	adrp	x3, l_anon.7694ead2345f98dee47a813f5dd44bac.2@PAGE
Lloh5:
	add	x3, x3, l_anon.7694ead2345f98dee47a813f5dd44bac.2@PAGEOFF
	mov	x0, #0
	mov	x1, x2
	mov	x2, x8
	bl	__ZN4core5slice5index16slice_index_fail17hadaab6fd6d0d9c6dE
LBB1_21:
Lloh6:
	adrp	x3, l_anon.7694ead2345f98dee47a813f5dd44bac.3@PAGE
Lloh7:
	add	x3, x3, l_anon.7694ead2345f98dee47a813f5dd44bac.3@PAGEOFF
	mov	x0, #0
	mov	x1, x2
	mov	x2, x8
	bl	__ZN4core5slice5index16slice_index_fail17hadaab6fd6d0d9c6dE
LBB1_22:
Lloh8:
	adrp	x3, l_anon.7694ead2345f98dee47a813f5dd44bac.4@PAGE
Lloh9:
	add	x3, x3, l_anon.7694ead2345f98dee47a813f5dd44bac.4@PAGEOFF
	mov	x0, #0
	mov	x1, x2
	mov	x2, x8
	bl	__ZN4core5slice5index16slice_index_fail17hadaab6fd6d0d9c6dE
LBB1_23:
Lloh10:
	adrp	x3, l_anon.7694ead2345f98dee47a813f5dd44bac.5@PAGE
Lloh11:
	add	x3, x3, l_anon.7694ead2345f98dee47a813f5dd44bac.5@PAGEOFF
	mov	x0, #0
	mov	x1, x2
	mov	x2, x8
	bl	__ZN4core5slice5index16slice_index_fail17hadaab6fd6d0d9c6dE
LBB1_24:
Lloh12:
	adrp	x3, l_anon.7694ead2345f98dee47a813f5dd44bac.6@PAGE
Lloh13:
	add	x3, x3, l_anon.7694ead2345f98dee47a813f5dd44bac.6@PAGEOFF
	mov	x0, #0
	mov	x1, x2
	mov	x2, x8
	bl	__ZN4core5slice5index16slice_index_fail17hadaab6fd6d0d9c6dE
	.loh AdrpAdd	Lloh0, Lloh1
	.loh AdrpAdd	Lloh2, Lloh3
	.loh AdrpAdd	Lloh4, Lloh5
	.loh AdrpAdd	Lloh6, Lloh7
	.loh AdrpAdd	Lloh8, Lloh9
	.loh AdrpAdd	Lloh10, Lloh11
	.loh AdrpAdd	Lloh12, Lloh13
