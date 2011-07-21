/** 
 *  Sample program for Hyper Operating System V4 Advance
 *
 * @file  ostimer.c
 * @brief %jp{OSタイマ}%en{OS timer}
 *
 * Copyright (C) 1998-2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "kernel.h"
#include "ostimer.h"


#define TIMER0_CONTROL	((volatile UW *)0xfffff100)
#define TIMER0_COMPARE	((volatile UW *)0xfffff104)
#define TIMER0_COUNTER	((volatile UW *)0xfffff10c)

#define INTNO_TIMER0	0



static void OsTimer_Isr(VP_INT exinf);		/**< %jp{タイマ割込みサービスルーチン} */


/** %jp{OS用タイマ初期化ルーチン} */
void OsTimer_Initialize(VP_INT exinf)
{
	T_CISR cisr;
	
	/* %jp{割込みサービスルーチン生成} */
	cisr.isratr = TA_HLNG;
	cisr.exinf  = 0;
	cisr.intno  = INTNO_TIMER0;
	cisr.isr    = (FP)OsTimer_Isr;
	acre_isr(&cisr);
	
	/* 開始 */
	*TIMER0_COMPARE = (50000 - 1);		/* 50Mhz / 50000 = 1kHz (1ms) */
	*TIMER0_CONTROL = 0x0002;			/* clear */
	*TIMER0_CONTROL = 0x0001;			/* start */
	
	/* 割込み許可 */
	ena_int(INTNO_TIMER0);
}


/** %jp{タイマ割込みハンドラ} */
void OsTimer_Isr(VP_INT exinf)
{
	/* %jp{要因クリア} */
	vclr_int(INTNO_TIMER0);
	
	/* %jp{タイムティック供給} */
	isig_tim();
}



/* end of file */
