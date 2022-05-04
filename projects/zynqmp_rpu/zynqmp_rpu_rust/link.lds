OUTPUT_ARCH(arm)
ENTRY(_rst_handler)

MEMORY
{
	vector : o = 0x00000000, l = 0x00000040		/* A-TCM */
	ram0   : o = 0x00000040, l = 0x0000ffc0		/* A-TCM */
	ram1   : o = 0x00020000, l = 0x00010000		/* B-TCM */
}

SECTIONS
{
	.vector :
	{
      	___vector = . ;
		KEEP(*vectors.o(.text)) 
		FILL(0xff)
		___vector_end = . ; 
	} > vector

	.text :
	{
		 ___text = . ; 
		*(.text .text.* .rodata*)
		 ___text_end = . ; 
	} > ram0
    

	data :
	{
		___data = . ;
		*(.data .data.*)
		___data_end = . ;
	} > ram1

	.bss :
	{
		___bss = . ;
		*(.bss .bss.*)
		___bss_end = . ;  
	} > ram1

    .app_stack ALIGN(0x08):
    {
        *(.usr_stack .usr_stack.*);
        ___usr_stack_end = . ; 
    } > ram1
    
    .stacks ALIGN(0x08):
    {
        ___usr_stack = . ; 
        . += 1024;
        ___usr_stack_end = . ;

        ___fiq_stack = . ; 
        . += 512;
        ___fiq_stack_end = . ;

        ___irq_stack = . ; 
        . += 512;
        ___irq_stack_end = . ;

        ___svc_stack = . ; 
        . += 128;
        ___svc_stack_end = . ;

        ___abt_stack = . ; 
        . += 128;
        ___abt_stack_end = . ;

        ___und_stack = . ; 
        . += 128;
        ___und_stack_end = . ;
    } > ram1

    /DISCARD/ :
    {
        *(.ARM.exidx.*);
    }
}
