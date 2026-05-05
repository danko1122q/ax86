; SPDX-License-Identifier: BSD-2-Clause
; Copyright (c) 2026 danko1122q
; All rights reserved.

as_memory_start u32 ?
as_memory_end u32 ?

as_additional_memory u32 ?
as_additional_memory_end u32 ?

as_stack_limit u32 ?

as_initial_definitions u32 ?
as_input_file u32 ?
as_output_file u32 ?
as_symbols_file u32 ?

as_passes_limit u16 ?

; Internal core variables:

as_current_pass u16 ?

as_include_paths u32 ?
as_free_additional_memory u32 ?
as_source_start u32 ?
as_code_start u32 ?
as_code_size u32 ?
as_real_code_size u32 ?
as_written_size u32 ?
as_headers_size u32 ?

as_current_line u32 ?
as_macro_line u32 ?
as_macro_block u32 ?
as_macro_block_line u32 ?
as_macro_block_line_number u32 ?
as_macro_symbols u32 ?
as_struc_name u32 ?
as_struc_label u32 ?
as_instant_macro_start u32 ?
as_parameters_end u32 ?
as_default_argument_value u32 ?
as_locals_counter rb 8
as_current_locals_prefix u32 ?
as_anonymous_reverse u32 ?
as_anonymous_forward u32 ?
as_labels_list u32 ?
as_label_hash u32 ?
as_label_leaf u32 ?
as_hash_tree u32 ?
as_addressing_space u32 ?
as_undefined_data_start u32 ?
as_undefined_data_end u32 ?
as_counter u32 ?
as_counter_limit u32 ?
as_error_info u32 ?
as_error_line u32 ?
as_error u32 ?
as_tagged_blocks u32 ?
as_structures_buffer u32 ?
as_number_start u32 ?
as_current_offset u32 ?
as_value u64 ?
as_fp_value rd 8
as_adjustment u64 ?
as_symbol_identifier u32 ?
as_address_symbol u32 ?
as_address_high u32 ?
as_uncompressed_displacement u32 ?
as_format_flags u32 ?
as_resolver_flags u32 ?
as_symbols_stream u32 ?
as_number_of_relocations u32 ?
as_number_of_sections u32 ?
as_stub_size u32 ?
as_stub_file u32 ?
as_current_section u32 ?
as_machine u16 ?
as_subsystem u16 ?
as_subsystem_version u32 ?
as_image_base u32 ?
as_image_base_high u32 ?
as_merge_segment u32 ?
as_resource_data u32 ?
as_resource_size u32 ?
as_actual_fixups_size u32 ?
as_reserved_fixups u32 ?
as_reserved_fixups_size u32 ?
as_last_fixup_base u32 ?
as_last_fixup_header u32 ?
as_parenthesis_stack u32 ?
as_blocks_stack u32 ?
as_parsed_lines u32 ?
as_logical_value_parentheses u32 ?
as_file_extension u32 ?

as_operand_size u8 ?
as_operand_flags u8 ?
as_operand_prefix u8 ?
as_rex_prefix u8 ?
as_opcode_prefix u8 ?
as_vex_required u8 ?
as_vex_register u8 ?
as_immediate_size u8 ?
as_mask_register u8 ?
as_broadcast_size u8 ?
as_rounding_mode u8 ?

as_base_code u8 ?
as_extended_code u8 ?
as_supplemental_code u8 ?
as_postbyte_register u8 ?
as_segment_register u8 ?
as_xop_opcode_map u8 ?

as_mmx_size u8 ?
as_jump_type u8 ?
as_push_size u8 ?
as_value_size u8 ?
as_address_size u8 ?
as_label_size u8 ?
as_size_declared u8 ?
as_address_size_declared u8 ?
as_displacement_compression u8 ?

as_value_undefined u8 ?
as_value_constant u8 ?
as_value_type u8 ?
as_value_sign u8 ?
as_fp_sign u8 ?
as_fp_format u8 ?
as_address_sign u8 ?
as_address_register u8 ?
as_compare_type u8 ?
as_logical_value_wrapping u8 ?
as_next_pass_needed u8 ?
as_output_format u8 ?
as_code_type u8 ?
as_adjustment_sign u8 ?
as_evex_mode u8 ?

as_macro_status u8 ?
as_skip_default_argument_value u8 ?
as_prefix_flags u8 ?
as_formatter_symbols_allowed u8 ?
as_decorator_symbols_allowed u8 ?
as_free_address_range u8 ?

as_characters rb 100h
as_converted rb 100h
as_message rb 180h
