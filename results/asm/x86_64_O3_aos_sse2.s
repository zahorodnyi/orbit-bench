aos_compute_forces:
	test	rsi, rsi
	je	.LBB0_8
	lea	rax, [rdi - 52]
	xor	ecx, ecx
	movss	xmm0, dword ptr [rip + .LCPI0_0]
	movss	xmm1, dword ptr [rip + .LCPI0_1]
	jmp	.LBB0_2
.LBB0_7:
	movlps	qword ptr [rdx + 28], xmm5
	movss	dword ptr [rdx + 36], xmm4
	cmp	rcx, rsi
	je	.LBB0_8
.LBB0_2:
	mov	r8, rcx
	shl	r8, 6
	lea	rdx, [rdi + r8]
	movsd	xmm2, qword ptr [rdi + r8]
	movss	xmm3, dword ptr [rdi + r8 + 8]
	inc	rcx
	xorps	xmm5, xmm5
	xorps	xmm4, xmm4
	xor	r8d, r8d
.LBB0_3:
	mov	r9, r8
	shl	r9, 6
	add	r9, rax
.LBB0_4:
	cmp	r8, rsi
	jae	.LBB0_7
	inc	r8
	add	r9, 64
	cmp	rcx, r8
	je	.LBB0_4
	movss	xmm6, dword ptr [r9 - 4]
	subss	xmm6, xmm3
	movaps	xmm7, xmm6
	mulss	xmm7, xmm6
	movsd	xmm8, qword ptr [r9 - 12]
	subps	xmm8, xmm2
	movaps	xmm9, xmm8
	mulps	xmm9, xmm8
	movaps	xmm10, xmm9
	shufps	xmm10, xmm9, 85
	addss	xmm10, xmm9
	addss	xmm10, xmm7
	addss	xmm10, xmm0
	xorps	xmm7, xmm7
	sqrtss	xmm7, xmm10
	movaps	xmm9, xmm1
	divss	xmm9, xmm7
	movss	xmm7, dword ptr [r9]
	mulss	xmm7, xmm9
	mulss	xmm7, xmm9
	mulss	xmm7, xmm9
	mulss	xmm6, xmm7
	shufps	xmm7, xmm7, 0
	mulps	xmm7, xmm8
	addps	xmm5, xmm7
	addss	xmm4, xmm6
	jmp	.LBB0_3
.LBB0_8:
	ret
.Lfunc_end0:
	.size	aos_compute_forces, .Lfunc_end0-aos_compute_forces
