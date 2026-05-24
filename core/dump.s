; SPDX-License-Identifier: BSD-2-Clause
; Copyright (c) 2026 danko1122q
; All rights reserved.

as_dump_symbols:
SYM_HDR_ID_LEN      = -40h+0Ch
SYM_HDR_SRC_SIZE    = -40h+14h
SYM_HDR_BLK_SIZE    = -40h+20h
SYM_HDR_SRC_OFFSET  = -40h+24h
SYM_HDR_SUBSECT_OFF = -40h+2Ch
SYM_HDR_SUBSECT_SZ  = -40h+30h
SYM_HDR_SUBSECT_TOT = -40h+38h

	mov	edi,[as_code_start]
	call	as_setup_dump_header
	mov	esi,[as_input_file]
	call	as_copy_asciiz
	cmp	edi,[as_tagged_blocks]
	if_above_equal	as_out_of_memory
	mov	eax,edi
	sub	eax,ebx
	mov	[ebx-40h+0Ch],eax
	mov	esi,[as_output_file]
	call	as_copy_asciiz
	cmp	edi,[as_tagged_blocks]
	if_above_equal	as_out_of_memory
	mov	edx,[as_symbols_stream]
	mov	ebp,[as_free_additional_memory]
	and	[as_number_of_sections],0
	cmp	[as_output_format],4
	if_equal	as_prepare_strings_table
	cmp	[as_output_format],5
	if_not_equal	as_strings_table_ready
	bit_test	[as_format_flags],0
	if_carry	as_strings_table_ready
      as_prepare_strings_table:
	cmp	edx,ebp
	if_equal	as_strings_table_ready
	mov	al,[edx]
	test	al,al
	if_zero	as_prepare_string
	cmp	al,80h
	if_equal	as_prepare_string
	add	edx,0Ch
	cmp	al,0C0h
	if_below	as_prepare_strings_table
	add	edx,4
	jmp	as_prepare_strings_table
      as_prepare_string:
	mov	esi,edi
	sub	esi,ebx
	xchg	esi,[edx+4]
	test	al,al
	if_zero	as_prepare_section_string
	or	as_u32 [edx+4],1 shl 31
	add	edx,0Ch
      as_prepare_external_string:
	mov	ecx,[esi]
	add	esi,4
	rep	movs as_u8 [edi],[esi]
	mov	as_u8 [edi],0
	inc	edi
	cmp	edi,[as_tagged_blocks]
	if_above_equal	as_out_of_memory
	jmp	as_prepare_strings_table
      as_prepare_section_string:
	mov	ecx,[as_number_of_sections]
	mov	eax,ecx
	inc	eax
	mov	[as_number_of_sections],eax
	xchg	eax,[edx+4]
	shl	ecx,2
	add	ecx,[as_free_additional_memory]
	mov	[ecx],eax
	add	edx,20h
	test	esi,esi
	if_zero	as_prepare_default_section_string
	cmp	[as_output_format],5
	if_not_equal	as_prepare_external_string
	bit_test	[as_format_flags],0
	if_carry	as_prepare_external_string
	mov	esi,[esi]
	add	esi,[as_resource_data]
      as_copy_elf_section_name:
	lods	as_u8 [esi]
	cmp	edi,[as_tagged_blocks]
	if_above_equal	as_out_of_memory
	stos	as_u8 [edi]
	test	al,al
	if_not_zero	as_copy_elf_section_name
	jmp	as_prepare_strings_table
      as_prepare_default_section_string:
	mov	eax,'.fla'
	stos	as_u32 [edi]
	mov	ax,'t'
	stos	as_u16 [edi]
	cmp	edi,[as_tagged_blocks]
	if_above_equal	as_out_of_memory
	jmp	as_prepare_strings_table
      as_strings_table_ready:
	mov	edx,[as_tagged_blocks]
	mov	ebp,[as_memory_end]
	sub	ebp,[as_labels_list]
	add	ebp,edx
      as_prepare_labels_dump:
	cmp	edx,ebp
	if_equal	as_labels_dump_ok
	mov	eax,[edx+24]
	test	eax,eax
	if_zero	as_label_dump_name_ok
	cmp	eax,[as_memory_start]
	if_below	as_label_name_outside_source
	cmp	eax,[as_source_start]
	if_above	as_label_name_outside_source
	sub	eax,[as_memory_start]
	dec	eax
	mov	[edx+24],eax
	jmp	as_label_dump_name_ok
      as_label_name_outside_source:
	mov	esi,eax
	mov	eax,edi
	sub	eax,ebx
	or	eax,1 shl 31
	mov	[edx+24],eax
	movzx	ecx,as_u8 [esi-1]
	lea	eax,[edi+ecx+1]
	cmp	edi,[as_tagged_blocks]
	if_above_equal	as_out_of_memory
	rep	movsb
	xor	al,al
	stosb
      as_label_dump_name_ok:
	mov	eax,[edx+28]
	test	eax,eax
	if_zero	as_label_dump_line_ok
	sub	eax,[as_memory_start]
	mov	[edx+28],eax
      as_label_dump_line_ok:
	test	as_u8 [edx+9],4
	if_zero	as_convert_base_symbol_for_label
	xor	eax,eax
	mov	[edx],eax
	mov	[edx+4],eax
	jmp	as_base_symbol_for_label_ok
      as_convert_base_symbol_for_label:
	mov	eax,[edx+20]
	test	eax,eax
	if_zero	as_base_symbol_for_label_ok
	cmp	eax,[as_symbols_stream]
	mov	eax,[eax+4]
	if_above_equal	as_base_symbol_for_label_ok
	xor	eax,eax
      as_base_symbol_for_label_ok:
	mov	[edx+20],eax
	mov	ax,[as_current_pass]
	cmp	ax,[edx+16]
	if_equal	as_label_defined_flag_ok
	and	as_u8 [edx+8],not 1
      as_label_defined_flag_ok:
	cmp	ax,[edx+18]
	if_equal	as_label_used_flag_ok
	and	as_u8 [edx+8],not 8
      as_label_used_flag_ok:
	add	edx,LABEL_STRUCTURE_SIZE
	jmp	as_prepare_labels_dump
      as_labels_dump_ok:
	mov	eax, edi
	sub	eax, ebx
	mov	[ebx+SYM_HDR_SRC_SIZE], eax
	add	eax, 40h
	mov	[ebx-40h+18h], eax
	mov	ecx,[as_memory_end]
	sub	ecx,[as_labels_list]
	mov	[ebx-40h+1Ch],ecx
	add	eax,ecx
	mov	[ebx-40h+20h],eax
	mov	ecx,[as_source_start]
	sub	ecx,[as_memory_start]
	mov	[ebx-40h+24h],ecx
	add	eax,ecx
	mov	[ebx-40h+28h],eax
	mov	eax,[as_number_of_sections]
	shl	eax,2
	mov	[ebx-40h+34h],eax
	call	as_prepare_preprocessed_source
	mov	esi,[as_labels_list]
	mov	ebp,edi
      as_make_lines_dump:
	cmp	esi,[as_tagged_blocks]
	if_equal	as_lines_dump_ok
	mov	eax,[esi-4]
	mov	ecx,[esi-8]
	sub	esi,8
	sub	esi,ecx
	cmp	eax,1
	if_equal	as_process_line_dump
	cmp	eax,2
	if_not_equal	as_make_lines_dump
	add	as_u32 [ebx-40h+3Ch],8
	jmp	as_make_lines_dump
      as_process_line_dump:
	push	ebx
	mov	ebx,[esi+8]
	mov	eax,[esi+4]
	sub	eax,[as_code_start]
	add	eax,[as_headers_size]
	test	as_u8 [ebx+0Ah],1
	if_zero	as_store_offset
	xor	eax,eax
      as_store_offset:
	stos	as_u32 [edi]
	mov	eax,[esi]
	sub	eax,[as_memory_start]
	stos	as_u32 [edi]
	mov	eax,[esi+4]
	xor	edx,edx
	xor	cl,cl
	sub	eax,[ebx]
	sub_with_borrow	edx,[ebx+4]
	sub_with_borrow	cl,[ebx+8]
	stos	as_u32 [edi]
	mov	eax,edx
	stos	as_u32 [edi]
	mov	eax,[ebx+10h]
	stos	as_u32 [edi]
	mov	eax,[ebx+14h]
	test	eax,eax
	if_zero	as_base_symbol_for_line_ok
	cmp	eax,[as_symbols_stream]
	mov	eax,[eax+4]
	if_above_equal	as_base_symbol_for_line_ok
	xor	eax,eax
      as_base_symbol_for_line_ok:
	stos	as_u32 [edi]
	mov	al,[ebx+9]
	stos	as_u8 [edi]
	mov	al,[esi+10h]
	stos	as_u8 [edi]
	mov	al,[ebx+0Ah]
	and	al,1
	stos	as_u8 [edi]
	mov	al,cl
	stos	as_u8 [edi]
	pop	ebx
	cmp	edi,[as_tagged_blocks]
	if_above_equal	as_out_of_memory
	mov	eax,edi
	sub	eax,1Ch
	sub	eax,ebp
	mov	[esi],eax
	jmp	as_make_lines_dump
      as_lines_dump_ok:
	mov	edx,edi
	mov	eax,[as_current_offset]
	sub	eax,[as_code_start]
	add	eax,[as_headers_size]
	stos	as_u32 [edi]
	mov	ecx,edi
	sub	ecx,ebx
	sub	ecx, [ebx+SYM_HDR_SRC_SIZE]
	mov	[ebx+SYM_HDR_SUBSECT_OFF], ecx
	add	ecx, [ebx-40h+28h]
	mov	[ebx+SYM_HDR_SUBSECT_SZ], ecx
	add	ecx, [ebx-40h+34h]
	mov	[ebx+SYM_HDR_SUBSECT_TOT], ecx
      as_find_inexisting_offsets:
	sub	edx,1Ch
	cmp	edx,ebp
	if_below	as_write_symbols
	test	as_u8 [edx+1Ah],1
	if_not_zero	as_find_inexisting_offsets
	cmp	eax,[edx]
	if_below	as_correct_inexisting_offset
	mov	eax,[edx]
	jmp	as_find_inexisting_offsets
      as_correct_inexisting_offset:
	and	as_u32 [edx],0
	or	as_u8 [edx+1Ah],2
	jmp	as_find_inexisting_offsets
      as_write_symbols:
	mov	edx,[as_symbols_file]
	call	as_create
	if_carry	as_write_failed
	mov	edx,[as_code_start]
	mov	ecx,[edx+14h]
	add	ecx,40h
	call	as_write
	if_carry	as_write_failed
	mov	edx,[as_tagged_blocks]
	mov	ecx,[as_memory_end]
	sub	ecx,[as_labels_list]
	call	as_write
	if_carry	as_write_failed
	mov	edx,[as_memory_start]
	mov	ecx,[as_source_start]
	sub	ecx,edx
	call	as_write
	if_carry	as_write_failed
	mov	edx,ebp
	mov	ecx,edi
	sub	ecx,edx
	call	as_write
	if_carry	as_write_failed
	mov	edx,[as_free_additional_memory]
	mov	ecx,[as_number_of_sections]
	shl	ecx,2
	call	as_write
	if_carry	as_write_failed
	mov	esi,[as_labels_list]
	mov	edi,[as_memory_start]
      as_make_references_dump:
	cmp	esi,[as_tagged_blocks]
	if_equal	as_references_dump_ok
	mov	eax,[esi-4]
	mov	ecx,[esi-8]
	sub	esi,8
	sub	esi,ecx
	cmp	eax,2
	if_equal	as_dump_reference
	cmp	eax,1
	if_not_equal	as_make_references_dump
	mov	edx,[esi]
	jmp	as_make_references_dump
      as_dump_reference:
	mov	eax,[as_memory_end]
	sub	eax,[esi]
	sub	eax,LABEL_STRUCTURE_SIZE
	stosd
	mov	eax,edx
	stosd
	cmp	edi,[as_tagged_blocks]
	if_below	as_make_references_dump
	jmp	as_out_of_memory
      as_references_dump_ok:
	mov	edx,[as_memory_start]
	mov	ecx,edi
	sub	ecx,edx
	call	as_write
	if_carry	as_write_failed
	call	as_close
	ret
      as_setup_dump_header:
	xor	eax,eax
	mov	ecx,40h shr 2
	rep	stos as_u32 [edi]
	mov	ebx,edi
	mov	as_u32 [ebx-40h],'fas'+1Ah shl 24
	mov	as_u32 [ebx-40h+4],VERSION_MAJOR + VERSION_MINOR shl 8 + 40h shl 16
	mov	as_u32 [ebx-40h+10h],40h
	ret
as_prepare_preprocessed_source:
	mov	esi,[as_memory_start]
	mov	ebp,[as_source_start]
	test	ebp,ebp
	if_not_zero	as_prepare_preprocessed_line
	mov	ebp,[as_current_line]
	inc	ebp
      as_prepare_preprocessed_line:
	cmp	esi,ebp
	if_above_equal	as_preprocessed_source_ok
	mov	eax,[as_memory_start]
	mov	edx,[as_input_file]
	cmp	[esi],edx
	if_not_equal	as_line_not_from_main_input
	mov	[esi],eax
      as_line_not_from_main_input:
	sub	[esi],eax
	test	as_u8 [esi+7],1 shl 7
	if_zero	as_prepare_next_preprocessed_line
	sub	[esi+8],eax
	sub	[esi+12],eax
      as_prepare_next_preprocessed_line:
	call	as_skip_preprocessed_line
	jmp	as_prepare_preprocessed_line
      as_preprocessed_source_ok:
	ret
      as_skip_preprocessed_line:
	add	esi,16
      as_skip_preprocessed_line_content:
	lods	as_u8 [esi]
	cmp	al,1Ah
	if_equal	as_skip_preprocessed_symbol
	cmp	al,3Bh
	if_equal	as_skip_preprocessed_symbol
	cmp	al,22h
	if_equal	as_skip_preprocessed_string
	or	al,al
	if_not_zero	as_skip_preprocessed_line_content
	ret
      as_skip_preprocessed_string:
	lods	as_u32 [esi]
	add	esi,eax
	jmp	as_skip_preprocessed_line_content
      as_skip_preprocessed_symbol:
	lods	as_u8 [esi]
	movzx	eax,al
	add	esi,eax
	jmp	as_skip_preprocessed_line_content
as_restore_preprocessed_source:
	mov	esi,[as_memory_start]
	mov	ebp,[as_source_start]
	test	ebp,ebp
	if_not_zero	as_restore_preprocessed_line
	mov	ebp,[as_current_line]
	inc	ebp
      as_restore_preprocessed_line:
	cmp	esi,ebp
	if_above_equal	as_preprocessed_source_restored
	mov	eax,[as_memory_start]
	add	[esi],eax
	cmp	[esi],eax
	if_not_equal	as_preprocessed_line_source_restored
	mov	edx,[as_input_file]
	mov	[esi],edx
      as_preprocessed_line_source_restored:
	test	as_u8 [esi+7],1 shl 7
	if_zero	as_restore_next_preprocessed_line
	add	[esi+8],eax
	add	[esi+12],eax
      as_restore_next_preprocessed_line:
	call	as_skip_preprocessed_line
	jmp	as_restore_preprocessed_line
      as_preprocessed_source_restored:
	ret
as_dump_preprocessed_source:
	mov	edi,[as_free_additional_memory]
	call	as_setup_dump_header
	mov	esi,[as_input_file]
	call	as_copy_asciiz
	cmp	edi,[as_additional_memory_end]
	if_above_equal	as_out_of_memory
	mov	eax,edi
	sub	eax,ebx
	dec	eax
	mov	[ebx+SYM_HDR_ID_LEN], eax
	mov	eax, edi
	sub	eax, ebx
	mov	[ebx+SYM_HDR_SRC_SIZE], eax
	add	eax, 40h
	mov	[ebx+SYM_HDR_BLK_SIZE], eax
	call	as_prepare_preprocessed_source
	sub	esi,[as_memory_start]
	mov	[ebx-40h+24h],esi
	mov	edx,[as_symbols_file]
	call	as_create
	if_carry	as_write_failed
	mov	edx,[as_free_additional_memory]
	mov	ecx,[edx+14h]
	add	ecx,40h
	call	as_write
	if_carry	as_write_failed
	mov	edx,[as_memory_start]
	mov	ecx,esi
	call	as_write
	if_carry	as_write_failed
	call	as_close
	ret
