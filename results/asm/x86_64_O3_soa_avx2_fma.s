soa_compute_forces:
	push	r15
	push	r14
	push	r12
	push	rbx
	sub	rsp, 72
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
	jae	.LBB1_14
.LBB1_17:
	movabs	rsi, 2305843009213693944
	mov	rdi, rdx
	and	rdi, rsi
	cmp	rdi, rdx
	jne	.LBB1_18
.LBB1_24:
	add	rsp, 72
	pop	rbx
	pop	r12
	pop	r14
	pop	r15
	vzeroupper
	ret
.LBB1_14:
	mov	r14, rdx
	shr	r14, 3
	lea	r15, [4*rdx]
	and	r15, -8
	xor	edi, edi
	vbroadcastss	ymm1, dword ptr [rip + .LCPI1_0]
	vbroadcastss	ymm5, dword ptr [rip + .LCPI1_1]
	jmp	.LBB1_15
.LBB1_29:
	vmovups	ymmword ptr [r10 + 4*rdi], ymm2
	vmovups	ymmword ptr [r11 + 4*rdi], ymm3
	vmovups	ymmword ptr [rbx + 4*rdi], ymm4
	mov	rdi, rsi
	test	r14, r14
	je	.LBB1_17
.LBB1_15:
	lea	rsi, [rdi + 8]
	mov	r12, rdi
	or	r12, 7
	cmp	r12, rdx
	jae	.LBB1_16
	dec	r14
	vmovups	ymm6, ymmword ptr [rax + 4*rdi]
	vmovups	ymm15, ymmword ptr [rcx + 4*rdi]
	vmovups	ymm11, ymmword ptr [r8 + 4*rdi]
	vxorps	xmm2, xmm2, xmm2
	xor	r12d, r12d
	vxorps	xmm3, xmm3, xmm3
	vxorps	xmm4, xmm4, xmm4
	vmovups	ymmword ptr [rsp], ymm6
.LBB1_26:
	vbroadcastss	ymm8, dword ptr [rax + r12]
	vsubps	ymm8, ymm8, ymm6
	vbroadcastss	ymm9, dword ptr [rcx + r12]
	vsubps	ymm9, ymm9, ymm15
	vbroadcastss	ymm10, dword ptr [r8 + r12]
	vsubps	ymm10, ymm10, ymm11
	vmovaps	ymm7, ymm11
	vmovaps	ymm11, ymm8
	vfmadd213ps	ymm11, ymm8, ymm1
	vbroadcastss	ymm0, dword ptr [r9 + r12]
	vmovups	ymmword ptr [rsp + 32], ymm0
	vbroadcastss	ymm13, dword ptr [rax + r12 + 4]
	vfmadd231ps	ymm11, ymm9, ymm9
	vsubps	ymm0, ymm13, ymm6
	vbroadcastss	ymm14, dword ptr [rcx + r12 + 4]
	vsubps	ymm14, ymm14, ymm15
	vfmadd231ps	ymm11, ymm10, ymm10
	vmovaps	ymm6, ymm15
	vbroadcastss	ymm15, dword ptr [r8 + r12 + 4]
	vsqrtps	ymm11, ymm11
	vsubps	ymm15, ymm15, ymm7
	vmovaps	ymm13, ymm0
	vdivps	ymm11, ymm5, ymm11
	vfmadd213ps	ymm13, ymm0, ymm1
	vfmadd231ps	ymm13, ymm14, ymm14
	vfmadd231ps	ymm13, ymm15, ymm15
	vmovaps	ymm12, ymm1
	vmulps	ymm1, ymm11, ymm11
	vsqrtps	ymm13, ymm13
	vmulps	ymm1, ymm11, ymm1
	vdivps	ymm11, ymm5, ymm13
	vmulps	ymm1, ymm1, ymmword ptr [rsp + 32]
	vfmadd231ps	ymm2, ymm1, ymm8
	vfmadd231ps	ymm3, ymm1, ymm9
	vmulps	ymm8, ymm11, ymm11
	vfmadd231ps	ymm4, ymm10, ymm1
	vmulps	ymm1, ymm11, ymm8
	vmovaps	ymm11, ymm7
	vbroadcastss	ymm8, dword ptr [r9 + r12 + 4]
	vmulps	ymm1, ymm8, ymm1
	vfmadd231ps	ymm2, ymm1, ymm0
	vfmadd231ps	ymm3, ymm1, ymm14
	vfmadd231ps	ymm4, ymm15, ymm1
	vmovaps	ymm15, ymm6
	vmovups	ymm6, ymmword ptr [rsp]
	vmovaps	ymm1, ymm12
	add	r12, 8
	cmp	r15, r12
	jne	.LBB1_26
	vbroadcastss	ymm7, dword ptr [rip + .LCPI1_1]
	test	dl, 1
	je	.LBB1_29
	vbroadcastss	ymm0, dword ptr [rax + r12]
	vsubps	ymm0, ymm0, ymm6
	vbroadcastss	ymm1, dword ptr [rcx + r12]
	vsubps	ymm1, ymm1, ymm15
	vbroadcastss	ymm6, dword ptr [r8 + r12]
	vsubps	ymm8, ymm6, ymm11
	vmovaps	ymm6, ymm0
	vfmadd213ps	ymm6, ymm0, ymm12
	vfmadd231ps	ymm6, ymm1, ymm1
	vfmadd231ps	ymm6, ymm8, ymm8
	vsqrtps	ymm6, ymm6
	vdivps	ymm6, ymm7, ymm6
	vmulps	ymm7, ymm6, ymm6
	vmulps	ymm6, ymm6, ymm7
	vbroadcastss	ymm7, dword ptr [r9 + r12]
	vmulps	ymm6, ymm7, ymm6
	vfmadd231ps	ymm2, ymm6, ymm0
	vfmadd231ps	ymm3, ymm6, ymm1
	vmovaps	ymm1, ymm12
	vfmadd231ps	ymm4, ymm8, ymm6
	jmp	.LBB1_29
.LBB1_18:
	cmp	rdx, 1
	mov	r14, rdx
	adc	r14, 0
	add	rsi, 6
	and	rsi, r14
	vmovss	xmm0, dword ptr [rip + .LCPI1_0]
	vmovss	xmm1, dword ptr [rip + .LCPI1_1]
	jmp	.LBB1_19
.LBB1_23:
	vmovss	dword ptr [r10 + 4*rdi], xmm4
	vmovss	dword ptr [r11 + 4*rdi], xmm3
	vmovss	dword ptr [rbx + 4*rdi], xmm2
	inc	rdi
	cmp	rdi, rdx
	jae	.LBB1_24
.LBB1_19:
	vmovss	xmm7, dword ptr [rax + 4*rdi]
	vmovss	xmm6, dword ptr [rcx + 4*rdi]
	vmovss	xmm5, dword ptr [r8 + 4*rdi]
	vxorps	xmm2, xmm2, xmm2
	xor	r15d, r15d
	vxorps	xmm3, xmm3, xmm3
	vxorps	xmm4, xmm4, xmm4
	cmp	rdx, 2
	jb	.LBB1_21
.LBB1_20:
	vmovss	xmm8, dword ptr [rax + 4*r15]
	vmovss	xmm9, dword ptr [rax + 4*r15 + 4]
	vsubss	xmm8, xmm8, xmm7
	vmovss	xmm10, dword ptr [rcx + 4*r15]
	vmovss	xmm11, dword ptr [rcx + 4*r15 + 4]
	vsubss	xmm10, xmm10, xmm6
	vmovss	xmm12, dword ptr [r8 + 4*r15]
	vmovss	xmm13, dword ptr [r8 + 4*r15 + 4]
	vsubss	xmm12, xmm12, xmm5
	vmovaps	xmm14, xmm8
	vfmadd213ss	xmm14, xmm8, xmm0
	vfmadd231ss	xmm14, xmm10, xmm10
	vfmadd231ss	xmm14, xmm12, xmm12
	vsqrtss	xmm14, xmm14, xmm14
	vdivss	xmm14, xmm1, xmm14
	vmulss	xmm15, xmm14, xmm14
	vmulss	xmm14, xmm14, xmm15
	vmulss	xmm14, xmm14, dword ptr [r9 + 4*r15]
	vfmadd231ss	xmm4, xmm14, xmm8
	vfmadd231ss	xmm3, xmm14, xmm10
	vfmadd231ss	xmm2, xmm12, xmm14
	vsubss	xmm8, xmm9, xmm7
	vsubss	xmm9, xmm11, xmm6
	vsubss	xmm10, xmm13, xmm5
	vmovaps	xmm11, xmm8
	vfmadd213ss	xmm11, xmm8, xmm0
	vfmadd231ss	xmm11, xmm9, xmm9
	vfmadd231ss	xmm11, xmm10, xmm10
	vsqrtss	xmm11, xmm11, xmm11
	vdivss	xmm11, xmm1, xmm11
	vmulss	xmm12, xmm11, xmm11
	vmulss	xmm11, xmm11, xmm12
	vmulss	xmm11, xmm11, dword ptr [r9 + 4*r15 + 4]
	add	r15, 2
	vfmadd231ss	xmm4, xmm11, xmm8
	vfmadd231ss	xmm3, xmm11, xmm9
	vfmadd231ss	xmm2, xmm10, xmm11
	cmp	rsi, r15
	jne	.LBB1_20
.LBB1_21:
	test	r14b, 1
	je	.LBB1_23
	vmovss	xmm8, dword ptr [rax + 4*r15]
	vsubss	xmm7, xmm8, xmm7
	vmovss	xmm8, dword ptr [rcx + 4*r15]
	vsubss	xmm6, xmm8, xmm6
	vmovss	xmm8, dword ptr [r8 + 4*r15]
	vsubss	xmm5, xmm8, xmm5
	vmovaps	xmm8, xmm7
	vfmadd213ss	xmm8, xmm7, xmm0
	vfmadd231ss	xmm8, xmm6, xmm6
	vfmadd231ss	xmm8, xmm5, xmm5
	vsqrtss	xmm8, xmm8, xmm8
	vdivss	xmm8, xmm1, xmm8
	vmulss	xmm9, xmm8, xmm8
	vmulss	xmm8, xmm8, xmm9
	vmulss	xmm8, xmm8, dword ptr [r9 + 4*r15]
	vfmadd231ss	xmm4, xmm8, xmm7
	vfmadd231ss	xmm3, xmm8, xmm6
	vfmadd231ss	xmm2, xmm5, xmm8
	jmp	.LBB1_23
.LBB1_16:
	lea	rcx, [rip + .Lanon.7694ead2345f98dee47a813f5dd44bac.7]
	vzeroupper
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
