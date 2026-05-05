; SPDX-License-Identifier: BSD-2-Clause
; Copyright (c) 2026 danko1122q
; All rights reserved.

as_simple_instruction_except64:
as_simple_instruction:
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
as_simple_instruction_only64:
	jmp	as_illegal_instruction
as_simple_instruction_16bit_except64:
as_simple_instruction_16bit:
	cmp	[as_code_type],16
	if_not_equal	as_size_prefix
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
      as_size_prefix:
	mov	ah,al
	mov	al,66h
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
as_simple_instruction_32bit_except64:
as_simple_instruction_32bit:
	cmp	[as_code_type],16
	if_equal	as_size_prefix
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
as_iret_instruction:
	jmp	as_simple_instruction
as_simple_instruction_64bit:
	jmp	as_illegal_instruction
as_simple_extended_instruction_64bit:
	jmp	as_illegal_instruction
as_simple_extended_instruction:
	mov	ah,al
	mov	al,0Fh
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
as_simple_extended_instruction_f3:
	mov	as_u8 [edi],0F3h
	inc	edi
	jmp	as_simple_extended_instruction
as_prefix_instruction:
	stos	as_u8 [edi]
	or	[as_prefix_flags],1
	jmp	as_continue_line
as_segment_prefix:
	mov	ah,al
	shr	ah,4
	cmp	ah,3
	if_not_equal	as_illegal_instruction
	and	al,1111b
	mov	[as_segment_register],al
	call	as_store_segment_prefix
	or	[as_prefix_flags],1
	jmp	as_continue_line
as_bnd_prefix_instruction:
	stos	as_u8 [edi]
	or	[as_prefix_flags],1 + 10h
	jmp	as_continue_line
as_int_instruction:
	call	as_take_byte_value
	test	eax,eax
	if_not_sign	as_int_imm_ok
	call	as_recoverable_overflow
      as_int_imm_ok:
	mov	ah,al
	mov	al,0CDh
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
      as_take_byte_value:
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	ah,1
	if_above	as_invalid_operand_size
	cmp	al,'('
	if_not_equal	as_invalid_operand
	call	as_get_byte_value
	ret

as_aa_instruction:
	push	eax
	mov	bl,10
	cmp	as_u8 [esi],'('
	if_not_equal	as_aa_store
	inc	esi
	xor	al,al
	xchg	al,[as_operand_size]
	cmp	al,1
	if_above	as_invalid_operand_size
	call	as_get_byte_value
	mov	bl,al
      as_aa_store:
	cmp	[as_operand_size],0
	if_not_equal	as_invalid_operand
	pop	eax
	mov	ah,bl
	stos	as_u16 [edi]
	jmp	as_instruction_assembled

as_basic_instruction:
	mov	[as_base_code],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_basic_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
      as_basic_mem:
	call	as_get_address
	push	edx ebx ecx
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'('
	if_equal	as_basic_mem_imm
	cmp	al,10h
	if_not_equal	as_invalid_operand
      as_basic_mem_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	[as_postbyte_register],al
	pop	ecx ebx edx
	mov	al,ah
	cmp	al,1
	if_equal	as_instruction_ready
	call	as_operand_autodetect
	inc	[as_base_code]
      as_instruction_ready:
	call	as_store_instruction
	jmp	as_instruction_assembled
      as_basic_mem_imm:
	mov	al,[as_operand_size]
	cmp	al,1
	if_below	as_basic_mem_imm_nosize
	if_equal	as_basic_mem_imm_8bit
	cmp	al,2
	if_equal	as_basic_mem_imm_16bit
	cmp	al,4
	if_equal	as_basic_mem_imm_32bit
	cmp	al,8
	if_not_equal	as_invalid_operand_size
      as_basic_mem_imm_64bit:
	cmp	[as_size_declared],0
	if_not_equal	as_long_immediate_not_encodable
	call	as_operand_64bit
	call	as_get_simm32
	cmp	[as_value_type],4
	if_above_equal	as_long_immediate_not_encodable
	jmp	as_basic_mem_imm_32bit_ok
      as_basic_mem_imm_nosize:
	call	as_recoverable_unknown_size
      as_basic_mem_imm_8bit:
	call	as_get_byte_value
	mov	as_u8 [as_value],al
	mov	al,[as_base_code]
	shr	al,3
	mov	[as_postbyte_register],al
	pop	ecx ebx edx
	mov	[as_base_code],80h
	call	as_store_instruction_with_imm8
	jmp	as_instruction_assembled
      as_basic_mem_imm_16bit:
	call	as_operand_16bit
	call	as_get_word_value
	mov	as_u16 [as_value],ax
	mov	al,[as_base_code]
	shr	al,3
	mov	[as_postbyte_register],al
	pop	ecx ebx edx
	cmp	[as_value_type],0
	if_not_equal	as_basic_mem_imm_16bit_store
	cmp	[as_size_declared],0
	if_not_equal	as_basic_mem_imm_16bit_store
	cmp	as_u16 [as_value],80h
	if_below	as_basic_mem_simm_8bit
	cmp	as_u16 [as_value],-80h
	if_above_equal	as_basic_mem_simm_8bit
      as_basic_mem_imm_16bit_store:
	mov	[as_base_code],81h
	call	as_store_instruction_with_imm16
	jmp	as_instruction_assembled
      as_basic_mem_simm_8bit:
	mov	[as_base_code],83h
	call	as_store_instruction_with_imm8
	jmp	as_instruction_assembled
      as_basic_mem_imm_32bit:
	call	as_operand_32bit
	call	as_get_dword_value
      as_basic_mem_imm_32bit_ok:
	mov	as_u32 [as_value],eax
	mov	al,[as_base_code]
	shr	al,3
	mov	[as_postbyte_register],al
	pop	ecx ebx edx
	cmp	[as_value_type],0
	if_not_equal	as_basic_mem_imm_32bit_store
	cmp	[as_size_declared],0
	if_not_equal	as_basic_mem_imm_32bit_store
	cmp	as_u32 [as_value],80h
	if_below	as_basic_mem_simm_8bit
	cmp	as_u32 [as_value],-80h
	if_above_equal	as_basic_mem_simm_8bit
      as_basic_mem_imm_32bit_store:
	mov	[as_base_code],81h
	call	as_store_instruction_with_imm32
	jmp	as_instruction_assembled
      as_get_simm32:
	call	as_get_qword_value
	mov	ecx,edx
	sign_extend_dword
	cmp	ecx,edx
	if_equal	as_simm32_range_ok
	call	as_recoverable_overflow
      as_simm32_range_ok:
	cmp	[as_value_type],4
	if_not_equal	as_get_simm32_ok
	mov	[as_value_type],2
      as_get_simm32_ok:
	ret
      as_basic_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_basic_reg_reg
	cmp	al,'('
	if_equal	as_basic_reg_imm
	cmp	al,'['
	if_not_equal	as_invalid_operand
      as_basic_reg_mem:
	call	as_get_address
	mov	al,[as_operand_size]
	cmp	al,1
	if_equal	as_basic_reg_mem_8bit
	call	as_operand_autodetect
	add	[as_base_code],3
	jmp	as_instruction_ready
      as_basic_reg_mem_8bit:
	add	[as_base_code],2
	jmp	as_instruction_ready
      as_basic_reg_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,[as_postbyte_register]
	mov	[as_postbyte_register],al
	mov	al,ah
	cmp	al,1
	if_equal	as_nomem_instruction_ready
	call	as_operand_autodetect
	inc	[as_base_code]
      as_nomem_instruction_ready:
	call	as_store_nomem_instruction
	jmp	as_instruction_assembled
      as_basic_reg_imm:
	mov	al,[as_operand_size]
	cmp	al,1
	if_equal	as_basic_reg_imm_8bit
	cmp	al,2
	if_equal	as_basic_reg_imm_16bit
	cmp	al,4
	if_equal	as_basic_reg_imm_32bit
	cmp	al,8
	if_not_equal	as_invalid_operand_size
      as_basic_reg_imm_64bit:
	cmp	[as_size_declared],0
	if_not_equal	as_long_immediate_not_encodable
	call	as_operand_64bit
	call	as_get_simm32
	cmp	[as_value_type],4
	if_above_equal	as_long_immediate_not_encodable
	jmp	as_basic_reg_imm_32bit_ok
      as_basic_reg_imm_8bit:
	call	as_get_byte_value
	mov	dl,al
	mov	bl,[as_base_code]
	shr	bl,3
	xchg	bl,[as_postbyte_register]
	or	bl,bl
	if_zero	as_basic_al_imm
	mov	[as_base_code],80h
	call	as_store_nomem_instruction
	mov	al,dl
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
      as_basic_al_imm:
	mov	al,[as_base_code]
	add	al,4
	stos	as_u8 [edi]
	mov	al,dl
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
      as_basic_reg_imm_16bit:
	call	as_operand_16bit
	call	as_get_word_value
	mov	dx,ax
	mov	bl,[as_base_code]
	shr	bl,3
	xchg	bl,[as_postbyte_register]
	cmp	[as_value_type],0
	if_not_equal	as_basic_reg_imm_16bit_store
	cmp	[as_size_declared],0
	if_not_equal	as_basic_reg_imm_16bit_store
	cmp	dx,80h
	if_below	as_basic_reg_simm_8bit
	cmp	dx,-80h
	if_above_equal	as_basic_reg_simm_8bit
      as_basic_reg_imm_16bit_store:
	or	bl,bl
	if_zero	as_basic_ax_imm
	mov	[as_base_code],81h
	call	as_store_nomem_instruction
      as_basic_store_imm_16bit:
	mov	ax,dx
	call	as_mark_relocation
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
      as_basic_reg_simm_8bit:
	mov	[as_base_code],83h
	call	as_store_nomem_instruction
	mov	al,dl
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
      as_basic_ax_imm:
	add	[as_base_code],5
	call	as_store_classic_instruction_code
	jmp	as_basic_store_imm_16bit
      as_basic_reg_imm_32bit:
	call	as_operand_32bit
	call	as_get_dword_value
      as_basic_reg_imm_32bit_ok:
	mov	edx,eax
	mov	bl,[as_base_code]
	shr	bl,3
	xchg	bl,[as_postbyte_register]
	cmp	[as_value_type],0
	if_not_equal	as_basic_reg_imm_32bit_store
	cmp	[as_size_declared],0
	if_not_equal	as_basic_reg_imm_32bit_store
	cmp	edx,80h
	if_below	as_basic_reg_simm_8bit
	cmp	edx,-80h
	if_above_equal	as_basic_reg_simm_8bit
      as_basic_reg_imm_32bit_store:
	or	bl,bl
	if_zero	as_basic_eax_imm
	mov	[as_base_code],81h
	call	as_store_nomem_instruction
      as_basic_store_imm_32bit:
	mov	eax,edx
	call	as_mark_relocation
	stos	as_u32 [edi]
	jmp	as_instruction_assembled
      as_basic_eax_imm:
	add	[as_base_code],5
	call	as_store_classic_instruction_code
	jmp	as_basic_store_imm_32bit
      as_recoverable_unknown_size:
	cmp	[as_error_line],0
	if_not_equal	as_ignore_unknown_size
	push	[as_current_line]
	pop	[as_error_line]
	mov	[as_error],as_operand_size_not_specified
      as_ignore_unknown_size:
	ret
as_single_operand_instruction:
	mov	[as_base_code],0F6h
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_single_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
      as_single_mem:
	call	as_get_address
	mov	al,[as_operand_size]
	cmp	al,1
	if_equal	as_single_mem_8bit
	if_below	as_single_mem_nosize
	call	as_operand_autodetect
	inc	[as_base_code]
	jmp	as_instruction_ready
      as_single_mem_nosize:
	call	as_recoverable_unknown_size
      as_single_mem_8bit:
	jmp	as_instruction_ready
      as_single_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	mov	al,ah
	cmp	al,1
	if_equal	as_single_reg_8bit
	call	as_operand_autodetect
	inc	[as_base_code]
      as_single_reg_8bit:
	jmp	as_nomem_instruction_ready
as_mov_instruction:
	mov	[as_base_code],88h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_mov_reg
	cmp	al,14h
	if_equal	as_mov_creg
	cmp	al,'['
	if_not_equal	as_invalid_operand
      as_mov_mem:
	call	as_get_address
	push	edx ebx ecx
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'('
	if_equal	as_mov_mem_imm
	cmp	al,10h
	if_not_equal	as_invalid_operand
      as_mov_mem_reg:
	lods	as_u8 [esi]
	cmp	al,30h
	if_below	as_mov_mem_general_reg
	cmp	al,40h
	if_below	as_mov_mem_sreg
      as_mov_mem_general_reg:
	call	as_convert_register
	mov	[as_postbyte_register],al
	pop	ecx ebx edx
	cmp	ah,1
	if_equal	as_mov_mem_reg_8bit
	inc	[as_base_code]
	mov	al,ah
	call	as_operand_autodetect
	mov	al,[as_postbyte_register]
	or	al,bl
	or	al,bh
	if_zero	as_mov_mem_ax
	jmp	as_instruction_ready
      as_mov_mem_reg_8bit:
	or	al,bl
	or	al,bh
	if_not_zero	as_instruction_ready
      as_mov_mem_al:
	test	ch,22h
	if_not_zero	as_mov_mem_address16_al
	test	ch,44h
	if_not_zero	as_mov_mem_address32_al
	test	ch,not 88h
	if_not_zero	as_invalid_address_size
	call	as_check_mov_address64
	cmp	al,0
	if_greater	as_mov_mem_address64_al
	if_less	as_instruction_ready
	cmp	[as_code_type],16
	if_not_equal	as_mov_mem_address32_al
	cmp	edx,10000h
	if_below	as_mov_mem_address16_al
      as_mov_mem_address32_al:
	call	as_store_segment_prefix_if_necessary
	call	as_address_32bit_prefix
	mov	[as_base_code],0A2h
      as_store_mov_address32:
	call	as_store_classic_instruction_code
	call	as_store_address_32bit_value
	jmp	as_instruction_assembled
      as_mov_mem_address16_al:
	call	as_store_segment_prefix_if_necessary
	call	as_address_16bit_prefix
	mov	[as_base_code],0A2h
      as_store_mov_address16:
	call	as_store_classic_instruction_code
	mov	eax,edx
	stos	as_u16 [edi]
	cmp	edx,10000h
	if_greater_equal	as_value_out_of_range
	jmp	as_instruction_assembled
      as_check_mov_address64:
	jmp	as_no_address64
	test	ch,88h
	if_not_zero	as_address64_required
	mov	eax,[as_address_high]
	or	eax,eax
	if_zero	as_no_address64
	bit_test	edx,31
	add_with_carry	eax,0
	if_zero	as_address64_simm32
      as_address64_required:
	mov	al,1
	ret
      as_address64_simm32:
	mov	al,-1
	ret
      as_no_address64:
	test	ch,08h
	if_not_zero	as_invalid_address_size
	xor	al,al
	ret
      as_mov_mem_address64_al:
	call	as_store_segment_prefix_if_necessary
	mov	[as_base_code],0A2h
      as_store_mov_address64:
	call	as_store_classic_instruction_code
	call	as_store_address_64bit_value
	jmp	as_instruction_assembled
      as_mov_mem_ax:
	test	ch,22h
	if_not_zero	as_mov_mem_address16_ax
	test	ch,44h
	if_not_zero	as_mov_mem_address32_ax
	test	ch,not 88h
	if_not_zero	as_invalid_address_size
	call	as_check_mov_address64
	cmp	al,0
	if_greater	as_mov_mem_address64_ax
	if_less	as_instruction_ready
	cmp	[as_code_type],16
	if_not_equal	as_mov_mem_address32_ax
	cmp	edx,10000h
	if_below	as_mov_mem_address16_ax
      as_mov_mem_address32_ax:
	call	as_store_segment_prefix_if_necessary
	call	as_address_32bit_prefix
	mov	[as_base_code],0A3h
	jmp	as_store_mov_address32
      as_mov_mem_address16_ax:
	call	as_store_segment_prefix_if_necessary
	call	as_address_16bit_prefix
	mov	[as_base_code],0A3h
	jmp	as_store_mov_address16
      as_mov_mem_address64_ax:
	call	as_store_segment_prefix_if_necessary
	mov	[as_base_code],0A3h
	jmp	as_store_mov_address64
      as_mov_mem_sreg:
	sub	al,31h
	mov	[as_postbyte_register],al
	pop	ecx ebx edx
	mov	ah,[as_operand_size]
	or	ah,ah
	if_zero	as_mov_mem_sreg_store
	cmp	ah,2
	if_not_equal	as_invalid_operand_size
      as_mov_mem_sreg_store:
	mov	[as_base_code],8Ch
	jmp	as_instruction_ready
      as_mov_mem_imm:
	mov	al,[as_operand_size]
	cmp	al,1
	if_below	as_mov_mem_imm_nosize
	if_equal	as_mov_mem_imm_8bit
	cmp	al,2
	if_equal	as_mov_mem_imm_16bit
	cmp	al,4
	if_equal	as_mov_mem_imm_32bit
	cmp	al,8
	if_not_equal	as_invalid_operand_size
      as_mov_mem_imm_64bit:
	cmp	[as_size_declared],0
	if_not_equal	as_long_immediate_not_encodable
	call	as_operand_64bit
	call	as_get_simm32
	cmp	[as_value_type],4
	if_above_equal	as_long_immediate_not_encodable
	jmp	as_mov_mem_imm_32bit_store
      as_mov_mem_imm_nosize:
	call	as_recoverable_unknown_size
      as_mov_mem_imm_8bit:
	call	as_get_byte_value
	mov	as_u8 [as_value],al
	mov	[as_postbyte_register],0
	mov	[as_base_code],0C6h
	pop	ecx ebx edx
	call	as_store_instruction_with_imm8
	jmp	as_instruction_assembled
      as_mov_mem_imm_16bit:
	call	as_operand_16bit
	call	as_get_word_value
	mov	as_u16 [as_value],ax
	mov	[as_postbyte_register],0
	mov	[as_base_code],0C7h
	pop	ecx ebx edx
	call	as_store_instruction_with_imm16
	jmp	as_instruction_assembled
      as_mov_mem_imm_32bit:
	call	as_operand_32bit
	call	as_get_dword_value
      as_mov_mem_imm_32bit_store:
	mov	as_u32 [as_value],eax
	mov	[as_postbyte_register],0
	mov	[as_base_code],0C7h
	pop	ecx ebx edx
	call	as_store_instruction_with_imm32
	jmp	as_instruction_assembled
      as_mov_reg:
	lods	as_u8 [esi]
	mov	ah,al
	sub	ah,10h
	and	ah,al
	test	ah,0F0h
	if_not_zero	as_mov_sreg
	call	as_convert_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_equal	as_mov_reg_mem
	cmp	al,'('
	if_equal	as_mov_reg_imm
	cmp	al,14h
	if_equal	as_mov_reg_creg
	cmp	al,10h
	if_not_equal	as_invalid_operand
      as_mov_reg_reg:
	lods	as_u8 [esi]
	mov	ah,al
	sub	ah,10h
	and	ah,al
	test	ah,0F0h
	if_not_zero	as_mov_reg_sreg
	call	as_convert_register
	mov	bl,[as_postbyte_register]
	mov	[as_postbyte_register],al
	mov	al,ah
	cmp	al,1
	if_equal	as_mov_reg_reg_8bit
	call	as_operand_autodetect
	inc	[as_base_code]
      as_mov_reg_reg_8bit:
	jmp	as_nomem_instruction_ready
      as_mov_reg_sreg:
	mov	bl,[as_postbyte_register]
	mov	ah,al
	and	al,1111b
	mov	[as_postbyte_register],al
	shr	ah,4
	cmp	ah,3
	if_not_equal	as_invalid_operand
	dec	[as_postbyte_register]
	cmp	[as_operand_size],8
	if_equal	as_mov_reg_sreg64
	cmp	[as_operand_size],4
	if_equal	as_mov_reg_sreg32
	cmp	[as_operand_size],2
	if_not_equal	as_invalid_operand_size
	call	as_operand_16bit
	jmp	as_mov_reg_sreg_store
      as_mov_reg_sreg64:
	call	as_operand_64bit
	jmp	as_mov_reg_sreg_store
      as_mov_reg_sreg32:
	call	as_operand_32bit
      as_mov_reg_sreg_store:
	mov	[as_base_code],8Ch
	jmp	as_nomem_instruction_ready
      as_mov_reg_creg:
	lods	as_u8 [esi]
	mov	bl,al
	shr	al,4
	cmp	al,4
	if_above	as_invalid_operand
	add	al,20h
	mov	[as_extended_code],al
	and	bl,1111b
	xchg	bl,[as_postbyte_register]
	mov	[as_base_code],0Fh
	cmp	[as_operand_size],4
	if_not_equal	as_invalid_operand_size
	cmp	[as_postbyte_register],8
	if_not_equal	as_mov_reg_creg_store
	cmp	[as_extended_code],20h
	if_not_equal	as_mov_reg_creg_store
	mov	al,0F0h
	stos	as_u8 [edi]
	mov	[as_postbyte_register],0
      as_mov_reg_creg_store:
	jmp	as_nomem_instruction_ready
      as_mov_reg_creg_64bit:
	cmp	[as_operand_size],8
	if_not_equal	as_invalid_operand_size
	jmp	as_nomem_instruction_ready
      as_mov_reg_mem:
	add	[as_base_code],2
	call	as_get_address
	mov	al,[as_operand_size]
	cmp	al,1
	if_equal	as_mov_reg_mem_8bit
	inc	[as_base_code]
	call	as_operand_autodetect
	mov	al,[as_postbyte_register]
	or	al,bl
	or	al,bh
	if_zero	as_mov_ax_mem
	jmp	as_instruction_ready
      as_mov_reg_mem_8bit:
	mov	al,[as_postbyte_register]
	or	al,bl
	or	al,bh
	if_zero	as_mov_al_mem
	jmp	as_instruction_ready
      as_mov_al_mem:
	test	ch,22h
	if_not_zero	as_mov_al_mem_address16
	test	ch,44h
	if_not_zero	as_mov_al_mem_address32
	test	ch,not 88h
	if_not_zero	as_invalid_address_size
	call	as_check_mov_address64
	cmp	al,0
	if_greater	as_mov_al_mem_address64
	if_less	as_instruction_ready
	cmp	[as_code_type],16
	if_not_equal	as_mov_al_mem_address32
	cmp	edx,10000h
	if_below	as_mov_al_mem_address16
      as_mov_al_mem_address32:
	call	as_store_segment_prefix_if_necessary
	call	as_address_32bit_prefix
	mov	[as_base_code],0A0h
	jmp	as_store_mov_address32
      as_mov_al_mem_address16:
	call	as_store_segment_prefix_if_necessary
	call	as_address_16bit_prefix
	mov	[as_base_code],0A0h
	jmp	as_store_mov_address16
      as_mov_al_mem_address64:
	call	as_store_segment_prefix_if_necessary
	mov	[as_base_code],0A0h
	jmp	as_store_mov_address64
      as_mov_ax_mem:
	test	ch,22h
	if_not_zero	as_mov_ax_mem_address16
	test	ch,44h
	if_not_zero	as_mov_ax_mem_address32
	test	ch,not 88h
	if_not_zero	as_invalid_address_size
	call	as_check_mov_address64
	cmp	al,0
	if_greater	as_mov_ax_mem_address64
	if_less	as_instruction_ready
	cmp	[as_code_type],16
	if_not_equal	as_mov_ax_mem_address32
	cmp	edx,10000h
	if_below	as_mov_ax_mem_address16
      as_mov_ax_mem_address32:
	call	as_store_segment_prefix_if_necessary
	call	as_address_32bit_prefix
	mov	[as_base_code],0A1h
	jmp	as_store_mov_address32
      as_mov_ax_mem_address16:
	call	as_store_segment_prefix_if_necessary
	call	as_address_16bit_prefix
	mov	[as_base_code],0A1h
	jmp	as_store_mov_address16
      as_mov_ax_mem_address64:
	call	as_store_segment_prefix_if_necessary
	mov	[as_base_code],0A1h
	jmp	as_store_mov_address64
      as_mov_reg_imm:
	mov	al,[as_operand_size]
	cmp	al,1
	if_equal	as_mov_reg_imm_8bit
	cmp	al,2
	if_equal	as_mov_reg_imm_16bit
	cmp	al,4
	if_equal	as_mov_reg_imm_32bit
	cmp	al,8
	if_not_equal	as_invalid_operand_size
      as_mov_reg_imm_64bit:
	call	as_operand_64bit
	call	as_get_qword_value
	mov	ecx,edx
	cmp	[as_size_declared],0
	if_not_equal	as_mov_reg_imm_64bit_store
	cmp	[as_value_type],4
	if_above_equal	as_mov_reg_imm_64bit_store
	sign_extend_dword
	cmp	ecx,edx
	if_equal	as_mov_reg_64bit_imm_32bit
      as_mov_reg_imm_64bit_store:
	push	eax ecx
	mov	al,0B8h
	call	as_store_mov_reg_imm_code
	pop	edx eax
	call	as_mark_relocation
	stos	as_u32 [edi]
	mov	eax,edx
	stos	as_u32 [edi]
	jmp	as_instruction_assembled
      as_mov_reg_imm_8bit:
	call	as_get_byte_value
	mov	dl,al
	mov	al,0B0h
	call	as_store_mov_reg_imm_code
	mov	al,dl
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
      as_mov_reg_imm_16bit:
	call	as_get_word_value
	mov	dx,ax
	call	as_operand_16bit
	mov	al,0B8h
	call	as_store_mov_reg_imm_code
	mov	ax,dx
	call	as_mark_relocation
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
      as_mov_reg_imm_32bit:
	call	as_operand_32bit
	call	as_get_dword_value
	mov	edx,eax
	mov	al,0B8h
	call	as_store_mov_reg_imm_code
      as_mov_store_imm_32bit:
	mov	eax,edx
	call	as_mark_relocation
	stos	as_u32 [edi]
	jmp	as_instruction_assembled
      as_store_mov_reg_imm_code:
	mov	ah,[as_postbyte_register]
	test	ah,1000b
	if_zero	as_mov_reg_imm_prefix_ok
	or	[as_rex_prefix],41h
      as_mov_reg_imm_prefix_ok:
	and	ah,111b
	add	al,ah
	mov	[as_base_code],al
	call	as_store_classic_instruction_code
	ret
      as_mov_reg_64bit_imm_32bit:
	mov	edx,eax
	mov	bl,[as_postbyte_register]
	mov	[as_postbyte_register],0
	mov	[as_base_code],0C7h
	call	as_store_nomem_instruction
	jmp	as_mov_store_imm_32bit
      as_mov_sreg:
	mov	ah,al
	and	al,1111b
	mov	[as_postbyte_register],al
	shr	ah,4
	cmp	ah,3
	if_not_equal	as_invalid_operand
	cmp	al,2
	if_equal	as_illegal_instruction
	dec	[as_postbyte_register]
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_equal	as_mov_sreg_mem
	cmp	al,10h
	if_not_equal	as_invalid_operand
      as_mov_sreg_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	or	ah,ah
	if_zero	as_mov_sreg_reg_size_ok
	cmp	ah,2
	if_not_equal	as_invalid_operand_size
	mov	bl,al
      as_mov_sreg_reg_size_ok:
	mov	[as_base_code],8Eh
	jmp	as_nomem_instruction_ready
      as_mov_sreg_mem:
	call	as_get_address
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_mov_sreg_mem_size_ok
	cmp	al,2
	if_not_equal	as_invalid_operand_size
      as_mov_sreg_mem_size_ok:
	mov	[as_base_code],8Eh
	jmp	as_instruction_ready
      as_mov_creg:
	lods	as_u8 [esi]
	mov	ah,al
	shr	ah,4
	cmp	ah,4
	if_above	as_invalid_operand
	add	ah,22h
	mov	[as_extended_code],ah
	and	al,1111b
	mov	[as_postbyte_register],al
	mov	[as_base_code],0Fh
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_register
	mov	bl,al
	cmp	ah,4
	if_not_equal	as_invalid_operand_size
	cmp	[as_postbyte_register],8
	if_not_equal	as_mov_creg_store
	cmp	[as_extended_code],22h
	if_not_equal	as_mov_creg_store
	mov	al,0F0h
	stos	as_u8 [edi]
	mov	[as_postbyte_register],0
      as_mov_creg_store:
	jmp	as_nomem_instruction_ready
      as_mov_creg_64bit:
	cmp	ah,8
	if_equal	as_mov_creg_store
	jmp	as_invalid_operand_size
as_test_instruction:
	mov	[as_base_code],84h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_test_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
      as_test_mem:
	call	as_get_address
	push	edx ebx ecx
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'('
	if_equal	as_test_mem_imm
	cmp	al,10h
	if_not_equal	as_invalid_operand
      as_test_mem_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	[as_postbyte_register],al
	pop	ecx ebx edx
	mov	al,ah
	cmp	al,1
	if_equal	as_test_mem_reg_8bit
	call	as_operand_autodetect
	inc	[as_base_code]
      as_test_mem_reg_8bit:
	jmp	as_instruction_ready
      as_test_mem_imm:
	mov	al,[as_operand_size]
	cmp	al,1
	if_below	as_test_mem_imm_nosize
	if_equal	as_test_mem_imm_8bit
	cmp	al,2
	if_equal	as_test_mem_imm_16bit
	cmp	al,4
	if_equal	as_test_mem_imm_32bit
	cmp	al,8
	if_not_equal	as_invalid_operand_size
      as_test_mem_imm_64bit:
	cmp	[as_size_declared],0
	if_not_equal	as_long_immediate_not_encodable
	call	as_operand_64bit
	call	as_get_simm32
	cmp	[as_value_type],4
	if_above_equal	as_long_immediate_not_encodable
	jmp	as_test_mem_imm_32bit_store
      as_test_mem_imm_nosize:
	call	as_recoverable_unknown_size
      as_test_mem_imm_8bit:
	call	as_get_byte_value
	mov	as_u8 [as_value],al
	mov	[as_postbyte_register],0
	mov	[as_base_code],0F6h
	pop	ecx ebx edx
	call	as_store_instruction_with_imm8
	jmp	as_instruction_assembled
      as_test_mem_imm_16bit:
	call	as_operand_16bit
	call	as_get_word_value
	mov	as_u16 [as_value],ax
	mov	[as_postbyte_register],0
	mov	[as_base_code],0F7h
	pop	ecx ebx edx
	call	as_store_instruction_with_imm16
	jmp	as_instruction_assembled
      as_test_mem_imm_32bit:
	call	as_operand_32bit
	call	as_get_dword_value
      as_test_mem_imm_32bit_store:
	mov	as_u32 [as_value],eax
	mov	[as_postbyte_register],0
	mov	[as_base_code],0F7h
	pop	ecx ebx edx
	call	as_store_instruction_with_imm32
	jmp	as_instruction_assembled
      as_test_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_equal	as_test_reg_mem
	cmp	al,'('
	if_equal	as_test_reg_imm
	cmp	al,10h
	if_not_equal	as_invalid_operand
      as_test_reg_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,[as_postbyte_register]
	mov	[as_postbyte_register],al
	mov	al,ah
	cmp	al,1
	if_equal	as_test_reg_reg_8bit
	call	as_operand_autodetect
	inc	[as_base_code]
      as_test_reg_reg_8bit:
	jmp	as_nomem_instruction_ready
      as_test_reg_imm:
	mov	al,[as_operand_size]
	cmp	al,1
	if_equal	as_test_reg_imm_8bit
	cmp	al,2
	if_equal	as_test_reg_imm_16bit
	cmp	al,4
	if_equal	as_test_reg_imm_32bit
	cmp	al,8
	if_not_equal	as_invalid_operand_size
      as_test_reg_imm_64bit:
	cmp	[as_size_declared],0
	if_not_equal	as_long_immediate_not_encodable
	call	as_operand_64bit
	call	as_get_simm32
	cmp	[as_value_type],4
	if_above_equal	as_long_immediate_not_encodable
	jmp	as_test_reg_imm_32bit_store
      as_test_reg_imm_8bit:
	call	as_get_byte_value
	mov	dl,al
	mov	bl,[as_postbyte_register]
	mov	[as_postbyte_register],0
	mov	[as_base_code],0F6h
	or	bl,bl
	if_zero	as_test_al_imm
	call	as_store_nomem_instruction
	mov	al,dl
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
      as_test_al_imm:
	mov	[as_base_code],0A8h
	call	as_store_classic_instruction_code
	mov	al,dl
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
      as_test_reg_imm_16bit:
	call	as_operand_16bit
	call	as_get_word_value
	mov	dx,ax
	mov	bl,[as_postbyte_register]
	mov	[as_postbyte_register],0
	mov	[as_base_code],0F7h
	or	bl,bl
	if_zero	as_test_ax_imm
	call	as_store_nomem_instruction
	mov	ax,dx
	call	as_mark_relocation
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
      as_test_ax_imm:
	mov	[as_base_code],0A9h
	call	as_store_classic_instruction_code
	mov	ax,dx
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
      as_test_reg_imm_32bit:
	call	as_operand_32bit
	call	as_get_dword_value
      as_test_reg_imm_32bit_store:
	mov	edx,eax
	mov	bl,[as_postbyte_register]
	mov	[as_postbyte_register],0
	mov	[as_base_code],0F7h
	or	bl,bl
	if_zero	as_test_eax_imm
	call	as_store_nomem_instruction
	mov	eax,edx
	call	as_mark_relocation
	stos	as_u32 [edi]
	jmp	as_instruction_assembled
      as_test_eax_imm:
	mov	[as_base_code],0A9h
	call	as_store_classic_instruction_code
	mov	eax,edx
	stos	as_u32 [edi]
	jmp	as_instruction_assembled
      as_test_reg_mem:
	call	as_get_address
	mov	al,[as_operand_size]
	cmp	al,1
	if_equal	as_test_reg_mem_8bit
	call	as_operand_autodetect
	inc	[as_base_code]
      as_test_reg_mem_8bit:
	jmp	as_instruction_ready
as_xchg_instruction:
	mov	[as_base_code],86h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_xchg_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
      as_xchg_mem:
	call	as_get_address
	push	edx ebx ecx
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_test_mem_reg
	jmp	as_invalid_operand
      as_xchg_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_equal	as_test_reg_mem
	cmp	al,10h
	if_not_equal	as_invalid_operand
      as_xchg_reg_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	mov	al,ah
	cmp	al,1
	if_equal	as_xchg_reg_reg_8bit
	call	as_operand_autodetect
	cmp	[as_postbyte_register],0
	if_equal	as_xchg_ax_reg
	or	bl,bl
	if_not_zero	as_xchg_reg_reg_store
	mov	bl,[as_postbyte_register]
      as_xchg_ax_reg:
	jmp	as_xchg_ax_reg_ok
	cmp	ah,4
	if_not_equal	as_xchg_ax_reg_ok
	or	bl,bl
	if_zero	as_xchg_reg_reg_store
      as_xchg_ax_reg_ok:
	test	bl,1000b
	if_zero	as_xchg_ax_reg_store
	or	[as_rex_prefix],41h
	and	bl,111b
      as_xchg_ax_reg_store:
	add	bl,90h
	mov	[as_base_code],bl
	call	as_store_classic_instruction_code
	jmp	as_instruction_assembled
      as_xchg_reg_reg_store:
	inc	[as_base_code]
      as_xchg_reg_reg_8bit:
	jmp	as_nomem_instruction_ready
as_push_instruction:
	mov	[as_push_size],al
      as_push_next:
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_push_reg
	cmp	al,'('
	if_equal	as_push_imm
	cmp	al,'['
	if_not_equal	as_invalid_operand
      as_push_mem:
	call	as_get_address
	mov	al,[as_operand_size]
	mov	ah,[as_push_size]
	cmp	al,2
	if_equal	as_push_mem_16bit
	cmp	al,4
	if_equal	as_push_mem_32bit
	cmp	al,8
	if_equal	as_push_mem_64bit
	or	al,al
	if_not_zero	as_invalid_operand_size
	cmp	ah,2
	if_equal	as_push_mem_16bit
	cmp	ah,4
	if_equal	as_push_mem_32bit
	cmp	ah,8
	if_equal	as_push_mem_64bit
	call	as_recoverable_unknown_size
	jmp	as_push_mem_store
      as_push_mem_16bit:
	test	ah,not 2
	if_not_zero	as_invalid_operand_size
	call	as_operand_16bit
	jmp	as_push_mem_store
      as_push_mem_32bit:
	test	ah,not 4
	if_not_zero	as_invalid_operand_size
	call	as_operand_32bit
	jmp	as_push_mem_store
      as_push_mem_64bit:
	test	ah,not 8
	if_not_zero	as_invalid_operand_size
	jmp	as_illegal_instruction
      as_push_mem_store:
	mov	[as_base_code],0FFh
	mov	[as_postbyte_register],110b
	call	as_store_instruction
	jmp	as_push_done
      as_push_reg:
	lods	as_u8 [esi]
	mov	ah,al
	sub	ah,10h
	and	ah,al
	test	ah,0F0h
	if_not_zero	as_push_sreg
	call	as_convert_register
	test	al,1000b
	if_zero	as_push_reg_ok
	or	[as_rex_prefix],41h
	and	al,111b
      as_push_reg_ok:
	add	al,50h
	mov	[as_base_code],al
	mov	al,ah
	mov	ah,[as_push_size]
	cmp	al,2
	if_equal	as_push_reg_16bit
	cmp	al,4
	if_equal	as_push_reg_32bit
	cmp	al,8
	if_not_equal	as_invalid_operand_size
      as_push_reg_64bit:
	test	ah,not 8
	if_not_zero	as_invalid_operand_size
	jmp	as_illegal_instruction
	jmp	as_push_reg_store
      as_push_reg_32bit:
	test	ah,not 4
	if_not_zero	as_invalid_operand_size
	call	as_operand_32bit
	jmp	as_push_reg_store
      as_push_reg_16bit:
	test	ah,not 2
	if_not_zero	as_invalid_operand_size
	call	as_operand_16bit
      as_push_reg_store:
	call	as_store_classic_instruction_code
	jmp	as_push_done
      as_push_sreg:
	mov	bl,al
	mov	dl,[as_operand_size]
	mov	dh,[as_push_size]
	cmp	dl,2
	if_equal	as_push_sreg16
	cmp	dl,4
	if_equal	as_push_sreg32
	cmp	dl,8
	if_equal	as_push_sreg64
	or	dl,dl
	if_not_zero	as_invalid_operand_size
	cmp	dh,2
	if_equal	as_push_sreg16
	cmp	dh,4
	if_equal	as_push_sreg32
	cmp	dh,8
	if_equal	as_push_sreg64
	jmp	as_push_sreg_store
      as_push_sreg16:
	test	dh,not 2
	if_not_zero	as_invalid_operand_size
	call	as_operand_16bit
	jmp	as_push_sreg_store
      as_push_sreg32:
	test	dh,not 4
	if_not_zero	as_invalid_operand_size
	call	as_operand_32bit
	jmp	as_push_sreg_store
      as_push_sreg64:
	test	dh,not 8
	if_not_zero	as_invalid_operand_size
	jmp	as_illegal_instruction
      as_push_sreg_store:
	mov	al,bl
	cmp	al,40h
	if_above_equal	as_invalid_operand
	sub	al,31h
	if_carry	as_invalid_operand
	cmp	al,4
	if_above_equal	as_push_sreg_386
	shl	al,3
	add	al,6
	mov	[as_base_code],al
	jmp	as_push_reg_store
      as_push_sreg_386:
	sub	al,4
	shl	al,3
	add	al,0A0h
	mov	[as_extended_code],al
	mov	[as_base_code],0Fh
	jmp	as_push_reg_store
      as_push_imm:
	mov	al,[as_operand_size]
	mov	ah,[as_push_size]
	or	al,al
	if_equal	as_push_imm_size_ok
	or	ah,ah
	if_equal	as_push_imm_size_ok
	cmp	al,ah
	if_not_equal	as_invalid_operand_size
      as_push_imm_size_ok:
	cmp	al,2
	if_equal	as_push_imm_16bit
	cmp	al,4
	if_equal	as_push_imm_32bit
	cmp	al,8
	if_equal	as_push_imm_64bit
	cmp	ah,2
	if_equal	as_push_imm_optimized_16bit
	cmp	ah,4
	if_equal	as_push_imm_optimized_32bit
	cmp	ah,8
	if_equal	as_push_imm_optimized_64bit
	or	al,al
	if_not_zero	as_invalid_operand_size
	cmp	[as_code_type],16
	if_equal	as_push_imm_optimized_16bit
	cmp	[as_code_type],32
	if_equal	as_push_imm_optimized_32bit
      as_push_imm_optimized_64bit:
	jmp	as_illegal_instruction
	call	as_get_simm32
	mov	edx,eax
	cmp	[as_value_type],0
	if_not_equal	as_push_imm_32bit_store
	cmp	eax,-80h
	if_less	as_push_imm_32bit_store
	cmp	eax,80h
	if_greater_equal	as_push_imm_32bit_store
	jmp	as_push_imm_8bit
      as_push_imm_optimized_32bit:
	call	as_get_dword_value
	mov	edx,eax
	call	as_operand_32bit
	cmp	[as_value_type],0
	if_not_equal	as_push_imm_32bit_store
	cmp	eax,-80h
	if_less	as_push_imm_32bit_store
	cmp	eax,80h
	if_greater_equal	as_push_imm_32bit_store
	jmp	as_push_imm_8bit
      as_push_imm_optimized_16bit:
	call	as_get_word_value
	mov	dx,ax
	call	as_operand_16bit
	cmp	[as_value_type],0
	if_not_equal	as_push_imm_16bit_store
	cmp	ax,-80h
	if_less	as_push_imm_16bit_store
	cmp	ax,80h
	if_greater_equal	as_push_imm_16bit_store
      as_push_imm_8bit:
	mov	ah,al
	mov	[as_base_code],6Ah
	call	as_store_classic_instruction_code
	mov	al,ah
	stos	as_u8 [edi]
	jmp	as_push_done
      as_push_imm_16bit:
	call	as_get_word_value
	mov	dx,ax
	call	as_operand_16bit
      as_push_imm_16bit_store:
	mov	[as_base_code],68h
	call	as_store_classic_instruction_code
	mov	ax,dx
	call	as_mark_relocation
	stos	as_u16 [edi]
	jmp	as_push_done
      as_push_imm_64bit:
	jmp	as_illegal_instruction
	call	as_get_simm32
	mov	edx,eax
	jmp	as_push_imm_32bit_store
      as_push_imm_32bit:
	call	as_get_dword_value
	mov	edx,eax
	call	as_operand_32bit
      as_push_imm_32bit_store:
	mov	[as_base_code],68h
	call	as_store_classic_instruction_code
	mov	eax,edx
	call	as_mark_relocation
	stos	as_u32 [edi]
      as_push_done:
	lods	as_u8 [esi]
	dec	esi
	cmp	al,0Fh
	if_equal	as_instruction_assembled
	or	al,al
	if_zero	as_instruction_assembled
;	 mov	 [as_operand_size],0
;	 mov	 [as_operand_flags],0
;	 mov	 [as_operand_prefix],0
;	 mov	 [as_rex_prefix],0
	and	as_u32 [as_operand_size],0
	jmp	as_push_next
as_pop_instruction:
	mov	[as_push_size],al
      as_pop_next:
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_pop_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
      as_pop_mem:
	call	as_get_address
	mov	al,[as_operand_size]
	mov	ah,[as_push_size]
	cmp	al,2
	if_equal	as_pop_mem_16bit
	cmp	al,4
	if_equal	as_pop_mem_32bit
	cmp	al,8
	if_equal	as_pop_mem_64bit
	or	al,al
	if_not_zero	as_invalid_operand_size
	cmp	ah,2
	if_equal	as_pop_mem_16bit
	cmp	ah,4
	if_equal	as_pop_mem_32bit
	cmp	ah,8
	if_equal	as_pop_mem_64bit
	call	as_recoverable_unknown_size
	jmp	as_pop_mem_store
      as_pop_mem_16bit:
	test	ah,not 2
	if_not_zero	as_invalid_operand_size
	call	as_operand_16bit
	jmp	as_pop_mem_store
      as_pop_mem_32bit:
	test	ah,not 4
	if_not_zero	as_invalid_operand_size
	call	as_operand_32bit
	jmp	as_pop_mem_store
      as_pop_mem_64bit:
	test	ah,not 8
	if_not_zero	as_invalid_operand_size
	jmp	as_illegal_instruction
      as_pop_mem_store:
	mov	[as_base_code],08Fh
	mov	[as_postbyte_register],0
	call	as_store_instruction
	jmp	as_pop_done
      as_pop_reg:
	lods	as_u8 [esi]
	mov	ah,al
	sub	ah,10h
	and	ah,al
	test	ah,0F0h
	if_not_zero	as_pop_sreg
	call	as_convert_register
	test	al,1000b
	if_zero	as_pop_reg_ok
	or	[as_rex_prefix],41h
	and	al,111b
      as_pop_reg_ok:
	add	al,58h
	mov	[as_base_code],al
	mov	al,ah
	mov	ah,[as_push_size]
	cmp	al,2
	if_equal	as_pop_reg_16bit
	cmp	al,4
	if_equal	as_pop_reg_32bit
	cmp	al,8
	if_equal	as_pop_reg_64bit
	jmp	as_invalid_operand_size
      as_pop_reg_64bit:
	test	ah,not 8
	if_not_zero	as_invalid_operand_size
	jmp	as_illegal_instruction
	jmp	as_pop_reg_store
      as_pop_reg_32bit:
	test	ah,not 4
	if_not_zero	as_invalid_operand_size
	call	as_operand_32bit
	jmp	as_pop_reg_store
      as_pop_reg_16bit:
	test	ah,not 2
	if_not_zero	as_invalid_operand_size
	call	as_operand_16bit
      as_pop_reg_store:
	call	as_store_classic_instruction_code
      as_pop_done:
	lods	as_u8 [esi]
	dec	esi
	cmp	al,0Fh
	if_equal	as_instruction_assembled
	or	al,al
	if_zero	as_instruction_assembled
;	 mov	 [as_operand_size],0
;	 mov	 [as_operand_flags],0
;	 mov	 [as_operand_prefix],0
;	 mov	 [as_rex_prefix],0
	and	as_u32 [as_operand_size],0
	jmp	as_pop_next
      as_pop_sreg:
	mov	dl,[as_operand_size]
	mov	dh,[as_push_size]
	cmp	al,32h
	if_equal	as_pop_cs
	mov	bl,al
	cmp	dl,2
	if_equal	as_pop_sreg16
	cmp	dl,4
	if_equal	as_pop_sreg32
	cmp	dl,8
	if_equal	as_pop_sreg64
	or	dl,dl
	if_not_zero	as_invalid_operand_size
	cmp	dh,2
	if_equal	as_pop_sreg16
	cmp	dh,4
	if_equal	as_pop_sreg32
	cmp	dh,8
	if_equal	as_pop_sreg64
	jmp	as_pop_sreg_store
      as_pop_sreg16:
	test	dh,not 2
	if_not_zero	as_invalid_operand_size
	call	as_operand_16bit
	jmp	as_pop_sreg_store
      as_pop_sreg32:
	test	dh,not 4
	if_not_zero	as_invalid_operand_size
	call	as_operand_32bit
	jmp	as_pop_sreg_store
      as_pop_sreg64:
	test	dh,not 8
	if_not_zero	as_invalid_operand_size
	jmp	as_illegal_instruction
      as_pop_sreg_store:
	mov	al,bl
	cmp	al,40h
	if_above_equal	as_invalid_operand
	sub	al,31h
	if_carry	as_invalid_operand
	cmp	al,4
	if_above_equal	as_pop_sreg_386
	shl	al,3
	add	al,7
	mov	[as_base_code],al
	jmp	as_pop_reg_store
      as_pop_cs:
	cmp	[as_code_type],16
	if_not_equal	as_illegal_instruction
	cmp	dl,2
	if_equal	as_pop_cs_store
	or	dl,dl
	if_not_zero	as_invalid_operand_size
	cmp	dh,2
	if_equal	as_pop_cs_store
	or	dh,dh
	if_not_zero	as_illegal_instruction
      as_pop_cs_store:
	test	dh,not 2
	if_not_zero	as_invalid_operand_size
	mov	al,0Fh
	stos	as_u8 [edi]
	jmp	as_pop_done
      as_pop_sreg_386:
	sub	al,4
	shl	al,3
	add	al,0A1h
	mov	[as_extended_code],al
	mov	[as_base_code],0Fh
	jmp	as_pop_reg_store
as_inc_instruction:
	mov	[as_base_code],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_inc_reg
	cmp	al,'['
	if_equal	as_inc_mem
	if_not_equal	as_invalid_operand
      as_inc_mem:
	call	as_get_address
	mov	al,[as_operand_size]
	cmp	al,1
	if_equal	as_inc_mem_8bit
	if_below	as_inc_mem_nosize
	call	as_operand_autodetect
	mov	al,0FFh
	xchg	al,[as_base_code]
	mov	[as_postbyte_register],al
	jmp	as_instruction_ready
      as_inc_mem_nosize:
	call	as_recoverable_unknown_size
      as_inc_mem_8bit:
	mov	al,0FEh
	xchg	al,[as_base_code]
	mov	[as_postbyte_register],al
	jmp	as_instruction_ready
      as_inc_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	mov	al,0FEh
	xchg	al,[as_base_code]
	mov	[as_postbyte_register],al
	mov	al,ah
	cmp	al,1
	if_equal	as_inc_reg_8bit
	call	as_operand_autodetect
	mov	al,[as_postbyte_register]
	shl	al,3
	add	al,bl
	add	al,40h
	mov	[as_base_code],al
	call	as_store_classic_instruction_code
	jmp	as_instruction_assembled
      as_inc_reg_long_form:
	inc	[as_base_code]
      as_inc_reg_8bit:
	jmp	as_nomem_instruction_ready
as_set_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_set_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
      as_set_mem:
	call	as_get_address
	cmp	[as_operand_size],1
	if_above	as_invalid_operand_size
	mov	[as_postbyte_register],0
	jmp	as_instruction_ready
      as_set_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	cmp	ah,1
	if_not_equal	as_invalid_operand_size
	mov	bl,al
	mov	[as_postbyte_register],0
	jmp	as_nomem_instruction_ready
as_arpl_instruction:
	mov	[as_base_code],63h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_arpl_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_register
	mov	[as_postbyte_register],al
	cmp	ah,2
	if_not_equal	as_invalid_operand_size
	jmp	as_instruction_ready
      as_arpl_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	cmp	ah,2
	if_not_equal	as_invalid_operand_size
	mov	bl,al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_register
	mov	[as_postbyte_register],al
	jmp	as_nomem_instruction_ready
as_bound_instruction:
	call	as_take_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	cmp	al,2
	if_equal	as_bound_store
	cmp	al,4
	if_not_equal	as_invalid_operand_size
      as_bound_store:
	call	as_operand_autodetect
	mov	[as_base_code],62h
	jmp	as_instruction_ready
as_enter_instruction:
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	ah,2
	if_equal	as_enter_imm16_size_ok
	or	ah,ah
	if_not_zero	as_invalid_operand_size
      as_enter_imm16_size_ok:
	cmp	al,'('
	if_not_equal	as_invalid_operand
	call	as_get_word_value
	cmp	[as_next_pass_needed],0
	if_not_equal	as_enter_imm16_ok
	cmp	[as_value_type],0
	if_not_equal	as_invalid_use_of_symbol
	test	eax,eax
	if_sign	as_value_out_of_range
      as_enter_imm16_ok:
	push	eax
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	ah,1
	if_equal	as_enter_imm8_size_ok
	or	ah,ah
	if_not_zero	as_invalid_operand_size
      as_enter_imm8_size_ok:
	cmp	al,'('
	if_not_equal	as_invalid_operand
	call	as_get_byte_value
	cmp	[as_next_pass_needed],0
	if_not_equal	as_enter_imm8_ok
	test	eax,eax
	if_sign	as_value_out_of_range
      as_enter_imm8_ok:
	mov	dl,al
	pop	ebx
	mov	al,0C8h
	stos	as_u8 [edi]
	mov	ax,bx
	stos	as_u16 [edi]
	mov	al,dl
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
as_ret_instruction_only64:
	jmp	as_illegal_instruction
as_ret_instruction_32bit_except64:
as_ret_instruction_32bit:
	call	as_operand_32bit
	jmp	as_ret_instruction
as_ret_instruction_16bit:
	call	as_operand_16bit
	jmp	as_ret_instruction
as_ret_instruction:
	and	[as_prefix_flags],not 10h
      as_ret_common:
	mov	[as_base_code],al
	lods	as_u8 [esi]
	dec	esi
	or	al,al
	if_zero	as_simple_ret
	cmp	al,0Fh
	if_equal	as_simple_ret
	lods	as_u8 [esi]
	call	as_get_size_operator
	or	ah,ah
	if_zero	as_ret_imm
	cmp	ah,2
	if_equal	as_ret_imm
	jmp	as_invalid_operand_size
      as_ret_imm:
	cmp	al,'('
	if_not_equal	as_invalid_operand
	call	as_get_word_value
	cmp	[as_next_pass_needed],0
	if_not_equal	as_ret_imm_ok
	cmp	[as_value_type],0
	if_not_equal	as_invalid_use_of_symbol
	test	eax,eax
	if_sign	as_value_out_of_range
      as_ret_imm_ok:
	cmp	[as_size_declared],0
	if_not_equal	as_ret_imm_store
	or	ax,ax
	if_zero	as_simple_ret
      as_ret_imm_store:
	mov	dx,ax
	call	as_store_classic_instruction_code
	mov	ax,dx
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
      as_simple_ret:
	inc	[as_base_code]
	call	as_store_classic_instruction_code
	jmp	as_instruction_assembled
as_retf_instruction:
	jmp	as_ret_common
as_retf_instruction_64bit:
	call	as_operand_64bit
	jmp	as_ret_common
as_retf_instruction_32bit:
	call	as_operand_32bit
	jmp	as_ret_common
as_retf_instruction_16bit:
	call	as_operand_16bit
	jmp	as_ret_common
as_lea_instruction:
	mov	[as_base_code],8Dh
	call	as_take_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	xor	al,al
	xchg	al,[as_operand_size]
	push	eax
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	or	[as_operand_flags],1
	call	as_get_address
	pop	eax
	mov	[as_operand_size],al
	call	as_operand_autodetect
	jmp	as_instruction_ready
as_ls_instruction:
	or	al,al
	if_zero	as_les_instruction
	cmp	al,3
	if_zero	as_lds_instruction
	add	al,0B0h
	mov	[as_extended_code],al
	mov	[as_base_code],0Fh
	jmp	as_ls_code_ok
      as_les_instruction:
	mov	[as_base_code],0C4h
	jmp	as_ls_short_code
      as_lds_instruction:
	mov	[as_base_code],0C5h
      as_ls_short_code:
      as_ls_code_ok:
	call	as_take_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	add	[as_operand_size],2
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	cmp	al,4
	if_equal	as_ls_16bit
	cmp	al,6
	if_equal	as_ls_32bit
	cmp	al,10
	if_equal	as_ls_64bit
	jmp	as_invalid_operand_size
      as_ls_16bit:
	call	as_operand_16bit
	jmp	as_instruction_ready
      as_ls_32bit:
	call	as_operand_32bit
	jmp	as_instruction_ready
      as_ls_64bit:
	call	as_operand_64bit
	jmp	as_instruction_ready
as_sh_instruction:
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_sh_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
      as_sh_mem:
	call	as_get_address
	push	edx ebx ecx
	mov	al,[as_operand_size]
	push	eax
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'('
	if_equal	as_sh_mem_imm
	cmp	al,10h
	if_not_equal	as_invalid_operand
      as_sh_mem_reg:
	lods	as_u8 [esi]
	cmp	al,11h
	if_not_equal	as_invalid_operand
	pop	eax ecx ebx edx
	cmp	al,1
	if_equal	as_sh_mem_cl_8bit
	if_below	as_sh_mem_cl_nosize
	call	as_operand_autodetect
	mov	[as_base_code],0D3h
	jmp	as_instruction_ready
      as_sh_mem_cl_nosize:
	call	as_recoverable_unknown_size
      as_sh_mem_cl_8bit:
	mov	[as_base_code],0D2h
	jmp	as_instruction_ready
      as_sh_mem_imm:
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_sh_mem_imm_size_ok
	cmp	al,1
	if_not_equal	as_invalid_operand_size
      as_sh_mem_imm_size_ok:
	call	as_get_byte_value
	mov	as_u8 [as_value],al
	pop	eax ecx ebx edx
	cmp	al,1
	if_equal	as_sh_mem_imm_8bit
	if_below	as_sh_mem_imm_nosize
	call	as_operand_autodetect
	cmp	as_u8 [as_value],1
	if_equal	as_sh_mem_1
	mov	[as_base_code],0C1h
	call	as_store_instruction_with_imm8
	jmp	as_instruction_assembled
      as_sh_mem_1:
	mov	[as_base_code],0D1h
	jmp	as_instruction_ready
      as_sh_mem_imm_nosize:
	call	as_recoverable_unknown_size
      as_sh_mem_imm_8bit:
	cmp	as_u8 [as_value],1
	if_equal	as_sh_mem_1_8bit
	mov	[as_base_code],0C0h
	call	as_store_instruction_with_imm8
	jmp	as_instruction_assembled
      as_sh_mem_1_8bit:
	mov	[as_base_code],0D0h
	jmp	as_instruction_ready
      as_sh_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bx,ax
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'('
	if_equal	as_sh_reg_imm
	cmp	al,10h
	if_not_equal	as_invalid_operand
      as_sh_reg_reg:
	lods	as_u8 [esi]
	cmp	al,11h
	if_not_equal	as_invalid_operand
	mov	al,bh
	cmp	al,1
	if_equal	as_sh_reg_cl_8bit
	call	as_operand_autodetect
	mov	[as_base_code],0D3h
	jmp	as_nomem_instruction_ready
      as_sh_reg_cl_8bit:
	mov	[as_base_code],0D2h
	jmp	as_nomem_instruction_ready
      as_sh_reg_imm:
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_sh_reg_imm_size_ok
	cmp	al,1
	if_not_equal	as_invalid_operand_size
      as_sh_reg_imm_size_ok:
	push	ebx
	call	as_get_byte_value
	mov	dl,al
	pop	ebx
	mov	al,bh
	cmp	al,1
	if_equal	as_sh_reg_imm_8bit
	call	as_operand_autodetect
	cmp	dl,1
	if_equal	as_sh_reg_1
	mov	[as_base_code],0C1h
	call	as_store_nomem_instruction
	mov	al,dl
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
      as_sh_reg_1:
	mov	[as_base_code],0D1h
	jmp	as_nomem_instruction_ready
      as_sh_reg_imm_8bit:
	cmp	dl,1
	if_equal	as_sh_reg_1_8bit
	mov	[as_base_code],0C0h
	call	as_store_nomem_instruction
	mov	al,dl
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
      as_sh_reg_1_8bit:
	mov	[as_base_code],0D0h
	jmp	as_nomem_instruction_ready
as_shd_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_shd_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
      as_shd_mem:
	call	as_get_address
	push	edx ebx ecx
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	mov	al,ah
	mov	[as_operand_size],0
	push	eax
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'('
	if_equal	as_shd_mem_reg_imm
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	cmp	al,11h
	if_not_equal	as_invalid_operand
	pop	eax ecx ebx edx
	call	as_operand_autodetect
	inc	[as_extended_code]
	jmp	as_instruction_ready
      as_shd_mem_reg_imm:
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_shd_mem_reg_imm_size_ok
	cmp	al,1
	if_not_equal	as_invalid_operand_size
      as_shd_mem_reg_imm_size_ok:
	call	as_get_byte_value
	mov	as_u8 [as_value],al
	pop	eax ecx ebx edx
	call	as_operand_autodetect
	call	as_store_instruction_with_imm8
	jmp	as_instruction_assembled
      as_shd_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_register
	mov	bl,[as_postbyte_register]
	mov	[as_postbyte_register],al
	mov	al,ah
	push	eax ebx
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'('
	if_equal	as_shd_reg_reg_imm
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	cmp	al,11h
	if_not_equal	as_invalid_operand
	pop	ebx eax
	call	as_operand_autodetect
	inc	[as_extended_code]
	jmp	as_nomem_instruction_ready
      as_shd_reg_reg_imm:
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_shd_reg_reg_imm_size_ok
	cmp	al,1
	if_not_equal	as_invalid_operand_size
      as_shd_reg_reg_imm_size_ok:
	call	as_get_byte_value
	mov	dl,al
	pop	ebx eax
	call	as_operand_autodetect
	call	as_store_nomem_instruction
	mov	al,dl
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
as_movx_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	call	as_take_register
	mov	[as_postbyte_register],al
	mov	al,ah
	push	eax
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_movx_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	pop	eax
	mov	ah,[as_operand_size]
	or	ah,ah
	if_zero	as_movx_unknown_size
	cmp	ah,al
	if_above_equal	as_invalid_operand_size
	cmp	ah,1
	if_equal	as_movx_mem_store
	cmp	ah,2
	if_not_equal	as_invalid_operand_size
	inc	[as_extended_code]
      as_movx_mem_store:
	call	as_operand_autodetect
	jmp	as_instruction_ready
      as_movx_unknown_size:
	cmp	al,2
	if_equal	as_movx_mem_store
	call	as_recoverable_unknown_size
	jmp	as_movx_mem_store
      as_movx_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	pop	ebx
	xchg	bl,al
	cmp	ah,al
	if_above_equal	as_invalid_operand_size
	cmp	ah,1
	if_equal	as_movx_reg_8bit
	cmp	ah,2
	if_equal	as_movx_reg_16bit
	jmp	as_invalid_operand_size
      as_movx_reg_8bit:
	call	as_operand_autodetect
	jmp	as_nomem_instruction_ready
      as_movx_reg_16bit:
	call	as_operand_autodetect
	inc	[as_extended_code]
	jmp	as_nomem_instruction_ready
as_movsxd_instruction:
	mov	[as_base_code],al
	call	as_take_register
	mov	[as_postbyte_register],al
	cmp	ah,8
	if_not_equal	as_invalid_operand_size
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_movsxd_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	cmp	[as_operand_size],4
	if_equal	as_movsxd_mem_store
	cmp	[as_operand_size],0
	if_not_equal	as_invalid_operand_size
      as_movsxd_mem_store:
	call	as_operand_64bit
	jmp	as_instruction_ready
      as_movsxd_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	cmp	ah,4
	if_not_equal	as_invalid_operand_size
	mov	bl,al
	call	as_operand_64bit
	jmp	as_nomem_instruction_ready
as_bt_instruction:
	mov	[as_postbyte_register],al
	shl	al,3
	add	al,83h
	mov	[as_extended_code],al
	mov	[as_base_code],0Fh
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_bt_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	push	eax ebx ecx
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	cmp	as_u8 [esi],'('
	if_equal	as_bt_mem_imm
	cmp	as_u8 [esi],11h
	if_not_equal	as_bt_mem_reg
	cmp	as_u8 [esi+2],'('
	if_equal	as_bt_mem_imm
      as_bt_mem_reg:
	call	as_take_register
	mov	[as_postbyte_register],al
	pop	ecx ebx edx
	mov	al,ah
	call	as_operand_autodetect
	jmp	as_instruction_ready
      as_bt_mem_imm:
	xor	al,al
	xchg	al,[as_operand_size]
	push	eax
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'('
	if_not_equal	as_invalid_operand
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_bt_mem_imm_size_ok
	cmp	al,1
	if_not_equal	as_invalid_operand_size
      as_bt_mem_imm_size_ok:
	call	as_get_byte_value
	mov	as_u8 [as_value],al
	pop	eax
	or	al,al
	if_zero	as_bt_mem_imm_nosize
	call	as_operand_autodetect
      as_bt_mem_imm_store:
	pop	ecx ebx edx
	mov	[as_extended_code],0BAh
	call	as_store_instruction_with_imm8
	jmp	as_instruction_assembled
      as_bt_mem_imm_nosize:
	call	as_recoverable_unknown_size
	jmp	as_bt_mem_imm_store
      as_bt_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	cmp	as_u8 [esi],'('
	if_equal	as_bt_reg_imm
	cmp	as_u8 [esi],11h
	if_not_equal	as_bt_reg_reg
	cmp	as_u8 [esi+2],'('
	if_equal	as_bt_reg_imm
      as_bt_reg_reg:
	call	as_take_register
	mov	[as_postbyte_register],al
	mov	al,ah
	call	as_operand_autodetect
	jmp	as_nomem_instruction_ready
      as_bt_reg_imm:
	xor	al,al
	xchg	al,[as_operand_size]
	push	eax ebx
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'('
	if_not_equal	as_invalid_operand
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_bt_reg_imm_size_ok
	cmp	al,1
	if_not_equal	as_invalid_operand_size
      as_bt_reg_imm_size_ok:
	call	as_get_byte_value
	mov	as_u8 [as_value],al
	pop	ebx eax
	call	as_operand_autodetect
      as_bt_reg_imm_store:
	mov	[as_extended_code],0BAh
	call	as_store_nomem_instruction
	mov	al,as_u8 [as_value]
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
as_bs_instruction:
	mov	[as_extended_code],al
	mov	[as_base_code],0Fh
	call	as_get_reg_mem
	if_carry	as_bs_reg_reg
	mov	al,[as_operand_size]
	call	as_operand_autodetect
	jmp	as_instruction_ready
      as_bs_reg_reg:
	mov	al,ah
	call	as_operand_autodetect
	jmp	as_nomem_instruction_ready
      as_get_reg_mem:
	call	as_take_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_get_reg_reg
	cmp	al,'['
	if_not_equal	as_invalid_argument
	call	as_get_address
	clear_carry
	ret
      as_get_reg_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	set_carry
	ret
as_ud_instruction:
	mov	[as_extended_code],al
	mov	[as_base_code],0Fh
	call	as_get_reg_mem
	if_carry	as_ud_reg_reg
	cmp	[as_operand_size],4
	if_not_equal	as_invalid_operand_size
	jmp	as_instruction_ready
      as_ud_reg_reg:
	cmp	ah,4
	if_not_equal	as_invalid_operand_size
	jmp	as_nomem_instruction_ready

as_imul_instruction:
	mov	[as_base_code],0F6h
	mov	[as_postbyte_register],5
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_imul_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
      as_imul_mem:
	call	as_get_address
	mov	al,[as_operand_size]
	cmp	al,1
	if_equal	as_imul_mem_8bit
	if_below	as_imul_mem_nosize
	call	as_operand_autodetect
	inc	[as_base_code]
	jmp	as_instruction_ready
      as_imul_mem_nosize:
	call	as_recoverable_unknown_size
      as_imul_mem_8bit:
	jmp	as_instruction_ready
      as_imul_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	cmp	as_u8 [esi],','
	if_equal	as_imul_reg_
	mov	bl,al
	mov	al,ah
	cmp	al,1
	if_equal	as_imul_reg_8bit
	call	as_operand_autodetect
	inc	[as_base_code]
      as_imul_reg_8bit:
	jmp	as_nomem_instruction_ready
      as_imul_reg_:
	mov	[as_postbyte_register],al
	inc	esi
	cmp	as_u8 [esi],'('
	if_equal	as_imul_reg_imm
	cmp	as_u8 [esi],11h
	if_not_equal	as_imul_reg_noimm
	cmp	as_u8 [esi+2],'('
	if_equal	as_imul_reg_imm
      as_imul_reg_noimm:
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_imul_reg_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
      as_imul_reg_mem:
	call	as_get_address
	push	edx ebx ecx
	cmp	as_u8 [esi],','
	if_equal	as_imul_reg_mem_imm
	mov	al,[as_operand_size]
	call	as_operand_autodetect
	pop	ecx ebx edx
	mov	[as_base_code],0Fh
	mov	[as_extended_code],0AFh
	jmp	as_instruction_ready
      as_imul_reg_mem_imm:
	inc	esi
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'('
	if_not_equal	as_invalid_operand
	mov	al,[as_operand_size]
	cmp	al,2
	if_equal	as_imul_reg_mem_imm_16bit
	cmp	al,4
	if_equal	as_imul_reg_mem_imm_32bit
	cmp	al,8
	if_not_equal	as_invalid_operand_size
      as_imul_reg_mem_imm_64bit:
	cmp	[as_size_declared],0
	if_not_equal	as_long_immediate_not_encodable
	call	as_operand_64bit
	call	as_get_simm32
	cmp	[as_value_type],4
	if_above_equal	as_long_immediate_not_encodable
	jmp	as_imul_reg_mem_imm_32bit_ok
      as_imul_reg_mem_imm_16bit:
	call	as_operand_16bit
	call	as_get_word_value
	mov	as_u16 [as_value],ax
	cmp	[as_value_type],0
	if_not_equal	as_imul_reg_mem_imm_16bit_store
	cmp	[as_size_declared],0
	if_not_equal	as_imul_reg_mem_imm_16bit_store
	cmp	ax,-80h
	if_less	as_imul_reg_mem_imm_16bit_store
	cmp	ax,80h
	if_less	as_imul_reg_mem_imm_8bit_store
      as_imul_reg_mem_imm_16bit_store:
	pop	ecx ebx edx
	mov	[as_base_code],69h
	call	as_store_instruction_with_imm16
	jmp	as_instruction_assembled
      as_imul_reg_mem_imm_32bit:
	call	as_operand_32bit
	call	as_get_dword_value
      as_imul_reg_mem_imm_32bit_ok:
	mov	as_u32 [as_value],eax
	cmp	[as_value_type],0
	if_not_equal	as_imul_reg_mem_imm_32bit_store
	cmp	[as_size_declared],0
	if_not_equal	as_imul_reg_mem_imm_32bit_store
	cmp	eax,-80h
	if_less	as_imul_reg_mem_imm_32bit_store
	cmp	eax,80h
	if_less	as_imul_reg_mem_imm_8bit_store
      as_imul_reg_mem_imm_32bit_store:
	pop	ecx ebx edx
	mov	[as_base_code],69h
	call	as_store_instruction_with_imm32
	jmp	as_instruction_assembled
      as_imul_reg_mem_imm_8bit_store:
	pop	ecx ebx edx
	mov	[as_base_code],6Bh
	call	as_store_instruction_with_imm8
	jmp	as_instruction_assembled
      as_imul_reg_imm:
	mov	bl,[as_postbyte_register]
	dec	esi
	jmp	as_imul_reg_reg_imm
      as_imul_reg_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	cmp	as_u8 [esi],','
	if_equal	as_imul_reg_reg_imm
	mov	al,ah
	call	as_operand_autodetect
	mov	[as_base_code],0Fh
	mov	[as_extended_code],0AFh
	jmp	as_nomem_instruction_ready
      as_imul_reg_reg_imm:
	inc	esi
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'('
	if_not_equal	as_invalid_operand
	mov	al,[as_operand_size]
	cmp	al,2
	if_equal	as_imul_reg_reg_imm_16bit
	cmp	al,4
	if_equal	as_imul_reg_reg_imm_32bit
	cmp	al,8
	if_not_equal	as_invalid_operand_size
      as_imul_reg_reg_imm_64bit:
	cmp	[as_size_declared],0
	if_not_equal	as_long_immediate_not_encodable
	call	as_operand_64bit
	push	ebx
	call	as_get_simm32
	cmp	[as_value_type],4
	if_above_equal	as_long_immediate_not_encodable
	jmp	as_imul_reg_reg_imm_32bit_ok
      as_imul_reg_reg_imm_16bit:
	call	as_operand_16bit
	push	ebx
	call	as_get_word_value
	pop	ebx
	mov	dx,ax
	cmp	[as_value_type],0
	if_not_equal	as_imul_reg_reg_imm_16bit_store
	cmp	[as_size_declared],0
	if_not_equal	as_imul_reg_reg_imm_16bit_store
	cmp	ax,-80h
	if_less	as_imul_reg_reg_imm_16bit_store
	cmp	ax,80h
	if_less	as_imul_reg_reg_imm_8bit_store
      as_imul_reg_reg_imm_16bit_store:
	mov	[as_base_code],69h
	call	as_store_nomem_instruction
	mov	ax,dx
	call	as_mark_relocation
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
      as_imul_reg_reg_imm_32bit:
	call	as_operand_32bit
	push	ebx
	call	as_get_dword_value
      as_imul_reg_reg_imm_32bit_ok:
	pop	ebx
	mov	edx,eax
	cmp	[as_value_type],0
	if_not_equal	as_imul_reg_reg_imm_32bit_store
	cmp	[as_size_declared],0
	if_not_equal	as_imul_reg_reg_imm_32bit_store
	cmp	eax,-80h
	if_less	as_imul_reg_reg_imm_32bit_store
	cmp	eax,80h
	if_less	as_imul_reg_reg_imm_8bit_store
      as_imul_reg_reg_imm_32bit_store:
	mov	[as_base_code],69h
	call	as_store_nomem_instruction
	mov	eax,edx
	call	as_mark_relocation
	stos	as_u32 [edi]
	jmp	as_instruction_assembled
      as_imul_reg_reg_imm_8bit_store:
	mov	[as_base_code],6Bh
	call	as_store_nomem_instruction
	mov	al,dl
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
as_in_instruction:
	call	as_take_register
	or	al,al
	if_not_zero	as_invalid_operand
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	mov	al,ah
	push	eax
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'('
	if_equal	as_in_imm
	cmp	al,10h
	if_equal	as_in_reg
	jmp	as_invalid_operand
      as_in_reg:
	lods	as_u8 [esi]
	cmp	al,22h
	if_not_equal	as_invalid_operand
	pop	eax
	cmp	al,1
	if_equal	as_in_al_dx
	cmp	al,2
	if_equal	as_in_ax_dx
	cmp	al,4
	if_not_equal	as_invalid_operand_size
      as_in_ax_dx:
	call	as_operand_autodetect
	mov	[as_base_code],0EDh
	call	as_store_classic_instruction_code
	jmp	as_instruction_assembled
      as_in_al_dx:
	mov	al,0ECh
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
      as_in_imm:
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_in_imm_size_ok
	cmp	al,1
	if_not_equal	as_invalid_operand_size
      as_in_imm_size_ok:
	call	as_get_byte_value
	mov	dl,al
	pop	eax
	cmp	al,1
	if_equal	as_in_al_imm
	cmp	al,2
	if_equal	as_in_ax_imm
	cmp	al,4
	if_not_equal	as_invalid_operand_size
      as_in_ax_imm:
	call	as_operand_autodetect
	mov	[as_base_code],0E5h
	call	as_store_classic_instruction_code
	mov	al,dl
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
      as_in_al_imm:
	mov	al,0E4h
	stos	as_u8 [edi]
	mov	al,dl
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
as_out_instruction:
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'('
	if_equal	as_out_imm
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	cmp	al,22h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	mov	[as_operand_size],0
	call	as_take_register
	or	al,al
	if_not_zero	as_invalid_operand
	mov	al,ah
	cmp	al,1
	if_equal	as_out_dx_al
	cmp	al,2
	if_equal	as_out_dx_ax
	cmp	al,4
	if_not_equal	as_invalid_operand_size
      as_out_dx_ax:
	call	as_operand_autodetect
	mov	[as_base_code],0EFh
	call	as_store_classic_instruction_code
	jmp	as_instruction_assembled
      as_out_dx_al:
	mov	al,0EEh
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
      as_out_imm:
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_out_imm_size_ok
	cmp	al,1
	if_not_equal	as_invalid_operand_size
      as_out_imm_size_ok:
	call	as_get_byte_value
	mov	dl,al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	mov	[as_operand_size],0
	call	as_take_register
	or	al,al
	if_not_zero	as_invalid_operand
	mov	al,ah
	cmp	al,1
	if_equal	as_out_imm_al
	cmp	al,2
	if_equal	as_out_imm_ax
	cmp	al,4
	if_not_equal	as_invalid_operand_size
      as_out_imm_ax:
	call	as_operand_autodetect
	mov	[as_base_code],0E7h
	call	as_store_classic_instruction_code
	mov	al,dl
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
      as_out_imm_al:
	mov	al,0E6h
	stos	as_u8 [edi]
	mov	al,dl
	stos	as_u8 [edi]
	jmp	as_instruction_assembled

as_call_instruction:
	mov	[as_postbyte_register],10b
	mov	[as_base_code],0E8h
	mov	[as_extended_code],9Ah
	jmp	as_process_jmp
as_jmp_instruction:
	mov	[as_postbyte_register],100b
	mov	[as_base_code],0E9h
	mov	[as_extended_code],0EAh
      as_process_jmp:
	lods	as_u8 [esi]
	call	as_get_jump_operator
	test	[as_prefix_flags],10h
	if_zero	as_jmp_type_ok
	test	[as_jump_type],not 2
	if_not_zero	as_illegal_instruction
	mov	[as_jump_type],2
	and	[as_prefix_flags],not 10h
      as_jmp_type_ok:
	call	as_get_size_operator
	cmp	al,'('
	if_equal	as_jmp_imm
	mov	[as_base_code],0FFh
	cmp	al,10h
	if_equal	as_jmp_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
      as_jmp_mem:
	cmp	[as_jump_type],1
	if_equal	as_illegal_instruction
	call	as_get_address
	mov	edx,eax
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_jmp_mem_size_not_specified
	cmp	al,2
	if_equal	as_jmp_mem_16bit
	cmp	al,4
	if_equal	as_jmp_mem_32bit
	cmp	al,6
	if_equal	as_jmp_mem_48bit
	cmp	al,8
	if_equal	as_jmp_mem_64bit
	cmp	al,10
	if_equal	as_jmp_mem_80bit
	jmp	as_invalid_operand_size
      as_jmp_mem_size_not_specified:
	cmp	[as_jump_type],3
	if_equal	as_jmp_mem_far
	cmp	[as_jump_type],2
	if_equal	as_jmp_mem_near
	call	as_recoverable_unknown_size
      as_jmp_mem_near:
	cmp	[as_code_type],16
	if_equal	as_jmp_mem_16bit
	cmp	[as_code_type],32
	if_equal	as_jmp_mem_near_32bit
      as_jmp_mem_64bit:
	cmp	[as_jump_type],3
	if_equal	as_invalid_operand_size
	jmp	as_illegal_instruction
	jmp	as_instruction_ready
      as_jmp_mem_far:
	cmp	[as_code_type],16
	if_equal	as_jmp_mem_far_32bit
      as_jmp_mem_48bit:
	call	as_operand_32bit
      as_jmp_mem_far_store:
	cmp	[as_jump_type],2
	if_equal	as_invalid_operand_size
	inc	[as_postbyte_register]
	jmp	as_instruction_ready
      as_jmp_mem_80bit:
	call	as_operand_64bit
	jmp	as_jmp_mem_far_store
      as_jmp_mem_far_32bit:
	call	as_operand_16bit
	jmp	as_jmp_mem_far_store
      as_jmp_mem_32bit:
	cmp	[as_jump_type],3
	if_equal	as_jmp_mem_far_32bit
	cmp	[as_jump_type],2
	if_equal	as_jmp_mem_near_32bit
	cmp	[as_code_type],16
	if_equal	as_jmp_mem_far_32bit
      as_jmp_mem_near_32bit:
	call	as_operand_32bit
	jmp	as_instruction_ready
      as_jmp_mem_16bit:
	cmp	[as_jump_type],3
	if_equal	as_invalid_operand_size
	call	as_operand_16bit
	jmp	as_instruction_ready
      as_jmp_reg:
	test	[as_jump_type],1
	if_not_zero	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	mov	al,ah
	cmp	al,2
	if_equal	as_jmp_reg_16bit
	cmp	al,4
	if_equal	as_jmp_reg_32bit
	cmp	al,8
	if_not_equal	as_invalid_operand_size
      as_jmp_reg_64bit:
	jmp	as_illegal_instruction
	jmp	as_nomem_instruction_ready
      as_jmp_reg_32bit:
	call	as_operand_32bit
	jmp	as_nomem_instruction_ready
      as_jmp_reg_16bit:
	call	as_operand_16bit
	jmp	as_nomem_instruction_ready
      as_jmp_imm:
	cmp	as_u8 [esi],'.'
	if_equal	as_invalid_value
	mov	ebx,esi
	dec	esi
	call	as_skip_symbol
	xchg	esi,ebx
	cmp	as_u8 [ebx],':'
	if_equal	as_jmp_far
	cmp	[as_jump_type],3
	if_equal	as_invalid_operand
      as_jmp_near:
	mov	al,[as_operand_size]
	cmp	al,2
	if_equal	as_jmp_imm_16bit
	cmp	al,4
	if_equal	as_jmp_imm_32bit
	cmp	al,8
	if_equal	as_jmp_imm_64bit
	or	al,al
	if_not_zero	as_invalid_operand_size
	cmp	[as_code_type],16
	if_equal	as_jmp_imm_16bit
      as_jmp_imm_32bit:
	call	as_get_address_dword_value
	cmp	[as_code_type],16
	if_not_equal	as_jmp_imm_32bit_prefix_ok
	mov	as_u8 [edi],66h
	inc	edi
      as_jmp_imm_32bit_prefix_ok:
	call	as_calculate_jump_offset
	sign_extend_dword
	call	as_check_for_short_jump
	if_carry	as_jmp_short
      as_jmp_imm_32bit_store:
	mov	edx,eax
	sub	edx,3
	if_not_overflow	as_jmp_imm_32bit_ok
      as_jmp_imm_32bit_ok:
	mov	al,[as_base_code]
	stos	as_u8 [edi]
	mov	eax,edx
	call	as_mark_relocation
	stos	as_u32 [edi]
	jmp	as_instruction_assembled
      as_jmp_imm_64bit:
	jmp	as_invalid_operand_size
	call	as_get_address_qword_value
	call	as_calculate_jump_offset
	mov	ecx,edx
	sign_extend_dword
	cmp	edx,ecx
	if_not_equal	as_jump_out_of_range
	call	as_check_for_short_jump
	if_not_carry	as_jmp_imm_32bit_store
      as_jmp_short:
	mov	ah,al
	mov	al,0EBh
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
      as_jmp_imm_16bit:
	call	as_get_address_word_value
	cmp	[as_code_type],16
	if_equal	as_jmp_imm_16bit_prefix_ok
	mov	as_u8 [edi],66h
	inc	edi
      as_jmp_imm_16bit_prefix_ok:
	call	as_calculate_jump_offset
	sign_extend_word
	sign_extend_dword
	call	as_check_for_short_jump
	if_carry	as_jmp_short
	cmp	[as_value_type],0
	if_not_equal	as_invalid_use_of_symbol
	mov	edx,eax
	dec	edx
	mov	al,[as_base_code]
	stos	as_u8 [edi]
	mov	eax,edx
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
      as_calculate_jump_offset:
	add	edi,2
	mov	ebp,[as_addressing_space]
	call	as_calculate_relative_offset
	sub	edi,2
	ret
      as_check_for_short_jump:
	cmp	[as_jump_type],1
	if_equal	as_forced_short
	if_above	as_no_short_jump
	cmp	[as_base_code],0E8h
	if_equal	as_no_short_jump
	cmp	[as_value_type],0
	if_not_equal	as_no_short_jump
	cmp	eax,80h
	if_below	as_short_jump
	cmp	eax,-80h
	if_above_equal	as_short_jump
      as_no_short_jump:
	clear_carry
	ret
      as_forced_short:
	cmp	[as_base_code],0E8h
	if_equal	as_illegal_instruction
	cmp	[as_next_pass_needed],0
	if_not_equal	as_jmp_short_value_type_ok
	cmp	[as_value_type],0
	if_not_equal	as_invalid_use_of_symbol
      as_jmp_short_value_type_ok:
	cmp	eax,-80h
	if_above_equal	as_short_jump
	cmp	eax,80h
	if_above_equal	as_jump_out_of_range
      as_short_jump:
	set_carry
	ret
      as_jump_out_of_range:
	cmp	[as_error_line],0
	if_not_equal	as_instruction_assembled
	mov	eax,[as_current_line]
	mov	[as_error_line],eax
	mov	[as_error],as_relative_jump_out_of_range
	jmp	as_instruction_assembled
      as_jmp_far:
	cmp	[as_jump_type],2
	if_equal	as_invalid_operand
	mov	al,[as_extended_code]
	mov	[as_base_code],al
	call	as_get_word_value
	push	eax
	inc	esi
	lods	as_u8 [esi]
	cmp	al,'('
	if_not_equal	as_invalid_operand
	mov	al,[as_value_type]
	push	eax
	push	[as_symbol_identifier]
	cmp	as_u8 [esi],'.'
	if_equal	as_invalid_value
	mov	al,[as_operand_size]
	cmp	al,4
	if_equal	as_jmp_far_16bit
	cmp	al,6
	if_equal	as_jmp_far_32bit
	or	al,al
	if_not_zero	as_invalid_operand_size
	cmp	[as_code_type],16
	if_not_equal	as_jmp_far_32bit
      as_jmp_far_16bit:
	call	as_get_word_value
	mov	ebx,eax
	call	as_operand_16bit
	call	as_store_classic_instruction_code
	mov	ax,bx
	call	as_mark_relocation
	stos	as_u16 [edi]
      as_jmp_far_segment:
	pop	[as_symbol_identifier]
	pop	eax
	mov	[as_value_type],al
	pop	eax
	call	as_mark_relocation
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
      as_jmp_far_32bit:
	call	as_get_dword_value
	mov	ebx,eax
	call	as_operand_32bit
	call	as_store_classic_instruction_code
	mov	eax,ebx
	call	as_mark_relocation
	stos	as_u32 [edi]
	jmp	as_jmp_far_segment
as_conditional_jump:
	mov	[as_base_code],al
	and	[as_prefix_flags],not 10h
	lods	as_u8 [esi]
	call	as_get_jump_operator
	cmp	[as_jump_type],3
	if_equal	as_invalid_operand
	call	as_get_size_operator
	cmp	al,'('
	if_not_equal	as_invalid_operand
	cmp	as_u8 [esi],'.'
	if_equal	as_invalid_value
	mov	al,[as_operand_size]
	cmp	al,2
	if_equal	as_conditional_jump_16bit
	cmp	al,4
	if_equal	as_conditional_jump_32bit
	cmp	al,8
	if_equal	as_conditional_jump_64bit
	or	al,al
	if_not_zero	as_invalid_operand_size
	cmp	[as_code_type],16
	if_equal	as_conditional_jump_16bit
      as_conditional_jump_32bit:
	call	as_get_address_dword_value
	cmp	[as_code_type],16
	if_not_equal	as_conditional_jump_32bit_prefix_ok
	mov	as_u8 [edi],66h
	inc	edi
      as_conditional_jump_32bit_prefix_ok:
	call	as_calculate_jump_offset
	sign_extend_dword
	call	as_check_for_short_jump
	if_carry	as_conditional_jump_short
      as_conditional_jump_32bit_store:
	mov	edx,eax
	sub	edx,4
	if_not_overflow	as_conditional_jump_32bit_range_ok
      as_conditional_jump_32bit_range_ok:
	mov	ah,[as_base_code]
	add	ah,10h
	mov	al,0Fh
	stos	as_u16 [edi]
	mov	eax,edx
	call	as_mark_relocation
	stos	as_u32 [edi]
	jmp	as_instruction_assembled
      as_conditional_jump_64bit:
	jmp	as_invalid_operand_size
	call	as_get_address_qword_value
	call	as_calculate_jump_offset
	mov	ecx,edx
	sign_extend_dword
	cmp	edx,ecx
	if_not_equal	as_jump_out_of_range
	call	as_check_for_short_jump
	if_not_carry	as_conditional_jump_32bit_store
      as_conditional_jump_short:
	mov	ah,al
	mov	al,[as_base_code]
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
      as_conditional_jump_16bit:
	call	as_get_address_word_value
	cmp	[as_code_type],16
	if_equal	as_conditional_jump_16bit_prefix_ok
	mov	as_u8 [edi],66h
	inc	edi
      as_conditional_jump_16bit_prefix_ok:
	call	as_calculate_jump_offset
	sign_extend_word
	sign_extend_dword
	call	as_check_for_short_jump
	if_carry	as_conditional_jump_short
	cmp	[as_value_type],0
	if_not_equal	as_invalid_use_of_symbol
	mov	edx,eax
	sub	dx,2
	mov	ah,[as_base_code]
	add	ah,10h
	mov	al,0Fh
	stos	as_u16 [edi]
	mov	eax,edx
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
as_loop_instruction_16bit:
	cmp	[as_code_type],16
	if_equal	as_loop_instruction
	mov	[as_operand_prefix],67h
	jmp	as_loop_instruction
as_loop_instruction_32bit:
	cmp	[as_code_type],32
	if_equal	as_loop_instruction
	mov	[as_operand_prefix],67h
      jmp     as_loop_instruction
as_loop_instruction_64bit:
	jmp	as_illegal_instruction
as_loop_instruction:
	mov	[as_base_code],al
	lods	as_u8 [esi]
	call	as_get_jump_operator
	cmp	[as_jump_type],1
	if_above	as_invalid_operand
	call	as_get_size_operator
	cmp	al,'('
	if_not_equal	as_invalid_operand
	cmp	as_u8 [esi],'.'
	if_equal	as_invalid_value
	mov	al,[as_operand_size]
	cmp	al,2
	if_equal	as_loop_jump_16bit
	cmp	al,4
	if_equal	as_loop_jump_32bit
	cmp	al,8
	if_equal	as_loop_jump_64bit
	or	al,al
	if_not_zero	as_invalid_operand_size
	cmp	[as_code_type],16
	if_equal	as_loop_jump_16bit
      as_loop_jump_32bit:
	call	as_get_address_dword_value
	cmp	[as_code_type],16
	if_not_equal	as_loop_jump_32bit_prefix_ok
	mov	as_u8 [edi],66h
	inc	edi
      as_loop_jump_32bit_prefix_ok:
	call	as_loop_counter_size
	call	as_calculate_jump_offset
	sign_extend_dword
      as_make_loop_jump:
	call	as_check_for_short_jump
	if_carry	as_conditional_jump_short
	scas	as_u16 [edi]
	jmp	as_jump_out_of_range
      as_loop_counter_size:
	cmp	[as_operand_prefix],0
	if_equal	as_loop_counter_size_ok
	push	eax
	mov	al,[as_operand_prefix]
	stos	as_u8 [edi]
	pop	eax
      as_loop_counter_size_ok:
	ret
      as_loop_jump_64bit:
	jmp	as_invalid_operand_size
	call	as_get_address_qword_value
	call	as_loop_counter_size
	call	as_calculate_jump_offset
	mov	ecx,edx
	sign_extend_dword
	cmp	edx,ecx
	if_not_equal	as_jump_out_of_range
	jmp	as_make_loop_jump
      as_loop_jump_16bit:
	call	as_get_address_word_value
	cmp	[as_code_type],16
	if_equal	as_loop_jump_16bit_prefix_ok
	mov	as_u8 [edi],66h
	inc	edi
      as_loop_jump_16bit_prefix_ok:
	call	as_loop_counter_size
	call	as_calculate_jump_offset
	sign_extend_word
	sign_extend_dword
	jmp	as_make_loop_jump

as_movs_instruction:
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	or	eax,eax
	if_not_zero	as_invalid_address
	or	bl,ch
	if_not_zero	as_invalid_address
	cmp	[as_segment_register],1
	if_above	as_invalid_address
	push	ebx
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	pop	edx
	or	eax,eax
	if_not_zero	as_invalid_address
	or	bl,ch
	if_not_zero	as_invalid_address
	mov	al,dh
	mov	ah,bh
	shr	al,4
	shr	ah,4
	cmp	al,ah
	if_not_equal	as_address_sizes_do_not_agree
	and	bh,111b
	and	dh,111b
	cmp	bh,6
	if_not_equal	as_invalid_address
	cmp	dh,7
	if_not_equal	as_invalid_address
	cmp	al,2
	if_equal	as_movs_address_16bit
	cmp	al,4
	if_equal	as_movs_address_32bit
	jmp	as_invalid_address_size
	jmp	as_movs_store
      as_movs_address_32bit:
	call	as_address_32bit_prefix
	jmp	as_movs_store
      as_movs_address_16bit:
	call	as_address_16bit_prefix
      as_movs_store:
	xor	ebx,ebx
	call	as_store_segment_prefix_if_necessary
	mov	al,0A4h
      as_movs_check_size:
	mov	bl,[as_operand_size]
	cmp	bl,1
	if_equal	as_simple_instruction
	inc	al
	cmp	bl,2
	if_equal	as_simple_instruction_16bit
	cmp	bl,4
	if_equal	as_simple_instruction_32bit
	cmp	bl,8
	if_equal	as_simple_instruction_64bit
	or	bl,bl
	if_not_zero	as_invalid_operand_size
	call	as_recoverable_unknown_size
	jmp	as_simple_instruction
as_lods_instruction:
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	or	eax,eax
	if_not_zero	as_invalid_address
	or	bl,ch
	if_not_zero	as_invalid_address
	cmp	bh,26h
	if_equal	as_lods_address_16bit
	cmp	bh,46h
	if_equal	as_lods_address_32bit
	cmp	bh,86h
	if_not_equal	as_invalid_address
	jmp	as_invalid_address_size
	jmp	as_lods_store
      as_lods_address_32bit:
	call	as_address_32bit_prefix
	jmp	as_lods_store
      as_lods_address_16bit:
	call	as_address_16bit_prefix
      as_lods_store:
	xor	ebx,ebx
	call	as_store_segment_prefix_if_necessary
	mov	al,0ACh
	jmp	as_movs_check_size
as_stos_instruction:
	mov	[as_base_code],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	or	eax,eax
	if_not_zero	as_invalid_address
	or	bl,ch
	if_not_zero	as_invalid_address
	cmp	bh,27h
	if_equal	as_stos_address_16bit
	cmp	bh,47h
	if_equal	as_stos_address_32bit
	cmp	bh,87h
	if_not_equal	as_invalid_address
	jmp	as_invalid_address_size
	jmp	as_stos_store
      as_stos_address_32bit:
	call	as_address_32bit_prefix
	jmp	as_stos_store
      as_stos_address_16bit:
	call	as_address_16bit_prefix
      as_stos_store:
	cmp	[as_segment_register],1
	if_above	as_invalid_address
	mov	al,[as_base_code]
	jmp	as_movs_check_size
as_cmps_instruction:
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	or	eax,eax
	if_not_zero	as_invalid_address
	or	bl,ch
	if_not_zero	as_invalid_address
	mov	al,[as_segment_register]
	push	eax ebx
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	or	eax,eax
	if_not_zero	as_invalid_address
	or	bl,ch
	if_not_zero	as_invalid_address
	pop	edx eax
	cmp	[as_segment_register],1
	if_above	as_invalid_address
	mov	[as_segment_register],al
	mov	al,dh
	mov	ah,bh
	shr	al,4
	shr	ah,4
	cmp	al,ah
	if_not_equal	as_address_sizes_do_not_agree
	and	bh,111b
	and	dh,111b
	cmp	bh,7
	if_not_equal	as_invalid_address
	cmp	dh,6
	if_not_equal	as_invalid_address
	cmp	al,2
	if_equal	as_cmps_address_16bit
	cmp	al,4
	if_equal	as_cmps_address_32bit
	jmp	as_invalid_address_size
	jmp	as_cmps_store
      as_cmps_address_32bit:
	call	as_address_32bit_prefix
	jmp	as_cmps_store
      as_cmps_address_16bit:
	call	as_address_16bit_prefix
      as_cmps_store:
	xor	ebx,ebx
	call	as_store_segment_prefix_if_necessary
	mov	al,0A6h
	jmp	as_movs_check_size
as_ins_instruction:
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	or	eax,eax
	if_not_zero	as_invalid_address
	or	bl,ch
	if_not_zero	as_invalid_address
	cmp	bh,27h
	if_equal	as_ins_address_16bit
	cmp	bh,47h
	if_equal	as_ins_address_32bit
	cmp	bh,87h
	if_not_equal	as_invalid_address
	jmp	as_invalid_address_size
	jmp	as_ins_store
      as_ins_address_32bit:
	call	as_address_32bit_prefix
	jmp	as_ins_store
      as_ins_address_16bit:
	call	as_address_16bit_prefix
      as_ins_store:
	cmp	[as_segment_register],1
	if_above	as_invalid_address
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	cmp	al,22h
	if_not_equal	as_invalid_operand
	mov	al,6Ch
      as_ins_check_size:
	cmp	[as_operand_size],8
	if_not_equal	as_movs_check_size
	jmp	as_invalid_operand_size
as_outs_instruction:
	lods	as_u8 [esi]
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	cmp	al,22h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	or	eax,eax
	if_not_zero	as_invalid_address
	or	bl,ch
	if_not_zero	as_invalid_address
	cmp	bh,26h
	if_equal	as_outs_address_16bit
	cmp	bh,46h
	if_equal	as_outs_address_32bit
	cmp	bh,86h
	if_not_equal	as_invalid_address
	jmp	as_invalid_address_size
	jmp	as_outs_store
      as_outs_address_32bit:
	call	as_address_32bit_prefix
	jmp	as_outs_store
      as_outs_address_16bit:
	call	as_address_16bit_prefix
      as_outs_store:
	xor	ebx,ebx
	call	as_store_segment_prefix_if_necessary
	mov	al,6Eh
	jmp	as_ins_check_size
as_xlat_instruction:
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	or	eax,eax
	if_not_zero	as_invalid_address
	or	bl,ch
	if_not_zero	as_invalid_address
	cmp	bh,23h
	if_equal	as_xlat_address_16bit
	cmp	bh,43h
	if_equal	as_xlat_address_32bit
	cmp	bh,83h
	if_not_equal	as_invalid_address
	jmp	as_invalid_address_size
	jmp	as_xlat_store
      as_xlat_address_32bit:
	call	as_address_32bit_prefix
	jmp	as_xlat_store
      as_xlat_address_16bit:
	call	as_address_16bit_prefix
      as_xlat_store:
	call	as_store_segment_prefix_if_necessary
	mov	al,0D7h
	cmp	[as_operand_size],1
	if_below_equal	as_simple_instruction
	jmp	as_invalid_operand_size

as_pm_word_instruction:
	mov	ah,al
	shr	ah,4
	and	al,111b
	mov	[as_base_code],0Fh
	mov	[as_extended_code],ah
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_pm_reg
      as_pm_mem:
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	cmp	al,2
	if_equal	as_pm_mem_store
	or	al,al
	if_not_zero	as_invalid_operand_size
      as_pm_mem_store:
	jmp	as_instruction_ready
      as_pm_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	cmp	ah,2
	if_not_equal	as_invalid_operand_size
	jmp	as_nomem_instruction_ready
as_pm_store_word_instruction:
	mov	ah,al
	shr	ah,4
	and	al,111b
	mov	[as_base_code],0Fh
	mov	[as_extended_code],ah
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_pm_mem
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	mov	al,ah
	call	as_operand_autodetect
	jmp	as_nomem_instruction_ready
as_lgdt_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],1
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	cmp	al,6
	if_equal	as_lgdt_mem_48bit
	cmp	al,10
	if_equal	as_lgdt_mem_80bit
	or	al,al
	if_not_zero	as_invalid_operand_size
	jmp	as_lgdt_mem_store
      as_lgdt_mem_80bit:
	jmp	as_illegal_instruction
	jmp	as_lgdt_mem_store
      as_lgdt_mem_48bit:
	cmp	[as_postbyte_register],2
	if_below	as_lgdt_mem_store
	call	as_operand_32bit
      as_lgdt_mem_store:
	jmp	as_instruction_ready
as_lar_instruction:
	mov	[as_extended_code],al
	mov	[as_base_code],0Fh
	call	as_take_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	xor	al,al
	xchg	al,[as_operand_size]
	call	as_operand_autodetect
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_lar_reg_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_lar_reg_mem
	cmp	al,2
	if_not_equal	as_invalid_operand_size
      as_lar_reg_mem:
	jmp	as_instruction_ready
      as_lar_reg_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	cmp	ah,2
	if_not_equal	as_invalid_operand_size
	mov	bl,al
	jmp	as_nomem_instruction_ready
as_invlpg_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],1
	mov	[as_postbyte_register],7
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	jmp	as_instruction_ready
as_simple_instruction_f2_0f_01:
	mov	as_u8 [edi],0F2h
	inc	edi
	jmp	as_simple_instruction_0f_01
as_simple_instruction_f3_0f_01_64bit:
	jmp	as_illegal_instruction
as_simple_instruction_f3_0f_01:
	mov	as_u8 [edi],0F3h
	inc	edi
	jmp	as_simple_instruction_0f_01
as_swapgs_instruction:
	jmp	as_illegal_instruction
as_simple_instruction_0f_01:
	mov	ah,al
	mov	al,0Fh
	stos	as_u8 [edi]
	mov	al,1
	stos	as_u16 [edi]
	jmp	as_instruction_assembled

as_basic_486_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_basic_486_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	push	edx ebx ecx
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_register
	mov	[as_postbyte_register],al
	pop	ecx ebx edx
	mov	al,ah
	cmp	al,1
	if_equal	as_basic_486_mem_reg_8bit
	call	as_operand_autodetect
	inc	[as_extended_code]
      as_basic_486_mem_reg_8bit:
	jmp	as_instruction_ready
      as_basic_486_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_register
	mov	bl,al
	xchg	bl,[as_postbyte_register]
	mov	al,ah
	cmp	al,1
	if_equal	as_basic_486_reg_reg_8bit
	call	as_operand_autodetect
	inc	[as_extended_code]
      as_basic_486_reg_reg_8bit:
	jmp	as_nomem_instruction_ready
as_bswap_instruction:
	call	as_take_register
	test	al,1000b
	if_zero	as_bswap_reg_code_ok
	or	[as_rex_prefix],41h
	and	al,111b
      as_bswap_reg_code_ok:
	add	al,0C8h
	mov	[as_extended_code],al
	mov	[as_base_code],0Fh
	cmp	ah,8
	if_equal	as_bswap_reg64
	cmp	ah,4
	if_not_equal	as_invalid_operand_size
	call	as_operand_32bit
	call	as_store_classic_instruction_code
	jmp	as_instruction_assembled
      as_bswap_reg64:
	call	as_operand_64bit
	call	as_store_classic_instruction_code
	jmp	as_instruction_assembled
as_cmpxchgx_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],0C7h
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	ah,1
	xchg	[as_postbyte_register],ah
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_cmpxchgx_size_ok
	cmp	al,ah
	if_not_equal	as_invalid_operand_size
      as_cmpxchgx_size_ok:
	cmp	ah,16
	if_not_equal	as_cmpxchgx_store
	call	as_operand_64bit
      as_cmpxchgx_store:
	jmp	as_instruction_ready
as_nop_instruction:
	mov	ah,[esi]
	cmp	ah,10h
	if_equal	as_extended_nop
	cmp	ah,11h
	if_equal	as_extended_nop
	cmp	ah,'['
	if_equal	as_extended_nop
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
      as_extended_nop:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],1Fh
	mov	[as_postbyte_register],0
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_extended_nop_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_extended_nop_store
	call	as_operand_autodetect
      as_extended_nop_store:
	jmp	as_instruction_ready
      as_extended_nop_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	mov	al,ah
	call	as_operand_autodetect
	jmp	as_nomem_instruction_ready

as_basic_fpu_instruction:
	mov	[as_postbyte_register],al
	mov	[as_base_code],0D8h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_basic_fpu_streg
	cmp	al,'['
	if_equal	as_basic_fpu_mem
	dec	esi
	mov	ah,[as_postbyte_register]
	cmp	ah,2
	if_below	as_invalid_operand
	cmp	ah,3
	if_above	as_invalid_operand
	mov	bl,1
	jmp	as_nomem_instruction_ready
      as_basic_fpu_mem:
	call	as_get_address
	mov	al,[as_operand_size]
	cmp	al,4
	if_equal	as_basic_fpu_mem_32bit
	cmp	al,8
	if_equal	as_basic_fpu_mem_64bit
	or	al,al
	if_not_zero	as_invalid_operand_size
	call	as_recoverable_unknown_size
      as_basic_fpu_mem_32bit:
	jmp	as_instruction_ready
      as_basic_fpu_mem_64bit:
	mov	[as_base_code],0DCh
	jmp	as_instruction_ready
      as_basic_fpu_streg:
	lods	as_u8 [esi]
	call	as_convert_fpu_register
	mov	bl,al
	mov	ah,[as_postbyte_register]
	cmp	ah,2
	if_equal	as_basic_fpu_single_streg
	cmp	ah,3
	if_equal	as_basic_fpu_single_streg
	or	al,al
	if_zero	as_basic_fpu_st0
	test	ah,110b
	if_zero	as_basic_fpu_streg_st0
	xor	[as_postbyte_register],1
      as_basic_fpu_streg_st0:
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_fpu_register
	or	al,al
	if_not_zero	as_invalid_operand
	mov	[as_base_code],0DCh
	jmp	as_nomem_instruction_ready
      as_basic_fpu_st0:
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_fpu_register
	mov	bl,al
      as_basic_fpu_single_streg:
	mov	[as_base_code],0D8h
	jmp	as_nomem_instruction_ready
as_simple_fpu_instruction:
	mov	ah,al
	or	ah,11000000b
	mov	al,0D9h
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
as_fi_instruction:
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	cmp	al,2
	if_equal	as_fi_mem_16bit
	cmp	al,4
	if_equal	as_fi_mem_32bit
	or	al,al
	if_not_zero	as_invalid_operand_size
	call	as_recoverable_unknown_size
      as_fi_mem_32bit:
	mov	[as_base_code],0DAh
	jmp	as_instruction_ready
      as_fi_mem_16bit:
	mov	[as_base_code],0DEh
	jmp	as_instruction_ready
as_fld_instruction:
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_fld_streg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	cmp	al,4
	if_equal	as_fld_mem_32bit
	cmp	al,8
	if_equal	as_fld_mem_64bit
	cmp	al,10
	if_equal	as_fld_mem_80bit
	or	al,al
	if_not_zero	as_invalid_operand_size
	call	as_recoverable_unknown_size
      as_fld_mem_32bit:
	mov	[as_base_code],0D9h
	jmp	as_instruction_ready
      as_fld_mem_64bit:
	mov	[as_base_code],0DDh
	jmp	as_instruction_ready
      as_fld_mem_80bit:
	mov	al,[as_postbyte_register]
	cmp	al,0
	if_equal	as_fld_mem_80bit_store
	dec	[as_postbyte_register]
	cmp	al,3
	if_equal	as_fld_mem_80bit_store
	jmp	as_invalid_operand_size
      as_fld_mem_80bit_store:
	add	[as_postbyte_register],5
	mov	[as_base_code],0DBh
	jmp	as_instruction_ready
      as_fld_streg:
	lods	as_u8 [esi]
	call	as_convert_fpu_register
	mov	bl,al
	cmp	[as_postbyte_register],2
	if_above_equal	as_fst_streg
	mov	[as_base_code],0D9h
	jmp	as_nomem_instruction_ready
      as_fst_streg:
	mov	[as_base_code],0DDh
	jmp	as_nomem_instruction_ready
as_fild_instruction:
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	cmp	al,2
	if_equal	as_fild_mem_16bit
	cmp	al,4
	if_equal	as_fild_mem_32bit
	cmp	al,8
	if_equal	as_fild_mem_64bit
	or	al,al
	if_not_zero	as_invalid_operand_size
	call	as_recoverable_unknown_size
      as_fild_mem_32bit:
	mov	[as_base_code],0DBh
	jmp	as_instruction_ready
      as_fild_mem_16bit:
	mov	[as_base_code],0DFh
	jmp	as_instruction_ready
      as_fild_mem_64bit:
	mov	al,[as_postbyte_register]
	cmp	al,1
	if_equal	as_fisttp_64bit_store
	if_below	as_fild_mem_64bit_store
	dec	[as_postbyte_register]
	cmp	al,3
	if_equal	as_fild_mem_64bit_store
	jmp	as_invalid_operand_size
      as_fild_mem_64bit_store:
	add	[as_postbyte_register],5
	mov	[as_base_code],0DFh
	jmp	as_instruction_ready
      as_fisttp_64bit_store:
	mov	[as_base_code],0DDh
	jmp	as_instruction_ready
as_fbld_instruction:
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_fbld_mem_80bit
	cmp	al,10
	if_equal	as_fbld_mem_80bit
	jmp	as_invalid_operand_size
      as_fbld_mem_80bit:
	mov	[as_base_code],0DFh
	jmp	as_instruction_ready
as_faddp_instruction:
	mov	[as_postbyte_register],al
	mov	[as_base_code],0DEh
	mov	edx,esi
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_faddp_streg
	mov	esi,edx
	mov	bl,1
	jmp	as_nomem_instruction_ready
      as_faddp_streg:
	lods	as_u8 [esi]
	call	as_convert_fpu_register
	mov	bl,al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_fpu_register
	or	al,al
	if_not_zero	as_invalid_operand
	jmp	as_nomem_instruction_ready
as_fcompp_instruction:
	mov	ax,0D9DEh
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
as_fucompp_instruction:
	mov	ax,0E9DAh
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
as_fxch_instruction:
	mov	dx,01D9h
	jmp	as_fpu_single_operand
as_ffreep_instruction:
	mov	dx,00DFh
	jmp	as_fpu_single_operand
as_ffree_instruction:
	mov	dl,0DDh
	mov	dh,al
      as_fpu_single_operand:
	mov	ebx,esi
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_fpu_streg
	or	dh,dh
	if_zero	as_invalid_operand
	mov	esi,ebx
	shl	dh,3
	or	dh,11000001b
	mov	ax,dx
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
      as_fpu_streg:
	lods	as_u8 [esi]
	call	as_convert_fpu_register
	shl	dh,3
	or	dh,al
	or	dh,11000000b
	mov	ax,dx
	stos	as_u16 [edi]
	jmp	as_instruction_assembled

as_fstenv_instruction:
	mov	as_u8 [edi],9Bh
	inc	edi
as_fldenv_instruction:
	mov	[as_base_code],0D9h
	jmp	as_fpu_mem
as_fstenv_instruction_16bit:
	mov	as_u8 [edi],9Bh
	inc	edi
as_fldenv_instruction_16bit:
	call	as_operand_16bit
	jmp	as_fldenv_instruction
as_fstenv_instruction_32bit:
	mov	as_u8 [edi],9Bh
	inc	edi
as_fldenv_instruction_32bit:
	call	as_operand_32bit
	jmp	as_fldenv_instruction
as_fsave_instruction_32bit:
	mov	as_u8 [edi],9Bh
	inc	edi
as_fnsave_instruction_32bit:
	call	as_operand_32bit
	jmp	as_fnsave_instruction
as_fsave_instruction_16bit:
	mov	as_u8 [edi],9Bh
	inc	edi
as_fnsave_instruction_16bit:
	call	as_operand_16bit
	jmp	as_fnsave_instruction
as_fsave_instruction:
	mov	as_u8 [edi],9Bh
	inc	edi
as_fnsave_instruction:
	mov	[as_base_code],0DDh
      as_fpu_mem:
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	cmp	[as_operand_size],0
	if_not_equal	as_invalid_operand_size
	jmp	as_instruction_ready
as_fstcw_instruction:
	mov	as_u8 [edi],9Bh
	inc	edi
as_fldcw_instruction:
	mov	[as_postbyte_register],al
	mov	[as_base_code],0D9h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_fldcw_mem_16bit
	cmp	al,2
	if_equal	as_fldcw_mem_16bit
	jmp	as_invalid_operand_size
      as_fldcw_mem_16bit:
	jmp	as_instruction_ready
as_fstsw_instruction:
	mov	al,9Bh
	stos	as_u8 [edi]
as_fnstsw_instruction:
	mov	[as_base_code],0DDh
	mov	[as_postbyte_register],7
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_fstsw_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_fstsw_mem_16bit
	cmp	al,2
	if_equal	as_fstsw_mem_16bit
	jmp	as_invalid_operand_size
      as_fstsw_mem_16bit:
	jmp	as_instruction_ready
      as_fstsw_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	cmp	ax,0200h
	if_not_equal	as_invalid_operand
	mov	ax,0E0DFh
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
as_finit_instruction:
	mov	as_u8 [edi],9Bh
	inc	edi
as_fninit_instruction:
	mov	ah,al
	mov	al,0DBh
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
as_fcmov_instruction:
	mov	dh,0DAh
	jmp	as_fcomi_streg
as_fcomi_instruction:
	mov	dh,0DBh
	jmp	as_fcomi_streg
as_fcomip_instruction:
	mov	dh,0DFh
      as_fcomi_streg:
	mov	dl,al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_fpu_register
	mov	ah,al
	cmp	as_u8 [esi],','
	if_equal	as_fcomi_st0_streg
	add	ah,dl
	mov	al,dh
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
      as_fcomi_st0_streg:
	or	ah,ah
	if_not_zero	as_invalid_operand
	inc	esi
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_fpu_register
	mov	ah,al
	add	ah,dl
	mov	al,dh
	stos	as_u16 [edi]
	jmp	as_instruction_assembled

as_basic_mmx_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
      as_mmx_instruction:
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	call	as_make_mmx_prefix
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_mmx_mmreg_mmreg
	cmp	al,'['
	if_not_equal	as_invalid_operand
      as_mmx_mmreg_mem:
	call	as_get_address
	jmp	as_instruction_ready
      as_mmx_mmreg_mmreg:
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	mov	bl,al
	jmp	as_nomem_instruction_ready
as_mmx_bit_shift_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	call	as_make_mmx_prefix
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_mmx_mmreg_mmreg
	cmp	al,'('
	if_equal	as_mmx_ps_mmreg_imm8
	cmp	al,'['
	if_equal	as_mmx_mmreg_mem
	jmp	as_invalid_operand
      as_mmx_ps_mmreg_imm8:
	call	as_get_byte_value
	mov	as_u8 [as_value],al
	test	[as_operand_size],not 1
	if_not_zero	as_invalid_value
	mov	bl,[as_extended_code]
	mov	al,bl
	shr	bl,4
	and	al,1111b
	add	al,70h
	mov	[as_extended_code],al
	sub	bl,0Ch
	shl	bl,1
	xchg	bl,[as_postbyte_register]
	call	as_store_nomem_instruction
	mov	al,as_u8 [as_value]
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
as_pmovmskb_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	call	as_take_register
	cmp	ah,4
	if_equal	as_pmovmskb_reg_size_ok
	jmp	as_invalid_operand_size
	cmp	ah,8
	if_not_zero	as_invalid_operand_size
      as_pmovmskb_reg_size_ok:
	mov	[as_postbyte_register],al
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	mov	bl,al
	call	as_make_mmx_prefix
	cmp	[as_extended_code],0C5h
	if_equal	as_mmx_nomem_imm8
	jmp	as_nomem_instruction_ready
      as_mmx_imm8:
	push	ebx ecx edx
	xor	cl,cl
	xchg	cl,[as_operand_size]
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	test	ah,not 1
	if_not_zero	as_invalid_operand_size
	mov	[as_operand_size],cl
	cmp	al,'('
	if_not_equal	as_invalid_operand
	call	as_get_byte_value
	mov	as_u8 [as_value],al
	pop	edx ecx ebx
	call	as_store_instruction_with_imm8
	jmp	as_instruction_assembled
      as_mmx_nomem_imm8:
	call	as_store_nomem_instruction
	call	as_append_imm8
	jmp	as_instruction_assembled
      as_append_imm8:
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	test	ah,not 1
	if_not_zero	as_invalid_operand_size
	cmp	al,'('
	if_not_equal	as_invalid_operand
	call	as_get_byte_value
	stosb
	ret

as_pinsrw_instruction:
	mov	[as_extended_code],al
	mov	[as_base_code],0Fh
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	call	as_make_mmx_prefix
	mov	[as_postbyte_register],al
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_pinsrw_mmreg_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	cmp	[as_operand_size],0
	if_equal	as_mmx_imm8
	cmp	[as_operand_size],2
	if_not_equal	as_invalid_operand_size
	jmp	as_mmx_imm8
      as_pinsrw_mmreg_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	cmp	ah,4
	if_not_equal	as_invalid_operand_size
	mov	bl,al
	jmp	as_mmx_nomem_imm8
as_pshufw_instruction:
	mov	[as_mmx_size],8
	mov	[as_opcode_prefix],al
	jmp	as_pshuf_instruction
as_pshufd_instruction:
	mov	[as_mmx_size],16
	mov	[as_opcode_prefix],al
      as_pshuf_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],70h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	cmp	ah,[as_mmx_size]
	if_not_equal	as_invalid_operand_size
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_pshuf_mmreg_mmreg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	jmp	as_mmx_imm8
      as_pshuf_mmreg_mmreg:
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	mov	bl,al
	jmp	as_mmx_nomem_imm8
as_movd_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],7Eh
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_movd_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	test	[as_operand_size],not 4
	if_not_zero	as_invalid_operand_size
	call	as_get_mmx_source_register
	jmp	as_instruction_ready
      as_movd_reg:
	lods	as_u8 [esi]
	cmp	al,0B0h
	if_above_equal	as_movd_mmreg
	call	as_convert_register
	cmp	ah,4
	if_not_equal	as_invalid_operand_size
	mov	bl,al
	call	as_get_mmx_source_register
	jmp	as_nomem_instruction_ready
      as_movd_mmreg:
	mov	[as_extended_code],6Eh
	call	as_convert_mmx_register
	mov	[as_postbyte_register],al
	call	as_make_mmx_prefix
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_movd_mmreg_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	test	[as_operand_size],not 4
	if_not_zero	as_invalid_operand_size
	jmp	as_instruction_ready
      as_movd_mmreg_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	cmp	ah,4
	if_not_equal	as_invalid_operand_size
	mov	bl,al
	jmp	as_nomem_instruction_ready
      as_get_mmx_source_register:
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	mov	[as_postbyte_register],al
      as_make_mmx_prefix:
	cmp	[as_operand_size],16
	if_not_equal	as_no_mmx_prefix
	mov	[as_operand_prefix],66h
      as_no_mmx_prefix:
	ret
as_movq_instruction:
	mov	[as_base_code],0Fh
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_movq_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	test	[as_operand_size],not 8
	if_not_zero	as_invalid_operand_size
	call	as_get_mmx_source_register
	mov	al,7Fh
	cmp	ah,8
	if_equal	as_movq_mem_ready
	mov	al,0D6h
      as_movq_mem_ready:
	mov	[as_extended_code],al
	jmp	as_instruction_ready
      as_movq_reg:
	lods	as_u8 [esi]
	cmp	al,0B0h
	if_above_equal	as_movq_mmreg
	call	as_convert_register
	cmp	ah,8
	if_not_equal	as_invalid_operand_size
	mov	bl,al
	mov	[as_extended_code],7Eh
	call	as_operand_64bit
	call	as_get_mmx_source_register
	jmp	as_nomem_instruction_ready
      as_movq_mmreg:
	call	as_convert_mmx_register
	mov	[as_postbyte_register],al
	mov	[as_extended_code],6Fh
	mov	[as_mmx_size],ah
	cmp	ah,16
	if_not_equal	as_movq_mmreg_
	mov	[as_extended_code],7Eh
	mov	[as_opcode_prefix],0F3h
      as_movq_mmreg_:
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_movq_mmreg_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	test	[as_operand_size],not 8
	if_not_zero	as_invalid_operand_size
	jmp	as_instruction_ready
      as_movq_mmreg_reg:
	lods	as_u8 [esi]
	cmp	al,0B0h
	if_above_equal	as_movq_mmreg_mmreg
	mov	[as_operand_size],0
	call	as_convert_register
	cmp	ah,8
	if_not_equal	as_invalid_operand_size
	mov	[as_extended_code],6Eh
	mov	[as_opcode_prefix],0
	mov	bl,al
	cmp	[as_mmx_size],16
	if_not_equal	as_movq_mmreg_reg_store
	mov	[as_opcode_prefix],66h
      as_movq_mmreg_reg_store:
	call	as_operand_64bit
	jmp	as_nomem_instruction_ready
      as_movq_mmreg_mmreg:
	call	as_convert_mmx_register
	cmp	ah,[as_mmx_size]
	if_not_equal	as_invalid_operand_size
	mov	bl,al
	jmp	as_nomem_instruction_ready
as_movdq_instruction:
	mov	[as_opcode_prefix],al
	mov	[as_base_code],0Fh
	mov	[as_extended_code],6Fh
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_movdq_mmreg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_postbyte_register],al
	mov	[as_extended_code],7Fh
	jmp	as_instruction_ready
      as_movdq_mmreg:
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_movdq_mmreg_mmreg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	jmp	as_instruction_ready
      as_movdq_mmreg_mmreg:
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	bl,al
	jmp	as_nomem_instruction_ready
as_lddqu_instruction:
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	push	eax
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	pop	eax
	mov	[as_postbyte_register],al
	mov	[as_opcode_prefix],0F2h
	mov	[as_base_code],0Fh
	mov	[as_extended_code],0F0h
	jmp	as_instruction_ready

as_movdq2q_instruction:
	mov	[as_opcode_prefix],0F2h
	mov	[as_mmx_size],8
	jmp	as_movq2dq_
as_movq2dq_instruction:
	mov	[as_opcode_prefix],0F3h
	mov	[as_mmx_size],16
      as_movq2dq_:
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	cmp	ah,[as_mmx_size]
	if_not_equal	as_invalid_operand_size
	mov	[as_postbyte_register],al
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	xor	[as_mmx_size],8+16
	cmp	ah,[as_mmx_size]
	if_not_equal	as_invalid_operand_size
	mov	bl,al
	mov	[as_base_code],0Fh
	mov	[as_extended_code],0D6h
	jmp	as_nomem_instruction_ready

as_sse_ps_instruction_imm8:
	mov	[as_immediate_size],1
as_sse_ps_instruction:
	mov	[as_mmx_size],16
	jmp	as_sse_instruction
as_sse_pd_instruction_imm8:
	mov	[as_immediate_size],1
as_sse_pd_instruction:
	mov	[as_mmx_size],16
	mov	[as_opcode_prefix],66h
	jmp	as_sse_instruction
as_sse_ss_instruction:
	mov	[as_mmx_size],4
	mov	[as_opcode_prefix],0F3h
	jmp	as_sse_instruction
as_sse_sd_instruction:
	mov	[as_mmx_size],8
	mov	[as_opcode_prefix],0F2h
	jmp	as_sse_instruction
as_cmp_pd_instruction:
	mov	[as_opcode_prefix],66h
as_cmp_ps_instruction:
	mov	[as_mmx_size],16
	mov	as_u8 [as_value],al
	mov	al,0C2h
	jmp	as_sse_instruction
as_cmp_ss_instruction:
	mov	[as_mmx_size],4
	mov	[as_opcode_prefix],0F3h
	jmp	as_cmp_sx_instruction
as_cmpsd_instruction:
	mov	al,0A7h
	mov	ah,[esi]
	or	ah,ah
	if_zero	as_simple_instruction_32bit
	cmp	ah,0Fh
	if_equal	as_simple_instruction_32bit
	mov	al,-1
as_cmp_sd_instruction:
	mov	[as_mmx_size],8
	mov	[as_opcode_prefix],0F2h
      as_cmp_sx_instruction:
	mov	as_u8 [as_value],al
	mov	al,0C2h
	jmp	as_sse_instruction
as_comiss_instruction:
	mov	[as_mmx_size],4
	jmp	as_sse_instruction
as_comisd_instruction:
	mov	[as_mmx_size],8
	mov	[as_opcode_prefix],66h
	jmp	as_sse_instruction
as_cvtdq2pd_instruction:
	mov	[as_opcode_prefix],0F3h
as_cvtps2pd_instruction:
	mov	[as_mmx_size],8
	jmp	as_sse_instruction
as_cvtpd2dq_instruction:
	mov	[as_mmx_size],16
	mov	[as_opcode_prefix],0F2h
	jmp	as_sse_instruction
as_movshdup_instruction:
	mov	[as_mmx_size],16
	mov	[as_opcode_prefix],0F3h
as_sse_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
      as_sse_xmmreg:
	lods	as_u8 [esi]
	call	as_convert_xmm_register
      as_sse_reg:
	mov	[as_postbyte_register],al
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_sse_xmmreg_xmmreg
      as_sse_reg_mem:
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	cmp	[as_operand_size],0
	if_equal	as_sse_mem_size_ok
	mov	al,[as_mmx_size]
	cmp	[as_operand_size],al
	if_not_equal	as_invalid_operand_size
      as_sse_mem_size_ok:
	mov	al,[as_extended_code]
	mov	ah,[as_supplemental_code]
	cmp	al,0C2h
	if_equal	as_sse_cmp_mem_ok
	cmp	ax,443Ah
	if_equal	as_sse_cmp_mem_ok
	cmp	[as_immediate_size],1
	if_equal	as_mmx_imm8
	cmp	[as_immediate_size],-1
	if_not_equal	as_sse_ok
	call	as_take_additional_xmm0
	mov	[as_immediate_size],0
      as_sse_ok:
	jmp	as_instruction_ready
      as_sse_cmp_mem_ok:
	cmp	as_u8 [as_value],-1
	if_equal	as_mmx_imm8
	call	as_store_instruction_with_imm8
	jmp	as_instruction_assembled
      as_sse_xmmreg_xmmreg:
	cmp	[as_operand_prefix],66h
	if_not_equal	as_sse_xmmreg_xmmreg_ok
	cmp	[as_extended_code],12h
	if_equal	as_invalid_operand
	cmp	[as_extended_code],16h
	if_equal	as_invalid_operand
      as_sse_xmmreg_xmmreg_ok:
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	bl,al
	mov	al,[as_extended_code]
	mov	ah,[as_supplemental_code]
	cmp	al,0C2h
	if_equal	as_sse_cmp_nomem_ok
	cmp	ax,443Ah
	if_equal	as_sse_cmp_nomem_ok
	cmp	[as_immediate_size],1
	if_equal	as_mmx_nomem_imm8
	cmp	[as_immediate_size],-1
	if_not_equal	as_sse_nomem_ok
	call	as_take_additional_xmm0
	mov	[as_immediate_size],0
      as_sse_nomem_ok:
	jmp	as_nomem_instruction_ready
      as_sse_cmp_nomem_ok:
	cmp	as_u8 [as_value],-1
	if_equal	as_mmx_nomem_imm8
	call	as_store_nomem_instruction
	mov	al,as_u8 [as_value]
	stosb
	jmp	as_instruction_assembled
      as_take_additional_xmm0:
	cmp	as_u8 [esi],','
	if_not_equal	as_additional_xmm0_ok
	inc	esi
	lods	as_u8 [esi]
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	test	al,al
	if_not_zero	as_invalid_operand
      as_additional_xmm0_ok:
	ret

as_pslldq_instruction:
	mov	[as_postbyte_register],al
	mov	[as_opcode_prefix],66h
	mov	[as_base_code],0Fh
	mov	[as_extended_code],73h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	bl,al
	jmp	as_mmx_nomem_imm8
as_movpd_instruction:
	mov	[as_opcode_prefix],66h
as_movps_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	mov	[as_mmx_size],16
	jmp	as_sse_mov_instruction
as_movss_instruction:
	mov	[as_mmx_size],4
	mov	[as_opcode_prefix],0F3h
	jmp	as_sse_movs
as_movsd_instruction:
	mov	al,0A5h
	mov	ah,[esi]
	or	ah,ah
	if_zero	as_simple_instruction_32bit
	cmp	ah,0Fh
	if_equal	as_simple_instruction_32bit
	mov	[as_mmx_size],8
	mov	[as_opcode_prefix],0F2h
      as_sse_movs:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],10h
	jmp	as_sse_mov_instruction
as_sse_mov_instruction:
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_sse_xmmreg
      as_sse_mem:
	cmp	al,'['
	if_not_equal	as_invalid_operand
	inc	[as_extended_code]
	call	as_get_address
	cmp	[as_operand_size],0
	if_equal	as_sse_mem_xmmreg
	mov	al,[as_mmx_size]
	cmp	[as_operand_size],al
	if_not_equal	as_invalid_operand_size
	mov	[as_operand_size],0
      as_sse_mem_xmmreg:
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_postbyte_register],al
	jmp	as_instruction_ready
as_movlpd_instruction:
	mov	[as_opcode_prefix],66h
as_movlps_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	mov	[as_mmx_size],8
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_sse_mem
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_postbyte_register],al
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	jmp	as_sse_reg_mem
as_movhlps_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	mov	[as_mmx_size],0
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_sse_xmmreg_xmmreg_ok
	jmp	as_invalid_operand
as_maskmovq_instruction:
	mov	cl,8
	jmp	as_maskmov_instruction
as_maskmovdqu_instruction:
	mov	cl,16
	mov	[as_opcode_prefix],66h
      as_maskmov_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],0F7h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	cmp	ah,cl
	if_not_equal	as_invalid_operand_size
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	mov	bl,al
	jmp	as_nomem_instruction_ready
as_movmskpd_instruction:
	mov	[as_opcode_prefix],66h
as_movmskps_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],50h
	call	as_take_register
	mov	[as_postbyte_register],al
	cmp	ah,4
	if_equal	as_movmskps_reg_ok
	cmp	ah,8
	if_not_equal	as_invalid_operand_size
	jmp	as_invalid_operand
      as_movmskps_reg_ok:
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_sse_xmmreg_xmmreg_ok
	jmp	as_invalid_operand

as_cvtpi2pd_instruction:
	mov	[as_opcode_prefix],66h
as_cvtpi2ps_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_postbyte_register],al
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_cvtpi_xmmreg_xmmreg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	cmp	[as_operand_size],0
	if_equal	as_cvtpi_size_ok
	cmp	[as_operand_size],8
	if_not_equal	as_invalid_operand_size
      as_cvtpi_size_ok:
	jmp	as_instruction_ready
      as_cvtpi_xmmreg_xmmreg:
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	cmp	ah,8
	if_not_equal	as_invalid_operand_size
	mov	bl,al
	jmp	as_nomem_instruction_ready
as_cvtsi2ss_instruction:
	mov	[as_opcode_prefix],0F3h
	jmp	as_cvtsi_instruction
as_cvtsi2sd_instruction:
	mov	[as_opcode_prefix],0F2h
      as_cvtsi_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_postbyte_register],al
      as_cvtsi_xmmreg:
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_cvtsi_xmmreg_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	cmp	[as_operand_size],0
	if_equal	as_cvtsi_size_ok
	cmp	[as_operand_size],4
	if_equal	as_cvtsi_size_ok
	cmp	[as_operand_size],8
	if_not_equal	as_invalid_operand_size
	call	as_operand_64bit
      as_cvtsi_size_ok:
	jmp	as_instruction_ready
      as_cvtsi_xmmreg_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	cmp	ah,4
	if_equal	as_cvtsi_xmmreg_reg_store
	cmp	ah,8
	if_not_equal	as_invalid_operand_size
	call	as_operand_64bit
      as_cvtsi_xmmreg_reg_store:
	mov	bl,al
	jmp	as_nomem_instruction_ready
as_cvtps2pi_instruction:
	mov	[as_mmx_size],8
	jmp	as_cvtpd_instruction
as_cvtpd2pi_instruction:
	mov	[as_opcode_prefix],66h
	mov	[as_mmx_size],16
      as_cvtpd_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	cmp	ah,8
	if_not_equal	as_invalid_operand_size
	mov	[as_operand_size],0
	jmp	as_sse_reg
as_cvtss2si_instruction:
	mov	[as_opcode_prefix],0F3h
	mov	[as_mmx_size],4
	jmp	as_cvt2si_instruction
as_cvtsd2si_instruction:
	mov	[as_opcode_prefix],0F2h
	mov	[as_mmx_size],8
      as_cvt2si_instruction:
	mov	[as_extended_code],al
	mov	[as_base_code],0Fh
	call	as_take_register
	mov	[as_operand_size],0
	cmp	ah,4
	if_equal	as_sse_reg
	cmp	ah,8
	if_not_equal	as_invalid_operand_size
	call	as_operand_64bit
	jmp	as_sse_reg

as_ssse3_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],38h
	mov	[as_supplemental_code],al
	jmp	as_mmx_instruction
as_palignr_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],3Ah
	mov	[as_supplemental_code],0Fh
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	call	as_make_mmx_prefix
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_palignr_mmreg_mmreg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	jmp	as_mmx_imm8
      as_palignr_mmreg_mmreg:
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	mov	bl,al
	jmp	as_mmx_nomem_imm8

as_sse4_instruction_38_xmm0:
	mov	[as_immediate_size],-1
	jmp	as_sse4_instruction_38
as_sse4_instruction_66_38_xmm0:
	mov	[as_immediate_size],-1
as_sse4_instruction_66_38:
	mov	[as_opcode_prefix],66h
as_sse4_instruction_38:
	mov	[as_mmx_size],16
	mov	[as_supplemental_code],al
	mov	al,38h
	jmp	as_sse_instruction
as_sse4_ss_instruction_66_3a_imm8:
	mov	[as_immediate_size],1
	mov	cl,4
	jmp	as_sse4_instruction_66_3a_setup
as_sse4_sd_instruction_66_3a_imm8:
	mov	[as_immediate_size],1
	mov	cl,8
	jmp	as_sse4_instruction_66_3a_setup
as_sse4_instruction_66_3a_imm8:
	mov	[as_immediate_size],1
	mov	cl,16
      as_sse4_instruction_66_3a_setup:
	mov	[as_opcode_prefix],66h
      as_sse4_instruction_3a_setup:
	mov	[as_supplemental_code],al
	mov	al,3Ah
	mov	[as_mmx_size],cl
	jmp	as_sse_instruction
as_sse4_instruction_3a_imm8:
	mov	[as_immediate_size],1
	mov	cl,16
	jmp	as_sse4_instruction_3a_setup
as_pclmulqdq_instruction:
	mov	as_u8 [as_value],al
	mov	al,44h
	mov	cl,16
	jmp	as_sse4_instruction_66_3a_setup
as_extractps_instruction:
	call	as_setup_66_0f_3a
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_extractps_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	cmp	[as_operand_size],4
	if_equal	as_extractps_size_ok
	cmp	[as_operand_size],0
	if_not_equal	as_invalid_operand_size
      as_extractps_size_ok:
	push	edx ebx ecx
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_postbyte_register],al
	pop	ecx ebx edx
	jmp	as_mmx_imm8
      as_extractps_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	push	eax
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_postbyte_register],al
	pop	ebx
	mov	al,bh
	cmp	al,4
	if_equal	as_mmx_nomem_imm8
	cmp	al,8
	if_not_equal	as_invalid_operand_size
	jmp	as_illegal_instruction
	jmp	as_mmx_nomem_imm8
      as_setup_66_0f_3a:
	mov	[as_extended_code],3Ah
	mov	[as_supplemental_code],al
	mov	[as_base_code],0Fh
	mov	[as_opcode_prefix],66h
	ret
as_insertps_instruction:
	call	as_setup_66_0f_3a
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_postbyte_register],al
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_insertps_xmmreg_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	cmp	[as_operand_size],4
	if_equal	as_insertps_size_ok
	cmp	[as_operand_size],0
	if_not_equal	as_invalid_operand_size
      as_insertps_size_ok:
	jmp	as_mmx_imm8
      as_insertps_xmmreg_reg:
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	mov	bl,al
	jmp	as_mmx_nomem_imm8
as_pextrq_instruction:
	mov	[as_mmx_size],8
	jmp	as_pextr_instruction
as_pextrd_instruction:
	mov	[as_mmx_size],4
	jmp	as_pextr_instruction
as_pextrw_instruction:
	mov	[as_mmx_size],2
	jmp	as_pextr_instruction
as_pextrb_instruction:
	mov	[as_mmx_size],1
      as_pextr_instruction:
	call	as_setup_66_0f_3a
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_pextr_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_mmx_size]
	cmp	al,[as_operand_size]
	if_equal	as_pextr_size_ok
	cmp	[as_operand_size],0
	if_not_equal	as_invalid_operand_size
      as_pextr_size_ok:
	cmp	al,8
	if_not_equal	as_pextr_prefix_ok
	call	as_operand_64bit
      as_pextr_prefix_ok:
	push	edx ebx ecx
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_postbyte_register],al
	pop	ecx ebx edx
	jmp	as_mmx_imm8
      as_pextr_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	cmp	[as_mmx_size],4
	if_above	as_pextrq_reg
	cmp	ah,4
	if_equal	as_pextr_reg_size_ok
	jmp	as_pextr_invalid_size
	cmp	ah,8
	if_equal	as_pextr_reg_size_ok
      as_pextr_invalid_size:
	jmp	as_invalid_operand_size
      as_pextrq_reg:
	cmp	ah,8
	if_not_equal	as_pextr_invalid_size
	call	as_operand_64bit
      as_pextr_reg_size_ok:
	mov	[as_operand_size],0
	push	eax
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	mov	ebx,eax
	pop	eax
	mov	[as_postbyte_register],al
	mov	al,ah
	cmp	[as_mmx_size],2
	if_not_equal	as_pextr_reg_store
	mov	[as_opcode_prefix],0
	mov	[as_extended_code],0C5h
	call	as_make_mmx_prefix
	jmp	as_mmx_nomem_imm8
      as_pextr_reg_store:
	cmp	bh,16
	if_not_equal	as_invalid_operand_size
	xchg	bl,[as_postbyte_register]
	jmp	as_mmx_nomem_imm8
as_pinsrb_instruction:
	mov	[as_mmx_size],1
	jmp	as_pinsr_instruction
as_pinsrd_instruction:
	mov	[as_mmx_size],4
	jmp	as_pinsr_instruction
as_pinsrq_instruction:
	mov	[as_mmx_size],8
	call	as_operand_64bit
      as_pinsr_instruction:
	call	as_setup_66_0f_3a
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_postbyte_register],al
      as_pinsr_xmmreg:
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_pinsr_xmmreg_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	cmp	[as_operand_size],0
	if_equal	as_mmx_imm8
	mov	al,[as_mmx_size]
	cmp	al,[as_operand_size]
	if_equal	as_mmx_imm8
	jmp	as_invalid_operand_size
      as_pinsr_xmmreg_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	cmp	[as_mmx_size],8
	if_equal	as_pinsrq_xmmreg_reg
	cmp	ah,4
	if_equal	as_mmx_nomem_imm8
	jmp	as_invalid_operand_size
      as_pinsrq_xmmreg_reg:
	cmp	ah,8
	if_equal	as_mmx_nomem_imm8
	jmp	as_invalid_operand_size
as_pmovsxbw_instruction:
	mov	[as_mmx_size],8
	jmp	as_pmovsx_instruction
as_pmovsxbd_instruction:
	mov	[as_mmx_size],4
	jmp	as_pmovsx_instruction
as_pmovsxbq_instruction:
	mov	[as_mmx_size],2
	jmp	as_pmovsx_instruction
as_pmovsxwd_instruction:
	mov	[as_mmx_size],8
	jmp	as_pmovsx_instruction
as_pmovsxwq_instruction:
	mov	[as_mmx_size],4
	jmp	as_pmovsx_instruction
as_pmovsxdq_instruction:
	mov	[as_mmx_size],8
      as_pmovsx_instruction:
	call	as_setup_66_0f_38
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_pmovsx_xmmreg_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	cmp	[as_operand_size],0
	if_equal	as_instruction_ready
	mov	al,[as_mmx_size]
	cmp	al,[as_operand_size]
	if_not_equal	as_invalid_operand_size
	jmp	as_instruction_ready
      as_pmovsx_xmmreg_reg:
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	bl,al
	jmp	as_nomem_instruction_ready
      as_setup_66_0f_38:
	mov	[as_extended_code],38h
	mov	[as_supplemental_code],al
	mov	[as_base_code],0Fh
	mov	[as_opcode_prefix],66h
	ret

as_xsaves_instruction_64bit:
	call	as_operand_64bit
as_xsaves_instruction:
	mov	ah,0C7h
	jmp	as_xsave_common
as_fxsave_instruction_64bit:
	call	as_operand_64bit
as_fxsave_instruction:
	mov	ah,0AEh
	xor	cl,cl
      as_xsave_common:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],ah
	mov	[as_postbyte_register],al
	mov	[as_mmx_size],cl
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	xor	ah,ah
	xchg	ah,[as_operand_size]
	or	ah,ah
	if_zero	as_xsave_size_ok
	cmp	ah,[as_mmx_size]
	if_not_equal	as_invalid_operand_size
      as_xsave_size_ok:
	jmp	as_instruction_ready
as_clflush_instruction:
	mov	ah,0AEh
	mov	cl,1
	jmp	as_xsave_common
as_cldemote_instruction:
	mov	ah,1Ch
	mov	cl,1
	jmp	as_xsave_common
as_stmxcsr_instruction:
	mov	ah,0AEh
	mov	cl,4
	jmp	as_xsave_common
as_prefetch_instruction:
	mov	[as_extended_code],18h
      as_prefetch_mem_8bit:
	mov	[as_base_code],0Fh
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	or	ah,ah
	if_zero	as_prefetch_size_ok
	cmp	ah,1
	if_not_equal	as_invalid_operand_size
      as_prefetch_size_ok:
	call	as_get_address
	jmp	as_instruction_ready
as_amd_prefetch_instruction:
	mov	[as_extended_code],0Dh
	jmp	as_prefetch_mem_8bit
as_clflushopt_instruction:
	mov	[as_extended_code],0AEh
	mov	[as_opcode_prefix],66h
	jmp	as_prefetch_mem_8bit
as_pcommit_instruction:
	mov	as_u8 [edi],66h
	inc	edi
as_fence_instruction:
	mov	bl,al
	mov	ax,0AE0Fh
	stos	as_u16 [edi]
	mov	al,bl
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
as_pause_instruction:
	mov	ax,90F3h
	stos	as_u16 [edi]
	jmp	as_instruction_assembled
as_movntq_instruction:
	mov	[as_mmx_size],8
	jmp	as_movnt_instruction
as_movntpd_instruction:
	mov	[as_opcode_prefix],66h
as_movntps_instruction:
	mov	[as_mmx_size],16
      as_movnt_instruction:
	mov	[as_extended_code],al
	mov	[as_base_code],0Fh
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_mmx_register
	cmp	ah,[as_mmx_size]
	if_not_equal	as_invalid_operand_size
	mov	[as_postbyte_register],al
	jmp	as_instruction_ready

as_movntsd_instruction:
	mov	[as_opcode_prefix],0F2h
	mov	[as_mmx_size],8
	jmp	as_movnts_instruction
as_movntss_instruction:
	mov	[as_opcode_prefix],0F3h
	mov	[as_mmx_size],4
      as_movnts_instruction:
	mov	[as_extended_code],al
	mov	[as_base_code],0Fh
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	cmp	al,[as_mmx_size]
	if_equal	as_movnts_size_ok
	test	al,al
	if_not_zero	as_invalid_operand_size
      as_movnts_size_ok:
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_postbyte_register],al
	jmp	as_instruction_ready

as_movdiri_instruction:
	mov	[as_supplemental_code],al
	mov	al,38h
as_movnti_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_register
	cmp	ah,4
	if_equal	as_movnti_store
	cmp	ah,8
	if_not_equal	as_invalid_operand_size
	call	as_operand_64bit
      as_movnti_store:
	mov	[as_postbyte_register],al
	jmp	as_instruction_ready
as_monitor_instruction:
	mov	[as_postbyte_register],al
	cmp	as_u8 [esi],0
	if_equal	as_monitor_instruction_store
	cmp	as_u8 [esi],0Fh
	if_equal	as_monitor_instruction_store
	call	as_take_register
	cmp	ax,0400h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_register
	cmp	ax,0401h
	if_not_equal	as_invalid_operand
	cmp	[as_postbyte_register],0C8h
	if_not_equal	as_monitor_instruction_store
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_register
	cmp	ax,0402h
	if_not_equal	as_invalid_operand
      as_monitor_instruction_store:
	mov	ax,010Fh
	stos	as_u16 [edi]
	mov	al,[as_postbyte_register]
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
as_hreset_instruction:
	call	as_take_byte_value
	mov	dl,al
	cmp	as_u8 [esi],','
	if_not_equal	as_hreset_instruction_store
	lods	as_u8 [esi]
	call	as_take_register
	cmp	ax,0400h
	if_not_equal	as_invalid_operand
      as_hreset_instruction_store:
	mov	eax,0F03A0FF3h
	stos	as_u32 [edi]
	mov	al,0C0h
	mov	ah,dl
	stos	as_u16 [edi]
	jmp	as_instruction_assembled

as_pconfig_instruction:
	mov	[as_postbyte_register],al
	jmp	as_monitor_instruction_store
as_movntdqa_instruction:
	call	as_setup_66_0f_38
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	jmp	as_instruction_ready

as_extrq_instruction:
	mov	[as_opcode_prefix],66h
	mov	[as_base_code],0Fh
	mov	[as_extended_code],78h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_postbyte_register],al
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_extrq_xmmreg_xmmreg
	test	ah,not 1
	if_not_zero	as_invalid_operand_size
	cmp	al,'('
	if_not_equal	as_invalid_operand
	xor	bl,bl
	xchg	bl,[as_postbyte_register]
	call	as_store_nomem_instruction
	call	as_get_byte_value
	stosb
	call	as_append_imm8
	jmp	as_instruction_assembled
      as_extrq_xmmreg_xmmreg:
	inc	[as_extended_code]
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	bl,al
	jmp	as_nomem_instruction_ready
as_insertq_instruction:
	mov	[as_opcode_prefix],0F2h
	mov	[as_base_code],0Fh
	mov	[as_extended_code],78h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_postbyte_register],al
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	bl,al
	cmp	as_u8 [esi],','
	if_equal	as_insertq_with_imm
	inc	[as_extended_code]
	jmp	as_nomem_instruction_ready
      as_insertq_with_imm:
	call	as_store_nomem_instruction
	call	as_append_imm8
	call	as_append_imm8
	jmp	as_instruction_assembled

as_crc32_instruction:
	mov	[as_opcode_prefix],0F2h
	mov	[as_base_code],0Fh
	mov	[as_extended_code],38h
	mov	[as_supplemental_code],0F0h
	call	as_take_register
	mov	[as_postbyte_register],al
	cmp	ah,4
	if_equal	as_crc32_reg_size_ok
	cmp	ah,8
	if_not_equal	as_invalid_operand
	jmp	as_illegal_instruction
      as_crc32_reg_size_ok:
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_crc32_reg_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	test	al,al
	if_zero	as_crc32_unknown_size
	cmp	al,1
	if_equal	as_crc32_reg_mem_store
	inc	[as_supplemental_code]
	call	as_operand_autodetect
      as_crc32_reg_mem_store:
	jmp	as_instruction_ready
      as_crc32_unknown_size:
	call	as_recoverable_unknown_size
	jmp	as_crc32_reg_mem_store
      as_crc32_reg_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	mov	al,ah
	cmp	al,1
	if_equal	as_crc32_reg_reg_store
	inc	[as_supplemental_code]
	call	as_operand_autodetect
      as_crc32_reg_reg_store:
	jmp	as_nomem_instruction_ready
as_popcnt_instruction:
	mov	[as_opcode_prefix],0F3h
	jmp	as_bs_instruction
as_movbe_instruction:
	mov	[as_supplemental_code],al
	mov	[as_extended_code],38h
	mov	[as_base_code],0Fh
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_equal	as_movbe_mem
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_argument
	call	as_get_address
	mov	al,[as_operand_size]
	call	as_operand_autodetect
	jmp	as_instruction_ready
      as_movbe_mem:
	inc	[as_supplemental_code]
	call	as_get_address
	push	edx ebx ecx
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_register
	mov	[as_postbyte_register],al
	pop	ecx ebx edx
	mov	al,[as_operand_size]
	call	as_operand_autodetect
	jmp	as_instruction_ready
as_adx_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],38h
	mov	[as_supplemental_code],0F6h
	mov	[as_operand_prefix],al
	call	as_get_reg_mem
	if_carry	as_adx_reg_reg
	mov	al,[as_operand_size]
	cmp	al,4
	if_equal	as_instruction_ready
	cmp	al,8
	if_not_equal	as_invalid_operand_size
	call	as_operand_64bit
	jmp	as_instruction_ready
      as_adx_reg_reg:
	cmp	ah,4
	if_equal	as_nomem_instruction_ready
	cmp	ah,8
	if_not_equal	as_invalid_operand_size
	call	as_operand_64bit
	jmp	as_nomem_instruction_ready
as_rdpid_instruction:
	mov	[as_postbyte_register],al
	mov	[as_extended_code],0C7h
	mov	[as_base_code],0Fh
	mov	[as_opcode_prefix],0F3h
	call	as_take_register
	mov	bl,al
	cmp	ah,4
	if_not_equal	as_invalid_operand_size
	jmp	as_nomem_instruction_ready
      as_rdpid_64bit:
	cmp	ah,8
	if_not_equal	as_invalid_operand_size
	jmp	as_nomem_instruction_ready
as_ptwrite_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],0AEh
	mov	[as_postbyte_register],al
	mov	[as_opcode_prefix],0F3h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_ptwrite_reg
      as_ptwrite_mem:
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	cmp	al,4
	if_equal	as_ptwrite_mem_store
	cmp	al,8
	if_equal	as_ptwrite_mem_64bit
	or	al,al
	if_not_zero	as_invalid_operand_size
	call	as_recoverable_unknown_size
	jmp	as_ptwrite_mem_store
      as_ptwrite_mem_64bit:
	call	as_operand_64bit
      as_ptwrite_mem_store:
	mov	al,[as_operand_size]
	call	as_operand_autodetect
	jmp	as_instruction_ready
      as_ptwrite_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	mov	al,ah
	cmp	al,4
	if_equal	as_nomem_instruction_ready
	cmp	al,8
	if_not_equal	as_invalid_operand_size
	call	as_operand_64bit
	jmp	as_nomem_instruction_ready

as_vmclear_instruction:
	mov	[as_opcode_prefix],66h
	jmp	as_vmx_instruction
as_vmxon_instruction:
	mov	[as_opcode_prefix],0F3h
as_vmx_instruction:
	mov	[as_postbyte_register],al
	mov	[as_extended_code],0C7h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_vmx_size_ok
	cmp	al,8
	if_not_equal	as_invalid_operand_size
      as_vmx_size_ok:
	mov	[as_base_code],0Fh
	jmp	as_instruction_ready
as_vmread_instruction:
	mov	[as_extended_code],78h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_vmread_nomem
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_register
	mov	[as_postbyte_register],al
	call	as_vmread_check_size
	jmp	as_vmx_size_ok
      as_vmread_nomem:
	lods	as_u8 [esi]
	call	as_convert_register
	push	eax
	call	as_vmread_check_size
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_register
	mov	[as_postbyte_register],al
	call	as_vmread_check_size
	pop	ebx
	mov	[as_base_code],0Fh
	jmp	as_nomem_instruction_ready
      as_vmread_check_size:
	cmp	[as_operand_size],4
	if_not_equal	as_invalid_operand_size
	ret
      as_vmread_long:
	cmp	[as_operand_size],8
	if_not_equal	as_invalid_operand_size
	ret
as_vmwrite_instruction:
	mov	[as_extended_code],79h
	call	as_take_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_vmwrite_nomem
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	call	as_vmread_check_size
	jmp	as_vmx_size_ok
      as_vmwrite_nomem:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	mov	[as_base_code],0Fh
	jmp	as_nomem_instruction_ready
as_vmx_inv_instruction:
	call	as_setup_66_0f_38
	call	as_take_register
	mov	[as_postbyte_register],al
	call	as_vmread_check_size
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_vmx_size_ok
	cmp	al,16
	if_not_equal	as_invalid_operand_size
	jmp	as_vmx_size_ok
as_simple_svm_instruction:
	push	eax
	mov	[as_base_code],0Fh
	mov	[as_extended_code],1
	call	as_take_register
	or	al,al
	if_not_zero	as_invalid_operand
      as_simple_svm_detect_size:
	cmp	ah,2
	if_equal	as_simple_svm_16bit
	cmp	ah,4
	if_equal	as_simple_svm_32bit
	jmp	as_invalid_operand_size
	jmp	as_simple_svm_store
      as_simple_svm_16bit:
	cmp	[as_code_type],16
	if_equal	as_simple_svm_store
	jmp	as_prefixed_svm_store
      as_simple_svm_32bit:
	cmp	[as_code_type],32
	if_equal	as_simple_svm_store
      as_prefixed_svm_store:
	mov	al,67h
	stos	as_u8 [edi]
      as_simple_svm_store:
	call	as_store_classic_instruction_code
	pop	eax
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
as_skinit_instruction:
	call	as_take_register
	cmp	ax,0400h
	if_not_equal	as_invalid_operand
	mov	al,0DEh
	jmp	as_simple_instruction_0f_01
as_clzero_instruction:
	call	as_take_register
	or	al,al
	if_not_zero	as_invalid_operand
	mov	al,0FCh
	cmp	ah,4
	if_not_equal	as_invalid_operand
	jmp	as_simple_instruction_0f_01
      as_clzero_64bit:
	cmp	ah,8
	if_not_equal	as_invalid_operand
	jmp	as_simple_instruction_0f_01
as_invlpga_instruction:
	push	eax
	mov	[as_base_code],0Fh
	mov	[as_extended_code],1
	call	as_take_register
	or	al,al
	if_not_zero	as_invalid_operand
	mov	bl,ah
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_register
	cmp	ax,0401h
	if_not_equal	as_invalid_operand
	mov	ah,bl
	jmp	as_simple_svm_detect_size

as_senduipi_instruction:
	jmp	as_illegal_instruction
	mov	[as_opcode_prefix],0F3h
as_rdrand_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],0C7h
	mov	[as_postbyte_register],al
	call	as_take_register
	mov	bl,al
	cmp	[as_opcode_prefix],0F3h
	if_equal	as_senduipi_reg64
	mov	al,ah
	call	as_operand_autodetect
	jmp	as_nomem_instruction_ready
      as_senduipi_reg64:
	cmp	ah,8
	if_not_equal	as_invalid_operand_size
	jmp	as_nomem_instruction_ready
as_rdfsbase_instruction:
	jmp	as_illegal_instruction
	mov	[as_opcode_prefix],0F3h
	mov	[as_base_code],0Fh
	mov	[as_extended_code],0AEh
	mov	[as_postbyte_register],al
	call	as_take_register
	mov	bl,al
	mov	al,ah
	cmp	ah,2
	if_equal	as_invalid_operand_size
	call	as_operand_autodetect
	jmp	as_nomem_instruction_ready

as_xabort_instruction:
	call	as_take_byte_value
	mov	dl,al
	mov	ax,0F8C6h
	stos	as_u16 [edi]
	mov	al,dl
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
as_xbegin_instruction:
	lods	as_u8 [esi]
	cmp	al,'('
	if_not_equal	as_invalid_operand
	mov	al,[as_code_type]
	cmp	al,64
	if_equal	as_xbegin_64bit
	cmp	al,32
	if_equal	as_xbegin_32bit
      as_xbegin_16bit:
	call	as_get_address_word_value
	add	edi,4
	mov	ebp,[as_addressing_space]
	call	as_calculate_relative_offset
	sub	edi,4
	shl	eax,16
	mov	ax,0F8C7h
	stos	as_u32 [edi]
	jmp	as_instruction_assembled
      as_xbegin_32bit:
	call	as_get_address_dword_value
	jmp	as_xbegin_address_ok
      as_xbegin_64bit:
	call	as_get_address_qword_value
      as_xbegin_address_ok:
	add	edi,5
	mov	ebp,[as_addressing_space]
	call	as_calculate_relative_offset
	sub	edi,5
	mov	edx,eax
	sign_extend_word
	cmp	eax,edx
	if_not_equal	as_xbegin_rel32
	mov	al,66h
	stos	as_u8 [edi]
	mov	eax,edx
	shl	eax,16
	mov	ax,0F8C7h
	stos	as_u32 [edi]
	jmp	as_instruction_assembled
      as_xbegin_rel32:
	sub	edx,1
	if_not_overflow	as_xbegin_rel32_ok
      as_xbegin_rel32_ok:
	mov	ax,0F8C7h
	stos	as_u16 [edi]
	mov	eax,edx
	stos	as_u32 [edi]
	jmp	as_instruction_assembled

      as_get_bnd_size:
	mov	al,4
	jmp	as_bnd_size_ok
	add	al,4
      as_bnd_size_ok:
	mov	[as_address_size],al
	ret
      as_get_address_component:
	mov	[as_free_address_range],0
	call	as_calculate_address
	mov	[as_address_high],edx
	mov	edx,eax
	or	bx,bx
	if_zero	as_address_component_ok
	mov	al,bl
	or	al,bh
	shr	al,4
	or	al,[as_address_size]
	cmp	al,4
	if_equal	as_address_component_ok
	cmp	al,8
	if_not_equal	as_invalid_address
      as_address_component_ok:
	ret
as_bndldx_instruction:
      as_get_sib_address_components:
	lods	as_u8 [esi]
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address_prefixes
	call	as_get_address_component
	cmp	as_u8 [esi-1],']'
	if_equal	as_bnd_mib_ok
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	cmp	al,'('
	if_not_equal	as_invalid_operand
	mov	al,[as_address_sign]
	push	eax ebx ecx edx
	push	[as_address_symbol]
	call	as_get_address_component
	lods	as_u8 [esi]
	cmp	al,']'
	if_not_equal	as_invalid_operand
	or	dl,bl
	or	dl,[as_address_sign]
	or	edx,[as_address_high]
	if_not_zero	as_invalid_address
	mov	[as_address_register],bh
	pop	[as_address_symbol]
	pop	edx ecx ebx eax
	mov	[as_address_sign],al
	or	bl,bl
	if_zero	as_mib_place_index
	or	bh,bh
	if_not_zero	as_invalid_address
	mov	bh,bl
      as_mib_place_index:
	mov	bl,[as_address_register]
	xor	cl,cl
	or	bl,bl
	if_zero	as_bnd_mib_ok
	inc	cl
      as_bnd_mib_ok:
	ret

as_tpause_instruction:
	mov	[as_postbyte_register],6
	mov	[as_extended_code],0AEh
	mov	[as_base_code],0Fh
	mov	[as_opcode_prefix],al
	call	as_take_register
	cmp	ah,4
	if_not_equal	as_invalid_operand_size
	mov	bl,al
	cmp	as_u8 [esi],','
	if_not_equal	as_nomem_instruction_ready
	inc	esi
	call	as_take_register
	cmp	ax,0402h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_register
	cmp	ax,0400h
	if_not_equal	as_invalid_operand
	jmp	as_nomem_instruction_ready
as_umonitor_instruction:
	mov	[as_postbyte_register],6
	mov	[as_extended_code],0AEh
	mov	[as_base_code],0Fh
	mov	[as_opcode_prefix],0F3h
	call	as_take_register
	mov	bl,al
	cmp	ah,4
	if_equal	as_umonitor_reg32
	shl	ah,3
	cmp	ah,[as_code_type]
	if_equal	as_umonitor_ok
	jmp	as_invalid_operand_size
      as_umonitor_reg32:
	call	as_address_32bit_prefix
      as_umonitor_ok:
	jmp	as_nomem_instruction_ready
as_movdir64b_instruction:
	call	as_setup_66_0f_38
      as_movdir64b_reg_mem:
	call	as_take_register
	mov	[as_postbyte_register],al
	xor	al,al
	xchg	al,[as_operand_size]
	push	eax
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_movdir64b_ready
	cmp	al,64
	if_not_equal	as_invalid_operand_size
      as_movdir64b_ready:
	push	edi
	call	as_store_instruction
	pop	ebx eax
	mov	cl,[as_code_type]
	cmp	as_u8 [ebx],67h
	if_not_equal	as_movdir64b_size_check
	shr	cl,1
	cmp	cl,16
	if_above_equal	as_movdir64b_size_check
	mov	cl,32
      as_movdir64b_size_check:
	shl	al,3
	cmp	al,cl
	if_not_equal	as_invalid_operand_size
	jmp	as_instruction_assembled
as_enqcmd_instruction:
	mov	[as_opcode_prefix],al
	mov	[as_base_code],0Fh
	mov	[as_extended_code],38h
	mov	[as_supplemental_code],0F8h
	jmp	as_movdir64b_reg_mem

as_setssbsy_instruction:
	shl	eax,24
	or	eax,010FF3h
	stos	as_u32 [edi]
	jmp	as_instruction_assembled
as_rstorssp_instruction:
	mov	ah,1
	jmp	as_setup_clrssbsy
as_clrssbsy_instruction:
	mov	ah,0AEh
      as_setup_clrssbsy:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],ah
	mov	[as_postbyte_register],al
	mov	[as_opcode_prefix],0F3h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	test	[as_operand_size],not 8
	if_not_zero	as_invalid_operand_size
	jmp	as_instruction_ready
as_rdsspq_instruction:
	mov	[as_rex_prefix],48h
as_rdsspd_instruction:
	mov	ah,1Eh
	jmp	as_setup_incssp
as_incsspq_instruction:
	mov	[as_rex_prefix],48h
as_incsspd_instruction:
	mov	ah,0AEh
      as_setup_incssp:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],ah
	mov	[as_postbyte_register],al
	mov	[as_opcode_prefix],0F3h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	call	as_cet_size_check
	jmp	as_nomem_instruction_ready
      as_cet_size_check:
	cmp	[as_rex_prefix],0
	if_equal	as_cet_dword
	jmp	as_illegal_instruction
      as_cet_dword:
	cmp	ah,4
	if_not_equal	as_invalid_operand_size
	ret
as_wrussq_instruction:
	mov	[as_opcode_prefix],66h
as_wrssq_instruction:
	mov	[as_rex_prefix],48h
	jmp	as_wrssd_instruction
as_wrussd_instruction:
	mov	[as_opcode_prefix],66h
as_wrssd_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],38h
	mov	[as_supplemental_code],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_wrss_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	push	edx ebx ecx
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_register
	mov	[as_postbyte_register],al
	pop	ecx ebx edx
	call	as_cet_size_check
	jmp	as_instruction_ready
      as_wrss_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_register
	mov	bl,al
	xchg	bl,[as_postbyte_register]
	call	as_cet_size_check
	jmp	as_nomem_instruction_ready
as_endbr_instruction:
	shl	eax,24
	or	eax,1E0FF3h
	stos	as_u32 [edi]
	jmp	as_instruction_assembled

as_take_register:
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
as_convert_register:
	mov	ah,al
	shr	ah,4
	and	al,0Fh
	cmp	ah,8
	if_equal	as_match_register_size
	cmp	ah,4
	if_above	as_invalid_operand
	cmp	ah,1
	if_above	as_match_register_size
	cmp	al,4
	if_below	as_match_register_size
	or	ah,ah
	if_zero	as_high_byte_register
	or	[as_rex_prefix],40h
      as_match_register_size:
	cmp	ah,[as_operand_size]
	if_equal	as_register_size_ok
	cmp	[as_operand_size],0
	if_not_equal	as_operand_sizes_do_not_match
	mov	[as_operand_size],ah
      as_register_size_ok:
	ret
      as_high_byte_register:
	mov	ah,1
	or	[as_rex_prefix],10h
	jmp	as_match_register_size
as_convert_fpu_register:
	mov	ah,al
	shr	ah,4
	and	al,111b
	cmp	ah,10
	if_not_equal	as_invalid_operand
	jmp	as_match_register_size
as_convert_mmx_register:
	mov	ah,al
	shr	ah,4
	cmp	ah,0Ch
	if_equal	as_xmm_register
	if_above	as_invalid_operand
	and	al,111b
	cmp	ah,0Bh
	if_not_equal	as_invalid_operand
	mov	ah,8
	jmp	as_match_register_size
      as_xmm_register:
	and	al,0Fh
	mov	ah,16
	cmp	al,8
	if_below	as_match_register_size
	jmp	as_invalid_operand
	jmp	as_match_register_size
as_convert_xmm_register:
	mov	ah,al
	shr	ah,4
	cmp	ah,0Ch
	if_equal	as_xmm_register
	jmp	as_invalid_operand
as_get_size_operator:
	xor	ah,ah
	cmp	al,11h
	if_not_equal	as_no_size_operator
	mov	[as_size_declared],1
	lods	as_u16 [esi]
	xchg	al,ah
	or	[as_operand_flags],1
	cmp	ah,[as_operand_size]
	if_equal	as_size_operator_ok
	cmp	[as_operand_size],0
	if_not_equal	as_operand_sizes_do_not_match
	mov	[as_operand_size],ah
      as_size_operator_ok:
	ret
      as_no_size_operator:
	mov	[as_size_declared],0
	cmp	al,'['
	if_not_equal	as_size_operator_ok
	and	[as_operand_flags],not 1
	ret
as_get_jump_operator:
	mov	[as_jump_type],0
	cmp	al,12h
	if_not_equal	as_jump_operator_ok
	lods	as_u16 [esi]
	mov	[as_jump_type],al
	mov	al,ah
      as_jump_operator_ok:
	ret
as_get_address:
	and	[as_address_size],0
      as_get_address_of_required_size:
	call	as_get_address_prefixes
	and	[as_free_address_range],0
	call	as_calculate_address
	cmp	as_u8 [esi-1],']'
	if_not_equal	as_invalid_address
	mov	[as_address_high],edx
	mov	edx,eax
	cmp	[as_address_size_declared],0
	if_not_equal	as_address_ok
	cmp	[as_segment_register],4
	if_above	as_address_ok
	or	bx,bx
	if_not_zero	as_clear_address_size
	jmp	as_address_ok
      as_calculate_relative_address:
	mov	edx,[as_address_symbol]
	mov	[as_symbol_identifier],edx
	mov	edx,[as_address_high]
	mov	ebp,[as_addressing_space]
	call	as_calculate_relative_offset
	mov	[as_address_high],edx
	sign_extend_dword
	cmp	edx,[as_address_high]
	if_equal	as_address_high_ok
	call	as_recoverable_overflow
      as_address_high_ok:
	mov	edx,eax
	ror	ecx,16
	mov	cl,[as_value_type]
	rol	ecx,16
	mov	bx,9900h
      as_clear_address_size:
	and	ch,not 0Fh
      as_address_ok:
	ret
as_get_address_prefixes:
	and	[as_segment_register],0
	and	[as_address_size_declared],0
	mov	al,[as_code_type]
	shr	al,3
	mov	[as_value_size],al
	mov	al,[esi]
	and	al,11110000b
	cmp	al,60h
	if_not_equal	as_get_address_size_prefix
	lods	as_u8 [esi]
	sub	al,60h
	mov	[as_segment_register],al
	mov	al,[esi]
	and	al,11110000b
      as_get_address_size_prefix:
	cmp	al,70h
	if_not_equal	as_address_size_prefix_ok
	lods	as_u8 [esi]
	sub	al,70h
	cmp	al,2
	if_below	as_invalid_address_size
	cmp	al,8
	if_above	as_invalid_address_size
	mov	[as_value_size],al
	or	[as_address_size_declared],1
	or	[as_address_size],al
	cmp	al,[as_address_size]
	if_not_equal	as_invalid_address_size
      as_address_size_prefix_ok:
	ret
as_operand_16bit:
	cmp	[as_code_type],16
	if_equal	as_size_prefix_ok
	mov	[as_operand_prefix],66h
	ret
as_operand_32bit:
	cmp	[as_code_type],16
	if_not_equal	as_size_prefix_ok
	mov	[as_operand_prefix],66h
      as_size_prefix_ok:
	ret
as_operand_64bit:
	jmp	as_illegal_instruction
as_operand_autodetect:
	cmp	al,2
	if_equal	as_operand_16bit
	cmp	al,4
	if_equal	as_operand_32bit
	cmp	al,8
	if_equal	as_operand_64bit
	jmp	as_invalid_operand_size
as_store_segment_prefix_if_necessary:
	mov	al,[as_segment_register]
	or	al,al
	if_zero	as_segment_prefix_ok
	cmp	al,4
	if_above	as_segment_prefix_386
	cmp	al,3
	if_equal	as_ss_prefix
	if_below	as_segment_prefix_86
	cmp	bl,25h
	if_equal	as_segment_prefix_86
	cmp	bh,25h
	if_equal	as_segment_prefix_86
	cmp	bh,45h
	if_equal	as_segment_prefix_86
	cmp	bh,44h
	if_equal	as_segment_prefix_86
	ret
      as_ss_prefix:
	cmp	bl,25h
	if_equal	as_segment_prefix_ok
	cmp	bh,25h
	if_equal	as_segment_prefix_ok
	cmp	bh,45h
	if_equal	as_segment_prefix_ok
	cmp	bh,44h
	if_equal	as_segment_prefix_ok
	jmp	as_segment_prefix_86
as_store_segment_prefix:
	mov	al,[as_segment_register]
	or	al,al
	if_zero	as_segment_prefix_ok
	cmp	al,5
	if_above_equal	as_segment_prefix_386
      as_segment_prefix_86:
	dec	al
	shl	al,3
	add	al,26h
	stos	as_u8 [edi]
	jmp	as_segment_prefix_ok
      as_segment_prefix_386:
	add	al,64h-5
	stos	as_u8 [edi]
      as_segment_prefix_ok:
	ret
as_store_instruction_code:
	cmp	[as_vex_required],0
	if_not_equal	as_store_vex_instruction_code
as_store_classic_instruction_code:
	mov	al,[as_operand_prefix]
	or	al,al
	if_zero	as_operand_prefix_ok
	stos	as_u8 [edi]
      as_operand_prefix_ok:
	mov	al,[as_opcode_prefix]
	or	al,al
	if_zero	as_opcode_prefix_ok
	stos	as_u8 [edi]
      as_opcode_prefix_ok:
	mov	al,[as_rex_prefix]
	test	al,40h
	if_zero	as_rex_prefix_ok
	jmp	as_invalid_operand
      as_rex_prefix_ok:
	mov	al,[as_base_code]
	stos	as_u8 [edi]
	cmp	al,0Fh
	if_not_equal	as_instruction_code_ok
      as_store_extended_code:
	mov	al,[as_extended_code]
	stos	as_u8 [edi]
	cmp	al,38h
	if_equal	as_store_supplemental_code
	cmp	al,3Ah
	if_equal	as_store_supplemental_code
      as_instruction_code_ok:
	ret
      as_store_supplemental_code:
	mov	al,[as_supplemental_code]
	stos	as_u8 [edi]
	ret
as_store_nomem_instruction:
	test	[as_postbyte_register],10000b
	if_zero	as_nomem_reg_high_code_ok
	or	[as_vex_required],10h
	and	[as_postbyte_register],1111b
      as_nomem_reg_high_code_ok:
	test	[as_postbyte_register],1000b
	if_zero	as_nomem_reg_code_ok
	or	[as_rex_prefix],44h
	and	[as_postbyte_register],111b
      as_nomem_reg_code_ok:
	test	bl,10000b
	if_zero	as_nomem_rm_high_code_ok
	or	[as_rex_prefix],42h
	or	[as_vex_required],8
	and	bl,1111b
      as_nomem_rm_high_code_ok:
	test	bl,1000b
	if_zero	as_nomem_rm_code_ok
	or	[as_rex_prefix],41h
	and	bl,111b
      as_nomem_rm_code_ok:
	and	[as_displacement_compression],0
	call	as_store_instruction_code
	mov	al,[as_postbyte_register]
	shl	al,3
	or	al,bl
	or	al,11000000b
	stos	as_u8 [edi]
	ret
as_store_instruction:
	mov	[as_current_offset],edi
	and	[as_displacement_compression],0
	test	[as_postbyte_register],10000b
	if_zero	as_reg_high_code_ok
	or	[as_vex_required],10h
	and	[as_postbyte_register],1111b
      as_reg_high_code_ok:
	test	[as_postbyte_register],1000b
	if_zero	as_reg_code_ok
	or	[as_rex_prefix],44h
	and	[as_postbyte_register],111b
      as_reg_code_ok:
	jmp	as_address_value_ok
	xor	eax,eax
	bit_test	edx,31
	sub_with_borrow	eax,[as_address_high]
	if_zero	as_address_value_ok
	cmp	[as_address_high],0
	if_not_equal	as_address_value_out_of_range
	test	ch,44h
	if_not_zero	as_address_value_ok
	test	bx,8080h
	if_zero	as_address_value_ok
      as_address_value_out_of_range:
	call	as_recoverable_overflow
      as_address_value_ok:
	call	as_store_segment_prefix_if_necessary
	test	[as_vex_required],4
	if_not_zero	as_address_vsib
	or	bx,bx
	if_zero	as_address_immediate
	cmp	bx,9800h
	if_equal	as_address_rip_based
	cmp	bx,9400h
	if_equal	as_address_eip_based
	cmp	bx,9900h
	if_equal	as_address_relative
	mov	al,bl
	or	al,bh
	and	al,11110000b
	cmp	al,80h
	if_equal	as_postbyte_64bit
	cmp	al,40h
	if_equal	as_postbyte_32bit
	cmp	al,20h
	if_not_equal	as_invalid_address
	test	[as_operand_flags],80h
	if_not_zero	as_invalid_address_size
	call	as_address_16bit_prefix
	test	ch,22h
	setz	[as_displacement_compression]
	call	as_store_instruction_code
	cmp	bl,bh
	if_below_equal	as_determine_16bit_address
	xchg	bl,bh
      as_determine_16bit_address:
	cmp	bx,2600h
	if_equal	as_address_si
	cmp	bx,2700h
	if_equal	as_address_di
	cmp	bx,2300h
	if_equal	as_address_bx
	cmp	bx,2500h
	if_equal	as_address_bp
	cmp	bx,2625h
	if_equal	as_address_bp_si
	cmp	bx,2725h
	if_equal	as_address_bp_di
	cmp	bx,2723h
	if_equal	as_address_bx_di
	cmp	bx,2623h
	if_not_equal	as_invalid_address
      as_address_bx_si:
	xor	al,al
	jmp	as_postbyte_16bit
      as_address_bx_di:
	mov	al,1
	jmp	as_postbyte_16bit
      as_address_bp_si:
	mov	al,10b
	jmp	as_postbyte_16bit
      as_address_bp_di:
	mov	al,11b
	jmp	as_postbyte_16bit
      as_address_si:
	mov	al,100b
	jmp	as_postbyte_16bit
      as_address_di:
	mov	al,101b
	jmp	as_postbyte_16bit
      as_address_bx:
	mov	al,111b
	jmp	as_postbyte_16bit
      as_address_bp:
	mov	al,110b
      as_postbyte_16bit:
	test	ch,22h
	if_not_zero	as_address_16bit_value
	or	ch,ch
	if_not_zero	as_address_sizes_do_not_agree
	cmp	edx,10000h
	if_greater_equal	as_value_out_of_range
	cmp	edx,-8000h
	if_less	as_value_out_of_range
	or	dx,dx
	if_zero	as_address
	cmp	[as_displacement_compression],2
	if_above	as_address_8bit_value
	if_equal	as_address_16bit_value
	cmp	dx,80h
	if_below	as_address_8bit_value
	cmp	dx,-80h
	if_above_equal	as_address_8bit_value
      as_address_16bit_value:
	or	al,10000000b
	mov	cl,[as_postbyte_register]
	shl	cl,3
	or	al,cl
	stos	as_u8 [edi]
	mov	eax,edx
	stos	as_u16 [edi]
	ret
      as_address_8bit_value:
	or	al,01000000b
	mov	cl,[as_postbyte_register]
	shl	cl,3
	or	al,cl
	stos	as_u8 [edi]
	mov	al,dl
	stos	as_u8 [edi]
	ret
      as_address:
	cmp	al,110b
	if_equal	as_address_8bit_value
	mov	cl,[as_postbyte_register]
	shl	cl,3
	or	al,cl
	stos	as_u8 [edi]
	ret
      as_address_vsib:
	mov	al,bl
	shr	al,4
	test	al,1
	if_zero	as_vsib_high_code_ok
	or	[as_vex_register],10000b
	or	[as_vex_required],8
	xor	al,1
      as_vsib_high_code_ok:
	cmp	al,6
	if_equal	as_vsib_index_ok
	cmp	al,0Ch
	if_below	as_invalid_address
      as_vsib_index_ok:
	mov	al,bh
	shr	al,4
	cmp	al,4
	if_equal	as_postbyte_32bit
	test	al,al
	if_not_zero	as_invalid_address
      as_postbyte_32bit:
	call	as_address_32bit_prefix
	jmp	as_address_prefix_ok
      as_postbyte_64bit:
	jmp	as_invalid_address_size
      as_address_prefix_ok:
	cmp	bl,44h
	if_equal	as_invalid_address
	cmp	bl,84h
	if_equal	as_invalid_address
	test	bh,1000b
	if_zero	as_base_code_ok
	or	[as_rex_prefix],41h
      as_base_code_ok:
	test	bl,1000b
	if_zero	as_index_code_ok
	or	[as_rex_prefix],42h
      as_index_code_ok:
	test	ch,44h or 88h
	setz	[as_displacement_compression]
	call	as_store_instruction_code
	or	cl,cl
	if_zero	as_only_base_register
      as_base_and_index:
	mov	al,100b
	xor	ah,ah
	cmp	cl,1
	if_equal	as_scale_ok
	cmp	cl,2
	if_equal	as_scale_1
	cmp	cl,4
	if_equal	as_scale_2
	or	ah,11000000b
	jmp	as_scale_ok
      as_scale_2:
	or	ah,10000000b
	jmp	as_scale_ok
      as_scale_1:
	or	ah,01000000b
      as_scale_ok:
	or	bh,bh
	if_zero	as_only_index_register
	and	bl,111b
	shl	bl,3
	or	ah,bl
	and	bh,111b
	or	ah,bh
      as_sib_ready:
	test	ch,44h or 88h
	if_not_zero	as_sib_address_32bit_value
	or	ch,ch
	if_not_zero	as_address_sizes_do_not_agree
	cmp	bh,5
	if_equal	as_address_value
	or	edx,edx
	if_zero	as_sib_address
      as_address_value:
	cmp	[as_displacement_compression],2
	if_above	as_sib_address_8bit_value
	if_equal	as_sib_address_32bit_value
	cmp	edx,80h
	if_below	as_sib_address_8bit_value
	cmp	edx,-80h
	if_above_equal	as_sib_address_8bit_value
      as_sib_address_32bit_value:
	or	al,10000000b
	mov	cl,[as_postbyte_register]
	shl	cl,3
	or	al,cl
	stos	as_u16 [edi]
	jmp	as_store_address_32bit_value
      as_sib_address_8bit_value:
	or	al,01000000b
	mov	cl,[as_postbyte_register]
	shl	cl,3
	or	al,cl
	stos	as_u16 [edi]
	mov	al,dl
	stos	as_u8 [edi]
	ret
      as_sib_address:
	mov	cl,[as_postbyte_register]
	shl	cl,3
	or	al,cl
	stos	as_u16 [edi]
	ret
      as_only_index_register:
	or	ah,101b
	and	bl,111b
	shl	bl,3
	or	ah,bl
	mov	cl,[as_postbyte_register]
	shl	cl,3
	or	al,cl
	stos	as_u16 [edi]
	test	ch,44h or 88h
	if_not_zero	as_store_address_32bit_value
	or	ch,ch
	if_not_zero	as_invalid_address_size
	cmp	[as_displacement_compression],2
	if_below_equal	as_store_address_32bit_value
	mov	edx,[as_uncompressed_displacement]
	jmp	as_store_address_32bit_value
      as_zero_index_register:
	mov	bl,4
	mov	cl,1
	jmp	as_base_and_index
      as_only_base_register:
	mov	al,bh
	and	al,111b
	cmp	al,4
	if_equal	as_zero_index_register
	test	[as_operand_flags],80h
	if_not_zero	as_zero_index_register
	test	ch,44h or 88h
	if_not_zero	as_simple_address_32bit_value
	or	ch,ch
	if_not_zero	as_address_sizes_do_not_agree
	or	edx,edx
	if_zero	as_simple_address
	cmp	[as_displacement_compression],2
	if_above	as_simple_address_8bit_value
	if_equal	as_simple_address_32bit_value
	cmp	edx,80h
	if_below	as_simple_address_8bit_value
	cmp	edx,-80h
	if_above_equal	as_simple_address_8bit_value
      as_simple_address_32bit_value:
	or	al,10000000b
	mov	cl,[as_postbyte_register]
	shl	cl,3
	or	al,cl
	stos	as_u8 [edi]
	jmp	as_store_address_32bit_value
      as_simple_address_8bit_value:
	or	al,01000000b
	mov	cl,[as_postbyte_register]
	shl	cl,3
	or	al,cl
	stos	as_u8 [edi]
	mov	al,dl
	stos	as_u8 [edi]
	ret
      as_simple_address:
	cmp	al,5
	if_equal	as_simple_address_8bit_value
	mov	cl,[as_postbyte_register]
	shl	cl,3
	or	al,cl
	stos	as_u8 [edi]
	ret
      as_address_immediate:
	test	ch,44h or 88h
	if_not_zero	as_address_immediate_32bit
	test	ch,22h
	if_not_zero	as_address_immediate_16bit
	or	ch,ch
	if_not_zero	as_invalid_address_size
	cmp	[as_code_type],16
	if_equal	as_addressing_16bit
      as_address_immediate_32bit:
	call	as_address_32bit_prefix
	call	as_store_instruction_code
      as_store_immediate_address:
	mov	al,101b
	mov	cl,[as_postbyte_register]
	shl	cl,3
	or	al,cl
	stos	as_u8 [edi]
      as_store_address_32bit_value:
	test	ch,0F0h
	if_zero	as_address_32bit_relocation_ok
	mov	eax,ecx
	shr	eax,16
	cmp	al,4
	if_not_equal	as_address_32bit_relocation
	mov	al,2
      as_address_32bit_relocation:
	xchg	[as_value_type],al
	mov	ebx,[as_address_symbol]
	xchg	ebx,[as_symbol_identifier]
	call	as_mark_relocation
	mov	[as_value_type],al
	mov	[as_symbol_identifier],ebx
      as_address_32bit_relocation_ok:
	mov	eax,edx
	stos	as_u32 [edi]
	ret
      as_store_address_64bit_value:
	test	ch,0F0h
	if_zero	as_address_64bit_relocation_ok
	mov	eax,ecx
	shr	eax,16
	xchg	[as_value_type],al
	mov	ebx,[as_address_symbol]
	xchg	ebx,[as_symbol_identifier]
	call	as_mark_relocation
	mov	[as_value_type],al
	mov	[as_symbol_identifier],ebx
      as_address_64bit_relocation_ok:
	mov	eax,edx
	stos	as_u32 [edi]
	mov	eax,[as_address_high]
	stos	as_u32 [edi]
	ret
      as_address_immediate_sib:
	test	ch,44h
	if_not_zero	as_address_immediate_sib_32bit
	test	ch,not 88h
	if_not_zero	as_invalid_address_size
	test	edx,80000000h
	if_zero	as_address_immediate_sib_store
	cmp	[as_address_high],0
	if_equal	as_address_immediate_sib_nosignextend
      as_address_immediate_sib_store:
	call	as_store_instruction_code
	mov	al,100b
	mov	ah,100101b
	mov	cl,[as_postbyte_register]
	shl	cl,3
	or	al,cl
	stos	as_u16 [edi]
	jmp	as_store_address_32bit_value
      as_address_immediate_sib_32bit:
	test	ecx,0FF0000h
	if_not_zero	as_address_immediate_sib_nosignextend
	test	edx,80000000h
	if_zero	as_address_immediate_sib_store
      as_address_immediate_sib_nosignextend:
	call	as_address_32bit_prefix
	jmp	as_address_immediate_sib_store
      as_address_eip_based:
	mov	al,67h
	stos	as_u8 [edi]
      as_address_rip_based:
	jmp	as_invalid_address
	call	as_store_instruction_code
	jmp	as_store_immediate_address
      as_address_relative:
	call	as_store_instruction_code
	movzx	eax,[as_immediate_size]
	add	eax,edi
	sub	eax,[as_current_offset]
	add	eax,5
	sub	edx,eax
	if_not_overflow	as_address_relative_ok
	call	as_recoverable_overflow
      as_address_relative_ok:
	mov	al,101b
	mov	cl,[as_postbyte_register]
	shl	cl,3
	or	al,cl
	stos	as_u8 [edi]
	shr	ecx,16
	xchg	[as_value_type],cl
	mov	ebx,[as_address_symbol]
	xchg	ebx,[as_symbol_identifier]
	mov	eax,edx
	call	as_mark_relocation
	mov	[as_value_type],cl
	mov	[as_symbol_identifier],ebx
	stos	as_u32 [edi]
	ret
      as_addressing_16bit:
	cmp	edx,10000h
	if_greater_equal	as_address_immediate_32bit
	cmp	edx,-8000h
	if_less	as_address_immediate_32bit
	movzx	edx,dx
      as_address_immediate_16bit:
	call	as_address_16bit_prefix
	call	as_store_instruction_code
	mov	al,110b
	mov	cl,[as_postbyte_register]
	shl	cl,3
	or	al,cl
	stos	as_u8 [edi]
	mov	eax,edx
	stos	as_u16 [edi]
	cmp	edx,10000h
	if_greater_equal	as_value_out_of_range
	cmp	edx,-8000h
	if_less	as_value_out_of_range
	ret
      as_address_16bit_prefix:
	cmp	[as_code_type],16
	if_equal	as_instruction_prefix_ok
	mov	al,67h
	stos	as_u8 [edi]
	ret
      as_address_32bit_prefix:
	cmp	[as_code_type],32
	if_equal	as_instruction_prefix_ok
	mov	al,67h
	stos	as_u8 [edi]
      as_instruction_prefix_ok:
	ret
as_store_instruction_with_imm8:
	mov	[as_immediate_size],1
	call	as_store_instruction
	mov	al,as_u8 [as_value]
	stos	as_u8 [edi]
	ret
as_store_instruction_with_imm16:
	mov	[as_immediate_size],2
	call	as_store_instruction
	mov	ax,as_u16 [as_value]
	call	as_mark_relocation
	stos	as_u16 [edi]
	ret
as_store_instruction_with_imm32:
	mov	[as_immediate_size],4
	call	as_store_instruction
	mov	eax,as_u32 [as_value]
	call	as_mark_relocation
	stos	as_u32 [edi]
	ret
