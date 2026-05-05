# AX86 — Assembly x86

AX86 is a self-hosted 32-bit x86 assembler targeting Linux. It produces ELF32 executables, ELF32 relocatable objects, DOS COM binaries, and raw flat binaries. Running the output on a 64-bit host requires QEMU.

See [`docs/syntax.md`](docs/syntax.md) for the language reference.

The assembler binary is named **`ax86`**.

---

## Building

```sh
./ax86 ax86.s ax86
chmod +x ax86
```

---

## Usage

```
ax86 <source> [output]
```

| Flag | Effect |
|------|--------|
| `-m <kb>` | Working memory in kilobytes (default: 16384) |
| `-p <n>` | Maximum assembly passes |
| `-d NAME=value` | Predefine a numeric symbol |
| `-s <file>` | Dump symbol table to file |
| `-i <path>` | Add an include search directory |

```sh
ax86 hello.s hello
ax86 -d DEBUG=1 prog.s prog
ax86 -m 65536 large.s large
ax86 -s prog.sym prog.s prog
```

---

## Output Formats

The `format` directive at the top of every source file selects the output type.

| Directive | Produces | Extension |
|-----------|----------|-----------|
| `format elf executable 3` | Linux ELF32 executable | *(none)* |
| `format elf` | ELF32 relocatable object | `.o` |
| `format binary` | Headerless flat binary | `.bin` |
| `format com` | DOS COM binary (origin 100h) | `.com` |

64-bit output is not supported.

---

## Hello World

```asm
format elf executable 3
entry _start

segment readable executable
_start:
    mov  eax, 4
    mov  ebx, 1
    mov  ecx, msg
    mov  edx, msg_len
    trap 0x80
    mov  eax, 1
    xor  ebx, ebx
    trap 0x80

segment readable
msg     u8 'Hello, world!', 10
msg_len = $ - msg
```

```sh
ax86 hello.s hello && ./hello
```

---

## DOS COM

```asm
format com

    mov  ah, 9
    mov  dx, msg
    trap 0x21
    mov  ax, 4C00h
    trap 0x21

msg u8 'Hello!', 13, 10, '$'
```

---

## Minimal ELF32 — 87 bytes

52-byte ELF header + 32-byte program header + 3 bytes of code. The Linux i386 ABI guarantees `eax = 0` at process entry.

```asm
format elf executable 3

    inc  eax        ; eax = 1 (sys_exit)
    trap 0x80
```

```sh
ax86 87.s 87 && qemu-i386 ./87 && echo $?
```

### Running ELF32 on a 64-bit host

64-bit Linux kernels typically lack the `ia32` personality. Install QEMU user-mode emulation:

```sh
sudo apt install qemu-user           # Debian / Ubuntu
sudo dnf install qemu-user           # Fedora / RHEL
sudo pacman -S qemu-user             # Arch
```

Then prefix any ELF32 binary with `qemu-i386`. To run them transparently without the prefix, also install `qemu-user-binfmt` and restart `systemd-binfmt`.

---

## Linking Objects

```asm
format elf

section '.text' executable

public add_ints
add_ints:
    mov  eax, [esp+4]
    add  eax, [esp+8]
    ret
```

```sh
ax86 lib.s lib.o
ld -m elf_i386 -o prog main.o lib.o
```

---

## Syntax at a Glance

### Data definitions

```asm
name   u8  'text', 13, 10, 0   ; bytes
value  u32 0xDEADBEEF           ; dword
table  u16 1, 2, 3, 4           ; word array
buf    rb 256                   ; reserve 256 bytes (uninitialised)
nums   rd 16                    ; reserve 16 dwords
```

### Size overrides

```asm
mov  as_u8  [ptr], 7
mov  as_u32 [ptr], 0
movzx eax, as_u8 [ptr]
```

### Conditional jumps

```asm
cmp  eax, 0
if_less     .negative
if_equal    .zero
if_greater  .positive
```

---

## Project Layout

```
ax86.s              entry point, argument parsing, top-level control flow
core/
  platform32.s    platform shims
  linux32.s       Linux i386 syscall I/O
  scan.s          lexer
  expand.s        preprocessor (include / define / equ / fix)
  tokens.s        token stream helpers
  emit.s          instruction encoder
  calc.s          constant-expression evaluator
  output_fmt.s    format writers: ELF32, COFF, flat binary, COM
  state.s         global assembler state
  structs.s       keyword and mnemonic tables
  msgdata.s       error message text
  fault.s         error reporting
  dump.s          symbol table dump
  version.s       version string
arch/
  x86.s           x86-32 instruction set
  vec.s           SSE/AVX vector instructions
docs/
  syntax.md       language reference
```

---

## Instruction Names

AX86 defines its own mnemonic set. These are not aliases layered on top of another assembler — they are the primary names the encoder recognises.

### Selected mappings

| AX86 | x86 | Notes |
|------|-----|-------|
| `trap n` | `int n` | `trap 0x80` invokes a Linux syscall |
| `no_op` | `nop` | |
| `halt` | `hlt` | Privileged |
| `return_from_interrupt` | `iret` | Privileged |
| `system_call` | `syscall` | |
| `create_frame size, nest` | `enter size, nest` | |
| `destroy_frame` | `leave` | |
| `byte_swap reg` | `bswap reg` | |
| `exchange_add dst, src` | `xadd dst, src` | |
| `compare_exchange dst, src` | `cmpxchg dst, src` | |
| `compare_exchange_8b mem` | `cmpxchg8b mem` | |
| `read_port dx` | `in eax, dx` | Privileged |
| `write_port dx` | `out dx, eax` | Privileged |
| `load_fence` | `lfence` | |
| `store_fence` | `sfence` | |
| `memory_fence` | `mfence` | |
| `cpu_info` | `cpuid` | |
| `read_timestamp` | `rdtsc` | |

All 28 conditional-move variants follow `move_if_<condition>` — e.g. `move_if_equal`, `move_if_less`, `move_if_not_carry`. See [docs/syntax.md §22](docs/syntax.md#22-instruction-names) for the complete table.

---

## Design

AX86's assembler design is inspired by FASM (Flat Assembler).

---

## License

BSD 2-Clause. Copyright (c) 2026 danko1122q. See [`LICENSE`](LICENSE).
