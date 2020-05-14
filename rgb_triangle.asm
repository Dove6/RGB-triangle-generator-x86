section	.text
	global draw_triangle
	extern memset
	extern swap_vertices

draw_triangle:
	; function arguments
	;  BYTE *image_data
	%define image_data ebp+0x8
	;  struct BITMAPINFOHEADER *info_header
	%define info_header ebp+0xc
	;  struct VERTEXDATA (*vertices)[3]
	%define vertices ebp+0x10

	; stack layout
	;  ebp-0x30  vertical_step - vertical linear interpolation step for three sides of a triangle
	;    ebp-0x30  vertical_step[0].x (float dword)
	;    ebp-0x2c  vertical_step[0].r (float dword)
	;    ebp-0x28  vertical_step[0].g (float dword)
	;    ebp-0x24  vertical_step[0].b (float dword)
	;    ebp-0x20  vertical_step[1].x (float dword)
	;    ebp-0x1c  vertical_step[1].r (float dword)
	;    ebp-0x18  vertical_step[1].g (float dword)
	;    ebp-0x14  vertical_step[1].b (float dword)
	;    ebp-0x10  vertical_step[2].x (float dword)
	;    ebp-0x0c  vertical_step[2].r (float dword)
	;    ebp-0x08  vertical_step[2].g (float dword)
	;    ebp-0x04  vertical_step[2].b (float dword)
	%define vertical_step ebp-0x30
	;  ebp-0x50  right - right end of horizontal line
	;    ebp-0x50  right.x (float dword)
	;    ebp-0x4c  right.r (float dword)
	;    ebp-0x48  right.g (float dword)
	;    ebp-0x44  right.b (float dword)
	;    ebp-0x40  right.int_x (signed int dword)
	;    ebp-0x3c  right.int_r (signed int dword)
	;    ebp-0x38  right.int_g (signed int dword)
	;    ebp-0x34  right.int_b (signed int dword)
	%define right ebp-0x50
	;  ebp-0x70  left - left end of horizontal line
	;    ebp-0x70  left.x (float dword)
	;    ebp-0x6c  left.r (float dword)
	;    ebp-0x68  left.g (float dword)
	;    ebp-0x64  left.b (float dword)
	;    ebp-0x60  left.int_x (signed int dword)
	;    ebp-0x5c  left.int_r (signed int dword)
	;    ebp-0x58  left.int_g (signed int dword)
	;    ebp-0x54  left.int_b (signed int dword)
	%define left ebp-0x70
	;  ebp-0x7c  horizontal_step - horizontal linear interpolation step between "left" and "right"
	;    ebp-0x7c  horizontal_step.r (float dword)
	;    ebp-0x78  horizontal_step.g (float dword)
	;    ebp-0x74  horizontal_step.b (float dword)
	%define horizontal_step ebp-0x7c
	;  ebp-0x80  abs_width - image width in pixels (unsigned int dword)
	%define abs_width ebp-0x80
	;  ebp-0x84  max_y - maximal Y position of triangle fitting into the bitmap (signed int dword)
	%define max_y ebp-0x84
	;  ebp-0x88  min_y - minimal Y position of triangle fitting into the bitmap (signed int dword)
	%define min_y ebp-0x88
	;  ebp-0x8c  max_x - maximal X position of triangle fitting into the bitmap (signed int dword)
	%define max_x ebp-0x8c
	;  ebp-0x90  min_x - minimal X position of triangle fitting into the bitmap (signed int dword)
	%define min_x ebp-0x90
	;  ebp-0x94  stride - image width in bytes rounded up to the nearest dword (unsigned int dword)
	%define stride ebp-0x94
	;  ebp-0x98  row_address - address of the first pixel in the current row (pointer dword)
	%define row_address ebp-0x98

	; total size of local variables put initially on the stack
	%define local_size 0x98

	; make sure provided pointer arguments are not null
	mov eax, -1  ; error indicator
	cmp [image_data], dword 0
	jz draw_triangle_end
	cmp [info_header], dword 0
	jz draw_triangle_end
	cmp [vertices], dword 0
	jz draw_triangle_end
	
	; prologue
	enter local_size, 0
	
	; zero-initialize local variables
	push dword local_size
	push dword 0  ; memory value after initialization
	lea eax, [ebp-local_size]
	push eax
	call memset  ; memset(ebp-local_size, 0, local_size)
	add esp, 12
	
	; save the callee-saved registers on the stack
	push ebx
	push esi
	push edi

calc_step0:
	mov ebx, [vertices]
	mov eax, [ebx+4] ; *vertices + 0 * 12 + 4 (posY)
	mov [min_y], eax ; save *vertices[0].posY as min_y
	sub eax, [ebx+12+4] ; *vertices + 1 * 12 + 4 (posY)
	jz calc_step1
	finit
	push eax         ;
	fild dword [esp] ; load position difference to FPU
	fild dword [ebx] ; *vertices + 0 * 12 + 0 (posX)
	fisub dword [ebx+12] ; *vertices + 1 * 12 + 0 (posX)
	fdiv st0, st1
	fstp dword [vertical_step] ; store result in vertical_step + 0 * 16 + 0 (x)
	movzx eax, byte [ebx+8] ; *vertices + 0 * 12 + 8 (colR)
	mov [esp], eax
	fild dword [esp]
	movzx eax, byte [ebx+12+8] ; *vertices + 1 * 12 + 8 (colR)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [vertical_step+4] ; store result in vertical_step + 0 * 16 + 4 (r)
	movzx eax, byte [ebx+9] ; *vertices + 0 * 12 + 9 (colG)
	push eax
	fild dword [esp]
	movzx eax, byte [ebx+12+9] ; *vertices + 1 * 12 + 9 (colG)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [vertical_step+8] ; store result in vertical_step + 0 * 16 + 8 (g)
	movzx eax, byte [ebx+10] ; *vertices + 0 * 12 + 10 (colB)
	push eax
	fild dword [esp]
	movzx eax, byte [ebx+22] ; *vertices + 1 * 12 + 10 (colB)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [vertical_step+12] ; store result in vertical_step + 0 * 16 + 12 (b)
	fstp st0
	add esp, 4

calc_step1:
	mov eax, [ebx+4] ; *vertices + 0 * 12 + 4 (posY)
	mov edx, [ebx+2*12+4] ; *vertices + 2 * 12 + 4 (posY)
	mov [max_y], edx ; save *vertices[2].posY as max_y
	sub eax, edx
	jz calc_step2
	push eax         ;
	fild dword [esp] ; load position difference to FPU
	fild dword [ebx] ; *vertices + 0 * 12 + 0 (posX)
	fisub dword [ebx+2*12] ; *vertices + 2 * 12 + 0 (posX)
	fdiv st0, st1
	fstp dword [vertical_step+16] ; store result in vertical_step + 1 * 16 + 0 (x)
	movzx eax, byte [ebx+8] ; *vertices + 0 * 12 + 8 (colR)
	mov [esp], eax
	fild dword [esp]
	movzx eax, byte [ebx+2*12+8] ; *vertices + 2 * 12 + 8 (colR)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [vertical_step+16+4] ; store result in vertical_step + 1 * 16 + 4 (r)
	movzx eax, byte [ebx+9] ; *vertices + 0 * 12 + 9 (colG)
	push eax
	fild dword [esp]
	movzx eax, byte [ebx+2*12+9] ; *vertices + 2 * 12 + 9 (colG)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [vertical_step+16+8] ; store result in vertical_step + 1 * 16 + 8 (g)
	movzx eax, byte [ebx+10] ; *vertices + 0 * 12 + 10 (colB)
	push eax
	fild dword [esp]
	movzx eax, byte [ebx+2*12+10] ; *vertices + 2 * 12 + 10 (colB)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [vertical_step+16+12] ; store result in vertical_step + 1 * 16 + 12 (b)
	fstp st0
	add esp, 4

calc_step2:
	mov eax, [ebx+12+4] ; *vertices + 1 * 12 + 4 (posY)
	sub eax, [ebx+2*12+4] ; *vertices + 2 * 12 + 4 (posY)
	jz calc_minmax_y
	push eax         ;
	fild dword [esp] ; load position difference to FPU
	fild dword [ebx+12] ; *vertices + 1 * 12 + 0 (posX)
	fisub dword [ebx+2*12] ; *vertices + 2 * 12 + 0 (posX)
	fdiv st0, st1
	fstp dword [vertical_step+2*16] ; store result in vertical_step + 2 * 16 + 0 (x)
	movzx eax, byte [ebx+12+8] ; *vertices + 1 * 12 + 8 (colR)
	mov [esp], eax
	fild dword [esp]
	movzx eax, byte [ebx+2*12+8] ; *vertices + 2 * 12 + 8 (colR)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [vertical_step+2*16+4] ; store result in vertical_step + 2 * 16 + 4 (r)
	movzx eax, byte [ebx+12+9] ; *vertices + 1 * 12 + 9 (colG)
	push eax
	fild dword [esp]
	movzx eax, byte [ebx+2*12+9] ; *vertices + 2 * 12 + 9 (colG)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [vertical_step+2*16+8] ; store result in vertical_step + 2 * 16 + 8 (g)
	movzx eax, byte [ebx+12+10] ; *vertices + 1 * 12 + 10 (colB)
	push eax
	fild dword [esp]
	movzx eax, byte [ebx+2*12+10] ; *vertices + 2 * 12 + 10 (colB)
	mov [esp], eax
	fisub dword [esp]
	fdiv st0, st1
	fstp dword [vertical_step+2*16+12] ; store result in vertical_step + 2 * 16 + 12 (b)
	fstp st0
	add esp, 4

calc_minmax_y:
	; min_y = max(min_y, 0)
	mov esi, ebx
	xor ebx, ebx
	mov eax, [min_y] ; load min_y
	test eax, eax
	cmovl eax, ebx
	mov [min_y], eax ; store min_y

	; max_y = min(max_y, abs(info_header->biHeight) - 1)
	mov ebx, [info_header]
	mov eax, [ebx+8] ; info_header->biHeight
	mov edx, eax ;
	sar edx, 31  ;
	xor eax, edx ;
	sub eax, edx ; get absolute height
	sub eax, 1
	mov edx, [max_y] ; load max_y
	cmp eax, edx
	cmovl edx, eax
	mov [max_y], edx ; store max_y

	mov eax, [ebx+4] ; info_header->biWidth
	mov ebx, eax ;
	sar ebx, 31  ;
	xor eax, ebx ;
	sub eax, ebx ; get absolute value of width
	mov [abs_width], eax
	mov ebx, eax ;
	shl eax, 1   ;
	add eax, ebx ; multiply eax by 3
	add eax, 3
	and eax, 0xfffffffc
	mov [stride], eax

	mov ecx, [min_y]
draw_triangle_y_pre_loop:
	cmp ecx, [max_y]
	jg draw_triangle_y_loop_end
	mov edi, esi ; (*vertices)[0]
	add edi, 12 ; (*vertices)[1]
	lea ebx, [vertical_step] ; vertical_step[0]
	mov edx, ebx
	add ebx, 32 ; vertical_step[2]
	cmp ecx, [edi+4] ; *vertices + 1 * 12 + 4 (posY)
	cmovl edi, esi ; reset to (*vertices)[0]
	cmovl ebx, edx ; reset to vertical_step[0]
	; zero eax, edx
	; ebx - appropriate vertical_step
	; edi - appropriate vertex
	; esi - original vertices

	; calculate initial left x
	mov eax, [ebx]
	push eax  ; vertical_step x (float)
	fld dword [esp]
	mov edx, ecx
	sub edx, [edi+4]
	push edx  ; vertical_step multiplier: i - vertices posY (int32_t)
	fimul dword [esp]
	fld st0
	mov eax, [edi]
	push eax ; starting value: vertices posX (int32_t)
	fiadd dword [esp]
	fst dword [left]  ; left + 0 (x)
	fistp dword [left+0x10]  ; left + 16 (integer) + 0 (x)
	; float TOP -> i - vertices posY
	add esp, 4

	; calculate initial left r
	mov eax, [ebx+4]
	mov [esp+4], eax ; vertical_step r (float)
	fld dword [esp+4]
	fmul st0, st1
	mov al, [edi+8]
	movzx eax, al  ; expand uint8_t to uint32_t
	mov [esp], eax  ; starting value: vertices colR (int32_t)
	fiadd dword [esp]
	fst dword [left+4]  ; left + 4 (r)
	fistp dword [left+0x10+4]  ; left + 16 (integer) + 4 (r)

	; calculate initial left g
	mov eax, [ebx+8]
	mov [esp+4], eax  ; vertical_step g (float)
	fld dword [esp+4]
	fmul st0, st1
	mov al, [edi+9]
	movzx eax, al  ; expand uint8_t to uint32_t
	mov [esp], eax  ; starting value: vertices colG (int32_t)
	fiadd dword [esp]
	fst dword [left+8]  ; left + 8 (g)
	fistp dword [left+0x10+8]  ; left + 16 (integer) 8 (g)

	; calculate initial left b
	mov eax, [ebx+12]
	mov [esp+4], eax  ; vertical_step b (float)
	fld dword [esp+4]
	fmul st0, st1
	mov al, [edi+10]
	movzx eax, al  ; expand uint8_t to uint32_t
	mov [esp], eax  ; starting value: vertices colB (int32_t)
	fiadd dword [esp]
	fst dword [left+12]  ; left + 12 (b)
	fistp dword [left+0x10+12]  ; left + 16 (integer) + 12 (b)

	; calculate initial right x
	mov eax, [vertical_step+16]
	mov [esp+4], eax  ; vertical_step[1].x (float)
	fld dword [esp+4]
	fmul st0, st1
	mov eax, [esi]
	mov [esp], eax  ; starting value: vertices[0].posX (int32_t)
	fiadd dword [esp]
	fst dword [right]  ; right + 0 (x)
	fistp dword [right+0x10]  ; right + 16 (integer) + 0 (x)

	; calculate initial right r
	mov eax, [vertical_step+16+4]
	mov [esp+4], eax  ; vertical_step[1].r (float)
	fld dword [esp+4]
	fmul st0, st1
	mov al, [esi+8]
	movzx eax, al  ; expand uint8_t to uint32_t
	mov [esp], eax  ; starting value: vertices[0].colR (int32_t)
	fiadd dword [esp]
	fst dword [right+4]  ; right + 4 (r)
	fistp dword [right+0x10+4]  ; right + 16 (integer) + 4 (r)

	; calculate initial right g
	mov eax, [vertical_step+16+8]
	mov [esp+4], eax  ; vertical_step[1].g (float)
	fld dword [esp+4]
	fmul st0, st1
	mov al, [esi+9]
	movzx eax, al  ; expand uint8_t to uint32_t
	mov [esp], eax  ; starting value: vertices[0].colG (int32_t)
	fiadd dword [esp]
	fst dword [right+8]  ; right + 8 (g)
	fistp dword [right+0x10+8]  ; right + 16 (integer) + 8 (g)

	; calculate initial right b
	mov eax, [vertical_step+16+12]
	mov [esp+4], eax  ; vertical_step[1].b (float)
	fld dword [esp+4]
	fmul st0, st1
	mov al, [esi+10]
	movzx eax, al  ; expand uint8_t to uint32_t
	mov [esp], eax  ; starting value: vertices[0].colB (int32_t)
	fiadd dword [esp]
	fst dword [right+12]  ; right + 12 (b)
	fistp dword [right+0x10+12]  ; right + 16 (integer) + 12 (b)

	fstp st0
	add esp, 8
	; calculate row address
	mov eax, [stride]
	mul dword [min_y]
	add eax, [image_data]
	mov [row_address], eax
draw_triangle_y_loop:
	cmp ecx, [max_y]
	jg draw_triangle_y_loop_end
	sub esp, 4
	lea edi, [left]
	lea edx, [right]
	mov eax, [edi+0x10]  ; left.int_x
	mov ebx, [edx+0x10]  ; right.int_x
	cmp eax, ebx
	jz draw_triangle_x_pre_loop
	; "exchange" if left.int_x > right.int_x
	cmovg eax, edi
	cmovg edi, edx
	cmovg edx, eax
	cmovg eax, ebx
	cmovg ebx, [edx+0x10]
	
	sub eax, ebx
	mov [esp], eax
	fild dword [esp]
	; calculate red step
	fld dword [edi+4]
	fsub dword [edx+4]
	fdiv st0, st1
	fstp dword [horizontal_step]
	; calculate green step
	fld dword [edi+8]
	fsub dword [edx+8]
	fdiv st0, st1
	fstp dword [horizontal_step+4]
	; calculate blue step
	fld dword [edi+12]
	fsub dword [edx+12]
	fdiv st0, st1
	fstp dword [horizontal_step+8]
	fstp st0 ; clear fpu
	add esp, 4

draw_triangle_x_pre_loop:
	mov eax, [edi+0x10]  ; left-most int_x
	xor ebx, ebx
	cmp eax, ebx
	cmovl eax, ebx
	mov [min_x], eax
	mov eax, [edx+0x10]  ; right-most int_x
	mov ebx, [abs_width]
	dec ebx
	cmp eax, ebx
	cmovg eax, ebx
	mov [max_x], eax
	push ecx
	mov ecx, [min_x]
	mov eax, ecx
	mov ebx, [edi+0x10]  ; left-most int_x
	sub eax, ebx
	push eax
	fild dword [esp]
	fld dword [horizontal_step]
	fmul st1
	fiadd dword [edi+0x10+4]  ; left-most int_r
	fld dword [horizontal_step+4]
	fmul st2
	fiadd dword [edi+0x10+8]  ; left-most int_g
	fld dword [horizontal_step+8]
	fmul st3
	fiadd dword [edi+0x10+12]  ; left-most int_b
	add esp, 4
	mov ebx, ecx  ;
	shl ebx, 1    ;
	add ebx, ecx  ; multiply min_x by 3
	add ebx, [row_address]
draw_triangle_x_loop:
	cmp ecx, [max_x]  ; check loop condition
	jg draw_triangle_x_loop_end
	sub esp, 4
	fist dword [esp]
	fincstp
	mov eax, [esp]
	mov [ebx], al  ; save blue
	fist dword [esp]
	fincstp
	mov eax, [esp]
	mov [ebx+1], al  ; save green
	fist dword [esp]
	mov eax, [esp]
	mov [ebx+2], al  ; save red
	; calc next colors
	fadd dword [horizontal_step]  ; red
	fdecstp
	fadd dword [horizontal_step+4]  ; green
	fdecstp
	fadd dword [horizontal_step+8]  ; blue
	add esp, 4
	add ebx, 3
	inc ecx
	jmp draw_triangle_x_loop
draw_triangle_x_loop_end:
	fstp st0  ;
	fstp st0  ;
	fstp st0  ;
	fstp st0  ; clear fpu
	pop ecx  ; get back the vertical loop counter
	inc ecx
	mov eax, [row_address]
	add eax, [stride]
	mov [row_address], eax
	; update left and right
	fld dword [left]
	mov eax, [esi+12+4]  ; (*vertices)[1].posY
	lea ebx, [vertical_step+32]
	cmp ecx, eax
	lea eax, [vertical_step]
	cmovg eax, ebx
	fadd dword [eax]  ; vertical_step x
	fst dword [left]         ;
	fistp dword [left+0x10]  ; save left.x
	fld dword [left+4]
	fadd dword [eax+4]  ; vertical_step r
	fst dword [left+4]         ;
	fistp dword [left+0x10+4]  ; save left.r
	fld dword [left+8]
	fadd dword [eax+8]  ; vertical_step g
	fst dword [left+8]         ;
	fistp dword [left+0x10+8]  ; save left.g
	fld dword [left+12]
	fadd dword [eax+12] ; vertical_step b
	fst dword [left+12]         ;
	fistp dword [left+0x10+12]  ; save left.b
	fld dword [right]
	fadd dword [vertical_step+16] ; vertical_step[1].x
	fst dword [right]         ;
	fistp dword [right+0x10]  ; save right.x
	fld dword [right+4]
	fadd dword [vertical_step+16+4] ; vertical_step[1].r
	fst dword [right+4]         ;
	fistp dword [right+0x10+4]  ; save right.r
	fld dword [right+8]
	fadd dword [vertical_step+16+8] ; vertical_step[1].g
	fst dword [right+8]         ;
	fistp dword [right+0x10+8]  ; save right.g
	fld dword [right+12]
	fadd dword [vertical_step+16+12] ; vertical_step[1].b
	fst dword [right+12]         ;
	fistp dword [right+0x10+12]  ; save right.b

	jmp draw_triangle_y_loop
draw_triangle_y_loop_end:

    xor eax, eax ; return 0

draw_triangle_cleanup:
	pop edi
	pop esi
	pop ebx
	leave
draw_triangle_end:
	ret
