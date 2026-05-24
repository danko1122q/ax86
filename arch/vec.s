; SPDX-License-Identifier: BSD-2-Clause
; Copyright (c) 2026 danko1122q
; All rights reserved.

as_avx_single_source_pd_instruction_er_evex:
	or	[as_vex_required],8
as_avx_single_source_pd_instruction_er:
	or	[as_operand_flags],2+4+8
	jmp	as_avx_pd_instruction
as_avx_single_source_pd_instruction_sae_evex:
	or	[as_vex_required],8
	or	[as_operand_flags],2+4
	jmp	as_avx_pd_instruction
as_avx_pd_instruction_imm8:
	mov	[as_immediate_size],1
	jmp	as_avx_pd_instruction
as_avx_pd_instruction_er:
	or	[as_operand_flags],8
as_avx_pd_instruction_sae:
	or	[as_operand_flags],4
as_avx_pd_instruction:
	mov	[as_opcode_prefix],66h
	or	[as_rex_prefix],80h
	mov	cx,0800h
	jmp	as_avx_instruction_with_broadcast
as_avx_pd_instruction_38_evex:
	or	[as_vex_required],8
	mov	[as_supplemental_code],al
	mov	al,38h
	jmp	as_avx_pd_instruction
as_avx_cvtps2dq_instruction:
	mov	[as_opcode_prefix],66h
	jmp	as_avx_single_source_ps_instruction_er
as_avx_cvtudq2ps_instruction:
	mov	[as_opcode_prefix],0F2h
as_avx_single_source_ps_instruction_er_evex:
	or	[as_vex_required],8
as_avx_single_source_ps_instruction_er:
	or	[as_operand_flags],2+4+8
	jmp	as_avx_ps_instruction
as_avx_single_source_ps_instruction_noevex:
	or	[as_operand_flags],2
	or	[as_vex_required],2
	jmp	as_avx_ps_instruction
as_avx_ps_instruction_imm8:
	mov	[as_immediate_size],1
	jmp	as_avx_ps_instruction
as_avx_ps_instruction_er:
	or	[as_operand_flags],8
as_avx_ps_instruction_sae:
	or	[as_operand_flags],4
as_avx_ps_instruction:
	mov	cx,0400h
	jmp	as_avx_instruction_with_broadcast
as_avx_ps_instruction_66_38_evex:
	or	[as_vex_required],8
	mov	[as_opcode_prefix],66h
	mov	[as_supplemental_code],al
	mov	al,38h
	jmp	as_avx_ps_instruction
as_avx_sd_instruction_er:
	or	[as_operand_flags],8
as_avx_sd_instruction_sae:
	or	[as_operand_flags],4
as_avx_sd_instruction:
	mov	[as_opcode_prefix],0F2h
	or	[as_rex_prefix],80h
	mov	cl,8
	jmp	as_avx_instruction
as_avx_ss_instruction_er:
	or	[as_operand_flags],8
as_avx_ss_instruction_sae:
	or	[as_operand_flags],4
as_avx_ss_instruction:
	mov	[as_opcode_prefix],0F3h
	mov	cl,4
	jmp	as_avx_instruction
as_avx_ss_instruction_noevex:
	or	[as_vex_required],2
	jmp	as_avx_ss_instruction
as_avx_single_source_q_instruction_38_evex:
	or	[as_operand_flags],2
as_avx_q_instruction_38_evex:
	or	[as_vex_required],8
as_avx_q_instruction_38:
	mov	[as_supplemental_code],al
	mov	al,38h
	jmp	as_avx_q_instruction
as_avx_q_instruction_38_w1_evex:
	or	[as_vex_required],8
as_avx_q_instruction_38_w1:
	or	[as_rex_prefix],8
	jmp	as_avx_q_instruction_38
as_avx_q_instruction_3a_imm8_w1:
	or	[as_rex_prefix],8
	jmp	as_avx_q_instruction_3a_imm8
as_avx_q_instruction_3a_imm8_evex:
	or	[as_vex_required],8
as_avx_q_instruction_3a_imm8:
	mov	[as_immediate_size],1
	mov	[as_supplemental_code],al
	mov	al,3Ah
	jmp	as_avx_q_instruction
as_avx_q_instruction_evex:
	or	[as_vex_required],8
as_avx_q_instruction:
	or	[as_rex_prefix],80h
	mov	ch,8
	jmp	as_avx_pi_instruction
as_avx_single_source_d_instruction_38_evex_w1:
	or	[as_rex_prefix],8
as_avx_single_source_d_instruction_38_evex:
	or	[as_vex_required],8
as_avx_single_source_d_instruction_38:
	or	[as_operand_flags],2
	jmp	as_avx_d_instruction_38
as_avx_d_instruction_38_evex:
	or	[as_vex_required],8
as_avx_d_instruction_38:
	mov	[as_supplemental_code],al
	mov	al,38h
	jmp	as_avx_d_instruction
as_avx_d_instruction_3a_imm8_evex:
	mov	[as_immediate_size],1
	or	[as_vex_required],8
	mov	[as_supplemental_code],al
	mov	al,3Ah
	jmp	as_avx_d_instruction
as_avx_single_source_d_instruction_imm8:
	or	[as_operand_flags],2
	mov	[as_immediate_size],1
	jmp	as_avx_d_instruction
as_avx_d_instruction_evex:
	or	[as_vex_required],8
as_avx_d_instruction:
	mov	ch,4
	jmp	as_avx_pi_instruction
as_avx_bw_instruction_3a_imm8_w1_evex:
	or	[as_rex_prefix],8
as_avx_bw_instruction_3a_imm8_evex:
	mov	[as_immediate_size],1
	or	[as_vex_required],8
	mov	[as_supplemental_code],al
	mov	al,3Ah
	jmp	as_avx_bw_instruction
as_avx_single_source_bw_instruction_38:
	or	[as_operand_flags],2
as_avx_bw_instruction_38:
	mov	[as_supplemental_code],al
	mov	al,38h
as_avx_bw_instruction:
	xor	ch,ch
      as_avx_pi_instruction:
	mov	[as_opcode_prefix],66h
	xor	cl,cl
	jmp	as_avx_instruction_with_broadcast
as_avx_bw_instruction_38_w1_evex:
	or	[as_rex_prefix],8
as_avx_bw_instruction_38_evex:
	or	[as_vex_required],8
	jmp	as_avx_bw_instruction_38
as_avx_pd_instruction_noevex:
	xor	cl,cl
	or	[as_vex_required],2
	mov	[as_opcode_prefix],66h
	jmp	as_avx_instruction
as_avx_ps_instruction_noevex:
	or	[as_vex_required],2
	mov	[as_opcode_prefix],0F2h
	xor	cl,cl
	jmp	as_avx_instruction
as_avx_instruction:
	xor	ch,ch
      as_avx_instruction_with_broadcast:
	mov	[as_mmx_size],cl
	mov	[as_broadcast_size],ch
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
      as_avx_xop_common:
	or	[as_vex_required],1
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
      as_avx_reg:
	lods	as_u8 [esi]
	call	as_convert_avx_register
	mov	[as_postbyte_register],al
	call	as_take_avx512_mask
      as_avx_vex_reg:
	test	[as_operand_flags],2
	if_not_zero	as_avx_vex_reg_ok
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	[as_vex_register],al
      as_avx_vex_reg_ok:
	mov	al,[as_mmx_size]
	or	al,al
	if_zero	as_avx_regs_size_ok
	mov	ah,[as_operand_size]
	or	ah,ah
	if_zero	as_avx_regs_size_ok
	cmp	al,ah
	if_equal	as_avx_regs_size_ok
	if_above	as_invalid_operand_size
	cmp	ah,16
	if_not_equal	as_invalid_operand_size
      as_avx_regs_size_ok:
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
      as_avx_regs_rm:
	call	as_take_avx_rm
	if_carry	as_avx_regs_reg
	mov	al,[as_immediate_size]
	cmp	al,1
	if_equal	as_mmx_imm8
	if_below	as_instruction_ready
	cmp	al,-4
	if_equal	as_sse_cmp_mem_ok
	cmp	as_u8 [esi],','
	if_not_equal	as_invalid_operand
	inc	esi
	call	as_take_avx_register
	shl	al,4
	if_carry	as_invalid_operand
	or	as_u8 [as_value],al
	test	al,80h
	if_zero	as_avx_regs_mem_reg_store
	jmp	as_invalid_operand
      as_avx_regs_mem_reg_store:
	call	as_take_imm4_if_needed
	call	as_store_instruction_with_imm8
	jmp	as_instruction_assembled
      as_avx_regs_reg:
	mov	bl,al
	call	as_take_avx512_rounding
	mov	al,[as_immediate_size]
	cmp	al,1
	if_equal	as_mmx_nomem_imm8
	if_below	as_nomem_instruction_ready
	cmp	al,-4
	if_equal	as_sse_cmp_nomem_ok
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	mov	al,bl
	shl	al,4
	if_carry	as_invalid_operand
	or	as_u8 [as_value],al
	test	al,80h
	if_zero	as_avx_regs_reg_
	jmp	as_invalid_operand
      as_avx_regs_reg_:
	call	as_take_avx_rm
	if_carry	as_avx_regs_reg_reg
	cmp	[as_immediate_size],-2
	if_greater	as_invalid_operand
	or	[as_rex_prefix],8
	call	as_take_imm4_if_needed
	call	as_store_instruction_with_imm8
	jmp	as_instruction_assembled
      as_avx_regs_reg_reg:
	shl	al,4
	if_carry	as_invalid_operand
	and	as_u8 [as_value],1111b
	or	as_u8 [as_value],al
	call	as_take_imm4_if_needed
	call	as_store_nomem_instruction
	mov	al,as_u8 [as_value]
	stos	as_u8 [edi]
	jmp	as_instruction_assembled
      as_take_avx_rm:
	xor	cl,cl
	xchg	cl,[as_operand_size]
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_equal	as_take_avx_mem
	cmp	al,10h
	if_not_equal	as_invalid_operand
	mov	[as_operand_size],cl
	lods	as_u8 [esi]
	call	as_convert_avx_register
	or	cl,cl
	if_not_zero	as_avx_reg_ok
	or	cl,[as_mmx_size]
	if_zero	as_avx_reg_ok
	cmp	ah,cl
	if_equal	as_avx_reg_ok
	if_below	as_invalid_operand_size
	cmp	ah,16
	if_not_equal	as_invalid_operand_size
      as_avx_reg_ok:
	set_carry
	ret
      as_take_avx_mem:
	push	ecx
	call	as_get_address
	cmp	as_u8 [esi],'{'
	if_not_equal	as_avx_mem_ok
	inc	esi
	lods	as_u8 [esi]
	cmp	al,1Fh
	if_not_equal	as_invalid_operand
	mov	al,[esi]
	shr	al,4
	cmp	al,1
	if_not_equal	as_invalid_operand
	mov	al,[as_mmx_size]
	or	al,al
	if_not_zero	as_avx_mem_broadcast_check
	mov	eax,[esp]
	or	al,al
	if_not_zero	as_avx_mem_broadcast_check
	mov	al,[as_broadcast_size]
	mov	[as_mmx_size],al
	mov	ah,cl
	lods	as_u8 [esi]
	and	al,1111b
	mov	cl,al
	mov	al,[as_broadcast_size]
	shl	al,cl
	mov	[esp],al
	mov	cl,ah
	jmp	as_avx_mem_broadcast_ok
      as_avx_mem_broadcast_check:
	bit_scan_forward	eax,eax
	xchg	al,[as_broadcast_size]
	mov	[as_mmx_size],al
	bit_scan_forward	eax,eax
	if_zero	as_invalid_operand
	mov	ah,[as_broadcast_size]
	sub	ah,al
	lods	as_u8 [esi]
	and	al,1111b
	cmp	al,ah
	if_not_equal	as_invalid_operand_size
      as_avx_mem_broadcast_ok:
	or	[as_vex_required],40h
	lods	as_u8 [esi]
	cmp	al,'}'
	if_not_equal	as_invalid_operand
      as_avx_mem_ok:
	pop	eax
	or	al,al
	if_zero	as_avx_mem_size_deciding
	xchg	al,[as_operand_size]
	cmp	[as_mmx_size],0
	if_not_equal	as_avx_mem_size_enforced
	or	al,al
	if_zero	as_avx_mem_size_ok
	cmp	al,[as_operand_size]
	if_not_equal	as_operand_sizes_do_not_match
      as_avx_mem_size_ok:
	clear_carry
	ret
      as_avx_mem_size_deciding:
	mov	al,[as_operand_size]
	cmp	[as_mmx_size],0
	if_not_equal	as_avx_mem_size_enforced
	cmp	al,16
	if_equal	as_avx_mem_size_ok
	cmp	al,32
	if_equal	as_avx_mem_size_ok
	cmp	al,64
	if_equal	as_avx_mem_size_ok
	or	al,al
	if_not_zero	as_invalid_operand_size
	call	as_recoverable_unknown_size
      as_avx_mem_size_enforced:
	or	al,al
	if_zero	as_avx_mem_size_ok
	cmp	al,[as_mmx_size]
	if_equal	as_avx_mem_size_ok
	jmp	as_invalid_operand_size
      as_take_imm4_if_needed:
	cmp	[as_immediate_size],-3
	if_not_equal	as_imm4_ok
	push	ebx ecx edx
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	cmp	al,'('
	if_not_equal	as_invalid_operand
	call	as_get_byte_value
	test	al,11110000b
	if_not_zero	as_value_out_of_range
	or	as_u8 [as_value],al
	pop	edx ecx ebx
      as_imm4_ok:
	ret
      as_take_avx512_mask:
	cmp	as_u8 [esi],'{'
	if_not_equal	as_avx512_masking_ok
	test	[as_operand_flags],10h
	if_not_zero	as_invalid_operand
	inc	esi
	lods	as_u8 [esi]
	cmp	al,14h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	mov	ah,al
	shr	ah,4
	cmp	ah,5
	if_not_equal	as_invalid_operand
	and	al,111b
	or	al,al
	if_zero	as_invalid_operand
	mov	[as_mask_register],al
	or	[as_vex_required],20h
	lods	as_u8 [esi]
	cmp	al,'}'
	if_not_equal	as_invalid_operand
	cmp	as_u8 [esi],'{'
	if_not_equal	as_avx512_masking_ok
	test	[as_operand_flags],20h
	if_not_zero	as_invalid_operand
	inc	esi
	lods	as_u8 [esi]
	cmp	al,1Fh
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	or	al,al
	if_not_zero	as_invalid_operand
	or	[as_mask_register],80h
	lods	as_u8 [esi]
	cmp	al,'}'
	if_not_equal	as_invalid_operand
      as_avx512_masking_ok:
	retn
      as_take_avx512_rounding:
	test	[as_operand_flags],4+8
	if_zero	as_avx512_rounding_done
	test	[as_operand_flags],8
	if_zero	as_avx512_rounding_allowed
	cmp	[as_mmx_size],0
	if_not_equal	as_avx512_rounding_allowed
	cmp	[as_operand_size],64
	if_not_equal	as_avx512_rounding_done
      as_avx512_rounding_allowed:
	cmp	as_u8 [esi],','
	if_not_equal	as_avx512_rounding_done
	cmp	as_u8 [esi+1],'{'
	if_not_equal	as_avx512_rounding_done
	add	esi,2
	mov	[as_rounding_mode],0
	or	[as_vex_required],40h
	test	[as_operand_flags],8
	if_zero	as_take_sae
	or	[as_vex_required],80h
	lods	as_u8 [esi]
	cmp	al,1Fh
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	mov	ah,al
	shr	ah,4
	cmp	ah,2
	if_not_equal	as_invalid_operand
	and	al,11b
	mov	[as_rounding_mode],al
	lods	as_u8 [esi]
	cmp	al,'-'
	if_not_equal	as_invalid_operand
      as_take_sae:
	lods	as_u8 [esi]
	cmp	al,1Fh
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	cmp	al,30h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	cmp	al,'}'
	if_not_equal	as_invalid_operand
      as_avx512_rounding_done:
	retn

as_avx_movdqu_instruction:
	mov	ah,0F3h
	jmp	as_avx_movdq_instruction
as_avx_movdqa_instruction:
	mov	ah,66h
      as_avx_movdq_instruction:
	mov	[as_opcode_prefix],ah
	or	[as_vex_required],2
	jmp	as_avx_movps_instruction
as_avx512_movdqu16_instruction:
	or	[as_rex_prefix],8
as_avx512_movdqu8_instruction:
	mov	ah,0F2h
	jmp	as_avx_movdq_instruction_evex
as_avx512_movdqu64_instruction:
	or	[as_rex_prefix],8
as_avx512_movdqu32_instruction:
	mov	ah,0F3h
	jmp	as_avx_movdq_instruction_evex
as_avx512_movdqa64_instruction:
	or	[as_rex_prefix],8
as_avx512_movdqa32_instruction:
	mov	ah,66h
      as_avx_movdq_instruction_evex:
	mov	[as_opcode_prefix],ah
	or	[as_vex_required],8
	jmp	as_avx_movps_instruction
as_avx_movpd_instruction:
	mov	[as_opcode_prefix],66h
	or	[as_rex_prefix],80h
as_avx_movps_instruction:
	or	[as_operand_flags],2
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	or	[as_vex_required],1
	xor	al,al
	mov	[as_mmx_size],al
	mov	[as_broadcast_size],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_avx_reg
	inc	[as_extended_code]
	test	[as_extended_code],1
	if_not_zero	as_avx_mem
	add	[as_extended_code],-1+10h
      as_avx_mem:
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	or	[as_operand_flags],20h
	call	as_take_avx512_mask
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	[as_postbyte_register],al
	jmp	as_instruction_ready
as_avx_movntpd_instruction:
	or	[as_rex_prefix],80h
as_avx_movntdq_instruction:
	mov	[as_opcode_prefix],66h
as_avx_movntps_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	or	[as_vex_required],1
	or	[as_operand_flags],10h
	mov	[as_mmx_size],0
	lods	as_u8 [esi]
	call	as_get_size_operator
	jmp	as_avx_mem
as_avx_compress_q_instruction:
	or	[as_rex_prefix],8
as_avx_compress_d_instruction:
	or	[as_vex_required],8
	mov	[as_mmx_size],0
	call	as_setup_66_0f_38
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_avx_mem
	lods	as_u8 [esi]
	call	as_convert_avx_register
	mov	bl,al
	call	as_take_avx512_mask
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	[as_postbyte_register],al
	jmp	as_nomem_instruction_ready
as_avx_lddqu_instruction:
	mov	ah,0F2h
	or	[as_vex_required],2
      as_avx_load_instruction:
	mov	[as_opcode_prefix],ah
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	mov	[as_mmx_size],0
	or	[as_vex_required],1
	call	as_take_avx_register
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
as_avx_movntdqa_instruction:
	mov	[as_supplemental_code],al
	mov	al,38h
	mov	ah,66h
	jmp	as_avx_load_instruction
as_avx_movq_instruction:
	or	[as_rex_prefix],8
	mov	[as_mmx_size],8
	jmp	as_avx_mov_instruction
as_avx_movd_instruction:
	mov	[as_mmx_size],4
      as_avx_mov_instruction:
	or	[as_vex_required],1
	mov	[as_opcode_prefix],66h
	mov	[as_base_code],0Fh
	mov	[as_extended_code],7Eh
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_avx_movd_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_mmx_size]
	not	al
	and	[as_operand_size],al
	if_not_zero	as_invalid_operand_size
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_avx_register
	cmp	ah,16
	if_not_equal	as_invalid_operand_size
	mov	[as_postbyte_register],al
	cmp	[as_mmx_size],8
	if_not_equal	as_instruction_ready
	and	[as_rex_prefix],not 8
	or	[as_rex_prefix],80h
	mov	[as_extended_code],0D6h
	jmp	as_instruction_ready
      as_avx_movd_reg:
	lods	as_u8 [esi]
	cmp	al,0C0h
	if_above_equal	as_avx_movd_xmmreg
	call	as_convert_register
	cmp	ah,[as_mmx_size]
	if_not_equal	as_invalid_operand_size
	mov	[as_operand_size],0
	mov	bl,al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_avx_register
	cmp	ah,16
	if_not_equal	as_invalid_operand_size
	mov	[as_postbyte_register],al
      as_avx_movd_reg_ready:
	test	[as_rex_prefix],8
	if_zero	as_nomem_instruction_ready
	jmp	as_illegal_instruction
	jmp	as_nomem_instruction_ready
      as_avx_movd_xmmreg:
	sub	[as_extended_code],10h
	call	as_convert_avx_register
	cmp	ah,16
	if_not_equal	as_invalid_operand_size
	mov	[as_postbyte_register],al
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_avx_movd_xmmreg_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_mmx_size]
	cmp	al,8
	if_not_equal	as_avx_movd_xmmreg_mem_ready
	call	as_avx_movq_xmmreg_xmmreg_opcode
      as_avx_movd_xmmreg_mem_ready:
	not	al
	test	[as_operand_size],al
	if_not_zero	as_invalid_operand_size
	jmp	as_instruction_ready
      as_avx_movd_xmmreg_reg:
	lods	as_u8 [esi]
	cmp	al,0C0h
	if_above_equal	as_avx_movq_xmmreg_xmmreg
	call	as_convert_register
	cmp	ah,[as_mmx_size]
	if_not_equal	as_invalid_operand_size
	mov	bl,al
	jmp	as_avx_movd_reg_ready
      as_avx_movq_xmmreg_xmmreg:
	cmp	[as_mmx_size],8
	if_not_equal	as_invalid_operand
	call	as_avx_movq_xmmreg_xmmreg_opcode
	call	as_convert_avx_register
	cmp	ah,16
	if_not_equal	as_invalid_operand_size
	mov	bl,al
	jmp	as_nomem_instruction_ready
      as_avx_movq_xmmreg_xmmreg_opcode:
	and	[as_rex_prefix],not 8
	or	[as_rex_prefix],80h
	add	[as_extended_code],10h
	mov	[as_opcode_prefix],0F3h
	ret
as_avx_movddup_instruction:
	or	[as_vex_required],1
	mov	[as_opcode_prefix],0F2h
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	or	[as_rex_prefix],80h
	xor	al,al
	mov	[as_mmx_size],al
	mov	[as_broadcast_size],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_avx_register
	mov	[as_postbyte_register],al
	cmp	ah,16
	if_above	as_avx_movddup_size_ok
	mov	[as_mmx_size],8
      as_avx_movddup_size_ok:
	call	as_take_avx512_mask
	jmp	as_avx_vex_reg_ok
as_avx_movlpd_instruction:
	mov	[as_opcode_prefix],66h
	or	[as_rex_prefix],80h
as_avx_movlps_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	mov	[as_mmx_size],8
	mov	[as_broadcast_size],0
	or	[as_vex_required],1
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_avx_movlps_mem
	lods	as_u8 [esi]
	call	as_convert_avx_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	[as_vex_register],al
	cmp	[as_operand_size],16
	if_not_equal	as_invalid_operand
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_rm
	if_carry	as_invalid_operand
	jmp	as_instruction_ready
      as_avx_movlps_mem:
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
      as_avx_movlps_mem_:
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_avx_movlps_mem_size_ok
	cmp	al,[as_mmx_size]
	if_not_equal	as_invalid_operand_size
	mov	[as_operand_size],0
      as_avx_movlps_mem_size_ok:
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	cmp	ah,16
	if_not_equal	as_invalid_operand
	mov	[as_postbyte_register],al
	inc	[as_extended_code]
	jmp	as_instruction_ready
as_avx_movhlps_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	or	[as_vex_required],1
	call	as_take_avx_register
	cmp	ah,16
	if_not_equal	as_invalid_operand
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	[as_vex_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	bl,al
	jmp	as_nomem_instruction_ready
as_avx_movsd_instruction:
	mov	al,0F2h
	mov	cl,8
	or	[as_rex_prefix],80h
	jmp	as_avx_movs_instruction
as_avx_movss_instruction:
	mov	al,0F3h
	mov	cl,4
      as_avx_movs_instruction:
	mov	[as_opcode_prefix],al
	mov	[as_mmx_size],cl
	or	[as_vex_required],1
	mov	[as_base_code],0Fh
	mov	[as_extended_code],10h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_avx_movs_mem
	lods	as_u8 [esi]
	call	as_convert_avx_register
	cmp	ah,16
	if_not_equal	as_invalid_operand
	mov	[as_postbyte_register],al
	call	as_take_avx512_mask
	xor	cl,cl
	xchg	cl,[as_operand_size]
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_avx_movs_reg_mem
	mov	[as_operand_size],cl
	lods	as_u8 [esi]
	call	as_convert_avx_register
	mov	[as_vex_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	bl,al
	cmp	bl,8
	if_below	as_nomem_instruction_ready
	inc	[as_extended_code]
	xchg	bl,[as_postbyte_register]
	jmp	as_nomem_instruction_ready
      as_avx_movs_reg_mem:
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_avx_movs_reg_mem_ok
	cmp	al,[as_mmx_size]
	if_not_equal	as_invalid_operand_size
      as_avx_movs_reg_mem_ok:
	jmp	as_instruction_ready
      as_avx_movs_mem:
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	or	[as_operand_flags],20h
	call	as_take_avx512_mask
	jmp	as_avx_movlps_mem_

as_avx_comiss_instruction:
	or	[as_operand_flags],2+4+10h
	mov	cl,4
	jmp	as_avx_instruction
as_avx_comisd_instruction:
	or	[as_operand_flags],2+4+10h
	mov	[as_opcode_prefix],66h
	or	[as_rex_prefix],80h
	mov	cl,8
	jmp	as_avx_instruction
as_avx_movshdup_instruction:
	or	[as_operand_flags],2
	mov	[as_opcode_prefix],0F3h
	xor	cl,cl
	jmp	as_avx_instruction
as_avx_cvtqq2pd_instruction:
	mov	[as_opcode_prefix],0F3h
	or	[as_vex_required],8
	or	[as_operand_flags],2+4+8
	or	[as_rex_prefix],8
	mov	cx,0800h
	jmp	as_avx_instruction_with_broadcast
as_avx_pshuf_w_instruction:
	mov	[as_opcode_prefix],al
	or	[as_operand_flags],2
	mov	[as_immediate_size],1
	mov	al,70h
	xor	cl,cl
	jmp	as_avx_instruction
as_avx_single_source_128bit_instruction_38_noevex:
	or	[as_operand_flags],2
as_avx_128bit_instruction_38_noevex:
	mov	cl,16
	jmp	as_avx_instruction_38_noevex
as_avx_single_source_instruction_38_noevex:
	or	[as_operand_flags],2
	jmp	as_avx_pi_instruction_38_noevex
as_avx_pi_instruction_38_noevex:
	xor	cl,cl
      as_avx_instruction_38_noevex:
	or	[as_vex_required],2
      as_avx_instruction_38:
	mov	[as_opcode_prefix],66h
	mov	[as_supplemental_code],al
	mov	al,38h
	jmp	as_avx_instruction
as_avx_ss_instruction_3a_imm8_noevex:
	mov	cl,4
	jmp	as_avx_instruction_3a_imm8_noevex
as_avx_sd_instruction_3a_imm8_noevex:
	mov	cl,8
	jmp	as_avx_instruction_3a_imm8_noevex
as_avx_single_source_128bit_instruction_3a_imm8_noevex:
	or	[as_operand_flags],2
as_avx_128bit_instruction_3a_imm8_noevex:
	mov	cl,16
	jmp	as_avx_instruction_3a_imm8_noevex
as_avx_triple_source_instruction_3a_noevex:
	xor	cl,cl
	mov	[as_immediate_size],-1
	mov	as_u8 [as_value],0
	jmp	as_avx_instruction_3a_noevex
as_avx_single_source_instruction_3a_imm8_noevex:
	or	[as_operand_flags],2
as_avx_pi_instruction_3a_imm8_noevex:
	xor	cl,cl
      as_avx_instruction_3a_imm8_noevex:
	mov	[as_immediate_size],1
      as_avx_instruction_3a_noevex:
	or	[as_vex_required],2
      as_avx_instruction_3a:
	mov	[as_opcode_prefix],66h
	mov	[as_supplemental_code],al
	mov	al,3Ah
	jmp	as_avx_instruction
as_avx_pi_instruction_3a_imm8:
	xor	cl,cl
	mov	[as_immediate_size],1
	jmp	as_avx_instruction_3a
as_avx_pclmulqdq_instruction:
	mov	as_u8 [as_value],al
	mov	[as_immediate_size],-4
	xor	cl,cl
	mov	al,44h
	or	[as_operand_flags],10h
	jmp	as_avx_instruction_3a
as_avx_instruction_38_nomask:
	or	[as_operand_flags],10h
	xor	cl,cl
	jmp	as_avx_instruction_38

as_avx512_single_source_pd_instruction_sae_imm8:
	or	[as_operand_flags],2
as_avx512_pd_instruction_sae_imm8:
	or	[as_rex_prefix],8
	mov	cx,0800h
	jmp	as_avx512_instruction_sae_imm8
as_avx512_single_source_ps_instruction_sae_imm8:
	or	[as_operand_flags],2
as_avx512_ps_instruction_sae_imm8:
	mov	cx,0400h
	jmp	as_avx512_instruction_sae_imm8
as_avx512_sd_instruction_sae_imm8:
	or	[as_rex_prefix],8
	mov	cx,0008h
	jmp	as_avx512_instruction_sae_imm8
as_avx512_ss_instruction_sae_imm8:
	mov	cx,0004h
      as_avx512_instruction_sae_imm8:
	or	[as_operand_flags],4
      as_avx512_instruction_imm8:
	or	[as_vex_required],8
	mov	[as_opcode_prefix],66h
	mov	[as_immediate_size],1
	mov	[as_supplemental_code],al
	mov	al,3Ah
	jmp	as_avx_instruction_with_broadcast
as_avx512_pd_instruction_er:
	or	[as_operand_flags],4+8
	jmp	as_avx512_pd_instruction
as_avx512_single_source_pd_instruction_sae:
	or	[as_operand_flags],4
as_avx512_single_source_pd_instruction:
	or	[as_operand_flags],2
as_avx512_pd_instruction:
	or	[as_rex_prefix],8
	mov	cx,0800h
	jmp	as_avx512_instruction
as_avx512_ps_instruction_er:
	or	[as_operand_flags],4+8
	jmp	as_avx512_ps_instruction
as_avx512_single_source_ps_instruction_sae:
	or	[as_operand_flags],4
as_avx512_single_source_ps_instruction:
	or	[as_operand_flags],2
as_avx512_ps_instruction:
	mov	cx,0400h
	jmp	as_avx512_instruction
as_avx512_sd_instruction_er:
	or	[as_operand_flags],8
as_avx512_sd_instruction_sae:
	or	[as_operand_flags],4
as_avx512_sd_instruction:
	or	[as_rex_prefix],8
	mov	cx,0008h
	jmp	as_avx512_instruction
as_avx512_ss_instruction_er:
	or	[as_operand_flags],8
as_avx512_ss_instruction_sae:
	or	[as_operand_flags],4
as_avx512_ss_instruction:
	mov	cx,0004h
      as_avx512_instruction:
	or	[as_vex_required],8
	mov	[as_opcode_prefix],66h
	mov	[as_supplemental_code],al
	mov	al,38h
	jmp	as_avx_instruction_with_broadcast
as_avx512_exp2pd_instruction:
	or	[as_rex_prefix],8
	or	[as_operand_flags],2+4
	mov	cx,0840h
	jmp	as_avx512_instruction
as_avx512_exp2ps_instruction:
	or	[as_operand_flags],2+4
	mov	cx,0440h
	jmp	as_avx512_instruction

as_fma_instruction_pd:
	or	[as_rex_prefix],8
	mov	cx,0800h
	jmp	as_fma_instruction
as_fma_instruction_ps:
	mov	cx,0400h
	jmp	as_fma_instruction
as_fma_instruction_sd:
	or	[as_rex_prefix],8
	mov	cx,0008h
	jmp	as_fma_instruction
as_fma_instruction_ss:
	mov	cx,0004h
      as_fma_instruction:
	or	[as_operand_flags],4+8
	mov	[as_opcode_prefix],66h
	mov	[as_supplemental_code],al
	mov	al,38h
	jmp	as_avx_instruction_with_broadcast

as_fma4_instruction_p:
	xor	cl,cl
	jmp	as_fma4_instruction
as_fma4_instruction_sd:
	mov	cl,8
	jmp	as_fma4_instruction
as_fma4_instruction_ss:
	mov	cl,4
      as_fma4_instruction:
	mov	[as_immediate_size],-2
	mov	as_u8 [as_value],0
	jmp	as_avx_instruction_3a_noevex

as_avx_cmp_pd_instruction:
	mov	[as_opcode_prefix],66h
	or	[as_rex_prefix],80h
	mov	cx,0800h
	jmp	as_avx_cmp_instruction
as_avx_cmp_ps_instruction:
	mov	cx,0400h
	jmp	as_avx_cmp_instruction
as_avx_cmp_sd_instruction:
	mov	[as_opcode_prefix],0F2h
	or	[as_rex_prefix],80h
	mov	cx,0008h
	jmp	as_avx_cmp_instruction
as_avx_cmp_ss_instruction:
	mov	[as_opcode_prefix],0F3h
	mov	cx,0004h
      as_avx_cmp_instruction:
	mov	as_u8 [as_value],al
	mov	[as_immediate_size],-4
	or	[as_operand_flags],4+20h
	mov	al,0C2h
	jmp	as_avx_cmp_common
as_avx_cmpeqq_instruction:
	or	[as_rex_prefix],80h
	mov	ch,8
	mov	[as_supplemental_code],al
	mov	al,38h
	jmp	as_avx_cmp_pi_instruction
as_avx_cmpeqd_instruction:
	mov	ch,4
	jmp	as_avx_cmp_pi_instruction
as_avx_cmpeqb_instruction:
	xor	ch,ch
	jmp	as_avx_cmp_pi_instruction
as_avx512_cmp_uq_instruction:
	or	[as_rex_prefix],8
	mov	ch,8
	mov	ah,1Eh
	jmp	as_avx_cmp_pi_instruction_evex
as_avx512_cmp_ud_instruction:
	mov	ch,4
	mov	ah,1Eh
	jmp	as_avx_cmp_pi_instruction_evex
as_avx512_cmp_q_instruction:
	or	[as_rex_prefix],8
	mov	ch,8
	mov	ah,1Fh
	jmp	as_avx_cmp_pi_instruction_evex
as_avx512_cmp_d_instruction:
	mov	ch,4
	mov	ah,1Fh
	jmp	as_avx_cmp_pi_instruction_evex
as_avx512_cmp_uw_instruction:
	or	[as_rex_prefix],8
as_avx512_cmp_ub_instruction:
	xor	ch,ch
	mov	ah,3Eh
	jmp	as_avx_cmp_pi_instruction_evex
as_avx512_cmp_w_instruction:
	or	[as_rex_prefix],8
as_avx512_cmp_b_instruction:
	xor	ch,ch
	mov	ah,3Fh
      as_avx_cmp_pi_instruction_evex:
	mov	as_u8 [as_value],al
	mov	[as_immediate_size],-4
	mov	[as_supplemental_code],ah
	mov	al,3Ah
	or	[as_vex_required],8
      as_avx_cmp_pi_instruction:
	xor	cl,cl
	or	[as_operand_flags],20h
	mov	[as_opcode_prefix],66h
      as_avx_cmp_common:
	mov	[as_mmx_size],cl
	mov	[as_broadcast_size],ch
	mov	[as_extended_code],al
	mov	[as_base_code],0Fh
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,14h
	if_equal	as_avx_maskreg
	cmp	al,10h
	if_not_equal	as_invalid_operand
	or	[as_vex_required],2
	jmp	as_avx_reg
      as_avx_maskreg:
	cmp	[as_operand_size],0
	if_not_equal	as_invalid_operand_size
	or	[as_vex_required],8
	lods	as_u8 [esi]
	call	as_convert_mask_register
	mov	[as_postbyte_register],al
	call	as_take_avx512_mask
	jmp	as_avx_vex_reg
as_avx512_fpclasspd_instruction:
	or	[as_rex_prefix],8
	mov	cx,0800h
	jmp	as_avx_fpclass_instruction
as_avx512_fpclassps_instruction:
	mov	cx,0400h
	jmp	as_avx_fpclass_instruction
as_avx512_fpclasssd_instruction:
	or	[as_rex_prefix],8
	mov	cx,0008h
	jmp	as_avx_fpclass_instruction
as_avx512_fpclassss_instruction:
	mov	cx,0004h
      as_avx_fpclass_instruction:
	mov	[as_broadcast_size],ch
	mov	[as_mmx_size],cl
	or	[as_operand_flags],2
	call	as_setup_66_0f_3a
	mov	[as_immediate_size],1
	lods	as_u8 [esi]
	cmp	al,14h
	if_equal	as_avx_maskreg
	jmp	as_invalid_operand
as_avx512_ptestnmd_instruction:
	mov	ch,4
	jmp	as_avx512_ptestnm_instruction
as_avx512_ptestnmq_instruction:
	or	[as_rex_prefix],8
	mov	ch,8
	jmp	as_avx512_ptestnm_instruction
as_avx512_ptestnmw_instruction:
	or	[as_rex_prefix],8
as_avx512_ptestnmb_instruction:
	xor	ch,ch
      as_avx512_ptestnm_instruction:
	mov	ah,0F3h
	jmp	as_avx512_ptest_instruction
as_avx512_ptestmd_instruction:
	mov	ch,4
	jmp	as_avx512_ptestm_instruction
as_avx512_ptestmq_instruction:
	or	[as_rex_prefix],8
	mov	ch,8
	jmp	as_avx512_ptestm_instruction
as_avx512_ptestmw_instruction:
	or	[as_rex_prefix],8
as_avx512_ptestmb_instruction:
	xor	ch,ch
      as_avx512_ptestm_instruction:
	mov	ah,66h
      as_avx512_ptest_instruction:
	xor	cl,cl
	mov	[as_opcode_prefix],ah
	mov	[as_supplemental_code],al
	mov	al,38h
	or	[as_vex_required],8
	jmp	as_avx_cmp_common

as_mask_shift_instruction_q:
	or	[as_rex_prefix],8
as_mask_shift_instruction_d:
	or	[as_operand_flags],2
	or	[as_immediate_size],1
	mov	[as_opcode_prefix],66h
	mov	[as_supplemental_code],al
	mov	al,3Ah
	jmp	as_mask_instruction
as_mask_instruction_single_source_b:
	mov	[as_opcode_prefix],66h
	jmp	as_mask_instruction_single_source_w
as_mask_instruction_single_source_d:
	mov	[as_opcode_prefix],66h
as_mask_instruction_single_source_q:
	or	[as_rex_prefix],8
as_mask_instruction_single_source_w:
	or	[as_operand_flags],2
	jmp	as_mask_instruction
as_mask_instruction_b:
	mov	[as_opcode_prefix],66h
	jmp	as_mask_instruction_w
as_mask_instruction_d:
	mov	[as_opcode_prefix],66h
as_mask_instruction_q:
	or	[as_rex_prefix],8
as_mask_instruction_w:
	mov	[as_operand_size],32
as_mask_instruction:
	or	[as_vex_required],1
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	call	as_take_mask_register
	mov	[as_postbyte_register],al
	test	[as_operand_flags],2
	if_not_zero	as_mask_instruction_nds_ok
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_mask_register
	mov	[as_vex_register],al
      as_mask_instruction_nds_ok:
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_mask_register
	mov	bl,al
	cmp	[as_immediate_size],0
	if_not_equal	as_mmx_nomem_imm8
	jmp	as_nomem_instruction_ready
as_take_mask_register:
	lods	as_u8 [esi]
	cmp	al,14h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
as_convert_mask_register:
	mov	ah,al
	shr	ah,4
	cmp	ah,5
	if_not_equal	as_invalid_operand
	and	al,1111b
	ret
as_kmov_instruction:
	mov	[as_mmx_size],al
	or	[as_vex_required],1
	mov	[as_base_code],0Fh
	mov	[as_extended_code],90h
	lods	as_u8 [esi]
	cmp	al,14h
	if_equal	as_kmov_maskreg
	cmp	al,10h
	if_equal	as_kmov_reg
	call	as_get_size_operator
	inc	[as_extended_code]
	cmp	al,'['
	if_not_equal	as_invalid_argument
	call	as_get_address
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_mask_register
	mov	[as_postbyte_register],al
      as_kmov_with_mem:
	mov	ah,[as_mmx_size]
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_kmov_mem_size_ok
	cmp	al,ah
	if_not_equal	as_invalid_operand_size
      as_kmov_mem_size_ok:
	call	as_setup_kmov_prefix
	jmp	as_instruction_ready
      as_setup_kmov_prefix:
	cmp	ah,4
	if_below	as_kmov_w_ok
	or	[as_rex_prefix],8
      as_kmov_w_ok:
	test	ah,1 or 4
	if_zero	as_kmov_prefix_ok
	mov	[as_opcode_prefix],66h
      as_kmov_prefix_ok:
	ret
      as_kmov_maskreg:
	lods	as_u8 [esi]
	call	as_convert_mask_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	cmp	al,14h
	if_equal	as_kmov_maskreg_maskreg
	cmp	al,10h
	if_equal	as_kmov_maskreg_reg
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_argument
	call	as_get_address
	jmp	as_kmov_with_mem
      as_kmov_maskreg_maskreg:
	lods	as_u8 [esi]
	call	as_convert_mask_register
	mov	bl,al
	mov	ah,[as_mmx_size]
	call	as_setup_kmov_prefix
	jmp	as_nomem_instruction_ready
      as_kmov_maskreg_reg:
	add	[as_extended_code],2
	lods	as_u8 [esi]
	call	as_convert_register
      as_kmov_with_reg:
	mov	bl,al
	mov	al,[as_mmx_size]
	mov	ah,4
	cmp	al,ah
	if_below_equal	as_kmov_reg_size_check
	mov	ah,al
      as_kmov_reg_size_check:
	cmp	ah,[as_operand_size]
	if_not_equal	as_invalid_operand_size
	cmp	al,8
	if_equal	as_kmov_f2_w1
	cmp	al,2
	if_above	as_kmov_f2
	if_equal	as_nomem_instruction_ready
	mov	[as_opcode_prefix],66h
	jmp	as_nomem_instruction_ready
      as_kmov_f2_w1:
	or	[as_rex_prefix],8
	jmp	as_illegal_instruction
      as_kmov_f2:
	mov	[as_opcode_prefix],0F2h
	jmp	as_nomem_instruction_ready
      as_kmov_reg:
	add	[as_extended_code],3
	lods	as_u8 [esi]
	call	as_convert_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_mask_register
	jmp	as_kmov_with_reg
as_avx512_pmov_m2_instruction_w1:
	or	[as_rex_prefix],8
as_avx512_pmov_m2_instruction:
	or	[as_vex_required],8
	call	as_setup_f3_0f_38
	call	as_take_avx_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_mask_register
	mov	bl,al
	jmp	as_nomem_instruction_ready
as_avx512_pmov_2m_instruction_w1:
	or	[as_rex_prefix],8
as_avx512_pmov_2m_instruction:
	or	[as_vex_required],8
	call	as_setup_f3_0f_38
	call	as_take_mask_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	bl,al
	jmp	as_nomem_instruction_ready
      as_setup_f3_0f_38:
	mov	[as_extended_code],38h
	mov	[as_supplemental_code],al
	mov	[as_base_code],0Fh
	mov	[as_opcode_prefix],0F3h
	ret

as_vzeroall_instruction:
	mov	[as_operand_size],32
as_vzeroupper_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	and	[as_displacement_compression],0
	call	as_store_vex_instruction_code
	jmp	as_instruction_assembled
as_vstmxcsr_instruction:
	or	[as_vex_required],2
	jmp	as_stmxcsr_instruction

as_avx_perm2f128_instruction:
	or	[as_vex_required],2
	xor	ch,ch
      as_avx_instruction_imm8_without_128bit:
	mov	[as_immediate_size],1
	mov	ah,3Ah
	jmp	as_avx_instruction_without_128bit
as_avx512_shuf_q_instruction:
	or	[as_rex_prefix],8
	or	[as_vex_required],8
	mov	ch,8
	jmp	as_avx_instruction_imm8_without_128bit
as_avx512_shuf_d_instruction:
	or	[as_vex_required],8
	mov	ch,4
	jmp	as_avx_instruction_imm8_without_128bit
as_avx_permd_instruction:
	mov	ah,38h
	mov	ch,4
      as_avx_instruction_without_128bit:
	xor	cl,cl
	call	as_setup_avx_66_supplemental
	call	as_take_avx_register
	cmp	ah,32
	if_below	as_invalid_operand_size
	mov	[as_postbyte_register],al
	call	as_take_avx512_mask
	jmp	as_avx_vex_reg
      as_setup_avx_66_supplemental:
	mov	[as_opcode_prefix],66h
	mov	[as_broadcast_size],ch
	mov	[as_mmx_size],cl
	mov	[as_base_code],0Fh
	mov	[as_extended_code],ah
	mov	[as_supplemental_code],al
	or	[as_vex_required],1
	ret
as_avx_permq_instruction:
	or	[as_rex_prefix],8
	mov	ch,8
	jmp	as_avx_permil_instruction
as_avx_permilpd_instruction:
	or	[as_rex_prefix],80h
	mov	ch,8
	jmp	as_avx_permil_instruction
as_avx_permilps_instruction:
	mov	ch,4
      as_avx_permil_instruction:
	or	[as_operand_flags],2
	xor	cl,cl
	mov	ah,3Ah
	call	as_setup_avx_66_supplemental
	call	as_take_avx_register
	cmp	[as_supplemental_code],4
	if_above_equal	as_avx_permil_size_ok
	cmp	ah,32
	if_below	as_invalid_operand_size
      as_avx_permil_size_ok:
	mov	[as_postbyte_register],al
	call	as_take_avx512_mask
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_rm
	if_not_carry	as_mmx_imm8
	mov	bl,al
	cmp	as_u8 [esi],','
	if_not_equal	as_invalid_operand
	mov	al,[esi+1]
	cmp	al,11h
	if_not_equal	as_avx_permil_rm_or_imm8
	mov	al,[esi+3]
      as_avx_permil_rm_or_imm8:
	cmp	al,'('
	if_equal	as_mmx_nomem_imm8
	mov	[as_vex_register],bl
	inc	esi
	mov	[as_extended_code],38h
	mov	al,[as_supplemental_code]
	cmp	al,4
	if_below	as_avx_permq_rm
	add	[as_supplemental_code],8
	jmp	as_avx_regs_rm
      as_avx_permq_rm:
	or	[as_vex_required],8
	shl	al,5
	negate	al
	add	al,36h
	mov	[as_supplemental_code],al
	jmp	as_avx_regs_rm
as_vpermil_2pd_instruction:
	mov	[as_immediate_size],-2
	mov	as_u8 [as_value],al
	mov	al,49h
	jmp	as_vpermil2_instruction_setup
as_vpermil_2ps_instruction:
	mov	[as_immediate_size],-2
	mov	as_u8 [as_value],al
	mov	al,48h
	jmp	as_vpermil2_instruction_setup
as_vpermil2_instruction:
	mov	[as_immediate_size],-3
	mov	as_u8 [as_value],0
      as_vpermil2_instruction_setup:
	or	[as_vex_required],2
	mov	[as_base_code],0Fh
	mov	[as_supplemental_code],al
	mov	al,3Ah
	xor	cl,cl
	jmp	as_avx_instruction

as_avx_shift_q_instruction_evex:
	or	[as_vex_required],8
as_avx_shift_q_instruction:
	or	[as_rex_prefix],80h
	mov	cl,8
	jmp	as_avx_shift_instruction
as_avx_shift_d_instruction:
	mov	cl,4
	jmp	as_avx_shift_instruction
as_avx_shift_bw_instruction:
	xor	cl,cl
      as_avx_shift_instruction:
	mov	[as_broadcast_size],cl
	mov	[as_mmx_size],0
	mov	[as_opcode_prefix],66h
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	or	[as_vex_required],1
	call	as_take_avx_register
	mov	[as_postbyte_register],al
	call	as_take_avx512_mask
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	xor	cl,cl
	xchg	cl,[as_operand_size]
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_equal	as_avx_shift_reg_mem
	mov	[as_operand_size],cl
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_avx_register
	mov	[as_vex_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	push	esi
	xor	cl,cl
	xchg	cl,[as_operand_size]
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_avx_shift_reg_reg_reg
	pop	esi
	cmp	al,'['
	if_equal	as_avx_shift_reg_reg_mem
	xchg	cl,[as_operand_size]
	test	cl,not 1
	if_not_zero	as_invalid_operand_size
	dec	esi
	call	as_convert_avx_shift_opcode
	mov	bl,al
	jmp	as_mmx_nomem_imm8
      as_convert_avx_shift_opcode:
	mov	al,[as_extended_code]
	mov	ah,al
	and	ah,1111b
	add	ah,70h
	mov	[as_extended_code],ah
	shr	al,4
	sub	al,0Ch
	shl	al,1
	xchg	al,[as_postbyte_register]
	xchg	al,[as_vex_register]
	ret
      as_avx_shift_reg_reg_reg:
	pop	eax
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	xchg	cl,[as_operand_size]
	mov	bl,al
	jmp	as_nomem_instruction_ready
      as_avx_shift_reg_reg_mem:
	mov	[as_mmx_size],16
	push	ecx
	lods	as_u8 [esi]
	call	as_get_size_operator
	call	as_get_address
	pop	eax
	xchg	al,[as_operand_size]
	test	al,al
	if_zero	as_instruction_ready
	cmp	al,16
	if_not_equal	as_invalid_operand_size
	jmp	as_instruction_ready
      as_avx_shift_reg_mem:
	or	[as_vex_required],8
	call	as_take_avx_mem
	call	as_convert_avx_shift_opcode
	jmp	as_mmx_imm8
as_avx_shift_dq_instruction:
	mov	[as_postbyte_register],al
	mov	[as_opcode_prefix],66h
	mov	[as_base_code],0Fh
	mov	[as_extended_code],73h
	or	[as_vex_required],1
	mov	[as_mmx_size],0
	call	as_take_avx_register
	mov	[as_vex_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_equal	as_avx_shift_dq_reg_mem
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_avx_register
	mov	bl,al
	jmp	as_mmx_nomem_imm8
      as_avx_shift_dq_reg_mem:
	or	[as_vex_required],8
	call	as_get_address
	jmp	as_mmx_imm8
as_avx512_rotate_q_instruction:
	mov	cl,8
	or	[as_rex_prefix],cl
	jmp	as_avx512_rotate_instruction
as_avx512_rotate_d_instruction:
	mov	cl,4
      as_avx512_rotate_instruction:
	mov	[as_broadcast_size],cl
	mov	[as_postbyte_register],al
	mov	[as_opcode_prefix],66h
	mov	[as_base_code],0Fh
	mov	[as_extended_code],72h
	or	[as_vex_required],8
	mov	[as_mmx_size],0
	mov	[as_immediate_size],1
	call	as_take_avx_register
	mov	[as_vex_register],al
	call	as_take_avx512_mask
	jmp	as_avx_vex_reg_ok

as_avx_pmovsxbq_instruction:
	mov	cl,2
	jmp	as_avx_pmovsx_instruction
as_avx_pmovsxbd_instruction:
	mov	cl,4
	jmp	as_avx_pmovsx_instruction
as_avx_pmovsxbw_instruction:
	mov	cl,8
      as_avx_pmovsx_instruction:
	mov	[as_mmx_size],cl
	or	[as_vex_required],1
	call	as_setup_66_0f_38
	call	as_take_avx_register
	mov	[as_postbyte_register],al
	call	as_take_avx512_mask
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	xor	al,al
	xchg	al,[as_operand_size]
	bit_scan_forward	ecx,eax
	sub	cl,4
	shl	[as_mmx_size],cl
	push	eax
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_avx_pmovsx_reg_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	pop	eax
	xchg	al,[as_operand_size]
	or	al,al
	if_zero	as_instruction_ready
	cmp	al,[as_mmx_size]
	if_not_equal	as_invalid_operand_size
	jmp	as_instruction_ready
      as_avx_pmovsx_reg_reg:
	lods	as_u8 [esi]
	call	as_convert_avx_register
	mov	bl,al
	cmp	ah,[as_mmx_size]
	if_equal	as_avx_pmovsx_xmmreg_reg_size_ok
	if_below	as_invalid_operand_size
	cmp	ah,16
	if_not_equal	as_invalid_operand_size
      as_avx_pmovsx_xmmreg_reg_size_ok:
	pop	eax
	mov	[as_operand_size],al
	jmp	as_nomem_instruction_ready
as_avx512_pmovqb_instruction:
	mov	cl,2
	jmp	as_avx512_pmov_instruction
as_avx512_pmovdb_instruction:
	mov	cl,4
	jmp	as_avx512_pmov_instruction
as_avx512_pmovwb_instruction:
	mov	cl,8
      as_avx512_pmov_instruction:
	mov	[as_mmx_size],cl
	or	[as_vex_required],8
	mov	[as_extended_code],38h
	mov	[as_supplemental_code],al
	mov	[as_base_code],0Fh
	mov	[as_opcode_prefix],0F3h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_avx512_pmov_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	or	[as_operand_flags],20h
	call	as_avx512_pmov_common
	or	al,al
	if_zero	as_instruction_ready
	cmp	al,[as_mmx_size]
	if_not_equal	as_invalid_operand_size
	jmp	as_instruction_ready
      as_avx512_pmov_common:
	call	as_take_avx512_mask
	xor	al,al
	xchg	al,[as_operand_size]
	push	eax
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	[as_postbyte_register],al
	mov	al,ah
	mov	ah,cl
	bit_scan_forward	ecx,eax
	sub	cl,4
	shl	[as_mmx_size],cl
	mov	cl,ah
	pop	eax
	ret
      as_avx512_pmov_reg:
	lods	as_u8 [esi]
	call	as_convert_avx_register
	mov	bl,al
	call	as_avx512_pmov_common
	cmp	al,[as_mmx_size]
	if_equal	as_nomem_instruction_ready
	if_below	as_invalid_operand_size
	cmp	al,16
	if_not_equal	as_invalid_operand_size
	jmp	as_nomem_instruction_ready

as_avx_broadcast_128_instruction_noevex:
	or	[as_vex_required],2
	mov	cl,10h
	jmp	as_avx_broadcast_instruction
as_avx512_broadcast_32x2_instruction:
	mov	cl,08h
	jmp	as_avx_broadcast_instruction_evex
as_avx512_broadcast_32x4_instruction:
	mov	cl,10h
	jmp	as_avx_broadcast_instruction_evex
as_avx512_broadcast_32x8_instruction:
	mov	cl,20h
	jmp	as_avx_broadcast_instruction_evex
as_avx512_broadcast_64x2_instruction:
	mov	cl,10h
	jmp	as_avx_broadcast_instruction_w1_evex
as_avx512_broadcast_64x4_instruction:
	mov	cl,20h
      as_avx_broadcast_instruction_w1_evex:
	or	[as_rex_prefix],8
      as_avx_broadcast_instruction_evex:
	or	[as_vex_required],8
	jmp	as_avx_broadcast_instruction
as_avx_broadcastss_instruction:
	mov	cl,4
	jmp	as_avx_broadcast_instruction
as_avx_broadcastsd_instruction:
	or	[as_rex_prefix],80h
	mov	cl,8
	jmp	as_avx_broadcast_instruction
as_avx_pbroadcastb_instruction:
	mov	cl,1
	jmp	as_avx_broadcast_pi_instruction
as_avx_pbroadcastw_instruction:
	mov	cl,2
	jmp	as_avx_broadcast_pi_instruction
as_avx_pbroadcastd_instruction:
	mov	cl,4
	jmp	as_avx_broadcast_pi_instruction
as_avx_pbroadcastq_instruction:
	mov	cl,8
	or	[as_rex_prefix],80h
      as_avx_broadcast_pi_instruction:
	or	[as_operand_flags],40h
      as_avx_broadcast_instruction:
	mov	[as_opcode_prefix],66h
	mov	[as_supplemental_code],al
	mov	al,38h
	mov	[as_mmx_size],cl
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	or	[as_vex_required],1
	call	as_take_avx_register
	cmp	ah,[as_mmx_size]
	if_equal	as_invalid_operand_size
	test	[as_operand_flags],40h
	if_not_zero	as_avx_broadcast_destination_size_ok
	cmp	[as_mmx_size],4
	if_equal	as_avx_broadcast_destination_size_ok
	cmp	[as_supplemental_code],59h
	if_equal	as_avx_broadcast_destination_size_ok
	cmp	ah,16
	if_equal	as_invalid_operand_size
      as_avx_broadcast_destination_size_ok:
	xor	ah,ah
	xchg	ah,[as_operand_size]
	push	eax
	call	as_take_avx512_mask
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_avx_broadcast_reg_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	pop	eax
	xchg	ah,[as_operand_size]
	mov	[as_postbyte_register],al
	mov	al,[as_broadcast_size]
	mov	al,[as_mmx_size]
	cmp	al,ah
	if_equal	as_instruction_ready
	or	al,al
	if_zero	as_instruction_ready
	or	ah,ah
	if_zero	as_instruction_ready
	jmp	as_invalid_operand_size
      as_avx_broadcast_reg_reg:
	lods	as_u8 [esi]
	test	[as_operand_flags],40h
	if_zero	as_avx_broadcast_reg_avx_reg
	cmp	al,60h
	if_below	as_avx_broadcast_reg_general_reg
	cmp	al,80h
	if_below	as_avx_broadcast_reg_avx_reg
	cmp	al,0C0h
	if_below	as_avx_broadcast_reg_general_reg
      as_avx_broadcast_reg_avx_reg:
	call	as_convert_avx_register
	mov	bl,al
	mov	al,[as_mmx_size]
	or	al,al
	if_zero	as_avx_broadcast_reg_avx_reg_size_ok
	cmp	ah,16
	if_not_equal	as_invalid_operand_size
	cmp	al,ah
	if_above_equal	as_invalid_operand
      as_avx_broadcast_reg_avx_reg_size_ok:
	pop	eax
	xchg	ah,[as_operand_size]
	mov	[as_postbyte_register],al
	test	[as_vex_required],2
	if_not_zero	as_invalid_operand
	jmp	as_nomem_instruction_ready
      as_avx_broadcast_reg_general_reg:
	call	as_convert_register
	mov	bl,al
	mov	al,[as_mmx_size]
	or	al,al
	if_zero	as_avx_broadcast_reg_general_reg_size_ok
	cmp	al,ah
	if_equal	as_avx_broadcast_reg_general_reg_size_ok
	if_above	as_invalid_operand_size
	cmp	ah,4
	if_not_equal	as_invalid_operand_size
      as_avx_broadcast_reg_general_reg_size_ok:
	cmp	al,4
	if_below	as_avx_broadcast_reg_general_reg_ready
	cmp	al,8
	mov	al,3
	if_not_equal	as_avx_broadcast_reg_general_reg_ready
	or	[as_rex_prefix],8
      as_avx_broadcast_reg_general_reg_ready:
	add	al,7Ah-1
	mov	[as_supplemental_code],al
	or	[as_vex_required],8
	pop	eax
	xchg	ah,[as_operand_size]
	mov	[as_postbyte_register],al
	jmp	as_nomem_instruction_ready

as_avx512_extract_64x4_instruction:
	or	[as_rex_prefix],8
as_avx512_extract_32x8_instruction:
	or	[as_vex_required],8
	mov	cl,32
	jmp	as_avx_extractf_instruction
as_avx512_extract_64x2_instruction:
	or	[as_rex_prefix],8
as_avx512_extract_32x4_instruction:
	or	[as_vex_required],8
	mov	cl,16
	jmp	as_avx_extractf_instruction
as_avx_extractf128_instruction:
	or	[as_vex_required],2
	mov	cl,16
      as_avx_extractf_instruction:
	mov	[as_mmx_size],cl
	call	as_setup_66_0f_3a
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_avx_extractf_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	xor	al,al
	xchg	al,[as_operand_size]
	or	al,al
	if_zero	as_avx_extractf_mem_size_ok
	cmp	al,[as_mmx_size]
	if_not_equal	as_invalid_operand_size
      as_avx_extractf_mem_size_ok:
	call	as_take_avx512_mask
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	cmp	ah,[as_mmx_size]
	if_below_equal	as_invalid_operand_size
	mov	[as_postbyte_register],al
	jmp	as_mmx_imm8
      as_avx_extractf_reg:
	lods	as_u8 [esi]
	call	as_convert_avx_register
	cmp	ah,[as_mmx_size]
	if_not_equal	as_invalid_operand_size
	push	eax
	call	as_take_avx512_mask
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	cmp	ah,[as_mmx_size]
	if_below_equal	as_invalid_operand_size
	mov	[as_postbyte_register],al
	pop	ebx
	jmp	as_mmx_nomem_imm8
as_avx512_insert_64x4_instruction:
	or	[as_rex_prefix],8
as_avx512_insert_32x8_instruction:
	or	[as_vex_required],8
	mov	cl,32
	jmp	as_avx_insertf_instruction
as_avx512_insert_64x2_instruction:
	or	[as_rex_prefix],8
as_avx512_insert_32x4_instruction:
	or	[as_vex_required],8
	mov	cl,16
	jmp	as_avx_insertf_instruction
as_avx_insertf128_instruction:
	or	[as_vex_required],2
	mov	cl,16
      as_avx_insertf_instruction:
	mov	[as_mmx_size],cl
	mov	[as_broadcast_size],0
	call	as_setup_66_0f_3a
	call	as_take_avx_register
	cmp	ah,[as_mmx_size]
	if_below_equal	as_invalid_operand
	mov	[as_postbyte_register],al
	call	as_take_avx512_mask
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	[as_vex_register],al
	mov	al,[as_mmx_size]
	xchg	al,[as_operand_size]
	push	eax
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_avx_insertf_reg_reg_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	pop	eax
	mov	[as_operand_size],al
	jmp	as_mmx_imm8
      as_avx_insertf_reg_reg_reg:
	lods	as_u8 [esi]
	call	as_convert_avx_register
	mov	bl,al
	pop	eax
	mov	[as_operand_size],al
	jmp	as_mmx_nomem_imm8
as_avx_extract_b_instruction:
	mov	cl,1
	jmp	as_avx_extract_instruction
as_avx_extract_w_instruction:
	mov	cl,2
	jmp	as_avx_extract_instruction
as_avx_extract_q_instruction:
	or	[as_rex_prefix],8
	mov	cl,8
	jmp	as_avx_extract_instruction
as_avx_extract_d_instruction:
	mov	cl,4
      as_avx_extract_instruction:
	mov	[as_mmx_size],cl
	call	as_setup_66_0f_3a
	or	[as_vex_required],1
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_avx_extractps_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	mov	al,[as_mmx_size]
	not	al
	and	[as_operand_size],al
	if_not_zero	as_invalid_operand_size
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_avx_register
	cmp	ah,16
	if_not_equal	as_invalid_operand_size
	mov	[as_postbyte_register],al
	jmp	as_mmx_imm8
      as_avx_extractps_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	mov	al,[as_mmx_size]
	cmp	ah,al
	if_below	as_invalid_operand_size
	cmp	ah,4
	if_equal	as_avx_extractps_reg_size_ok
	cmp	ah,8
	if_not_equal	as_invalid_operand_size
	jmp	as_invalid_operand
	cmp	al,4
	if_above_equal	as_avx_extractps_reg_size_ok
	or	[as_rex_prefix],8
      as_avx_extractps_reg_size_ok:
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_avx_register
	cmp	ah,16
	if_not_equal	as_invalid_operand_size
	mov	[as_postbyte_register],al
	cmp	[as_supplemental_code],15h
	if_not_equal	as_mmx_nomem_imm8
	mov	[as_extended_code],0C5h
	xchg	bl,[as_postbyte_register]
	jmp	as_mmx_nomem_imm8
as_avx_insertps_instruction:
	mov	[as_immediate_size],1
	or	[as_operand_flags],10h
	mov	[as_opcode_prefix],66h
	mov	[as_supplemental_code],al
	mov	al,3Ah
	mov	cl,4
	jmp	as_avx_instruction
as_avx_pinsrb_instruction:
	mov	cl,1
	jmp	as_avx_pinsr_instruction_3a
as_avx_pinsrw_instruction:
	mov	cl,2
	jmp	as_avx_pinsr_instruction
as_avx_pinsrd_instruction:
	mov	cl,4
	jmp	as_avx_pinsr_instruction_3a
as_avx_pinsrq_instruction:
	jmp	as_illegal_instruction
	mov	cl,8
	or	[as_rex_prefix],8
      as_avx_pinsr_instruction_3a:
	mov	[as_supplemental_code],al
	mov	al,3Ah
      as_avx_pinsr_instruction:
	mov	[as_opcode_prefix],66h
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	mov	[as_mmx_size],cl
	or	[as_vex_required],1
	call	as_take_avx_register
	cmp	ah,16
	if_not_equal	as_invalid_operand_size
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	[as_vex_register],al
	jmp	as_pinsr_xmmreg

as_avx_cvtudq2pd_instruction:
	or	[as_vex_required],8
as_avx_cvtdq2pd_instruction:
	mov	[as_opcode_prefix],0F3h
	mov	cl,4
	jmp	as_avx_cvt_d_instruction
as_avx_cvtps2qq_instruction:
	or	[as_operand_flags],8
as_avx_cvttps2qq_instruction:
	or	[as_operand_flags],4
	or	[as_vex_required],8
	mov	[as_opcode_prefix],66h
	mov	cl,4
	jmp	as_avx_cvt_d_instruction
as_avx_cvtps2pd_instruction:
	or	[as_operand_flags],4
	mov	cl,4
      as_avx_cvt_d_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	or	[as_vex_required],1
	mov	[as_broadcast_size],cl
	call	as_take_avx_register
	mov	[as_postbyte_register],al
	call	as_take_avx512_mask
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	xor	ecx,ecx
	xchg	cl,[as_operand_size]
	mov	al,cl
	shr	al,1
	mov	[as_mmx_size],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_equal	as_avx_cvt_d_reg_mem
	cmp	al,10h
	if_not_equal	as_invalid_operand
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	call	as_convert_avx_register
	cmp	ah,[as_mmx_size]
	if_equal	as_avx_cvt_d_reg_reg_size_ok
	if_below	as_invalid_operand_size
	cmp	ah,16
	if_not_equal	as_invalid_operand_size
      as_avx_cvt_d_reg_reg_size_ok:
	mov	bl,al
	mov	[as_operand_size],cl
	call	as_take_avx512_rounding
	jmp	as_nomem_instruction_ready
      as_avx_cvt_d_reg_mem:
	call	as_take_avx_mem
	jmp	as_instruction_ready
as_avx_cvtpd2dq_instruction:
	or	[as_operand_flags],4+8
	mov	[as_opcode_prefix],0F2h
	jmp	as_avx_cvt_q_instruction
as_avx_cvtuqq2ps_instruction:
	mov	[as_opcode_prefix],0F2h
as_avx_cvtpd2udq_instruction:
	or	[as_operand_flags],8
as_avx_cvttpd2udq_instruction:
	or	[as_operand_flags],4
	or	[as_vex_required],8
	jmp	as_avx_cvt_q_instruction
as_avx_cvtpd2ps_instruction:
	or	[as_operand_flags],8
as_avx_cvttpd2dq_instruction:
	or	[as_operand_flags],4
	mov	[as_opcode_prefix],66h
      as_avx_cvt_q_instruction:
	mov	[as_broadcast_size],8
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	or	[as_vex_required],1
	or	[as_rex_prefix],80h
	call	as_take_avx_register
	mov	[as_postbyte_register],al
	push	eax
	call	as_take_avx512_mask
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	xor	al,al
	mov	[as_operand_size],al
	mov	[as_mmx_size],al
	call	as_take_avx_rm
	if_not_carry	as_avx_cvt_q_reg_mem
	mov	bl,al
	pop	eax
	call	as_avx_cvt_q_check_size
	call	as_take_avx512_rounding
	jmp	as_nomem_instruction_ready
      as_avx_cvt_q_reg_mem:
	pop	eax
	call	as_avx_cvt_q_check_size
	jmp	as_instruction_ready
      as_avx_cvt_q_check_size:
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_avx_cvt_q_size_not_specified
	cmp	al,64
	if_above	as_invalid_operand_size
	shr	al,1
	cmp	al,ah
	if_equal	as_avx_cvt_q_size_ok
	if_above	as_invalid_operand_size
	cmp	ah,16
	if_not_equal	as_invalid_operand_size
      as_avx_cvt_q_size_ok:
	ret
      as_avx_cvt_q_size_not_specified:
	cmp	ah,64 shr 1
	if_not_equal	as_recoverable_unknown_size
	mov	[as_operand_size],64
	ret
as_avx_cvttps2udq_instruction:
	or	[as_vex_required],8
	or	[as_operand_flags],2+4
	mov	cx,0400h
	jmp	as_avx_instruction_with_broadcast
as_avx_cvttps2dq_instruction:
	mov	[as_opcode_prefix],0F3h
	or	[as_operand_flags],2+4
	mov	cx,0400h
	jmp	as_avx_instruction_with_broadcast
as_avx_cvtph2ps_instruction:
	mov	[as_opcode_prefix],66h
	mov	[as_supplemental_code],al
	or	[as_operand_flags],4
	mov	al,38h
	xor	cl,cl
	jmp	as_avx_cvt_d_instruction
as_avx_cvtps2ph_instruction:
	call	as_setup_66_0f_3a
	or	[as_vex_required],1
	or	[as_operand_flags],4
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_vcvtps2ph_reg
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	call	as_take_avx512_mask
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	shl	[as_operand_size],1
	call	as_take_avx_register
	mov	[as_postbyte_register],al
	shr	ah,1
	mov	[as_mmx_size],ah
	jmp	as_mmx_imm8
      as_vcvtps2ph_reg:
	lods	as_u8 [esi]
	call	as_convert_avx_register
	mov	bl,al
	call	as_take_avx512_mask
	xor	cl,cl
	xchg	cl,[as_operand_size]
	shl	cl,1
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	[as_postbyte_register],al
	or	cl,cl
	if_zero	as_vcvtps2ph_reg_size_ok
	cmp	cl,ah
	if_equal	as_vcvtps2ph_reg_size_ok
	if_below	as_invalid_operand_size
	cmp	ah,16
	if_not_equal	as_invalid_operand_size
      as_vcvtps2ph_reg_size_ok:
	call	as_take_avx512_rounding
	jmp	as_mmx_nomem_imm8

as_avx_cvtsd2usi_instruction:
	or	[as_operand_flags],8
as_avx_cvttsd2usi_instruction:
	or	[as_vex_required],8
	jmp	as_avx_cvttsd2si_instruction
as_avx_cvtsd2si_instruction:
	or	[as_operand_flags],8
as_avx_cvttsd2si_instruction:
	mov	ah,0F2h
	mov	cl,8
	jmp	as_avx_cvt_2si_instruction
as_avx_cvtss2usi_instruction:
	or	[as_operand_flags],8
as_avx_cvttss2usi_instruction:
	or	[as_vex_required],8
	jmp	as_avx_cvttss2si_instruction
as_avx_cvtss2si_instruction:
	or	[as_operand_flags],8
as_avx_cvttss2si_instruction:
	mov	ah,0F3h
	mov	cl,4
      as_avx_cvt_2si_instruction:
	or	[as_operand_flags],2+4
	mov	[as_mmx_size],cl
	mov	[as_broadcast_size],0
	mov	[as_opcode_prefix],ah
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	or	[as_vex_required],1
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_register
	mov	[as_postbyte_register],al
	mov	[as_operand_size],0
	cmp	ah,4
	if_equal	as_avx_cvt_2si_reg
	cmp	ah,8
	if_not_equal	as_invalid_operand_size
	call	as_operand_64bit
      as_avx_cvt_2si_reg:
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_rm
	if_not_carry	as_instruction_ready
	mov	bl,al
	call	as_take_avx512_rounding
	jmp	as_nomem_instruction_ready
as_avx_cvtusi2sd_instruction:
	or	[as_vex_required],8
as_avx_cvtsi2sd_instruction:
	mov	ah,0F2h
	mov	cl,8
	jmp	as_avx_cvtsi_instruction
as_avx_cvtusi2ss_instruction:
	or	[as_vex_required],8
as_avx_cvtsi2ss_instruction:
	mov	ah,0F3h
	mov	cl,4
      as_avx_cvtsi_instruction:
	or	[as_operand_flags],2+4+8
	mov	[as_mmx_size],cl
	mov	[as_opcode_prefix],ah
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	or	[as_vex_required],1
	call	as_take_avx_register
	cmp	ah,16
	if_not_equal	as_invalid_operand_size
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	[as_vex_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_equal	as_avx_cvtsi_reg_reg_mem
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	cmp	ah,4
	if_equal	as_avx_cvtsi_reg_reg_reg32
	cmp	ah,8
	if_not_equal	as_invalid_operand_size
	call	as_operand_64bit
      as_avx_cvtsi_rounding:
	call	as_take_avx512_rounding
	jmp	as_nomem_instruction_ready
      as_avx_cvtsi_reg_reg_reg32:
	cmp	[as_mmx_size],8
	if_not_equal	as_avx_cvtsi_rounding
	jmp	as_nomem_instruction_ready
      as_avx_cvtsi_reg_reg_mem:
	call	as_get_address
	mov	al,[as_operand_size]
	mov	[as_mmx_size],al
	or	al,al
	if_zero	as_single_mem_nosize
	cmp	al,4
	if_equal	as_instruction_ready
	cmp	al,8
	if_not_equal	as_invalid_operand_size
	call	as_operand_64bit
	jmp	as_instruction_ready

as_avx_maskmov_w1_instruction:
	or	[as_rex_prefix],8
as_avx_maskmov_instruction:
	call	as_setup_66_0f_38
	mov	[as_mmx_size],0
	or	[as_vex_required],2
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_avx_maskmov_mem
	lods	as_u8 [esi]
	call	as_convert_avx_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	[as_vex_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	jmp	as_instruction_ready
      as_avx_maskmov_mem:
	cmp	al,'['
	if_not_equal	as_invalid_operand
	call	as_get_address
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	[as_vex_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	[as_postbyte_register],al
	add	[as_supplemental_code],2
	jmp	as_instruction_ready
as_avx_movmskpd_instruction:
	mov	[as_opcode_prefix],66h
as_avx_movmskps_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],50h
	or	[as_vex_required],2
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_register
	mov	[as_postbyte_register],al
	cmp	ah,4
	if_equal	as_avx_movmskps_reg_ok
	cmp	ah,8
	if_not_equal	as_invalid_operand_size
	jmp	as_invalid_operand
      as_avx_movmskps_reg_ok:
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	bl,al
	jmp	as_nomem_instruction_ready
as_avx_maskmovdqu_instruction:
	or	[as_vex_required],2
	jmp	as_maskmovdqu_instruction
as_avx_pmovmskb_instruction:
	or	[as_vex_required],2
	mov	[as_opcode_prefix],66h
	mov	[as_base_code],0Fh
	mov	[as_extended_code],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_register
	cmp	ah,4
	if_equal	as_avx_pmovmskb_reg_size_ok
	jmp	as_invalid_operand_size
	cmp	ah,8
	if_not_zero	as_invalid_operand_size
      as_avx_pmovmskb_reg_size_ok:
	mov	[as_postbyte_register],al
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	bl,al
	jmp	as_nomem_instruction_ready

as_gather_pd_instruction:
	or	[as_rex_prefix],8
as_gather_ps_instruction:
	call	as_setup_66_0f_38
	or	[as_vex_required],4
	or	[as_operand_flags],20h
	call	as_take_avx_register
	mov	[as_postbyte_register],al
	call	as_take_avx512_mask
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	xor	cl,cl
	xchg	cl,[as_operand_size]
	push	ecx
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_argument
	call	as_get_address
	pop	eax
	xchg	al,[as_operand_size]
      as_gather_mem_size_check:
	mov	ah,4
	test	[as_rex_prefix],8
	if_zero	as_gather_elements_size_ok
	add	ah,ah
      as_gather_elements_size_ok:
	mov	[as_mmx_size],ah
	test	al,al
	if_zero	as_gather_mem_size_ok
	cmp	al,ah
	if_not_equal	as_invalid_operand_size
      as_gather_mem_size_ok:
	cmp	as_u8 [esi],','
	if_equal	as_gather_reg_mem_reg
	test	[as_vex_required],20h
	if_zero	as_invalid_operand
	mov	ah,[as_operand_size]
	mov	al,80h
	jmp	as_gather_arguments_ok
      as_gather_reg_mem_reg:
	or	[as_vex_required],2
	inc	esi
	call	as_take_avx_register
      as_gather_arguments_ok:
	mov	[as_vex_register],al
	cmp	al,[as_postbyte_register]
	if_equal	as_disallowed_combination_of_registers
	mov	al,bl
	and	al,11111b
	cmp	al,[as_postbyte_register]
	if_equal	as_disallowed_combination_of_registers
	cmp	al,[as_vex_register]
	if_equal	as_disallowed_combination_of_registers
	mov	al,bl
	shr	al,5
	cmp	al,0Ch shr 1
	if_equal	as_gather_vr128
	mov	ah,32
	cmp	al,6 shr 1
	if_not_equal	as_gather_regular
	add	ah,ah
      as_gather_regular:
	mov	al,[as_rex_prefix]
	shr	al,3
	xor	al,[as_supplemental_code]
	test	al,1
	if_zero	as_gather_uniform
	test	[as_supplemental_code],1
	if_zero	as_gather_double
	mov	al,ah
	xchg	al,[as_operand_size]
	add	al,al
	cmp	al,ah
	if_not_equal	as_invalid_operand_size
	jmp	as_instruction_ready
      as_gather_double:
	add	ah,ah
      as_gather_uniform:
	cmp	ah,[as_operand_size]
	if_not_equal	as_invalid_operand_size
	jmp	as_instruction_ready
      as_gather_vr128:
	cmp	ah,16
	if_equal	as_instruction_ready
	cmp	ah,32
	if_not_equal	as_invalid_operand_size
	test	[as_supplemental_code],1
	if_not_zero	as_invalid_operand_size
	test	[as_rex_prefix],8
	if_zero	as_invalid_operand_size
	jmp	as_instruction_ready
as_scatter_pd_instruction:
	or	[as_rex_prefix],8
as_scatter_ps_instruction:
	call	as_setup_66_0f_38
	or	[as_vex_required],4+8
	or	[as_operand_flags],20h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_argument
	call	as_get_address
	call	as_take_avx512_mask
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	xor	al,al
	xchg	al,[as_operand_size]
	push	eax
	call	as_take_avx_register
	mov	[as_postbyte_register],al
	pop	eax
	jmp	as_gather_mem_size_check
as_gatherpf_qpd_instruction:
	mov	ah,0C7h
	jmp	as_gatherpf_pd_instruction
as_gatherpf_dpd_instruction:
	mov	ah,0C6h
      as_gatherpf_pd_instruction:
	or	[as_rex_prefix],8
	mov	cl,8
	jmp	as_gatherpf_instruction
as_gatherpf_qps_instruction:
	mov	ah,0C7h
	jmp	as_gatherpf_ps_instruction
as_gatherpf_dps_instruction:
	mov	ah,0C6h
      as_gatherpf_ps_instruction:
	mov	cl,4
      as_gatherpf_instruction:
	mov	[as_mmx_size],cl
	mov	[as_postbyte_register],al
	mov	al,ah
	call	as_setup_66_0f_38
	or	[as_vex_required],4+8
	or	[as_operand_flags],20h
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_not_equal	as_invalid_argument
	call	as_get_address
	call	as_take_avx512_mask
	mov	ah,[as_mmx_size]
	mov	al,[as_operand_size]
	or	al,al
	if_zero	as_gatherpf_mem_size_ok
	cmp	al,ah
	if_not_equal	as_invalid_operand_size
      as_gatherpf_mem_size_ok:
	mov	[as_operand_size],64
	mov	al,6 shr 1
	cmp	ah,4
	if_equal	as_gatherpf_check_vsib
	cmp	[as_supplemental_code],0C6h
	if_not_equal	as_gatherpf_check_vsib
	mov	al,0Eh shr 1
      as_gatherpf_check_vsib:
	mov	ah,bl
	shr	ah,5
	cmp	al,ah
	if_not_equal	as_invalid_operand
	jmp	as_instruction_ready

as_bmi_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],38h
	mov	[as_supplemental_code],0F3h
	mov	[as_postbyte_register],al
      as_bmi_reg:
	or	[as_vex_required],2
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_register
	mov	[as_vex_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_bmi_reg_reg
	cmp	al,'['
	if_not_equal	as_invalid_argument
	call	as_get_address
	call	as_operand_32or64
	jmp	as_instruction_ready
      as_bmi_reg_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	call	as_operand_32or64
	jmp	as_nomem_instruction_ready
      as_operand_32or64:
	mov	al,[as_operand_size]
	cmp	al,4
	if_equal	as_operand_32or64_ok
	cmp	al,8
	if_not_equal	as_invalid_operand_size
	jmp	as_invalid_operand
	or	[as_rex_prefix],8
      as_operand_32or64_ok:
	ret
as_pdep_instruction:
	mov	[as_opcode_prefix],0F2h
	jmp	as_andn_instruction
as_pext_instruction:
	mov	[as_opcode_prefix],0F3h
as_andn_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],38h
	mov	[as_supplemental_code],al
	or	[as_vex_required],2
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	jmp	as_bmi_reg
as_sarx_instruction:
	mov	[as_opcode_prefix],0F3h
	jmp	as_bzhi_instruction
as_shrx_instruction:
	mov	[as_opcode_prefix],0F2h
	jmp	as_bzhi_instruction
as_shlx_instruction:
	mov	[as_opcode_prefix],66h
as_bzhi_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],38h
	mov	[as_supplemental_code],al
	or	[as_vex_required],2
	call	as_get_reg_mem
	if_carry	as_bzhi_reg_reg
	call	as_get_vex_source_register
	if_carry	as_invalid_operand
	call	as_operand_32or64
	jmp	as_instruction_ready
      as_bzhi_reg_reg:
	call	as_get_vex_source_register
	if_carry	as_invalid_operand
	call	as_operand_32or64
	jmp	as_nomem_instruction_ready
      as_get_vex_source_register:
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_no_vex_source_register
	lods	as_u8 [esi]
	call	as_convert_register
	mov	[as_vex_register],al
	clear_carry
	ret
      as_no_vex_source_register:
	set_carry
	ret
as_bextr_instruction:
	mov	[as_base_code],0Fh
	mov	[as_extended_code],38h
	mov	[as_supplemental_code],al
	or	[as_vex_required],2
	call	as_get_reg_mem
	if_carry	as_bextr_reg_reg
	call	as_get_vex_source_register
	if_carry	as_bextr_reg_mem_imm32
	call	as_operand_32or64
	jmp	as_instruction_ready
      as_bextr_reg_reg:
	call	as_get_vex_source_register
	if_carry	as_bextr_reg_reg_imm32
	call	as_operand_32or64
	jmp	as_nomem_instruction_ready
      as_setup_bextr_imm_opcode:
	mov	[as_xop_opcode_map],0Ah
	mov	[as_base_code],10h
	call	as_operand_32or64
	ret
      as_bextr_reg_mem_imm32:
	call	as_get_imm32
	call	as_setup_bextr_imm_opcode
	jmp	as_store_instruction_with_imm32
      as_bextr_reg_reg_imm32:
	call	as_get_imm32
	call	as_setup_bextr_imm_opcode
      as_store_nomem_instruction_with_imm32:
	call	as_store_nomem_instruction
	mov	eax,as_u32 [as_value]
	call	as_mark_relocation
	stos	as_u32 [edi]
	jmp	as_instruction_assembled
      as_get_imm32:
	cmp	al,'('
	if_not_equal	as_invalid_operand
	push	edx ebx ecx
	call	as_get_dword_value
	mov	as_u32 [as_value],eax
	pop	ecx ebx edx
	ret
as_rorx_instruction:
	mov	[as_opcode_prefix],0F2h
	mov	[as_base_code],0Fh
	mov	[as_extended_code],3Ah
	mov	[as_supplemental_code],al
	or	[as_vex_required],2
	call	as_get_reg_mem
	if_carry	as_rorx_reg_reg
	call	as_operand_32or64
	jmp	as_mmx_imm8
      as_rorx_reg_reg:
	call	as_operand_32or64
	jmp	as_mmx_nomem_imm8

as_tbm_instruction:
	mov	[as_xop_opcode_map],9
	mov	ah,al
	shr	ah,4
	and	al,111b
	mov	[as_base_code],ah
	mov	[as_postbyte_register],al
	jmp	as_bmi_reg

as_llwpcb_instruction:
	or	[as_vex_required],2
	mov	[as_xop_opcode_map],9
	mov	[as_base_code],12h
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_register
	mov	bl,al
	call	as_operand_32or64
	jmp	as_nomem_instruction_ready
as_lwpins_instruction:
	or	[as_vex_required],2
	mov	[as_xop_opcode_map],0Ah
	mov	[as_base_code],12h
	mov	[as_vex_register],al
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	xor	cl,cl
	xchg	cl,[as_operand_size]
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_equal	as_lwpins_reg_reg
	cmp	al,'['
	if_not_equal	as_invalid_argument
	push	ecx
	call	as_get_address
	pop	eax
	xchg	al,[as_operand_size]
	test	al,al
	if_zero	as_lwpins_reg_mem_size_ok
	cmp	al,4
	if_not_equal	as_invalid_operand_size
      as_lwpins_reg_mem_size_ok:
	call	as_prepare_lwpins
	jmp	as_store_instruction_with_imm32
      as_lwpins_reg_reg:
	lods	as_u8 [esi]
	call	as_convert_register
	cmp	ah,4
	if_not_equal	as_invalid_operand_size
	mov	[as_operand_size],cl
	mov	bl,al
	call	as_prepare_lwpins
	jmp	as_store_nomem_instruction_with_imm32
      as_prepare_lwpins:
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_imm32
	call	as_operand_32or64
	mov	al,[as_vex_register]
	xchg	al,[as_postbyte_register]
	mov	[as_vex_register],al
	ret

as_xop_single_source_sd_instruction:
	or	[as_operand_flags],2
	mov	[as_mmx_size],8
	jmp	as_xop_instruction_9
as_xop_single_source_ss_instruction:
	or	[as_operand_flags],2
	mov	[as_mmx_size],4
	jmp	as_xop_instruction_9
as_xop_single_source_instruction:
	or	[as_operand_flags],2
	mov	[as_mmx_size],0
      as_xop_instruction_9:
	mov	[as_base_code],al
	mov	[as_xop_opcode_map],9
	jmp	as_avx_xop_common
as_xop_single_source_128bit_instruction:
	or	[as_operand_flags],2
	mov	[as_mmx_size],16
	jmp	as_xop_instruction_9
as_xop_triple_source_128bit_instruction:
	mov	[as_immediate_size],-1
	mov	as_u8 [as_value],0
	mov	[as_mmx_size],16
	jmp	as_xop_instruction_8
as_xop_128bit_instruction:
	mov	[as_immediate_size],-2
	mov	as_u8 [as_value],0
	mov	[as_mmx_size],16
      as_xop_instruction_8:
	mov	[as_base_code],al
	mov	[as_xop_opcode_map],8
	jmp	as_avx_xop_common
as_xop_pcom_b_instruction:
	mov	ah,0CCh
	jmp	as_xop_pcom_instruction
as_xop_pcom_d_instruction:
	mov	ah,0CEh
	jmp	as_xop_pcom_instruction
as_xop_pcom_q_instruction:
	mov	ah,0CFh
	jmp	as_xop_pcom_instruction
as_xop_pcom_w_instruction:
	mov	ah,0CDh
	jmp	as_xop_pcom_instruction
as_xop_pcom_ub_instruction:
	mov	ah,0ECh
	jmp	as_xop_pcom_instruction
as_xop_pcom_ud_instruction:
	mov	ah,0EEh
	jmp	as_xop_pcom_instruction
as_xop_pcom_uq_instruction:
	mov	ah,0EFh
	jmp	as_xop_pcom_instruction
as_xop_pcom_uw_instruction:
	mov	ah,0EDh
      as_xop_pcom_instruction:
	mov	as_u8 [as_value],al
	mov	[as_immediate_size],-4
	mov	[as_mmx_size],16
	mov	[as_base_code],ah
	mov	[as_xop_opcode_map],8
	jmp	as_avx_xop_common
as_vpcmov_instruction:
	or	[as_vex_required],2
	mov	[as_immediate_size],-2
	mov	as_u8 [as_value],0
	mov	[as_mmx_size],0
	mov	[as_base_code],al
	mov	[as_xop_opcode_map],8
	jmp	as_avx_xop_common
as_xop_shift_instruction:
	mov	[as_base_code],al
	or	[as_vex_required],2
	mov	[as_xop_opcode_map],9
	call	as_take_avx_register
	cmp	ah,16
	if_not_equal	as_invalid_operand
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,'['
	if_equal	as_xop_shift_reg_mem
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	call	as_convert_xmm_register
	mov	[as_vex_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	push	esi
	xor	cl,cl
	xchg	cl,[as_operand_size]
	lods	as_u8 [esi]
	call	as_get_size_operator
	pop	esi
	xchg	cl,[as_operand_size]
	cmp	al,'['
	if_equal	as_xop_shift_reg_reg_mem
	cmp	al,10h
	if_not_equal	as_xop_shift_reg_reg_imm
	call	as_take_avx_register
	mov	bl,al
	xchg	bl,[as_vex_register]
	jmp	as_nomem_instruction_ready
      as_xop_shift_reg_reg_mem:
	or	[as_rex_prefix],8
	lods	as_u8 [esi]
	call	as_get_size_operator
	call	as_get_address
	jmp	as_instruction_ready
      as_xop_shift_reg_reg_imm:
	xor	bl,bl
	xchg	bl,[as_vex_register]
	cmp	[as_base_code],94h
	if_above_equal	as_invalid_operand
	add	[as_base_code],30h
	mov	[as_xop_opcode_map],8
	dec	esi
	jmp	as_mmx_nomem_imm8
      as_xop_shift_reg_mem:
	call	as_get_address
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	push	esi
	xor	cl,cl
	xchg	cl,[as_operand_size]
	lods	as_u8 [esi]
	call	as_get_size_operator
	pop	esi
	xchg	cl,[as_operand_size]
	cmp	al,10h
	if_not_equal	as_xop_shift_reg_mem_imm
	call	as_take_avx_register
	mov	[as_vex_register],al
	jmp	as_instruction_ready
      as_xop_shift_reg_mem_imm:
	cmp	[as_base_code],94h
	if_above_equal	as_invalid_operand
	add	[as_base_code],30h
	mov	[as_xop_opcode_map],8
	dec	esi
	jmp	as_mmx_imm8

as_avx512_4vnniw_instruction:
	mov	[as_opcode_prefix],0F2h
	mov	[as_base_code],0Fh
	mov	[as_extended_code],38h
	mov	[as_supplemental_code],al
	mov	[as_mmx_size],16
	mov	[as_broadcast_size],0
	or	[as_vex_required],8
	call	as_take_avx_register
	mov	[as_postbyte_register],al
	call	as_take_avx512_mask
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_register
	mov	[as_vex_register],al
	cmp	as_u8 [esi],'+'
	if_not_equal	as_reg4_ok
	inc	esi
	cmp	as_u32 [esi],29030128h
	if_not_equal	as_invalid_operand
	lods	as_u32 [esi]
      as_reg4_ok:
	cmp	[as_operand_size],64
	if_not_equal	as_invalid_operand_size
	mov	[as_operand_size],0
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_avx_rm
	if_carry	as_invalid_operand
	mov	[as_operand_size],64
	jmp	as_instruction_ready

as_take_tile_register:
	lods	as_u8 [esi]
	cmp	al,14h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
	mov	ah,al
	shr	ah,4
	cmp	ah,7
	if_not_equal	as_invalid_operand
	and	al,1111b
	ret
as_take_tile_address:
	or	[as_operand_flags],80h
	mov	[as_address_size],0
	jmp	as_get_sib_address_components
as_amx_int8_instruction:
	mov	ah,5Eh
	jmp	as_amx_instruction
as_amx_bf16_instruction:
	mov	ah,5Ch
as_amx_instruction:
	mov	[as_opcode_prefix],al
	or	[as_vex_required],2
	mov	[as_base_code],0Fh
	mov	[as_extended_code],38h
	mov	[as_supplemental_code],ah
	call	as_take_tile_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_tile_register
	mov	bl,al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_tile_register
	mov	[as_vex_register],al
	jmp	as_nomem_instruction_ready
as_tilezero_instruction:
	call	as_take_tile_register
	mov	[as_postbyte_register],al
	mov	[as_opcode_prefix],0F2h
	jmp	as_tile_instruction
as_tilerelease_instruction:
	mov	[as_postbyte_register],0
      as_tile_instruction:
	or	[as_vex_required],2
	mov	[as_base_code],0Fh
	mov	[as_extended_code],38h
	mov	[as_supplemental_code],49h
	xor	bl,bl
	mov	[as_vex_register],0
	jmp	as_nomem_instruction_ready
as_ldtilecfg_instruction:
	mov	[as_opcode_prefix],al
	or	[as_vex_required],2
	mov	[as_supplemental_code],49h
	mov	ah,38h
	xor	al,al
	mov	cl,64
	jmp	as_xsave_common
as_tileloadd_instruction:
	call	as_tileloadd_setup
	call	as_take_tile_register
	mov	[as_postbyte_register],al
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_tile_address
	jmp	as_instruction_ready
      as_tileloadd_setup:
	mov	[as_opcode_prefix],al
	or	[as_vex_required],2
	mov	[as_base_code],0Fh
	mov	[as_extended_code],38h
	mov	[as_supplemental_code],4Bh
	ret
as_tilestored_instruction:
	call	as_tileloadd_setup
	call	as_take_tile_address
	lods	as_u8 [esi]
	cmp	al,','
	if_not_equal	as_invalid_operand
	call	as_take_tile_register
	mov	[as_postbyte_register],al
	jmp	as_instruction_ready

as_set_evex_mode:
	mov	[as_evex_mode],al
	jmp	as_instruction_assembled

as_take_avx_register:
	lods	as_u8 [esi]
	call	as_get_size_operator
	cmp	al,10h
	if_not_equal	as_invalid_operand
	lods	as_u8 [esi]
as_convert_avx_register:
	mov	ah,al
	and	al,1Fh
	and	ah,0E0h
	sub	ah,60h
	if_below	as_invalid_operand
	if_zero	as_avx512_register_size
	sub	ah,60h
	if_below	as_invalid_operand
	if_not_zero	as_avx_register_size_ok
	mov	ah,16
	jmp	as_avx_register_size_ok
      as_avx512_register_size:
	mov	ah,64
      as_avx_register_size_ok:
	cmp	al,8
	if_below	as_match_register_size
	jmp	as_invalid_operand
	jmp	as_match_register_size
as_store_vex_instruction_code:
	test	[as_rex_prefix],10h
	if_not_zero	as_invalid_operand
	test	[as_vex_required],0F8h
	if_not_zero	as_store_evex_instruction_code
	test	[as_vex_register],10000b
	if_not_zero	as_store_evex_instruction_code
	cmp	[as_operand_size],64
	if_equal	as_store_evex_instruction_code
	mov	al,[as_base_code]
	cmp	al,0Fh
	if_not_equal	as_store_xop_instruction_code
	test	[as_vex_required],2
	if_not_zero	as_prepare_vex
	cmp	[as_evex_mode],0
	if_equal	as_prepare_vex
	cmp	[as_displacement_compression],1
	if_not_equal	as_prepare_vex
	cmp	edx,80h
	if_below	as_prepare_vex
	cmp	edx,-80h
	if_above_equal	as_prepare_vex
	mov	al,bl
	or	al,bh
	shr	al,4
	cmp	al,2
	if_equal	as_prepare_vex
	call	as_compress_displacement
	cmp	[as_displacement_compression],2
	if_above	as_prepare_evex
	if_below	as_prepare_vex
	dec	[as_displacement_compression]
	mov	edx,[as_uncompressed_displacement]
      as_prepare_vex:
	mov	ah,[as_extended_code]
	cmp	ah,38h
	if_equal	as_store_vex_0f38_instruction_code
	cmp	ah,3Ah
	if_equal	as_store_vex_0f3a_instruction_code
	test	[as_rex_prefix],1011b
	if_not_zero	as_store_vex_0f_instruction_code
	mov	[edi+2],ah
	mov	as_u8 [edi],0C5h
	mov	al,[as_vex_register]
	not	al
	shl	al,3
	mov	ah,[as_rex_prefix]
	shl	ah,5
	and	ah,80h
	xor	al,ah
	call	as_get_vex_lpp_bits
	mov	[edi+1],al
	call	as_check_vex
	add	edi,3
	ret
      as_get_vex_lpp_bits:
	cmp	[as_operand_size],32
	if_not_equal	as_get_vex_pp_bits
	or	al,100b
      as_get_vex_pp_bits:
	mov	ah,[as_opcode_prefix]
	cmp	ah,66h
	if_equal	as_vex_66
	cmp	ah,0F3h
	if_equal	as_vex_f3
	cmp	ah,0F2h
	if_equal	as_vex_f2
	test	ah,ah
	if_not_zero	as_disallowed_combination_of_registers
	ret
      as_vex_f2:
	or	al,11b
	ret
      as_vex_f3:
	or	al,10b
	ret
      as_vex_66:
	or	al,1
	ret
      as_store_vex_0f38_instruction_code:
	mov	al,11100010b
	mov	ah,[as_supplemental_code]
	jmp	as_make_c4_vex
      as_store_vex_0f3a_instruction_code:
	mov	al,11100011b
	mov	ah,[as_supplemental_code]
	jmp	as_make_c4_vex
      as_store_vex_0f_instruction_code:
	mov	al,11100001b
      as_make_c4_vex:
	mov	[edi+3],ah
	mov	as_u8 [edi],0C4h
	mov	ah,[as_rex_prefix]
	shl	ah,5
	xor	al,ah
	mov	[edi+1],al
	call	as_check_vex
	mov	al,[as_vex_register]
	xor	al,1111b
	shl	al,3
	mov	ah,[as_rex_prefix]
	shl	ah,4
	and	ah,80h
	or	al,ah
	call	as_get_vex_lpp_bits
	mov	[edi+2],al
	add	edi,4
	ret
      as_check_vex:
	not	al
	test	al,11000000b
	if_not_zero	as_invalid_operand
	test	[as_rex_prefix],40h
	if_not_zero	as_invalid_operand
      as_vex_ok:
	ret
as_store_xop_instruction_code:
	mov	[edi+3],al
	mov	as_u8 [edi],8Fh
	mov	al,[as_xop_opcode_map]
	mov	ah,[as_rex_prefix]
	test	ah,40h
	if_zero	as_xop_ok
	jmp	as_invalid_operand
      as_xop_ok:
	not	ah
	shl	ah,5
	xor	al,ah
	mov	[edi+1],al
	mov	al,[as_vex_register]
	xor	al,1111b
	shl	al,3
	mov	ah,[as_rex_prefix]
	shl	ah,4
	and	ah,80h
	or	al,ah
	call	as_get_vex_lpp_bits
	mov	[edi+2],al
	add	edi,4
	ret
as_store_evex_instruction_code:
	test	[as_vex_required],2
	if_not_zero	as_invalid_operand
	cmp	[as_base_code],0Fh
	if_not_equal	as_invalid_operand
	cmp	[as_displacement_compression],1
	if_not_equal	as_prepare_evex
	call	as_compress_displacement
      as_prepare_evex:
	mov	ah,[as_extended_code]
	cmp	ah,38h
	if_equal	as_store_evex_0f38_instruction_code
	cmp	ah,3Ah
	if_equal	as_store_evex_0f3a_instruction_code
	mov	al,11110001b
      as_make_evex:
	mov	[edi+4],ah
	mov	as_u8 [edi],62h
	mov	ah,[as_rex_prefix]
	shl	ah,5
	xor	al,ah
	mov	ah,[as_vex_required]
	and	ah,10h
	xor	al,ah
	mov	[edi+1],al
	call	as_check_vex
	mov	al,[as_vex_register]
	not	al
	and	al,1111b
	shl	al,3
	mov	ah,[as_rex_prefix]
	shl	ah,4
	or	ah,[as_rex_prefix]
	and	ah,80h
	or	al,ah
	or	al,100b
	call	as_get_vex_pp_bits
	mov	[edi+2],al
	mov	al,[as_vex_register]
	not	al
	shr	al,1
	and	al,1000b
	test	[as_vex_required],80h
	if_not_equal	as_evex_rounding
	mov	ah,[as_operand_size]
	cmp	ah,16
	if_below_equal	as_evex_l_ok
	or	al,ah
	jmp	as_evex_l_ok
      as_evex_rounding:
	mov	ah,[as_rounding_mode]
	shl	ah,5
	or	al,ah
      as_evex_l_ok:
	test	[as_vex_required],20h
	if_zero	as_evex_zaaa_ok
	or	al,[as_mask_register]
      as_evex_zaaa_ok:
	test	[as_vex_required],40h
	if_zero	as_evex_b_ok
	or	al,10h
      as_evex_b_ok:
	mov	[edi+3],al
	add	edi,5
	ret
      as_store_evex_0f38_instruction_code:
	mov	al,11110010b
	mov	ah,[as_supplemental_code]
	jmp	as_make_evex
      as_store_evex_0f3a_instruction_code:
	mov	al,11110011b
	mov	ah,[as_supplemental_code]
	jmp	as_make_evex
as_compress_displacement:
	mov	ebp,ecx
	mov	[as_uncompressed_displacement],edx
	or	edx,edx
	if_zero	as_displacement_compressed
	xor	ecx,ecx
	mov	cl,[as_mmx_size]
	test	cl,cl
	if_not_zero	as_calculate_displacement_scale
	mov	cl,[as_operand_size]
      as_calculate_displacement_scale:
	bit_scan_forward	ecx,ecx
	if_zero	as_displacement_compression_ok
	xor	eax,eax
	shrd	eax,edx,cl
	if_not_zero	as_displacement_not_compressed
	sar	edx,cl
	cmp	edx,80h
	if_below	as_displacement_compressed
	cmp	edx,-80h
	if_above_equal	as_displacement_compressed
	shl	edx,cl
      as_displacement_not_compressed:
	inc	[as_displacement_compression]
	jmp	as_displacement_compression_ok
      as_displacement_compressed:
	add	[as_displacement_compression],2
      as_displacement_compression_ok:
	mov	ecx,ebp
	ret
