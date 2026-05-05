; SPDX-License-Identifier: BSD-2-Clause
; Copyright (c) 2026 danko1122q
; All rights reserved.

as_calculate_expression:

        mov     [as_current_offset],edi
        mov     [as_value_undefined],0
        cmp     as_u8 [esi],0
        if_equal        as_get_string_value
        cmp     as_u8 [esi],'.'
        if_equal        as_convert_fp
      as_calculation_loop:
        mov     eax,[as_tagged_blocks]
        sub     eax,0Ch
        cmp     eax,edi
        if_below_equal  as_out_of_memory
        lods    as_u8 [esi]
        cmp     al,1
        if_equal        as_get_byte_number
        cmp     al,2
        if_equal        as_get_word_number
        cmp     al,4
        if_equal        as_get_dword_number
        cmp     al,8
        if_equal        as_get_qword_number
        cmp     al,0Fh
        if_equal        as_value_out_of_range
        cmp     al,10h
        if_equal        as_get_register
        cmp     al,11h
        if_equal        as_get_label
        cmp     al,')'
        if_equal        as_expression_calculated
        cmp     al,']'
        if_equal        as_expression_calculated
        cmp     al,'!'
        if_equal        as_invalid_expression
        sub     edi,14h
        mov     ebx,edi
        sub     ebx,14h
        cmp     al,0F0h
        if_equal        as_calculate_rva
        cmp     al,0F1h
        if_equal        as_calculate_plt
        cmp     al,0D0h
        if_equal        as_calculate_not
        cmp     al,0E0h
        if_equal        as_calculate_bsf
        cmp     al,0E1h
        if_equal        as_calculate_bsr
        cmp     al,083h
        if_equal        as_calculate_neg
        mov     dx,[ebx+8]
        or      dx,[edi+8]
        cmp     al,80h
        if_equal        as_calculate_add
        cmp     al,81h
        if_equal        as_calculate_sub
        mov     ah,[ebx+12]
        or      ah,[edi+12]
        if_zero as_absolute_values_calculation
        call    as_recoverable_misuse
      as_absolute_values_calculation:
        cmp     al,90h
        if_equal        as_calculate_mul
        cmp     al,91h
        if_equal        as_calculate_div
        or      dx,dx
        if_not_zero     as_invalid_expression
        cmp     al,0A0h
        if_equal        as_calculate_mod
        cmp     al,0B0h
        if_equal        as_calculate_and
        cmp     al,0B1h
        if_equal        as_calculate_or
        cmp     al,0B2h
        if_equal        as_calculate_xor
        cmp     al,0C0h
        if_equal        as_calculate_shl
        cmp     al,0C1h
        if_equal        as_calculate_shr
        jmp     as_invalid_expression
      as_expression_calculated:
        sub     edi,14h
        cmp     [as_value_undefined],0
        if_equal        as_expression_value_ok
        xor     eax,eax
        mov     [edi],eax
        mov     [edi+4],eax
        mov     [edi+12],eax
      as_expression_value_ok:
        ret
      as_get_byte_number:
        xor     eax,eax
        lods    as_u8 [esi]
        stos    as_u32 [edi]
        xor     al,al
        stos    as_u32 [edi]
      as_got_number:
        and     as_u16 [edi-8+8],0
        and     as_u16 [edi-8+12],0
        and     as_u32 [edi-8+16],0
        add     edi,0Ch
        jmp     as_calculation_loop
      as_get_word_number:
        xor     eax,eax
        lods    as_u16 [esi]
        stos    as_u32 [edi]
        xor     ax,ax
        stos    as_u32 [edi]
        jmp     as_got_number
      as_get_dword_number:
        movs    as_u32 [edi],[esi]
        xor     eax,eax
        stos    as_u32 [edi]
        jmp     as_got_number
      as_get_qword_number:
        movs    as_u32 [edi],[esi]
        movs    as_u32 [edi],[esi]
        jmp     as_got_number
      as_get_register:
        mov     as_u8 [edi+9],0
        and     as_u16 [edi+12],0
        lods    as_u8 [esi]
        mov     [edi+8],al
        mov     as_u8 [edi+10],1
        xor     eax,eax
        mov     [edi+16],eax
        stos    as_u32 [edi]
        stos    as_u32 [edi]
        add     edi,0Ch
        jmp     as_calculation_loop
      as_get_label:
        xor     eax,eax
        mov     [edi+8],eax
        mov     [edi+12],eax
        mov     [edi+20],eax
        lods    as_u32 [esi]
        cmp     eax,0Fh
        if_below        as_predefined_label
        if_equal        as_reserved_word_used_as_symbol
        mov     ebx,eax
        mov     ax,[as_current_pass]
        mov     [ebx+18],ax
        mov     cl,[ebx+9]
        shr     cl,1
        and     cl,1
        negate  cl
        or      as_u8 [ebx+8],8
        test    as_u8 [ebx+8],1
        if_zero as_label_undefined
        cmp     ax,[ebx+16]
        if_equal        as_unadjusted_label
        test    as_u8 [ebx+8],4
        if_not_zero     as_label_out_of_scope
        test    as_u8 [ebx+9],1
        if_zero as_unadjusted_label
        mov     eax,[ebx]
        sub     eax,as_u32 [as_adjustment]
        stos    as_u32 [edi]
        mov     eax,[ebx+4]
        sub_with_borrow eax,as_u32 [as_adjustment+4]
        stos    as_u32 [edi]
        sub_with_borrow cl,[as_adjustment_sign]
        mov     [edi-8+13],cl
        mov     eax,as_u32 [as_adjustment]
        or      al,[as_adjustment_sign]
        or      eax,as_u32 [as_adjustment+4]
        if_zero as_got_label
        or      [as_next_pass_needed],-1
        jmp     as_got_label
      as_unadjusted_label:
        mov     eax,[ebx]
        stos    as_u32 [edi]
        mov     eax,[ebx+4]
        stos    as_u32 [edi]
        mov     [edi-8+13],cl
      as_got_label:
        test    as_u8 [ebx+9],4
        if_not_zero     as_invalid_use_of_symbol
        call    as_store_label_reference
        mov     al,[ebx+11]
        mov     [edi-8+12],al
        mov     eax,[ebx+12]
        mov     [edi-8+8],eax
        cmp     al,ah
        if_not_equal    as_labeled_registers_ok
        shr     eax,16
        add     al,ah
        if_overflow     as_labeled_registers_ok
        xor     ah,ah
        mov     [edi-8+10],ax
        mov     [edi-8+9],ah
      as_labeled_registers_ok:
        mov     eax,[ebx+20]
        mov     [edi-8+16],eax
        add     edi,0Ch
        mov     al,[ebx+10]
        or      al,al
        if_zero as_calculation_loop
        test    [as_operand_flags],1
        if_not_zero     as_calculation_loop
      as_check_size:
        xchg    [as_operand_size],al
        or      al,al
        if_zero as_calculation_loop
        cmp     al,[as_operand_size]
        if_not_equal    as_operand_sizes_do_not_match
        jmp     as_calculation_loop
      as_actual_file_offset_label:
        mov     eax,[as_undefined_data_end]
        mov     ebp,[as_addressing_space]
        test    as_u8 [ds:ebp+0Ah],1
        if_not_zero     as_use_undefined_data_offset
        cmp     eax,[as_current_offset]
        if_not_equal    as_use_current_offset
      as_use_undefined_data_offset:
        mov     eax,[as_undefined_data_start]
        jmp     as_make_file_offset_label
      as_current_file_offset_label:
        mov     ebp,[as_addressing_space]
        test    as_u8 [ds:ebp+0Ah],1
        if_zero as_use_current_offset
        mov     eax,[as_undefined_data_end]
        jmp     as_make_file_offset_label
      as_use_current_offset:
        mov     eax,[as_current_offset]
      as_make_file_offset_label:
        cmp     [as_output_format],2
        if_above_equal  as_invalid_use_of_symbol
        sub     eax,[as_code_start]
        jmp     as_make_dword_label_value
      as_current_offset_label:
        mov     eax,[as_current_offset]
      as_make_current_offset_label:
        xor     edx,edx
        xor     ch,ch
        mov     ebp,[as_addressing_space]
        sub     eax,[ds:ebp]
        sub_with_borrow edx,[ds:ebp+4]
        sub_with_borrow ch,[ds:ebp+8]
        jp      as_current_offset_label_ok
        call    as_recoverable_overflow
      as_current_offset_label_ok:
        stos    as_u32 [edi]
        mov     eax,edx
        stos    as_u32 [edi]
        mov     eax,[ds:ebp+10h]
        stos    as_u32 [edi]
        mov     cl,[ds:ebp+9]
        mov     [edi-12+12],cx
        mov     eax,[ds:ebp+14h]
        mov     [edi-12+16],eax
        add     edi,8
        jmp     as_calculation_loop
      as_org_origin_label:
        mov     eax,[as_addressing_space]
        mov     eax,[eax+18h]
        jmp     as_make_current_offset_label
      as_counter_label:
        mov     eax,[as_counter]
      as_make_dword_label_value:
        stos    as_u32 [edi]
        xor     eax,eax
        stos    as_u32 [edi]
        add     edi,0Ch
        jmp     as_calculation_loop
      as_timestamp_label:
        call    as_make_timestamp
      as_make_qword_label_value:
        stos    as_u32 [edi]
        mov     eax,edx
        stos    as_u32 [edi]
        add     edi,0Ch
        jmp     as_calculation_loop
      as_predefined_label:
        or      eax,eax
        if_zero as_current_offset_label
        cmp     eax,1
        if_equal        as_counter_label
        cmp     eax,2
        if_equal        as_timestamp_label
        cmp     eax,3
        if_equal        as_org_origin_label
        cmp     eax,4
        if_equal        as_current_file_offset_label
        cmp     eax,5
        if_equal        as_actual_file_offset_label
        mov     edx,as_invalid_value
        jmp     as_error_undefined
      as_label_out_of_scope:
        mov     edx,as_symbol_out_of_scope
        jmp     as_error_undefined
      as_label_undefined:
        mov     edx,as_undefined_symbol
      as_error_undefined:
        cmp     [as_current_pass],1
        if_above        as_undefined_value
      as_force_next_pass:
        or      [as_next_pass_needed],-1
      as_undefined_value:
        or      [as_value_undefined],-1
        and     as_u16 [edi+12],0
        xor     eax,eax
        stos    as_u32 [edi]
        stos    as_u32 [edi]
        add     edi,0Ch
        cmp     [as_error_line],0
        if_not_equal    as_calculation_loop
        mov     eax,[as_current_line]
        mov     [as_error_line],eax
        mov     [as_error],edx
        mov     [as_error_info],ebx
        jmp     as_calculation_loop
      as_calculate_add:
        xor     ah,ah
        mov     ah,[ebx+12]
        mov     al,[edi+12]
        or      al,al
        if_zero as_add_values
        or      ah,ah
        if_zero as_add_relocatable
        add     ah,al
        if_not_zero     as_invalid_add
        mov     ecx,[edi+16]
        cmp     ecx,[ebx+16]
        if_equal        as_add_values
      as_invalid_add:
        call    as_recoverable_misuse
        jmp     as_add_values
      as_add_relocatable:
        mov     ah,al
        mov     ecx,[edi+16]
        mov     [ebx+16],ecx
      as_add_values:
        mov     [ebx+12],ah
        mov     eax,[edi]
        add     [ebx],eax
        mov     eax,[edi+4]
        add_with_carry  [ebx+4],eax
        mov     al,[edi+13]
        add_with_carry  [ebx+13],al
        jp      as_add_sign_ok
        call    as_recoverable_overflow
      as_add_sign_ok:
        or      dx,dx
        if_zero as_calculation_loop
        push    esi
        mov     esi,ebx
        mov     cl,[edi+10]
        mov     al,[edi+8]
        call    as_add_register
        mov     cl,[edi+11]
        mov     al,[edi+9]
        call    as_add_register
        pop     esi
        jmp     as_calculation_loop
      as_add_register:
        or      al,al
        if_zero as_add_register_done
      as_add_register_start:
        cmp     [esi+8],al
        if_not_equal    as_add_in_second_slot
        add     [esi+10],cl
        if_overflow     as_value_out_of_range
        if_not_zero     as_add_register_done
        mov     as_u8 [esi+8],0
        ret
      as_add_in_second_slot:
        cmp     [esi+9],al
        if_not_equal    as_create_in_first_slot
        add     [esi+11],cl
        if_overflow     as_value_out_of_range
        if_not_zero     as_add_register_done
        mov     as_u8 [esi+9],0
        ret
      as_create_in_first_slot:
        cmp     as_u8 [esi+8],0
        if_not_equal    as_create_in_second_slot
        mov     [esi+8],al
        mov     [esi+10],cl
        ret
      as_create_in_second_slot:
        cmp     as_u8 [esi+9],0
        if_not_equal    as_invalid_expression
        mov     [esi+9],al
        mov     [esi+11],cl
      as_add_register_done:
        ret
      as_out_of_range:
        jmp     as_calculation_loop
      as_calculate_sub:
        xor     ah,ah
        mov     ah,[ebx+12]
        mov     al,[edi+12]
        or      al,al
        if_zero as_sub_values
        or      ah,ah
        if_zero as_negate_relocatable
        cmp     al,ah
        if_not_equal    as_invalid_sub
        xor     ah,ah
        mov     ecx,[edi+16]
        cmp     ecx,[ebx+16]
        if_equal        as_sub_values
      as_invalid_sub:
        call    as_recoverable_misuse
        jmp     as_sub_values
      as_negate_relocatable:
        negate  al
        mov     ah,al
        mov     ecx,[edi+16]
        mov     [ebx+16],ecx
      as_sub_values:
        mov     [ebx+12],ah
        mov     eax,[edi]
        sub     [ebx],eax
        mov     eax,[edi+4]
        sub_with_borrow [ebx+4],eax
        mov     al,[edi+13]
        sub_with_borrow [ebx+13],al
        jp      as_sub_sign_ok
        cmp     [as_error_line],0
        if_not_equal    as_sub_sign_ok
        call    as_recoverable_overflow
      as_sub_sign_ok:
        or      dx,dx
        if_zero as_calculation_loop
        push    esi
        mov     esi,ebx
        mov     cl,[edi+10]
        mov     al,[edi+8]
        call    as_sub_register
        mov     cl,[edi+11]
        mov     al,[edi+9]
        call    as_sub_register
        pop     esi
        jmp     as_calculation_loop
      as_sub_register:
        or      al,al
        if_zero as_add_register_done
        negate  cl
        if_overflow     as_value_out_of_range
        jmp     as_add_register_start
      as_calculate_mul:
        or      dx,dx
        if_zero as_mul_start
        cmp     as_u16 [ebx+8],0
        if_not_equal    as_mul_start
        xor     ecx,ecx
      as_swap_values:
        mov     eax,[ebx+ecx]
        xchg    eax,[edi+ecx]
        mov     [ebx+ecx],eax
        add     ecx,4
        cmp     ecx,16
        if_below        as_swap_values
      as_mul_start:
        push    esi edx
        mov     esi,ebx
        xor     bl,bl
        cmp     as_u8 [esi+13],0
        if_equal        as_mul_first_sign_ok
        xor     bl,-1
        mov     eax,[esi]
        mov     edx,[esi+4]
        not     eax
        not     edx
        add     eax,1
        add_with_carry  edx,0
        mov     [esi],eax
        mov     [esi+4],edx
        or      eax,edx
        if_zero as_mul_overflow
      as_mul_first_sign_ok:
        cmp     as_u8 [edi+13],0
        if_equal        as_mul_second_sign_ok
        xor     bl,-1
        cmp     as_u8 [esi+8],0
        if_equal        as_mul_first_register_sign_ok
        negate  as_u8 [esi+10]
        if_overflow     as_invalid_expression
      as_mul_first_register_sign_ok:
        cmp     as_u8 [esi+9],0
        if_equal        as_mul_second_register_sign_ok
        negate  as_u8 [esi+11]
        if_overflow     as_invalid_expression
      as_mul_second_register_sign_ok:
        mov     eax,[edi]
        mov     edx,[edi+4]
        not     eax
        not     edx
        add     eax,1
        add_with_carry  edx,0
        mov     [edi],eax
        mov     [edi+4],edx
        or      eax,edx
        if_zero as_mul_overflow
      as_mul_second_sign_ok:
        cmp     as_u32 [esi+4],0
        if_zero as_mul_numbers
        cmp     as_u32 [edi+4],0
        if_zero as_mul_numbers
        if_not_zero     as_mul_overflow
      as_mul_numbers:
        mov     eax,[esi+4]
        mul     as_u32 [edi]
        or      edx,edx
        if_not_zero     as_mul_overflow
        mov     ecx,eax
        mov     eax,[esi]
        mul     as_u32 [edi+4]
        or      edx,edx
        if_not_zero     as_mul_overflow
        add     ecx,eax
        if_carry        as_mul_overflow
        mov     eax,[esi]
        mul     as_u32 [edi]
        add     edx,ecx
        if_carry        as_mul_overflow
        mov     [esi],eax
        mov     [esi+4],edx
        or      bl,bl
        if_zero as_mul_ok
        not     eax
        not     edx
        add     eax,1
        add_with_carry  edx,0
        mov     [esi],eax
        mov     [esi+4],edx
        or      eax,edx
        if_not_zero     as_mul_ok
        not     bl
      as_mul_ok:
        mov     [esi+13],bl
        pop     edx
        or      dx,dx
        if_zero as_mul_calculated
        cmp     as_u16 [edi+8],0
        if_not_equal    as_invalid_value
        cmp     as_u8 [esi+8],0
        if_equal        as_mul_first_register_ok
        call    as_get_byte_scale
        signed_multiply as_u8 [esi+10]
        mov     dl,ah
        sign_extend_byte
        cmp     ah,dl
        if_not_equal    as_value_out_of_range
        mov     [esi+10],al
        or      al,al
        if_not_zero     as_mul_first_register_ok
        mov     [esi+8],al
      as_mul_first_register_ok:
        cmp     as_u8 [esi+9],0
        if_equal        as_mul_calculated
        call    as_get_byte_scale
        signed_multiply as_u8 [esi+11]
        mov     dl,ah
        sign_extend_byte
        cmp     ah,dl
        if_not_equal    as_value_out_of_range
        mov     [esi+11],al
        or      al,al
        if_not_zero     as_mul_calculated
        mov     [esi+9],al
      as_mul_calculated:
        pop     esi
        jmp     as_calculation_loop
      as_mul_overflow:
        pop     edx esi
        call    as_recoverable_overflow
        jmp     as_calculation_loop
      as_get_byte_scale:
        mov     al,[edi]
        sign_extend_byte
        sign_extend_word
        sign_extend_dword
        cmp     edx,[edi+4]
        if_not_equal    as_value_out_of_range
        cmp     eax,[edi]
        if_not_equal    as_value_out_of_range
        ret
      as_calculate_div:
        push    esi edx
        mov     esi,ebx
        call    as_div_64
        pop     edx
        or      dx,dx
        if_zero as_div_calculated
        cmp     as_u8 [esi+8],0
        if_equal        as_div_first_register_ok
        call    as_get_byte_scale
        or      al,al
        if_zero as_value_out_of_range
        mov     al,[esi+10]
        sign_extend_byte
        signed_divide   as_u8 [edi]
        or      ah,ah
        if_not_zero     as_invalid_use_of_symbol
        mov     [esi+10],al
      as_div_first_register_ok:
        cmp     as_u8 [esi+9],0
        if_equal        as_div_calculated
        call    as_get_byte_scale
        or      al,al
        if_zero as_value_out_of_range
        mov     al,[esi+11]
        sign_extend_byte
        signed_divide   as_u8 [edi]
        or      ah,ah
        if_not_zero     as_invalid_use_of_symbol
        mov     [esi+11],al
      as_div_calculated:
        pop     esi
        jmp     as_calculation_loop
      as_calculate_mod:
        push    esi
        mov     esi,ebx
        call    as_div_64
        mov     [esi],eax
        mov     [esi+4],edx
        mov     [esi+13],bh
        pop     esi
        jmp     as_calculation_loop
      as_calculate_and:
        mov     eax,[edi]
        mov     edx,[edi+4]
        mov     cl,[edi+13]
        and     [ebx],eax
        and     [ebx+4],edx
        and     [ebx+13],cl
        jmp     as_calculation_loop
      as_calculate_or:
        mov     eax,[edi]
        mov     edx,[edi+4]
        mov     cl,[edi+13]
        or      [ebx],eax
        or      [ebx+4],edx
        or      [ebx+13],cl
        jmp     as_calculation_loop
      as_calculate_xor:
        mov     eax,[edi]
        mov     edx,[edi+4]
        mov     cl,[edi+13]
        xor     [ebx],eax
        xor     [ebx+4],edx
        xor     [ebx+13],cl
        jmp     as_calculation_loop
      as_shr_negative:
        mov     as_u8 [edi+13],0
        not     as_u32 [edi]
        not     as_u32 [edi+4]
        add     as_u32 [edi],1
        add_with_carry  as_u32 [edi+4],0
        if_carry        as_shl_over
      as_calculate_shl:
        cmp     as_u8 [edi+13],0
        if_not_equal    as_shl_negative
        mov     edx,[ebx+4]
        mov     eax,[ebx]
        cmp     as_u32 [edi+4],0
        if_not_equal    as_shl_over
        movsx   ecx,as_u8 [ebx+13]
        xchg    ecx,[edi]
        cmp     ecx,64
        if_equal        as_shl_max
        if_above        as_shl_over
        cmp     ecx,32
        if_above_equal  as_shl_high
        shld    [edi],edx,cl
        shld    edx,eax,cl
        shl     eax,cl
        mov     [ebx],eax
        mov     [ebx+4],edx
        jmp     as_shl_done
      as_shl_over:
        cmp     as_u8 [ebx+13],0
        if_not_equal    as_shl_overflow
      as_shl_max:
        movsx   ecx,as_u8 [ebx+13]
        cmp     eax,ecx
        if_not_equal    as_shl_overflow
        cmp     edx,ecx
        if_not_equal    as_shl_overflow
        xor     eax,eax
        mov     [ebx],eax
        mov     [ebx+4],eax
        jmp     as_calculation_loop
      as_shl_high:
        sub     cl,32
        shld    [edi],edx,cl
        shld    edx,eax,cl
        shl     eax,cl
        mov     [ebx+4],eax
        and     as_u32 [ebx],0
        cmp     edx,[edi]
        if_not_equal    as_shl_overflow
      as_shl_done:
        movsx   eax,as_u8 [ebx+13]
        cmp     eax,[edi]
        if_equal        as_calculation_loop
      as_shl_overflow:
        call    as_recoverable_overflow
        jmp     as_calculation_loop
      as_shl_negative:
        mov     as_u8 [edi+13],0
        not     as_u32 [edi]
        not     as_u32 [edi+4]
        add     as_u32 [edi],1
        add_with_carry  as_u32 [edi+4],0
        if_not_carry    as_calculate_shr
        dec     as_u32 [edi+4]
      as_calculate_shr:
        cmp     as_u8 [edi+13],0
        if_not_equal    as_shr_negative
        mov     edx,[ebx+4]
        mov     eax,[ebx]
        cmp     as_u32 [edi+4],0
        if_not_equal    as_shr_over
        mov     ecx,[edi]
        cmp     ecx,64
        if_above_equal  as_shr_over
        push    esi
        movsx   esi,as_u8 [ebx+13]
        cmp     ecx,32
        if_above_equal  as_shr_high
        shrd    eax,edx,cl
        shrd    edx,esi,cl
        mov     [ebx],eax
        mov     [ebx+4],edx
        pop     esi
        jmp     as_calculation_loop
      as_shr_high:
        sub     cl,32
        shrd    edx,esi,cl
        mov     [ebx],edx
        mov     [ebx+4],esi
        pop     esi
        jmp     as_calculation_loop
      as_shr_over:
        movsx   eax,as_u8 [ebx+13]
        mov     as_u32 [ebx],eax
        mov     as_u32 [ebx+4],eax
        jmp     as_calculation_loop
      as_calculate_not:
        cmp     as_u16 [edi+8],0
        if_not_equal    as_invalid_expression
        cmp     as_u8 [edi+12],0
        if_equal        as_not_ok
        call    as_recoverable_misuse
      as_not_ok:
        not     as_u32 [edi]
        not     as_u32 [edi+4]
        not     as_u8 [edi+13]
        add     edi,14h
        jmp     as_calculation_loop
      as_calculate_bsf:
        cmp     as_u16 [edi+8],0
        if_not_equal    as_invalid_expression
        cmp     as_u8 [edi+12],0
        if_equal        as_bsf_ok
        call    as_recoverable_misuse
      as_bsf_ok:
        xor     ecx,ecx
        bit_scan_forward        eax,[edi]
        if_not_zero     as_finish_bs
        mov     ecx,32
        bit_scan_forward        eax,[edi+4]
        if_not_zero     as_finish_bs
        cmp     as_u8 [edi+13],0
        if_not_equal    as_finish_bs
      as_bs_overflow:
        call    as_recoverable_overflow
        add     edi,14h
        jmp     as_calculation_loop
      as_calculate_bsr:
        cmp     as_u16 [edi+8],0
        if_not_equal    as_invalid_expression
        cmp     as_u8 [edi+12],0
        if_equal        as_bsr_ok
        call    as_recoverable_misuse
      as_bsr_ok:
        cmp     as_u8 [edi+13],0
        if_not_equal    as_bs_overflow
        mov     ecx,32
        bit_scan_reverse        eax,[edi+4]
        if_not_zero     as_finish_bs
        xor     ecx,ecx
        bit_scan_reverse        eax,[edi]
        if_zero as_bs_overflow
      as_finish_bs:
        add     eax,ecx
        xor     edx,edx
        mov     [edi],eax
        mov     [edi+4],edx
        mov     [edi+13],dl
        add     edi,14h
        jmp     as_calculation_loop
      as_calculate_neg:
        cmp     as_u8 [edi+8],0
        if_equal        as_neg_first_register_ok
        negate  as_u8 [edi+10]
        if_overflow     as_invalid_expression
      as_neg_first_register_ok:
        cmp     as_u8 [edi+9],0
        if_equal        as_neg_second_register_ok
        negate  as_u8 [edi+11]
        if_overflow     as_invalid_expression
      as_neg_second_register_ok:
        negate  as_u8 [edi+12]
        xor     eax,eax
        xor     edx,edx
        xor     cl,cl
        xchg    eax,[edi]
        xchg    edx,[edi+4]
        xchg    cl,[edi+13]
        sub     [edi],eax
        sub_with_borrow [edi+4],edx
        sub_with_borrow [edi+13],cl
        jp      as_neg_sign_ok
        call    as_recoverable_overflow
      as_neg_sign_ok:
        add     edi,14h
        jmp     as_calculation_loop
      as_calculate_rva:
        cmp     as_u16 [edi+8],0
        if_not_equal    as_invalid_expression
        mov     al,[as_output_format]
        cmp     al,5
        if_equal        as_calculate_gotoff
        cmp     al,3
        if_not_equal    as_invalid_expression
        test    [as_format_flags],8
        if_not_zero     as_pe64_rva
        mov     al,2
        bit_test        [as_resolver_flags],0
        if_carry        as_rva_type_ok
        xor     al,al
      as_rva_type_ok:
        cmp     as_u8 [edi+12],al
        if_equal        as_rva_ok
        call    as_recoverable_misuse
      as_rva_ok:
        mov     as_u8 [edi+12],0
        mov     eax,[as_code_start]
        mov     eax,[eax+34h]
        xor     edx,edx
      as_finish_rva:
        sub     [edi],eax
        sub_with_borrow [edi+4],edx
        sub_with_borrow as_u8 [edi+13],0
        jp      as_rva_finished
        call    as_recoverable_overflow
      as_rva_finished:
        add     edi,14h
        jmp     as_calculation_loop
      as_pe64_rva:
        mov     al,4
        bit_test        [as_resolver_flags],0
        if_carry        as_pe64_rva_type_ok
        xor     al,al
      as_pe64_rva_type_ok:
        cmp     as_u8 [edi+12],al
        if_equal        as_pe64_rva_ok
        call    as_recoverable_misuse
      as_pe64_rva_ok:
        mov     as_u8 [edi+12],0
        mov     eax,[as_code_start]
        mov     edx,[eax+34h]
        mov     eax,[eax+30h]
        jmp     as_finish_rva
      as_calculate_gotoff:
        test    [as_format_flags],1
        if_not_zero     as_calculate_elf_dyn_rva
        test    [as_format_flags],8
        if_not_zero     as_invalid_expression
      as_incorrect_change_of_value_type:
        call    as_recoverable_misuse
      as_change_value_type:
        mov     as_u8 [edi+12],dl
        add     edi,14h
        jmp     as_calculation_loop
      as_calculate_elf_dyn_rva:
        xor     dl,dl
        test    as_u8 [edi+12],1
        if_not_zero     as_incorrect_change_of_value_type
        jmp     as_change_value_type
      as_calculate_plt:
        cmp     as_u16 [edi+8],0
        if_not_equal    as_invalid_expression
        cmp     [as_output_format],5
        if_not_equal    as_invalid_expression
        test    [as_format_flags],1
        if_not_zero     as_invalid_expression
        mov     dl,6
        mov     dh,2
        test    [as_format_flags],8
        if_zero as_check_value_for_plt
        mov     dh,4
      as_check_value_for_plt:
        mov     eax,[edi]
        or      eax,[edi+4]
        if_not_zero     as_incorrect_change_of_value_type
        cmp     as_u8 [edi+12],dh
        if_not_equal    as_incorrect_change_of_value_type
        mov     eax,[edi+16]
        cmp     as_u8 [eax],80h
        if_not_equal    as_incorrect_change_of_value_type
        jmp     as_change_value_type
      as_div_64:
        xor     ebx,ebx
        cmp     as_u32 [edi],0
        if_not_equal    as_divider_ok
        cmp     as_u32 [edi+4],0
        if_not_equal    as_divider_ok
        cmp     [as_next_pass_needed],0
        if_equal        as_value_out_of_range
        jmp     as_div_done
      as_divider_ok:
        cmp     as_u8 [esi+13],0
        if_equal        as_div_first_sign_ok
        mov     eax,[esi]
        mov     edx,[esi+4]
        not     eax
        not     edx
        add     eax,1
        add_with_carry  edx,0
        mov     [esi],eax
        mov     [esi+4],edx
        or      eax,edx
        if_zero as_value_out_of_range
        xor     bx,-1
      as_div_first_sign_ok:
        cmp     as_u8 [edi+13],0
        if_equal        as_div_second_sign_ok
        mov     eax,[edi]
        mov     edx,[edi+4]
        not     eax
        not     edx
        add     eax,1
        add_with_carry  edx,0
        mov     [edi],eax
        mov     [edi+4],edx
        or      eax,edx
        if_zero as_value_out_of_range
        xor     bl,-1
      as_div_second_sign_ok:
        cmp     as_u32 [edi+4],0
        if_not_equal    as_div_high
        mov     ecx,[edi]
        mov     eax,[esi+4]
        xor     edx,edx
        div     ecx
        mov     [esi+4],eax
        mov     eax,[esi]
        div     ecx
        mov     [esi],eax
        mov     eax,edx
        xor     edx,edx
        jmp     as_div_done
      as_div_high:
        push    ebx
        mov     eax,[esi+4]
        xor     edx,edx
        div     as_u32 [edi+4]
        mov     ebx,[esi]
        mov     [esi],eax
        and     as_u32 [esi+4],0
        mov     ecx,edx
        mul     as_u32 [edi]
      as_div_high_loop:
        cmp     ecx,edx
        if_above        as_div_high_done
        if_below        as_div_high_large_correction
        cmp     ebx,eax
        if_above_equal  as_div_high_done
      as_div_high_correction:
        dec     as_u32 [esi]
        sub     eax,[edi]
        sub_with_borrow edx,[edi+4]
        if_not_carry    as_div_high_loop
      as_div_high_done:
        sub     ebx,eax
        sub_with_borrow ecx,edx
        mov     edx,ecx
        mov     eax,ebx
        pop     ebx
        jmp     as_div_done
      as_div_high_large_correction:
        push    eax edx
        mov     eax,edx
        sub     eax,ecx
        xor     edx,edx
        div     as_u32 [edi+4]
        shr     eax,1
        if_zero as_div_high_small_correction
        sub     [esi],eax
        push    eax
        mul     as_u32 [edi+4]
        sub     as_u32 [esp+4],eax
        pop     eax
        mul     as_u32 [edi]
        sub     as_u32 [esp+4],eax
        sub_with_borrow as_u32 [esp],edx
        pop     edx eax
        jmp     as_div_high_loop
      as_div_high_small_correction:
        pop     edx eax
        jmp     as_div_high_correction
      as_div_done:
        or      bh,bh
        if_zero as_remainder_ok
        not     eax
        not     edx
        add     eax,1
        add_with_carry  edx,0
        mov     ecx,eax
        or      ecx,edx
        if_not_zero     as_remainder_ok
        not     bh
      as_remainder_ok:
        or      bl,bl
        if_zero as_div_ok
        not     as_u32 [esi]
        not     as_u32 [esi+4]
        add     as_u32 [esi],1
        add_with_carry  as_u32 [esi+4],0
        mov     ecx,[esi]
        or      ecx,[esi+4]
        if_not_zero     as_div_ok
        not     bl
      as_div_ok:
        mov     [esi+13],bl
        ret
      as_store_label_reference:
        cmp     [as_symbols_file],0
        if_equal        as_label_reference_ok
        cmp     [as_next_pass_needed],0
        if_not_equal    as_label_reference_ok
        mov     eax,[as_tagged_blocks]
        mov     as_u32 [eax-4],2
        mov     as_u32 [eax-8],4
        sub     eax,8+4
        cmp     eax,edi
        if_below_equal  as_out_of_memory
        mov     [as_tagged_blocks],eax
        mov     [eax],ebx
      as_label_reference_ok:
        ret
      as_convert_fp:
        inc     esi
        and     as_u16 [edi+8],0
        and     as_u16 [edi+12],0
        mov     al,[as_value_size]
        cmp     al,2
        if_equal        as_convert_fp_word
        cmp     al,4
        if_equal        as_convert_fp_dword
        test    al,not 8
        if_zero as_convert_fp_qword
        call    as_recoverable_misuse
      as_convert_fp_qword:
        xor     eax,eax
        xor     edx,edx
        cmp     as_u16 [esi+8],8000h
        if_equal        as_fp_qword_store
        mov     bx,[esi+8]
        mov     eax,[esi]
        mov     edx,[esi+4]
        add     eax,eax
        add_with_carry  edx,edx
        mov     ecx,edx
        shr     edx,12
        shrd    eax,ecx,12
        if_not_carry    as_fp_qword_ok
        add     eax,1
        add_with_carry  edx,0
        bit_test        edx,20
        if_not_carry    as_fp_qword_ok
        and     edx,1 shl 20 - 1
        inc     bx
        shr     edx,1
        rcr     eax,1
      as_fp_qword_ok:
        add     bx,3FFh
        cmp     bx,7FFh
        if_greater_equal        as_value_out_of_range
        cmp     bx,0
        if_greater      as_fp_qword_exp_ok
        or      edx,1 shl 20
        mov     cx,bx
        negate  cx
        inc     cx
        cmp     cx,52+1
        if_above        as_value_out_of_range
        cmp     cx,32
        if_below        as_fp_qword_small_shift
        sub     cx,32
        mov     eax,edx
        xor     edx,edx
        shr     eax,cl
        jmp     as_fp_qword_shift_done
      as_fp_qword_small_shift:
        mov     ebx,edx
        shr     edx,cl
        shrd    eax,ebx,cl
      as_fp_qword_shift_done:
        mov     bx,0
        if_not_carry    as_fp_qword_exp_ok
        add     eax,1
        add_with_carry  edx,0
        test    edx,1 shl 20
        if_zero as_fp_qword_exp_ok
        and     edx,1 shl 20 - 1
        inc     bx
      as_fp_qword_exp_ok:
        shl     ebx,20
        or      edx,ebx
        if_not_zero     as_fp_qword_store
        or      eax,eax
        if_zero as_value_out_of_range
      as_fp_qword_store:
        ; pack float32/64 sign bit into high word (inline: pack_sign32 edx, [esi+11])
        mov     bl,[esi+11]
        shl     ebx,31
        or      edx,ebx
        mov     [edi],eax
        mov     [edi+4],edx
        add     esi,13
        ret
      as_convert_fp_word:
        xor     eax,eax
        cmp     as_u16 [esi+8],8000h
        if_equal        as_fp_word_store
        mov     bx,[esi+8]
        mov     ax,[esi+6]
        shl     ax,1
        shr     ax,6
        if_not_carry    as_fp_word_ok
        inc     ax
        bit_test        ax,10
        if_not_carry    as_fp_word_ok
        and     ax,1 shl 10 - 1
        inc     bx
        shr     ax,1
      as_fp_word_ok:
        add     bx,0Fh
        cmp     bx,01Fh
        if_greater_equal        as_value_out_of_range
        cmp     bx,0
        if_greater      as_fp_word_exp_ok
        or      ax,1 shl 10
        mov     cx,bx
        negate  cx
        inc     cx
        cmp     cx,10+1
        if_above        as_value_out_of_range
        xor     bx,bx
        shr     ax,cl
        if_not_carry    as_fp_word_exp_ok
        inc     ax
        test    ax,1 shl 10
        if_zero as_fp_word_exp_ok
        and     ax,1 shl 10 - 1
        inc     bx
      as_fp_word_exp_ok:
        shl     bx,10
        or      ax,bx
        if_zero as_value_out_of_range
      as_fp_word_store:
        ; pack float16 sign bit into result word (inline: pack_sign16 ax, [esi+11])
        mov     bl,[esi+11]
        shl     bx,15
        or      ax,bx
        mov     [edi], eax
        xor     eax, eax
        mov     [edi+4], eax
        add     esi, 13
        ret
      as_convert_fp_dword:
        xor     eax,eax
        cmp     as_u16 [esi+8],8000h
        if_equal        as_fp_dword_store
        mov     bx,[esi+8]
        mov     eax,[esi+4]
        shl     eax,1
        shr     eax,9
        if_not_carry    as_fp_dword_ok
        inc     eax
        bit_test        eax,23
        if_not_carry    as_fp_dword_ok
        and     eax,1 shl 23 - 1
        inc     bx
        shr     eax,1
      as_fp_dword_ok:
        add     bx,7Fh
        cmp     bx,0FFh
        if_greater_equal        as_value_out_of_range
        cmp     bx,0
        if_greater      as_fp_dword_exp_ok
        or      eax,1 shl 23
        mov     cx,bx
        negate  cx
        inc     cx
        cmp     cx,23+1
        if_above        as_value_out_of_range
        xor     bx,bx
        shr     eax,cl
        if_not_carry    as_fp_dword_exp_ok
        inc     eax
        test    eax,1 shl 23
        if_zero as_fp_dword_exp_ok
        and     eax,1 shl 23 - 1
        inc     bx
      as_fp_dword_exp_ok:
        shl     ebx,23
        or      eax,ebx
        if_zero as_value_out_of_range
      as_fp_dword_store:
        ; pack float32 sign bit into result (inline: pack_sign32 eax, [esi+11])
        mov     bl,[esi+11]
        shl     ebx,31
        or      eax,ebx
        mov     [edi], eax
        xor     eax, eax
        mov     [edi+4], eax
        add     esi, 13
        ret
      as_get_string_value:
        inc     esi
        lods    as_u32 [esi]
        mov     ecx,eax
        cmp     ecx,8
        if_above        as_value_out_of_range
        mov     edx,edi
        xor     eax,eax
        stos    as_u32 [edi]
        stos    as_u32 [edi]
        mov     edi,edx
        rep     movs as_u8 [edi],[esi]
        mov     edi,edx
        inc     esi
        and     as_u16 [edi+8],0
        and     as_u16 [edi+12],0
        ret

as_get_byte_value:
        mov     [as_value_size],1
        or      [as_operand_flags],1
        call    as_calculate_value
        or      al,al
        if_zero as_check_byte_value
        call    as_recoverable_misuse
      as_check_byte_value:
        mov     eax,[edi]
        mov     edx,[edi+4]
        cmp     as_u8 [edi+13],0
        if_equal        as_byte_positive
        cmp     edx,-1
        if_not_equal    as_range_exceeded
        cmp     eax,-100h
        if_below        as_range_exceeded
        ret
      as_byte_positive:
        test    edx,edx
        if_not_zero     as_range_exceeded
        cmp     eax,100h
        if_above_equal  as_range_exceeded
      as_return_byte_value:
        ret
      as_range_exceeded:
        xor     eax,eax
        xor     edx,edx
      as_recoverable_overflow:
        cmp     [as_error_line],0
        if_not_equal    as_ignore_overflow
        push    [as_current_line]
        pop     [as_error_line]
        mov     [as_error],as_value_out_of_range
        or      [as_value_undefined],-1
      as_ignore_overflow:
        ret
      as_recoverable_misuse:
        cmp     [as_error_line],0
        if_not_equal    as_ignore_misuse
        push    [as_current_line]
        pop     [as_error_line]
        mov     [as_error],as_invalid_use_of_symbol
      as_ignore_misuse:
        ret
as_get_word_value:
        mov     [as_value_size],2
        or      [as_operand_flags],1
        call    as_calculate_value
        cmp     al,2
        if_below        as_check_word_value
        call    as_recoverable_misuse
      as_check_word_value:
        mov     eax,[edi]
        mov     edx,[edi+4]
        cmp     as_u8 [edi+13],0
        if_equal        as_word_positive
        cmp     edx,-1
        if_not_equal    as_range_exceeded
        cmp     eax,-10000h
        if_below        as_range_exceeded
        ret
      as_word_positive:
        test    edx,edx
        if_not_zero     as_range_exceeded
        cmp     eax,10000h
        if_above_equal  as_range_exceeded
        ret
as_get_dword_value:
        mov     [as_value_size],4
        or      [as_operand_flags],1
        call    as_calculate_value
        cmp     al,4
        if_not_equal    as_check_dword_value
        mov     [as_value_type],2
        mov     eax,[edi]
        sign_extend_dword
        cmp     edx,[edi+4]
        if_not_equal    as_range_exceeded
        mov     ecx,edx
        sar     ecx,31
        cmp     cl,[as_value_sign]
        if_not_equal    as_range_exceeded
        ret
      as_check_dword_value:
        mov     eax,[edi]
        mov     edx,[edi+4]
        cmp     as_u8 [edi+13],0
        if_equal        as_dword_positive
        cmp     edx,-1
        if_not_equal    as_range_exceeded
        ret
      as_dword_positive:
        test    edx,edx
        if_not_equal    as_range_exceeded
        ret
as_get_pword_value:
        mov     [as_value_size],6
        or      [as_operand_flags],1
        call    as_calculate_value
        cmp     al,4
        if_not_equal    as_check_pword_value
        call    as_recoverable_misuse
      as_check_pword_value:
        mov     eax,[edi]
        mov     edx,[edi+4]
        cmp     as_u8 [edi+13],0
        if_equal        as_pword_positive
        cmp     edx,-10000h
        if_below        as_range_exceeded
        ret
      as_pword_positive:
        cmp     edx,10000h
        if_above_equal  as_range_exceeded
        ret
as_get_qword_value:
        mov     [as_value_size],8
        or      [as_operand_flags],1
        call    as_calculate_value
      as_check_qword_value:
        mov     eax,[edi]
        mov     edx,[edi+4]
        ret
as_get_count_value:
        mov     [as_value_size],8
        or      [as_operand_flags],1
        call    as_calculate_expression
        cmp     as_u16 [edi+8],0
        if_not_equal    as_invalid_value
        mov     [as_value_sign],0
        mov     al,[edi+12]
        or      al,al
        if_zero as_check_count_value
        call    as_recoverable_misuse
      as_check_count_value:
        cmp     as_u8 [edi+13],0
        if_not_equal    as_invalid_count_value
        mov     eax,[edi]
        mov     edx,[edi+4]
        or      edx,edx
        if_not_zero     as_invalid_count_value
        ret
      as_invalid_count_value:
        cmp     [as_error_line],0
        if_not_equal    as_zero_count
        mov     eax,[as_current_line]
        mov     [as_error_line],eax
        mov     [as_error],as_invalid_value
      as_zero_count:
        xor     eax,eax
        ret
as_get_value:
        mov     [as_operand_size],0
        lods    as_u8 [esi]
        call    as_get_size_operator
        cmp     al,'('
        if_not_equal    as_invalid_value
        mov     al,[as_operand_size]
        cmp     al,1
        if_equal        as_value_byte
        cmp     al,2
        if_equal        as_value_word
        cmp     al,4
        if_equal        as_value_dword
        cmp     al,6
        if_equal        as_value_pword
        cmp     al,8
        if_equal        as_value_qword
        or      al,al
        if_not_zero     as_invalid_value
        mov     [as_value_size],al
        call    as_calculate_value
        mov     eax,[edi]
        mov     edx,[edi+4]
        ret
      as_calculate_value:
        call    as_calculate_expression
        cmp     as_u16 [edi+8],0
        if_not_equal    as_invalid_value
        mov     eax,[edi+16]
        mov     [as_symbol_identifier],eax
        mov     al,[edi+13]
        mov     [as_value_sign],al
        mov     al,[edi+12]
        mov     [as_value_type],al
        ret
      as_value_qword:
        call    as_get_qword_value
      as_truncated_value:
        mov     [as_value_sign],0
        ret
      as_value_pword:
        call    as_get_pword_value
        movzx   edx,dx
        jmp     as_truncated_value
      as_value_dword:
        call    as_get_dword_value
        xor     edx,edx
        jmp     as_truncated_value
      as_value_word:
        call    as_get_word_value
        xor     edx,edx
        movzx   eax,ax
        jmp     as_truncated_value
      as_value_byte:
        call    as_get_byte_value
        xor     edx,edx
        movzx   eax,al
        jmp     as_truncated_value
as_get_address_word_value:
        mov     [as_address_size],2
        mov     [as_value_size],2
        mov     [as_free_address_range],0
        jmp     as_calculate_address
as_get_address_dword_value:
        mov     [as_address_size],4
        mov     [as_value_size],4
        mov     [as_free_address_range],0
        jmp     as_calculate_address
as_get_address_qword_value:
        mov     [as_address_size],8
        mov     [as_value_size],8
        mov     [as_free_address_range],0
        jmp     as_calculate_address
as_get_address_value:
        mov     [as_address_size],0
        mov     [as_value_size],8
        or      [as_free_address_range],-1
      as_calculate_address:
        cmp     as_u8 [esi],'.'
        if_equal        as_invalid_address
        call    as_calculate_expression
        mov     eax,[edi+16]
        mov     [as_address_symbol],eax
        mov     al,[edi+13]
        mov     [as_address_sign],al
        mov     al,[edi+12]
        mov     [as_value_type],al
        cmp     al,0
        if_equal        as_address_size_ok
        if_greater      as_get_address_symbol_size
        negate  al
      as_get_address_symbol_size:
        cmp     al,6
        if_equal        as_special_address_type_32bit
        cmp     al,5
        if_equal        as_special_address_type_32bit
        if_above        as_invalid_address_type
        test    al,1
        if_not_zero     as_invalid_address_type
        shl     al,5
        jmp     as_address_symbol_ok
      as_invalid_address_type:
        call    as_recoverable_misuse
      as_special_address_type_32bit:
        mov     al,40h
      as_address_symbol_ok:
        mov     ah,[as_address_size]
        or      [as_address_size],al
        shr     al,4
        or      ah,ah
        if_zero as_address_size_ok
        cmp     al,ah
        if_equal        as_address_size_ok
        cmp     ax,0408h
        if_equal        as_address_sizes_mixed
        cmp     ax,0804h
        if_not_equal    as_address_sizes_do_not_agree
      as_address_sizes_mixed:
        cmp     [as_value_type],4
        if_not_equal    as_address_sizes_mixed_type_ok
        mov     [as_value_type],2
      as_address_sizes_mixed_type_ok:
        mov     eax,[edi]
        sign_extend_dword
        cmp     edx,[edi+4]
        if_equal        as_address_size_ok
        cmp     [as_error_line],0
        if_not_equal    as_address_size_ok
        call    as_recoverable_overflow
      as_address_size_ok:
        xor     ebx,ebx
        xor     ecx,ecx
        mov     cl,[as_value_type]
        shl     ecx,16
        mov     ch,[as_address_size]
        cmp     as_u16 [edi+8],0
        if_equal        as_check_immediate_address
        mov     al,[edi+8]
        mov     dl,[edi+10]
        call    as_get_address_register
        mov     al,[edi+9]
        mov     dl,[edi+11]
        call    as_get_address_register
        mov     ax,bx
        shr     ah,4
        shr     al,4
        or      bh,bh
        if_zero as_check_address_registers
        or      bl,bl
        if_zero as_check_address_registers
        cmp     al,ah
        if_not_equal    as_check_vsib
      as_check_address_registers:
        or      al,ah
        cmp     al,0Ch
        if_above_equal  as_check_vsib
        cmp     al,6
        if_equal        as_check_vsib
        cmp     al,7
        if_equal        as_check_vsib
        mov     ah,[as_address_size]
        and     ah,0Fh
        if_zero as_address_registers_sizes_ok
        cmp     al,ah
        if_not_equal    as_invalid_address
      as_address_registers_sizes_ok:
        cmp     al,4
        if_equal        as_sib_allowed
        cmp     al,8
        if_equal        as_sib_allowed
        cmp     al,9
        if_equal        as_check_ip_relative_address
        cmp     cl,1
        if_above        as_invalid_address
        cmp     [as_free_address_range],0
        if_not_equal    as_check_qword_value
        jmp     as_check_word_value
      as_address_sizes_do_not_match:
        cmp     al,0Fh
        if_not_equal    as_invalid_address
        mov     al,bh
        and     al,0Fh
        cmp     al,ah
        if_not_equal    as_invalid_address
      as_check_ip_relative_address:
        or      bl,bl
        if_not_zero     as_invalid_address
        cmp     bh,98h
        if_equal        as_check_rip_relative_address
        cmp     bh,94h
        if_not_equal    as_invalid_address
        cmp     [as_free_address_range],0
        if_equal        as_check_dword_value
        mov     eax,[edi]
        mov     edx,[edi+4]
        ret
      as_check_rip_relative_address:
        mov     eax,[edi]
        sign_extend_dword
        cmp     edx,[edi+4]
        if_not_equal    as_range_exceeded
        cmp     dl,[edi+13]
        if_not_equal    as_range_exceeded
        ret
      as_get_address_register:
        or      al,al
        if_zero as_address_register_ok
        cmp     dl,1
        if_not_equal    as_scaled_register
        or      bh,bh
        if_not_zero     as_scaled_register
        mov     bh,al
      as_address_register_ok:
        ret
      as_scaled_register:
        or      bl,bl
        if_not_zero     as_invalid_address
        mov     bl,al
        mov     cl,dl
        jmp     as_address_register_ok
      as_sib_allowed:
        or      bh,bh
        if_not_zero     as_check_index_with_base
        cmp     cl,3
        if_equal        as_special_index_scale
        cmp     cl,5
        if_equal        as_special_index_scale
        cmp     cl,9
        if_equal        as_special_index_scale
        cmp     cl,2
        if_not_equal    as_check_index_scale
        cmp     bl,45h
        if_not_equal    as_special_index_scale
        cmp     [as_segment_register],4
        if_not_equal    as_special_index_scale
        cmp     [as_value_type],0
        if_not_equal    as_check_index_scale
        mov     al,[edi]
        sign_extend_byte
        sign_extend_word
        cmp     eax,[edi]
        if_not_equal    as_check_index_scale
        sign_extend_dword
        cmp     edx,[edi+4]
        if_not_equal    as_check_immediate_address
      as_special_index_scale:
        mov     bh,bl
        dec     cl
      as_check_immediate_address:
        cmp     [as_free_address_range],0
        if_not_equal    as_check_qword_value
        mov     al,[as_address_size]
        and     al,0Fh
        cmp     al,2
        if_equal        as_check_word_value
        cmp     al,4
        if_equal        as_check_dword_value
        cmp     al,8
        if_equal        as_check_qword_value
        or      al,al
        if_not_zero     as_invalid_value
        jmp     as_check_dword_value
        jmp     as_check_qword_value
      as_check_index_with_base:
        cmp     cl,1
        if_not_equal    as_check_index_scale
        cmp     bl,44h
        if_equal        as_swap_base_with_index
        cmp     bl,84h
        if_equal        as_swap_base_with_index
        cmp     bl,45h
        if_not_equal    as_check_for_ebp_base
        cmp     [as_segment_register],3
        if_equal        as_swap_base_with_index
        jmp     as_check_immediate_address
      as_check_for_ebp_base:
        cmp     bh,45h
        if_not_equal    as_check_immediate_address
        cmp     [as_segment_register],4
        if_not_equal    as_check_immediate_address
      as_swap_base_with_index:
        xchg    bl,bh
        jmp     as_check_immediate_address
      as_check_for_rbp_base:
        cmp     bh,45h
        if_equal        as_swap_base_with_index
        cmp     bh,85h
        if_equal        as_swap_base_with_index
        jmp     as_check_immediate_address
      as_check_index_scale:
        test    cl,not 1111b
        if_not_zero     as_invalid_address
        mov     al,cl
        dec     al
        and     al,cl
        if_zero as_check_immediate_address
        jmp     as_invalid_address
      as_check_vsib:
        xor     ah,ah
      as_check_vsib_base:
        test    bh,bh
        if_zero as_check_vsib_index
        mov     al,bh
        shr     al,4
        cmp     al,4
        if_equal        as_check_vsib_base_size
        jmp     as_swap_vsib_registers
        cmp     al,8
        if_not_equal    as_swap_vsib_registers
      as_check_vsib_base_size:
        mov     ah,[as_address_size]
        and     ah,0Fh
        if_zero as_check_vsib_index
        cmp     al,ah
        if_not_equal    as_invalid_address
      as_check_vsib_index:
        mov     al,bl
        and     al,0E0h
        cmp     al,0C0h
        if_above_equal  as_check_index_scale
        cmp     al,60h
        if_equal        as_check_index_scale
        jmp     as_invalid_address
      as_swap_vsib_registers:
        xor     ah,-1
        if_zero as_invalid_address
        cmp     cl,1
        if_above        as_invalid_address
        xchg    bl,bh
        mov     cl,1
        jmp     as_check_vsib_base

as_calculate_relative_offset:
        cmp     [as_value_undefined],0
        if_not_equal    as_relative_offset_ok
        test    bh,bh
        setne   ch
        cmp     bx,[ds:ebp+10h]
        if_equal        as_origin_registers_ok
        xchg    bh,bl
        xchg    ch,cl
        cmp     bx,[ds:ebp+10h]
        if_not_equal    as_invalid_value
      as_origin_registers_ok:
        cmp     cx,[ds:ebp+10h+2]
        if_not_equal    as_invalid_value
        mov     bl,[as_address_sign]
        add     eax,[ds:ebp]
        add_with_carry  edx,[ds:ebp+4]
        add_with_carry  bl,[ds:ebp+8]
        sub     eax,edi
        sub_with_borrow edx,0
        sub_with_borrow bl,0
        mov     [as_value_sign],bl
        mov     bl,[as_value_type]
        mov     ecx,[as_address_symbol]
        mov     [as_symbol_identifier],ecx
        test    bl,1
        if_not_zero     as_relative_offset_unallowed
        cmp     bl,6
        if_equal        as_plt_relative_offset
        mov     bh,[ds:ebp+9]
        cmp     bl,bh
        if_equal        as_set_relative_offset_type
        cmp     bx,0402h
        if_equal        as_set_relative_offset_type
      as_relative_offset_unallowed:
        call    as_recoverable_misuse
      as_set_relative_offset_type:
        cmp     [as_value_type],0
        if_equal        as_relative_offset_ok
        mov     [as_value_type],0
        cmp     ecx,[ds:ebp+14h]
        if_equal        as_relative_offset_ok
        mov     [as_value_type],3
      as_relative_offset_ok:
        ret
      as_plt_relative_offset:
        mov     [as_value_type],7
        cmp     as_u8 [ds:ebp+9],2
        if_equal        as_relative_offset_ok
        cmp     as_u8 [ds:ebp+9],4
        if_not_equal    as_recoverable_misuse
        ret

as_calculate_logical_expression:
        xor     al,al
      as_calculate_embedded_logical_expression:
        mov     [as_logical_value_wrapping],al
        call    as_get_logical_value
      as_logical_loop:
        cmp     as_u8 [esi],'|'
        if_equal        as_logical_or
        cmp     as_u8 [esi],'&'
        if_equal        as_logical_and
        ret
      as_logical_or:
        inc     esi
        or      al,al
        if_not_zero     as_logical_value_already_determined
        push    eax
        call    as_get_logical_value
        pop     ebx
        or      al,bl
        jmp     as_logical_loop
      as_logical_and:
        inc     esi
        or      al,al
        if_zero as_logical_value_already_determined
        push    eax
        call    as_get_logical_value
        pop     ebx
        and     al,bl
        jmp     as_logical_loop
      as_logical_value_already_determined:
        push    eax
        call    as_skip_logical_value
        if_carry        as_invalid_expression
        pop     eax
        jmp     as_logical_loop
      as_get_value_for_comparison:
        mov     [as_value_size],8
        or      [as_operand_flags],1
        lods    as_u8 [esi]
        call    as_calculate_expression
        cmp     as_u8 [edi+8],0
        if_not_equal    as_first_register_size_ok
        mov     as_u8 [edi+10],0
      as_first_register_size_ok:
        cmp     as_u8 [edi+9],0
        if_not_equal    as_second_register_size_ok
        mov     as_u8 [edi+11],0
      as_second_register_size_ok:
        mov     eax,[edi+16]
        mov     [as_symbol_identifier],eax
        mov     al,[edi+13]
        mov     [as_value_sign],al
        mov     bl,[edi+12]
        mov     eax,[edi]
        mov     edx,[edi+4]
        mov     ecx,[edi+8]
        ret
      as_get_logical_value:
        xor     al,al
      as_check_for_negation:
        cmp     as_u8 [esi],'~'
        if_not_equal    as_negation_ok
        inc     esi
        xor     al,-1
        jmp     as_check_for_negation
      as_negation_ok:
        push    eax
        mov     al,[esi]
        cmp     al,91h
        if_equal        as_logical_expression
        cmp     al,0FFh
        if_equal        as_invalid_expression
        cmp     al,88h
        if_equal        as_check_for_defined
        cmp     al,8Ah
        if_equal        as_check_for_earlier_defined
        cmp     al,89h
        if_equal        as_check_for_used
        cmp     al,'0'
        if_equal        as_given_false
        cmp     al,'1'
        if_equal        as_given_true
        cmp     al,'('
        if_not_equal    as_invalid_value
        call    as_get_value_for_comparison
        mov     bh,[as_value_sign]
        push    eax edx
        push    [as_symbol_identifier]
        push    ebx ecx
        mov     al,[esi]
        or      al,al
        if_zero as_logical_number
        cmp     al,0Fh
        if_equal        as_logical_number
        cmp     al,92h
        if_equal        as_logical_number
        cmp     al,'&'
        if_equal        as_logical_number
        cmp     al,'|'
        if_equal        as_logical_number
        inc     esi
        mov     [as_compare_type],al
        cmp     as_u8 [esi],'('
        if_not_equal    as_invalid_value
        call    as_get_value_for_comparison
        cmp     bl,[esp+4]
        if_not_equal    as_values_not_relative
        or      bl,bl
        if_zero as_check_values_registers
        mov     ebx,[as_symbol_identifier]
        cmp     ebx,[esp+8]
        if_not_equal    as_values_not_relative
      as_check_values_registers:
        cmp     ecx,[esp]
        if_equal        as_values_relative
        ror     ecx,16
        xchg    ch,cl
        ror     ecx,16
        xchg    ch,cl
        cmp     ecx,[esp]
        if_equal        as_values_relative
      as_values_not_relative:
        cmp     [as_compare_type],0F8h
        if_not_equal    as_invalid_comparison
        add     esp,12+8
        jmp     as_return_false
      as_invalid_comparison:
        call    as_recoverable_misuse
      as_values_relative:
        pop     ebx
        shl     ebx,16
        mov     bx,[esp]
        add     esp,8
        pop     ecx ebp
        cmp     [as_compare_type],'='
        if_equal        as_check_equal
        cmp     [as_compare_type],0F1h
        if_equal        as_check_not_equal
        cmp     [as_compare_type],0F8h
        if_equal        as_return_true
        test    ebx,0FFFF0000h
        if_zero as_check_less_or_greater
        call    as_recoverable_misuse
      as_check_less_or_greater:
        cmp     [as_compare_type],'>'
        if_equal        as_check_greater
        cmp     [as_compare_type],'<'
        if_equal        as_check_less
        cmp     [as_compare_type],0F2h
        if_equal        as_check_not_less
        cmp     [as_compare_type],0F3h
        if_equal        as_check_not_greater
        jmp     as_invalid_expression
      as_check_equal:
        cmp     bh,[as_value_sign]
        if_not_equal    as_return_false
        cmp     eax,ebp
        if_not_equal    as_return_false
        cmp     edx,ecx
        if_not_equal    as_return_false
        jmp     as_return_true
      as_check_greater:
        cmp     bh,[as_value_sign]
        if_greater      as_return_true
        if_less as_return_false
        cmp     edx,ecx
        if_below        as_return_true
        if_above        as_return_false
        cmp     eax,ebp
        if_below        as_return_true
        if_above_equal  as_return_false
      as_check_less:
        cmp     bh,[as_value_sign]
        if_greater      as_return_false
        if_less as_return_true
        cmp     edx,ecx
        if_below        as_return_false
        if_above        as_return_true
        cmp     eax,ebp
        if_below_equal  as_return_false
        if_above        as_return_true
      as_check_not_less:
        cmp     bh,[as_value_sign]
        if_greater      as_return_true
        if_less as_return_false
        cmp     edx,ecx
        if_below        as_return_true
        if_above        as_return_false
        cmp     eax,ebp
        if_below_equal  as_return_true
        if_above        as_return_false
      as_check_not_greater:
        cmp     bh,[as_value_sign]
        if_greater      as_return_false
        if_less as_return_true
        cmp     edx,ecx
        if_below        as_return_false
        if_above        as_return_true
        cmp     eax,ebp
        if_below        as_return_false
        if_above_equal  as_return_true
      as_check_not_equal:
        cmp     bh,[as_value_sign]
        if_not_equal    as_return_true
        cmp     eax,ebp
        if_not_equal    as_return_true
        cmp     edx,ecx
        if_not_equal    as_return_true
        jmp     as_return_false
      as_logical_number:
        pop     ecx ebx eax edx eax
        or      bl,bl
        if_not_zero     as_invalid_logical_number
        or      cx,cx
        if_zero as_logical_number_ok
      as_invalid_logical_number:
        call    as_recoverable_misuse
      as_logical_number_ok:
        test    bh,bh
        if_not_zero     as_return_true
        or      eax,edx
        if_not_zero     as_return_true
        jmp     as_return_false
      as_check_for_earlier_defined:
        or      bh,-1
        jmp     as_check_if_expression_defined
      as_check_for_defined:
        xor     bh,bh
      as_check_if_expression_defined:
        or      bl,-1
        lods    as_u16 [esi]
        cmp     ah,'('
        if_not_equal    as_invalid_expression
      as_check_expression:
        lods    as_u8 [esi]
        or      al,al
        if_zero as_defined_string
        cmp     al,'.'
        if_equal        as_defined_fp_value
        cmp     al,')'
        if_equal        as_expression_checked
        cmp     al,'!'
        if_equal        as_invalid_expression
        cmp     al,0Fh
        if_equal        as_check_expression
        cmp     al,10h
        if_equal        as_defined_register
        cmp     al,11h
        if_equal        as_check_if_symbol_defined
        cmp     al,80h
        if_above_equal  as_check_expression
        movzx   eax,al
        add     esi,eax
        jmp     as_check_expression
      as_defined_register:
        inc     esi
        jmp     as_check_expression
      as_defined_fp_value:
        add     esi,12+1
        jmp     as_expression_checked
      as_defined_string:
        lods    as_u32 [esi]
        add     esi,eax
        inc     esi
        jmp     as_expression_checked
      as_check_if_symbol_defined:
        lods    as_u32 [esi]
        cmp     eax,-1
        if_equal        as_invalid_expression
        cmp     eax,0Fh
        if_below        as_check_expression
        if_equal        as_reserved_word_used_as_symbol
        test    bh,bh
        if_not_zero     as_no_prediction
        test    as_u8 [eax+8],4
        if_not_zero     as_no_prediction
        test    as_u8 [eax+8],1
        if_zero as_symbol_predicted_undefined
        mov     cx,[as_current_pass]
        sub     cx,[eax+16]
        if_zero as_check_expression
        cmp     cx,1
        if_above        as_symbol_predicted_undefined
        or      as_u8 [eax+8],40h+80h
        jmp     as_check_expression
      as_no_prediction:
        test    as_u8 [eax+8],1
        if_zero as_symbol_undefined
        mov     cx,[as_current_pass]
        sub     cx,[eax+16]
        if_zero as_check_expression
        jmp     as_symbol_undefined
      as_symbol_predicted_undefined:
        or      as_u8 [eax+8],40h
        and     as_u8 [eax+8],not 80h
      as_symbol_undefined:
        xor     bl,bl
        jmp     as_check_expression
      as_expression_checked:
        mov     al,bl
        jmp     as_logical_value_ok
      as_check_for_used:
        lods    as_u16 [esi]
        cmp     ah,2
        if_not_equal    as_invalid_expression
        lods    as_u32 [esi]
        cmp     eax,0Fh
        if_below        as_invalid_use_of_symbol
        if_equal        as_reserved_word_used_as_symbol
        inc     esi
        test    as_u8 [eax+8],8
        if_zero as_not_used
        mov     cx,[as_current_pass]
        sub     cx,[eax+18]
        if_zero as_return_true
        cmp     cx,1
        if_above        as_not_used
        or      as_u8 [eax+8],10h+20h
        jmp     as_return_true
      as_not_used:
        or      as_u8 [eax+8],10h
        and     as_u8 [eax+8],not 20h
        jmp     as_return_false
      as_given_false:
        inc     esi
      as_return_false:
        xor     al,al
        jmp     as_logical_value_ok
      as_given_true:
        inc     esi
      as_return_true:
        or      al,-1
        jmp     as_logical_value_ok
      as_logical_expression:
        lods    as_u8 [esi]
        mov     dl,[as_logical_value_wrapping]
        push    edx
        call    as_calculate_embedded_logical_expression
        pop     edx
        mov     [as_logical_value_wrapping],dl
        push    eax
        lods    as_u8 [esi]
        cmp     al,92h
        if_not_equal    as_invalid_expression
        pop     eax
      as_logical_value_ok:
        pop     ebx
        xor     al,bl
        ret

as_skip_symbol:
        lods    as_u8 [esi]
        or      al,al
        if_zero as_nothing_to_skip
        cmp     al,0Fh
        if_equal        as_nothing_to_skip
        cmp     al,1
        if_equal        as_skip_instruction
        cmp     al,2
        if_equal        as_skip_label
        cmp     al,3
        if_equal        as_skip_label
        cmp     al,4
        if_equal        as_skip_special_label
        cmp     al,20h
        if_below        as_skip_assembler_symbol
        cmp     al,'('
        if_equal        as_skip_expression
        cmp     al,'['
        if_equal        as_skip_address
      as_skip_done:
        clear_carry
        ret
      as_skip_label:
        add     esi,2
      as_skip_instruction:
        add     esi,2
      as_skip_assembler_symbol:
        inc     esi
        jmp     as_skip_done
      as_skip_special_label:
        add     esi,4
        jmp     as_skip_done
      as_skip_address:
        mov     al,[esi]
        and     al,11110000b
        cmp     al,60h
        if_below        as_skip_expression
        cmp     al,70h
        if_above        as_skip_expression
        inc     esi
        jmp     as_skip_address
      as_skip_expression:
        lods    as_u8 [esi]
        or      al,al
        if_zero as_skip_string
        cmp     al,'.'
        if_equal        as_skip_fp_value
        cmp     al,')'
        if_equal        as_skip_done
        cmp     al,']'
        if_equal        as_skip_done
        cmp     al,'!'
        if_equal        as_skip_expression
        cmp     al,0Fh
        if_equal        as_skip_expression
        cmp     al,10h
        if_equal        as_skip_register
        cmp     al,11h
        if_equal        as_skip_label_value
        cmp     al,80h
        if_above_equal  as_skip_expression
        movzx   eax,al
        add     esi,eax
        jmp     as_skip_expression
      as_skip_label_value:
        add     esi,3
      as_skip_register:
        inc     esi
        jmp     as_skip_expression
      as_skip_fp_value:
        add     esi,12
        jmp     as_skip_done
      as_skip_string:
        lods    as_u32 [esi]
        add     esi,eax
        inc     esi
        jmp     as_skip_done
      as_nothing_to_skip:
        dec     esi
        set_carry
        ret

as_expand_path:
        lods    as_u8 [esi]
        cmp     al,'%'
        if_equal        as_environment_variable
        stos    as_u8 [edi]
        or      al,al
        if_not_zero     as_expand_path
        cmp     edi,[as_memory_end]
        if_above        as_out_of_memory
        ret
      as_environment_variable:
        mov     ebx,esi
      as_find_variable_end:
        lods    as_u8 [esi]
        or      al,al
        if_zero as_not_environment_variable
        cmp     al,'%'
        if_not_equal    as_find_variable_end
        mov     as_u8 [esi-1],0
        push    esi
        mov     esi,ebx
        call    as_get_environment_variable
        pop     esi
        mov     as_u8 [esi-1],'%'
        jmp     as_expand_path
      as_not_environment_variable:
        mov     al,'%'
        stos    as_u8 [edi]
        mov     esi,ebx
        jmp     as_expand_path
as_get_include_directory:
        lods    as_u8 [esi]
        cmp     al,';'
        if_equal        as_include_directory_ok
        stos    as_u8 [edi]
        or      al,al
        if_not_zero     as_get_include_directory
        dec     esi
        dec     edi
      as_include_directory_ok:
        cmp     as_u8 [edi-1],'/'
        if_equal        as_path_separator_ok
        cmp     as_u8 [edi-1],'\'
        if_equal        as_path_separator_ok
        mov     al,'/'
        stos    as_u8 [edi]
      as_path_separator_ok:
        ret
