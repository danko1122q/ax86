; SPDX-License-Identifier: BSD-2-Clause
; Copyright (c) 2026 danko1122q
; All rights reserved.

as_parser:
        mov     eax,[as_memory_end]
        mov     [as_labels_list],eax
        mov     eax,[as_additional_memory]
        mov     [as_free_additional_memory],eax
        xor     eax,eax
        mov     [as_current_locals_prefix],eax
        mov     [as_anonymous_reverse],eax
        mov     [as_anonymous_forward],eax
        mov     [as_hash_tree],eax
        mov     [as_blocks_stack],eax
        mov     [as_parsed_lines],eax
        mov     esi,[as_memory_start]
        mov     edi,[as_source_start]
      as_parser_loop:
        mov     [as_current_line],esi
        lea     eax,[edi+100h]
        cmp     eax,[as_labels_list]
        if_above_equal  as_out_of_memory
        cmp     as_u8 [esi+16],0
        if_equal        as_empty_line
        cmp     as_u8 [esi+16],3Bh
        if_equal        as_empty_line
        mov     al,0Fh
        stos    as_u8 [edi]
        mov     eax,esi
        stos    as_u32 [edi]
        inc     [as_parsed_lines]
        add     esi,16
      as_parse_line:
        mov     [as_formatter_symbols_allowed],0
        mov     [as_decorator_symbols_allowed],0
        cmp     as_u8 [esi],1Ah
        if_not_equal    as_empty_instruction
        push    edi
        add     esi,2
        movzx   ecx,as_u8 [esi-1]
        cmp     as_u8 [esi+ecx],':'
        if_equal        as_simple_label
        cmp     as_u8 [esi+ecx],'='
        if_equal        as_constant_label
        call    as_get_instruction
        if_not_carry    as_main_instruction_identified
        cmp     as_u8 [esi+ecx],1Ah
        if_not_equal    as_no_data_label
        push    esi ecx
        lea     esi,[esi+ecx+2]
        movzx   ecx,as_u8 [esi-1]
        call    as_get_data_directive
        if_not_carry    as_data_label
        pop     ecx esi
      as_no_data_label:
        call    as_get_data_directive
        if_not_carry    as_main_instruction_identified
        pop     edi
        sub     esi,2
        xor     bx,bx
        call    as_parse_line_contents
        jmp     as_parse_next_line
      as_simple_label:
        pop     edi
        call    as_identify_label
        cmp     as_u8 [esi+1],':'
        if_equal        as_block_label
        mov     as_u8 [edi],2
        inc     edi
        stos    as_u32 [edi]
        inc     esi
        xor     al,al
        stos    as_u8 [edi]
        jmp     as_parse_line
      as_block_label:
        mov     as_u8 [edi],4
        inc     edi
        stos    as_u32 [edi]
        add     esi,2
        jmp     as_parse_line
      as_constant_label:
        pop     edi
        call    as_get_label_id
        mov     as_u8 [edi],3
        inc     edi
        stos    as_u32 [edi]
        xor     al,al
        stos    as_u8 [edi]
        inc     esi
        xor     bx,bx
        call    as_parse_line_contents
        jmp     as_parse_next_line
      as_data_label:
        pop     ecx edx
        pop     edi
        push    eax ebx esi
        mov     esi,edx
        movzx   ecx,as_u8 [esi-1]
        call    as_identify_label
        mov     as_u8 [edi],2
        inc     edi
        stos    as_u32 [edi]
        pop     esi ebx eax
        stos    as_u8 [edi]
        push    edi
      as_main_instruction_identified:
        pop     edi
        mov     dl,al
        mov     al,1
        stos    as_u8 [edi]
        mov     ax,bx
        stos    as_u16 [edi]
        mov     al,dl
        stos    as_u8 [edi]
        cmp     bx,as_if_directive-as_instruction_handler
        if_equal        as_parse_block
        cmp     bx,as_repeat_directive-as_instruction_handler
        if_equal        as_parse_block
        cmp     bx,as_while_directive-as_instruction_handler
        if_equal        as_parse_block
        cmp     bx,as_end_directive-as_instruction_handler
        if_equal        as_parse_end_directive
        cmp     bx,as_else_directive-as_instruction_handler
        if_equal        as_parse_else
        cmp     bx,as_assert_directive-as_instruction_handler
        if_equal        as_parse_assert
      as_common_parse:
        call    as_parse_line_contents
        jmp     as_parse_next_line
      as_empty_instruction:
        lods    as_u8 [esi]
        or      al,al
        if_zero as_parse_next_line
        cmp     al,':'
        if_equal        as_invalid_name
        dec     esi
        mov     [as_parenthesis_stack],0
        call    as_parse_argument
        jmp     as_parse_next_line
      as_empty_line:
        add     esi,16
      as_skip_rest_of_line:
        call    as_skip_foreign_line
      as_parse_next_line:
        cmp     esi,[as_source_start]
        if_below        as_parser_loop
      as_source_parsed:
        cmp     [as_blocks_stack],0
        if_equal        as_blocks_stack_ok
        pop     eax
        pop     [as_current_line]
        jmp     as_missing_end_directive
      as_blocks_stack_ok:
        xor     al,al
        stos    as_u8 [edi]
        add     edi,0Fh
        and     edi,not 0Fh
        mov     [as_code_start],edi
        ret
      as_parse_block:
        mov     eax,esp
        sub     eax,[as_stack_limit]
        cmp     eax,100h
        if_below        as_stack_overflow
        push    [as_current_line]
        mov     ax,bx
        shl     eax,16
        push    eax
        inc     [as_blocks_stack]
        cmp     bx,as_if_directive-as_instruction_handler
        if_equal        as_parse_if
        cmp     bx,as_while_directive-as_instruction_handler
        if_equal        as_parse_while
        call    as_parse_line_contents
        jmp     as_parse_next_line
      as_parse_end_directive:
        cmp     as_u8 [esi],1Ah
        if_not_equal    as_common_parse
        push    edi
        inc     esi
        movzx   ecx,as_u8 [esi]
        inc     esi
        call    as_get_instruction
        pop     edi
        if_not_carry    as_parse_end_block
        sub     esi,2
        jmp     as_common_parse
      as_parse_end_block:
        mov     dl,al
        mov     al,1
        stos    as_u8 [edi]
        mov     ax,bx
        stos    as_u16 [edi]
        mov     al,dl
        stos    as_u8 [edi]
        lods    as_u8 [esi]
        or      al,al
        if_not_zero     as_extra_characters_on_line
        cmp     bx,as_if_directive-as_instruction_handler
        if_equal        as_close_parsing_block
        cmp     bx,as_repeat_directive-as_instruction_handler
        if_equal        as_close_parsing_block
        cmp     bx,as_while_directive-as_instruction_handler
        if_equal        as_close_parsing_block
        jmp     as_parse_next_line
      as_close_parsing_block:
        cmp     [as_blocks_stack],0
        if_equal        as_unexpected_instruction
        cmp     bx,[esp+2]
        if_not_equal    as_unexpected_instruction
        dec     [as_blocks_stack]
        pop     eax edx
        cmp     bx,as_if_directive-as_instruction_handler
        if_not_equal    as_parse_next_line
        test    al,1100b
        if_zero as_parse_next_line
        test    al,10000b
        if_not_zero     as_parse_next_line
        sub     edi,8
        jmp     as_parse_next_line
      as_parse_if:
        push    edi
        call    as_parse_line_contents
        xor     al,al
        stos    as_u8 [edi]
        xchg    esi,[esp]
        mov     edi,esi
        call    as_preevaluate_logical_expression
        pop     esi
        cmp     al,'0'
        if_equal        as_parse_false_condition_block
        cmp     al,'1'
        if_equal        as_parse_true_condition_block
        or      as_u8 [esp],10000b
        jmp     as_parse_next_line
      as_parse_while:
        push    edi
        call    as_parse_line_contents
        xor     al,al
        stos    as_u8 [edi]
        xchg    esi,[esp]
        mov     edi,esi
        call    as_preevaluate_logical_expression
        pop     esi
        cmp     al,'0'
        if_equal        as_parse_false_condition_block
        cmp     al,'1'
        if_not_equal    as_parse_next_line
        stos    as_u8 [edi]
        jmp     as_parse_next_line
      as_parse_false_condition_block:
        or      as_u8 [esp],1
        sub     edi,4
        jmp     as_skip_parsing
      as_parse_true_condition_block:
        or      as_u8 [esp],100b
        sub     edi,4
        jmp     as_parse_next_line
      as_parse_else:
        cmp     [as_blocks_stack],0
        if_equal        as_unexpected_instruction
        cmp     as_u16 [esp+2],as_if_directive-as_instruction_handler
        if_not_equal    as_unexpected_instruction
        lods    as_u8 [esi]
        or      al,al
        if_zero as_parse_pure_else
        cmp     al,1Ah
        if_not_equal    as_extra_characters_on_line
        push    edi
        movzx   ecx,as_u8 [esi]
        inc     esi
        call    as_get_instruction
        if_carry        as_extra_characters_on_line
        pop     edi
        cmp     bx,as_if_directive-as_instruction_handler
        if_not_equal    as_extra_characters_on_line
        test    as_u8 [esp],100b
        if_not_zero     as_skip_true_condition_else
        mov     dl,al
        mov     al,1
        stos    as_u8 [edi]
        mov     ax,bx
        stos    as_u16 [edi]
        mov     al,dl
        stos    as_u8 [edi]
        jmp     as_parse_if
      as_parse_assert:
        push    edi
        call    as_parse_line_contents
        xor     al,al
        stos    as_u8 [edi]
        xchg    esi,[esp]
        mov     edi,esi
        call    as_preevaluate_logical_expression
        pop     esi
        or      al,al
        if_zero as_parse_next_line
        stos    as_u8 [edi]
        jmp     as_parse_next_line
      as_skip_true_condition_else:
        sub     edi,4
        or      as_u8 [esp],1
        jmp     as_skip_parsing_contents
      as_parse_pure_else:
        bit_test_set    as_u32 [esp],1
        if_carry        as_unexpected_instruction
        test    as_u8 [esp],100b
        if_zero as_parse_next_line
        sub     edi,4
        or      as_u8 [esp],1
        jmp     as_skip_parsing
      as_skip_parsing:
        cmp     esi,[as_source_start]
        if_above_equal  as_source_parsed
        mov     [as_current_line],esi
        add     esi,16
      as_skip_parsing_line:
        cmp     as_u8 [esi],1Ah
        if_not_equal    as_skip_parsing_contents
        inc     esi
        movzx   ecx,as_u8 [esi]
        inc     esi
        cmp     as_u8 [esi+ecx],':'
        if_equal        as_skip_parsing_label
        push    edi
        call    as_get_instruction
        pop     edi
        if_not_carry    as_skip_parsing_instruction
        add     esi,ecx
        jmp     as_skip_parsing_contents
      as_skip_parsing_label:
        lea     esi,[esi+ecx+1]
        jmp     as_skip_parsing_line
      as_skip_parsing_instruction:
        cmp     bx,as_if_directive-as_instruction_handler
        if_equal        as_skip_parsing_block
        cmp     bx,as_repeat_directive-as_instruction_handler
        if_equal        as_skip_parsing_block
        cmp     bx,as_while_directive-as_instruction_handler
        if_equal        as_skip_parsing_block
        cmp     bx,as_end_directive-as_instruction_handler
        if_equal        as_skip_parsing_end_directive
        cmp     bx,as_else_directive-as_instruction_handler
        if_equal        as_skip_parsing_else
      as_skip_parsing_contents:
        lods    as_u8 [esi]
        or      al,al
        if_zero as_skip_parsing
        cmp     al,1Ah
        if_equal        as_skip_parsing_symbol
        cmp     al,3Bh
        if_equal        as_skip_parsing_symbol
        cmp     al,22h
        if_equal        as_skip_parsing_string
        jmp     as_skip_parsing_contents
      as_skip_parsing_symbol:
        lods    as_u8 [esi]
        movzx   eax,al
        add     esi,eax
        jmp     as_skip_parsing_contents
      as_skip_parsing_string:
        lods    as_u32 [esi]
        add     esi,eax
        jmp     as_skip_parsing_contents
      as_skip_parsing_block:
        mov     eax,esp
        sub     eax,[as_stack_limit]
        cmp     eax,100h
        if_below        as_stack_overflow
        push    [as_current_line]
        mov     ax,bx
        shl     eax,16
        push    eax
        inc     [as_blocks_stack]
        jmp     as_skip_parsing_contents
      as_skip_parsing_end_directive:
        cmp     as_u8 [esi],1Ah
        if_not_equal    as_skip_parsing_contents
        push    edi
        inc     esi
        movzx   ecx,as_u8 [esi]
        inc     esi
        call    as_get_instruction
        pop     edi
        if_not_carry    as_skip_parsing_end_block
        add     esi,ecx
        jmp     as_skip_parsing_contents
      as_skip_parsing_end_block:
        lods    as_u8 [esi]
        or      al,al
        if_not_zero     as_extra_characters_on_line
        cmp     bx,as_if_directive-as_instruction_handler
        if_equal        as_close_skip_parsing_block
        cmp     bx,as_repeat_directive-as_instruction_handler
        if_equal        as_close_skip_parsing_block
        cmp     bx,as_while_directive-as_instruction_handler
        if_equal        as_close_skip_parsing_block
        jmp     as_skip_parsing
      as_close_skip_parsing_block:
        cmp     [as_blocks_stack],0
        if_equal        as_unexpected_instruction
        cmp     bx,[esp+2]
        if_not_equal    as_unexpected_instruction
        dec     [as_blocks_stack]
        pop     eax edx
        test    al,1
        if_zero as_skip_parsing
        cmp     bx,as_if_directive-as_instruction_handler
        if_not_equal    as_parse_next_line
        test    al,10000b
        if_zero as_parse_next_line
        mov     al,0Fh
        stos    as_u8 [edi]
        mov     eax,[as_current_line]
        stos    as_u32 [edi]
        inc     [as_parsed_lines]
        mov     eax,1 + (as_end_directive-as_instruction_handler) shl 8
        stos    as_u32 [edi]
        mov     eax,1 + (as_if_directive-as_instruction_handler) shl 8
        stos    as_u32 [edi]
        jmp     as_parse_next_line
      as_skip_parsing_else:
        cmp     [as_blocks_stack],0
        if_equal        as_unexpected_instruction
        cmp     as_u16 [esp+2],as_if_directive-as_instruction_handler
        if_not_equal    as_unexpected_instruction
        lods    as_u8 [esi]
        or      al,al
        if_zero as_skip_parsing_pure_else
        cmp     al,1Ah
        if_not_equal    as_extra_characters_on_line
        push    edi
        movzx   ecx,as_u8 [esi]
        inc     esi
        call    as_get_instruction
        if_carry        as_extra_characters_on_line
        pop     edi
        cmp     bx,as_if_directive-as_instruction_handler
        if_not_equal    as_extra_characters_on_line
        mov     al,[esp]
        test    al,1
        if_zero as_skip_parsing_contents
        test    al,100b
        if_not_zero     as_skip_parsing_contents
        test    al,10000b
        if_not_zero     as_parse_else_if
        xor     al,al
        mov     [esp],al
        mov     al,0Fh
        stos    as_u8 [edi]
        mov     eax,[as_current_line]
        stos    as_u32 [edi]
        inc     [as_parsed_lines]
      as_parse_else_if:
        mov     eax,1 + (as_if_directive-as_instruction_handler) shl 8
        stos    as_u32 [edi]
        jmp     as_parse_if
      as_skip_parsing_pure_else:
        bit_test_set    as_u32 [esp],1
        if_carry        as_unexpected_instruction
        mov     al,[esp]
        test    al,1
        if_zero as_skip_parsing
        test    al,100b
        if_not_zero     as_skip_parsing
        and     al,not 1
        or      al,1000b
        mov     [esp],al
        jmp     as_parse_next_line

as_parse_line_contents:
        mov     [as_parenthesis_stack],0
      as_parse_instruction_arguments:
        cmp     bx,as_prefix_instruction-as_instruction_handler
        if_equal        as_allow_embedded_instruction
        cmp     bx,as_times_directive-as_instruction_handler
        if_equal        as_parse_times_directive
        cmp     bx,as_end_directive-as_instruction_handler
        if_equal        as_allow_embedded_instruction
        cmp     bx,as_label_directive-as_instruction_handler
        if_equal        as_parse_label_directive
        cmp     bx,as_segment_directive-as_instruction_handler
        if_equal        as_parse_segment_directive
        cmp     bx,as_load_directive-as_instruction_handler
        if_equal        as_parse_load_directive
        cmp     bx,as_extrn_directive-as_instruction_handler
        if_equal        as_parse_extrn_directive
        cmp     bx,as_public_directive-as_instruction_handler
        if_equal        as_parse_public_directive
        cmp     bx,as_section_directive-as_instruction_handler
        if_equal        as_parse_formatter_argument
        cmp     bx,as_format_directive-as_instruction_handler
        if_equal        as_parse_formatter_argument
        cmp     bx,as_data_directive-as_instruction_handler
        if_equal        as_parse_formatter_argument
        jmp     as_parse_argument
      as_parse_formatter_argument:
        or      [as_formatter_symbols_allowed],-1
      as_parse_argument:
        lea     eax,[edi+100h]
        cmp     eax,[as_labels_list]
        if_above_equal  as_out_of_memory
        lods    as_u8 [esi]
        cmp     al,':'
        if_equal        as_instruction_separator
        cmp     al,','
        if_equal        as_separator
        cmp     al,'='
        if_equal        as_expression_comparator
        cmp     al,'|'
        if_equal        as_separator
        cmp     al,'&'
        if_equal        as_separator
        cmp     al,'~'
        if_equal        as_separator
        cmp     al,'>'
        if_equal        as_greater
        cmp     al,'<'
        if_equal        as_less
        cmp     al,')'
        if_equal        as_close_parenthesis
        or      al,al
        if_zero as_contents_parsed
        cmp     al,'['
        if_equal        as_address_argument
        cmp     al,']'
        if_equal        as_separator
        cmp     al,'{'
        if_equal        as_open_decorator
        cmp     al,'}'
        if_equal        as_close_decorator
        cmp     al,'#'
        if_equal        as_unallowed_character
        cmp     al,'`'
        if_equal        as_unallowed_character
        cmp     al,3Bh
        if_equal        as_foreign_argument
        cmp     [as_decorator_symbols_allowed],0
        if_equal        as_not_a_separator
        cmp     al,'-'
        if_equal        as_separator
      as_not_a_separator:
        dec     esi
        cmp     al,1Ah
        if_not_equal    as_expression_argument
        push    edi
        mov     edi,as_directive_operators
        call    as_get_operator
        or      al,al
        if_not_zero     as_operator_argument
        inc     esi
        movzx   ecx,as_u8 [esi]
        inc     esi
        call    as_get_symbol
        if_not_carry    as_symbol_argument
        cmp     ecx,1
        if_not_equal    as_check_argument
        cmp     as_u8 [esi],'?'
        if_not_equal    as_check_argument
        pop     edi
        movs    as_u8 [edi],[esi]
        jmp     as_argument_parsed
      as_foreign_argument:
        dec     esi
        call    as_skip_foreign_line
        jmp     as_contents_parsed
      as_symbol_argument:
        pop     edi
        stos    as_u16 [edi]
        cmp     as_u8 [esi],'+'
        if_not_equal    as_argument_parsed
        and     ax,0F0FFh
        cmp     ax,6010h
        if_not_equal    as_argument_parsed
        movs    as_u8 [edi],[esi]
        jmp     as_argument_parsed
      as_operator_argument:
        pop     edi
        cmp     al,85h
        if_equal        as_ptr_argument
        stos    as_u8 [edi]
        cmp     al,8Ch
        if_equal        as_forced_expression
        cmp     al,81h
        if_equal        as_forced_parenthesis
        cmp     al,80h
        if_equal        as_parse_at_operator
        cmp     al,82h
        if_equal        as_parse_from_operator
        cmp     al,89h
        if_equal        as_parse_label_operator
        cmp     al,0F8h
        if_equal        as_forced_expression
        jmp     as_argument_parsed
      as_instruction_separator:
        stos    as_u8 [edi]
      as_allow_embedded_instruction:
        cmp     as_u8 [esi],1Ah
        if_not_equal    as_parse_argument
        push    edi
        inc     esi
        movzx   ecx,as_u8 [esi]
        inc     esi
        call    as_get_instruction
        if_not_carry    as_embedded_instruction
        call    as_get_data_directive
        if_not_carry    as_embedded_instruction
        pop     edi
        sub     esi,2
        jmp     as_parse_argument
      as_embedded_instruction:
        pop     edi
        mov     dl,al
        mov     al,1
        stos    as_u8 [edi]
        mov     ax,bx
        stos    as_u16 [edi]
        mov     al,dl
        stos    as_u8 [edi]
        jmp     as_parse_instruction_arguments
      as_parse_times_directive:
        mov     al,'('
        stos    as_u8 [edi]
        call    as_convert_expression
        mov     al,')'
        stos    as_u8 [edi]
        cmp     as_u8 [esi],':'
        if_not_equal    as_allow_embedded_instruction
        movs    as_u8 [edi],[esi]
        jmp     as_allow_embedded_instruction
      as_parse_segment_directive:
        or      [as_formatter_symbols_allowed],-1
      as_parse_label_directive:
        cmp     as_u8 [esi],1Ah
        if_not_equal    as_argument_parsed
        push    esi
        inc     esi
        movzx   ecx,as_u8 [esi]
        inc     esi
        call    as_identify_label
        pop     ebx
        cmp     eax,0Fh
        if_equal        as_non_label_identified
        mov     as_u8 [edi],2
        inc     edi
        stos    as_u32 [edi]
        xor     al,al
        stos    as_u8 [edi]
        jmp     as_argument_parsed
      as_non_label_identified:
        mov     esi,ebx
        jmp     as_argument_parsed
      as_parse_load_directive:
        cmp     as_u8 [esi],1Ah
        if_not_equal    as_argument_parsed
        push    esi
        inc     esi
        movzx   ecx,as_u8 [esi]
        inc     esi
        call    as_get_label_id
        pop     ebx
        cmp     eax,0Fh
        if_equal        as_non_label_identified
        mov     as_u8 [edi],2
        inc     edi
        stos    as_u32 [edi]
        xor     al,al
        stos    as_u8 [edi]
        jmp     as_argument_parsed
      as_parse_public_directive:
        cmp     as_u8 [esi],1Ah
        if_not_equal    as_parse_argument
        inc     esi
        push    esi
        movzx   ecx,as_u8 [esi]
        inc     esi
        push    esi ecx
        push    edi
        or      [as_formatter_symbols_allowed],-1
        call    as_get_symbol
        mov     [as_formatter_symbols_allowed],0
        pop     edi
        if_carry        as_parse_public_label
        cmp     al,1Dh
        if_not_equal    as_parse_public_label
        add     esp,12
        stos    as_u16 [edi]
        jmp     as_parse_public_directive
      as_parse_public_label:
        pop     ecx esi
        mov     al,2
        stos    as_u8 [edi]
        call    as_get_label_id
        stos    as_u32 [edi]
        mov     ax,8600h
        stos    as_u16 [edi]
        pop     ebx
        push    ebx esi edi
        mov     edi,as_directive_operators
        call    as_get_operator
        pop     edi edx ebx
        cmp     al,86h
        if_equal        as_argument_parsed
        mov     esi,edx
        xchg    esi,ebx
        movzx   ecx,as_u8 [esi]
        inc     esi
        mov     ax,'('
        stos    as_u16 [edi]
        mov     eax,ecx
        stos    as_u32 [edi]
        rep     movs as_u8 [edi],[esi]
        xor     al,al
        stos    as_u8 [edi]
        xchg    esi,ebx
        jmp     as_argument_parsed
      as_parse_extrn_directive:
        cmp     as_u8 [esi],22h
        if_equal        as_parse_quoted_extrn
        cmp     as_u8 [esi],1Ah
        if_not_equal    as_parse_argument
        push    esi
        movzx   ecx,as_u8 [esi+1]
        add     esi,2
        mov     ax,'('
        stos    as_u16 [edi]
        mov     eax,ecx
        stos    as_u32 [edi]
        rep     movs as_u8 [edi],[esi]
        mov     ax,8600h
        stos    as_u16 [edi]
        pop     esi
      as_parse_label_operator:
        cmp     as_u8 [esi],1Ah
        if_not_equal    as_argument_parsed
        inc     esi
        movzx   ecx,as_u8 [esi]
        inc     esi
        mov     al,2
        stos    as_u8 [edi]
        call    as_get_label_id
        stos    as_u32 [edi]
        xor     al,al
        stos    as_u8 [edi]
        jmp     as_argument_parsed
      as_parse_from_operator:
        cmp     as_u8 [esi],22h
        if_equal        as_argument_parsed
      as_parse_at_operator:
        cmp     as_u8 [esi],':'
        if_equal        as_argument_parsed
        jmp     as_forced_multipart_expression
      as_parse_quoted_extrn:
        inc     esi
        mov     ax,'('
        stos    as_u16 [edi]
        lods    as_u32 [esi]
        mov     ecx,eax
        stos    as_u32 [edi]
        rep     movs as_u8 [edi],[esi]
        xor     al,al
        stos    as_u8 [edi]
        push    esi edi
        mov     edi,as_directive_operators
        call    as_get_operator
        mov     edx,esi
        pop     edi esi
        cmp     al,86h
        if_not_equal    as_argument_parsed
        stos    as_u8 [edi]
        mov     esi,edx
        jmp     as_parse_label_operator
      as_ptr_argument:
        call    as_parse_address
        jmp     as_address_parsed
      as_check_argument:
        push    esi ecx
        sub     esi,2
        mov     edi,as_single_operand_operators
        call    as_get_operator
        pop     ecx esi
        or      al,al
        if_not_zero     as_not_instruction
        call    as_get_instruction
        if_not_carry    as_embedded_instruction
        call    as_get_data_directive
        if_not_carry    as_embedded_instruction
      as_not_instruction:
        pop     edi
        sub     esi,2
      as_expression_argument:
        cmp     as_u8 [esi],22h
        if_not_equal    as_not_string
        mov     eax,[esi+1]
        lea     ebx,[esi+5+eax]
        push    ebx ecx esi edi
        call    as_parse_expression
        pop     eax edx ecx ebx
        cmp     esi,ebx
        if_not_equal    as_expression_argument_parsed
        mov     edi,eax
        mov     esi,edx
      as_string_argument:
        inc     esi
        mov     ax,'('
        stos    as_u16 [edi]
        lods    as_u32 [esi]
        mov     ecx,eax
        stos    as_u32 [edi]
        shr     ecx,1
        if_not_carry    as_string_movsb_ok
        movs    as_u8 [edi],[esi]
      as_string_movsb_ok:
        shr     ecx,1
        if_not_carry    as_string_movsw_ok
        movs    as_u16 [edi],[esi]
      as_string_movsw_ok:
        rep     movs as_u32 [edi],[esi]
        xor     al,al
        stos    as_u8 [edi]
        jmp     as_expression_argument_parsed
      as_parse_expression:
        mov     al,'('
        stos    as_u8 [edi]
        call    as_convert_expression
        mov     al,')'
        stos    as_u8 [edi]
        ret
      as_not_string:
        cmp     as_u8 [esi],'('
        if_not_equal    as_expression
        mov     eax,esp
        sub     eax,[as_stack_limit]
        cmp     eax,100h
        if_below        as_stack_overflow
        push    esi edi
        inc     esi
        mov     al,91h
        stos    as_u8 [edi]
        inc     [as_parenthesis_stack]
        jmp     as_parse_argument
      as_expression_comparator:
        stos    as_u8 [edi]
        jmp     as_forced_expression
      as_greater:
        cmp     as_u8 [esi],'='
        if_not_equal    as_separator
        inc     esi
        mov     al,0F2h
        jmp     as_separator
      as_less:
        cmp     as_u8 [edi-1],0F6h
        if_equal        as_separator
        cmp     as_u8 [esi],'>'
        if_equal        as_not_equal
        cmp     as_u8 [esi],'='
        if_not_equal    as_separator
        inc     esi
        mov     al,0F3h
        jmp     as_separator
      as_not_equal:
        inc     esi
        mov     al,0F1h
        jmp     as_expression_comparator
      as_expression:
        call    as_parse_expression
        jmp     as_expression_argument_parsed
      as_forced_expression:
        xor     al,al
        xchg    al,[as_formatter_symbols_allowed]
        push    eax
        call    as_parse_expression
      as_forced_expression_parsed:
        pop     eax
        mov     [as_formatter_symbols_allowed],al
        jmp     as_argument_parsed
      as_forced_multipart_expression:
        xor     al,al
        xchg    al,[as_formatter_symbols_allowed]
        push    eax
        call    as_parse_expression
        cmp     as_u8 [esi],':'
        if_not_equal    as_forced_expression_parsed
        movs    as_u8 [edi],[esi]
        call    as_parse_expression
        jmp     as_forced_expression_parsed
      as_address_argument:
        call    as_parse_address
        lods    as_u8 [esi]
        cmp     al,']'
        if_equal        as_address_parsed
        cmp     al,','
        if_equal        as_divided_address
        dec     esi
        mov     al,')'
        stos    as_u8 [edi]
        jmp     as_argument_parsed
      as_divided_address:
        mov     ax,'),'
        stos    as_u16 [edi]
        jmp     as_expression
      as_address_parsed:
        mov     al,']'
        stos    as_u8 [edi]
        jmp     as_argument_parsed
      as_parse_address:
        mov     al,'['
        stos    as_u8 [edi]
        cmp     as_u16 [esi],021Ah
        if_not_equal    as_convert_address
        push    esi
        add     esi,4
        lea     ebx,[esi+1]
        cmp     as_u8 [esi],':'
        pop     esi
        if_not_equal    as_convert_address
        add     esi,2
        mov     ecx,2
        push    ebx edi
        call    as_get_symbol
        pop     edi esi
        if_carry        as_unknown_segment_prefix
        cmp     al,10h
        if_not_equal    as_unknown_segment_prefix
        mov     al,ah
        and     ah,11110000b
        cmp     ah,30h
        if_not_equal    as_unknown_segment_prefix
        add     al,30h
        stos    as_u8 [edi]
        jmp     as_convert_address
      as_unknown_segment_prefix:
        sub     esi,5
      as_convert_address:
        push    edi
        mov     edi,as_address_sizes
        call    as_get_operator
        pop     edi
        or      al,al
        if_zero as_convert_expression
        add     al,70h
        stos    as_u8 [edi]
        jmp     as_convert_expression
      as_forced_parenthesis:
        cmp     as_u8 [esi],'('
        if_not_equal    as_argument_parsed
        inc     esi
        mov     al,91h
        jmp     as_separator
      as_unallowed_character:
        mov     al,0FFh
        jmp     as_separator
      as_open_decorator:
        inc     [as_decorator_symbols_allowed]
        jmp     as_separator
      as_close_decorator:
        dec     [as_decorator_symbols_allowed]
        jmp     as_separator
      as_close_parenthesis:
        mov     al,92h
      as_separator:
        stos    as_u8 [edi]
      as_argument_parsed:
        cmp     [as_parenthesis_stack],0
        if_equal        as_parse_argument
        dec     [as_parenthesis_stack]
        add     esp,8
        jmp     as_argument_parsed
      as_expression_argument_parsed:
        cmp     [as_parenthesis_stack],0
        if_equal        as_parse_argument
        cmp     as_u8 [esi],')'
        if_not_equal    as_argument_parsed
        dec     [as_parenthesis_stack]
        pop     edi esi
        jmp     as_expression
      as_contents_parsed:
        cmp     [as_parenthesis_stack],0
        if_equal        as_contents_ok
        dec     [as_parenthesis_stack]
        add     esp,8
        jmp     as_contents_parsed
      as_contents_ok:
        ret

as_identify_label:
        cmp     as_u8 [esi],'.'
        if_equal        as_local_label_name
        call    as_get_label_id
        cmp     eax,10h
        if_below        as_label_identified
        or      ebx,ebx
        if_zero as_anonymous_label_name
        dec     ebx
        mov     [as_current_locals_prefix],ebx
      as_label_identified:
        ret
      as_anonymous_label_name:
        cmp     as_u8 [esi-1],'@'
        if_equal        as_anonymous_label_name_ok
        mov     eax,0Fh
      as_anonymous_label_name_ok:
        ret
      as_local_label_name:
        call    as_get_label_id
        ret

as_get_operator:
        cmp     as_u8 [esi],1Ah
        if_not_equal    as_get_simple_operator
        mov     edx,esi
        push    ebp
        inc     esi
        lods    as_u8 [esi]
        movzx   ebp,al
        push    edi
        mov     ecx,ebp
        call    as_lower_case
        pop     edi
      as_check_operator:
        mov     esi,as_converted
        movzx   ecx,as_u8 [edi]
        jecxz   as_no_operator
        inc     edi
        mov     ebx,edi
        add     ebx,ecx
        cmp     ecx,ebp
        if_not_equal    as_next_operator
        repe    cmps as_u8 [esi],[edi]
        if_equal        as_operator_found
        if_below        as_no_operator
      as_next_operator:
        mov     edi,ebx
        inc     edi
        jmp     as_check_operator
      as_no_operator:
        mov     esi,edx
        mov     ecx,ebp
        pop     ebp
      as_no_simple_operator:
        xor     al,al
        ret
      as_operator_found:
        lea     esi,[edx+2+ebp]
        mov     ecx,ebp
        pop     ebp
        mov     al,[edi]
        ret
      as_get_simple_operator:
        mov     al,[esi]
        cmp     al,22h
        if_equal        as_no_simple_operator
      as_simple_operator:
        cmp     as_u8 [edi],1
        if_below        as_no_simple_operator
        if_above        as_simple_next_operator
        cmp     al,[edi+1]
        if_equal        as_simple_operator_found
      as_simple_next_operator:
        movzx   ecx,as_u8 [edi]
        lea     edi,[edi+1+ecx+1]
        jmp     as_simple_operator
      as_simple_operator_found:
        inc     esi
        mov     al,[edi+2]
        ret

as_get_symbol:
        push    esi
        mov     ebp,ecx
        call    as_lower_case
        mov     ecx,ebp
        cmp     cl,11
        if_above        as_no_symbol
        sub     cl,1
        if_carry        as_no_symbol
        movzx   ebx,as_u16 [as_symbols+ecx*4]
        add     ebx,as_symbols
        movzx   edx,as_u16 [as_symbols+ecx*4+2]
      as_scan_symbols:
        or      edx,edx
        if_zero as_no_symbol
        mov     eax,edx
        shr     eax,1
        lea     edi,[ebp+2]
        signed_multiply eax,edi
        lea     edi,[ebx+eax]
        mov     esi,as_converted
        mov     ecx,ebp
        repe    cmps as_u8 [esi],[edi]
        if_above        as_symbols_up
        if_below        as_symbols_down
        mov     ax,[edi]
        cmp     al,18h
        if_below        as_symbol_ok
        cmp     al,1Fh
        if_equal        as_decorator_symbol
        cmp     [as_formatter_symbols_allowed],0
        if_equal        as_no_symbol
      as_symbol_ok:
        pop     esi
        add     esi,ebp
        clear_carry
        ret
      as_decorator_symbol:
        cmp     [as_decorator_symbols_allowed],0
        if_not_equal    as_symbol_ok
      as_no_symbol:
        pop     esi
        mov     ecx,ebp
        set_carry
        ret
      as_symbols_down:
        shr     edx,1
        jmp     as_scan_symbols
      as_symbols_up:
        lea     ebx,[edi+ecx+2]
        shr     edx,1
        add_with_carry  edx,-1
        jmp     as_scan_symbols

as_get_data_directive:
        push    esi
        mov     ebp,ecx
        call    as_lower_case
        mov     ecx,ebp
        cmp     cl,4
        if_above        as_no_instruction
        sub     cl,2
        if_carry        as_no_instruction
        movzx   ebx,as_u16 [as_data_directives+ecx*4]
        add     ebx,as_data_directives
        movzx   edx,as_u16 [as_data_directives+ecx*4+2]
        jmp     as_scan_instructions

as_get_instruction:
        push    esi
        mov     ebp,ecx
        call    as_lower_case
        mov     ecx,ebp
        cmp     cl,25
        if_above        as_no_instruction
        sub     cl,2
        if_carry        as_no_instruction
        movzx   ebx,as_u16 [as_instructions+ecx*4]
        add     ebx,as_instructions
        movzx   edx,as_u16 [as_instructions+ecx*4+2]
      as_scan_instructions:
        or      edx,edx
        if_zero as_no_instruction
        mov     eax,edx
        shr     eax,1
        lea     edi,[ebp+3]
        signed_multiply eax,edi
        lea     edi,[ebx+eax]
        mov     esi,as_converted
        mov     ecx,ebp
        repe    cmps as_u8 [esi],[edi]
        if_above        as_instructions_up
        if_below        as_instructions_down
        pop     esi
        add     esi,ebp
        mov     al,[edi]
        mov     bx,[edi+1]
        clear_carry
        ret
      as_no_instruction:
        pop     esi
        mov     ecx,ebp
        set_carry
        ret
      as_instructions_down:
        shr     edx,1
        jmp     as_scan_instructions
      as_instructions_up:
        lea     ebx,[edi+ecx+3]
        shr     edx,1
        add_with_carry  edx,-1
        jmp     as_scan_instructions

as_get_label_id:
        cmp     ecx,100h
        if_above_equal  as_name_too_long
        cmp     as_u8 [esi],'@'
        if_equal        as_anonymous_label
        cmp     as_u8 [esi],'.'
        if_not_equal    as_standard_label
        cmp     as_u8 [esi+1],'.'
        if_equal        as_standard_label
        cmp     [as_current_locals_prefix],0
        if_equal        as_standard_label
        push    edi
        mov     edi,[as_additional_memory_end]
        sub     edi,2
        sub     edi,ecx
        push    ecx esi
        mov     esi,[as_current_locals_prefix]
        lods    as_u8 [esi]
        movzx   ecx,al
        sub     edi,ecx
        cmp     edi,[as_free_additional_memory]
        if_below        as_out_of_memory
        mov     as_u16 [edi],0
        add     edi,2
        mov     ebx,edi
        rep     movs as_u8 [edi],[esi]
        pop     esi ecx
        add     al,cl
        if_carry        as_name_too_long
        rep     movs as_u8 [edi],[esi]
        pop     edi
        push    ebx esi
        movzx   ecx,al
        mov     as_u8 [ebx-1],al
        mov     esi,ebx
        call    as_get_label_id
        pop     esi ebx
        cmp     ebx,[eax+24]
        if_not_equal    as_composed_label_id_ok
        lea     edx,[ebx-2]
        mov     [as_additional_memory_end],edx
      as_composed_label_id_ok:
        ret
      as_anonymous_label:
        cmp     ecx,2
        if_not_equal    as_standard_label
        mov     al,[esi+1]
        mov     ebx,as_characters
        translate_byte  as_u8 [ebx]
        cmp     al,'@'
        if_equal        as_new_anonymous
        cmp     al,'b'
        if_equal        as_anonymous_back
        cmp     al,'r'
        if_equal        as_anonymous_back
        cmp     al,'f'
        if_not_equal    as_standard_label
        add     esi,2
        mov     eax,[as_anonymous_forward]
        or      eax,eax
        if_not_zero     as_anonymous_ok
        mov     eax,[as_current_line]
        mov     [as_error_line],eax
        call    as_allocate_label
        mov     [as_anonymous_forward],eax
      as_anonymous_ok:
        xor     ebx,ebx
        ret
      as_anonymous_back:
        mov     eax,[as_anonymous_reverse]
        add     esi,2
        or      eax,eax
        if_zero as_bogus_anonymous
        jmp     as_anonymous_ok
      as_bogus_anonymous:
        call    as_allocate_label
        mov     [as_anonymous_reverse],eax
        jmp     as_anonymous_ok
      as_new_anonymous:
        add     esi,2
        mov     eax,[as_anonymous_forward]
        or      eax,eax
        if_not_zero     as_new_anonymous_ok
        call    as_allocate_label
      as_new_anonymous_ok:
        mov     [as_anonymous_reverse],eax
        mov     [as_anonymous_forward],0
        jmp     as_anonymous_ok
      as_standard_label:
        cmp     as_u8 [esi],'%'
        if_equal        as_get_predefined_id
        cmp     as_u8 [esi],'$'
        if_equal        as_current_address_label
        cmp     as_u8 [esi],'?'
        if_not_equal    as_find_label
        cmp     ecx,1
        if_not_equal    as_find_label
        inc     esi
        mov     eax,0Fh
        ret
      as_current_address_label:
        cmp     ecx,3
        if_equal        as_current_address_label_3_characters
        if_above        as_find_label
        inc     esi
        cmp     ecx,1
        if_below_equal  as_get_current_offset_id
        inc     esi
        cmp     as_u8 [esi-1],'$'
        if_equal        as_get_org_origin_id
        cmp     as_u8 [esi-1],'%'
        if_equal        as_get_file_offset_id
        sub     esi,2
        jmp     as_find_label
      as_get_current_offset_id:
        xor     eax,eax
        ret
      as_get_counter_id:
        mov     eax,1
        ret
      as_get_timestamp_id:
        mov     eax,2
        ret
      as_get_org_origin_id:
        mov     eax,3
        ret
      as_get_file_offset_id:
        mov     eax,4
        ret
      as_current_address_label_3_characters:
        cmp     as_u16 [esi+1],'%%'
        if_not_equal    as_find_label
        add     esi,3
      as_get_actual_file_offset_id:
        mov     eax,5
        ret
      as_get_predefined_id:
        cmp     ecx,2
        if_above        as_find_label
        inc     esi
        cmp     cl,1
        if_equal        as_get_counter_id
        lods    as_u8 [esi]
        mov     ebx,as_characters
        translate_byte  [ebx]
        cmp     al,'t'
        if_equal        as_get_timestamp_id
        sub     esi,2
      as_find_label:
        xor     ebx,ebx
        mov     eax,2166136261
        mov     ebp,16777619
      as_hash_label:
        xor     al,[esi+ebx]
        mul     ebp
        inc     bl
        cmp     bl,cl
        if_below        as_hash_label
        mov     ebp,eax
        shl     eax,8
        and     ebp,0FFh shl 24
        xor     ebp,eax
        or      ebp,ebx
        mov     [as_label_hash],ebp
        push    edi esi
        push    ecx
        mov     ecx,32
        mov     ebx,as_hash_tree
      as_follow_tree:
        mov     edx,[ebx]
        or      edx,edx
        if_zero as_extend_tree
        xor     eax,eax
        shl     ebp,1
        add_with_carry  eax,0
        lea     ebx,[edx+eax*4]
        dec     ecx
        if_not_zero     as_follow_tree
        mov     [as_label_leaf],ebx
        pop     edx
        mov     eax,[ebx]
        or      eax,eax
        if_zero as_add_label
        mov     ebx,esi
        mov     ebp,[as_label_hash]
      as_compare_labels:
        mov     esi,ebx
        mov     ecx,edx
        mov     edi,[eax+4]
        mov     edi,[edi+24]
        repe    cmps as_u8 [esi],[edi]
        if_equal        as_label_found
        mov     eax,[eax]
        or      eax,eax
        if_not_zero     as_compare_labels
        jmp     as_add_label
      as_label_found:
        add     esp,4
        pop     edi
        mov     eax,[eax+4]
        ret
      as_extend_tree:
        mov     edx,[as_free_additional_memory]
        lea     eax,[edx+8]
        cmp     eax,[as_additional_memory_end]
        if_above        as_out_of_memory
        mov     [as_free_additional_memory],eax
        xor     eax,eax
        mov     [edx],eax
        mov     [edx+4],eax
        shl     ebp,1
        add_with_carry  eax,0
        mov     [ebx],edx
        lea     ebx,[edx+eax*4]
        dec     ecx
        if_not_zero     as_extend_tree
        mov     [as_label_leaf],ebx
        pop     edx
      as_add_label:
        mov     ecx,edx
        pop     esi
        cmp     as_u8 [esi-2],0
        if_equal        as_label_name_ok
        mov     al,[esi]
        cmp     al,30h
        if_below        as_name_first_char_ok
        cmp     al,39h
        if_below_equal  as_numeric_name
      as_name_first_char_ok:
        cmp     al,'$'
        if_not_equal    as_check_for_reserved_word
      as_numeric_name:
        add     esi,ecx
      as_reserved_word:
        mov     eax,0Fh
        pop     edi
        ret
      as_check_for_reserved_word:
        call    as_get_instruction
        if_not_carry    as_reserved_word
        call    as_get_data_directive
        if_not_carry    as_reserved_word
        call    as_get_symbol
        if_not_carry    as_reserved_word
        sub     esi,2
        mov     edi,as_operators
        call    as_get_operator
        or      al,al
        if_not_zero     as_reserved_word
        mov     edi,as_single_operand_operators
        call    as_get_operator
        or      al,al
        if_not_zero     as_reserved_word
        mov     edi,as_directive_operators
        call    as_get_operator
        or      al,al
        if_not_zero     as_reserved_word
        inc     esi
        movzx   ecx,as_u8 [esi]
        inc     esi
      as_label_name_ok:
        mov     edx,[as_free_additional_memory]
        lea     eax,[edx+8]
        cmp     eax,[as_additional_memory_end]
        if_above        as_out_of_memory
        mov     [as_free_additional_memory],eax
        mov     ebx,esi
        add     esi,ecx
        mov     eax,[as_label_leaf]
        mov     edi,[eax]
        mov     [edx],edi
        mov     [eax],edx
        call    as_allocate_label
        mov     [edx+4],eax
        mov     [eax+24],ebx
        pop     edi
        ret
      as_allocate_label:
        mov     eax,[as_labels_list]
        mov     ecx,LABEL_STRUCTURE_SIZE shr 2
      as_initialize_label:
        sub     eax,4
        mov     as_u32 [eax],0
        loop    as_initialize_label
        mov     [as_labels_list],eax
        ret

as_skip_foreign_line:
      as_skip_foreign_token:
        lods    as_u8 [esi]
        or      al,al
        if_zero as_foreign_line_skipped
        cmp     al,1Ah
        if_equal        as_skip_foreign_symbol
        cmp     al,22h
        if_equal        as_skip_foreign_string
        jmp     as_skip_foreign_token
      as_skip_foreign_symbol:
        lods    as_u8 [esi]
        movzx   eax,al
        add     esi,eax
        jmp     as_skip_foreign_token
      as_skip_foreign_string:
        lods    as_u32 [esi]
        add     esi,eax
        jmp     as_skip_foreign_token
      as_foreign_line_skipped:
        ret

LABEL_STRUCTURE_SIZE = 32
