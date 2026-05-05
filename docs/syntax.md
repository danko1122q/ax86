# AX86 Language Reference

---

## Contents

1. [Format Directives](#1-format-directives)
2. [Segments and Sections](#2-segments-and-sections)
3. [Entry Point](#3-entry-point)
4. [Data Directives](#4-data-directives)
5. [Reserve Directives](#5-reserve-directives)
6. [Memory Size Overrides](#6-memory-size-overrides)
7. [Code Width: use16 and use32](#7-code-width-use16-and-use32)
8. [Numeric Literals](#8-numeric-literals)
9. [Operators](#9-operators)
10. [Position Counters and Layout](#10-position-counters-and-layout)
11. [Labels and Constants](#11-labels-and-constants)
12. [Conditional Branches](#12-conditional-branches)
13. [Unconditional Control Flow](#13-unconditional-control-flow)
14. [Flag Manipulation](#14-flag-manipulation)
15. [Extended Arithmetic](#15-extended-arithmetic)
16. [Bit Instructions](#16-bit-instructions)
17. [Sign Extension](#17-sign-extension)
18. [String and Block Instructions](#18-string-and-block-instructions)
19. [Addressing Modes](#19-addressing-modes)
20. [Preprocessor](#20-preprocessor)
21. [CLI Reference](#21-cli-reference)
22. [Instruction Names](#22-instruction-names)

---

## 1. Format Directives

Every source file must open with a `format` directive. It selects the output container and sets the default code width.

| Directive | Output | Default width |
|-----------|--------|---------------|
| `format elf executable 3` | Linux ELF32 executable | 32-bit |
| `format elf` | ELF32 relocatable object (`.o`) | 32-bit |
| `format binary` | Headerless flat binary (`.bin`) | **16-bit** |
| `format com` | DOS COM binary — origin at 100h (`.com`) | **16-bit** |

`format binary` defaults to 16-bit. Insert `use32` immediately after the directive when targeting 32-bit code.

`elf64` is not supported.

---

## 2. Segments and Sections

### ELF32 Executable

Use `segment` with permission flags. All segments are implicitly readable.

```asm
segment readable executable    ; .text  (r-x)
segment readable writeable     ; .data  (rw-)
segment readable               ; .rodata (r--)
```

### ELF32 Object

Use `section 'name'` with optional flags.

```asm
section '.text' executable
section '.data' writeable
section '.rodata'
section '.bss' writeable
```

### Permission flags

| Flag | Object | Executable |
|------|--------|------------|
| `readable` | ❌ | ✅ (`segment` only) |
| `writeable` | ✅ | ✅ |
| `executable` | ✅ | ✅ |

### Flat binary and COM

Neither format uses segments. Output begins at the first emitted byte (`format binary`) or at 100h (`format com`).

---

## 3. Entry Point

```asm
format elf executable 3
entry _start

segment readable executable
_start:
    ; first instruction here
```

Without `entry`, execution begins at the first byte of the first segment.

---

## 4. Data Directives

AX86 does not have `db` / `dw` / `dd` / `dq`. Use the sized forms:

| Directive | Bytes |
|-----------|-------|
| `u8` | 1 |
| `u16` | 2 |
| `u32` | 4 |
| `u64` | 8 |
| `u80` | 10 — x87 extended; accepts `?`, integers, floats |
| `u128` | 16 |
| `u256` | 32 |
| `u512` | 64 |

`?` emits a zero-filled slot (resolved at link time for objects, zeroed for executables).

Multiple values and strings are comma-separated on one line:

```asm
greeting  u8  'Hello', 13, 10, 0
coord     u32 320, 240
slot      u64 ?
```

---

## 5. Reserve Directives

Reserve uninitialised space. Must be in a writeable segment or section.

| Directive | Reserves |
|-----------|----------|
| `rb n` | n bytes |
| `rw n` | n × 2 bytes |
| `rd n` | n × 4 bytes |
| `rq n` | n × 8 bytes |

```asm
segment readable writeable
scratch  rb 128
matrix   rd 16
```

---

## 6. Memory Size Overrides

When the assembler cannot infer operand width from context, supply an explicit override.

| Override | Width |
|----------|-------|
| `as_u8` | 1 byte |
| `as_u16` | 2 bytes |
| `as_u32` | 4 bytes |
| `as_u64` | 8 bytes |
| `as_u128` | 16 bytes |
| `as_u256` | 32 bytes |
| `as_u512` | 64 bytes |

```asm
mov  as_u8  [buf], 0xFF
mov  as_u32 [counter], 0
movzx eax, as_u8 [flags]
```

`mov eax, [flags]` where `flags` is a `u8` label is a size mismatch error. Use `movzx eax, as_u8 [flags]` or `mov al, [flags]`.

---

## 7. Code Width: use16 and use32

These directives switch the encoder between 16-bit and 32-bit output from the point they appear.

| Directive | Encodes |
|-----------|---------|
| `use16` | 16-bit instructions; 32-bit operands get a `0x66` prefix |
| `use32` | 32-bit instructions; 16-bit operands get a `0x66` prefix |

Default widths by format:

| Format | Default |
|--------|---------|
| `format binary` | 16-bit |
| `format com` | 16-bit |
| `format elf` | 32-bit |
| `format elf executable 3` | 32-bit |

### 32-bit flat binary

```asm
format binary
use32

    mov eax, 1
    xor ebx, ebx
    trap 0x80
```

### Mixed real-mode and protected-mode

```asm
format binary

use16
    ; real-mode stub
    mov ax, 0x1234
    int 21h

use32
    ; protected-mode payload
    mov eax, 1
    xor ebx, ebx
    trap 0x80
```

---

## 8. Numeric Literals

| Notation | Example | Decimal value |
|----------|---------|---------------|
| Decimal | `255` | 255 |
| Hex, `0x` prefix | `0xFF` | 255 |
| Hex, `h` suffix | `0FFh` | 255 |
| Binary, `b` suffix | `11111111b` | 255 |
| Octal, `o` suffix | `0377o` | 255 |
| Character | `'A'` | 65 |

The `0b` binary prefix is not recognised. Always use the `b` suffix.

The two hex notations are mutually exclusive within a single token. `0xFF80h` is an error — write `0xFF80` or `0FF80h`.

---

## 9. Operators

### Arithmetic and bitwise (expressions)

| Operator | Operation |
|----------|-----------|
| `+` `-` `*` `/` | Arithmetic |
| `mod` | Remainder |
| `shl` `shr` | Logical shift |
| `and` `or` `xor` `not` | Bitwise |

```asm
PAGE    = 1 shl 12
MASK    = 0xFF and (not 0x0F)
REMAIN  = 100 mod 7
```

### Relational operators

`=` `<>` `<` `>` `<=` `>=` are valid **only** inside preprocessor conditions (`if`, `else if`, `assert`, `while`, `match`). Using them in expressions or data definitions is an error.

```asm
if STACK_SIZE >= 4096
    ; large stack path
end if

; ERROR — relational operator in expression context:
X = 1 < 2
```

---

## 10. Position Counters and Layout

| Symbol / directive | Meaning |
|--------------------|---------|
| `$` | Address of the next byte to be emitted |
| `$$` | Base address of the current segment or section |
| `align n` | Pad with `0x90` bytes to the next n-byte boundary |
| `times n stmt` | Emit `stmt` n times inline |
| `repeat n` / `end repeat` | Emit a block n times; `%` holds the iteration counter (1-based) |
| `org addr` | Override the assumed load address |
| `__file__` | Preprocessor string: path of the current source file |
| `__line__` | Preprocessor number: current source line |

```asm
header_start:
    u32 0x464C457F
    u32 0
header_end:
HEADER_SIZE = header_end - header_start   ; 8

align 4

repeat 4
    u16 %    ; emits 1, 2, 3, 4 as words
end repeat
```

---

## 11. Labels and Constants

| Form | Scope / behaviour |
|------|-------------------|
| `name:` | Global label — visible across the whole file |
| `.name:` | Local label — scoped to the nearest preceding global label |
| `@@:` | Anonymous label |
| `@b` | Reference to the nearest previous `@@` |
| `@f` | Reference to the nearest following `@@` |
| `NAME = value` | Numeric constant — fixed after assignment |
| `NAME equ tokens` | Token alias — substituted textually |
| `public name` | Export a symbol from an ELF object or section |
| `extrn name` | Declare an external symbol for linking |

```asm
MAX_ITEMS = 64

process:
  .loop:
    dec ecx
    if_not_zero .loop   ; jumps to process's .loop

@@:
    dec edx
    if_not_zero @b      ; jumps back to nearest @@
```

---

## 12. Conditional Branches

| Mnemonic | Condition | Flags tested |
|----------|-----------|--------------|
| `if_equal label` | Equal / zero | ZF=1 |
| `if_not_equal label` | Not equal | ZF=0 |
| `if_zero label` | Zero | ZF=1 |
| `if_not_zero label` | Non-zero | ZF=0 |
| `if_above label` | Unsigned > | CF=0 ∧ ZF=0 |
| `if_below label` | Unsigned < | CF=1 |
| `if_above_equal label` | Unsigned ≥ | CF=0 |
| `if_below_equal label` | Unsigned ≤ | CF=1 ∨ ZF=1 |
| `if_greater label` | Signed > | ZF=0 ∧ SF=OF |
| `if_less label` | Signed < | SF≠OF |
| `if_greater_equal label` | Signed ≥ | SF=OF |
| `if_less_equal label` | Signed ≤ | ZF=1 ∨ SF≠OF |
| `if_carry label` | CF set | CF=1 |
| `if_not_carry label` | CF clear | CF=0 |
| `if_overflow label` | OF set | OF=1 |
| `if_not_overflow label` | OF clear | OF=0 |
| `if_sign label` | Result negative | SF=1 |
| `if_not_sign label` | Result non-negative | SF=0 |
| `if_parity label` | Even parity | PF=1 |
| `if_not_parity label` | Odd parity | PF=0 |

```asm
cmp eax, ebx
if_equal   .same
if_greater .a_wins
; falls through: b_wins
```

---

## 13. Unconditional Control Flow

| Mnemonic | Description |
|----------|-------------|
| `jmp label` | Near jump (±2 GB) |
| `jmp short label` | Short jump (−128 to +127 bytes) |
| `jmp reg` | Register-indirect jump |
| `jmp as_u32 [mem]` | Memory-indirect jump |
| `call label` | Near call |
| `call reg` | Register-indirect call |
| `call near as_u32 [mem]` | Memory-indirect call |
| `ret` | Return |
| `ret n` | Return and pop n bytes |
| `loop label` | ECX--; jump if ECX ≠ 0 |
| `loope label` | ECX--; jump if ECX ≠ 0 and ZF=1 |
| `loopne label` | ECX--; jump if ECX ≠ 0 and ZF=0 |

Memory-indirect forms require an explicit size override:

```asm
jmp  as_u32 [jump_table + eax*4]
call near as_u32 [vtable + ecx*4]
```

---

## 14. Flag Manipulation

| Mnemonic | Effect |
|----------|--------|
| `set_carry` | CF ← 1 |
| `clear_carry` | CF ← 0 |
| `complement_carry` | CF ← ¬CF |
| `set_direction` | DF ← 1 (string ops go downward) |
| `clear_direction` | DF ← 0 (string ops go upward, default) |
| `set_interrupt` | IF ← 1 (enable hardware interrupts) |
| `clear_interrupt` | IF ← 0 (disable hardware interrupts) |
| `push_flags` | Push EFLAGS |
| `pop_flags` | Pop EFLAGS |
| `load_flags_to_ah` | AH ← SF:ZF:0:AF:0:PF:1:CF |
| `store_ah_to_flags` | SF/ZF/AF/PF/CF ← AH bits |

---

## 15. Extended Arithmetic

| Mnemonic | Operation |
|----------|-----------|
| `add_with_carry dst, src` | dst = dst + src + CF |
| `sub_with_borrow dst, src` | dst = dst − src − CF |
| `negate dst` | dst = −dst (two's complement) |
| `signed_multiply dst, src` | dst = dst × src (signed, two-operand) |
| `signed_divide src` | eax = EDX:EAX ÷ src; edx = remainder |

```asm
; 6 × 7
mov eax, 6
mov ecx, 7
signed_multiply eax, ecx     ; eax = 42

; −14 / 3
mov eax, -14
sign_extend_dword
mov ecx, 3
signed_divide ecx            ; eax = -4, edx = -2

; 64-bit addition using two 32-bit registers
add  eax, [lo2]
add_with_carry edx, [hi2]
```

---

## 16. Bit Instructions

| Mnemonic | Description |
|----------|-------------|
| `bit_test dst, n` | CF ← bit n of dst |
| `bit_test_set dst, n` | CF ← bit n, then set it |
| `bit_test_reset dst, n` | CF ← bit n, then clear it |
| `bit_scan_forward dst, src` | dst = index of lowest set bit in src |
| `bit_scan_reverse dst, src` | dst = index of highest set bit in src |

```asm
mov eax, 00011000b
bit_test eax, 3
if_carry .bit3_was_set

bit_scan_forward ecx, eax    ; ecx = 3
bit_scan_reverse ecx, eax    ; ecx = 4
```

---

## 17. Sign Extension

Prepares EAX / EDX for `signed_divide`.

| Mnemonic | Widens |
|----------|--------|
| `sign_extend_byte` | AL → AX |
| `sign_extend_word` | AX → EAX |
| `sign_extend_dword` | EAX → EDX:EAX |

```asm
mov eax, -100
sign_extend_dword
mov ecx, 7
signed_divide ecx    ; eax = -14, edx = -2
```

---

## 18. String and Block Instructions

Prefix with `rep`, `repe`/`repz`, or `repne`/`repnz`. Direction is set by `clear_direction` (ascending, default) and `set_direction` (descending).

| Mnemonic | Operation |
|----------|-----------|
| `rep` | Repeat while ECX ≠ 0 |
| `repe` / `repz` | Repeat while ECX ≠ 0 ∧ ZF=1 |
| `repne` / `repnz` | Repeat while ECX ≠ 0 ∧ ZF=0 |
| `movsb` / `movsw` / `movsd` | [ESI] → [EDI]; advance ESI, EDI |
| `cmpsb` / `cmpsw` / `cmpsd` | Compare [ESI] vs [EDI]; advance both |
| `scasb` / `scasw` / `scasd` | Compare AL/AX/EAX vs [EDI]; advance EDI |
| `lodsb` / `lodsw` / `lodsd` | AL/AX/EAX ← [ESI]; advance ESI |
| `stosb` / `stosw` / `stosd` | [EDI] ← AL/AX/EAX; advance EDI |
| `translate_byte [base]` | AL ← [base + AL] |

```asm
; memcpy(dst, src, 32)
mov esi, src
mov edi, dst
mov ecx, 32
rep movsb

; memset(buf, 0, 64 dwords)
mov edi, buf
xor eax, eax
mov ecx, 64
rep stosd

; strchr(str, '\n') — max 512 bytes
mov edi, str
mov al, 10
mov ecx, 512
repne scasb          ; EDI points one past the match on success
```

---

## 19. Addressing Modes

| Mode | Example |
|------|---------|
| Register | `mov eax, ecx` |
| Immediate | `mov eax, 0xFF` |
| Direct | `mov eax, [table]` |
| Register indirect | `mov eax, [ebx]` |
| Base + displacement | `mov eax, [esp+4]` |
| Base + index | `mov eax, [ebx+esi]` |
| Base + index × scale | `mov eax, [ebx+esi*4]` |
| Full SIB + displacement | `mov eax, [ebx+esi*8+16]` |
| Override + indirect | `mov as_u32 [edi], 0` |

Valid scale factors: `1`, `2`, `4`, `8`.

---

## 20. Preprocessor

### include

```asm
include 'core/linux32.s'
include 'arch/x86.s'
```

Additional search directories are added with the `-i` flag.

### Conditional assembly

```asm
if VERSION >= 2
    include 'v2/features.s'
else
    include 'v1/compat.s'
end if
```

`if defined NAME` tests whether `NAME` is a numeric constant (defined with `=` or `-d`). It does **not** see `define` preprocessor variables.

```asm
RELEASE = 1
if defined RELEASE
    ; strip debug info
end if

; ax86 -d TRACE=1 prog.s prog
if defined TRACE
    ; emit tracing code
end if
```

### assert

Aborts assembly with an error when the condition is false.

```asm
assert HEADER_SIZE = 16
assert $ - section_start < 512
```

### restore

Undefines an `equ` or `define` symbol. Does not affect `=` constants.

```asm
TEMP equ scratch_reg
; ... use TEMP ...
restore TEMP
```

---

## 21. CLI Reference

```
ax86 <source> [output]
```

| Flag | Description |
|------|-------------|
| `-m <kb>` | Assembler heap size in kilobytes (default: 16384) |
| `-p <n>` | Maximum pass count |
| `-d NAME=value` | Predefine numeric symbol |
| `-s <file>` | Write symbol dump |
| `-i <path>` | Append to include search path |

Symbols from `-d` are numeric constants and are visible to `if defined`:

```asm
; ax86 -d RELEASE=1 prog.s prog
if defined RELEASE
    ; production build path
end if
```

---

## 22. Instruction Names

AX86 uses its own mnemonic vocabulary. No include file or declaration is needed — these names are built into the encoder.

### System instructions

| Mnemonic | x86 | Notes |
|----------|-----|-------|
| `trap n` | `int n` | `trap 0x80` — Linux syscall gate |
| `no_op` | `nop` | |
| `halt` | `hlt` | Ring 0 |
| `return_from_interrupt` | `iret` | Ring 0 |
| `system_call` | `syscall` | SYSENTER-style fast call |

```asm
; sys_exit(0)
xor ebx, ebx
mov eax, 1
trap 0x80
```

### Stack frame

| Mnemonic | x86 |
|----------|-----|
| `create_frame size, nesting` | `enter size, nesting` |
| `destroy_frame` | `leave` |

```asm
fn:
    create_frame 32, 0   ; 32 bytes of locals
    ; ...
    destroy_frame
    ret
```

### Atomic operations

| Mnemonic | x86 | Description |
|----------|-----|-------------|
| `byte_swap reg` | `bswap reg` | Reverse byte order |
| `exchange_add dst, src` | `xadd dst, src` | Swap, then add |
| `compare_exchange dst, src` | `cmpxchg dst, src` | CAS: EAX is the comparand |
| `compare_exchange_8b mem` | `cmpxchg8b mem` | 64-bit CAS: EDX:EAX compared, ECX:EBX written |

### I/O ports

| Mnemonic | x86 | Privilege |
|----------|-----|-----------|
| `read_port dx` | `in eax, dx` | Ring 0 / IOPL |
| `write_port dx` | `out dx, eax` | Ring 0 / IOPL |

### Memory ordering

| Mnemonic | x86 |
|----------|-----|
| `load_fence` | `lfence` |
| `store_fence` | `sfence` |
| `memory_fence` | `mfence` |

### CPU query

| Mnemonic | x86 | Notes |
|----------|-----|-------|
| `cpu_info` | `cpuid` | Leaf in EAX on entry |
| `read_timestamp` | `rdtsc` | Result in EDX:EAX |

### Conditional moves

All 28 `cmov` variants are named `move_if_<condition>`. The move happens only when the condition is true; flags are unaffected.

**Unsigned / flag-direct conditions**

| Mnemonic | Condition |
|----------|-----------|
| `move_if_equal dst, src` | ZF=1 |
| `move_if_not_equal dst, src` | ZF=0 |
| `move_if_zero dst, src` | ZF=1 |
| `move_if_not_zero dst, src` | ZF=0 |
| `move_if_above dst, src` | CF=0 ∧ ZF=0 |
| `move_if_below dst, src` | CF=1 |
| `move_if_above_equal dst, src` | CF=0 |
| `move_if_below_equal dst, src` | CF=1 ∨ ZF=1 |
| `move_if_carry dst, src` | CF=1 |
| `move_if_not_carry dst, src` | CF=0 |
| `move_if_not_above dst, src` | CF=1 ∨ ZF=1 |
| `move_if_not_below dst, src` | CF=0 |
| `move_if_not_above_equal dst, src` | CF=1 |
| `move_if_not_below_equal dst, src` | CF=0 ∧ ZF=0 |

**Signed conditions**

| Mnemonic | Condition |
|----------|-----------|
| `move_if_greater dst, src` | ZF=0 ∧ SF=OF |
| `move_if_less dst, src` | SF≠OF |
| `move_if_greater_equal dst, src` | SF=OF |
| `move_if_less_equal dst, src` | ZF=1 ∨ SF≠OF |
| `move_if_not_greater dst, src` | ZF=1 ∨ SF≠OF |
| `move_if_not_less dst, src` | SF=OF |
| `move_if_not_greater_equal dst, src` | SF≠OF |
| `move_if_not_less_equal dst, src` | ZF=0 ∧ SF=OF |

**Overflow, sign, parity**

| Mnemonic | Condition |
|----------|-----------|
| `move_if_overflow dst, src` | OF=1 |
| `move_if_not_overflow dst, src` | OF=0 |
| `move_if_sign dst, src` | SF=1 |
| `move_if_not_sign dst, src` | SF=0 |
| `move_if_parity dst, src` | PF=1 |
| `move_if_not_parity dst, src` | PF=0 |

```asm
; branchless abs(eax)
mov  ebx, eax
negate eax
move_if_sign eax, ebx        ; restore if negate overflowed (original was non-negative)

; branchless max(eax, ebx) → eax
cmp  eax, ebx
move_if_less eax, ebx
```
