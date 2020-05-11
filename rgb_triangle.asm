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
	; EBP-0x44  step (3 * 4 * float)
	; EBP-0x48  stride (int32_t)
	; EBP-0x4c  max_y (int32_t)
	; EBP-0x50  min_y (int32_t)
	; EBP-0x54  max_x (int32_t)
	; EBP-0x58  min_x (int32_t)
	; EBP-0x68  right (4 * float)
	; EBP-0x78  left (4 * float)
	; EBP-0x88  int_right (4 * int32_t)
	; EBP-0x98  int_left (4 * int32_t)
	; EBP-0xa4  line_color_step (3 * float)
	; EBP-0xa8  abs_width (int)
	; EBP-0xac  row_address (char *)
	; EBP-0xb0  pixel_address (char *)
	sub esp, 9ch
	%define step ebp-0x44
	%define stride ebp-0x48
	%define min_x ebp-0x58
	%define max_x ebp-0x54
	%define min_y ebp-0x50
	%define max_y ebp-0x4c
	%define left ebp-0x78
	%define right ebp-0x68
	%define int_left ebp-0x98
	%define int_right ebp-0x88
	%define line_color_step ebp-0xa4
	%define abs_width ebp-0xa8
	%define row_address ebp-0xac
	%define pixel_address ebp-0xb0

	; zero-initialize local variables
	push dword 9ch
	push dword 0
	lea eax, [ebp-0xb0]
	push eax
	call memset ; memset(esp, 0, 0x9c)
	add esp, 12

calc_step0:
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
	mov eax, [ebx+12+4] ; *vertices + 1 * 12 + 4 (posY)
	sub eax, [ebx+2*12+4] ; *vertices + 2 * 12 + 4 (posY)
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
	lea ebx, [step] ; step[0]
	mov edx, ebx
	add ebx, 32 ; step[2]
	cmp ecx, [edi+4] ; *vertices + 1 * 12 + 4 (posY)
	cmovle edi, esi ; reset to (*vertices)[0]
	cmovle ebx, edx ; reset to step[0]
	; zero eax, edx
	; ebx - appropriate step
	; edi - appropriate vertex
	; esi - original vertices

	; calculate initial left x
	mov eax, [ebx]
	push eax ; step x (float)
	fld dword [esp]
	mov edx, ecx
	sub edx, [edi+4]
	push edx ; step multiplier: i - vertices posY (int32_t)
	fimul dword [esp]
	fld st0
	mov eax, [edi]
	push eax ; starting value: vertices posX (int32_t)
	fiadd dword [esp]
	fst dword [left] ; left + 0 (x)
	fistp dword [int_left]
	; float TOP -> i - vertices posY
	add esp, 4

	; calculate initial left r
	mov eax, [ebx+4]
	mov [esp+4], eax ; step r (float)
	fld dword [esp+4]
	fmul st0, st1
	mov al, [edi+8]
	movzx eax, al ; expand uint8_t to uint32_t
	mov [esp], eax ; starting value: vertices colR (int32_t)
	fiadd dword [esp]
	fst dword [left+4] ; left + 4 (r)
	fistp dword [int_left+4]

	; calculate initial left g
	mov eax, [ebx+8]
	mov [esp+4], eax ; step g (float)
	fld dword [esp+4]
	fmul st0, st1
	mov al, [edi+9]
	movzx eax, al ; expand uint8_t to uint32_t
	mov [esp], eax ; starting value: vertices colG (int32_t)
	fiadd dword [esp]
	fst dword [left+8] ; left + 8 (g)
	fistp dword [int_left+8]

	; calculate initial left b
	mov eax, [ebx+12]
	mov [esp+4], eax ; step b (float)
	fld dword [esp+4]
	fmul st0, st1
	mov al, [edi+10]
	movzx eax, al ; expand uint8_t to uint32_t
	mov [esp], eax ; starting value: vertices colB (int32_t)
	fiadd dword [esp]
	fst dword [left+12] ; left + 12 (b)
	fistp dword [int_left+12]

	; calculate initial right x
	mov eax, [step+16]
	mov [esp+4], eax ; step[1].x (float)
	fld dword [esp+4]
	fmul st0, st1
	mov eax, [esi]
	mov [esp], eax ; starting value: vertices[0].posX (int32_t)
	fiadd dword [esp]
	fst dword [right] ; right + 0 (x)
	fistp dword [int_right]

	; calculate initial right r
	mov eax, [step+16+4]
	mov [esp+4], eax ; step[1].r (float)
	fld dword [esp+4]
	fmul st0, st1
	mov al, [esi+8]
	movzx eax, al ; expand uint8_t to uint32_t
	mov [esp], eax ; starting value: vertices[0].colR (int32_t)
	fiadd dword [esp]
	fst dword [right+4] ; right + 4 (r)
	fistp dword [int_right+4]

	; calculate initial right g
	mov eax, [step+16+8]
	mov [esp+4], eax ; step[1].g (float)
	fld dword [esp+4]
	fmul st0, st1
	mov al, [esi+9]
	movzx eax, al ; expand uint8_t to uint32_t
	mov [esp], eax ; starting value: vertices[0].colG (int32_t)
	fiadd dword [esp]
	fst dword [right+8] ; right + 8 (g)
	fistp dword [int_right+8]

	; calculate initial right b
	mov eax, [step+16+12]
	mov [esp+4], eax ; step[1].b (float)
	fld dword [esp+4]
	fmul st0, st1
	mov al, [esi+10]
	movzx eax, al ; expand uint8_t to uint32_t
	mov [esp], eax ; starting value: vertices[0].colB (int32_t)
	fiadd dword [esp]
	fst dword [right+12] ; right + 12 (b)
	fistp dword [int_right+12]

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
	lea edi, [int_left]
	lea edx, [int_right]
	mov eax, [edi] ; left.x (int)
	mov ebx, [edx] ; right.x (int)
	cmp eax, ebx
	jz draw_triangle_x_pre_loop
	; "exchange" if left.x > right.x
	cmovg eax, edi
	cmovg edi, edx
	cmovg edx, eax
	cmovg eax, [edi]
	cmovg ebx, [edx]
	
	sub eax, ebx
	mov [esp], eax
	fild dword [esp]
	; calculate red step
	fld dword [edi+4]
	fsub dword [edx+4]
	fdiv st0, st1
	fstp dword [line_color_step]
	; calculate green step
	fld dword [edi+8]
	fsub dword [edx+8]
	fdiv st0, st1
	fstp dword [line_color_step+4]
	; calculate blue step
	fld dword [edi+12]
	fsub dword [edx+12]
	fdiv st0, st1
	fstp dword [line_color_step+8]
	fstp st0 ; clear fpu
	add esp, 4

draw_triangle_x_pre_loop:
	mov eax, [edi] ; left-most X
	xor ebx, ebx
	cmp eax, ebx
	cmovl eax, ebx
	mov [min_x], eax
	mov eax, [edx] ; right-most X
	mov ebx, [abs_width]
	dec ebx
	cmp eax, ebx
	cmovg eax, ebx
	mov [max_x], eax
	push ecx
	mov ecx, [min_x]
	mov eax, ecx
	mov ebx, [edi]
	sub eax, ebx
	push eax
	fild dword [esp]
	fld dword [line_color_step]
	fmul st1
	fiadd dword [edi]
	fld dword [line_color_step+4]
	fmul st2
	fiadd dword [edi+4]
	fld dword [line_color_step+8]
	fmul st3
	fiadd dword [edi+8]
	add esp, 4
	fincstp
	fincstp
	mov ebx, ecx ;
	shl ebx, 1   ;
	add ebx, ecx ; multiply min_x by 3
	add ebx, [row_address]
draw_triangle_x_loop:
	cmp ecx, [edx]
	jg draw_triangle_x_loop_end
	sub esp, 4
	fist dword [esp]
	fdecstp
	mov eax, [esp]
	mov [ebx], al ; save blue
	fist dword [esp]
	fdecstp
	mov eax, [esp]
	mov [ebx+1], al ; save green
	fist dword [esp]
	mov eax, [esp]
	mov [ebx+2], al ; save red
	; calc next colors
	fadd dword [line_color_step] ; red
	fincstp
	fadd dword [line_color_step+4] ; green
	fincstp
	fadd dword [line_color_step+8] ; blue
	add esp, 4
	add ebx, 3
	inc ecx
	jmp draw_triangle_x_loop
draw_triangle_x_loop_end:
	fdecstp
	fdecstp
	fstp st0
	fstp st0
	fstp st0
	fstp st0 ; clear fpu
	pop ecx ; get back the vertical loop counter
	inc ecx
	mov eax, [row_address]
	add eax, [stride]
	mov [row_address], eax
	; update left and right
	fld dword [left]
	mov eax, [esi+12+4] ; (*vertices)[1].posY
	lea ebx, [step+32]
	cmp ecx, eax
	lea eax, [step]
	cmovg eax, ebx
	fadd dword [eax] ; step x
	fst dword [left]       ;
	fistp dword [int_left] ; save left.x
	fld dword [left+4]
	fadd dword [eax+4] ; step r
	fst dword [left+4]       ;
	fistp dword [int_left+4] ; save left.r
	fld dword [left+8]
	fadd dword [eax+8] ; step g
	fst dword [left+8]       ;
	fistp dword [int_left+8] ; save left.g
	fld dword [left+12]
	fadd dword [eax+12] ; step b
	fst dword [left+12]       ;
	fistp dword [int_left+12] ; save left.b
	fld dword [right]
	fadd dword [step+16] ; step[1].x
	fst dword [right]       ;
	fistp dword [int_right] ; save right.x
	fld dword [right+4]
	fadd dword [step+16+4] ; step[1].r
	fst dword [right+4]       ;
	fistp dword [int_right+4] ; save right.r
	fld dword [right+8]
	fadd dword [step+16+8] ; step[1].g
	fst dword [right+8]       ;
	fistp dword [int_right+8] ; save right.g
	fld dword [right+12]
	fadd dword [step+16+12] ; step[1].g
	fst dword [right+12]       ;
	fistp dword [int_right+12] ; save right.g

	jmp draw_triangle_y_loop
draw_triangle_y_loop_end:

    xor eax, eax ; return 0

	add esp, 9ch
draw_triangle_end:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
    mov esp, ebp
	pop ebp
	ret
