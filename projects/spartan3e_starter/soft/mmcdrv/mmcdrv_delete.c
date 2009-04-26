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


/** 削除 */
void MmcDrv_Delete(HANDLE hDriver)
{
	C_MMCDRV	*self;
	
	/* upper cast */
	self = (C_MMCDRV *)hDriver;

	/* デストラクタ呼び出し */
	MmcDrv_Destructor(self);
	
	/* メモリ削除 */
	SysMem_Free(self);
}



/* end of file */
