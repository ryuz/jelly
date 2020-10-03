OUTPUT_ARCH(mips)
ENTRY(_reset_handler)

MEMORY
{
	ro_area : o = 0x00000000, l = 0x00004000
	rw_area : o = 0x00004000, l = 0x00004000
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
	}  > ro_area
	.tors :
	{
		. = ALIGN(4);
		___ctors = . ;
		*(.ctors)
		___ctors_end = . ;
		___dtors = . ;
		*(.dtors)
		___dtors_end = . ;
	} > ro_area
	.data : AT (ADDR(.tors) + SIZEOF(.tors))
	{
	    ___data_rom = ADDR(.tors) + SIZEOF(.tors);
		___data = . ;
		*(.data)
		_gp = ALIGN(16) + 0x7ff0;
		*(.sdata)
		___data_end = . ;
	} > rw_area
	.bss :
	{
		___bss = . ;
		*(.sbss)
		*(.bss)
		*(COMMON)
		*(.scommon)
		___bss_end = . ;  
	} > rw_area
}

