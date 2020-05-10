section	.text
	global draw_triangle
	extern memset
	extern swap_vertices

draw_triangle: ; BYTE *image_data, struct BITMAPINFOHEADER *info_header, struct VERTEXDATA (*vertices)[3]
	%define image_data ebp+0x8
	%define info_header ebp+0xc
	%define vertices ebp+0x10
	push ebp
	mov ebp, esp
	push ebx
	push ecx
	push edx
	push esi
	push edi

	mov eax, -1
	; make sure image_data is not null pointer
	mov ebx, [image_data]
	test ebx, ebx
	jz draw_triangle_end
	; make sure info_header is not null pointer
	mov ebx, [info_header]
	test ebx, ebx
	jz draw_triangle_end
	; make sure vertices is not null pointer
	mov ebx, [vertices]
	test ebx, ebx
	jz draw_triangle_end

	; local variables
	; EBP-0x04  EBX \
	; EBP-0x08  ECX  }
	; EBP-0x0c  EDX  } saved registers
	; EBP-0x10  ESI  }
	; EBP-0x14  EDI /
	; EBP-0x44  step
	; EBP-0x48  stride
	; EBP-0x4c  max_y
	; EBP-0x50  min_y
	; EBP-0x64  right
	; EBP-0x78  left
	; EBP-0x84  line_color_step
	sub esp, 70h
	%define step ebp-0x44

	push dword 48 ; sizeof(struct VERTEXSTEP) * 3
	push dword 0
	lea eax, [ebp-44h]
	push eax
	call memset ; memset(step, 0, 48)
	add esp, 12

calc_step0:
	mov eax, [ebx+4] ; *vertices + 0 * 12 + 4
	mov [ebp-50h], eax ; save *vertices[0].posY as min_y
	sub eax, [ebx+12+4] ; *vertices + 1 * 12 + 4
	jz calc_step1
	finit
	push eax         ;
	fild dword [esp] ; load position difference to FPU
	fild dword [ebx] ; *vertices + 0 * 12 + 0 (posX)
	fisub dword [ebx+12] ; *vertices + 1 * 12 + 0 (posX)
	fdiv st0, st1
	fstp dword [step] ; store result in step + 0 * 16 + 0 (x)
	movzx eax, byte [ebx+8] ; *vertices + 0 * 12 + 8 (colR)
	mov [esp], eax
	fild dword [esp]
	movzx eax, byte [ebx+12+8] ; *vertices + 1 * 12 + 8 (colR)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [step+4] ; store result in step + 0 * 16 + 4 (r)
	movzx eax, byte [ebx+9] ; *vertices + 0 * 12 + 9 (colG)
	push eax
	fild dword [esp]
	movzx eax, byte [ebx+12+9] ; *vertices + 1 * 12 + 9 (colG)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [step+8] ; store result in step + 0 * 16 + 8 (g)
	movzx eax, byte [ebx+10] ; *vertices + 0 * 12 + 10 (colB)
	push eax
	fild dword [esp]
	movzx eax, byte [ebx+22] ; *vertices + 1 * 12 + 10 (colB)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [step+12] ; store result in step + 0 * 16 + 12 (b)
	fstp st0
	add esp, 4

calc_step1:
	mov eax, [ebx+4] ; *vertices + 0 * 12 + 4
	mov edx, [ebx+2*12+4] ; *vertices + 2 * 12 + 4
	mov [ebp-4ch], edx ; save *vertices[2].posY as max_y
	sub eax, edx
	jz calc_step2
	push eax         ;
	fild dword [esp] ; load position difference to FPU
	fild dword [ebx] ; *vertices + 0 * 12 + 0 (posX)
	fisub dword [ebx+2*12] ; *vertices + 2 * 12 + 0 (posX)
	fdiv st0, st1
	fstp dword [step+16] ; store result in step + 1 * 16 + 0 (x)
	movzx eax, byte [ebx+8] ; *vertices + 0 * 12 + 8 (colR)
	mov [esp], eax
	fild dword [esp]
	movzx eax, byte [ebx+2*12+8] ; *vertices + 2 * 12 + 8 (colR)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [step+16+4] ; store result in step + 1 * 16 + 4 (r)
	movzx eax, byte [ebx+9] ; *vertices + 0 * 12 + 9 (colG)
	push eax
	fild dword [esp]
	movzx eax, byte [ebx+2*12+9] ; *vertices + 2 * 12 + 9 (colG)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [step+16+8] ; store result in step + 1 * 16 + 8 (g)
	movzx eax, byte [ebx+10] ; *vertices + 0 * 12 + 10 (colB)
	push eax
	fild dword [esp]
	movzx eax, byte [ebx+2*12+10] ; *vertices + 2 * 12 + 10 (colB)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [step+16+12] ; store result in step + 1 * 16 + 12 (b)
	fstp st0
	add esp, 4

calc_step2:
	mov eax, [ebx+12+4] ; *vertices + 1 * 12 + 4
	sub eax, [ebx+2+12+4] ; *vertices + 2 * 12 + 4
	jz calc_minmax_y
	push eax         ;
	fild dword [esp] ; load position difference to FPU
	fild dword [ebx+12] ; *vertices + 1 * 12 + 0 (posX)
	fisub dword [ebx+2*12] ; *vertices + 2 * 12 + 0 (posX)
	fdiv st0, st1
	fstp dword [step+2*16] ; store result in step + 2 * 16 + 0 (x)
	movzx eax, byte [ebx+12+8] ; *vertices + 1 * 12 + 8 (colR)
	mov [esp], eax
	fild dword [esp]
	movzx eax, byte [ebx+2*12+8] ; *vertices + 2 * 12 + 8 (colR)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [step+2*16+4] ; store result in step + 2 * 16 + 4 (r)
	movzx eax, byte [ebx+12+9] ; *vertices + 1 * 12 + 9 (colG)
	push eax
	fild dword [esp]
	movzx eax, byte [ebx+2*12+9] ; *vertices + 2 * 12 + 9 (colG)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [step+2*16+8] ; store result in step + 2 * 16 + 8 (g)
	movzx eax, byte [ebx+12+10] ; *vertices + 1 * 12 + 10 (colB)
	push eax
	fild dword [esp]
	movzx eax, byte [ebx+2*12+10] ; *vertices + 2 * 12 + 10 (colB)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [step+2*16+12] ; store result in step + 2 * 16 + 12 (b)
	fstp st0
	add esp, 4

calc_minmax_y:
	; min_y = max(min_y, 0)
	xor ebx, ebx
	mov eax, [ebp-50h] ; load min_y
	test eax, eax
	cmovl eax, ebx
	mov [ebp-50h], eax ; store min_y

	; max_y = min(max_y, abs(info_header->biHeight) - 1)
	mov ebx, [info_header]
	mov eax, [ebx+8] ; info_header->biHeight
	mov edx, eax ;
	sar edx, 31  ;
	xor eax, edx ;
	sub eax, edx ; get absolute height
	sub eax, 1
	mov edx, [ebp-4ch] ; load max_y
	cmp eax, edx
	cmovl edx, eax
	mov [ebp-4ch], edx ; store max_y

	mov eax, [ebx+4] ; info_header->biWidth
	mov ebx, eax ;
	sar ebx, 31  ;
	xor eax, ebx ;
	sub eax, ebx ; get absolute value of width
	mov ebx, eax ;
	shl eax, 1   ;
	add eax, ebx ; multiply eax by 3
	add eax, 3
	and eax, 0xfffffffc
	mov [ebp-48h], eax

draw_triangle_loop:
	;...

    xor eax, eax ; return 0

draw_triangle_end:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
    mov esp, ebp
	pop ebp
	ret
