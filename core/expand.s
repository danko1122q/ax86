; SPDX-License-Identifier: BSD-2-Clause
; Copyright (c) 2026 danko1122q
; All rights reserved.

as_preprocessor:
        mov     edi,as_characters
        xor     al,al
      as_make_characters_table:
        stosb
        inc     al
        if_not_zero     as_make_characters_table
        mov     esi,as_characters+'a'
        mov     edi,as_characters+'A'
        mov     ecx,26
        rep     movsb
        mov     edi,as_characters
        mov     esi,as_token_delimiters+1
        movzx   ecx,as_u8 [esi-1]
        xor     eax,eax
      as_mark_token_delimiters:
        lodsb
        mov     as_u8 [edi+eax],0
        loop    as_mark_token_delimiters
        mov     edi,as_locals_counter
        mov     ax,1 + '0' shl 8
        stos    as_u16 [edi]
        mov     edi,[as_memory_start]
        mov     [as_include_paths],edi
        mov     esi,as_include_var
        call    as_get_environment_variable
        cmp     edi,[as_include_paths]
        if_equal        as_no_env_include
        mov     as_u8 [edi],';'
        inc     edi
      as_no_env_include:
        mov     esi,as_include_extra
      as_append_include_extra:
        lodsb
        stos    as_u8 [edi]
        or      al,al
        if_not_zero     as_append_include_extra
        mov     [as_memory_start],edi
        mov     eax,[as_additional_memory]
        mov     [as_free_additional_memory],eax
        mov     eax,[as_additional_memory_end]
        mov     [as_labels_list],eax
        xor     eax,eax
        mov     [as_source_start],eax
        mov     [as_tagged_blocks],eax
        mov     [as_hash_tree],eax
        mov     [as_error],eax
        mov     [as_macro_status],al
        mov     [as_current_line],eax
        mov     esi,[as_initial_definitions]
        test    esi,esi
        if_zero as_predefinitions_ok
      as_process_predefinitions:
        movzx   ecx,as_u8 [esi]
        test    ecx,ecx
        if_zero as_predefinitions_ok
        inc     esi
        lea     eax,[esi+ecx]
        push    eax
        mov     ch,10b
        call    as_add_preprocessor_symbol
        pop     esi
        mov     edi,[as_memory_start]
        mov     [edx+8],edi
      as_convert_predefinition:
        cmp     edi,[as_memory_end]
        if_above_equal  as_out_of_memory
        lods    as_u8 [esi]
        or      al,al
        if_zero as_predefinition_converted
        cmp     al,20h
        if_equal        as_convert_predefinition
        mov     ah,al
        mov     ebx,as_characters
        translate_byte  as_u8 [ebx]
        or      al,al
        if_zero as_predefinition_separator
        cmp     ah,27h
        if_equal        as_predefinition_string
        cmp     ah,22h
        if_equal        as_predefinition_string
        mov     as_u8 [edi],1Ah
        scas    as_u16 [edi]
        xchg    al,ah
        stos    as_u8 [edi]
        mov     ebx,as_characters
        xor     ecx,ecx
      as_predefinition_symbol:
        lods    as_u8 [esi]
        stos    as_u8 [edi]
        translate_byte  as_u8 [ebx]
        or      al,al
        loopnzd as_predefinition_symbol
        negate  ecx
        cmp     ecx,255
        if_above        as_invalid_definition
        mov     ebx,edi
        sub     ebx,ecx
        mov     as_u8 [ebx-2],cl
      as_found_predefinition_separator:
        dec     edi
        mov     ah,[esi-1]
      as_predefinition_separator:
        xchg    al,ah
        or      al,al
        if_zero as_predefinition_converted
        cmp     al,20h
        if_equal        as_convert_predefinition
        cmp     al,3Bh
        if_equal        as_invalid_definition
        cmp     al,5Ch
        if_equal        as_predefinition_backslash
        stos    as_u8 [edi]
        jmp     as_convert_predefinition
      as_predefinition_string:
        mov     al,22h
        stos    as_u8 [edi]
        scas    as_u32 [edi]
        mov     ebx,edi
      as_copy_predefinition_string:
        lods    as_u8 [esi]
        stos    as_u8 [edi]
        or      al,al
        if_zero as_invalid_definition
        cmp     al,ah
        if_not_equal    as_copy_predefinition_string
        lods    as_u8 [esi]
        cmp     al,ah
        if_equal        as_copy_predefinition_string
        dec     esi
        dec     edi
        mov     eax,edi
        sub     eax,ebx
        mov     [ebx-4],eax
        jmp     as_convert_predefinition
      as_predefinition_backslash:
        mov     as_u8 [edi],0
        lods    as_u8 [esi]
        or      al,al
        if_zero as_invalid_definition
        cmp     al,20h
        if_equal        as_invalid_definition
        cmp     al,3Bh
        if_equal        as_invalid_definition
        mov     al,1Ah
        stos    as_u8 [edi]
        mov     ecx,edi
        mov     ax,5C01h
        stos    as_u16 [edi]
        dec     esi
      as_group_predefinition_backslashes:
        lods    as_u8 [esi]
        cmp     al,5Ch
        if_not_equal    as_predefinition_backslashed_symbol
        stos    as_u8 [edi]
        inc     as_u8 [ecx]
        jmp     as_group_predefinition_backslashes
      as_predefinition_backslashed_symbol:
        cmp     al,20h
        if_equal        as_invalid_definition
        cmp     al,22h
        if_equal        as_invalid_definition
        cmp     al,27h
        if_equal        as_invalid_definition
        cmp     al,3Bh
        if_equal        as_invalid_definition
        mov     ah,al
        mov     ebx,as_characters
        translate_byte  as_u8 [ebx]
        or      al,al
        if_zero as_predefinition_backslashed_symbol_character
        mov     al,ah
      as_convert_predefinition_backslashed_symbol:
        stos    as_u8 [edi]
        translate_byte  as_u8 [ebx]
        or      al,al
        if_zero as_found_predefinition_separator
        inc     as_u8 [ecx]
        if_zero as_invalid_definition
        lods    as_u8 [esi]
        jmp     as_convert_predefinition_backslashed_symbol
      as_predefinition_backslashed_symbol_character:
        mov     al,ah
        stos    as_u8 [edi]
        inc     as_u8 [ecx]
        jmp     as_convert_predefinition
      as_predefinition_converted:
        mov     [as_memory_start],edi
        sub     edi,[edx+8]
        mov     [edx+12],edi
        jmp     as_process_predefinitions
      as_predefinitions_ok:
        mov     esi,[as_input_file]
        mov     edx,esi
        call    as_open
        if_carry        as_main_file_not_found
        mov     edi,[as_memory_start]
        call    as_preprocess_file
      as_preprocessing_finished:
        mov     [as_source_start],edi
        ret

as_preprocess_file:
        push    [as_memory_end]
        push    esi
        mov     al,2
        xor     edx,edx
        call    as_lseek
        push    eax
        xor     al,al
        xor     edx,edx
        call    as_lseek
        pop     ecx
        mov     edx,[as_memory_end]
        dec     edx
        mov     as_u8 [edx],1Ah
        sub     edx,ecx
        if_carry        as_out_of_memory
        mov     esi,edx
        cmp     edx,edi
        if_below_equal  as_out_of_memory
        mov     [as_memory_end],edx
        call    as_read
        call    as_close
        pop     edx
        xor     ecx,ecx
        mov     ebx,esi
      as_preprocess_source:
        inc     ecx
        mov     [as_current_line],edi
        mov     eax,edx
        stos    as_u32 [edi]
        mov     eax,ecx
        stos    as_u32 [edi]
        mov     eax,esi
        sub     eax,ebx
        stos    as_u32 [edi]
        xor     eax,eax
        stos    as_u32 [edi]
        push    ebx edx
        call    as_convert_line
        call    as_preprocess_line
        pop     edx ebx
      as_next_line:
        cmp     as_u8 [esi-1],0
        if_equal        as_file_end
        cmp     as_u8 [esi-1],1Ah
        if_not_equal    as_preprocess_source
      as_file_end:
        pop     [as_memory_end]
        clear_carry
        ret

as_convert_line:
        push    ecx
      as_convert_line_data:
        cmp     edi,[as_memory_end]
        if_above_equal  as_out_of_memory
        lods    as_u8 [esi]
        cmp     al,20h
        if_equal        as_convert_line_data
        cmp     al,9
        if_equal        as_convert_line_data
        mov     ah,al
        mov     ebx,as_characters
        translate_byte  as_u8 [ebx]
        or      al,al
        if_zero as_convert_separator
        cmp     ah,27h
        if_equal        as_convert_string
        cmp     ah,22h
        if_equal        as_convert_string
        mov     as_u8 [edi],1Ah
        scas    as_u16 [edi]
        xchg    al,ah
        stos    as_u8 [edi]
        mov     ebx,as_characters
        xor     ecx,ecx
      as_convert_symbol:
        lods    as_u8 [esi]
        stos    as_u8 [edi]
        translate_byte  as_u8 [ebx]
        or      al,al
        loopnzd as_convert_symbol
        negate  ecx
        cmp     ecx,255
        if_above        as_name_too_long
        mov     ebx,edi
        sub     ebx,ecx
        mov     as_u8 [ebx-2],cl
      as_found_separator:
        dec     edi
        mov     ah,[esi-1]
      as_convert_separator:
        xchg    al,ah
        cmp     al,20h
        if_below        as_control_character
        if_equal        as_convert_line_data
      as_symbol_character:
        cmp     al,3Bh
        if_equal        as_ignore_comment
        cmp     al,5Ch
        if_equal        as_backslash_character
        stos    as_u8 [edi]
        jmp     as_convert_line_data
      as_control_character:
        cmp     al,1Ah
        if_equal        as_line_end
        cmp     al,0Dh
        if_equal        as_cr_character
        cmp     al,0Ah
        if_equal        as_lf_character
        cmp     al,9
        if_equal        as_convert_line_data
        or      al,al
        if_not_zero     as_symbol_character
        jmp     as_line_end
      as_lf_character:
        lods    as_u8 [esi]
        cmp     al,0Dh
        if_equal        as_line_end
        dec     esi
        jmp     as_line_end
      as_cr_character:
        lods    as_u8 [esi]
        cmp     al,0Ah
        if_equal        as_line_end
        dec     esi
        jmp     as_line_end
      as_convert_string:
        mov     al,22h
        stos    as_u8 [edi]
        scas    as_u32 [edi]
        mov     ebx,edi
      as_copy_string:
        lods    as_u8 [esi]
        stos    as_u8 [edi]
        cmp     al,0Ah
        if_equal        as_no_end_quote
        cmp     al,0Dh
        if_equal        as_no_end_quote
        or      al,al
        if_zero as_no_end_quote
        cmp     al,1Ah
        if_equal        as_no_end_quote
        cmp     al,ah
        if_not_equal    as_copy_string
        lods    as_u8 [esi]
        cmp     al,ah
        if_equal        as_copy_string
        dec     esi
        dec     edi
        mov     eax,edi
        sub     eax,ebx
        mov     [ebx-4],eax
        jmp     as_convert_line_data
      as_backslash_character:
        mov     as_u8 [edi],0
        lods    as_u8 [esi]
        cmp     al,20h
        if_equal        as_concatenate_lines
        cmp     al,9
        if_equal        as_concatenate_lines
        cmp     al,1Ah
        if_equal        as_line_end
        or      al,al
        if_zero as_line_end
        cmp     al,0Ah
        if_equal        as_concatenate_lf
        cmp     al,0Dh
        if_equal        as_concatenate_cr
        cmp     al,3Bh
        if_equal        as_find_concatenated_line
        mov     al,1Ah
        stos    as_u8 [edi]
        mov     ecx,edi
        mov     ax,5C01h
        stos    as_u16 [edi]
        dec     esi
      as_group_backslashes:
        lods    as_u8 [esi]
        cmp     al,5Ch
        if_not_equal    as_backslashed_symbol
        stos    as_u8 [edi]
        inc     as_u8 [ecx]
        if_zero as_name_too_long
        jmp     as_group_backslashes
      as_no_end_quote:
        mov     as_u8 [ebx-5],0
        jmp     as_missing_end_quote
      as_backslashed_symbol:
        cmp     al,1Ah
        if_equal        as_extra_characters_on_line
        or      al,al
        if_zero as_extra_characters_on_line
        cmp     al,0Ah
        if_equal        as_extra_characters_on_line
        cmp     al,0Dh
        if_equal        as_extra_characters_on_line
        cmp     al,20h
        if_equal        as_extra_characters_on_line
        cmp     al,9
        if_equal        as_extra_characters_on_line
        cmp     al,22h
        if_equal        as_extra_characters_on_line
        cmp     al,27h
        if_equal        as_extra_characters_on_line
        cmp     al,3Bh
        if_equal        as_extra_characters_on_line
        mov     ah,al
        mov     ebx,as_characters
        translate_byte  as_u8 [ebx]
        or      al,al
        if_zero as_backslashed_symbol_character
        mov     al,ah
      as_convert_backslashed_symbol:
        stos    as_u8 [edi]
        translate_byte  as_u8 [ebx]
        or      al,al
        if_zero as_found_separator
        inc     as_u8 [ecx]
        if_zero as_name_too_long
        lods    as_u8 [esi]
        jmp     as_convert_backslashed_symbol
      as_backslashed_symbol_character:
        mov     al,ah
        stos    as_u8 [edi]
        inc     as_u8 [ecx]
        jmp     as_convert_line_data
      as_concatenate_lines:
        lods    as_u8 [esi]
        cmp     al,20h
        if_equal        as_concatenate_lines
        cmp     al,9
        if_equal        as_concatenate_lines
        cmp     al,1Ah
        if_equal        as_line_end
        or      al,al
        if_zero as_line_end
        cmp     al,0Ah
        if_equal        as_concatenate_lf
        cmp     al,0Dh
        if_equal        as_concatenate_cr
        cmp     al,3Bh
        if_not_equal    as_extra_characters_on_line
      as_find_concatenated_line:
        lods    as_u8 [esi]
        cmp     al,0Ah
        if_equal        as_concatenate_lf
        cmp     al,0Dh
        if_equal        as_concatenate_cr
        or      al,al
        if_zero as_concatenate_ok
        cmp     al,1Ah
        if_not_equal    as_find_concatenated_line
        jmp     as_line_end
      as_concatenate_lf:
        lods    as_u8 [esi]
        cmp     al,0Dh
        if_equal        as_concatenate_ok
        dec     esi
        jmp     as_concatenate_ok
      as_concatenate_cr:
        lods    as_u8 [esi]
        cmp     al,0Ah
        if_equal        as_concatenate_ok
        dec     esi
      as_concatenate_ok:
        inc     as_u32 [esp]
        jmp     as_convert_line_data
      as_ignore_comment:
        lods    as_u8 [esi]
        cmp     al,0Ah
        if_equal        as_lf_character
        cmp     al,0Dh
        if_equal        as_cr_character
        or      al,al
        if_zero as_line_end
        cmp     al,1Ah
        if_not_equal    as_ignore_comment
      as_line_end:
        xor     al,al
        stos    as_u8 [edi]
        pop     ecx
        ret

as_lower_case:
        mov     edi,as_converted
        mov     ebx,as_characters
      as_convert_case:
        lods    as_u8 [esi]
        translate_byte  as_u8 [ebx]
        stos    as_u8 [edi]
        loop    as_convert_case
      as_case_ok:
        ret

as_get_directive:
        push    edi
        mov     edx,esi
        mov     ebp,ecx
        call    as_lower_case
        pop     edi
      as_scan_directives:
        mov     esi,as_converted
        movzx   eax,as_u8 [edi]
        or      al,al
        if_zero as_no_directive
        mov     ecx,ebp
        inc     edi
        mov     ebx,edi
        add     ebx,eax
        mov     ah,[esi]
        cmp     ah,[edi]
        if_below        as_no_directive
        if_above        as_next_directive
        cmp     cl,al
        if_not_equal    as_next_directive
        repe    cmps as_u8 [esi],[edi]
        if_below        as_no_directive
        if_equal        as_directive_found
      as_next_directive:
        mov     edi,ebx
        add     edi,2
        jmp     as_scan_directives
      as_no_directive:
        mov     esi,edx
        mov     ecx,ebp
        set_carry
        ret
      as_directive_found:
        call    as_get_directive_handler_base
      as_directive_handler:
        lea     esi,[edx+ebp]
        movzx   ecx,as_u16 [ebx]
        add     eax,ecx
        clear_carry
        ret
      as_get_directive_handler_base:
        mov     eax,[esp]
        ret

as_preprocess_line:
        mov     eax,esp
        sub     eax,[as_stack_limit]
        cmp     eax,100h
        if_below        as_stack_overflow
        push    ecx esi
      as_preprocess_current_line:
        mov     esi,[as_current_line]
        add     esi,16
        cmp     as_u16 [esi],3Bh
        if_not_equal    as_line_start_ok
        add     esi,2
      as_line_start_ok:
        cmp     as_u8 [esi],1Ah
        if_not_equal    as_not_fix_constant
        movzx   edx,as_u8 [esi+1]
        lea     edx,[esi+2+edx]
        cmp     as_u16 [edx],031Ah
        if_not_equal    as_not_fix_constant
        mov     ebx,as_characters
        movzx   eax,as_u8 [edx+2]
        translate_byte  as_u8 [ebx]
        ror     eax,8
        mov     al,[edx+3]
        translate_byte  as_u8 [ebx]
        ror     eax,8
        mov     al,[edx+4]
        translate_byte  as_u8 [ebx]
        ror     eax,16
        cmp     eax,'fix'
        if_equal        as_define_fix_constant
      as_not_fix_constant:
        call    as_process_fix_constants
      as_initial_preprocessing_ok:
        mov     esi,[as_current_line]
        add     esi,16
      as_preprocess_instruction:
        mov     [as_current_offset],esi
        lods    as_u8 [esi]
        movzx   ecx,as_u8 [esi]
        inc     esi
        cmp     al,1Ah
        if_not_equal    as_not_preprocessor_symbol
        cmp     cl,3
        if_below        as_not_preprocessor_directive
        push    edi
        mov     edi,as_preprocessor_directives
        call    as_get_directive
        pop     edi
        if_carry        as_not_preprocessor_directive
        mov     as_u8 [edx-2],3Bh
        jmp     near eax
      as_not_preprocessor_directive:
      as_not_macro:
        mov     [as_struc_name],esi
        add     esi,ecx
        lods    as_u8 [esi]
        cmp     al,':'
        if_equal        as_preprocess_label
        cmp     al,1Ah
        if_not_equal    as_not_preprocessor_symbol
        lods    as_u8 [esi]
        cmp     al,3
        if_not_equal    as_not_symbolic_constant
        mov     ebx,as_characters
        movzx   eax,as_u8 [esi]
        translate_byte  as_u8 [ebx]
        ror     eax,8
        mov     al,[esi+1]
        translate_byte  as_u8 [ebx]
        ror     eax,8
        mov     al,[esi+2]
        translate_byte  as_u8 [ebx]
        ror     eax,16
        cmp     eax,'equ'
        if_equal        as_define_equ_constant
        mov     al,3
      as_not_symbolic_constant:
        jmp     as_not_preprocessor_symbol
      as_preprocess_label:
        dec     esi
        sub     esi,ecx
        lea     ebp,[esi-2]
        mov     ch,10b
        call    as_get_preprocessor_symbol
        if_not_carry    as_symbolic_constant_in_label
        lea     esi,[esi+ecx+1]
        cmp     as_u8 [esi],':'
        if_not_equal    as_preprocess_instruction
        inc     esi
        jmp     as_preprocess_instruction
      as_symbolic_constant_in_label:
        test    edx,edx
        if_zero as_reserved_word_used_as_symbol
        mov     ebx,[edx+8]
        mov     ecx,[edx+12]
        add     ecx,ebx
      as_check_for_broken_label:
        cmp     ebx,ecx
        if_equal        as_label_broken
        cmp     as_u8 [ebx],1Ah
        if_not_equal    as_label_broken
        movzx   eax,as_u8 [ebx+1]
        lea     ebx,[ebx+2+eax]
        cmp     ebx,ecx
        if_equal        as_label_constant_ok
        cmp     as_u8 [ebx],':'
        if_not_equal    as_label_broken
        inc     ebx
        cmp     as_u8 [ebx],':'
        if_not_equal    as_check_for_broken_label
        inc     ebx
        jmp     as_check_for_broken_label
      as_label_broken:
        call    as_replace_symbolic_constant
        jmp     as_line_preprocessed
      as_label_constant_ok:
        mov     ecx,edi
        sub     ecx,esi
        mov     edi,[edx+12]
        add     edi,ebp
        push    edi
        lea     eax,[edi+ecx]
        push    eax
        cmp     esi,edi
        if_equal        as_replace_label
        if_below        as_move_rest_of_line_up
        rep     movs as_u8 [edi],[esi]
        jmp     as_replace_label
      as_move_rest_of_line_up:
        lea     esi,[esi+ecx-1]
        lea     edi,[edi+ecx-1]
        set_direction
        rep     movs as_u8 [edi],[esi]
        clear_direction
      as_replace_label:
        mov     ecx,[edx+12]
        mov     edi,[esp+4]
        sub     edi,ecx
        mov     esi,[edx+8]
        rep     movs as_u8 [edi],[esi]
        pop     edi esi
        inc     esi
        jmp     as_preprocess_instruction
      as_not_preprocessor_symbol:
        mov     esi,[as_current_offset]
        call    as_process_equ_constants
      as_line_preprocessed:
        pop     esi ecx
        ret

as_get_preprocessor_symbol:
        push    ebp edi esi
        mov     ebp,ecx
        shl     ebp,22
        mov     al,ch
        and     al,11b
        movzx   ecx,cl
        cmp     al,10b
        if_not_equal    as_no_preprocessor_special_symbol
        cmp     cl,4
        if_below_equal  as_no_preprocessor_special_symbol
        mov     ax,'__'
        cmp     ax,[esi]
        if_not_equal    as_no_preprocessor_special_symbol
        cmp     ax,[esi+ecx-2]
        if_not_equal    as_no_preprocessor_special_symbol
        add     esi,2
        sub     ecx,4
        push    ebp
        mov     edi,as_preprocessor_special_symbols
        call    as_get_directive
        pop     ebp
        if_carry        as_preprocessor_special_symbol_not_recognized
        add     esi,2
        xor     edx,edx
        jmp     as_preprocessor_symbol_found
      as_preprocessor_special_symbol_not_recognized:
        add     ecx,4
        sub     esi,2
      as_no_preprocessor_special_symbol:
        mov     ebx,as_hash_tree
        mov     edi,10
      as_follow_hashes_roots:
        mov     edx,[ebx]
        or      edx,edx
        if_zero as_preprocessor_symbol_not_found
        xor     eax,eax
        shl     ebp,1
        add_with_carry  eax,0
        lea     ebx,[edx+eax*4]
        dec     edi
        if_not_zero     as_follow_hashes_roots
        mov     edi,ebx
        call    as_calculate_hash
        mov     ebp,eax
        and     ebp,3FFh
        shl     ebp,10
        xor     ebp,eax
        mov     ebx,edi
        mov     edi,22
      as_follow_hashes_tree:
        mov     edx,[ebx]
        or      edx,edx
        if_zero as_preprocessor_symbol_not_found
        xor     eax,eax
        shl     ebp,1
        add_with_carry  eax,0
        lea     ebx,[edx+eax*4]
        dec     edi
        if_not_zero     as_follow_hashes_tree
        mov     al,cl
        mov     edx,[ebx]
        or      edx,edx
        if_zero as_preprocessor_symbol_not_found
      as_compare_with_preprocessor_symbol:
        mov     edi,[edx+4]
        cmp     edi,1
        if_below_equal  as_next_equal_hash
        repe    cmps as_u8 [esi],[edi]
        if_equal        as_preprocessor_symbol_found
        mov     cl,al
        mov     esi,[esp]
      as_next_equal_hash:
        mov     edx,[edx]
        or      edx,edx
        if_not_zero     as_compare_with_preprocessor_symbol
      as_preprocessor_symbol_not_found:
        pop     esi edi ebp
        set_carry
        ret
      as_preprocessor_symbol_found:
        pop     ebx edi ebp
        clear_carry
        ret
      as_calculate_hash:
        xor     ebx,ebx
        mov     eax,2166136261
        mov     ebp,16777619
      as_fnv1a_hash:
        xor     al,[esi+ebx]
        mul     ebp
        inc     bl
        cmp     bl,cl
        if_below        as_fnv1a_hash
        ret
as_add_preprocessor_symbol:
        push    edi esi
        xor     eax,eax
        or      cl,cl
        if_zero as_reshape_hash
        cmp     ch,11b
        if_equal        as_preprocessor_symbol_name_ok
        push    ecx
        movzx   ecx,cl
        mov     edi,as_preprocessor_directives
        call    as_get_directive
        if_not_carry    as_reserved_word_used_as_symbol
        pop     ecx
      as_preprocessor_symbol_name_ok:
        call    as_calculate_hash
      as_reshape_hash:
        mov     ebp,eax
        and     ebp,3FFh
        shr     eax,10
        xor     ebp,eax
        shl     ecx,22
        or      ebp,ecx
        mov     ebx,as_hash_tree
        mov     ecx,32
      as_find_leave_for_symbol:
        mov     edx,[ebx]
        or      edx,edx
        if_zero as_extend_hashes_tree
        xor     eax,eax
        rol     ebp,1
        add_with_carry  eax,0
        lea     ebx,[edx+eax*4]
        dec     ecx
        if_not_zero     as_find_leave_for_symbol
        mov     edx,[ebx]
        or      edx,edx
        if_zero as_add_symbol_entry
        shr     ebp,30
        cmp     ebp,11b
        if_equal        as_reuse_symbol_entry
        cmp     as_u32 [edx+4],0
        if_not_equal    as_add_symbol_entry
      as_find_entry_to_reuse:
        mov     edi,[edx]
        or      edi,edi
        if_zero as_reuse_symbol_entry
        cmp     as_u32 [edi+4],0
        if_not_equal    as_reuse_symbol_entry
        mov     edx,edi
        jmp     as_find_entry_to_reuse
      as_add_symbol_entry:
        mov     eax,edx
        mov     edx,[as_labels_list]
        sub     edx,16
        cmp     edx,[as_free_additional_memory]
        if_below        as_out_of_memory
        mov     [as_labels_list],edx
        mov     [edx],eax
        mov     [ebx],edx
      as_reuse_symbol_entry:
        pop     esi edi
        mov     [edx+4],esi
        ret
      as_extend_hashes_tree:
        mov     edx,[as_labels_list]
        sub     edx,8
        cmp     edx,[as_free_additional_memory]
        if_below        as_out_of_memory
        mov     [as_labels_list],edx
        xor     eax,eax
        mov     [edx],eax
        mov     [edx+4],eax
        shl     ebp,1
        add_with_carry  eax,0
        mov     [ebx],edx
        lea     ebx,[edx+eax*4]
        dec     ecx
        if_not_zero     as_extend_hashes_tree
        mov     edx,[as_labels_list]
        sub     edx,16
        cmp     edx,[as_free_additional_memory]
        if_below        as_out_of_memory
        mov     [as_labels_list],edx
        mov     as_u32 [edx],0
        mov     [ebx],edx
        pop     esi edi
        mov     [edx+4],esi
        ret

as_define_fix_constant:
        add     edx,5
        add     esi,2
        push    edx
        mov     ch,11b
        jmp     as_define_preprocessor_constant
as_define_equ_constant:
        add     esi,3
        push    esi
        call    as_process_equ_constants
        mov     esi,[as_struc_name]
        mov     ch,10b
      as_define_preprocessor_constant:
        mov     as_u8 [esi-2],3Bh
        mov     cl,[esi-1]
        call    as_add_preprocessor_symbol
        pop     ebx
        mov     ecx,edi
        dec     ecx
        sub     ecx,ebx
        mov     [edx+8],ebx
        mov     [edx+12],ecx
        jmp     as_line_preprocessed
as_define_symbolic_constant:
        lods    as_u8 [esi]
        cmp     al,1Ah
        if_not_equal    as_invalid_name
        lods    as_u8 [esi]
        mov     cl,al
        mov     ch,10b
        call    as_add_preprocessor_symbol
        movzx   eax,as_u8 [esi-1]
        add     esi,eax
        lea     ecx,[edi-1]
        sub     ecx,esi
        mov     [edx+8],esi
        mov     [edx+12],ecx
        jmp     as_line_preprocessed

as_restore_equ_constant:
        mov     ch,10b
      as_restore_preprocessor_symbol:
        push    ecx
        lods    as_u8 [esi]
        cmp     al,1Ah
        if_not_equal    as_invalid_name
        lods    as_u8 [esi]
        mov     cl,al
        call    as_get_preprocessor_symbol
        if_carry        as_no_symbol_to_restore
        test    edx,edx
        if_zero as_symbol_restored
        mov     as_u32 [edx+4],0
        jmp     as_symbol_restored
      as_no_symbol_to_restore:
        add     esi,ecx
      as_symbol_restored:
        pop     ecx
        lods    as_u8 [esi]
        cmp     al,','
        if_equal        as_restore_preprocessor_symbol
        or      al,al
        if_not_zero     as_extra_characters_on_line
        jmp     as_line_preprocessed

as_process_fix_constants:
        mov     [as_value_type],11b
        jmp     as_process_symbolic_constants
as_process_equ_constants:
        mov     [as_value_type],10b
      as_process_symbolic_constants:
        mov     ebp,esi
        lods    as_u8 [esi]
        cmp     al,1Ah
        if_equal        as_check_symbol
        cmp     al,22h
        if_equal        as_ignore_string
        cmp     al,'{'
        if_equal        as_check_brace
        or      al,al
        if_not_zero     as_process_symbolic_constants
        ret
      as_ignore_string:
        lods    as_u32 [esi]
        add     esi,eax
        jmp     as_process_symbolic_constants
      as_check_brace:
        test    [as_value_type],80h
        if_zero as_process_symbolic_constants
        ret
      as_no_replacing:
        movzx   ecx,as_u8 [esi-1]
        add     esi,ecx
        jmp     as_process_symbolic_constants
      as_check_symbol:
        mov     cl,[esi]
        inc     esi
        mov     ch,[as_value_type]
        call    as_get_preprocessor_symbol
        if_carry        as_no_replacing
        mov     [as_current_section],edi
      as_replace_symbolic_constant:
        test    edx,edx
        if_zero as_replace_special_symbolic_constant
        mov     ecx,[edx+12]
        mov     edx,[edx+8]
        xchg    esi,edx
        call    as_move_data
        mov     esi,edx
      as_process_after_replaced:
        lods    as_u8 [esi]
        cmp     al,1Ah
        if_equal        as_symbol_after_replaced
        stos    as_u8 [edi]
        cmp     al,22h
        if_equal        as_string_after_replaced
        cmp     al,'{'
        if_equal        as_brace_after_replaced
        or      al,al
        if_not_zero     as_process_after_replaced
        mov     ecx,edi
        sub     ecx,esi
        mov     edi,ebp
        call    as_move_data
        mov     esi,edi
        ret
      as_move_data:
        lea     eax,[edi+ecx]
        cmp     eax,[as_memory_end]
        if_above_equal  as_out_of_memory
        shr     ecx,1
        if_not_carry    as_movsb_ok
        movs    as_u8 [edi],[esi]
      as_movsb_ok:
        shr     ecx,1
        if_not_carry    as_movsw_ok
        movs    as_u16 [edi],[esi]
      as_movsw_ok:
        rep     movs as_u32 [edi],[esi]
        ret
      as_string_after_replaced:
        lods    as_u32 [esi]
        stos    as_u32 [edi]
        mov     ecx,eax
        call    as_move_data
        jmp     as_process_after_replaced
      as_brace_after_replaced:
        test    [as_value_type],80h
        if_zero as_process_after_replaced
        mov     edx,edi
        mov     ecx,[as_current_section]
        sub     edx,ecx
        sub     ecx,esi
        rep     movs as_u8 [edi],[esi]
        mov     ecx,edi
        sub     ecx,esi
        mov     edi,ebp
        call    as_move_data
        lea     esi,[ebp+edx]
        ret
      as_symbol_after_replaced:
        mov     cl,[esi]
        inc     esi
        mov     ch,[as_value_type]
        call    as_get_preprocessor_symbol
        if_not_carry    as_replace_symbolic_constant
        movzx   ecx,as_u8 [esi-1]
        mov     al,1Ah
        mov     ah,cl
        stos    as_u16 [edi]
        call    as_move_data
        jmp     as_process_after_replaced
      as_replace_special_symbolic_constant:
        jmp     near eax
      as_preprocessed_file_value:
        call    as_get_current_line_from_file
        test    ebx,ebx
        if_zero as_process_after_replaced
        push    esi edi
        mov     esi,[ebx]
        mov     edi,esi
        xor     al,al
        or      ecx,-1
        repne   scas as_u8 [edi]
        add     ecx,2
        negate  ecx
        pop     edi
        lea     eax,[edi+1+4+ecx]
        cmp     eax,[as_memory_end]
        if_above        as_out_of_memory
        mov     al,22h
        stos    as_u8 [edi]
        mov     eax,ecx
        stos    as_u32 [edi]
        rep     movs as_u8 [edi],[esi]
        pop     esi
        jmp     as_process_after_replaced
      as_preprocessed_line_value:
        call    as_get_current_line_from_file
        test    ebx,ebx
        if_zero as_process_after_replaced
        lea     eax,[edi+1+4+20]
        cmp     eax,[as_memory_end]
        if_above        as_out_of_memory
        mov     ecx,[ebx+4]
        call    as_store_number_symbol
        jmp     as_process_after_replaced
as_store_number_symbol:
        push    eax ebx ecx edx
        mov     al,1Ah
        stos    as_u8 [edi]
        mov     ebx,edi
        xor     al,al
        stos    as_u8 [edi]
        mov     eax,ecx
        xor     ecx,ecx
        or      eax,eax
        if_not_zero     as_store_number_digits
        push    0
        inc     ecx
        jmp     as_store_number_emit
      as_store_number_digits:
        xor     edx,edx
        push    ecx
        mov     ecx,10
        div     ecx
        pop     ecx
        push    edx
        inc     ecx
        or      eax,eax
        if_not_zero     as_store_number_digits
      as_store_number_emit:
        mov     [ebx],cl
      as_store_number_emit_loop:
        pop     edx
        add     dl,'0'
        mov     [edi],dl
        inc     edi
        loop    as_store_number_emit_loop
        pop     edx ecx ebx eax
        ret
      as_get_current_line_from_file:
        mov     ebx,[as_current_line]
      as_find_line_from_file:
        test    ebx,ebx
        if_zero as_line_from_file_found
        test    as_u8 [ebx+7],80h
        if_zero as_line_from_file_found
        mov     ebx,[ebx+8]
        jmp     as_find_line_from_file
      as_line_from_file_found:
        ret

as_include_file:
        lods    as_u8 [esi]
        cmp     al,22h
        if_not_equal    as_invalid_argument
        lods    as_u32 [esi]
        cmp     as_u8 [esi+eax],0
        if_not_equal    as_extra_characters_on_line
        push    esi
        push    edi
        mov     ebx,[as_current_line]
      as_find_current_file_path:
        mov     esi,[ebx]
        test    as_u8 [ebx+7],80h
        if_zero as_copy_current_file_path
        mov     ebx,[ebx+8]
        jmp     as_find_current_file_path
      as_copy_current_file_path:
        lods    as_u8 [esi]
        stos    as_u8 [edi]
        or      al,al
        if_not_zero     as_copy_current_file_path
      as_cut_current_file_name:
        cmp     edi,[esp]
        if_equal        as_current_file_path_ok
        cmp     as_u8 [edi-1],'\'
        if_equal        as_current_file_path_ok
        cmp     as_u8 [edi-1],'/'
        if_equal        as_current_file_path_ok
        dec     edi
        jmp     as_cut_current_file_name
      as_current_file_path_ok:
        mov     esi,[esp+4]
        call    as_expand_path
        pop     edx
        mov     esi,edx
        call    as_open
        if_not_carry    as_include_path_ok
        mov     ebp,[as_include_paths]
      as_try_include_directories:
        mov     edi,esi
        mov     esi,ebp
        cmp     as_u8 [esi],0
        if_equal        as_try_in_current_directory
        push    ebp
        push    edi
        call    as_get_include_directory
        mov     [esp+4],esi
        mov     esi,[esp+8]
        call    as_expand_path
        pop     edx
        mov     esi,edx
        call    as_open
        pop     ebp
        if_not_carry    as_include_path_ok
        jmp     as_try_include_directories
        mov     edi,esi
      as_try_in_current_directory:
        mov     esi,[esp]
        push    edi
        call    as_expand_path
        pop     edx
        mov     esi,edx
        call    as_open
        if_carry        as_file_not_found
      as_include_path_ok:
        mov     edi,[esp]
      as_copy_preprocessed_path:
        lods    as_u8 [esi]
        stos    as_u8 [edi]
        or      al,al
        if_not_zero     as_copy_preprocessed_path
        pop     esi
        lea     ecx,[edi-1]
        sub     ecx,esi
        mov     [esi-4],ecx
        push    as_u32 [as_macro_status]
        and     [as_macro_status],0Fh
        call    as_preprocess_file
        pop     eax
        and     al,0F0h
        and     [as_macro_status],0Fh
        or      [as_macro_status],al
        jmp     as_line_preprocessed
