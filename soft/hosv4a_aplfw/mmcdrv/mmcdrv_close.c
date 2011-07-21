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
#include "system/sysapi/sysapi.h"


/** クローズ */
void MmcDrv_Close(C_DRVOBJ *pDrvObj, C_FILEOBJ *pFileObj)
{
	C_MMCDRV	*self;
	C_MMCFILE	*pFile;
	
	/* upper cast */
	self  = (C_MMCDRV *)pDrvObj;
	pFile = (C_MMCFILE *)pFileObj;

	SysMtx_Lock(self->hMtx);
	
	/* クローズ処理 */
	--self->iOpenCount;
	
	/* ディスクリプタ削除 */
	FileObj_Delete((C_FILEOBJ *)pFile);	
	SysMem_Free(pFile);

	SysMtx_Unlock(self->hMtx);
}


/* end of file */
