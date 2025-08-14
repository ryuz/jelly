OUTPUT_ARCH(riscv)
ENTRY(_rst_handler)

MEMORY
{
    ram  : o = 0x80000000, l = 0x0008000
}

SECTIONS
{
    .reset :
    {
        ___reset = . ;
        KEEP(*crt0.o(.text)) 
        ___reset_end = . ; 
    } > ram

    .text :
    {
         ___text = . ; 
        *(.text .text.* .rodata*)
         ___text_end = . ; 
    } > ram
    
    data :
    {
        ___data = . ;
        *(.data .data.*)
        ___data_end = . ;
    } > ram
    
    .bss :
    {
        ___bss = . ;
        *(.bss .bss.*)
        ___bss_end = . ;  
    } > ram
    
    .sbss :
    {
        ___sbss = . ;
        *(.sbss .sbss.*)
        ___sbss_end = . ;  
    } > ram
    
    .eh_frame :
    {
        ___eh_frame = . ;
        *(.eh_frame .eh_frame.*)
        ___eh_frame_end = . ;  
    } > ram
    
    .stacks ALIGN(0x08):
    {
        ___stack = . ; 
        . += 1024;
        ___stack_end = . ;
    } > ram
}
