; SPDX-License-Identifier: BSD-2-Clause
; Copyright (c) 2026 danko1122q
; All rights reserved.

as_out_of_memory:
	push	_as_out_of_memory
	jmp	as_fatal_error
as_stack_overflow:
	push	_as_stack_overflow
	jmp	as_fatal_error
as_main_file_not_found:
	push	_as_main_file_not_found
	jmp	as_fatal_error
as_write_failed:
	push	_as_write_failed
	jmp	as_fatal_error

as_code_cannot_be_generated:
	push	_as_code_cannot_be_generated
	jmp	as_general_error
as_format_limitations_exceeded:
	push	_as_format_limitations_exceeded
	jmp	as_general_error
as_invalid_definition:
	push	_as_invalid_definition
      as_general_error:
	cmp	[as_symbols_file],0
	if_equal	as_fatal_error
	call	as_dump_preprocessed_source
	jmp	as_fatal_error

as_file_not_found:
	push	_as_file_not_found
	jmp	as_error_with_source
as_error_reading_file:
	push	_as_error_reading_file
	jmp	as_error_with_source
as_invalid_file_format:
	push	_as_invalid_file_format
	jmp	as_error_with_source
as_invalid_macro_arguments:
	push	_as_invalid_macro_arguments
	jmp	as_error_with_source
as_incomplete_macro:
	push	_as_incomplete_macro
	jmp	as_error_with_source
as_unexpected_characters:
	push	_as_unexpected_characters
	jmp	as_error_with_source
as_invalid_argument:
	push	_as_invalid_argument
	jmp	as_error_with_source
as_illegal_instruction:
	push	_as_illegal_instruction
	jmp	as_error_with_source
as_invalid_operand:
	push	_as_invalid_operand
	jmp	as_error_with_source
as_invalid_operand_size:
	push	_as_invalid_operand_size
	jmp	as_error_with_source
as_operand_size_not_specified:
	push	_as_operand_size_not_specified
	jmp	as_error_with_source
as_operand_sizes_do_not_match:
	push	_as_operand_sizes_do_not_match
	jmp	as_error_with_source
as_invalid_address_size:
	push	_as_invalid_address_size
	jmp	as_error_with_source
as_address_sizes_do_not_agree:
	push	_as_address_sizes_do_not_agree
	jmp	as_error_with_source
as_disallowed_combination_of_registers:
	push	_as_disallowed_combination_of_registers
	jmp	as_error_with_source
as_long_immediate_not_encodable:
	push	_as_long_immediate_not_encodable
	jmp	as_error_with_source
as_relative_jump_out_of_range:
	push	_as_relative_jump_out_of_range
	jmp	as_error_with_source
as_invalid_expression:
	push	_as_invalid_expression
	jmp	as_error_with_source
as_invalid_address:
	push	_as_invalid_address
	jmp	as_error_with_source
as_invalid_value:
	push	_as_invalid_value
	jmp	as_error_with_source
as_value_out_of_range:
	push	_as_value_out_of_range
	jmp	as_error_with_source
as_undefined_symbol:
	mov	edi,as_message
	mov	esi,_as_undefined_symbol
	call	as_copy_asciiz
	push	as_message
	cmp	[as_error_info],0
	if_equal	as_error_with_source
	mov	esi,[as_error_info]
	mov	esi,[esi+24]
	or	esi,esi
	if_zero	as_error_with_source
	mov	as_u8 [edi-1],20h
	call	as_write_quoted_symbol_name
	jmp	as_error_with_source
      as_copy_asciiz:
	lods	as_u8 [esi]
	stos	as_u8 [edi]
	test	al,al
	if_not_zero	as_copy_asciiz
	ret
      as_write_quoted_symbol_name:
	mov	al,27h
	stosb
	movzx	ecx,as_u8 [esi-1]
	rep	movs as_u8 [edi],[esi]
	mov	ax,27h
	stosw
	ret
as_symbol_out_of_scope:
	mov	edi,as_message
	mov	esi,_as_symbol_out_of_scope_1
	call	as_copy_asciiz
	cmp	[as_error_info],0
	if_equal	as_finish_symbol_out_of_scope_message
	mov	esi,[as_error_info]
	mov	esi,[esi+24]
	or	esi,esi
	if_zero	as_finish_symbol_out_of_scope_message
	mov	as_u8 [edi-1],20h
	call	as_write_quoted_symbol_name
      as_finish_symbol_out_of_scope_message:
	mov	as_u8 [edi-1],20h
	mov	esi,_as_symbol_out_of_scope_2
	call	as_copy_asciiz
	push	as_message
	jmp	as_error_with_source
as_invalid_use_of_symbol:
	push	_as_invalid_use_of_symbol
	jmp	as_error_with_source
as_name_too_long:
	push	_as_name_too_long
	jmp	as_error_with_source
as_invalid_name:
	push	_as_invalid_name
	jmp	as_error_with_source
as_reserved_word_used_as_symbol:
	push	_as_reserved_word_used_as_symbol
	jmp	as_error_with_source
as_symbol_already_defined:
	push	_as_symbol_already_defined
	jmp	as_error_with_source
as_missing_end_quote:
	push	_as_missing_end_quote
	jmp	as_error_with_source
as_missing_end_directive:
	push	_as_missing_end_directive
	jmp	as_error_with_source
as_unexpected_instruction:
	push	_as_unexpected_instruction
	jmp	as_error_with_source
as_extra_characters_on_line:
	push	_as_extra_characters_on_line
	jmp	as_error_with_source
as_section_not_aligned_enough:
	push	_as_section_not_aligned_enough
	jmp	as_error_with_source
as_setting_already_specified:
	push	_as_setting_already_specified
	jmp	as_error_with_source
as_data_already_defined:
	push	_as_data_already_defined
	jmp	as_error_with_source
as_too_many_repeats:
	push	_as_too_many_repeats
	jmp	as_error_with_source
as_assertion_failed:
	push	_as_assertion_failed
	jmp	as_error_with_source
as_invoked_error:
	push	_as_invoked_error
      as_error_with_source:
	cmp	[as_symbols_file],0
	if_equal	as_assembler_error
	call	as_dump_preprocessed_source
	call	as_restore_preprocessed_source
	jmp	as_assembler_error
