/** 
 *  Sample program for Hyper Operating System V4 Advance
 *
 * @file  uart.h
 * @brief %jp{UARTへの出力}%en{UART device driver}
 *
 * Copyright (C) 1998-2006 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#ifndef __ostimer_h__
#define __ostimer_h__


#ifdef __cplusplus
extern "C" {
#endif

void Uart_Initialize(void);					/* %jp{UART の初期化} */
void Uart_PutChar(int c);					/* %jp{1文字出力} */
void Uart_PutString(const char *text);		/* %jp{文字列出力} */

void Uart_PutHexByte(char c);
void Uart_PutHexHalfWord(unsigned short h);
void Uart_PutHexWord(unsigned long w);


#ifdef __cplusplus
}
#endif


#endif	/* __ostimer_h__ */


/* end of file */
