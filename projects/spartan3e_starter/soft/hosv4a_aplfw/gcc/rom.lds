OUTPUT_ARCH(mips)
ENTRY(_reset_handler)

MEMORY
{
	rom    : o = 0x00000000, l = 0x00100000
	ram    : o = 0x10000000, l = 0x00100000
}

SECTIONS
{
	.text :
	{
		 ___text = . ; 
		*/crt0.o(.text)
		*(.text)
		*(.strings)
		*(.rodata*)
		*(.glue*)
		 ___text_end = . ; 
	}  > rom
	.tors :
	{
		. = ALIGN(4);
		___ctors = . ;
		*(.ctors)
		___ctors_end = . ;
		___dtors = . ;
		*(.dtors)
		___dtors_end = . ;
	} > rom
	data : AT (ADDR(.tors) + SIZEOF(.tors))
	{
	    ___data_rom = ADDR(.tors) + SIZEOF(.tors);
		___data = . ;
		*(.data)
		_gp = ALIGN(16) + 0x7ff0;
		*(.sdata)
		*(.eh_frame)
		___data_end = . ;
	} > ram
	.bss :
	{
		___bss = . ;
		*(.sbss)
		*(.bss)
		*(COMMON)
		*(.scommon)
		___bss_end = . ;  
	}  >ram
}

