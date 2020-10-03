/** 
 *  Hyper Operating System  Application Framework
 *
 * @file  mmcdrv.h
 * @brief %jp{MMC用デバイスドライバ}
 *
 * Copyright (C) 2006-2007 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "mmcdrv_local.h"


/* 仮想関数テーブル */
static const T_DRVOBJ_METHODS MmcDrv_Methods = 
	{
		{ MmcDrv_Delete },
		MmcDrv_Open,
		MmcDrv_Close,
		MmcDrv_IoControl,
		MmcDrv_Seek,
		MmcDrv_Read,
		MmcDrv_Write,
		MmcDrv_Flush,
		MmcDrv_GetInformation,
	};


/** コンストラクタ */
void MmcDrv_Constructor(C_MMCDRV *self, const T_DRVOBJ_METHODS *pMethods)
{
	if ( pMethods == NULL )
	{
		pMethods = &MmcDrv_Methods;
	}
	
	/* 親クラスコンストラクタ呼び出し */
	DrvObj_Constructor(&self->DrvObj, pMethods);
	
	/* メンバ変数初期化 */
	self->iOpenCount = 0;
	
	/* ミューテックス生成 */
	self->hMtx = SysMtx_Create(SYSMTX_ATTR_NORMAL);
}


/* end of file */
