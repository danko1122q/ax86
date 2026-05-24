; SPDX-License-Identifier: BSD-2-Clause
; Copyright (c) 2026 danko1122q
; All rights reserved.

O_ACCMODE  = 0003o
O_RDONLY   = 0000o
O_WRONLY   = 0001o
O_RDWR     = 0002o
O_CREAT    = 0100o
O_EXCL     = 0200o
O_NOCTTY   = 0400o
O_TRUNC    = 1000o
O_APPEND   = 2000o
O_NONBLOCK = 4000o

S_ISUID    = 4000o
S_ISGID    = 2000o
S_ISVTX    = 1000o
S_IRUSR    = 0400o
S_IWUSR    = 0200o
S_IXUSR    = 0100o
S_IRGRP    = 0040o
S_IWGRP    = 0020o
S_IXGRP    = 0010o
S_IROTH    = 0004o
S_IWOTH    = 0002o
S_IXOTH    = 0001o

TA_OUT_BUF_SIZE = 4000h

segment readable writeable
as_out_buf_pos	u32 ?
as_out_buf	rb TA_OUT_BUF_SIZE
segment readable executable

as_init_memory:
	mov	eax,esp
	and	eax,not 0FFFh
	add	eax,1000h-10000h
	mov	[as_stack_limit],eax
	xor	ebx,ebx
	mov	eax,45
	trap	0x80
	mov	[as_additional_memory],eax
	mov	ecx,[as_memory_setting]
	shl	ecx,10
	if_not_zero	as_allocate_memory
	mov	ecx,1000000h
      as_allocate_memory:
	mov	ebx,[as_additional_memory]
	add	ebx,ecx
	mov	eax,45
	trap	0x80
	cmp	eax,[as_additional_memory]
	if_equal	as_no_low_memory
	mov	[as_memory_end],eax
	sub	eax,[as_additional_memory]
	shr	eax,2
	add	eax,[as_additional_memory]
	mov	[as_additional_memory_end],eax
	mov	[as_memory_start],eax
	ret
      as_no_low_memory:
	push	_as_no_low_memory_str
	jmp	as_fatal_error
_as_no_low_memory_str u8 'failed to allocate memory within 32-bit addressing range',0

as_exit_program:
	push	eax
	call	as_flush_output
	pop	eax
	movzx	ebx,al
	mov	eax,1
	trap	0x80

as_get_environment_variable:
	mov	ecx,esi
	mov	ebx,[as_environment]
      as_next_variable:
	mov	esi,[ebx]
	test	esi,esi
	if_zero	as_no_environment_variable
	add	ebx,4
      as_compare_variable_names:
	mov	edx,ecx
      as_compare_character:
	lodsb
	mov	ah,[edx]
	inc	edx
	cmp	al,'='
	if_equal	as_end_of_variable_name
	or	ah,ah
	if_zero	as_next_variable
	sub	ah,al
	if_zero	as_compare_character
	cmp	ah,20h
	if_not_equal	as_next_variable
	cmp	al,41h
	if_below	as_next_variable
	cmp	al,5Ah
	if_below_equal	as_compare_character
	jmp	as_next_variable
      as_no_environment_variable:
	ret
      as_end_of_variable_name:
	or	ah,ah
	if_not_zero	as_next_variable
      as_copy_variable_value:
	lodsb
	cmp	edi,[as_memory_end]
	if_above_equal	as_out_of_memory
	stosb
	or	al,al
	if_not_zero	as_copy_variable_value
	dec	edi
	ret

as_open:
	push	esi edi ebp
	call	as_adapt_path
	mov	eax,5
	mov	ebx,as_buffer
	mov	ecx,O_RDONLY
	xor	edx,edx
	trap	0x80
	pop	ebp edi esi
	test	eax,eax
	if_sign	as_file_error
	mov	ebx,eax
	clear_carry
	ret
      as_adapt_path:
	mov	esi,edx
	mov	edi,as_buffer
      as_copy_path:
	lods	as_u8 [esi]
	cmp	al,'\'
	if_not_equal	as_path_char_ok
	mov	al,'/'
      as_path_char_ok:
	stos	as_u8 [edi]
	or	al,al
	if_not_zero	as_copy_path
	cmp	edi,as_buffer+1000h
	if_above	as_out_of_memory
	ret

as_create:
	push	esi edi ebp edx
	call	as_adapt_path
	mov	ebx,as_buffer
	mov	ecx,O_CREAT+O_TRUNC+O_WRONLY
	mov	edx,S_IRUSR+S_IWUSR+S_IRGRP+S_IROTH
	pop	eax
	cmp	eax,[as_output_file]
	if_not_equal	as_do_create
	cmp	[as_output_format],5
	if_not_equal	as_do_create
	bit_test	[as_format_flags],0
	if_not_carry	as_do_create
	or	edx,S_IXUSR+S_IXGRP+S_IXOTH
      as_do_create:
	mov	eax,5
	trap	0x80
	pop	ebp edi esi
	test	eax,eax
	if_sign	as_file_error
	mov	ebx,eax
	clear_carry
	ret

as_close:
	mov	eax,6
	trap	0x80
	ret

as_read:
	push	ecx edx esi edi ebp
	mov	eax,3
	xchg	ecx,edx
	trap	0x80
	pop	ebp edi esi edx ecx
	test	eax,eax
	if_sign	as_file_error
	cmp	eax,ecx
	if_not_equal	as_file_error
	clear_carry
	ret
      as_file_error:
	set_carry
	ret

as_write:
	push	edx esi edi ebp ecx
	mov	eax,4
	xchg	ecx,edx
	trap	0x80
	pop	ecx
	pop	ebp edi esi edx
	test	eax,eax
	if_sign	as_file_error
	cmp	eax,ecx
	if_not_equal	as_file_error
	clear_carry
	ret

as_lseek:
	mov	ecx,edx
	xor	edx,edx
	mov	dl,al
	mov	eax,19
	trap	0x80
	cmp	eax,-1
	if_equal	as_file_error
	clear_carry
	ret

as_display_string:
	push	esi edi
      as_ds_loop:
	mov	al,[esi]
	or	al,al
	if_zero	as_ds_done
	call	as_buf_putc
	inc	esi
	jmp	as_ds_loop
      as_ds_done:
	pop	edi esi
	ret

as_display_character:
	push	esi edi
	mov	al,dl
	call	as_buf_putc
	pop	edi esi
	ret

as_display_number:
	push	ebx
	mov	ecx,1000000000
	xor	edx,edx
	xor	bl,bl
      as_display_loop:
	div	ecx
	push	edx
	cmp	ecx,1
	if_equal	as_display_digit
	or	bl,bl
	if_not_zero	as_display_digit
	or	al,al
	if_zero	as_digit_ok
	not	bl
      as_display_digit:
	add	al,30h
	push	ebx ecx
	call	as_buf_putc
	pop	ecx ebx
      as_digit_ok:
	mov	eax,ecx
	xor	edx,edx
	mov	ecx,10
	div	ecx
	mov	ecx,eax
	pop	eax
	or	ecx,ecx
	if_not_zero	as_display_loop
	pop	ebx
	ret

as_buf_putc:
	push	edx
	mov	edx,[as_out_buf_pos]
	mov	[as_out_buf+edx],al
	inc	edx
	mov	[as_out_buf_pos],edx
	cmp	edx,TA_OUT_BUF_SIZE
	if_below	as_buf_putc_done
	call	as_flush_output
      as_buf_putc_done:
	pop	edx
	ret

as_flush_output:
	mov	ecx,[as_out_buf_pos]
	jecxz	as_flush_done
	push	ebx
	mov	eax,4
	mov	ebx,[as_con_handle]
	mov	edx,as_out_buf
	xchg	ecx,edx
	trap	0x80
	pop	ebx
	mov	as_u32 [as_out_buf_pos],0
      as_flush_done:
	ret

as_display_user_messages:
	mov	[as_displayed_count],0
	call	as_show_display_buffer
	cmp	[as_displayed_count],0
	if_equal	as_line_break_ok
	cmp	[as_last_displayed],0Ah
	if_equal	as_line_break_ok
	mov	dl,0Ah
	call	as_display_character
      as_line_break_ok:
	call	as_flush_output
	ret

as_display_block:
	jecxz	as_block_displayed
	add	[as_displayed_count],ecx
	mov	al,[esi+ecx-1]
	mov	[as_last_displayed],al
	push	esi edi ecx
      as_display_block_loop:
	mov	al,[esi]
	call	as_buf_putc
	inc	esi
	loop	as_display_block_loop
	pop	ecx edi esi
      as_block_displayed:
	ret

as_fatal_error:
	call	as_flush_output
	mov	[as_con_handle],2
	mov	esi,as_error_prefix
	call	as_display_string
	pop	esi
	call	as_display_string
	mov	esi,as_error_suffix
	call	as_display_string
	call	as_flush_output
	mov	al,0FFh
	jmp	as_exit_program

as_assembler_error:
	call	as_flush_output
	mov	[as_con_handle],2
	call	as_display_user_messages
	mov	ebx,[as_current_line]
	test	ebx,ebx
	if_zero	as_display_error_message
	push	as_u32 0
      as_get_error_lines:
	mov	eax,[ebx]
	cmp	as_u8 [eax],0
	if_equal	as_get_next_error_line
	push	ebx
	test	as_u8 [ebx+7],80h
	if_zero	as_display_error_line
	mov	edx,ebx
      as_find_definition_origin:
	mov	edx,[edx+12]
	test	as_u8 [edx+7],80h
	if_not_zero	as_find_definition_origin
	push	edx
      as_get_next_error_line:
	mov	ebx,[ebx+8]
	jmp	as_get_error_lines
      as_display_error_line:
	mov	esi,[ebx]
	call	as_display_string
	mov	esi,as_line_number_start
	call	as_display_string
	mov	eax,[ebx+4]
	and	eax,7FFFFFFFh
	call	as_display_number
	mov	dl,']'
	call	as_display_character
	pop	esi
	cmp	ebx,esi
	if_equal	as_line_number_ok
	mov	dl,20h
	call	as_display_character
	push	esi
	mov	esi,[esi]
	movzx	ecx,as_u8 [esi]
	inc	esi
	call	as_display_block
	mov	esi,as_line_number_start
	call	as_display_string
	pop	esi
	mov	eax,[esi+4]
	and	eax,7FFFFFFFh
	call	as_display_number
	mov	dl,']'
	call	as_display_character
      as_line_number_ok:
	mov	esi,as_line_data_start
	call	as_display_string
	mov	esi,ebx
	mov	edx,[esi]
	call	as_open
	mov	al,2
	xor	edx,edx
	call	as_lseek
	mov	edx,[esi+8]
	sub	eax,edx
	if_zero	as_line_data_displayed
	push	eax
	xor	al,al
	call	as_lseek
	mov	ecx,[esp]
	mov	edx,[as_additional_memory]
	lea	eax,[edx+ecx]
	cmp	eax,[as_additional_memory_end]
	if_above	as_out_of_memory
	call	as_read
	call	as_close
	pop	ecx
	mov	esi,[as_additional_memory]
      as_get_line_data:
	mov	al,[esi]
	cmp	al,0Ah
	if_equal	as_display_line_data
	cmp	al,0Dh
	if_equal	as_display_line_data
	cmp	al,1Ah
	if_equal	as_display_line_data
	or	al,al
	if_zero	as_display_line_data
	inc	esi
	loop	as_get_line_data
      as_display_line_data:
	mov	ecx,esi
	mov	esi,[as_additional_memory]
	sub	ecx,esi
	call	as_display_block
      as_line_data_displayed:
	mov	esi,as_lf
	call	as_display_string
	pop	ebx
	or	ebx,ebx
	if_not_zero	as_display_error_line
	cmp	[as_preprocessing_done],0
	if_equal	as_display_error_message
	mov	esi,as_preprocessed_instruction_prefix
	call	as_display_string
	mov	esi,[as_current_line]
	add	esi,16
	mov	edi,[as_additional_memory]
	xor	dl,dl
      as_convert_instruction:
	lodsb
	cmp	al,1Ah
	if_equal	as_copy_symbol
	cmp	al,22h
	if_equal	as_copy_symbol
	cmp	al,3Bh
	if_equal	as_instruction_converted
	stosb
	or	al,al
	if_zero	as_instruction_converted
	xor	dl,dl
	jmp	as_convert_instruction
      as_copy_symbol:
	or	dl,dl
	if_zero	as_space_ok
	mov	as_u8 [edi],20h
	inc	edi
      as_space_ok:
	cmp	al,22h
	if_equal	as_quoted
	lodsb
	movzx	ecx,al
	rep	movsb
	or	dl,-1
	jmp	as_convert_instruction
      as_quoted:
	mov	al,27h
	stosb
	lodsd
	mov	ecx,eax
	jecxz	as_quoted_copied
      as_copy_quoted:
	lodsb
	stosb
	cmp	al,27h
	if_not_equal	as_quote_ok
	stosb
      as_quote_ok:
	loop	as_copy_quoted
      as_quoted_copied:
	mov	al,27h
	stosb
	or	dl,-1
	jmp	as_convert_instruction
      as_instruction_converted:
	xor	al,al
	stosb
	mov	esi,[as_additional_memory]
	call	as_display_string
	mov	esi,as_lf
	call	as_display_string
      as_display_error_message:
	mov	esi,as_error_prefix
	call	as_display_string
	pop	esi
	call	as_display_string
	mov	esi,as_error_suffix
	call	as_display_string
	mov	al,2
	jmp	as_exit_program

as_make_timestamp:
	push	ebx
	mov	eax,13
	mov	ebx,as_timestamp
	trap	0x80
	mov	eax,as_u32 [as_timestamp]
	xor	edx,edx
	pop	ebx
	ret

as_error_prefix u8 'error: ',0
as_error_suffix u8 '.'
as_lf u8 0xA,0
as_line_number_start u8 ' [',0
as_line_data_start u8 ':',0xA,0
as_preprocessed_instruction_prefix u8 'processed: ',0
