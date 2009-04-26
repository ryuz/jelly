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


/** デストラクタ */
void MmcDrv_Destructor(C_MMCDRV *self)
{
	/* オブジェクト削除 */
	SysMtx_Delete(self->hMtx);
	
	/* 親クラスデストラクタ */
	DrvObj_Destructor(&self->DrvObj);
}


/* end of file */
