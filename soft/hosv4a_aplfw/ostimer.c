/** 
 *  Sample program for Hyper Operating System V4 Advance
 *
 * @file  ostimer.c
 * @brief %jp{OSタイマ}%en{OS timer}
 *
 * Copyright (C) 1998-2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "hosaplfw.h"
#include "system/sysapi/sysapi.h"
#include "ostimer.h"


#define TIMER0_CONTROL	((volatile unsigned long *)0xf1000000)
#define TIMER0_COMPARE	((volatile unsigned long *)0xf1000004)
#define TIMER0_COUNTER	((volatile unsigned long *)0xf100000c)

#define INTNO_TIMER0	0



static void OsTimer_Isr(VPARAM Param);		/**< %jp{タイマ割込みサービスルーチン} */


/** %jp{OS用タイマ初期化ルーチン} */
void OsTimer_Initialize(void)
{
	/* %jp{割込みサービスルーチン生成} */
	SysIsr_Create(INTNO_TIMER0, OsTimer_Isr, (VPARAM)0);
	
	/* %jp{開始} */
	*TIMER0_COMPARE = (50000 - 1);		/* 50Mhz / 50000 = 1kHz (1ms) */
	*TIMER0_CONTROL = 0x0002;			/* clear */
	*TIMER0_CONTROL = 0x0001;			/* start */
	
	/* %jp{割込み許可} */
	SysInt_Enable(INTNO_TIMER0);
}


/** %jp{タイマ割込みハンドラ} */
void OsTimer_Isr(VPARAM Param)
{
	/* %jp{要因クリア} */
	SysInt_Clear(INTNO_TIMER0);
	
	/* %jp{タイムティック供給} */
	SysTim_Signal(1000000);		/* 1ms = 1,000,000 ns */
}


/** システム時刻をナノ秒に換算(システム用) */
unsigned long SysTim_SysTimeToNanosecond(SYSTIM_SYSTIME SysTime)
{
	return (unsigned long)(SysTime % 1000000000);
}

/* システム時刻を秒に換算(システム用) */
unsigned long  SysTim_SysTimeToSecond(SYSTIM_SYSTIME SysTime)
{
	return (unsigned long)(SysTime / 1000000000);
}






/* end of file */

