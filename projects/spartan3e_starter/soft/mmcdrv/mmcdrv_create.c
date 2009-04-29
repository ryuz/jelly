/** 
 *  Hyper Operating System  Application Framework
 *
 * @file  mmcdrv.h
 * @brief %jp{メモリマップドファイル用デバイスドライバ}
 *
 * Copyright (C) 2006-2007 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "mmcdrv_local.h"




/** 生成 */
HANDLE MmcDrv_Create(void)
{
	C_MMCDRV *self;
	
	/* メモリ確保 */
	if ( (self = (C_MMCDRV *)SysMem_Alloc(sizeof(C_MMCDRV))) == NULL )
	{
		return HANDLE_NULL;
	}
	
	/* コンストラクタ呼び出し */
	MmcDrv_Constructor(self, NULL);
	
	return (HANDLE)self;
}


/* end of file */
