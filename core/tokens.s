; SPDX-License-Identifier: BSD-2-Clause
; Copyright (c) 2026 danko1122q
; All rights reserved.

as_convert_expression:
	push	ebp
	call	as_get_fp_value
	if_not_carry	as_fp_expression
	mov	[as_current_offset],esp
      as_expression_loop:
	push	edi
	mov	edi,as_single_operand_operators
	call	as_get_operator
	pop	edi
	or	al,al
	if_zero	as_expression_element
	cmp	al,82h
	if_equal	as_expression_loop
	push	eax
	jmp	as_expression_loop
      as_expression_element:
	mov	al,[esi]
	cmp	al,1Ah
	if_equal	as_expression_number
	cmp	al,22h
	if_equal	as_expression_number
	cmp	al,'('
	if_equal	as_expression_number
	mov	al,'!'
	stos	as_u8 [edi]
	jmp	as_expression_operator
      as_expression_number:
	call	as_convert_number
      as_expression_operator:
	push	edi
	mov	edi,as_operators
	call	as_get_operator
	pop	edi
	or	al,al
	if_zero	as_expression_end
      as_operators_loop:
	cmp	esp,[as_current_offset]
	if_equal	as_push_operator
	mov	bl,al
	and	bl,0F0h
	mov	bh,as_u8 [esp]
	and	bh,0F0h
	cmp	bl,bh
	if_above	as_push_operator
	pop	ebx
	mov	as_u8 [edi],bl
	inc	edi
	jmp	as_operators_loop
      as_push_operator:
	push	eax
	jmp	as_expression_loop
      as_expression_end:
	cmp	esp,[as_current_offset]
	if_equal	as_expression_converted
	pop	eax
	stos	as_u8 [edi]
	jmp	as_expression_end
      as_expression_converted:
	pop	ebp
	ret
      as_fp_expression:
	mov	al,'.'
	stos	as_u8 [edi]
	mov	eax,[as_fp_value]
	stos	as_u32 [edi]
	mov	eax,[as_fp_value+4]
	stos	as_u32 [edi]
	mov	eax,[as_fp_value+8]
	stos	as_u32 [edi]
	pop	ebp
	ret

as_convert_number:
	lea	eax,[edi+20h]
	mov	edx,[as_memory_end]
	cmp	[as_source_start],0
	if_equal	as_check_memory_for_number
	mov	edx,[as_labels_list]
      as_check_memory_for_number:
	cmp	eax,edx
	if_above_equal	as_out_of_memory
	mov	eax,esp
	sub	eax,[as_stack_limit]
	cmp	eax,100h
	if_below	as_stack_overflow
	cmp	as_u8 [esi],'('
	if_equal	as_expression_value
	inc	edi
	call	as_get_number
	if_carry	as_symbol_value
	or	ebp,ebp
	if_zero	as_valid_number
	mov	as_u8 [edi-1],0Fh
	ret
      as_valid_number:
	cmp	as_u32 [edi+4],0
	if_not_equal	as_qword_number
	cmp	as_u16 [edi+2],0
	if_not_equal	as_dword_number
	cmp	as_u8 [edi+1],0
	if_not_equal	as_word_number
      as_byte_number:
	mov	as_u8 [edi-1],1
	inc	edi
	ret
      as_qword_number:
	mov	as_u8 [edi-1],8
	add	edi,8
	ret
      as_dword_number:
	mov	as_u8 [edi-1],4
	scas	as_u32 [edi]
	ret
      as_word_number:
	mov	as_u8 [edi-1],2
	scas	as_u16 [edi]
	ret
      as_expression_value:
	inc	esi
	push	[as_current_offset]
	call	as_convert_expression
	pop	[as_current_offset]
	lods	as_u8 [esi]
	cmp	al,')'
	if_equal	as_subexpression_closed
	dec	esi
	mov	al,'!'
	stosb
      as_subexpression_closed:
	ret
      as_symbol_value:
	mov	eax,[as_source_start]
	test	eax,eax
	if_zero	as_preprocessor_value
	cmp	eax,-1
	if_equal	as_invalid_value
	push	edi esi
	lods	as_u16 [esi]
	cmp	al,1Ah
	if_not_equal	as_no_address_register
	movzx	ecx,ah
	call	as_get_symbol
	if_carry	as_no_address_register
	cmp	al,10h
	if_not_equal	as_no_address_register
	mov	al,ah
	shr	ah,4
	cmp	ah,4
	if_equal	as_register_value
	and	ah,not 1
	cmp	ah,8
	if_equal	as_register_value
	cmp	ah,0Ch
	if_above_equal	as_register_value
	cmp	ah,6
	if_equal	as_register_value
	cmp	al,23h
	if_equal	as_register_value
	cmp	al,25h
	if_equal	as_register_value
	cmp	al,26h
	if_equal	as_register_value
	cmp	al,27h
	if_equal	as_register_value
      as_no_address_register:
	pop	esi
	mov	edi,as_directive_operators
	call	as_get_operator
	pop	edi
	or	al,al
	if_not_zero	as_broken_value
	lods	as_u8 [esi]
	cmp	al,1Ah
	if_not_equal	as_invalid_value
	lods	as_u8 [esi]
	movzx	ecx,al
	call	as_get_label_id
      as_store_label_value:
	mov	as_u8 [edi-1],11h
	stos	as_u32 [edi]
	ret
      as_broken_value:
	mov	eax,0Fh
	jmp	as_store_label_value
      as_register_value:
	pop	edx edi
	mov	as_u8 [edi-1],10h
	stos	as_u8 [edi]
	ret
      as_preprocessor_value:
	dec	edi
	lods	as_u8 [esi]
	cmp	al,1Ah
	if_not_equal	as_invalid_value
	lods	as_u8 [esi]
	mov	cl,al
	mov	ch,10b
	call	as_get_preprocessor_symbol
	if_carry	as_invalid_value
	test	edx,edx
	if_zero	as_special_preprocessor_value
	push	esi
	mov	esi,[edx+8]
	push	[as_current_offset]
	call	as_convert_expression
	pop	[as_current_offset]
	pop	esi
	ret
      as_special_preprocessor_value:
	cmp	eax,as_preprocessed_line_value
	if_not_equal	as_invalid_value
	call	as_get_current_line_from_file
	mov	al,4
	stos	as_u8 [edi]
	mov	eax,[ebx+4]
	stos	as_u32 [edi]
	ret

as_get_number:
	xor	ebp,ebp
	lods	as_u8 [esi]
	cmp	al,22h
	if_equal	as_get_text_number
	cmp	al,1Ah
	if_not_equal	as_not_number
	lods	as_u8 [esi]
	movzx	ecx,al
	mov	[as_number_start],esi
	mov	al,[esi]
	cmp	al,'$'
	if_equal	as_number_begin
	sub	al,30h
	cmp	al,9
	if_above	as_invalid_number
      as_number_begin:
	mov	ebx,esi
	add	esi,ecx
	push	esi
	dec	esi
	mov	as_u32 [edi],0
	mov	as_u32 [edi+4],0
	cmp	as_u8 [ebx],'$'
	if_equal	as_pascal_hex_number
	cmp	as_u16 [ebx],'0x'
	if_equal	as_get_hex_number
	mov	al,[esi]
	dec	esi
	cmp	al,'h'
	if_equal	as_get_hex_number
	cmp	al,'b'
	if_equal	as_get_bin_number
	cmp	al,'d'
	if_equal	as_get_dec_number
	cmp	al,'o'
	if_equal	as_get_oct_number
	cmp	al,'q'
	if_equal	as_get_oct_number
	cmp	al,'H'
	if_equal	as_get_hex_number
	cmp	al,'B'
	if_equal	as_get_bin_number
	cmp	al,'D'
	if_equal	as_get_dec_number
	cmp	al,'O'
	if_equal	as_get_oct_number
	cmp	al,'Q'
	if_equal	as_get_oct_number
	inc	esi
      as_get_dec_number:
	mov	ebx,esi
	mov	esi,[as_number_start]
      as_get_dec_digit:
	cmp	esi,ebx
	if_above	as_number_ok
	cmp	as_u8 [esi],27h
	if_equal	as_next_dec_digit
	cmp	as_u8 [esi],'_'
	if_equal	as_next_dec_digit
	xor	edx,edx
	mov	eax,[edi]
	shld	edx,eax,2
	shl	eax,2
	add	eax,[edi]
	add_with_carry	edx,0
	add	eax,eax
	add_with_carry	edx,edx
	mov	[edi],eax
	mov	eax,[edi+4]
	add	eax,eax
	if_carry	as_dec_out_of_range
	add	eax,eax
	if_carry	as_dec_out_of_range
	add	eax,[edi+4]
	if_carry	as_dec_out_of_range
	add	eax,eax
	if_carry	as_dec_out_of_range
	add	eax,edx
	if_carry	as_dec_out_of_range
	mov	[edi+4],eax
	movzx	eax,as_u8 [esi]
	sub	al,30h
	if_carry	as_bad_number
	cmp	al,9
	if_above	as_bad_number
	add	[edi],eax
	add_with_carry	as_u32 [edi+4],0
	if_carry	as_dec_out_of_range
      as_next_dec_digit:
	inc	esi
	jmp	as_get_dec_digit
      as_dec_out_of_range:
	cmp	esi,ebx
	if_above	as_dec_out_of_range_finished
	lods	as_u8 [esi]
	cmp	al,27h
	if_equal	as_bad_number
	cmp	al,'_'
	if_equal	as_bad_number
	sub	al,30h
	if_carry	as_bad_number
	cmp	al,9
	if_above	as_bad_number
	jmp	as_dec_out_of_range
      as_dec_out_of_range_finished:
	or	ebp,-1
	jmp	as_number_ok
      as_bad_number:
	pop	eax
      as_invalid_number:
	mov	esi,[as_number_start]
	dec	esi
      as_not_number:
	dec	esi
	set_carry
	ret
      as_get_bin_number:
	xor	bl,bl
      as_get_bin_digit:
	cmp	esi,[as_number_start]
	if_below	as_number_ok
	movzx	eax,as_u8 [esi]
	cmp	al,27h
	if_equal	as_bin_digit_skip
	cmp	al,'_'
	if_equal	as_bin_digit_skip
	sub	al,30h
	cmp	al,1
	if_above	as_bad_number
	xor	edx,edx
	mov	cl,bl
	dec	esi
	cmp	bl,64
	if_equal	as_bin_out_of_range
	inc	bl
	cmp	cl,32
	if_above_equal	as_bin_digit_high
	shl	eax,cl
	or	as_u32 [edi],eax
	jmp	as_get_bin_digit
      as_bin_digit_high:
	sub	cl,32
	shl	eax,cl
	or	as_u32 [edi+4],eax
	jmp	as_get_bin_digit
      as_bin_out_of_range:
	or	al,al
	if_zero	as_get_bin_digit
	or	ebp,-1
	jmp	as_get_bin_digit
      as_bin_digit_skip:
	dec	esi
	jmp	as_get_bin_digit
      as_pascal_hex_number:
	cmp	cl,1
	if_equal	as_bad_number
      as_get_hex_number:
	xor	bl,bl
      as_get_hex_digit:
	cmp	esi,[as_number_start]
	if_below	as_number_ok
	movzx	eax,as_u8 [esi]
	cmp	al,27h
	if_equal	as_hex_digit_skip
	cmp	al,'_'
	if_equal	as_hex_digit_skip
	cmp	al,'x'
	if_equal	as_hex_number_ok
	cmp	al,'$'
	if_equal	as_pascal_hex_ok
	sub	al,30h
	cmp	al,9
	if_below_equal	as_hex_digit_ok
	sub	al,7
	cmp	al,15
	if_below_equal	as_hex_letter_digit_ok
	sub	al,20h
	cmp	al,15
	if_above	as_bad_number
      as_hex_letter_digit_ok:
	cmp	al,10
	if_below	as_bad_number
      as_hex_digit_ok:
	xor	edx,edx
	mov	cl,bl
	dec	esi
	cmp	bl,64
	if_equal	as_hex_out_of_range
	add	bl,4
	cmp	cl,32
	if_above_equal	as_hex_digit_high
	shl	eax,cl
	or	as_u32 [edi],eax
	jmp	as_get_hex_digit
      as_hex_digit_high:
	sub	cl,32
	shl	eax,cl
	or	as_u32 [edi+4],eax
	jmp	as_get_hex_digit
      as_hex_out_of_range:
	or	al,al
	if_zero	as_get_hex_digit
	or	ebp,-1
	jmp	as_get_hex_digit
      as_hex_digit_skip:
	dec	esi
	jmp	as_get_hex_digit
      as_get_oct_number:
	xor	bl,bl
      as_get_oct_digit:
	cmp	esi,[as_number_start]
	if_below	as_number_ok
	movzx	eax,as_u8 [esi]
	cmp	al,27h
	if_equal	as_oct_digit_skip
	cmp	al,'_'
	if_equal	as_oct_digit_skip
	sub	al,30h
	cmp	al,7
	if_above	as_bad_number
      as_oct_digit_ok:
	xor	edx,edx
	mov	cl,bl
	dec	esi
	cmp	bl,63
	if_above	as_oct_out_of_range
	if_not_equal	as_oct_range_ok
	cmp	al,1
	if_above	as_oct_out_of_range
      as_oct_range_ok:
	add	bl,3
	cmp	cl,30
	if_equal	as_oct_digit_wrap
	if_above	as_oct_digit_high
	shl	eax,cl
	or	as_u32 [edi],eax
	jmp	as_get_oct_digit
      as_oct_digit_wrap:
	shl	eax,cl
	add_with_carry	as_u32 [edi+4],0
	or	as_u32 [edi],eax
	jmp	as_get_oct_digit
      as_oct_digit_high:
	sub	cl,32
	shl	eax,cl
	or	as_u32 [edi+4],eax
	jmp	as_get_oct_digit
      as_oct_digit_skip:
	dec	esi
	jmp	as_get_oct_digit
      as_oct_out_of_range:
	or	al,al
	if_zero	as_get_oct_digit
	or	ebp,-1
	jmp	as_get_oct_digit
      as_hex_number_ok:
	dec	esi
      as_pascal_hex_ok:
	cmp	esi,[as_number_start]
	if_not_equal	as_bad_number
      as_number_ok:
	pop	esi
      as_number_done:
	clear_carry
	ret
      as_get_text_number:
	lods	as_u32 [esi]
	mov	edx,eax
	xor	bl,bl
	mov	as_u32 [edi],0
	mov	as_u32 [edi+4],0
      as_get_text_character:
	sub	edx,1
	if_carry	as_number_done
	movzx	eax,as_u8 [esi]
	inc	esi
	mov	cl,bl
	cmp	bl,64
	if_equal	as_text_out_of_range
	add	bl,8
	cmp	cl,32
	if_above_equal	as_text_character_high
	shl	eax,cl
	or	as_u32 [edi],eax
	jmp	as_get_text_character
      as_text_character_high:
	sub	cl,32
	shl	eax,cl
	or	as_u32 [edi+4],eax
	jmp	as_get_text_character
      as_text_out_of_range:
	or	ebp,-1
	jmp	as_get_text_character

as_get_fp_value:
	push	edi esi
      as_fp_value_start:
	lods	as_u8 [esi]
	cmp	al,'-'
	if_equal	as_fp_value_start
	cmp	al,'+'
	if_equal	as_fp_value_start
	cmp	al,1Ah
	if_not_equal	as_not_fp_value
	lods	as_u8 [esi]
	movzx	ecx,al
	cmp	cl,1
	if_below_equal	as_not_fp_value
	lea	edx,[esi+1]
	xor	ah,ah
      as_check_fp_value:
	lods	as_u8 [esi]
	cmp	al,'.'
	if_equal	as_fp_character_dot
	cmp	al,'E'
	if_equal	as_fp_character_exp
	cmp	al,'e'
	if_equal	as_fp_character_exp
	cmp	al,'F'
	if_equal	as_fp_last_character
	cmp	al,'f'
	if_equal	as_fp_last_character
      as_digit_expected:
	cmp	al,'0'
	if_below	as_not_fp_value
	cmp	al,'9'
	if_above	as_not_fp_value
	jmp	as_fp_character_ok
      as_fp_character_dot:
	cmp	esi,edx
	if_equal	as_not_fp_value
	or	ah,ah
	if_not_zero	as_not_fp_value
	or	ah,1
	lods	as_u8 [esi]
	loop	as_digit_expected
      as_not_fp_value:
	pop	esi edi
	set_carry
	ret
      as_fp_last_character:
	cmp	cl,1
	if_not_equal	as_not_fp_value
	or	ah,4
	jmp	as_fp_character_ok
      as_fp_character_exp:
	cmp	esi,edx
	if_equal	as_not_fp_value
	cmp	ah,1
	if_above	as_not_fp_value
	or	ah,2
	cmp	ecx,1
	if_not_equal	as_fp_character_ok
	cmp	as_u8 [esi],'+'
	if_equal	as_fp_exp_sign
	cmp	as_u8 [esi],'-'
	if_not_equal	as_fp_character_ok
      as_fp_exp_sign:
	inc	esi
	cmp	as_u8 [esi],1Ah
	if_not_equal	as_not_fp_value
	inc	esi
	lods	as_u8 [esi]
	movzx	ecx,al
	inc	ecx
      as_fp_character_ok:
	dec	ecx
	if_not_zero	as_check_fp_value
	or	ah,ah
	if_zero	as_not_fp_value
	pop	esi
	mov	[as_fp_sign],0
      as_fp_get_sign:
	lods	as_u8 [esi]
	cmp	al,1Ah
	if_equal	as_fp_get
	cmp	al,'+'
	if_equal	as_fp_get_sign
	xor	[as_fp_sign],1
	jmp	as_fp_get_sign
      as_fp_get:
	lods	as_u8 [esi]
	movzx	ecx,al
	xor	edx,edx
	mov	edi,as_fp_value
	mov	[edi],edx
	mov	[edi+4],edx
	mov	[edi+12],edx
	call	as_fp_optimize
	mov	[as_fp_format],0
	mov	al,[esi]
      as_fp_before_dot:
	lods	as_u8 [esi]
	cmp	al,'.'
	if_equal	as_fp_dot
	cmp	al,'E'
	if_equal	as_fp_exponent
	cmp	al,'e'
	if_equal	as_fp_exponent
	cmp	al,'F'
	if_equal	as_fp_done
	cmp	al,'f'
	if_equal	as_fp_done
	sub	al,30h
	mov	edi,as_fp_value+16
	xor	edx,edx
	mov	as_u32 [edi+12],edx
	mov	as_u32 [edi],edx
	mov	as_u32 [edi+4],edx
	mov	[edi+7],al
	mov	dl,7
	mov	as_u32 [edi+8],edx
	call	as_fp_optimize
	mov	edi,as_fp_value
	push	ecx
	mov	ecx,10
	call	as_fp_mul
	pop	ecx
	mov	ebx,as_fp_value+16
	call	as_fp_add
	loop	as_fp_before_dot
      as_fp_dot:
	mov	edi,as_fp_value+16
	xor	edx,edx
	mov	[edi],edx
	mov	[edi+4],edx
	mov	as_u8 [edi+7],80h
	mov	[edi+8],edx
	mov	as_u32 [edi+12],edx
	dec	ecx
	if_zero	as_fp_done
      as_fp_after_dot:
	lods	as_u8 [esi]
	cmp	al,'E'
	if_equal	as_fp_exponent
	cmp	al,'e'
	if_equal	as_fp_exponent
	cmp	al,'F'
	if_equal	as_fp_done
	cmp	al,'f'
	if_equal	as_fp_done
	inc	[as_fp_format]
	cmp	[as_fp_format],80h
	if_not_equal	as_fp_counter_ok
	mov	[as_fp_format],7Fh
      as_fp_counter_ok:
	dec	esi
	mov	edi,as_fp_value+16
	push	ecx
	mov	ecx,10
	call	as_fp_div
	push	as_u32 [edi]
	push	as_u32 [edi+4]
	push	as_u32 [edi+8]
	push	as_u32 [edi+12]
	lods	as_u8 [esi]
	sub	al,30h
	movzx	ecx,al
	call	as_fp_mul
	mov	ebx,edi
	mov	edi,as_fp_value
	call	as_fp_add
	mov	edi,as_fp_value+16
	pop	as_u32 [edi+12]
	pop	as_u32 [edi+8]
	pop	as_u32 [edi+4]
	pop	as_u32 [edi]
	pop	ecx
	dec	ecx
	if_not_zero	as_fp_after_dot
	jmp	as_fp_done
      as_fp_exponent:
	or	[as_fp_format],80h
	xor	edx,edx
	xor	ebp,ebp
	dec	ecx
	if_not_zero	as_get_exponent
	cmp	as_u8 [esi],'+'
	if_equal	as_fp_exponent_sign
	cmp	as_u8 [esi],'-'
	if_not_equal	as_fp_done
	not	ebp
      as_fp_exponent_sign:
	add	esi,2
	lods	as_u8 [esi]
	movzx	ecx,al
      as_get_exponent:
	movzx	eax,as_u8 [esi]
	inc	esi
	sub	al,30h
	cmp	al,10
	if_above_equal	as_exponent_ok
	signed_multiply	edx,10
	cmp	edx,8000h
	if_above_equal	as_value_out_of_range
	add	edx,eax
	loop	as_get_exponent
      as_exponent_ok:
	mov	edi,as_fp_value
	or	edx,edx
	if_zero	as_fp_done
	mov	ecx,edx
	or	ebp,ebp
	if_not_zero	as_fp_negative_power
      as_fp_power:
	push	ecx
	mov	ecx,10
	call	as_fp_mul
	pop	ecx
	loop	as_fp_power
	jmp	as_fp_done
      as_fp_negative_power:
	push	ecx
	mov	ecx,10
	call	as_fp_div
	pop	ecx
	loop	as_fp_negative_power
      as_fp_done:
	mov	edi,as_fp_value
	mov	al,[as_fp_format]
	mov	[edi+10],al
	mov	al,[as_fp_sign]
	mov	[edi+11],al
	test	as_u8 [edi+15],80h
	if_zero	as_fp_ok
	add	as_u32 [edi],1
	add_with_carry	as_u32 [edi+4],0
	if_not_carry	as_fp_ok
	mov	eax,[edi+4]
	shrd	[edi],eax,1
	shr	eax,1
	or	eax,80000000h
	mov	[edi+4],eax
	inc	as_u16 [edi+8]
      as_fp_ok:
	pop	edi
	clear_carry
	ret
      as_fp_mul:
	or	ecx,ecx
	if_zero	as_fp_zero
	mov	eax,[edi+12]
	mul	ecx
	mov	[edi+12],eax
	mov	ebx,edx
	mov	eax,[edi]
	mul	ecx
	add	eax,ebx
	add_with_carry	edx,0
	mov	[edi],eax
	mov	ebx,edx
	mov	eax,[edi+4]
	mul	ecx
	add	eax,ebx
	add_with_carry	edx,0
	mov	[edi+4],eax
      .loop:
	or	edx,edx
	if_zero	.done
	mov	eax,[edi]
	shrd	[edi+12],eax,1
	mov	eax,[edi+4]
	shrd	[edi],eax,1
	shrd	eax,edx,1
	mov	[edi+4],eax
	shr	edx,1
	inc	as_u32 [edi+8]
	cmp	as_u32 [edi+8],8000h
	if_greater_equal	as_value_out_of_range
	jmp	.loop
      .done:
	ret
      as_fp_div:
	mov	eax,[edi+4]
	xor	edx,edx
	div	ecx
	mov	[edi+4],eax
	mov	eax,[edi]
	div	ecx
	mov	[edi],eax
	mov	eax,[edi+12]
	div	ecx
	mov	[edi+12],eax
	mov	ebx,eax
	or	ebx,[edi]
	or	ebx,[edi+4]
	if_zero	as_fp_zero
      .loop:
	test	as_u8 [edi+7],80h
	if_not_zero	.exp_ok
	mov	eax,[edi]
	shld	[edi+4],eax,1
	mov	eax,[edi+12]
	shld	[edi],eax,1
	add	eax,eax
	mov	[edi+12],eax
	dec	as_u32 [edi+8]
	add	edx,edx
	jmp	.loop
      .exp_ok:
	mov	eax,edx
	xor	edx,edx
	div	ecx
	add	[edi+12],eax
	add_with_carry	as_u32 [edi],0
	add_with_carry	as_u32 [edi+4],0
	if_not_carry	.fp_div_done
	mov	eax,[edi+4]
	mov	ebx,[edi]
	shrd	[edi],eax,1
	shrd	[edi+12],ebx,1
	shr	eax,1
	or	eax,80000000h
	mov	[edi+4],eax
	inc	as_u32 [edi+8]
      .fp_div_done:
	ret
      as_fp_add:
	cmp	as_u32 [ebx+8],8000h
	if_equal	.fp_add_done
	cmp	as_u32 [edi+8],8000h
	if_equal	.fp_copy_val
	mov	eax,[ebx+8]
	cmp	eax,[edi+8]
	if_greater_equal	.exp_ok
	mov	eax,[edi+8]
      .exp_ok:
	call	.fp_align_exp
	xchg	ebx,edi
	call	.fp_align_exp
	xchg	ebx,edi
	mov	edx,[ebx+12]
	mov	eax,[ebx]
	mov	ebx,[ebx+4]
	add	[edi+12],edx
	add_with_carry	[edi],eax
	add_with_carry	[edi+4],ebx
	if_not_carry	.fp_add_done
	mov	eax,[edi]
	shrd	[edi+12],eax,1
	mov	eax,[edi+4]
	shrd	[edi],eax,1
	shr	eax,1
	or	eax,80000000h
	mov	[edi+4],eax
	inc	as_u32 [edi+8]
      .fp_add_done:
	ret
      .fp_copy_val:
	mov	eax, [ebx+0]
	mov	[edi+0], eax
	mov	eax, [ebx+4]
	mov	[edi+4], eax
	mov	eax, [ebx+8]
	mov	[edi+8], eax
	mov	eax, [ebx+12]
	mov	[edi+12], eax
	ret
      .fp_align_exp:
	push	ecx
	mov	ecx, eax
	sub	ecx, [ebx+8]
	mov	edx, [ebx+4]
	jecxz	.fp_align_done
      .fp_align_loop:
	mov	ebp, [ebx]
	shrd	[ebx+12], ebp, 1
	shrd	[ebx+0], edx, 1
	shr	edx, 1
	inc	as_u32 [ebx+8]
	loop	.fp_align_loop
      .fp_align_done:
	mov	[ebx+4], edx
	pop	ecx
	ret
      as_fp_optimize:
	mov	eax,[edi]
	mov	ebp,[edi+4]
	or	ebp,[edi]
	or	ebp,[edi+12]
	if_zero	as_fp_zero
      .loop:
	test	as_u8 [edi+7],80h
	if_not_zero	.done
	shld	[edi+4],eax,1
	mov	ebp,[edi+12]
	shld	eax,ebp,1
	mov	[edi],eax
	shl	as_u32 [edi+12],1
	dec	as_u32 [edi+8]
	jmp	.loop
      .done:
	ret
      as_fp_zero:
	mov	as_u32 [edi+8],8000h
	ret

as_preevaluate_logical_expression:
	xor	al,al
      as_preevaluate_embedded_logical_expression:
	mov	[as_logical_value_wrapping],al
	push	edi
	call	as_preevaluate_logical_value
      as_preevaluation_loop:
	cmp	al,0FFh
	if_equal	as_invalid_logical_expression
	mov	dl,[esi]
	inc	esi
	cmp	dl,'|'
	if_equal	as_preevaluate_or
	cmp	dl,'&'
	if_equal	as_preevaluate_and
	cmp	dl,92h
	if_equal	as_preevaluation_done
	or	dl,dl
	if_not_zero	as_invalid_logical_expression
      as_preevaluation_done:
	pop	edx
	dec	esi
	ret
      as_preevaluate_or:
	cmp	al,'1'
	if_equal	as_quick_true
	cmp	al,'0'
	if_equal	as_leave_only_following
	push	edi
	mov	al,dl
	stos	as_u8 [edi]
	call	as_preevaluate_logical_value
	pop	ebx
	cmp	al,'0'
	if_equal	as_leave_only_preceding
	cmp	al,'1'
	if_not_equal	as_preevaluation_loop
	stos	as_u8 [edi]
	xor	al,al
	jmp	as_preevaluation_loop
      as_preevaluate_and:
	cmp	al,'0'
	if_equal	as_quick_false
	cmp	al,'1'
	if_equal	as_leave_only_following
	push	edi
	mov	al,dl
	stos	as_u8 [edi]
	call	as_preevaluate_logical_value
	pop	ebx
	cmp	al,'1'
	if_equal	as_leave_only_preceding
	cmp	al,'0'
	if_not_equal	as_preevaluation_loop
	stos	as_u8 [edi]
	xor	al,al
	jmp	as_preevaluation_loop
      as_leave_only_following:
	mov	edi,[esp]
	call	as_preevaluate_logical_value
	jmp	as_preevaluation_loop
      as_leave_only_preceding:
	mov	edi,ebx
	xor	al,al
	jmp	as_preevaluation_loop
      as_quick_true:
	call	as_skip_logical_value
	if_carry	as_invalid_logical_expression
	mov	edi,[esp]
	mov	al,'1'
	jmp	as_preevaluation_loop
      as_quick_false:
	call	as_skip_logical_value
	if_carry	as_invalid_logical_expression
	mov	edi,[esp]
	mov	al,'0'
	jmp	as_preevaluation_loop
      as_invalid_logical_expression:
	pop	edi
	mov	esi,edi
	mov	al,0FFh
	stos	as_u8 [edi]
	ret
      as_skip_logical_value:
	cmp	as_u8 [esi],'~'
	if_not_equal	as_negation_skipped
	inc	esi
	jmp	as_skip_logical_value
      as_negation_skipped:
	mov	al,[esi]
	cmp	al,91h
	if_not_equal	as_skip_simple_logical_value
	inc	esi
	xchg	al,[as_logical_value_wrapping]
	push	eax
      as_skip_logical_expression:
	call	as_skip_logical_value
	lods	as_u8 [esi]
	or	al,al
	if_zero	as_wrongly_structured_logical_expression
	cmp	al,0Fh
	if_equal	as_wrongly_structured_logical_expression
	cmp	al,'|'
	if_equal	as_skip_logical_expression
	cmp	al,'&'
	if_equal	as_skip_logical_expression
	cmp	al,92h
	if_not_equal	as_wrongly_structured_logical_expression
	pop	eax
	mov	[as_logical_value_wrapping],al
      as_logical_value_skipped:
	clear_carry
	ret
      as_wrongly_structured_logical_expression:
	pop	eax
	set_carry
	ret
      as_skip_simple_logical_value:
	mov	[as_logical_value_parentheses],0
      as_find_simple_logical_value_end:
	mov	al,[esi]
	or	al,al
	if_zero	as_logical_value_skipped
	cmp	al,0Fh
	if_equal	as_logical_value_skipped
	cmp	al,'|'
	if_equal	as_logical_value_skipped
	cmp	al,'&'
	if_equal	as_logical_value_skipped
	cmp	al,91h
	if_equal	as_skip_logical_value_internal_parenthesis
	cmp	al,92h
	if_not_equal	as_skip_logical_value_symbol
	sub	[as_logical_value_parentheses],1
	if_not_carry	as_skip_logical_value_symbol
	cmp	[as_logical_value_wrapping],91h
	if_not_equal	as_skip_logical_value_symbol
	jmp	as_logical_value_skipped
      as_skip_logical_value_internal_parenthesis:
	inc	[as_logical_value_parentheses]
      as_skip_logical_value_symbol:
	call	as_skip_symbol
	jmp	as_find_simple_logical_value_end
      as_preevaluate_logical_value:
	mov	ebp,edi
      as_preevaluate_negation:
	cmp	as_u8 [esi],'~'
	if_not_equal	as_preevaluate_negation_ok
	movs	as_u8 [edi],[esi]
	jmp	as_preevaluate_negation
      as_preevaluate_negation_ok:
	mov	ebx,esi
	cmp	as_u8 [esi],91h
	if_not_equal	as_preevaluate_simple_logical_value
	lods	as_u8 [esi]
	stos	as_u8 [edi]
	push	ebp
	mov	dl,[as_logical_value_wrapping]
	push	edx
	call	as_preevaluate_embedded_logical_expression
	pop	edx
	mov	[as_logical_value_wrapping],dl
	pop	ebp
	cmp	al,0FFh
	if_equal	as_invalid_logical_value
	cmp	as_u8 [esi],92h
	if_not_equal	as_invalid_logical_value
	or	al,al
	if_not_zero	as_preevaluated_expression_value
	movs	as_u8 [edi],[esi]
	ret
      as_preevaluated_expression_value:
	inc	esi
	lea	edx,[edi-1]
	sub	edx,ebp
	test	edx,1
	if_zero	as_expression_negation_ok
	xor	al,1
      as_expression_negation_ok:
	mov	edi,ebp
	ret
      as_invalid_logical_value:
	mov	edi,ebp
	mov	al,0FFh
	ret
      as_preevaluate_simple_logical_value:
	xor	edx,edx
	mov	[as_logical_value_parentheses],edx
      as_find_logical_value_boundaries:
	mov	al,[esi]
	or	al,al
	if_zero	as_logical_value_boundaries_found
	cmp	al,91h
	if_equal	as_logical_value_internal_parentheses
	cmp	al,92h
	if_equal	as_logical_value_boundaries_parenthesis_close
	cmp	al,'|'
	if_equal	as_logical_value_boundaries_found
	cmp	al,'&'
	if_equal	as_logical_value_boundaries_found
	or	edx,edx
	if_not_zero	as_next_symbol_in_logical_value
	cmp	al,0F0h
	if_equal	as_preevaluable_logical_operator
	cmp	al,0F7h
	if_equal	as_preevaluable_logical_operator
	cmp	al,0F6h
	if_not_equal	as_next_symbol_in_logical_value
      as_preevaluable_logical_operator:
	mov	edx,esi
      as_next_symbol_in_logical_value:
	call	as_skip_symbol
	jmp	as_find_logical_value_boundaries
      as_logical_value_internal_parentheses:
	inc	[as_logical_value_parentheses]
	jmp	as_next_symbol_in_logical_value
      as_logical_value_boundaries_parenthesis_close:
	sub	[as_logical_value_parentheses],1
	if_not_carry	as_next_symbol_in_logical_value
	cmp	[as_logical_value_wrapping],91h
	if_not_equal	as_next_symbol_in_logical_value
      as_logical_value_boundaries_found:
	or	edx,edx
	if_zero	as_non_preevaluable_logical_value
	mov	al,[edx]
	cmp	al,0F0h
	if_equal	as_compare_symbols
	cmp	al,0F7h
	if_equal	as_compare_symbol_types
	cmp	al,0F6h
	if_equal	as_scan_symbols_list
      as_non_preevaluable_logical_value:
	mov	ecx,esi
	mov	esi,ebx
	sub	ecx,esi
	if_zero	as_invalid_logical_value
	cmp	esi,edi
	if_equal	as_leave_logical_value_intact
	rep	movs as_u8 [edi],[esi]
	xor	al,al
	ret
      as_leave_logical_value_intact:
	add	edi,ecx
	add	esi,ecx
	xor	al,al
	ret
      as_compare_symbols:
	lea	ecx,[esi-1]
	sub	ecx,edx
	mov	eax,edx
	sub	eax,ebx
	cmp	ecx,eax
	if_not_equal	as_preevaluated_false
	push	esi edi
	mov	esi,ebx
	lea	edi,[edx+1]
	repe	cmps as_u8 [esi],[edi]
	pop	edi esi
	if_equal	as_preevaluated_true
      as_preevaluated_false:
	mov	eax,edi
	sub	eax,ebp
	test	eax,1
	if_not_zero	as_store_true
      as_store_false:
	mov	edi,ebp
	mov	al,'0'
	ret
      as_preevaluated_true:
	mov	eax,edi
	sub	eax,ebp
	test	eax,1
	if_not_zero	as_store_false
      as_store_true:
	mov	edi,ebp
	mov	al,'1'
	ret
      as_compare_symbol_types:
	push	esi
	lea	esi,[edx+1]
      as_type_comparison:
	cmp	esi,[esp]
	if_equal	as_types_compared
	mov	al,[esi]
	cmp	al,[ebx]
	if_not_equal	as_different_type
	cmp	al,'('
	if_not_equal	as_equal_type
	mov	al,[esi+1]
	mov	ah,[ebx+1]
	cmp	al,ah
	if_equal	as_equal_type
	or	al,al
	if_zero	as_different_type
	or	ah,ah
	if_zero	as_different_type
	cmp	al,'.'
	if_equal	as_different_type
	cmp	ah,'.'
	if_equal	as_different_type
      as_equal_type:
	call	as_skip_symbol
	xchg	esi,ebx
	call	as_skip_symbol
	xchg	esi,ebx
	jmp	as_type_comparison
      as_types_compared:
	pop	esi
	cmp	as_u8 [ebx],0F7h
	if_not_equal	as_preevaluated_false
	jmp	as_preevaluated_true
      as_different_type:
	pop	esi
	jmp	as_preevaluated_false
      as_scan_symbols_list:
	push	edi esi
	lea	esi,[edx+1]
	sub	edx,ebx
	lods	as_u8 [esi]
	cmp	al,'<'
	if_not_equal	as_invalid_symbols_list
      as_get_next_from_list:
	mov	edi,esi
      as_get_from_list:
	cmp	as_u8 [esi],','
	if_equal	as_compare_in_list
	cmp	as_u8 [esi],'>'
	if_equal	as_compare_in_list
	cmp	esi,[esp]
	if_above_equal	as_invalid_symbols_list
	call	as_skip_symbol
	jmp	as_get_from_list
      as_compare_in_list:
	mov	ecx,esi
	sub	ecx,edi
	cmp	ecx,edx
	if_not_equal	as_not_equal_length_in_list
	mov	esi,ebx
	repe	cmps as_u8 [esi],[edi]
	mov	esi,edi
	if_not_equal	as_not_equal_in_list
      as_skip_rest_of_list:
	cmp	as_u8 [esi],'>'
	if_equal	as_check_list_end
	cmp	esi,[esp]
	if_above_equal	as_invalid_symbols_list
	call	as_skip_symbol
	jmp	as_skip_rest_of_list
      as_check_list_end:
	inc	esi
	cmp	esi,[esp]
	if_not_equal	as_invalid_symbols_list
	pop	esi edi
	jmp	as_preevaluated_true
      as_not_equal_in_list:
	add	esi,ecx
      as_not_equal_length_in_list:
	lods	as_u8 [esi]
	cmp	al,','
	if_equal	as_get_next_from_list
	cmp	esi,[esp]
	if_not_equal	as_invalid_symbols_list
	pop	esi edi
	jmp	as_preevaluated_false
      as_invalid_symbols_list:
	pop	esi edi
	jmp	as_invalid_logical_value
