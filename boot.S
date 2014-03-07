/* boot.S - bootstrap the kernel
 * vim:et:ts=4:sts=4:sw=4
 */

#define ASM_FILE        1
#include "multiboot.h"
#include "constants.h"

/* The flags for the Multiboot header. */
#ifdef __ELF__
# define MULTIBOOT_HEADER_FLAGS         0x00000003
#else
# define MULTIBOOT_HEADER_FLAGS         0x00010003
#endif

.text
.code32

.globl  start, _start
start:
_start:
jmp     multiboot_entry

/* Align 32 bits boundary. */
.align  4

/* Multiboot header. */
multiboot_header:
/* magic */
.long   MULTIBOOT_HEADER_MAGIC
/* flags */
.long   MULTIBOOT_HEADER_FLAGS
/* checksum */
.long   -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)
#ifndef __ELF__
    /* header_addr */
    .long   multiboot_header
    /* load_addr */
    .long   _start
    /* load_end_addr */
    .long   _edata
    /* bss_end_addr */
    .long   _end
    /* entry_addr */
    .long   multiboot_entry
#endif /* ! __ELF__ */

multiboot_entry:
    pushfl
    pop     %eax
    mov     %eax, %ecx
    btc     $21, %eax
    push    %eax
    popfl
    pushfl
    pop     %eax
    push    %ecx
    popfl
    xor     %eax, %ecx
    jz      fail

    mov     $0x80000000, %eax
    cpuid
    cmp     $0x80000001, %eax
    jb      fail

    mov     $0x80000001, %eax
    cpuid
    bt      $29, %edx
    jae     fail

golong:
    cli
    movl    %ebx, %esi
    movl    %eax, %edi

    # create a long mode page table
    movl    $pml4, %eax
    movl    %eax, %cr3

    # enable 64-bit page table with CR4.PAE
    movl    %cr4, %eax
    bts     $5, %eax
    movl    %eax, %cr4

    # enable long mode
    movl    $0xc0000080, %ecx
    rdmsr
    bts     $8, %eax
    wrmsr

    movl    %cr0, %eax
    bts     $31, %eax
    movl    %eax, %cr0

    lgdt    (pGDT)
    lidt    (pIDT)

    # enable paging and jump to long mode
    ljmp    $CS_KERNEL, $_load64

fail:
    mov     $0xb8000,%edi
    mov     $(80*25 / 2),%ecx
    xor     %eax,%eax
    rep stosl

    mov     $0xb8000,%edi
    mov     $nolong,%esi
    mov     $0x10,%ecx
    mov     $0x0c00,%eax
    rep movsl
hang:
    hlt
    jmp     hang

.code64
_load64:
    movq    $(bootstack_end - KERNEL_VMA_BASE), %rsp
    call    start64
    hlt


# GDT and IDT
.align 4096
GDT_START:
    .quad   0       # NULL descriptor

GDT_CSK:
    .short  0xffff  # code segment limit - ignored
    .short  0       # code base low - ignored
    .byte   0       # code base middle - ignored
    .byte   0x9A    # code access
    .byte   0xaf    # granularity (L=1)
    .byte   0       # code base high - ignored

GDT_DSK:
    .short  0xffff  # code segment limit - ignored
    .short  0       # code base low - ignored
    .byte   0       # code base middle - ignored
    .byte   0x92    # code access
    .byte   0xcf    # granularity (L=1)
    .byte   0       # code base high - ignored
GDT_END:

    .word 0 # padding

pGDT:
    .word   GDT_END - GDT_START - 1
    .quad   GDT_START

    .word 0 #padding

pIDT:
    .word 0
    .quad 0

.align 4096 # tables MUST be aligned
# PML4
pml4:
    .quad   (pml3a + 3)
    .fill   510, 8, 0
    .quad   (pml3b + 3)


# PML3
pml3a:
    .quad (pml2 + 3)
    .fill 511, 8, 0

pml3b:
    .fill 510, 8, 0
    .quad (pml2 + 3)
    .quad 0

# identity-map lower 2MB
pml2:
    .quad (pml1 + 3)
    .fill 511, 8, 0

pml1:
    i = 0
    .rept 512
    .quad (i + 3)
    i = i + 0x1000
    .endr

nolong:
    .asciz "N\7o\7 \7l\7o\7n\7g\7 \7m\7o\7d\7e\7 \7s\7u\7p\7p\7o\7r\7t\7e\7d\7.\7 \7H\14a\14l\14t\14e\14d\14.\14\0\0"
