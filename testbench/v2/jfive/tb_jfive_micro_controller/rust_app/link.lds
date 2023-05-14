OUTPUT_ARCH(riscv)
ENTRY(_rst_handler)

MEMORY
{
	ram  : o = 0x80000000, l = 0x0010000
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

    .app_stack ALIGN(0x08):
    {
        *(.usr_stack .usr_stack.*);
        ___usr_stack_end = . ; 
    } > ram
    
    .stacks ALIGN(0x08):
    {
        ___stack = . ; 
        . += 8192;
        ___stack_end = . ;
    } > ram
}
