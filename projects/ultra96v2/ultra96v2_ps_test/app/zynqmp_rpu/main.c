/** 
 *  Sample program for Hyper Operating System V4 Advance
 *
 * @file  main.c
 * @brief %jp{メイン関数}%en{main}
 *
 * Copyright (C) 1998-2020 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "kernel.h"
#include "arch/irc/arm/pl390/irc.h"


/** %jp{メイン関数} */
int main()
{
	int i;
	
    volatile long long* buf = (volatile long long*)0x80000000;
    long long tmp = 0;

//    for ( ; ; ) {
    	volatile int time0 = *(volatile int*)0xa0000000;
        for ( i = 0; i < 0x1000000; ++i ) {
        	tmp = buf[i];
//        	buf[i] = tmp;
    	}
    	volatile int time1 = *(volatile int*)0xa0000000;
    	volatile int time2 = time1 - time0;

//   	*(volatile int*)0xa0000000 = *(volatile int*)0x80000000; // 
		*(volatile int*)0xa0000010 = time2;
//		*(volatile int*)0xa0000020 = time0;
//		*(volatile int*)0xa0000030 = time1;
//   	*(volatile int*)0xa0000040 = tmp;
//    	*(volatile int*)0xa0000050 = 0x12345678;
//    }

	for(;;);

	/* ICD(Distributor) setup */
	UB targetcpu = 0x01;
	vdis_icd();
	
	/* set TTC0-1 */
	vchg_icdiptr(74, targetcpu);   /* set ICDIPTR */

	/* PL */
	for ( i = 0; i < 8; ++i ) {
		vchg_icdiptr(121 + i, targetcpu);  						/* set ICDIPTR */
		vchg_icdicfr(121 + i, _KERNEL_ARM_PL390_ICDICFR_EDGE);  /* set ICDICFR */
	}
	for ( i = 0; i < 8; ++i ) {
		vchg_icdiptr(136 + i, targetcpu);  						/* set ICDIPTR */
		vchg_icdicfr(136 + i, _KERNEL_ARM_PL390_ICDICFR_EDGE);  /* set ICDICFR */
	}

	vena_icd();	/* enable IDC */

	/* %jp{カーネルの動作開始} */
	vsta_knl();
	
	return 0;
}


/* end of file */
