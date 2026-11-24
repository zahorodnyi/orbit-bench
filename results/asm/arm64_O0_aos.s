_aos_compute_forces:
	sub	sp, sp, #304
	stp	x28, x27, [sp, #272]
	stp	x29, x30, [sp, #288]
	add	x29, sp, #288
	str	x0, [sp, #88]
	str	x1, [sp, #96]
	mov	x0, #0
	bl	__ZN63_$LT$I$u20$as$u20$core..iter..traits..collect..IntoIterator$GT$9into_iter17h83bf535ad1e28e59E
	str	x0, [sp, #104]
	str	x1, [sp, #112]
	b	LBB29_1
LBB29_1:
	add	x0, sp, #104
	bl	__ZN4core4iter5range101_$LT$impl$u20$core..iter..traits..iterator..Iterator$u20$for$u20$core..ops..range..Range$LT$A$GT$$GT$4next17h697e046df4a93d71E
	str	x0, [sp, #120]
	str	x1, [sp, #128]
	ldr	x8, [sp, #120]
	tbz	w8, #0, LBB29_3
	b	LBB29_2
LBB29_2:
	ldr	x9, [sp, #96]
	ldr	x8, [sp, #128]
	str	x8, [sp, #72]
	subs	x9, x8, x9
	str	x8, [sp, #80]
	b.lo	LBB29_4
	b	LBB29_5
LBB29_3:
	ldp	x29, x30, [sp, #288]
	ldp	x28, x27, [sp, #272]
	add	sp, sp, #304
	ret
LBB29_4:
	ldr	x8, [sp, #88]
	ldr	x9, [sp, #72]
	add	x1, x8, x9, lsl #6
	add	x0, sp, #136
	mov	w8, #64
	mov	x2, x8
	bl	_memcpy
	ldr	x1, [sp, #96]
	movi	d0, #0000000000000000
	stur	s0, [x29, #-76]
	stur	s0, [x29, #-72]
	stur	s0, [x29, #-68]
	ldur	s0, [x29, #-76]
	stur	s0, [x29, #-88]
	ldur	s0, [x29, #-72]
	stur	s0, [x29, #-84]
	ldur	s0, [x29, #-68]
	stur	s0, [x29, #-80]
	mov	x0, #0
	bl	__ZN63_$LT$I$u20$as$u20$core..iter..traits..collect..IntoIterator$GT$9into_iter17h83bf535ad1e28e59E
	stur	x0, [x29, #-64]
	stur	x1, [x29, #-56]
	b	LBB29_6
LBB29_5:
	ldr	x1, [sp, #96]
	ldr	x0, [sp, #80]
	adrp	x2, l_anon.82ca3f2de8b652a5ec458a83adf92652.22@PAGE
	add	x2, x2, l_anon.82ca3f2de8b652a5ec458a83adf92652.22@PAGEOFF
	bl	__ZN4core9panicking18panic_bounds_check17h865e5d10cdb12e28E
LBB29_6:
	sub	x0, x29, #64
	bl	__ZN4core4iter5range101_$LT$impl$u20$core..iter..traits..iterator..Iterator$u20$for$u20$core..ops..range..Range$LT$A$GT$$GT$4next17h697e046df4a93d71E
	stur	x0, [x29, #-48]
	stur	x1, [x29, #-40]
	ldur	x8, [x29, #-48]
	tbz	w8, #0, LBB29_9
	b	LBB29_7
LBB29_7:
	ldr	x8, [sp, #72]
	ldur	x9, [x29, #-40]
	str	x9, [sp, #64]
	subs	x8, x8, x9
	b.ne	LBB29_16
	b	LBB29_8
LBB29_8:
	b	LBB29_6
LBB29_9:
	ldr	x8, [sp, #72]
	ldr	x9, [sp, #96]
	ldur	s0, [x29, #-88]
	str	s0, [sp, #52]
	subs	x9, x8, x9
	str	x8, [sp, #56]
	b.hs	LBB29_11
	b	LBB29_10
LBB29_10:
	ldr	x8, [sp, #72]
	ldr	x9, [sp, #96]
	ldr	s0, [sp, #52]
	ldr	x10, [sp, #88]
	add	x10, x10, x8, lsl #6
	str	s0, [x10, #28]
	ldur	s0, [x29, #-84]
	str	s0, [sp, #36]
	subs	x9, x8, x9
	str	x8, [sp, #40]
	b.lo	LBB29_12
	b	LBB29_13
LBB29_11:
	ldr	x1, [sp, #96]
	ldr	x0, [sp, #56]
	adrp	x2, l_anon.82ca3f2de8b652a5ec458a83adf92652.23@PAGE
	add	x2, x2, l_anon.82ca3f2de8b652a5ec458a83adf92652.23@PAGEOFF
	bl	__ZN4core9panicking18panic_bounds_check17h865e5d10cdb12e28E
LBB29_12:
	ldr	x8, [sp, #72]
	ldr	x9, [sp, #96]
	ldr	s0, [sp, #36]
	ldr	x10, [sp, #88]
	add	x10, x10, x8, lsl #6
	str	s0, [x10, #32]
	ldur	s0, [x29, #-80]
	str	s0, [sp, #20]
	subs	x9, x8, x9
	str	x8, [sp, #24]
	b.lo	LBB29_14
	b	LBB29_15
LBB29_13:
	ldr	x1, [sp, #96]
	ldr	x0, [sp, #40]
	adrp	x2, l_anon.82ca3f2de8b652a5ec458a83adf92652.24@PAGE
	add	x2, x2, l_anon.82ca3f2de8b652a5ec458a83adf92652.24@PAGEOFF
	bl	__ZN4core9panicking18panic_bounds_check17h865e5d10cdb12e28E
LBB29_14:
	ldr	s0, [sp, #20]
	ldr	x8, [sp, #88]
	ldr	x9, [sp, #72]
	add	x8, x8, x9, lsl #6
	str	s0, [x8, #36]
	b	LBB29_1
LBB29_15:
	ldr	x1, [sp, #96]
	ldr	x0, [sp, #24]
	adrp	x2, l_anon.82ca3f2de8b652a5ec458a83adf92652.25@PAGE
	add	x2, x2, l_anon.82ca3f2de8b652a5ec458a83adf92652.25@PAGEOFF
	bl	__ZN4core9panicking18panic_bounds_check17h865e5d10cdb12e28E
LBB29_16:
	ldr	x8, [sp, #64]
	ldr	x9, [sp, #96]
	subs	x9, x8, x9
	str	x8, [sp, #8]
	b.hs	LBB29_18
	b	LBB29_17
LBB29_17:
	ldr	x8, [sp, #88]
	ldr	x9, [sp, #64]
	add	x1, x8, x9, lsl #6
	sub	x8, x29, #28
	add	x0, sp, #136
	bl	__ZN15godbolt_example12pair_gravity17hf39945d8b02dcbe2E
	ldur	s3, [x29, #-28]
	ldur	s2, [x29, #-24]
	ldur	s1, [x29, #-20]
	ldur	s0, [x29, #-88]
	fadd	s0, s0, s3
	stur	s0, [x29, #-88]
	ldur	s0, [x29, #-84]
	fadd	s0, s0, s2
	stur	s0, [x29, #-84]
	ldur	s0, [x29, #-80]
	fadd	s0, s0, s1
	stur	s0, [x29, #-80]
	b	LBB29_8
LBB29_18:
	ldr	x1, [sp, #96]
	ldr	x0, [sp, #8]
	adrp	x2, l_anon.82ca3f2de8b652a5ec458a83adf92652.26@PAGE
	add	x2, x2, l_anon.82ca3f2de8b652a5ec458a83adf92652.26@PAGEOFF
	bl	__ZN4core9panicking18panic_bounds_check17h865e5d10cdb12e28E
