; SPDX-License-Identifier: BSD-2-Clause
; Copyright (c) 2026 danko1122q
; All rights reserved.

as_assembler:
        xor     eax,eax
        mov     [as_stub_size],eax
        mov     [as_current_pass],ax
        mov     [as_resolver_flags],eax
        mov     [as_number_of_sections],eax
        mov     [as_actual_fixups_size],eax
      as_assembler_loop:
        mov     eax,[as_labels_list]
        mov     [as_tagged_blocks],eax
        mov     eax,[as_additional_memory]
        mov     [as_free_additional_memory],eax
        mov     eax,[as_additional_memory_end]
        mov     [as_structures_buffer],eax
        mov     esi,[as_source_start]
        mov     edi,[as_code_start]
        xor     eax,eax
        mov     as_u32 [as_adjustment],eax
        mov     as_u32 [as_adjustment+4],eax
        mov     [as_addressing_space],eax
        mov     [as_error_line],eax
        mov     [as_counter],eax
        mov     [as_format_flags],eax
        mov     [as_number_of_relocations],eax
        mov     [as_undefined_data_end],eax
        mov     [as_file_extension],eax
        mov     [as_next_pass_needed],al
        mov     [as_output_format],al
        mov     [as_adjustment_sign],al
        mov     [as_evex_mode],al
        mov     [as_code_type],16
        call    as_init_addressing_space
      as_pass_loop:
        call    as_assemble_line
        if_not_carry    as_pass_loop
        mov     eax,[as_additional_memory_end]
        cmp     eax,[as_structures_buffer]
        if_equal        as_pass_done
        sub     eax,18h
        mov     eax,[eax+4]
        mov     [as_current_line],eax
        jmp     as_missing_end_directive
      as_pass_done:
        call    as_close_pass
        mov     eax,[as_labels_list]
      as_check_symbols:
        cmp     eax,[as_memory_end]
        if_above_equal  as_symbols_checked
        test    as_u8 [eax+8],8
        if_zero as_symbol_defined_ok
        mov     cx,[as_current_pass]
        cmp     cx,[eax+18]
        if_not_equal    as_symbol_defined_ok
        test    as_u8 [eax+8],1
        if_zero as_symbol_defined_ok
        sub     cx,[eax+16]
        cmp     cx,1
        if_not_equal    as_symbol_defined_ok
        and     as_u8 [eax+8],not 1
        or      [as_next_pass_needed],-1
      as_symbol_defined_ok:
        test    as_u8 [eax+8],10h
        if_zero as_use_prediction_ok
        mov     cx,[as_current_pass]
        and     as_u8 [eax+8],not 10h
        test    as_u8 [eax+8],20h
        if_not_zero     as_check_use_prediction
        cmp     cx,[eax+18]
        if_not_equal    as_use_prediction_ok
        test    as_u8 [eax+8],8
        if_zero as_use_prediction_ok
        jmp     as_use_misprediction
      as_check_use_prediction:
        test    as_u8 [eax+8],8
        if_zero as_use_misprediction
        cmp     cx,[eax+18]
        if_equal        as_use_prediction_ok
      as_use_misprediction:
        or      [as_next_pass_needed],-1
      as_use_prediction_ok:
        test    as_u8 [eax+8],40h
        if_zero as_check_next_symbol
        and     as_u8 [eax+8],not 40h
        test    as_u8 [eax+8],4
        if_not_zero     as_define_misprediction
        mov     cx,[as_current_pass]
        test    as_u8 [eax+8],80h
        if_not_zero     as_check_define_prediction
        cmp     cx,[eax+16]
        if_not_equal    as_check_next_symbol
        test    as_u8 [eax+8],1
        if_zero as_check_next_symbol
        jmp     as_define_misprediction
      as_check_define_prediction:
        test    as_u8 [eax+8],1
        if_zero as_define_misprediction
        cmp     cx,[eax+16]
        if_equal        as_check_next_symbol
      as_define_misprediction:
        or      [as_next_pass_needed],-1
      as_check_next_symbol:
        add     eax,LABEL_STRUCTURE_SIZE
        jmp     as_check_symbols
      as_symbols_checked:
        cmp     [as_next_pass_needed],0
        if_not_equal    as_next_pass
        mov     eax,[as_error_line]
        or      eax,eax
        if_zero as_assemble_ok
        mov     [as_current_line],eax
        cmp     [as_error],as_undefined_symbol
        if_not_equal    as_error_confirmed
        mov     eax,[as_error_info]
        or      eax,eax
        if_zero as_error_confirmed
        test    as_u8 [eax+8],1
        if_not_zero     as_next_pass
      as_error_confirmed:
        call    as_error_handler
      as_error_handler:
        mov     eax,[as_error]
        sub     eax,as_error_handler
        add     [esp],eax
        ret
      as_next_pass:
        inc     [as_current_pass]
        mov     ax,[as_current_pass]
        cmp     ax,[as_passes_limit]
        if_equal        as_code_cannot_be_generated
        jmp     as_assembler_loop
      as_assemble_ok:
        ret

as_create_addressing_space:
        mov     ebx,[as_addressing_space]
        test    ebx,ebx
        if_zero as_init_addressing_space
        test    as_u8 [ebx+0Ah],1
        if_not_zero     as_illegal_instruction
        mov     eax,edi
        sub     eax,[ebx+18h]
        mov     [ebx+1Ch],eax
      as_init_addressing_space:
        mov     ebx,[as_tagged_blocks]
        mov     as_u32 [ebx-4],10h
        mov     as_u32 [ebx-8],24h
        sub     ebx,8+24h
        cmp     ebx,edi
        if_below_equal  as_out_of_memory
        mov     [as_tagged_blocks],ebx
        mov     [as_addressing_space],ebx
        ; initialize addressing-space block: base pointers, zero all fields
        xor     eax, eax
        ; [+00] and [+18h] hold the free-pointer (edi); all others start zero
        mov     [ebx+00h], edi          ; as_space.code_start
        mov     [ebx+04h], eax          ; as_space.code_flags
        mov     [ebx+08h], eax          ; as_space.org_origin
        mov     [ebx+10h], eax          ; as_space.virtual_start
        mov     [ebx+14h], eax          ; as_space.virtual_size
        mov     [ebx+18h], edi          ; as_space.output_ptr
        mov     [ebx+1Ch], eax          ; as_space.section_index
        mov     [ebx+20h], eax          ; as_space.reloc_count
        ret

as_assemble_line:
        mov     eax,[as_tagged_blocks]
        sub     eax,100h
        cmp     edi,eax
        if_above        as_out_of_memory
        lods    as_u8 [esi]
        cmp     al,1
        if_equal        as_assemble_instruction
        if_below        as_source_end
        cmp     al,3
        if_below        as_define_label
        if_equal        as_define_constant
        cmp     al,4
        if_equal        as_label_addressing_space
        cmp     al,0Fh
        if_equal        as_new_line
        cmp     al,13h
        if_equal        as_code_type_setting
        cmp     al,10h
        if_not_equal    as_illegal_instruction
        lods    as_u8 [esi]
        jmp     as_segment_prefix
      as_code_type_setting:
        lods    as_u8 [esi]
        mov     [as_code_type],al
        jmp     as_instruction_assembled
      as_new_line:
        lods    as_u32 [esi]
        mov     [as_current_line],eax
        and     [as_prefix_flags],0
        cmp     [as_symbols_file],0
        if_equal        as_continue_line
        cmp     [as_next_pass_needed],0
        if_not_equal    as_continue_line
        mov     ebx,[as_tagged_blocks]
        mov     as_u32 [ebx-4],1
        mov     as_u32 [ebx-8],14h
        sub     ebx,8+14h
        cmp     ebx,edi
        if_below_equal  as_out_of_memory
        mov     [as_tagged_blocks],ebx
        mov     [ebx],eax
        mov     [ebx+4],edi
        mov     eax,[as_addressing_space]
        mov     [ebx+8],eax
        mov     al,[as_code_type]
        mov     [ebx+10h],al
      as_continue_line:
        cmp     as_u8 [esi],0Fh
        if_equal        as_line_assembled
        jmp     as_assemble_line
      as_define_label:
        lods    as_u32 [esi]
        cmp     eax,0Fh
        if_below        as_invalid_use_of_symbol
        if_equal        as_reserved_word_used_as_symbol
        mov     ebx,eax
        lods    as_u8 [esi]
        mov     [as_label_size],al
        call    as_make_label
        jmp     as_continue_line
      as_make_label:
        mov     eax,edi
        xor     edx,edx
        xor     cl,cl
        mov     ebp,[as_addressing_space]
        sub     eax,[ds:ebp]
        sub_with_borrow edx,[ds:ebp+4]
        sub_with_borrow cl,[ds:ebp+8]
        jp      as_label_value_ok
        call    as_recoverable_overflow
      as_label_value_ok:
        mov     [as_address_sign],cl
        test    as_u8 [ds:ebp+0Ah],1
        if_not_zero     as_make_virtual_label
        or      as_u8 [ebx+9],1
        xchg    eax,[ebx]
        xchg    edx,[ebx+4]
        mov     ch,[ebx+9]
        shr     ch,1
        and     ch,1
        negate  ch
        sub     eax,[ebx]
        sub_with_borrow edx,[ebx+4]
        sub_with_borrow ch,cl
        mov     as_u32 [as_adjustment],eax
        mov     as_u32 [as_adjustment+4],edx
        mov     [as_adjustment_sign],ch
        or      al,ch
        or      eax,edx
        setnz   ah
        jmp     as_finish_label
      as_make_virtual_label:
        and     as_u8 [ebx+9],not 1
        cmp     eax,[ebx]
        mov     [ebx],eax
        setne   ah
        cmp     edx,[ebx+4]
        mov     [ebx+4],edx
        setne   al
        or      ah,al
      as_finish_label:
        mov     ebp,[as_addressing_space]
        mov     ch,[ds:ebp+9]
        mov     cl,[as_label_size]
        mov     edx,[ds:ebp+14h]
        mov     ebp,[ds:ebp+10h]
      as_finish_label_symbol:
        ; update sign flag, size, type, address — track if any field changed
        ; inline: sign_update [ebx+9], [as_address_sign], 10b
        mov     al,[as_address_sign]
        xor     al,[ebx+9]
        and     al,10b
        or      ah,al
        xor     [ebx+9],al
        ; inline: update_field [ebx+10], cl, al
        cmp     cl,[ebx+10]
        mov     [ebx+10],cl
        setne   al
        or      ah,al
        ; inline: update_field [ebx+11], ch, al
        cmp     ch,[ebx+11]
        mov     [ebx+11],ch
        setne   al
        or      ah,al
        ; inline: update_field [ebx+12], ebp, al
        cmp     ebp,[ebx+12]
        mov     [ebx+12],ebp
        setne   al
        or      ah,al
        or      ch,ch
        if_zero as_label_symbol_ok
        cmp     edx,[ebx+20]
        mov     [ebx+20],edx
        setne   al
        or      ah,al
      as_label_symbol_ok:
        mov     cx,[as_current_pass]
        xchg    [ebx+16],cx
        mov     edx,[as_current_line]
        mov     [ebx+28],edx
        and     as_u8 [ebx+8],not 2
        test    as_u8 [ebx+8],1
        if_zero as_new_label
        cmp     cx,[ebx+16]
        if_equal        as_symbol_already_defined
        bit_test_reset  as_u32 [ebx+8],10
        if_carry        as_requalified_label
        inc     cx
        sub     cx,[ebx+16]
        setnz   al
        or      ah,al
        if_zero as_label_made
        test    as_u8 [ebx+8],8
        if_zero as_label_made
        mov     cx,[as_current_pass]
        cmp     cx,[ebx+18]
        if_not_equal    as_label_made
      as_requalified_label:
        or      [as_next_pass_needed],-1
      as_label_made:
        ret
      as_new_label:
        or      as_u8 [ebx+8],1
        ret
      as_define_constant:
        lods    as_u32 [esi]
        inc     esi
        cmp     eax,0Fh
        if_below        as_invalid_use_of_symbol
        if_equal        as_reserved_word_used_as_symbol
        push    eax
        or      [as_operand_flags],1
        call    as_get_value
        pop     ebx
        xor     cl,cl
        mov     ch,[as_value_type]
        cmp     ch,3
        if_equal        as_invalid_use_of_symbol
      as_make_constant:
        and     as_u8 [ebx+9],not 1
        cmp     eax,[ebx]
        mov     [ebx],eax
        setne   ah
        cmp     edx,[ebx+4]
        mov     [ebx+4],edx
        setne   al
        or      ah,al
        ; update sign flag, size, type — track if any field changed
        ; inline: sign_update [ebx+9], [as_value_sign], 10b
        mov     al,[as_value_sign]
        xor     al,[ebx+9]
        and     al,10b
        or      ah,al
        xor     [ebx+9],al
        ; inline: update_field [ebx+10], cl, al
        cmp     cl,[ebx+10]
        mov     [ebx+10],cl
        setne   al
        or      ah,al
        ; inline: update_field [ebx+11], ch, al
        cmp     ch,[ebx+11]
        mov     [ebx+11],ch
        setne   al
        or      ah,al
        ; constant has no address component — zero the field
        xor     edx,edx
        ; inline: update_field [ebx+12], edx, al
        cmp     edx,[ebx+12]
        mov     [ebx+12],edx
        setne   al
        or      ah,al
        or      ch,ch
        if_zero as_constant_symbol_ok
        mov     edx,[as_symbol_identifier]
        cmp     edx,[ebx+20]
        mov     [ebx+20],edx
        setne   al
        or      ah,al
      as_constant_symbol_ok:
        mov     cx,[as_current_pass]
        xchg    [ebx+16],cx
        mov     edx,[as_current_line]
        mov     [ebx+28],edx
        test    as_u8 [ebx+8],1
        if_zero as_new_constant
        cmp     cx,[ebx+16]
        if_not_equal    as_redeclare_constant
        test    as_u8 [ebx+8],2
        if_zero as_symbol_already_defined
        or      as_u8 [ebx+8],4
        and     as_u8 [ebx+9],not 4
        jmp     as_instruction_assembled
      as_redeclare_constant:
        bit_test_reset  as_u32 [ebx+8],10
        if_carry        as_requalified_constant
        inc     cx
        sub     cx,[ebx+16]
        setnz   al
        or      ah,al
        if_zero as_instruction_assembled
        test    as_u8 [ebx+8],4
        if_not_zero     as_instruction_assembled
        test    as_u8 [ebx+8],8
        if_zero as_instruction_assembled
        mov     cx,[as_current_pass]
        cmp     cx,[ebx+18]
        if_not_equal    as_instruction_assembled
      as_requalified_constant:
        or      [as_next_pass_needed],-1
        jmp     as_instruction_assembled
      as_new_constant:
        or      as_u8 [ebx+8],1+2
        jmp     as_instruction_assembled
      as_label_addressing_space:
        lods    as_u32 [esi]
        cmp     eax,0Fh
        if_below        as_invalid_use_of_symbol
        if_equal        as_reserved_word_used_as_symbol
        mov     cx,[as_current_pass]
        test    as_u8 [eax+8],1
        if_zero as_make_addressing_space_label
        cmp     cx,[eax+16]
        if_equal        as_symbol_already_defined
        test    as_u8 [eax+9],4
        if_not_zero     as_make_addressing_space_label
        or      [as_next_pass_needed],-1
      as_make_addressing_space_label:
        mov     dx,[eax+8]
        and     dx,not (2 or 100h)
        or      dx,1 or 4 or 400h
        mov     [eax+8],dx
        mov     [eax+16],cx
        mov     edx,[as_current_line]
        mov     [eax+28],edx
        mov     ebx,[as_addressing_space]
        mov     [eax],ebx
        or      as_u8 [ebx+0Ah],2
        jmp     as_continue_line
      as_assemble_instruction:
;        mov     [as_operand_size],0
;        mov     [as_operand_flags],0
;        mov     [as_operand_prefix],0
;        mov     [as_rex_prefix],0
        and     as_u32 [as_operand_size],0
;        mov     [as_opcode_prefix],0
;        mov     [as_vex_required],0
;        mov     [as_vex_register],0
;        mov     [as_immediate_size],0
        and     as_u32 [as_opcode_prefix],0
        call    as_instruction_handler
      as_instruction_handler:
        movzx   ebx,as_u16 [esi]
        mov     al,[esi+2]
        add     esi,3
        add     [esp],ebx
        ret
      as_instruction_assembled:
        test    [as_prefix_flags],not 1
        if_not_zero     as_illegal_instruction
        mov     al,[esi]
        cmp     al,0Fh
        if_equal        as_line_assembled
        or      al,al
        if_not_zero     as_extra_characters_on_line
      as_line_assembled:
        clear_carry
        ret
      as_source_end:
        dec     esi
        set_carry
        ret

as_org_directive:
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_qword_value
        mov     cl,[as_value_type]
        test    cl,1
        if_not_zero     as_invalid_use_of_symbol
        push    eax
        mov     ebx,[as_addressing_space]
        mov     eax,edi
        sub     eax,[ebx+18h]
        mov     [ebx+1Ch],eax
        test    as_u8 [ebx+0Ah],1
        if_not_zero     as_in_virtual
        call    as_init_addressing_space
        jmp     as_org_space_ok
      as_in_virtual:
        call    as_close_virtual_addressing_space
        call    as_init_addressing_space
        or      as_u8 [ebx+0Ah],1
      as_org_space_ok:
        pop     eax
        mov     [ebx+9],cl
        mov     cl,[as_value_sign]
        sub     [ebx],eax
        sub_with_borrow [ebx+4],edx
        sub_with_borrow as_u8 [ebx+8],cl
        jp      as_org_value_ok
        call    as_recoverable_overflow
      as_org_value_ok:
        mov     edx,[as_symbol_identifier]
        mov     [ebx+14h],edx
        cmp     [as_output_format],1
        if_above        as_instruction_assembled
        cmp     edi,[as_code_start]
        if_not_equal    as_instruction_assembled
        cmp     eax,100h
        if_not_equal    as_instruction_assembled
        bit_test_set    [as_format_flags],0
        jmp     as_instruction_assembled
as_label_directive:
        lods    as_u8 [esi]
        cmp     al,2
        if_not_equal    as_invalid_argument
        lods    as_u32 [esi]
        cmp     eax,0Fh
        if_below        as_invalid_use_of_symbol
        if_equal        as_reserved_word_used_as_symbol
        inc     esi
        mov     ebx,eax
        mov     [as_label_size],0
        lods    as_u8 [esi]
        cmp     al,':'
        if_equal        as_get_label_size
        dec     esi
        cmp     al,11h
        if_not_equal    as_label_size_ok
      as_get_label_size:
        lods    as_u16 [esi]
        cmp     al,11h
        if_not_equal    as_invalid_argument
        mov     [as_label_size],ah
      as_label_size_ok:
        cmp     as_u8 [esi],80h
        if_equal        as_get_free_label_value
        call    as_make_label
        jmp     as_instruction_assembled
      as_get_free_label_value:
        inc     esi
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        push    ebx ecx
        or      as_u8 [ebx+8],4
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_address_value
        or      bh,bh
        setnz   ch
        xchg    ch,cl
        mov     bp,cx
        shl     ebp,16
        xchg    bl,bh
        mov     bp,bx
        pop     ecx ebx
        and     as_u8 [ebx+8],not 4
        mov     ch,[as_value_type]
        test    ch,1
        if_not_zero     as_invalid_use_of_symbol
      as_make_free_label:
        and     as_u8 [ebx+9],not 1
        cmp     eax,[ebx]
        mov     [ebx],eax
        setne   ah
        cmp     edx,[ebx+4]
        mov     [ebx+4],edx
        setne   al
        or      ah,al
        mov     edx,[as_address_symbol]
        mov     cl,[as_label_size]
        call    as_finish_label_symbol
        jmp     as_instruction_assembled
as_load_directive:
        lods    as_u8 [esi]
        cmp     al,2
        if_not_equal    as_invalid_argument
        lods    as_u32 [esi]
        cmp     eax,0Fh
        if_below        as_invalid_use_of_symbol
        if_equal        as_reserved_word_used_as_symbol
        inc     esi
        push    eax
        mov     al,1
        cmp     as_u8 [esi],11h
        if_not_equal    as_load_size_ok
        lods    as_u8 [esi]
        lods    as_u8 [esi]
      as_load_size_ok:
        cmp     al,8
        if_above        as_invalid_value
        mov     [as_operand_size],al
        and     as_u32 [as_value],0
        and     as_u32 [as_value+4],0
        lods    as_u8 [esi]
        cmp     al,82h
        if_not_equal    as_invalid_argument
        call    as_get_data_point
        if_carry        as_value_loaded
        push    esi edi
        mov     esi,ebx
        mov     edi,as_value
        rep     movs as_u8 [edi],[esi]
        pop     edi esi
      as_value_loaded:
        mov     [as_value_sign],0
        mov     eax,as_u32 [as_value]
        mov     edx,as_u32 [as_value+4]
        pop     ebx
        xor     cx,cx
        jmp     as_make_constant
      as_get_data_point:
        lods    as_u8 [esi]
        cmp     al,':'
        if_equal        as_get_data_offset
        cmp     al,'('
        if_not_equal    as_invalid_argument
        mov     ebx,[as_addressing_space]
        mov     ecx,edi
        sub     ecx,[ebx+18h]
        mov     [ebx+1Ch],ecx
        cmp     as_u8 [esi],11h
        if_not_equal    as_get_data_address
        cmp     as_u16 [esi+1+4],'):'
        if_not_equal    as_get_data_address
        inc     esi
        lods    as_u32 [esi]
        add     esi,2
        cmp     as_u8 [esi],'('
        if_not_equal    as_invalid_argument
        inc     esi
        cmp     eax,0Fh
        if_below_equal  as_reserved_word_used_as_symbol
        mov     edx,as_undefined_symbol
        test    as_u8 [eax+8],1
        if_zero as_addressing_space_unavailable
        mov     edx,as_symbol_out_of_scope
        mov     cx,[eax+16]
        cmp     cx,[as_current_pass]
        if_not_equal    as_addressing_space_unavailable
        test    as_u8 [eax+9],4
        if_zero as_invalid_use_of_symbol
        mov     ebx,eax
        mov     ax,[as_current_pass]
        mov     [ebx+18],ax
        or      as_u8 [ebx+8],8
        call    as_store_label_reference
      as_get_addressing_space:
        mov     ebx,[ebx]
      as_get_data_address:
        push    ebx
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        or      [as_operand_flags],1
        call    as_get_address_value
        pop     ebp
        call    as_calculate_relative_offset
        cmp     [as_next_pass_needed],0
        if_not_equal    as_data_address_type_ok
        cmp     [as_value_type],0
        if_not_equal    as_invalid_use_of_symbol
      as_data_address_type_ok:
        mov     ebx,edi
        xor     ecx,ecx
        add     ebx,eax
        add_with_carry  edx,ecx
        mov     eax,ebx
        sub     eax,[ds:ebp+18h]
        sub_with_borrow edx,ecx
        if_not_zero     as_bad_data_address
        mov     cl,[as_operand_size]
        add     eax,ecx
        cmp     eax,[ds:ebp+1Ch]
        if_above        as_bad_data_address
        clear_carry
        ret
      as_addressing_space_unavailable:
        cmp     [as_error_line],0
        if_not_equal    as_get_data_address
        push    [as_current_line]
        pop     [as_error_line]
        mov     [as_error],edx
        mov     [as_error_info],eax
        jmp     as_get_data_address
      as_bad_data_address:
        call    as_recoverable_overflow
        set_carry
        ret
      as_get_data_offset:
        cmp     [as_output_format],2
        if_above_equal  as_invalid_operand
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_dword_value
        cmp     [as_value_type],0
        if_equal        as_data_offset_ok
        call    as_recoverable_invalid_address
      as_data_offset_ok:
        add     eax,[as_code_start]
        if_carry        as_bad_data_address
        mov     ebx,eax
        movzx   ecx,[as_operand_size]
        add     eax,ecx
        if_carry        as_bad_data_address
        mov     edx,[as_addressing_space]
        test    as_u8 [edx+0Ah],1
        if_not_zero     as_data_offset_from_virtual
        cmp     eax,edi
        if_above        as_bad_data_address
        clear_carry
        ret
      as_data_offset_from_virtual:
        cmp     eax,[as_undefined_data_end]
        if_above        as_bad_data_address
        clear_carry
        ret

as_store_directive:
        cmp     as_u8 [esi],11h
        if_equal        as_sized_store
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        call    as_get_byte_value
        xor     edx,edx
        movzx   eax,al
        mov     [as_operand_size],1
        jmp     as_store_value_ok
      as_sized_store:
        or      [as_operand_flags],1
        call    as_get_value
      as_store_value_ok:
        cmp     [as_value_type],0
        if_not_equal    as_invalid_use_of_symbol
        mov     as_u32 [as_value],eax
        mov     as_u32 [as_value+4],edx
        lods    as_u8 [esi]
        cmp     al,80h
        if_not_equal    as_invalid_argument
        call    as_get_data_point
        if_carry        as_instruction_assembled
        push    esi edi
        mov     esi,as_value
        mov     edi,ebx
        rep     movs as_u8 [edi],[esi]
        mov     eax,edi
        pop     edi esi
        cmp     ebx,[as_undefined_data_end]
        if_above_equal  as_instruction_assembled
        cmp     eax,[as_undefined_data_start]
        if_below_equal  as_instruction_assembled
        mov     [as_undefined_data_start],eax
        jmp     as_instruction_assembled

as_display_directive:
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        cmp     as_u8 [esi],0
        if_not_equal    as_display_byte
        inc     esi
        lods    as_u32 [esi]
        mov     ecx,eax
        push    edi
        mov     edi,[as_tagged_blocks]
        sub     edi,8
        sub     edi,eax
        cmp     edi,[esp]
        if_below_equal  as_out_of_memory
        mov     [as_tagged_blocks],edi
        rep     movs as_u8 [edi],[esi]
        stos    as_u32 [edi]
        xor     eax,eax
        stos    as_u32 [edi]
        pop     edi
        inc     esi
        jmp     as_display_next
      as_display_byte:
        call    as_get_byte_value
        push    edi
        mov     edi,[as_tagged_blocks]
        sub     edi,8+1
        mov     [as_tagged_blocks],edi
        stos    as_u8 [edi]
        mov     eax,1
        stos    as_u32 [edi]
        dec     eax
        stos    as_u32 [edi]
        pop     edi
      as_display_next:
        cmp     edi,[as_tagged_blocks]
        if_above        as_out_of_memory
        lods    as_u8 [esi]
        cmp     al,','
        if_equal        as_display_directive
        dec     esi
        jmp     as_instruction_assembled
as_show_display_buffer:
        mov     eax,[as_tagged_blocks]
        or      eax,eax
        if_zero as_display_done
        mov     esi,[as_labels_list]
        cmp     esi,eax
        if_equal        as_display_done
      as_display_messages:
        sub     esi,8
        mov     eax,[esi+4]
        mov     ecx,[esi]
        sub     esi,ecx
        cmp     eax,10h
        if_equal        as_write_addressing_space
        test    eax,eax
        if_not_zero     as_skip_block
        push    esi
        call    as_display_block
        pop     esi
      as_skip_block:
        cmp     esi,[as_tagged_blocks]
        if_not_equal    as_display_messages
      as_display_done:
        ret
      as_write_addressing_space:
        mov     ecx,[esi+20h]
        jecxz   as_skip_block
        push    esi
        mov     edi,[as_free_additional_memory]
        mov     esi,[as_output_file]
        test    esi,esi
        if_zero as_addressing_space_written
        xor     ebx,ebx
      as_copy_output_path:
        lodsb
        cmp     edi,[as_structures_buffer]
        if_above_equal  as_out_of_memory
        stosb
        test    al,al
        if_zero as_output_path_copied
        cmp     al,'/'
        if_equal        as_new_path_segment
        cmp     al,'\'
        if_equal        as_new_path_segment
        cmp     al,'.'
        if_not_equal    as_copy_output_path
        mov     ebx,edi
        jmp     as_copy_output_path
      as_new_path_segment:
        xor     ebx,ebx
        jmp     as_copy_output_path
      as_output_path_copied:
        test    ebx,ebx
        if_not_zero     as_append_extension
        mov     as_u8 [edi-1],'.'
        mov     ebx,edi
      as_append_extension:
        mov     edi,ebx
        add     ebx,ecx
        inc     ebx
        cmp     ebx,[as_structures_buffer]
        if_above_equal  as_out_of_memory
        mov     esi,[esp]
        mov     esi,[esi+18h]
        sub     esi,ecx
        rep     movs as_u8 [edi],[esi]
        xor     al,al
        stos    as_u8 [edi]
        mov     edx,[as_free_additional_memory]
        call    as_create
        if_carry        as_write_failed
        mov     esi,[esp]
        mov     edx,[esi+18h]
        mov     ecx,[esi+1Ch]
        call    as_write
        if_carry        as_write_failed
        call    as_close
      as_addressing_space_written:
        pop     esi
        jmp     as_skip_block

as_times_directive:
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_count_value
        cmp     eax,0
        if_equal        as_zero_times
        cmp     as_u8 [esi],':'
        if_not_equal    as_times_argument_ok
        inc     esi
      as_times_argument_ok:
        push    [as_counter]
        push    [as_counter_limit]
        mov     [as_counter_limit],eax
        mov     [as_counter],1
      as_times_loop:
        mov     eax,esp
        sub     eax,[as_stack_limit]
        cmp     eax,100h
        if_below        as_stack_overflow
        push    esi
        or      [as_prefix_flags],1
        call    as_continue_line
        mov     eax,[as_counter_limit]
        cmp     [as_counter],eax
        if_equal        as_times_done
        inc     [as_counter]
        pop     esi
        jmp     as_times_loop
      as_times_done:
        pop     eax
        pop     [as_counter_limit]
        pop     [as_counter]
        jmp     as_instruction_assembled
      as_zero_times:
        call    as_skip_symbol
        if_not_carry    as_zero_times
        jmp     as_instruction_assembled

as_virtual_directive:
        lods    as_u8 [esi]
        cmp     al,'('
        if_equal        as_continue_virtual_area
        cmp     al,80h
        if_not_equal    as_virtual_at_current
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_address_value
        mov     ebp,[as_address_symbol]
        or      bh,bh
        setnz   ch
        jmp     as_set_virtual
      as_virtual_at_current:
        dec     esi
      as_virtual_fallback:
        mov     ebp,[as_addressing_space]
        mov     al,[ds:ebp+9]
        mov     [as_value_type],al
        mov     eax,edi
        xor     edx,edx
        xor     cl,cl
        sub     eax,[ds:ebp]
        sub_with_borrow edx,[ds:ebp+4]
        sub_with_borrow cl,[ds:ebp+8]
        mov     [as_address_sign],cl
        mov     bx,[ds:ebp+10h]
        mov     cx,[ds:ebp+10h+2]
        xchg    bh,bl
        xchg    ch,cl
        mov     ebp,[ds:ebp+14h]
      as_set_virtual:
        xchg    bl,bh
        xchg    cl,ch
        shl     ecx,16
        mov     cx,bx
        push    ecx eax
        mov     ebx,[as_addressing_space]
        test    as_u8 [ebx+0Ah],1
        if_not_zero     as_non_virtual_end_ok
        mov     eax,edi
        xchg    eax,[as_undefined_data_end]
        cmp     eax,edi
        if_equal        as_non_virtual_end_ok
        mov     [as_undefined_data_start],edi
      as_non_virtual_end_ok:
        call    as_allocate_virtual_structure_data
        call    as_init_addressing_space
        or      as_u8 [ebx+0Ah],1
        cmp     as_u8 [esi],86h
        if_not_equal    as_addressing_space_extension_ok
        cmp     as_u16 [esi+1],'('
        if_not_equal    as_invalid_argument
        mov     ecx,[esi+3]
        add     esi,3+4
        add     [ebx+18h],ecx
        mov     [ebx+20h],ecx
        or      as_u8 [ebx+0Ah],2
        push    ebx
        mov     ebx,as_characters
      as_get_extension:
        lods    as_u8 [esi]
        stos    as_u8 [edi]
        translate_byte  as_u8 [ebx]
        test    al,al
        if_zero as_invalid_argument
        loop    as_get_extension
        inc     esi
        pop     ebx
      as_addressing_space_extension_ok:
        pop     eax
        mov     cl,[as_address_sign]
        not     eax
        not     edx
        not     cl
        add     eax,1
        add_with_carry  edx,0
        add_with_carry  cl,0
        add     eax,edi
        add_with_carry  edx,0
        add_with_carry  cl,0
        mov     [ebx],eax
        mov     [ebx+4],edx
        mov     [ebx+8],cl
        pop     as_u32 [ebx+10h]
        mov     [ebx+14h],ebp
        mov     al,[as_value_type]
        test    al,1
        if_not_zero     as_invalid_use_of_symbol
        mov     [ebx+9],al
        jmp     as_instruction_assembled
      as_allocate_structure_data:
        mov     ebx,[as_structures_buffer]
        sub     ebx,18h
        cmp     ebx,[as_free_additional_memory]
        if_below        as_out_of_memory
        mov     [as_structures_buffer],ebx
        ret
      as_find_structure_data:
        mov     ebx,[as_structures_buffer]
      as_scan_structures:
        cmp     ebx,[as_additional_memory_end]
        if_equal        as_no_such_structure
        cmp     ax,[ebx]
        if_equal        as_structure_data_found
        add     ebx,18h
        jmp     as_scan_structures
      as_structure_data_found:
        ret
      as_no_such_structure:
        set_carry
        ret
      as_allocate_virtual_structure_data:
        call    as_allocate_structure_data
        mov     as_u16 [ebx],as_virtual_directive-as_instruction_handler
        mov     ecx,[as_addressing_space]
        mov     [ebx+12],ecx
        mov     [ebx+8],edi
        mov     ecx,[as_current_line]
        mov     [ebx+4],ecx
        mov     ebx,[as_addressing_space]
        mov     eax,edi
        sub     eax,[ebx+18h]
        mov     [ebx+1Ch],eax
        ret
      as_continue_virtual_area:
        cmp     as_u8 [esi],11h
        if_not_equal    as_invalid_argument
        cmp     as_u8 [esi+1+4],')'
        if_not_equal    as_invalid_argument
        inc     esi
        lods    as_u32 [esi]
        inc     esi
        cmp     eax,0Fh
        if_below_equal  as_reserved_word_used_as_symbol
        mov     edx,as_undefined_symbol
        test    as_u8 [eax+8],1
        if_zero as_virtual_area_unavailable
        mov     edx,as_symbol_out_of_scope
        mov     cx,[eax+16]
        cmp     cx,[as_current_pass]
        if_not_equal    as_virtual_area_unavailable
        mov     edx,as_invalid_use_of_symbol
        test    as_u8 [eax+9],4
        if_zero as_virtual_area_unavailable
        mov     ebx,eax
        mov     ax,[as_current_pass]
        mov     [ebx+18],ax
        or      as_u8 [ebx+8],8
        call    as_store_label_reference
        mov     ebx,[ebx]
        test    as_u8 [ebx+0Ah],4
        if_zero as_virtual_area_unavailable
        and     as_u8 [ebx+0Ah],not 4
        mov     edx,ebx
        call    as_allocate_virtual_structure_data
        mov     [as_addressing_space],edx
        push    esi
        mov     esi,[edx+18h]
        mov     ecx,[edx+1Ch]
        mov     eax,[edx+20h]
        sub     esi,eax
        add     ecx,eax
        lea     eax,[edi+ecx]
        cmp     eax,[as_tagged_blocks]
        if_above_equal  as_out_of_memory
        mov     eax,esi
        sub     eax,edi
        sub     [edx+18h],eax
        sub     [edx],eax
        sub_with_borrow as_u32 [edx+4],0
        sub_with_borrow as_u8 [edx+8],0
        mov     al,cl
        shr     ecx,2
        rep     movs as_u32 [edi],[esi]
        mov     cl,al
        and     cl,11b
        rep     movs as_u8 [edi],[esi]
        pop     esi
        jmp     as_instruction_assembled
      as_virtual_area_unavailable:
        cmp     [as_error_line],0
        if_not_equal    as_virtual_fallback
        push    [as_current_line]
        pop     [as_error_line]
        mov     [as_error],edx
        mov     [as_error_info],eax
        jmp     as_virtual_fallback
      as_end_virtual:
        call    as_find_structure_data
        if_carry        as_unexpected_instruction
        push    ebx
        call    as_close_virtual_addressing_space
        pop     ebx
        mov     eax,[ebx+12]
        mov     [as_addressing_space],eax
        mov     edi,[ebx+8]
      as_remove_structure_data:
        push    esi edi
        mov     ecx,ebx
        sub     ecx,[as_structures_buffer]
        shr     ecx,2
        lea     esi,[ebx-4]
        lea     edi,[esi+18h]
        set_direction
        rep     movs as_u32 [edi],[esi]
        clear_direction
        add     [as_structures_buffer],18h
        pop     edi esi
        ret
      as_close_virtual_addressing_space:
        mov     ebx,[as_addressing_space]
        mov     eax,edi
        sub     eax,[ebx+18h]
        mov     [ebx+1Ch],eax
        add     eax,[ebx+20h]
        test    as_u8 [ebx+0Ah],2
        if_zero as_addressing_space_closed
        or      as_u8 [ebx+0Ah],4
        push    esi edi ecx edx
        mov     ecx,eax
        mov     eax,[as_tagged_blocks]
        mov     as_u32 [eax-4],11h
        mov     as_u32 [eax-8],ecx
        sub     eax,8
        sub     eax,ecx
        mov     [as_tagged_blocks],eax
        lea     edi,[eax+ecx-1]
        add     eax,[ebx+20h]
        xchg    eax,[ebx+18h]
        sub     eax,[ebx+20h]
        lea     esi,[eax+ecx-1]
        mov     eax,edi
        sub     eax,esi
        set_direction
        shr     ecx,1
        if_not_carry    as_virtual_byte_ok
        movs    as_u8 [edi],[esi]
      as_virtual_byte_ok:
        dec     esi
        dec     edi
        shr     ecx,1
        if_not_carry    as_virtual_word_ok
        movs    as_u16 [edi],[esi]
      as_virtual_word_ok:
        sub     esi,2
        sub     edi,2
        rep     movs as_u32 [edi],[esi]
        clear_direction
        xor     edx,edx
        add     [ebx],eax
        add_with_carry  as_u32 [ebx+4],edx
        add_with_carry  as_u8 [ebx+8],dl
        pop     edx ecx edi esi
      as_addressing_space_closed:
        ret
as_repeat_directive:
        test    [as_prefix_flags],1
        if_not_zero     as_unexpected_instruction
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_count_value
        cmp     eax,0
        if_equal        as_zero_repeat
        call    as_allocate_structure_data
        mov     as_u16 [ebx],as_repeat_directive-as_instruction_handler
        xchg    eax,[as_counter_limit]
        mov     [ebx+10h],eax
        mov     eax,1
        xchg    eax,[as_counter]
        mov     [ebx+14h],eax
        mov     [ebx+8],esi
        mov     eax,[as_current_line]
        mov     [ebx+4],eax
        jmp     as_instruction_assembled
      as_end_repeat:
        test    [as_prefix_flags],1
        if_not_zero     as_unexpected_instruction
        call    as_find_structure_data
        if_carry        as_unexpected_instruction
        mov     eax,[as_counter_limit]
        inc     [as_counter]
        cmp     [as_counter],eax
        if_below_equal  as_continue_repeating
      as_stop_repeat:
        mov     eax,[ebx+10h]
        mov     [as_counter_limit],eax
        mov     eax,[ebx+14h]
        mov     [as_counter],eax
        call    as_remove_structure_data
        jmp     as_instruction_assembled
      as_continue_repeating:
        mov     esi,[ebx+8]
        jmp     as_instruction_assembled
      as_zero_repeat:
        mov     al,[esi]
        or      al,al
        if_zero as_missing_end_directive
        cmp     al,0Fh
        if_not_equal    as_extra_characters_on_line
        call    as_find_end_repeat
        jmp     as_instruction_assembled
      as_find_end_repeat:
        call    as_find_structure_end
        cmp     ax,as_repeat_directive-as_instruction_handler
        if_not_equal    as_unexpected_instruction
        ret
as_while_directive:
        test    [as_prefix_flags],1
        if_not_zero     as_unexpected_instruction
        call    as_allocate_structure_data
        mov     as_u16 [ebx],as_while_directive-as_instruction_handler
        mov     eax,1
        xchg    eax,[as_counter]
        mov     [ebx+10h],eax
        mov     [ebx+8],esi
        mov     eax,[as_current_line]
        mov     [ebx+4],eax
      as_do_while:
        push    ebx
        call    as_calculate_logical_expression
        or      al,al
        if_not_zero     as_while_true
        mov     al,[esi]
        or      al,al
        if_zero as_missing_end_directive
        cmp     al,0Fh
        if_not_equal    as_extra_characters_on_line
      as_stop_while:
        call    as_find_end_while
        pop     ebx
        mov     eax,[ebx+10h]
        mov     [as_counter],eax
        call    as_remove_structure_data
        jmp     as_instruction_assembled
      as_while_true:
        pop     ebx
        jmp     as_instruction_assembled
      as_end_while:
        test    [as_prefix_flags],1
        if_not_zero     as_unexpected_instruction
        call    as_find_structure_data
        if_carry        as_unexpected_instruction
        mov     eax,[ebx+4]
        mov     [as_current_line],eax
        inc     [as_counter]
        if_zero as_too_many_repeats
        mov     esi,[ebx+8]
        jmp     as_do_while
      as_find_end_while:
        call    as_find_structure_end
        cmp     ax,as_while_directive-as_instruction_handler
        if_not_equal    as_unexpected_instruction
        ret
as_if_directive:
        test    [as_prefix_flags],1
        if_not_zero     as_unexpected_instruction
        call    as_calculate_logical_expression
        mov     dl,al
        mov     al,[esi]
        or      al,al
        if_zero as_missing_end_directive
        cmp     al,0Fh
        if_not_equal    as_extra_characters_on_line
        or      dl,dl
        if_not_zero     as_if_true
        call    as_find_else
        if_carry        as_instruction_assembled
        mov     al,[esi]
        cmp     al,1
        if_not_equal    as_else_true
        cmp     as_u16 [esi+1],as_if_directive-as_instruction_handler
        if_not_equal    as_else_true
        add     esi,4
        jmp     as_if_directive
      as_if_true:
        xor     al,al
      as_make_if_structure:
        call    as_allocate_structure_data
        mov     as_u16 [ebx],as_if_directive-as_instruction_handler
        mov     as_u8 [ebx+2],al
        mov     eax,[as_current_line]
        mov     [ebx+4],eax
        jmp     as_instruction_assembled
      as_else_true:
        or      al,al
        if_zero as_missing_end_directive
        cmp     al,0Fh
        if_not_equal    as_extra_characters_on_line
        or      al,-1
        jmp     as_make_if_structure
      as_else_directive:
        test    [as_prefix_flags],1
        if_not_zero     as_unexpected_instruction
        mov     ax,as_if_directive-as_instruction_handler
        call    as_find_structure_data
        if_carry        as_unexpected_instruction
        cmp     as_u8 [ebx+2],0
        if_not_equal    as_unexpected_instruction
      as_found_else:
        mov     al,[esi]
        cmp     al,1
        if_not_equal    as_skip_else
        cmp     as_u16 [esi+1],as_if_directive-as_instruction_handler
        if_not_equal    as_skip_else
        add     esi,4
        call    as_find_else
        if_not_carry    as_found_else
        call    as_remove_structure_data
        jmp     as_instruction_assembled
      as_skip_else:
        or      al,al
        if_zero as_missing_end_directive
        cmp     al,0Fh
        if_not_equal    as_extra_characters_on_line
        call    as_find_end_if
        call    as_remove_structure_data
        jmp     as_instruction_assembled
      as_end_if:
        test    [as_prefix_flags],1
        if_not_zero     as_unexpected_instruction
        call    as_find_structure_data
        if_carry        as_unexpected_instruction
        call    as_remove_structure_data
        jmp     as_instruction_assembled
      as_find_else:
        call    as_find_structure_end
        cmp     ax,as_else_directive-as_instruction_handler
        if_equal        as_else_found
        cmp     ax,as_if_directive-as_instruction_handler
        if_not_equal    as_unexpected_instruction
        set_carry
        ret
      as_else_found:
        clear_carry
        ret
      as_find_end_if:
        call    as_find_structure_end
        cmp     ax,as_if_directive-as_instruction_handler
        if_not_equal    as_unexpected_instruction
        ret
      as_find_structure_end:
        push    [as_error_line]
        mov     eax,[as_current_line]
        mov     [as_error_line],eax
      as_find_end_directive:
        call    as_skip_symbol
        if_not_carry    as_find_end_directive
        lods    as_u8 [esi]
        cmp     al,0Fh
        if_not_equal    as_no_end_directive
        lods    as_u32 [esi]
        mov     [as_current_line],eax
      as_skip_labels:
        cmp     as_u8 [esi],2
        if_not_equal    as_labels_ok
        add     esi,6
        jmp     as_skip_labels
      as_labels_ok:
        cmp     as_u8 [esi],1
        if_not_equal    as_find_end_directive
        mov     ax,[esi+1]
        cmp     ax,as_prefix_instruction-as_instruction_handler
        if_equal        as_find_end_directive
        add     esi,4
        cmp     ax,as_repeat_directive-as_instruction_handler
        if_equal        as_skip_repeat
        cmp     ax,as_while_directive-as_instruction_handler
        if_equal        as_skip_while
        cmp     ax,as_if_directive-as_instruction_handler
        if_equal        as_skip_if
        cmp     ax,as_else_directive-as_instruction_handler
        if_equal        as_structure_end
        cmp     ax,as_end_directive-as_instruction_handler
        if_not_equal    as_find_end_directive
        cmp     as_u8 [esi],1
        if_not_equal    as_find_end_directive
        mov     ax,[esi+1]
        add     esi,4
        cmp     ax,as_repeat_directive-as_instruction_handler
        if_equal        as_structure_end
        cmp     ax,as_while_directive-as_instruction_handler
        if_equal        as_structure_end
        cmp     ax,as_if_directive-as_instruction_handler
        if_not_equal    as_find_end_directive
      as_structure_end:
        pop     [as_error_line]
        ret
      as_no_end_directive:
        mov     eax,[as_error_line]
        mov     [as_current_line],eax
        jmp     as_missing_end_directive
      as_skip_repeat:
        call    as_find_end_repeat
        jmp     as_find_end_directive
      as_skip_while:
        call    as_find_end_while
        jmp     as_find_end_directive
      as_skip_if:
        call    as_skip_if_block
        jmp     as_find_end_directive
      as_skip_if_block:
        call    as_find_else
        if_carry        as_if_block_skipped
        cmp     as_u8 [esi],1
        if_not_equal    as_skip_after_else
        cmp     as_u16 [esi+1],as_if_directive-as_instruction_handler
        if_not_equal    as_skip_after_else
        add     esi,4
        jmp     as_skip_if_block
      as_skip_after_else:
        call    as_find_end_if
      as_if_block_skipped:
        ret
as_end_directive:
        lods    as_u8 [esi]
        cmp     al,1
        if_not_equal    as_invalid_argument
        lods    as_u16 [esi]
        inc     esi
        cmp     ax,as_virtual_directive-as_instruction_handler
        if_equal        as_end_virtual
        cmp     ax,as_repeat_directive-as_instruction_handler
        if_equal        as_end_repeat
        cmp     ax,as_while_directive-as_instruction_handler
        if_equal        as_end_while
        cmp     ax,as_if_directive-as_instruction_handler
        if_equal        as_end_if
        cmp     ax,as_data_directive-as_instruction_handler
        if_equal        as_end_data
        jmp     as_invalid_argument
as_break_directive:
        mov     ebx,[as_structures_buffer]
        mov     al,[esi]
        or      al,al
        if_zero as_find_breakable_structure
        cmp     al,0Fh
        if_not_equal    as_extra_characters_on_line
      as_find_breakable_structure:
        cmp     ebx,[as_additional_memory_end]
        if_equal        as_unexpected_instruction
        mov     ax,[ebx]
        cmp     ax,as_repeat_directive-as_instruction_handler
        if_equal        as_break_repeat
        cmp     ax,as_while_directive-as_instruction_handler
        if_equal        as_break_while
        cmp     ax,as_if_directive-as_instruction_handler
        if_equal        as_break_if
        add     ebx,18h
        jmp     as_find_breakable_structure
      as_break_if:
        push    [as_current_line]
        mov     eax,[ebx+4]
        mov     [as_current_line],eax
        call    as_remove_structure_data
        call    as_skip_if_block
        pop     [as_current_line]
        mov     ebx,[as_structures_buffer]
        jmp     as_find_breakable_structure
      as_break_repeat:
        push    ebx
        call    as_find_end_repeat
        pop     ebx
        jmp     as_stop_repeat
      as_break_while:
        push    ebx
        jmp     as_stop_while

as_define_data:
        cmp     edi,[as_tagged_blocks]
        if_above_equal  as_out_of_memory
        cmp     as_u8 [esi],'('
        if_not_equal    as_simple_data_value
        mov     ebx,esi
        inc     esi
        call    as_skip_expression
        xchg    esi,ebx
        cmp     as_u8 [ebx],81h
        if_not_equal    as_simple_data_value
        inc     esi
        call    as_get_count_value
        inc     esi
        or      eax,eax
        if_zero as_duplicate_zero_times
        cmp     as_u8 [esi],91h
        if_not_equal    as_duplicate_single_data_value
        inc     esi
      as_duplicate_data:
        push    eax esi
      as_duplicated_values:
        cmp     edi,[as_tagged_blocks]
        if_above_equal  as_out_of_memory
        clear_carry
        call    near as_u32 [esp+8]
        lods    as_u8 [esi]
        cmp     al,','
        if_equal        as_duplicated_values
        cmp     al,92h
        if_not_equal    as_invalid_argument
        pop     ebx eax
        dec     eax
        if_zero as_data_defined
        mov     esi,ebx
        jmp     as_duplicate_data
      as_duplicate_single_data_value:
        cmp     edi,[as_tagged_blocks]
        if_above_equal  as_out_of_memory
        push    eax esi
        clear_carry
        call    near as_u32 [esp+8]
        pop     ebx eax
        dec     eax
        if_zero as_data_defined
        mov     esi,ebx
        jmp     as_duplicate_single_data_value
      as_duplicate_zero_times:
        cmp     as_u8 [esi],91h
        if_not_equal    as_skip_single_data_value
        inc     esi
      as_skip_data_value:
        call    as_skip_symbol
        if_carry        as_invalid_argument
        cmp     as_u8 [esi],92h
        if_not_equal    as_skip_data_value
        inc     esi
        jmp     as_data_defined
      as_skip_single_data_value:
        call    as_skip_symbol
        jmp     as_data_defined
      as_simple_data_value:
        cmp     edi,[as_tagged_blocks]
        if_above_equal  as_out_of_memory
        clear_carry
        call    near as_u32 [esp]
      as_data_defined:
        lods    as_u8 [esi]
        cmp     al,','
        if_equal        as_define_data
        dec     esi
        set_carry
        ret
as_data_bytes:
        call    as_define_data
        if_carry        as_instruction_assembled
        lods    as_u8 [esi]
        cmp     al,'('
        if_equal        as_get_byte
        cmp     al,'?'
        if_not_equal    as_invalid_argument
        mov     eax,edi
        mov     as_u8 [edi],0
        inc     edi
        jmp     as_undefined_data
      as_get_byte:
        cmp     as_u8 [esi],0
        if_equal        as_get_string
        call    as_get_byte_value
        stos    as_u8 [edi]
        ret
      as_get_string:
        inc     esi
        lods    as_u32 [esi]
        mov     ecx,eax
        lea     eax,[edi+ecx]
        cmp     eax,[as_tagged_blocks]
        if_above        as_out_of_memory
        rep     movs as_u8 [edi],[esi]
        inc     esi
        ret
      as_undefined_data:
        mov     ebp,[as_addressing_space]
        test    as_u8 [ds:ebp+0Ah],1
        if_zero as_mark_undefined_data
        ret
      as_mark_undefined_data:
        cmp     eax,[as_undefined_data_end]
        if_equal        as_undefined_data_ok
        mov     [as_undefined_data_start],eax
      as_undefined_data_ok:
        mov     [as_undefined_data_end],edi
        ret
as_data_unicode:
        or      [as_base_code],-1
        jmp     as_define_words
as_data_words:
        mov     [as_base_code],0
      as_define_words:
        call    as_define_data
        if_carry        as_instruction_assembled
        lods    as_u8 [esi]
        cmp     al,'('
        if_equal        as_get_word
        cmp     al,'?'
        if_not_equal    as_invalid_argument
        mov     eax,edi
        and     as_u16 [edi],0
        scas    as_u16 [edi]
        jmp     as_undefined_data
        ret
      as_get_word:
        cmp     [as_base_code],0
        if_equal        as_word_data_value
        cmp     as_u8 [esi],0
        if_equal        as_word_string
      as_word_data_value:
        call    as_get_word_value
        call    as_mark_relocation
        stos    as_u16 [edi]
        ret
      as_word_string:
        inc     esi
        lods    as_u32 [esi]
        mov     ecx,eax
        jecxz   as_word_string_ok
        lea     eax,[edi+ecx*2]
        cmp     eax,[as_tagged_blocks]
        if_above        as_out_of_memory
        xor     ah,ah
      as_copy_word_string:
        lods    as_u8 [esi]
        stos    as_u16 [edi]
        loop    as_copy_word_string
      as_word_string_ok:
        inc     esi
        ret
as_data_dwords:
        call    as_define_data
        if_carry        as_instruction_assembled
        lods    as_u8 [esi]
        cmp     al,'('
        if_equal        as_get_dword
        cmp     al,'?'
        if_not_equal    as_invalid_argument
        mov     eax,edi
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        jmp     as_undefined_data
      as_get_dword:
        push    esi
        call    as_get_dword_value
        pop     ebx
        cmp     as_u8 [esi],':'
        if_equal        as_complex_dword
        call    as_mark_relocation
        stos    as_u32 [edi]
        ret
      as_complex_dword:
        mov     esi,ebx
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_word_value
        push    eax
        inc     esi
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_operand
        mov     al,[as_value_type]
        push    eax
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_word_value
        call    as_mark_relocation
        stos    as_u16 [edi]
        pop     eax
        mov     [as_value_type],al
        pop     eax
        call    as_mark_relocation
        stos    as_u16 [edi]
        ret
as_data_pwords:
        call    as_define_data
        if_carry        as_instruction_assembled
        lods    as_u8 [esi]
        cmp     al,'('
        if_equal        as_get_pword
        cmp     al,'?'
        if_not_equal    as_invalid_argument
        mov     eax,edi
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        and     as_u16 [edi],0
        scas    as_u16 [edi]
        jmp     as_undefined_data
      as_get_pword:
        push    esi
        call    as_get_pword_value
        pop     ebx
        cmp     as_u8 [esi],':'
        if_equal        as_complex_pword
        call    as_mark_relocation
        stos    as_u32 [edi]
        mov     ax,dx
        stos    as_u16 [edi]
        ret
      as_complex_pword:
        mov     esi,ebx
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_word_value
        push    eax
        inc     esi
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_operand
        mov     al,[as_value_type]
        push    eax
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_dword_value
        call    as_mark_relocation
        stos    as_u32 [edi]
        pop     eax
        mov     [as_value_type],al
        pop     eax
        call    as_mark_relocation
        stos    as_u16 [edi]
        ret
as_data_qwords:
        call    as_define_data
        if_carry        as_instruction_assembled
        lods    as_u8 [esi]
        cmp     al,'('
        if_equal        as_get_qword
        cmp     al,'?'
        if_not_equal    as_invalid_argument
        mov     eax,edi
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        jmp     as_undefined_data
      as_get_qword:
        call    as_get_qword_value
        call    as_mark_relocation
        stos    as_u32 [edi]
        mov     eax,edx
        stos    as_u32 [edi]
        ret
as_data_twords:
        call    as_define_data
        if_carry        as_instruction_assembled
        lods    as_u8 [esi]
        cmp     al,'('
        if_equal        as_get_tword
        cmp     al,'?'
        if_not_equal    as_invalid_argument
        mov     eax,edi
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        and     as_u16 [edi],0
        scas    as_u16 [edi]
        jmp     as_undefined_data
      as_get_tword:
        cmp     as_u8 [esi],'.'
        if_equal        as_fp_tword_literal
        ; not a float literal — save esi so we can restore if needed
        push    esi
        call    as_get_qword_value
        ; eax = lo32, edx = hi32
        cmp     as_u8 [esi],':'
        if_equal        as_tword_restore_complex
        ; plain integer — convert to x87 80-bit extended precision
        pop     ecx                     ; discard saved esi
        ; handle zero specially
        or      eax,eax
        if_not_zero     as_integer_tword_nonzero
        or      edx,edx
        if_not_zero     as_integer_tword_nonzero
        xor     eax,eax
        stos    as_u32 [edi]
        stos    as_u32 [edi]
        xor     ax,ax
        stos    as_u16 [edi]
        ret
      as_integer_tword_nonzero:
        ; find MSB: check high dword first
        push    edx
        push    eax
        bit_scan_reverse        ecx,edx
        if_not_zero     as_tword_msb_in_hi
        bit_scan_reverse        ecx,eax
        ; MSB in lo dword: ecx = bit pos (0-31), total = ecx
        jmp     as_tword_have_msb
      as_tword_msb_in_hi:
        add     ecx,32                  ; total MSB position (32-63)
      as_tword_have_msb:
        ; ecx = MSB position (0-63)
        ; shift amount to normalize = 63 - ecx
        mov     ebx,63
        sub     ebx,ecx
        ; restore eax(lo), edx(hi)
        pop     eax
        pop     edx
        ; shift edx:eax left by ebx bits
        push    ecx                     ; save MSB pos for exponent
        mov     ecx,ebx
        or      ecx,ecx
        if_zero as_tword_no_shift
        cmp     ecx,32
        if_below        as_tword_small_shift
        ; shift >= 32
        sub     ecx,32
        mov     edx,eax
        xor     eax,eax
        shl     edx,cl
        jmp     as_tword_no_shift
      as_tword_small_shift:
        shld    edx,eax,cl
        shl     eax,cl
      as_tword_no_shift:
        ; store normalized mantissa: lo32 then hi32
        stos    as_u32 [edi]
        mov     eax,edx
        stos    as_u32 [edi]
        pop     ecx                     ; restore MSB pos
        ; biased exponent = 16383 + MSB_pos, sign bit = 0
        mov     ax,3FFFh
        add     ax,cx
        stos    as_u16 [edi]
        ret
      as_tword_restore_complex:
        pop     esi
        jmp     as_complex_tword
      as_fp_tword_literal:
        inc     esi
        cmp     as_u16 [esi+8],8000h
        if_equal        as_fp_zero_tword
        mov     eax,[esi]
        stos    as_u32 [edi]
        mov     eax,[esi+4]
        stos    as_u32 [edi]
        mov     ax,[esi+8]
        add     ax,3FFFh
        if_overflow     as_value_out_of_range
        cmp     ax,7FFFh
        if_greater_equal        as_value_out_of_range
        cmp     ax,0
        if_greater      as_tword_exp_ok
        mov     cx,ax
        negate  cx
        inc     cx
        cmp     cx,64
        if_above_equal  as_value_out_of_range
        cmp     cx,32
        if_above        as_large_shift
        mov     eax,[esi]
        mov     edx,[esi+4]
        mov     ebx,edx
        shr     edx,cl
        shrd    eax,ebx,cl
        jmp     as_tword_mantissa_shift_done
      as_large_shift:
        sub     cx,32
        xor     edx,edx
        mov     eax,[esi+4]
        shr     eax,cl
      as_tword_mantissa_shift_done:
        if_not_carry    as_store_shifted_mantissa
        add     eax,1
        add_with_carry  edx,0
      as_store_shifted_mantissa:
        mov     [edi-8],eax
        mov     [edi-4],edx
        xor     ax,ax
        test    edx,1 shl 31
        if_zero as_tword_exp_ok
        inc     ax
      as_tword_exp_ok:
        mov     bl,[esi+11]
        shl     bx,15
        or      ax,bx
        stos    as_u16 [edi]
        add     esi,13
        ret
      as_fp_zero_tword:
        xor     eax,eax
        stos    as_u32 [edi]
        stos    as_u32 [edi]
        mov     al,[esi+11]
        shl     ax,15
        stos    as_u16 [edi]
        add     esi,13
        ret
      as_complex_tword:
        call    as_get_word_value
        push    eax
        cmp     as_u8 [esi],':'
        if_not_equal    as_invalid_operand
        inc     esi
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_operand
        mov     al,[as_value_type]
        push    eax
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_qword_value
        call    as_mark_relocation
        stos    as_u32 [edi]
        mov     eax,edx
        stos    as_u32 [edi]
        pop     eax
        mov     [as_value_type],al
        pop     eax
        call    as_mark_relocation
        stos    as_u16 [edi]
        ret
as_data_file:
        lods    as_u16 [esi]
        cmp     ax,'('
        if_not_equal    as_invalid_argument
        add     esi,4
        call    as_open_binary_file
        mov     eax,[esi-4]
        lea     esi,[esi+eax+1]
        mov     al,2
        xor     edx,edx
        call    as_lseek
        push    eax
        xor     edx,edx
        cmp     as_u8 [esi],':'
        if_not_equal    as_position_ok
        inc     esi
        cmp     as_u8 [esi],'('
        if_not_equal    as_invalid_argument
        inc     esi
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        push    ebx
        call    as_get_count_value
        pop     ebx
        mov     edx,eax
        sub     [esp],edx
        if_carry        as_value_out_of_range
      as_position_ok:
        cmp     as_u8 [esi],','
        if_not_equal    as_size_ok
        inc     esi
        cmp     as_u8 [esi],'('
        if_not_equal    as_invalid_argument
        inc     esi
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        push    ebx edx
        call    as_get_count_value
        pop     edx ebx
        cmp     eax,[esp]
        if_above        as_value_out_of_range
        mov     [esp],eax
      as_size_ok:
        xor     al,al
        call    as_lseek
        pop     ecx
        mov     edx,edi
        add     edi,ecx
        if_carry        as_out_of_memory
        cmp     edi,[as_tagged_blocks]
        if_above        as_out_of_memory
        call    as_read
        if_carry        as_error_reading_file
        call    as_close
        lods    as_u8 [esi]
        cmp     al,','
        if_equal        as_data_file
        dec     esi
        jmp     as_instruction_assembled
      as_open_binary_file:
        push    esi
        push    edi
        mov     eax,[as_current_line]
      as_find_current_source_path: 
        mov     esi,[eax] 
        test    as_u8 [eax+7],80h 
        if_zero as_get_current_path 
        mov     eax,[eax+8]
        jmp     as_find_current_source_path
      as_get_current_path:
        lodsb
        stosb
        or      al,al
        if_not_zero     as_get_current_path
      as_cut_current_path:
        cmp     edi,[esp]
        if_equal        as_current_path_ok
        cmp     as_u8 [edi-1],'\'
        if_equal        as_current_path_ok
        cmp     as_u8 [edi-1],'/'
        if_equal        as_current_path_ok
        dec     edi
        jmp     as_cut_current_path
      as_current_path_ok:
        mov     esi,[esp+4]
        call    as_expand_path
        pop     edx
        mov     esi,edx
        call    as_open
        if_not_carry    as_file_opened
        mov     edx,[as_include_paths]
      as_search_in_include_paths:
        push    edx esi
        mov     edi,esi
        mov     esi,[esp+4]
        call    as_get_include_directory
        mov     [esp+4],esi
        mov     esi,[esp+8]
        call    as_expand_path
        pop     edx
        mov     esi,edx
        call    as_open
        pop     edx
        if_not_carry    as_file_opened
        cmp     as_u8 [edx],0
        if_not_equal    as_search_in_include_paths
        mov     edi,esi
        mov     esi,[esp]
        push    edi
        call    as_expand_path
        pop     edx
        mov     esi,edx
        call    as_open
        if_carry        as_file_not_found
      as_file_opened:
        mov     edi,esi
        pop     esi
        ret
as_reserve_bytes:
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_count_value
        mov     ecx,eax
        mov     edx,ecx
        add     edx,edi
        if_carry        as_out_of_memory
        cmp     edx,[as_tagged_blocks]
        if_above        as_out_of_memory
        push    edi
        cmp     [as_next_pass_needed],0
        if_equal        as_zero_bytes
        add     edi,ecx
        jmp     as_reserved_data
      as_zero_bytes:
        xor     eax,eax
        shr     ecx,1
        if_not_carry    as_bytes_stosb_ok
        stos    as_u8 [edi]
      as_bytes_stosb_ok:
        shr     ecx,1
        if_not_carry    as_bytes_stosw_ok
        stos    as_u16 [edi]
      as_bytes_stosw_ok:
        rep     stos as_u32 [edi]
      as_reserved_data:
        pop     eax
        call    as_undefined_data
        jmp     as_instruction_assembled
as_reserve_words:
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_count_value
        mov     ecx,eax
        mov     edx,ecx
        shl     edx,1
        if_carry        as_out_of_memory
        add     edx,edi
        if_carry        as_out_of_memory
        cmp     edx,[as_tagged_blocks]
        if_above        as_out_of_memory
        push    edi
        cmp     [as_next_pass_needed],0
        if_equal        as_zero_words
        lea     edi,[edi+ecx*2]
        jmp     as_reserved_data
      as_zero_words:
        xor     eax,eax
        shr     ecx,1
        if_not_carry    as_words_stosw_ok
        stos    as_u16 [edi]
      as_words_stosw_ok:
        rep     stos as_u32 [edi]
        jmp     as_reserved_data
as_reserve_dwords:
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_count_value
        mov     ecx,eax
        mov     edx,ecx
        shl     edx,1
        if_carry        as_out_of_memory
        shl     edx,1
        if_carry        as_out_of_memory
        add     edx,edi
        if_carry        as_out_of_memory
        cmp     edx,[as_tagged_blocks]
        if_above        as_out_of_memory
        push    edi
        cmp     [as_next_pass_needed],0
        if_equal        as_zero_dwords
        lea     edi,[edi+ecx*4]
        jmp     as_reserved_data
      as_zero_dwords:
        xor     eax,eax
        rep     stos as_u32 [edi]
        jmp     as_reserved_data
as_reserve_pwords:
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_count_value
        mov     ecx,eax
        shl     ecx,1
        if_carry        as_out_of_memory
        add     ecx,eax
        mov     edx,ecx
        shl     edx,1
        if_carry        as_out_of_memory
        add     edx,edi
        if_carry        as_out_of_memory
        cmp     edx,[as_tagged_blocks]
        if_above        as_out_of_memory
        push    edi
        cmp     [as_next_pass_needed],0
        if_equal        as_zero_words
        lea     edi,[edi+ecx*2]
        jmp     as_reserved_data
as_reserve_qwords:
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_count_value
        mov     ecx,eax
        shl     ecx,1
        if_carry        as_out_of_memory
        mov     edx,ecx
        shl     edx,1
        if_carry        as_out_of_memory
        shl     edx,1
        if_carry        as_out_of_memory
        add     edx,edi
        if_carry        as_out_of_memory
        cmp     edx,[as_tagged_blocks]
        if_above        as_out_of_memory
        push    edi
        cmp     [as_next_pass_needed],0
        if_equal        as_zero_dwords
        lea     edi,[edi+ecx*4]
        jmp     as_reserved_data
as_reserve_twords:
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_count_value
        mov     ecx,eax
        shl     ecx,2
        if_carry        as_out_of_memory
        add     ecx,eax
        mov     edx,ecx
        shl     edx,1
        if_carry        as_out_of_memory
        add     edx,edi
        if_carry        as_out_of_memory
        cmp     edx,[as_tagged_blocks]
        if_above        as_out_of_memory
        push    edi
        cmp     [as_next_pass_needed],0
        if_equal        as_zero_words
        lea     edi,[edi+ecx*2]
        jmp     as_reserved_data
as_align_directive:
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_count_value
        mov     edx,eax
        dec     edx
        test    eax,edx
        if_not_zero     as_invalid_align_value
        or      eax,eax
        if_zero as_invalid_align_value
        cmp     eax,1
        if_equal        as_instruction_assembled
        mov     ecx,edi
        mov     ebp,[as_addressing_space]
        sub     ecx,[ds:ebp]
        cmp     as_u32 [ds:ebp+10h],0
        if_not_equal    as_section_not_aligned_enough
        cmp     as_u8 [ds:ebp+9],0
        if_equal        as_make_alignment
        cmp     [as_output_format],3
        if_equal        as_pe_alignment
        cmp     [as_output_format],5
        if_not_equal    as_object_alignment
        test    [as_format_flags],1
        if_not_zero     as_pe_alignment
      as_object_alignment:
        mov     ebx,[ds:ebp+14h]
        cmp     as_u8 [ebx],0
        if_not_equal    as_section_not_aligned_enough
        cmp     eax,[ebx+10h]
        if_below_equal  as_make_alignment
        jmp     as_section_not_aligned_enough
      as_pe_alignment:
        cmp     eax,1000h
        if_above        as_section_not_aligned_enough
      as_make_alignment:
        dec     eax
        and     ecx,eax
        if_zero as_instruction_assembled
        negate  ecx
        add     ecx,eax
        inc     ecx
        mov     edx,ecx
        add     edx,edi
        if_carry        as_out_of_memory
        cmp     edx,[as_tagged_blocks]
        if_above        as_out_of_memory
        push    edi
        cmp     [as_next_pass_needed],0
        if_equal        as_nops
        add     edi,ecx
        jmp     as_reserved_data
      as_invalid_align_value:
        cmp     [as_error_line],0
        if_not_equal    as_instruction_assembled
        mov     eax,[as_current_line]
        mov     [as_error_line],eax
        mov     [as_error],as_invalid_value
        jmp     as_instruction_assembled
      as_nops:
        mov     eax,90909090h
        shr     ecx,1
        if_not_carry    as_nops_stosb_ok
        stos    as_u8 [edi]
      as_nops_stosb_ok:
        shr     ecx,1
        if_not_carry    as_nops_stosw_ok
        stos    as_u16 [edi]
      as_nops_stosw_ok:
        rep     stos as_u32 [edi]
        jmp     as_reserved_data
as_err_directive:
        mov     al,[esi]
        cmp     al,0Fh
        if_equal        as_invoked_error
        or      al,al
        if_zero as_invoked_error
        jmp     as_extra_characters_on_line
as_assert_directive:
        call    as_calculate_logical_expression
        or      al,al
        if_not_zero     as_instruction_assembled
        cmp     [as_error_line],0
        if_not_equal    as_instruction_assembled
        mov     eax,[as_current_line]
        mov     [as_error_line],eax
        mov     [as_error],as_assertion_failed
        jmp     as_instruction_assembled

; ---------------------------------------------------------------
; u8/u16/u32/u64/u80 - alias handlers (delegate ke existing)
; ---------------------------------------------------------------

as_data_u8:
        jmp     as_data_bytes
as_data_u16:
        jmp     as_data_words
as_data_u32:
        jmp     as_data_dwords
as_data_u64:
        jmp     as_data_qwords
as_data_u80:
        jmp     as_data_twords

; ---------------------------------------------------------------
; u128 - define 16-as_u8 (oword) integer data
; Sintaks: u128 expr [, expr ...]
; Tiap expr adalah nilai 64-bit, disimpan sebagai dua as_u64 (lo, hi=0)
; Untuk full 128-bit: u128 lo_val, hi_val  (dua item terpisah)
; ---------------------------------------------------------------

as_data_owords:
        call    as_define_data
        if_carry        as_instruction_assembled
      as_oword_value:
        lods    as_u8 [esi]
        cmp     al,'('
        if_equal        as_get_oword
        cmp     al,'?'
        if_not_equal    as_invalid_argument
        ; undefined: 16 bytes kosong
        mov     eax,edi
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        jmp     as_undefined_data
      as_get_oword:
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_qword_value
        call    as_mark_relocation
        stos    as_u32 [edi]            ; lo as_u32
        mov     eax,edx
        stos    as_u32 [edi]            ; hi as_u32 of 64-bit value
        xor     eax,eax
        stos    as_u32 [edi]            ; upper 64 bits = 0
        stos    as_u32 [edi]
        ret

; ---------------------------------------------------------------
; u256 - define 32-as_u8 (yword) integer data
; ---------------------------------------------------------------

as_data_ywords:
        call    as_define_data
        if_carry        as_instruction_assembled
      as_yword_value:
        lods    as_u8 [esi]
        cmp     al,'('
        if_equal        as_get_yword
        cmp     al,'?'
        if_not_equal    as_invalid_argument
        mov     eax,edi
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        jmp     as_undefined_data
      as_get_yword:
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_qword_value
        call    as_mark_relocation
        stos    as_u32 [edi]
        mov     eax,edx
        stos    as_u32 [edi]
        xor     eax,eax
        stos    as_u32 [edi]
        stos    as_u32 [edi]
        stos    as_u32 [edi]
        stos    as_u32 [edi]
        stos    as_u32 [edi]
        stos    as_u32 [edi]
        ret

; ---------------------------------------------------------------
; u512 - define 64-as_u8 (zword) integer data
; ---------------------------------------------------------------

as_data_zwords:
        call    as_define_data
        if_carry        as_instruction_assembled
      as_zword_value:
        lods    as_u8 [esi]
        cmp     al,'('
        if_equal        as_get_zword
        cmp     al,'?'
        if_not_equal    as_invalid_argument
        mov     ecx,16
      as_zword_undef_loop:
        and     as_u32 [edi],0
        scas    as_u32 [edi]
        loop    as_zword_undef_loop
        jmp     as_undefined_data
      as_get_zword:
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_qword_value
        call    as_mark_relocation
        stos    as_u32 [edi]
        mov     eax,edx
        stos    as_u32 [edi]
        xor     eax,eax
        mov     ecx,14
      as_zword_zero_loop:
        stos    as_u32 [edi]
        loop    as_zword_zero_loop
        ret

; ---------------------------------------------------------------
; Reserve handlers untuk u128/u256/u512
; ---------------------------------------------------------------

as_reserve_owords:
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_count_value
        ; ecx = count * 16 bytes
        mov     ecx,eax
        shl     ecx,4
        if_carry        as_out_of_memory
        mov     edx,ecx
        add     edx,edi
        if_carry        as_out_of_memory
        cmp     edx,[as_tagged_blocks]
        if_above        as_out_of_memory
        push    edi
        cmp     [as_next_pass_needed],0
        if_equal        as_zero_owords
        add     edi,ecx
        jmp     as_reserved_data
      as_zero_owords:
        xor     eax,eax
        shr     ecx,2
        rep     stos as_u32 [edi]
        jmp     as_reserved_data

as_reserve_ywords:
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_count_value
        mov     ecx,eax
        shl     ecx,5
        if_carry        as_out_of_memory
        mov     edx,ecx
        add     edx,edi
        if_carry        as_out_of_memory
        cmp     edx,[as_tagged_blocks]
        if_above        as_out_of_memory
        push    edi
        cmp     [as_next_pass_needed],0
        if_equal        as_zero_ywords
        add     edi,ecx
        jmp     as_reserved_data
      as_zero_ywords:
        xor     eax,eax
        shr     ecx,2
        rep     stos as_u32 [edi]
        jmp     as_reserved_data

as_reserve_zwords:
        lods    as_u8 [esi]
        cmp     al,'('
        if_not_equal    as_invalid_argument
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_value
        call    as_get_count_value
        mov     ecx,eax
        shl     ecx,6
        if_carry        as_out_of_memory
        mov     edx,ecx
        add     edx,edi
        if_carry        as_out_of_memory
        cmp     edx,[as_tagged_blocks]
        if_above        as_out_of_memory
        push    edi
        cmp     [as_next_pass_needed],0
        if_equal        as_zero_zwords
        add     edi,ecx
        jmp     as_reserved_data
      as_zero_zwords:
        xor     eax,eax
        shr     ecx,2
        rep     stos as_u32 [edi]
        jmp     as_reserved_data
