; SPDX-License-Identifier: BSD-2-Clause
; Copyright (c) 2026 danko1122q
; All rights reserved.

as_formatter:
SHF_NAME      = 00h
SHF_TYPE      = 04h
SHF_FLAGS     = 08h
SHF_ADDR      = 0Ch
SHF_OFFSET    = 10h
SHF_SIZE      = 14h
SHF_LINK      = 18h
SHF_INFO      = 1Ch
SHF_ALIGN     = 20h
SHF_ENTSIZE   = 24h

PHF_TYPE      = 00h
PHF_OFFSET    = 04h
PHF_VADDR     = 08h
PHF_PADDR     = 0Ch
PHF_FILESZ    = 10h
PHF_MEMSZ     = 14h
PHF_FLAGS     = 18h
PHF_ALIGN     = 1Ch

	mov	[as_current_offset],edi
	cmp	[as_output_file],0
	if_not_equal	as_output_path_ok
	mov	esi,[as_input_file]
	mov	edi,[as_free_additional_memory]
      as_duplicate_output_path:
	lods	as_u8 [esi]
	cmp	edi,[as_structures_buffer]
	if_above_equal	as_out_of_memory
	stos	as_u8 [edi]
	or	al,al
	if_not_zero	as_duplicate_output_path
	dec	edi
	mov	eax,edi
      as_find_extension:
	dec	eax
	cmp	eax,[as_free_additional_memory]
	if_below	as_extension_found
	cmp	as_u8 [eax],'\'
	if_equal	as_extension_found
	cmp	as_u8 [eax],'/'
	if_equal	as_extension_found
	cmp	as_u8 [eax],'.'
	if_not_equal	as_find_extension
	mov	edi,eax
      as_extension_found:
	lea	eax,[edi+9]
	cmp	eax,[as_structures_buffer]
	if_above_equal	as_out_of_memory
	cmp	[as_file_extension],0
	if_not_equal	as_extension_specified
	mov	al,[as_output_format]
	if_below	as_bin_extension
	cmp	al,4
	if_equal	as_obj_extension
	cmp	al,5
	if_equal	as_o_extension
      as_no_extension:
	xor	eax,eax
	jmp	as_make_extension
      as_bin_extension:
	mov	eax,'.bin'
	bit_test	[as_format_flags],0
	if_not_carry	as_make_extension
	mov	eax,'.com'
	jmp	as_make_extension
      as_obj_extension:
	mov	eax,'.obj'
	jmp	as_make_extension
      as_o_extension:
	mov	eax,'.o'
	bit_test	[as_format_flags],0
	if_not_carry	as_make_extension
	xor	eax,eax
      as_make_extension:
	xchg	eax,[edi]
	scas	as_u32 [edi]
	mov	as_u8 [edi],0
	scas	as_u8 [edi]
	mov	esi,edi
	stos	as_u32 [edi]
	sub	edi,9
	xor	eax,eax
	mov	ebx,as_characters
      as_adapt_case:
	mov	al,[esi]
	or	al,al
	if_zero	as_adapt_next
	translate_byte	as_u8 [ebx]
	cmp	al,[esi]
	if_equal	as_adapt_ok
	sub	as_u8 [edi],20h
      as_adapt_ok:
	inc	esi
      as_adapt_next:
	inc	edi
	cmp	as_u8 [edi],0
	if_not_equal	as_adapt_case
	jmp	as_extension_ok
      as_extension_specified:
	mov	al,'.'
	stos	as_u8 [edi]
	mov	esi,[as_file_extension]
      as_copy_extension:
	lods	as_u8 [esi]
	stos	as_u8 [edi]
	test	al,al
	if_not_zero	as_copy_extension
	dec	edi
      as_extension_ok:
	mov	esi,edi
	lea	ecx,[esi+1]
	sub	ecx,[as_free_additional_memory]
	mov	edi,[as_structures_buffer]
	dec	edi
	set_direction
	rep	movs as_u8 [edi],[esi]
	clear_direction
	inc	edi
	mov	[as_structures_buffer],edi
	mov	[as_output_file],edi
      as_output_path_ok:
	cmp	[as_symbols_file],0
	if_equal	as_labels_table_ok
	mov	ecx,[as_memory_end]
	sub	ecx,[as_labels_list]
	mov	edi,[as_tagged_blocks]
	sub	edi,8
	mov	[edi],ecx
	or	as_u32 [edi+4],-1
	sub	edi,ecx
	cmp	edi,[as_current_offset]
	if_below_equal	as_out_of_memory
	mov	[as_tagged_blocks],edi
	mov	esi,[as_memory_end]
      as_copy_labels:
	sub	esi,32
	cmp	esi,[as_labels_list]
	if_below	as_labels_table_ok
	mov	ecx,32 shr 2
	rep	movs as_u32 [edi],[esi]
	sub	esi,32
	jmp	as_copy_labels
      as_labels_table_ok:
	mov	edi,[as_current_offset]
	cmp	[as_output_format],5
	if_equal	as_elf_formatter_route
	jmp	as_common_formatter
      as_elf_formatter_route:
	bit_test	[as_format_flags],0
	if_not_carry	as_elf_formatter
      as_common_formatter:
	mov	eax,edi
	sub	eax,[as_code_start]
	mov	[as_real_code_size],eax
	cmp	edi,[as_undefined_data_end]
	if_not_equal	as_calculate_code_size
	mov	edi,[as_undefined_data_start]
      as_calculate_code_size:
	mov	[as_current_offset],edi
	sub	edi,[as_code_start]
	mov	[as_code_size],edi
	and	[as_written_size],0
	mov	edx,[as_output_file]
	call	as_create
	if_carry	as_write_failed
      as_write_output:
	call	as_write_code
      as_output_written:
	call	as_close
	cmp	[as_symbols_file],0
	if_not_equal	as_dump_symbols
	ret
      as_write_code:
	mov	eax,[as_written_size]
	mov	[as_headers_size],eax
	mov	edx,[as_code_start]
	mov	ecx,[as_code_size]
	add	[as_written_size],ecx
	lea	eax,[edx+ecx]
	call	as_write
	if_carry	as_write_failed
	ret
as_format_directive:
	cmp	edi,[as_code_start]
	if_not_equal	as_unexpected_instruction
	mov	ebp,[as_addressing_space]
	test	as_u8 [ds:ebp+0Ah],1
	if_not_zero	as_unexpected_instruction
	cmp	[as_output_format],0
	if_not_equal	as_unexpected_instruction
	lods	as_u8 [esi]
	cmp	al,1Ch
	if_equal	as_format_prefix
	cmp	al,18h
	if_not_equal	as_invalid_argument
	lods	as_u8 [esi]
      as_select_format:
	mov	dl,al
	shr	al,4
	mov	[as_output_format],al
	and	edx,0Fh
	or	[as_format_flags],edx
	cmp	al,2
	if_equal	as_illegal_instruction
	cmp	al,1
	if_equal	as_arc_check_com
      as_select_format_cont:
	cmp	al,3
	if_equal	as_illegal_instruction
	cmp	al,5
	if_equal	as_format_elf
      as_format_defined:
	test	[as_format_flags],20h
	if_not_zero	as_arc_com_setup
      as_format_defined_cont:
	cmp	as_u8 [esi],86h
	if_not_equal	as_instruction_assembled
	cmp	as_u16 [esi+1],'('
	if_not_equal	as_invalid_argument
	mov	eax,[esi+3]
	add	esi,3+4
	mov	[as_file_extension],esi
	lea	esi,[esi+eax+1]
	jmp	as_instruction_assembled
      as_arc_check_com:
	bit_test	[as_format_flags],0
	if_not_carry	as_arc_binary_format
	and	[as_format_flags],0FFFFFFFEh
	or	[as_format_flags],20h
	jmp	as_select_format_cont
      as_arc_binary_format:
	and	[as_format_flags],0FFFFFFFEh
	mov	[as_output_format],0
	jmp	as_format_defined
      as_arc_com_setup:
	and	[as_format_flags],0FFFFFFDFh
	mov	ebx,[as_addressing_space]
	sub	as_u32 [ebx],100h
	jmp	as_format_defined_cont
      as_format_prefix:
	lods	as_u8 [esi]
	mov	ah,al
	lods	as_u8 [esi]
	cmp	al,18h
	if_not_equal	as_invalid_argument
	lods	as_u8 [esi]
	mov	edx,eax
	shr	dl,4
	shr	dh,4
	cmp	dl,dh
	if_not_equal	as_invalid_argument
	or	al,ah
	jmp	as_select_format
as_entry_directive:
	bit_test_set	[as_format_flags],10h
	if_carry	as_setting_already_specified
	mov	al,[as_output_format]
	cmp	al,5
	if_not_equal	as_illegal_instruction
	bit_test	[as_format_flags],0
	if_carry	as_elf_entry
	jmp	as_illegal_instruction
as_stack_directive:
	jmp	as_illegal_instruction
as_heap_directive:
	jmp	as_illegal_instruction
as_data_directive:
	jmp	as_illegal_instruction
as_end_data:
	jmp	as_illegal_instruction
as_segment_directive:
	mov	al,[as_output_format]
	cmp	al,5
	if_equal	as_elf_segment
	jmp	as_illegal_instruction
as_section_directive:
	mov	al,[as_output_format]
	cmp	al,5
	if_equal	as_elf_section
	jmp	as_illegal_instruction
as_public_directive:
	mov	al,[as_output_format]
	cmp	al,5
	if_not_equal	as_illegal_instruction
	bit_test	[as_format_flags],0
	if_carry	as_illegal_instruction
      as_public_allowed:
	mov	[as_base_code],0C0h
	lods	as_u8 [esi]
	cmp	al,2
	if_equal	as_public_label
	cmp	al,1Dh
	if_not_equal	as_invalid_argument
	lods	as_u8 [esi]
	and	al,7
	add	[as_base_code],al
	lods	as_u8 [esi]
	cmp	al,2
	if_not_equal	as_invalid_argument
      as_public_label:
	lods	as_u32 [esi]
	cmp	eax,0Fh
	if_below	as_invalid_use_of_symbol
	if_equal	as_reserved_word_used_as_symbol
	inc	esi
	mov	dx,[as_current_pass]
	mov	[eax+18],dx
	or	as_u8 [eax+8],8
	mov	ebx,eax
	call	as_store_label_reference
	mov	eax,ebx
	mov	ebx,[as_free_additional_memory]
	lea	edx,[ebx+10h]
	cmp	edx,[as_structures_buffer]
	if_above_equal	as_out_of_memory
	mov	[as_free_additional_memory],edx
	mov	[ebx+8],eax
	mov	eax,[as_current_line]
	mov	[ebx+0Ch],eax
	lods	as_u8 [esi]
	cmp	al,86h
	if_not_equal	as_invalid_argument
	lods	as_u16 [esi]
	cmp	ax,'('
	if_not_equal	as_invalid_argument
	mov	[ebx+4],esi
	lods	as_u32 [esi]
	lea	esi,[esi+eax+1]
	mov	al,[as_base_code]
	mov	[ebx],al
	jmp	as_instruction_assembled
as_extrn_directive:
	mov	al,[as_output_format]
	cmp	al,4
	if_equal	as_extrn_allowed
	cmp	al,5
	if_not_equal	as_illegal_instruction
	bit_test	[as_format_flags],0
	if_carry	as_illegal_instruction
      as_extrn_allowed:
	lods	as_u16 [esi]
	cmp	ax,'('
	if_not_equal	as_invalid_argument
	mov	ebx,esi
	lods	as_u32 [esi]
	lea	esi,[esi+eax+1]
	mov	edx,[as_free_additional_memory]
	lea	eax,[edx+0Ch]
	cmp	eax,[as_structures_buffer]
	if_above_equal	as_out_of_memory
	mov	[as_free_additional_memory],eax
	mov	as_u8 [edx],80h
	mov	[edx+4],ebx
	lods	as_u8 [esi]
	cmp	al,86h
	if_not_equal	as_invalid_argument
	lods	as_u8 [esi]
	cmp	al,2
	if_not_equal	as_invalid_argument
	lods	as_u32 [esi]
	cmp	eax,0Fh
	if_below	as_invalid_use_of_symbol
	if_equal	as_reserved_word_used_as_symbol
	inc	esi
	mov	ebx,eax
	xor	ah,ah
	lods	as_u8 [esi]
	cmp	al,':'
	if_equal	as_get_extrn_size
	dec	esi
	cmp	al,11h
	if_not_equal	as_extrn_size_ok
      as_get_extrn_size:
	lods	as_u16 [esi]
	cmp	al,11h
	if_not_equal	as_invalid_argument
      as_extrn_size_ok:
	mov	[as_address_symbol],edx
	mov	[as_label_size],ah
	movzx	ecx,ah
	mov	[edx+8],ecx
	xor	eax,eax
	xor	edx,edx
	xor	ebp,ebp
	mov	[as_address_sign],0
	mov	ch,2
	jmp	as_make_free_label
	mov	ch,4
	jmp	as_make_free_label
as_mark_relocation:
	cmp	[as_value_type],0
	if_equal	as_relocation_ok
	mov	ebp,[as_addressing_space]
	test	as_u8 [ds:ebp+0Ah],1
	if_not_zero	as_relocation_ok
	cmp	[as_output_format],5
	if_equal	as_mark_elf_relocation
      as_relocation_ok:
	ret
as_close_pass:
	mov	al,[as_output_format]
	cmp	al,5
	if_equal	as_close_elf
	ret

as_recoverable_invalid_address:
	cmp	[as_error_line],0
	if_not_equal	as_ignore_invalid_address
	push	[as_current_line]
	pop	[as_error_line]
	mov	[as_error],as_invalid_address
      as_ignore_invalid_address:
	ret

      as_prepare_default_section:
	mov	ebx,[as_symbols_stream]
	cmp	as_u32 [ebx+0Ch],0
	if_not_equal	as_default_section_ok
	cmp	[as_number_of_sections],0
	if_equal	as_default_section_ok
	mov	edx,ebx
      as_find_references_to_default_section:
	cmp	ebx,[as_free_additional_memory]
	if_not_equal	as_check_reference
	add	[as_symbols_stream],20h
	ret
      as_check_reference:
	mov	al,[ebx]
	or	al,al
	if_zero	as_skip_other_section
	cmp	al,0C0h
	if_above_equal	as_check_public_reference
	cmp	al,80h
	if_above_equal	as_next_reference
	cmp	edx,[ebx+8]
	if_equal	as_default_section_ok
      as_next_reference:
	add	ebx,0Ch
	jmp	as_find_references_to_default_section
      as_check_public_reference:
	mov	eax,[ebx+8]
	add	ebx,10h
	test	as_u8 [eax+8],1
	if_zero	as_find_references_to_default_section
	mov	cx,[as_current_pass]
	cmp	cx,[eax+16]
	if_not_equal	as_find_references_to_default_section
	cmp	edx,[eax+20]
	if_equal	as_default_section_ok
	jmp	as_find_references_to_default_section
      as_skip_other_section:
	add	ebx,20h
	jmp	as_find_references_to_default_section
      as_default_section_ok:
	inc	[as_number_of_sections]
	ret
      as_symbols_enumerated:
	mov	[ebx+0Ch],eax
	mov	ebp,edi
	sub	ebp,ebx
	push	ebp
	lea	edi,[ebx+14h]
	mov	esi,[as_symbols_stream]
      as_find_section:
	cmp	esi,[as_free_additional_memory]
	if_equal	as_sections_finished
	mov	al,[esi]
	or	al,al
	if_zero	as_section_found
	add	esi,0Ch
	cmp	al,0C0h
	if_below	as_find_section
	add	esi,4
	jmp	as_find_section
      as_section_found:
	push	esi edi
	mov	esi,[esi+4]
	or	esi,esi
	if_zero	as_default_section
	mov	ecx,[esi]
	add	esi,4
	rep	movs as_u8 [edi],[esi]
	jmp	as_section_name_ok
      as_default_section:
	mov	al,'.'
	stos	as_u8 [edi]
	mov	eax,'flat'
	stos	as_u32 [edi]
      as_section_name_ok:
	pop	edi esi
	mov	eax,[esi+0Ch]
	mov	[edi+10h],eax
	mov	eax,[esi+14h]
	mov	[edi+24h],eax
	test	al,80h
	if_not_zero	as_section_ptr_ok
	mov	eax,[esi+8]
	sub	eax,[as_code_start]
	add	eax,ebp
	mov	[edi+14h],eax
      as_section_ptr_ok:
	mov	ebx,[as_code_start]
	mov	edx,[as_code_size]
	add	ebx,edx
	add	edx,ebp
	xor	ecx,ecx
	add	esi,20h
      as_find_relocations:
	cmp	esi,[as_free_additional_memory]
	if_equal	as_section_relocations_done
	mov	al,[esi]
	or	al,al
	if_zero	as_section_relocations_done
	cmp	al,80h
	if_below	as_add_relocation
	cmp	al,0C0h
	if_below	as_next_relocation
	add	esi,10h
	jmp	as_find_relocations
      as_add_relocation:
	lea	eax,[ebx+0Ah]
	cmp	eax,[as_tagged_blocks]
	if_above	as_out_of_memory
	mov	eax,[esi+4]
	mov	[ebx],eax
	mov	eax,[esi+8]
	mov	eax,[eax]
	shr	eax,8
	mov	[ebx+4],eax
	movzx	ax,as_u8 [esi]
	mov	[ebx+8],ax
	add	ebx,0Ah
	inc	ecx
      as_next_relocation:
	add	esi,0Ch
	jmp	as_find_relocations
      as_section_relocations_done:
	cmp	ecx,10000h
	if_below	as_section_relocations_count_16bit
	bit_test	[as_format_flags],0
	if_not_carry	as_format_limitations_exceeded
	mov	as_u16 [edi+20h],0FFFFh
	or	as_u32 [edi+24h],1000000h
	mov	[edi+18h],edx
	push	esi edi
	push	ecx
	lea	esi,[ebx-1]
	add	ebx,0Ah
	lea	edi,[ebx-1]
	signed_multiply	ecx,0Ah
	set_direction
	rep	movs as_u8 [edi],[esi]
	clear_direction
	pop	ecx
	inc	esi
	inc	ecx
	mov	[esi], ecx
	xor	eax, eax
	mov	[esi+4], eax
	mov	[esi+8], ax
	pop	edi esi
	jmp	as_section_relocations_ok
      as_section_relocations_count_16bit:
	mov	[edi+20h],cx
	jcxz	as_section_relocations_ok
	mov	[edi+18h],edx
      as_section_relocations_ok:
	sub	ebx,[as_code_start]
	mov	[as_code_size],ebx
	add	edi,28h
	jmp	as_find_section
      as_sections_finished:
	mov	edx,[as_free_additional_memory]
	mov	ebx,[as_code_size]
	add	ebp,ebx
	mov	[edx+8],ebp
	add	ebx,[as_code_start]
	mov	edi,ebx
	mov	ecx,[edx+0Ch]
	signed_multiply	ecx,12h shr 1
	xor	eax,eax
	shr	ecx,1
	if_not_carry	as_zero_symbols_table
	stos	as_u16 [edi]
      as_zero_symbols_table:
	rep	stos as_u32 [edi]
	mov	edx,edi
	stos	as_u32 [edi]
	mov	esi,[as_symbols_stream]
      as_make_symbols_table:
	cmp	esi,[as_free_additional_memory]
	if_equal	as_symbols_table_ok
	mov	al,[esi]
	cmp	al,0C0h
	if_above_equal	as_add_public_symbol
	cmp	al,80h
	if_above_equal	as_add_extrn_symbol
	or	al,al
	if_zero	as_add_section_symbol
	add	esi,0Ch
	jmp	as_make_symbols_table
      as_add_section_symbol:
	call	as_store_symbol_name
	movzx	eax,as_u16 [esi+1Eh]
	mov	[ebx+0Ch],ax
	mov	as_u8 [ebx+10h],3
	add	esi,20h
	add	ebx,12h
	jmp	as_make_symbols_table
      as_add_extrn_symbol:
	call	as_store_symbol_name
	mov	as_u8 [ebx+10h],2
	add	esi,0Ch
	add	ebx,12h
	jmp	as_make_symbols_table
      as_add_public_symbol:
	call	as_store_symbol_name
	mov	eax,[esi+0Ch]
	mov	[as_current_line],eax
	mov	eax,[esi+8]
	test	as_u8 [eax+8],1
	if_zero	as_undefined_symbol_ref
	mov	cx,[as_current_pass]
	cmp	cx,[eax+16]
	if_not_equal	as_undefined_symbol_ref
	mov	cl,[eax+11]
	or	cl,cl
	if_zero	as_public_constant
	cmp	cl,2
	if_equal	as_public_symbol_type_ok
	jmp	as_invalid_use_of_symbol
      as_undefined_symbol_ref:
	mov	[as_error_info],eax
	jmp	as_undefined_symbol
      as_public_symbol_type_ok:
	mov	ecx,[eax+20]
	cmp	as_u8 [ecx],80h
	if_equal	as_alias_symbol
	cmp	as_u8 [ecx],0
	if_not_equal	as_invalid_use_of_symbol
	mov	cx,[ecx+1Eh]
	mov	[ebx+0Ch],cx
      as_public_symbol_section_ok:
	movzx	ecx,as_u8 [eax+9]
	shr	cl,1
	and	cl,1
	negate	ecx
	cmp	ecx,[eax+4]
	if_not_equal	as_value_out_of_range
	xor	ecx,[eax]
	if_sign	as_value_out_of_range
	mov	eax,[eax]
	mov	[ebx+8],eax
	mov	al,2
	cmp	as_u8 [esi],0C0h
	if_equal	as_store_symbol_class
	inc	al
	cmp	as_u8 [esi],0C1h
	if_equal	as_store_symbol_class
	mov	al,105
      as_store_symbol_class:
	mov	as_u8 [ebx+10h],al
	add	esi,10h
	add	ebx,12h
	jmp	as_make_symbols_table
      as_alias_symbol:
	bit_test	[as_format_flags],0
	if_not_carry	as_invalid_use_of_symbol
	mov	ecx,[eax]
	or	ecx,[eax+4]
	if_not_zero	as_invalid_use_of_symbol
	mov	as_u8 [ebx+10h],69h
	mov	as_u8 [ebx+11h],1
	add	ebx,12h
	mov	ecx,[eax+20]
	mov	ecx,[ecx]
	shr	ecx,8
	mov	[ebx],ecx
	mov	as_u8 [ebx+4],3
	add	esi,10h
	add	ebx,12h
	jmp	as_make_symbols_table
      as_public_constant:
	mov	as_u16 [ebx+0Ch],0FFFFh
	jmp	as_public_symbol_section_ok
      as_symbols_table_ok:
	mov	eax,edi
	sub	eax,edx
	mov	[edx],eax
	sub	edi,[as_code_start]
	mov	[as_code_size],edi
	and	[as_written_size],0
	mov	edx,[as_output_file]
	call	as_create
	if_carry	as_write_failed
	mov	edx,[as_free_additional_memory]
	pop	ecx
	add	[as_written_size],ecx
	call	as_write
	if_carry	as_write_failed
	jmp	as_write_output
      as_store_symbol_name:
	push	esi
	mov	esi,[esi+4]
	or	esi,esi
	if_zero	as_default_name
	lods	as_u32 [esi]
	mov	ecx,eax
	cmp	ecx,8
	if_above	as_add_string
	push	edi
	mov	edi,ebx
	rep	movs as_u8 [edi],[esi]
	pop	edi esi
	ret
      as_default_name:
	mov	as_u32 [ebx],'.fla'
	mov	as_u32 [ebx+4],'t'
	pop	esi
	ret
      as_add_string:
	mov	eax,edi
	sub	eax,edx
	mov	[ebx+4],eax
	inc	ecx
	rep	movs as_u8 [edi],[esi]
	pop	esi
	ret

as_format_elf:
	mov	edx,edi
	mov	ecx,34h shr 2
	lea	eax,[edi+ecx*4]
	cmp	eax,[as_tagged_blocks]
	if_above_equal	as_out_of_memory
	xor	eax,eax
	rep	stos as_u32 [edi]
	mov	as_u32 [edx],7Fh + 'ELF' shl 8
	mov	al,1
	mov	[edx+4],al
	mov	[edx+5],al
	mov	[edx+6],al
	mov	[edx+14h],al
	mov	as_u8 [edx+12h],3
	mov	as_u8 [edx+28h],34h
	mov	as_u8 [edx+2Eh],28h
	mov	[as_code_type],32
	mov	as_u8 [edx+10h],2
	cmp	as_u16 [esi],1D19h
	if_equal	as_format_elf_exe
	mov	as_u8 [edx+10h],3
	cmp	as_u16 [esi],021Eh
	if_equal	as_format_elf_exe
      as_elf_header_ok:
	mov	as_u8 [edx+10h],1
	mov	eax,[as_additional_memory]
	mov	[as_symbols_stream],eax
	mov	ebx,eax
	add	eax,20h
	cmp	eax,[as_structures_buffer]
	if_above_equal	as_out_of_memory
	mov	[as_free_additional_memory],eax
	xor	eax,eax
	mov	[as_current_section],ebx
	mov	[as_number_of_sections],eax
	mov	[ebx],al
	mov	[ebx+4],eax
	mov	[ebx+8],edi
	mov	al,111b
	mov	[ebx+14h],eax
	mov	al,4
	mov	[ebx+10h],eax
	mov	edx,ebx
	call	as_init_addressing_space
	xchg	edx,ebx
	mov	[edx+14h],ebx
	mov	as_u8 [edx+9],2
	jmp	as_format_defined
as_elf_section:
	bit_test	[as_format_flags],0
	if_carry	as_illegal_instruction
	call	as_close_section
	mov	ebx,[as_free_additional_memory]
	lea	eax,[ebx+20h]
	cmp	eax,[as_structures_buffer]
	if_above_equal	as_out_of_memory
	mov	[as_free_additional_memory],eax
	mov	[as_current_section],ebx
	inc	as_u16 [as_number_of_sections]
	if_zero	as_format_limitations_exceeded
	xor	eax,eax
	mov	[ebx],al
	mov	[ebx+8],edi
	mov	[ebx+10h],eax
	mov	al,10b
	mov	[ebx+14h],eax
	mov	edx,ebx
	call	as_create_addressing_space
	xchg	edx,ebx
	mov	[edx+14h],ebx
	mov	as_u8 [edx+9],2
      as_elf_labels_type_ok:
	lods	as_u16 [esi]
	cmp	ax,'('
	if_not_equal	as_invalid_argument
	mov	[ebx+4],esi
	mov	ecx,[esi]
	lea	esi,[esi+4+ecx+1]
      as_elf_section_flags:
	cmp	as_u8 [esi],8Ch
	if_equal	as_elf_section_alignment
	cmp	as_u8 [esi],19h
	if_not_equal	as_elf_section_settings_ok
	inc	esi
	lods	as_u8 [esi]
	sub	al,28
	xor	al,11b
	test	al,not 10b
	if_not_zero	as_invalid_argument
	mov	cl,al
	mov	al,1
	shl	al,cl
	test	as_u8 [ebx+14h],al
	if_not_zero	as_setting_already_specified
	or	as_u8 [ebx+14h],al
	jmp	as_elf_section_flags
      as_elf_section_alignment:
	inc	esi
	lods	as_u8 [esi]
	cmp	al,'('
	if_not_equal	as_invalid_argument
	cmp	as_u8 [esi],'.'
	if_equal	as_invalid_value
	push	ebx
	call	as_get_count_value
	pop	ebx
	mov	edx,eax
	dec	edx
	test	eax,edx
	if_not_zero	as_invalid_value
	or	eax,eax
	if_zero	as_invalid_value
	xchg	[ebx+10h],eax
	or	eax,eax
	if_not_zero	as_setting_already_specified
	jmp	as_elf_section_flags
      as_elf_section_settings_ok:
	cmp	as_u32 [ebx+10h],0
	if_not_equal	as_instruction_assembled
	mov	as_u32 [ebx+10h],4
	jmp	as_instruction_assembled
      as_close_section:
	mov	ebx,[as_current_section]
	mov	eax,edi
	mov	edx,[ebx+8]
	sub	eax,edx
	mov	[ebx+0Ch],eax
	xor	eax,eax
	xchg	[as_undefined_data_end],eax
	cmp	eax,edi
	if_not_equal	as_close_section_ok
	cmp	edx,[as_undefined_data_start]
	if_not_equal	as_close_section_ok
	mov	edi,edx
	or	as_u8 [ebx+14h],80h
      as_close_section_ok:
	ret
      as_store_relocation:
	mov	ebx,[as_free_additional_memory]
	add	ebx,0Ch
	cmp	ebx,[as_structures_buffer]
	if_above_equal	as_out_of_memory
	mov	[as_free_additional_memory],ebx
	mov	as_u8 [ebx-0Ch],al
	mov	eax,[as_current_section]
	mov	eax,[eax+8]
	negate	eax
	add	eax,edi
	mov	[ebx-0Ch+4],eax
	mov	eax,[as_symbol_identifier]
	mov	[ebx-0Ch+8],eax
	pop	eax ebx
	ret

as_mark_elf_relocation:
	test	[as_format_flags],1
	if_not_zero	as_invalid_use_of_symbol
	push	ebx
	mov	ebx,[as_addressing_space]
	cmp	[as_value_type],3
	if_equal	as_elf_relocation_relative
	cmp	[as_value_type],7
	if_equal	as_elf_relocation_relative
	push	eax
	cmp	[as_value_type],5
	if_equal	as_elf_gotoff_relocation
	if_above	as_invalid_use_of_symbol
	mov	al,1
	jmp	as_store_relocation
      as_elf_gotoff_relocation:
	mov	al,9
	jmp	as_store_relocation
      as_elf_relocation_relative:
	cmp	as_u8 [ebx+9],0
	if_equal	as_invalid_use_of_symbol
	mov	ebx,[as_current_section]
	mov	ebx,[ebx+8]
	sub	ebx,edi
	sub	eax,ebx
	push	eax
	mov	al,2
	cmp	[as_value_type],3
	if_equal	as_store_relocation
	mov	al,4
	jmp	as_store_relocation
as_close_elf:
	bit_test	[as_format_flags],0
	if_carry	as_close_elf_exe
	call	as_close_section
	cmp	[as_next_pass_needed],0
	if_equal	as_elf_closed
	mov	eax,[as_symbols_stream]
	mov	[as_free_additional_memory],eax
      as_elf_closed:
	ret
as_elf_formatter:
	mov	ecx,edi
	sub	ecx,[as_code_start]
	negate	ecx
	and	ecx,111b
	and	ecx,11b
      as_align_elf_structures:
	xor	al,al
	rep	stos as_u8 [edi]
	push	edi
	call	as_prepare_default_section
	mov	esi,[as_symbols_stream]
	mov	edi,[as_free_additional_memory]
	xor	eax,eax
	mov	ecx,4
	rep	stos as_u32 [edi]
      as_find_first_section:
	mov	al,[esi]
	or	al,al
	if_zero	as_first_section_found
	cmp	al,0C0h
	if_below	as_skip_other_symbol
	add	esi,4
      as_skip_other_symbol:
	add	esi,0Ch
	jmp	as_find_first_section
      as_first_section_found:
	mov	ebx,esi
	mov	ebp,esi
	add	esi,20h
	xor	ecx,ecx
	xor	edx,edx
      as_find_next_section:
	cmp	esi,[as_free_additional_memory]
	if_equal	as_make_section_symbol
	mov	al,[esi]
	or	al,al
	if_zero	as_make_section_symbol
	cmp	al,0C0h
	if_above_equal	as_skip_public
	cmp	al,80h
	if_above_equal	as_skip_extrn
	or	as_u8 [ebx+14h],40h
      as_skip_extrn:
	add	esi,0Ch
	jmp	as_find_next_section
      as_skip_public:
	add	esi,10h
	jmp	as_find_next_section
      as_make_section_symbol:
	mov	eax,edi
	xchg	eax,[ebx+4]
	stos	as_u32 [edi]
	xor	eax,eax
	stos	as_u32 [edi]
	stos	as_u32 [edi]
	call	as_store_section_index
	jmp	as_section_symbol_ok
      as_store_section_index:
	inc	ecx
	mov	eax, ecx
	shl	eax, 8
	mov	[ebx],eax
	inc	dx
	if_zero	as_format_limitations_exceeded
	mov	eax,edx
	shl	eax,16
	mov	al,3
	test	as_u8 [ebx+14h],40h
	if_zero	as_section_index_ok
	or	ah,-1
	inc	dx
	if_zero	as_format_limitations_exceeded
      as_section_index_ok:
	stos	as_u32 [edi]
	ret

      as_section_symbol_ok:
	mov	ebx,esi
	add	esi,20h
	cmp	ebx,[as_free_additional_memory]
	if_not_equal	as_find_next_section
	inc	dx
	if_zero	as_format_limitations_exceeded
	mov	[as_current_section],edx
	mov	esi,[as_symbols_stream]
      as_find_other_symbols:
	cmp	esi,[as_free_additional_memory]
	if_equal	as_elf_symbol_table_ok
	mov	al,[esi]
	or	al,al
	if_zero	as_skip_section
	cmp	al,0C0h
	if_above_equal	as_make_public_symbol
	cmp	al,80h
	if_above_equal	as_make_extrn_symbol
	add	esi,0Ch
	jmp	as_find_other_symbols
      as_skip_section:
	add	esi,20h
	jmp	as_find_other_symbols
      as_make_public_symbol:
	mov	eax,[esi+0Ch]
	mov	[as_current_line],eax
	cmp	as_u8 [esi],0C0h
	if_not_equal	as_invalid_argument
	mov	ebx,[esi+8]
	test	as_u8 [ebx+8],1
	if_zero	as_undefined_public
	mov	ax,[as_current_pass]
	cmp	ax,[ebx+16]
	if_not_equal	as_undefined_public
	mov	dl,[ebx+11]
	or	dl,dl
	if_zero	as_public_absolute
	mov	eax,[ebx+20]
	cmp	as_u8 [eax],0
	if_not_equal	as_invalid_use_of_symbol
	mov	eax,[eax+4]
	cmp	dl,2
	if_not_equal	as_invalid_use_of_symbol
	mov	dx,[eax+0Eh]
	jmp	as_section_for_public_ok
      as_undefined_public:
	mov	[as_error_info],ebx
	jmp	as_undefined_symbol

      as_public_absolute:
	mov	dx,0FFF1h
      as_section_for_public_ok:
	mov	eax,[esi+4]
	stos	as_u32 [edi]
	movzx	eax,as_u8 [ebx+9]
	shr	al,1
	and	al,1
	negate	eax
	cmp	eax,[ebx+4]
	if_not_equal	as_value_out_of_range
	xor	eax,[ebx]
	if_sign	as_value_out_of_range
	mov	eax,[ebx]
	stos	as_u32 [edi]
	xor	eax,eax
	mov	al,[ebx+10]
	stos	as_u32 [edi]
	mov	eax,edx
	shl	eax,16
	mov	al,10h
	cmp	as_u8 [ebx+10],0
	if_equal	as_elf_public_function
	or	al,1
	jmp	as_store_elf_public_info
      as_elf_public_function:
	or	al,2
      as_store_elf_public_info:
	stos	as_u32 [edi]
	jmp	as_public_symbol_ok
      as_public_symbol_ok:
	inc	ecx
	mov	eax, ecx
	shl	eax, 8
	mov	al,0C0h
	mov	[esi],eax
	add	esi,10h
	jmp	as_find_other_symbols
      as_make_extrn_symbol:
	mov	eax,[esi+4]
	stos	as_u32 [edi]
	xor	eax,eax
	stos	as_u32 [edi]
	mov	eax,[esi+8]
	stos	as_u32 [edi]
	mov	eax,10h
	stos	as_u32 [edi]
	jmp	as_extrn_symbol_ok

      as_extrn_symbol_ok:
	inc	ecx
	mov	eax, ecx
	shl	eax, 8
	mov	al,80h
	mov	[esi],eax
	add	esi,0Ch
	jmp	as_find_other_symbols
      as_elf_symbol_table_ok:
	mov	edx,edi
	mov	ebx,[as_free_additional_memory]
	xor	al,al
	stos	as_u8 [edi]
	add	edi,16
	mov	[edx+1],edx
	add	ebx,10h
      as_make_string_table:
	cmp	ebx,edx
	if_equal	as_elf_string_table_ok
	cmp	as_u8 [ebx+0Dh],0
	if_equal	as_rel_prefix_ok
	mov	as_u8 [ebx+0Dh],0
	mov	eax,'.rel'
	stos	as_u32 [edi]
      as_rel_prefix_ok:
	mov	esi,edi
	sub	esi,edx
	xchg	esi,[ebx]
	add	ebx,10h
      as_make_elf_string:
	or	esi,esi
	if_zero	as_default_string
	lods	as_u32 [esi]
	mov	ecx,eax
	rep	movs as_u8 [edi],[esi]
	xor	al,al
	stos	as_u8 [edi]
	jmp	as_make_string_table
      as_default_string:
	mov	eax,'.fla'
	stos	as_u32 [edi]
	mov	ax,'t'
	stos	as_u16 [edi]
	jmp	as_make_string_table
      as_elf_string_table_ok:
	mov	[edx+1+8],edi
	mov	ebx,[as_code_start]
	mov	eax,edi
	sub	eax,[as_free_additional_memory]
	xor	ecx,ecx
	sub	ecx,eax
	and	ecx,11b
	add	eax,ecx
	mov	[ebx+20h],eax
	mov	eax,[as_current_section]
	inc	ax
	if_zero	as_format_limitations_exceeded
	mov	[ebx+32h],ax
	inc	ax
	if_zero	as_format_limitations_exceeded
	mov	[ebx+30h],ax
      as_elf_header_finished:
	xor	eax,eax
	add	ecx,10*4
	rep	stos as_u8 [edi]
      as_elf_null_section_ok:
	mov	esi,ebp
	xor	ecx,ecx
      as_make_section_entry:
	mov	ebx,edi
	mov	eax,[esi+4]
	mov	eax,[eax]
	stos	as_u32 [edi]
	mov	eax,1
	cmp	as_u32 [esi+0Ch],0
	if_equal	as_bss_section
	test	as_u8 [esi+14h],80h
	if_zero	as_section_type_ok
      as_bss_section:
	mov	al,8
      as_section_type_ok:
	stos	as_u32 [edi]
	mov	eax,[esi+14h]
	and	al,3Fh
	call	as_store_elf_machine_word
	xor	eax,eax
	call	as_store_elf_machine_word
	mov	eax,[esi+8]
	mov	[as_image_base],eax
	sub	eax,[as_code_start]
	call	as_store_elf_machine_word
	mov	eax,[esi+0Ch]
	call	as_store_elf_machine_word
	xor	eax,eax
	stos	as_u32 [edi]
	stos	as_u32 [edi]
	mov	eax,[esi+10h]
	call	as_store_elf_machine_word
	xor	eax,eax
	call	as_store_elf_machine_word
	inc	ecx
	add	esi,20h
	xchg	edi,[esp]
	mov	ebp,edi
      as_convert_relocations:
	cmp	esi,[as_free_additional_memory]
	if_equal	as_relocations_converted
	mov	al,[esi]
	or	al,al
	if_zero	as_relocations_converted
	cmp	al,80h
	if_below	as_make_relocation_entry
	cmp	al,0C0h
	if_below	as_relocation_entry_ok
	add	esi,10h
	jmp	as_convert_relocations
      as_make_relocation_entry:
	mov	eax,[esi+4]
	stos	as_u32 [edi]
	mov	eax,[esi+8]
	mov	eax,[eax]
	mov	al,[esi]
	stos	as_u32 [edi]
	jmp	as_relocation_entry_ok
      as_relocation_entry_ok:
	add	esi,0Ch
	jmp	as_convert_relocations
      as_store_elf_machine_word:
	stos	as_u32 [edi]
      as_elf_machine_word_ok:
	ret
      as_relocations_converted:
	cmp	edi,ebp
	xchg	edi,[esp]
	if_equal	as_rel_section_ok
	mov	eax,[ebx]
	sub	eax,4
      as_store_relocations_name_offset:
	stos	as_u32 [edi]
	mov	eax,9
      as_store_relocations_type:
	stos	as_u32 [edi]
	xor	al,al
	call	as_store_elf_machine_word
	call	as_store_elf_machine_word
	mov	eax,ebp
	sub	eax,[as_code_start]
	call	as_store_elf_machine_word
	mov	eax,[esp]
	sub	eax,ebp
	call	as_store_elf_machine_word
	mov	eax,[as_current_section]
	stos	as_u32 [edi]
	mov	eax,ecx
	stos	as_u32 [edi]
	inc	ecx
	mov	eax,4
	stos	as_u32 [edi]
	mov	al,8
	stos	as_u32 [edi]
	jmp	as_rel_section_ok
      as_finish_elf_rela_section:
	mov	eax,8
	stos	as_u32 [edi]
	xor	al,al
	stos	as_u32 [edi]
	mov	al,24
	stos	as_u32 [edi]
	xor	al,al
	stos	as_u32 [edi]
      as_rel_section_ok:
	cmp	esi,[as_free_additional_memory]
	if_not_equal	as_make_section_entry
	pop	eax
	mov	ebx,[as_code_start]
	sub	eax,ebx
	mov	[as_code_size],eax
	mov	ecx,20h
	jmp	as_adjust_elf_section_headers_offset
	mov	ecx,28h
      as_adjust_elf_section_headers_offset:
	add	[ebx+ecx],eax
	mov	eax,1
	stos	as_u32 [edi]
	mov	al,2
	stos	as_u32 [edi]
	xor	al,al
	call	as_store_elf_machine_word
	call	as_store_elf_machine_word
	mov	eax,[as_code_size]
	call	as_store_elf_machine_word
	mov	eax,[edx+1]
	sub	eax,[as_free_additional_memory]
	call	as_store_elf_machine_word
	mov	eax,[as_current_section]
	inc	eax
	stos	as_u32 [edi]
	mov	eax,[as_number_of_sections]
	inc	eax
	stos	as_u32 [edi]
	mov	eax,4
	stos	as_u32 [edi]
	mov	al,10h
	stos	as_u32 [edi]
	jmp	as_sym_section_ok
      as_finish_elf_sym_section:
	mov	eax,8
	stos	as_u32 [edi]
	xor	al,al
	stos	as_u32 [edi]
	mov	al,18h
	stos	as_u32 [edi]
	xor	al,al
	stos	as_u32 [edi]
      as_sym_section_ok:
	mov	al,1+8
	stos	as_u32 [edi]
	mov	al,3
	stos	as_u32 [edi]
	xor	al,al
	call	as_store_elf_machine_word
	call	as_store_elf_machine_word
	mov	eax,[edx+1]
	sub	eax,[as_free_additional_memory]
	add	eax,[as_code_size]
	call	as_store_elf_machine_word
	mov	eax,[edx+1+8]
	sub	eax,[edx+1]
	call	as_store_elf_machine_word
	xor	eax,eax
	stos	as_u32 [edi]
	stos	as_u32 [edi]
	mov	al,1
	call	as_store_elf_machine_word
	xor	eax,eax
	call	as_store_elf_machine_word
	mov	eax,'tab'
	mov	as_u32 [edx+1],'.sym'
	mov	[edx+1+4],eax
	mov	as_u32 [edx+1+8],'.str'
	mov	[edx+1+8+4],eax
	mov	[as_resource_data],edx
	mov	[as_written_size],0
	mov	edx,[as_output_file]
	call	as_create
	if_carry	as_write_failed
	call	as_write_code
	mov	ecx,edi
	mov	edx,[as_free_additional_memory]
	sub	ecx,edx
	add	[as_written_size],ecx
	call	as_write
	if_carry	as_write_failed
	jmp	as_output_written

as_format_elf_exe:
	add	esi,2
	or	[as_format_flags],1
	cmp	as_u8 [esi],'('
	if_not_equal	as_elf_exe_brand_ok
	inc	esi
	cmp	as_u8 [esi],'.'
	if_equal	as_invalid_value
	push	edx
	call	as_get_byte_value
	cmp	[as_value_type],0
	if_not_equal	as_invalid_use_of_symbol
	pop	edx
	mov	[edx+7],al
      as_elf_exe_brand_ok:
	mov	[as_image_base],8048000h
	cmp	as_u8 [esi],80h
	if_not_equal	as_elf_exe_base_ok
	lods	as_u16 [esi]
	cmp	ah,'('
	if_not_equal	as_invalid_argument
	cmp	as_u8 [esi],'.'
	if_equal	as_invalid_value
	push	edx
	call	as_get_dword_value
	cmp	[as_value_type],0
	if_not_equal	as_invalid_use_of_symbol
	mov	[as_image_base],eax
	pop	edx
      as_elf_exe_base_ok:
	mov	as_u8 [edx+2Ah],20h
	mov	ebx,edi
	mov	ecx,20h shr 2
	cmp	[as_current_pass],0
	if_equal	as_init_elf_segments
	signed_multiply	ecx,[as_number_of_sections]
      as_init_elf_segments:
	xor	eax,eax
	rep	stos as_u32 [edi]
	and	[as_number_of_sections],0
	mov	as_u8 [ebx],1
	mov	as_u16 [ebx+1Ch],1000h
	mov	as_u8 [ebx+18h],111b
	mov	ebp,[as_image_base]
	and	as_u32 [ebx+4],0
	mov	[ebx+8],ebp
	mov	[ebx+0Ch],ebp
	mov	eax,edi
	sub	eax,[as_code_start]
	add	eax,ebp
	mov	[edx+18h],eax
	and	[as_image_base_high],0
      as_elf_exe_addressing_setup:
	call	as_init_addressing_space
	call	as_setup_elf_exe_labels_type
	mov	eax,[as_code_start]
	xor	edx,edx
	xor	cl,cl
	sub	eax,[as_image_base]
	sub_with_borrow	edx,[as_image_base_high]
	sub_with_borrow	cl,0
	mov	[ebx],eax
	mov	[ebx+4],edx
	mov	[ebx+8],cl
	mov	[as_symbols_stream],edi
	jmp	as_format_defined

as_elf_entry:
	lods	as_u8 [esi]
	cmp	al,'('
	if_not_equal	as_invalid_argument
	cmp	as_u8 [esi],'.'
	if_equal	as_invalid_value
	call	as_get_dword_value
	mov	edx,[as_code_start]
	mov	[edx+18h],eax
	jmp	as_instruction_assembled
as_elf_segment:
	bit_test	[as_format_flags],0
	if_not_carry	as_illegal_instruction
	call	as_close_elf_segment
	push	eax
	call	as_create_addressing_space
	call	as_setup_elf_exe_labels_type
	mov	ebp,ebx
	mov	ebx,[as_number_of_sections]
	shl	ebx,5
	add	ebx,[as_code_start]
	add	ebx,34h
	cmp	ebx,[as_symbols_stream]
	if_below	as_new_elf_segment
	mov	ebx,[as_symbols_stream]
	sub	ebx,20h
	or	[as_next_pass_needed],-1
      as_new_elf_segment:
	mov	as_u8 [ebx],1
	and	as_u32 [ebx+18h],0
	mov	as_u16 [ebx+1Ch],1000h
      as_elf_segment_flags:
	cmp	as_u8 [esi],1Eh
	if_equal	as_elf_segment_type
	cmp	as_u8 [esi],19h
	if_not_equal	as_elf_segment_flags_ok
	lods	as_u16 [esi]
	sub	ah,28
	if_below_equal	as_invalid_argument
	cmp	ah,1
	if_equal	as_mark_elf_segment_flag
	cmp	ah,3
	if_above	as_invalid_argument
	xor	ah,1
	cmp	ah,2
	if_equal	as_mark_elf_segment_flag
	inc	ah
      as_mark_elf_segment_flag:
	test	[ebx+18h],ah
	if_not_zero	as_setting_already_specified
	or	[ebx+18h],ah
	jmp	as_elf_segment_flags
      as_elf_segment_type:
	cmp	as_u8 [ebx],1
	if_not_equal	as_setting_already_specified
	lods	as_u16 [esi]
	mov	ecx,[as_number_of_sections]
	jecxz	as_elf_segment_type_ok
	mov	edx,[as_code_start]
	add	edx,34h
      as_scan_elf_segment_types:
	cmp	edx,[as_symbols_stream]
	if_above_equal	as_elf_segment_type_ok
	cmp	[edx],ah
	if_equal	as_data_already_defined
	add	edx,20h
	loop	as_scan_elf_segment_types
      as_elf_segment_type_ok:
	mov	[ebx],ah
	mov	as_u16 [ebx+1Ch],1
	cmp	ah,50h
	if_below	as_elf_segment_flags
	or	as_u32 [ebx],6474E500h
	jmp	as_elf_segment_flags
      as_elf_segment_flags_ok:
	pop	edx
	cmp	as_u8 [ebx],1
	if_not_equal	as_no_elf_segment_merging
	cmp	[as_merge_segment],0
	if_not_equal	as_merge_elf_segment
      as_no_elf_segment_merging:
	mov	eax,edi
	sub	eax,[as_code_start]
	mov	[ebx+4],eax
	and	eax,0FFFh
	add	eax,edx
	mov	[ebx+8],eax
	mov	[ebx+0Ch],eax
	xor	edx,edx
      as_elf_segment_addressing_setup:
	xor	cl,cl
	not	eax
	not	edx
	not	cl
	add	eax,1
	add_with_carry	edx,0
	add_with_carry	cl,0
	add	eax,edi
	add_with_carry	edx,0
	add_with_carry	cl,0
	mov	[ds:ebp],eax
	mov	[ds:ebp+4],edx
	mov	[ds:ebp+8],cl
	inc	[as_number_of_sections]
	jmp	as_instruction_assembled
      as_merge_elf_segment:
	xor	ecx,ecx
	xchg	ecx,[as_merge_segment]
	cmp	ecx,-1
	if_equal	as_merge_elf_header
	mov	eax,[ecx+8]
	mov	ecx,[ecx+4]
      as_elf_segment_separated_base:
	mov	[ebx+8],eax
	mov	[ebx+0Ch],eax
	mov	[ebx+4],ecx
	sub	eax,ecx
	add	eax,edi
	sub	eax,[as_code_start]
	xor	edx,edx
	jmp	as_elf_segment_addressing_setup
      as_merge_elf_header:
	mov	eax,[as_image_base]
	xor	ecx,ecx
	jmp	as_elf_segment_separated_base
      as_close_elf_segment:
	cmp	[as_number_of_sections],0
	if_not_equal	as_finish_elf_segment
	cmp	edi,[as_symbols_stream]
	if_not_equal	as_first_elf_segment_ok
	or	[as_merge_segment],-1
	mov	eax,[as_image_base]
	ret
      as_first_elf_segment_ok:
	and	[as_merge_segment],0
	inc	[as_number_of_sections]
      as_finish_elf_segment:
	mov	ebx,[as_number_of_sections]
	dec	ebx
	shl	ebx,5
	add	ebx,[as_code_start]
	add	ebx,34h
	mov	eax,edi
	sub	eax,[as_code_start]
	sub	eax,[ebx+4]
	mov	edx,edi
	cmp	edi,[as_undefined_data_end]
	if_not_equal	as_elf_segment_size_ok
	cmp	as_u8 [ebx],1
	if_not_equal	as_elf_segment_size_ok
	mov	edi,[as_undefined_data_start]
      as_elf_segment_size_ok:
	mov	[ebx+14h],eax
	add	eax,edi
	sub	eax,edx
	mov	[ebx+10h],eax
	and	[as_undefined_data_end],0
	mov	eax,[ebx+8]
	cmp	as_u8 [ebx],1
	if_equal	as_elf_segment_position_move_and_align
	cmp	[as_merge_segment],0
	if_not_equal	as_elf_segment_position_move
	cmp	as_u8 [ebx],4
	if_equal	as_elf_segment_position_ok
	cmp	as_u8 [ebx],51h
	if_equal	as_elf_segment_position_ok
	mov	[as_merge_segment],ebx
      as_elf_segment_position_move:
	add	eax,[ebx+14h]
	jmp	as_elf_segment_position_ok
      as_elf_segment_position_move_and_align:
	add	eax,[ebx+14h]
	add	eax,0FFFh
      as_elf_segment_position_ok:
	and	eax,not 0FFFh
	ret
      as_setup_elf_exe_labels_type:
	mov	eax,[as_code_start]
	cmp	as_u8 [eax+10h],3
	if_not_equal	as_elf_exe_labels_type_ok
	mov	as_u8 [ebx+9],2
      as_elf_exe_labels_type_ok:
	ret

as_close_elf_exe:
	call	as_close_elf_segment
	mov	edx,[as_code_start]
	mov	eax,[as_number_of_sections]
	mov	as_u8 [edx+1Ch],34h
	mov	[edx+2Ch],ax
	shl	eax,5
	add	eax,edx
	add	eax,34h
	cmp	eax,[as_symbols_stream]
	if_equal	as_elf_exe_ok
	or	[as_next_pass_needed],-1
      as_elf_exe_ok:
	ret
