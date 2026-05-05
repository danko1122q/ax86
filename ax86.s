; SPDX-License-Identifier: BSD-2-Clause
; Copyright (c) 2026 danko1122q
; All rights reserved.

; AX86 — Assembly x86
; Build (Linux):   ./ax86 ax86.s ax86   && chmod +x ax86

	format	ELF executable 3
	entry	as_start

	include 'core/platform32.s'

segment readable executable

as_start:

	mov	[as_con_handle],1
	mov	esi,_as_logo
	call	as_display_string

	; 32-bit Linux argv layout: [esp] = argc, [esp+4] = argv[0], ...
	mov	[as_command_line],esp
	mov	ecx,[esp]
	lea	ebx,[esp+4+ecx*4+4]
	mov	[as_environment],ebx
	call	as_get_params
	if_carry	as_information

	call	as_init_memory

	mov	esi,_as_memory_prefix
	call	as_display_string
	mov	eax,[as_memory_end]
	sub	eax,[as_memory_start]
	add	eax,[as_additional_memory_end]
	sub	eax,[as_additional_memory]
	shr	eax,10
	call	as_display_number
	mov	esi,_as_memory_suffix
	call	as_display_string

	; timing start
	; gettimeofday (sys 78) -> buffer: [seconds dd, useconds dd]
	mov	eax,78
	mov	ebx,as_buffer
	xor	ecx,ecx
	trap	0x80
	mov	eax,as_u32 [as_buffer]
	mov	ecx,1000
	mul	ecx
	mov	ebx,eax
	mov	eax,as_u32 [as_buffer+4]
	mov	ecx,1000
	div	ecx
	add	eax,ebx
	mov	[as_start_time],eax

	and	[as_preprocessing_done],0
	call	as_preprocessor
	or	[as_preprocessing_done],-1
	call	as_parser
	call	as_assembler
	call	as_formatter

	call	as_display_user_messages
	movzx	eax,[as_current_pass]
	inc	eax
	call	as_display_number
	mov	esi,_as_passes_suffix
	call	as_display_string
	mov	eax,78
	mov	ebx,as_buffer
	xor	ecx,ecx
	trap	0x80
	mov	eax,as_u32 [as_buffer]
	mov	ecx,1000
	mul	ecx
	mov	ebx,eax
	mov	eax,as_u32 [as_buffer+4]
	mov	ecx,1000
	div	ecx
	add	eax,ebx
	sub	eax,[as_start_time]
	if_not_carry	as_time_ok
	add	eax,3600000
      as_time_ok:
	call	as_display_number
	mov	esi,_as_seconds_suffix
	call	as_display_string
      as_display_bytes_count:
	mov	eax,[as_written_size]
	call	as_display_number
	mov	esi,_as_bytes_suffix
	call	as_display_string
	xor	al,al
	jmp	as_exit_program

as_information:
	mov	esi,_as_usage
	call	as_display_string
	mov	al,1
	jmp	as_exit_program

as_get_params:
	mov	ebx,[as_command_line]
	mov	[as_input_file],0
	mov	[as_output_file],0
	mov	[as_symbols_file],0
	mov	[as_memory_setting],0
	mov	[as_passes_limit],100
	mov	ecx,[ebx]
	add	ebx,8
	dec	ecx
	if_zero	as_bad_params
	mov	[as_definitions_pointer],as_predefinitions
	mov	[as_path_pointer],as_paths
	mov	[as_include_extra_ptr],as_include_extra
	mov	as_u8 [as_include_extra],0
      as_get_param:
	mov	esi,[ebx]
	mov	al,[esi]
	cmp	al,'-'
	if_equal	as_option_param
	cmp	[as_input_file],0
	if_not_equal	as_get_output_file
	call	as_collect_path
	mov	[as_input_file],edx
	jmp	as_next_param
      as_get_output_file:
	cmp	[as_output_file],0
	if_not_equal	as_bad_params
	call	as_collect_path
	mov	[as_output_file],edx
	jmp	as_next_param
      as_option_param:
	inc	esi
	lodsb
	cmp	al,'m'
	if_equal	as_memory_option
	cmp	al,'M'
	if_equal	as_memory_option
	cmp	al,'p'
	if_equal	as_passes_option
	cmp	al,'P'
	if_equal	as_passes_option
	cmp	al,'d'
	if_equal	as_definition_option
	cmp	al,'D'
	if_equal	as_definition_option
	cmp	al,'s'
	if_equal	as_symbols_option
	cmp	al,'S'
	if_equal	as_symbols_option
	cmp	al,'i'
	if_equal	as_include_option
	cmp	al,'I'
	if_equal	as_include_option
      as_bad_params:
	set_carry
	ret
      as_memory_option:
	cmp	as_u8 [esi],0
	if_not_equal	as_get_memory_setting
	dec	ecx
	if_zero	as_bad_params
	add	ebx,4
	mov	esi,[ebx]
      as_get_memory_setting:
	call	as_get_option_value
	or	edx,edx
	if_zero	as_bad_params
	cmp	edx,1 shl (32-10)
	if_above_equal	as_bad_params
	mov	[as_memory_setting],edx
	jmp	as_next_param
      as_passes_option:
	cmp	as_u8 [esi],0
	if_not_equal	as_get_passes_setting
	dec	ecx
	if_zero	as_bad_params
	add	ebx,4
	mov	esi,[ebx]
      as_get_passes_setting:
	call	as_get_option_value
	or	edx,edx
	if_zero	as_bad_params
	cmp	edx,10000h
	if_above	as_bad_params
	mov	[as_passes_limit],dx
      as_next_param:
	add	ebx,4
	dec	ecx
	if_not_zero	as_get_param
	cmp	[as_input_file],0
	if_equal	as_bad_params
	mov	eax,[as_definitions_pointer]
	mov	as_u8 [eax],0
	mov	[as_initial_definitions],as_predefinitions
	clear_carry
	ret
      as_definition_option:
	cmp	as_u8 [esi],0
	if_not_equal	as_get_definition
	dec	ecx
	if_zero	as_bad_params
	add	ebx,4
	mov	esi,[ebx]
      as_get_definition:
	push	edi
	mov	edi,[as_definitions_pointer]
	call	as_convert_definition_option
	mov	[as_definitions_pointer],edi
	pop	edi
	if_carry	as_bad_params
	jmp	as_next_param
      as_symbols_option:
	cmp	as_u8 [esi],0
	if_not_equal	as_get_symbols_setting
	dec	ecx
	if_zero	as_bad_params
	add	ebx,4
	mov	esi,[ebx]
      as_get_symbols_setting:
	call	as_collect_path
	mov	[as_symbols_file],edx
	jmp	as_next_param
      as_include_option:
	cmp	as_u8 [esi],0
	if_not_equal	as_get_include_setting
	dec	ecx
	if_zero	as_bad_params
	add	ebx,4
	mov	esi,[ebx]
      as_get_include_setting:
	mov	edi,[as_include_extra_ptr]
	cmp	edi,as_include_extra+4000h
	if_above_equal	as_bad_params
      as_copy_include_path:
	lodsb
	or	al,al
	if_zero	as_include_path_done
	stosb
	cmp	edi,as_include_extra+4000h
	if_below	as_copy_include_path
	jmp	as_bad_params
      as_include_path_done:
	mov	al,';'
	stosb
	mov	[as_include_extra_ptr],edi
	jmp	as_next_param
      as_get_option_value:
	xor	eax,eax
	mov	edx,eax
      as_get_option_digit:
	lodsb
	cmp	al,20h
	if_equal	as_option_value_ok
	or	al,al
	if_zero	as_option_value_ok
	sub	al,30h
	if_carry	as_invalid_option_value
	cmp	al,9
	if_above	as_invalid_option_value
	signed_multiply	edx,10
	if_overflow	as_invalid_option_value
	add	edx,eax
	if_carry	as_invalid_option_value
	jmp	as_get_option_digit
      as_option_value_ok:
	dec	esi
	clear_carry
	ret
      as_invalid_option_value:
	set_carry
	ret
      as_convert_definition_option:
	mov	edx,edi
	cmp	edi,as_predefinitions+1000h
	if_above_equal	as_bad_definition_option
	xor	al,al
	stosb
      as_copy_definition_name:
	lodsb
	cmp	al,'='
	if_equal	as_copy_definition_value
	cmp	al,20h
	if_equal	as_bad_definition_option
	or	al,al
	if_zero	as_bad_definition_option
	cmp	edi,as_predefinitions+1000h
	if_above_equal	as_bad_definition_option
	stosb
	inc	as_u8 [edx]
	if_not_zero	as_copy_definition_name
      as_bad_definition_option:
	set_carry
	ret
      as_copy_definition_value:
	lodsb
	cmp	al,20h
	if_equal	as_definition_value_end
	or	al,al
	if_zero	as_definition_value_end
	cmp	edi,as_predefinitions+1000h
	if_above_equal	as_bad_definition_option
	stosb
	jmp	as_copy_definition_value
      as_definition_value_end:
	dec	esi
	cmp	edi,as_predefinitions+1000h
	if_above_equal	as_bad_definition_option
	xor	al,al
	stosb
	clear_carry
	ret
as_collect_path:
	mov	edi,[as_path_pointer]
	mov	edx,edi
      as_copy_path_to_low_memory:
	lodsb
	stosb
	test	al,al
	if_not_zero	as_copy_path_to_low_memory
	mov	[as_path_pointer],edi
	retn

include 'core/linux32.s'

include 'core/version.s'

_as_copyright u8 'asm project',0xA,0

_as_logo u8 'AX86 (Assembly x86) version ',VERSION_STRING,' (32-bit only)',0
_as_usage u8 0xA
	u8 'usage: ax86 <source> [output]',0xA
	u8 'optional settings:',0xA
	u8 ' -m <limit>         set the limit in kilobytes for the available memory',0xA
	u8 ' -p <limit>         set the maximum allowed number of passes',0xA
	u8 ' -d <n>=<value>  define symbolic variable',0xA
	u8 ' -s <file>          dump symbolic information for debugging',0xA
	u8 ' -i <path>          add directory to include search path',0xA
	u8 0
_as_memory_prefix u8 '  (',0
_as_memory_suffix u8 ' kilobytes memory, x86-32 only)',0xA,0
_as_passes_suffix u8 ' passes, ',0
_as_seconds_suffix u8 ' ms, ',0
_as_bytes_suffix u8 ' bytes.',0xA,0

include 'core/fault.s'
include 'core/dump.s'
include 'core/expand.s'
include 'core/scan.s'
include 'core/tokens.s'
include 'core/emit.s'
include 'core/calc.s'
include 'arch/x86.s'
include 'arch/vec.s'
include 'core/output_fmt.s'

include 'core/structs.s'
include 'core/msgdata.s'

segment readable writeable

align 4

include 'core/state.s'

as_command_line u32 ?
as_memory_setting u32 ?
as_path_pointer u32 ?
as_definitions_pointer u32 ?
as_environment u32 ?
as_timestamp u64 ?
as_start_time u32 ?
as_con_handle u32 ?
as_displayed_count u32 ?
as_last_displayed u8 ?
as_character u8 ?
as_preprocessing_done u8 ?

as_buffer rb 1000h
as_predefinitions rb 1000h
as_paths rb 10000h
as_include_extra rb 4000h
as_include_extra_ptr u32 ?

