; SPDX-License-Identifier: BSD-2-Clause
; Copyright (c) 2026 danko1122q
; All rights reserved.

; asm platform32 .as
; Compatibility shims for pure 32-bit ELF build — macro-free version.
; All macro definitions removed; use32 is a native assembler directive.
; promote_* calls removed (no-ops in 32-bit mode).
; update_field / mark_dirty / sign_update inlined at call sites.

use32
