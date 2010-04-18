/** 
 *  Sample program for Hyper Operating System V4 Advance
 *
 * @file  sample.c
 * @brief %jp{サンプルプログラム}%en{Sample program}
 *
 * Copyright (C) 1998-2009 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include <stdlib.h>
#include <string.h>
#include "kernel.h"
#include "kernel_id.h"
#include "uart.h"


#define LEFT(num)	((num) <= 1 ? 5 : (num) - 1)
#define RIGHT(num)	((num) >= 5 ? 1 : (num) + 1)


/** %jp{初期化ハンドラ} */
void Sample_Initialize(VP_INT exinf)
{
	/* %jp{UART初期化} */
	Uart_Initialize();
	
	/* %jp{タスク起動} */
	act_tsk(TSKID_SAMPLE1);
	act_tsk(TSKID_SAMPLE2);
	act_tsk(TSKID_SAMPLE3);
	act_tsk(TSKID_SAMPLE4);
	act_tsk(TSKID_SAMPLE5);
}


/** %jp{適当な時間待つ} */
void Sample_RandWait(void)
{
	static unsigned long seed = 12345;
	unsigned long r;
	
	wai_sem(SEMID_RAND);
	seed = seed * 22695477UL + 1;
	r = seed;
	sig_sem(SEMID_RAND);
	
	dly_tsk((r % 1000) + 100);
}


/** %jp{状態表示} */
void Sample_PrintSatet(int num, const char *text)
{
	int	i;
	
	wai_sem(SEMID_UART);
	
	/* %jp{文字列出力} */
	Uart_PutChar('0' + num);
	Uart_PutChar(' ');
	Uart_PutChar(':');
	Uart_PutChar(' ');
	for ( i = 0; text[i] != '\0'; i++ )
	{
		Uart_PutChar(text[i]);
	}
	Uart_PutChar('\r');
	Uart_PutChar('\n');
	
	sig_sem(SEMID_UART);
}


/** %jp{サンプルタスク} */
void Sample_Task(VP_INT exinf)
{
	int num;
	
	num = (int)exinf;
	
	/* %jp{いわゆる哲学者の食事の問題} */
	for ( ; ; )
	{
		/* %jp{適当な時間考える} */
		Sample_PrintSatet(num, "thinking");
		Sample_RandWait();
		
		/* %jp{左右のフォークを取るまでループ} */
		for ( ; ; )
		{
			/* %jp{左から順に取る} */
			wai_sem(LEFT(num));
			if ( pol_sem(RIGHT(num)) == E_OK )
			{
				break;	/* %jp{両方取れた} */
			}
			sig_sem(LEFT(num));	/* %jp{取れなければ離す} */
			
			/* %jp{適当な時間待つ} */
			Sample_PrintSatet(num, "hungry");
			Sample_RandWait();
			
			/* %jp{右から順に取る} */
			wai_sem(RIGHT(num));
			if ( pol_sem(LEFT(num)) == E_OK )
			{
				break;	/* %jp{両方取れた} */
			}
			sig_sem(RIGHT(num));	/* %jp{取れなければ離す} */
			
			/* %jp{適当な時間待つ} */
			Sample_PrintSatet(num, "hungry");
			Sample_RandWait();
		}
		
		/* %jp{適当な時間、食べる} */
		Sample_PrintSatet(num, "eating");
		Sample_RandWait();
		
		/* %jp{フォークを置く} */
		sig_sem(LEFT(num));
		sig_sem(RIGHT(num));
	}
}


/* end of file */
