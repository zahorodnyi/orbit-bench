soa_compute_forces:
	push	r15
	push	r14
	push	rbx
	sub	rsp, 112
	mov	rdx, qword ptr [rdi + 16]
	mov	rax, qword ptr [rdi + 40]
	cmp	rdx, rax
	ja	.LBB1_1
	mov	rax, qword ptr [rdi + 64]
	cmp	rdx, rax
	ja	.LBB1_4
	mov	rax, qword ptr [rdi + 88]
	cmp	rdx, rax
	ja	.LBB1_6
	mov	rax, qword ptr [rdi + 112]
	cmp	rdx, rax
	ja	.LBB1_8
	mov	rax, qword ptr [rdi + 136]
	cmp	rdx, rax
	ja	.LBB1_10
	mov	rax, qword ptr [rdi + 160]
	cmp	rdx, rax
	ja	.LBB1_12
	mov	rax, qword ptr [rdi + 8]
	mov	rcx, qword ptr [rdi + 32]
	mov	r8, qword ptr [rdi + 56]
	mov	r9, qword ptr [rdi + 80]
	mov	r10, qword ptr [rdi + 104]
	mov	r11, qword ptr [rdi + 128]
	mov	rbx, qword ptr [rdi + 152]
	cmp	rdx, 8
	jb	.LBB1_17
	mov	r14, rdx
	shr	r14, 3
	xor	edi, edi
	movaps	xmm8, xmmword ptr [rip + .LCPI1_0]
.LBB1_15:
	lea	rsi, [rdi + 8]
	mov	r15, rdi
	or	r15, 7
	cmp	r15, rdx
	jae	.LBB1_16
	dec	r14
	movups	xmm1, xmmword ptr [rax + 4*rdi]
	movaps	xmmword ptr [rsp + 80], xmm1
	movups	xmm1, xmmword ptr [rax + 4*rdi + 16]
	movaps	xmmword ptr [rsp + 64], xmm1
	movups	xmm1, xmmword ptr [rcx + 4*rdi]
	movaps	xmmword ptr [rsp + 48], xmm1
	movups	xmm1, xmmword ptr [rcx + 4*rdi + 16]
	movaps	xmmword ptr [rsp + 32], xmm1
	movups	xmm0, xmmword ptr [r8 + 4*rdi]
	movaps	xmmword ptr [rsp + 16], xmm0
	movups	xmm0, xmmword ptr [r8 + 4*rdi + 16]
	movaps	xmmword ptr [rsp], xmm0
	xorps	xmm5, xmm5
	xor	r15d, r15d
	xorps	xmm9, xmm9
	xorps	xmm10, xmm10
	xorps	xmm11, xmm11
	xorps	xmm12, xmm12
	xorps	xmm13, xmm13
.LBB1_24:
	movaps	xmmword ptr [rsp + 96], xmm5
	movss	xmm14, dword ptr [rax + 4*r15]
	shufps	xmm14, xmm14, 0
	movaps	xmm1, xmm14
	movss	xmm15, dword ptr [rcx + 4*r15]
	shufps	xmm15, xmm15, 0
	movaps	xmm2, xmm15
	subps	xmm1, xmmword ptr [rsp + 80]
	movss	xmm0, dword ptr [r8 + 4*r15]
	shufps	xmm0, xmm0, 0
	movaps	xmm6, xmm0
	subps	xmm2, xmmword ptr [rsp + 48]
	subps	xmm6, xmmword ptr [rsp + 16]
	movaps	xmm3, xmm1
	mulps	xmm3, xmm1
	addps	xmm3, xmm8
	movaps	xmm4, xmm2
	mulps	xmm4, xmm2
	movaps	xmm5, xmm6
	addps	xmm4, xmm3
	mulps	xmm5, xmm6
	addps	xmm5, xmm4
	movaps	xmm7, xmmword ptr [rip + .LCPI1_1]
	movaps	xmm4, xmm7
	sqrtps	xmm3, xmm5
	divps	xmm4, xmm3
	movaps	xmm3, xmm4
	mulps	xmm3, xmm4
	mulps	xmm3, xmm4
	movss	xmm4, dword ptr [r9 + 4*r15]
	shufps	xmm4, xmm4, 0
	mulps	xmm3, xmm4
	mulps	xmm1, xmm3
	mulps	xmm2, xmm3
	subps	xmm14, xmmword ptr [rsp + 64]
	subps	xmm15, xmmword ptr [rsp + 32]
	mulps	xmm3, xmm6
	movaps	xmm5, xmm14
	mulps	xmm5, xmm14
	movaps	xmm6, xmm15
	addps	xmm5, xmm8
	mulps	xmm6, xmm15
	addps	xmm6, xmm5
	movaps	xmm5, xmmword ptr [rsp + 96]
	subps	xmm0, xmmword ptr [rsp]
	addps	xmm5, xmm1
	movaps	xmm1, xmm0
	mulps	xmm1, xmm0
	addps	xmm1, xmm6
	addps	xmm10, xmm2
	sqrtps	xmm1, xmm1
	divps	xmm7, xmm1
	movaps	xmm1, xmm7
	mulps	xmm1, xmm7
	mulps	xmm1, xmm7
	mulps	xmm1, xmm4
	mulps	xmm14, xmm1
	addps	xmm9, xmm14
	mulps	xmm15, xmm1
	addps	xmm11, xmm15
	addps	xmm12, xmm3
	mulps	xmm1, xmm0
	addps	xmm13, xmm1
	inc	r15
	cmp	rdx, r15
	jne	.LBB1_24
	movups	xmmword ptr [r10 + 4*rdi], xmm5
	movups	xmmword ptr [r10 + 4*rdi + 16], xmm9
	movups	xmmword ptr [r11 + 4*rdi], xmm10
	movups	xmmword ptr [r11 + 4*rdi + 16], xmm11
	movups	xmmword ptr [rbx + 4*rdi], xmm12
	movups	xmmword ptr [rbx + 4*rdi + 16], xmm13
	mov	rdi, rsi
	test	r14, r14
	jne	.LBB1_15
.LBB1_17:
	movabs	rsi, 2305843009213693944
	and	rsi, rdx
	cmp	rsi, rdx
	je	.LBB1_22
	cmp	rdx, 1
	mov	rdi, rdx
	adc	rdi, 0
	movss	xmm0, dword ptr [rip + .LCPI1_2]
	movss	xmm1, dword ptr [rip + .LCPI1_3]
.LBB1_19:
	movss	xmm4, dword ptr [r8 + 4*rsi]
	movss	xmm2, dword ptr [rax + 4*rsi]
	movss	xmm5, dword ptr [rcx + 4*rsi]
	unpcklps	xmm5, xmm2
	xorps	xmm3, xmm3
	xorps	xmm2, xmm2
	xor	r14d, r14d
.LBB1_20:
	movss	xmm6, dword ptr [r8 + 4*r14]
	subss	xmm6, xmm4
	movaps	xmm7, xmm6
	mulss	xmm7, xmm6
	movss	xmm8, dword ptr [rax + 4*r14]
	movss	xmm9, dword ptr [rcx + 4*r14]
	unpcklps	xmm9, xmm8
	subps	xmm9, xmm5
	movaps	xmm8, xmm9
	mulps	xmm8, xmm9
	movaps	xmm10, xmm8
	shufps	xmm10, xmm8, 85
	addss	xmm10, xmm0
	addss	xmm10, xmm8
	addss	xmm10, xmm7
	xorps	xmm7, xmm7
	sqrtss	xmm7, xmm10
	movaps	xmm8, xmm1
	divss	xmm8, xmm7
	movaps	xmm7, xmm8
	mulss	xmm7, xmm8
	mulss	xmm7, xmm8
	mulss	xmm7, dword ptr [r9 + 4*r14]
	inc	r14
	movaps	xmm8, xmm7
	shufps	xmm8, xmm7, 0
	mulps	xmm8, xmm9
	addps	xmm3, xmm8
	mulss	xmm7, xmm6
	addss	xmm2, xmm7
	cmp	rdi, r14
	jne	.LBB1_20
	movaps	xmm4, xmm3
	shufps	xmm4, xmm3, 85
	movss	dword ptr [r10 + 4*rsi], xmm4
	movss	dword ptr [r11 + 4*rsi], xmm3
	movss	dword ptr [rbx + 4*rsi], xmm2
	inc	rsi
	cmp	rsi, rdx
	jb	.LBB1_19
.LBB1_22:
	add	rsp, 112
	pop	rbx
	pop	r14
	pop	r15
	ret
.LBB1_16:
	lea	rcx, [rip + .Lanon.7694ead2345f98dee47a813f5dd44bac.7]
	call	qword ptr [rip + _ZN4core5slice5index16slice_index_fail17hf1918ccaba3e9ba3E@GOTPCREL]
.LBB1_1:
	lea	rcx, [rip + .Lanon.7694ead2345f98dee47a813f5dd44bac.1]
	xor	edi, edi
	mov	rsi, rdx
	mov	rdx, rax
	call	qword ptr [rip + _ZN4core5slice5index16slice_index_fail17hf1918ccaba3e9ba3E@GOTPCREL]
.LBB1_4:
	lea	rcx, [rip + .Lanon.7694ead2345f98dee47a813f5dd44bac.2]
	xor	edi, edi
	mov	rsi, rdx
	mov	rdx, rax
	call	qword ptr [rip + _ZN4core5slice5index16slice_index_fail17hf1918ccaba3e9ba3E@GOTPCREL]
.LBB1_6:
	lea	rcx, [rip + .Lanon.7694ead2345f98dee47a813f5dd44bac.3]
	xor	edi, edi
	mov	rsi, rdx
	mov	rdx, rax
	call	qword ptr [rip + _ZN4core5slice5index16slice_index_fail17hf1918ccaba3e9ba3E@GOTPCREL]
.LBB1_8:
	lea	rcx, [rip + .Lanon.7694ead2345f98dee47a813f5dd44bac.4]
	xor	edi, edi
	mov	rsi, rdx
	mov	rdx, rax
	call	qword ptr [rip + _ZN4core5slice5index16slice_index_fail17hf1918ccaba3e9ba3E@GOTPCREL]
.LBB1_10:
	lea	rcx, [rip + .Lanon.7694ead2345f98dee47a813f5dd44bac.5]
	xor	edi, edi
	mov	rsi, rdx
	mov	rdx, rax
	call	qword ptr [rip + _ZN4core5slice5index16slice_index_fail17hf1918ccaba3e9ba3E@GOTPCREL]
.LBB1_12:
	lea	rcx, [rip + .Lanon.7694ead2345f98dee47a813f5dd44bac.6]
	xor	edi, edi
	mov	rsi, rdx
	mov	rdx, rax
	call	qword ptr [rip + _ZN4core5slice5index16slice_index_fail17hf1918ccaba3e9ba3E@GOTPCREL]
.Lfunc_end1:
	.size	soa_compute_forces, .Lfunc_end1-soa_compute_forces
