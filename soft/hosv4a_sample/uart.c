/** 
 *  Sample program for Hyper Operating System V4 Advance
 *
 * @file  uart.c
 * @brief %jp{UART‚Ö‚Ìo—Í}%en{UART device driver}
 *
 * Copyright (C) 1998-2006 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "kernel.h"


#define UART0_DATA	((volatile UW *)0xfffff200)
#define UART0_STAT	((volatile UW *)0xfffff204)



/* %jp{UART‚Ì‰Šú‰»} */
void Uart_Initialize(void)
{
}


/* %jp{1•¶š“ü—Í} */
char Uart_GetChar(void)
{
	while ( !(*UART0_STAT & 0x01) )
		;
	
	return *UART0_DATA;
}


/* %jp{1•¶šo—Í} */
void Uart_PutChar(int c)
{
	while ( !(*UART0_STAT & 0x02) )
		;
	
	*UART0_DATA = c;
}


/* %jp{•¶š—ño—Í} */
void Uart_PutString(const char *text)
{
	while ( *text != '\0' )
	{
		if ( *text == '\n' )
		{
			Uart_PutChar('\r');
			Uart_PutChar('\n');
		}
		else
		{
			Uart_PutChar(*text);
		}
		
		text++;
	}
}


char Uart_hex2asc(int a)
{
	if ( a < 10 )
	{
		return '0' + a;
	}
	return 'a' + a - 10;
}


void Uart_PutHexByte(char c)
{
	Uart_PutChar(Uart_hex2asc((c >> 4) & 0xf));
	Uart_PutChar(Uart_hex2asc((c >> 0) & 0xf));
}


void Uart_PutHexHalfWord(unsigned short h)
{
	Uart_PutHexByte((h >> 8) & 0xff);
	Uart_PutHexByte((h >> 0) & 0xff);
}

void Uart_PutHexWord(unsigned long w)
{
	Uart_PutHexHalfWord((w >> 16) & 0xffff);
	Uart_PutHexHalfWord((w >>  0) & 0xffff);
}



/* end of file */
