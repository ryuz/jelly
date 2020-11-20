/** 
 *  Sample program for Hyper Operating System V4 Advance
 *
 * @file  ostimer.c
 * @brief %jp{OSタイマ}%en{OS timer}
 *
 * Copyright (C) 1998-2006 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#ifndef __ostimer_h__
#define __ostimer_h__


#ifdef __cplusplus
extern "C" {
#endif

/** %jp{OS用タイマ初期化ルーチン} */
void OsTimer_Initialize(VP_INT exinf);

#ifdef __cplusplus
}
#endif


#endif	/* __ostimer_h__ */


/* end of file */
