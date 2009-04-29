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


void *memcpy(void *dst, const void *src, size_t count)
{
	char		*pDst;
	const char	*pSrc;
	
	pDst = (char       *)dst;
	pSrc = (const char *)src;
	while ( count-- > 0 )
	{
		*pDst++ = *pSrc++;
	}
	
	return dst;
}


/* end of file */
