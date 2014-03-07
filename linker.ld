ENTRY (_start)

kernel_VMA = 0xffffffff80000000;
kernel_LMA = 0x00100000;

SECTIONS
{
    . = kernel_LMA;

    kernel_start = .;

    .text_boot :
    {
        boot.o (.text)
    }

    . = ALIGN(0x1000);
    . += kernel_VMA;

    .text : AT(ADDR(.text) - kernel_VMA)
    {
        *(.text)
        *(.gnu.linkonce.t*)
    }

    . = ALIGN(0x1000);

    .rodata : AT(ADDR(.rodata) - kernel_VMA)
    {
        start_ctors = .;
        *(.ctor*)
        end_ctors = .;

        start_dtors = .;
        *(.dtor*)
        end_dtors = .;

        *(.rodata*)
        *(.gnu.linkonce.r*)
    }

    . = ALIGN(0x1000);

    .data : AT(ADDR(.data) - kernel_VMA)
    {
        *(.data)
        *(.gnu.linkonce.d*)
        edata = .;
    }

    . = ALIGN(0x1000);

    .bss : AT(ADDR(.bss) - kernel_VMA)
    {
        sbss = .;
        *(COMMON)
        *(.bss)
        *(.gnu.linkonce.b*)
        ebss = .;
    }

    . = ALIGN(0x1000);
    .bootstack : AT(ADDR(.bootstack) - kernel_VMA)
    {
        bootstack_start  = .;
        . += 0x8000;
        bootstack_end = .;
    }

    . = ALIGN(0x1000);
    kernel_end = . - kernel_VMA;

    /DISCARD/ :
    {
        *(.comment)
        *(.eh_frame)
    }
}
