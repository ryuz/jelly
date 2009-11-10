/** 
 *  Sample program for Hyper Operating System V4 Advance
 *
 * @file  sample.c
 * @brief %jp{サンプルプログラム}%en{Sample program}
 *
 * Copyright (C) 1998-2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include <string.h>


size_t strlen(const char *string)
{
	size_t i;
	
	for ( i = 0; string[i] != '\0'; i++ )
		;
	
	return i;
}


/* end of file */
