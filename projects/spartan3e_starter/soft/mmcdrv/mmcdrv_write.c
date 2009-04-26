/** 
 *  Hyper Operating System  Application Framework
 *
 * @file  mmcdrv.h
 * @brief %jp{メモリマップドファイル用デバイスドライバ}
 *
 * Copyright (C) 2006-2007 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include <string.h>
#include "mmcdrv_local.h"
#include "memfile_local.h"


FILE_SIZE MmcDrv_Write(C_DRVOBJ *pDrvObj, C_FILEOBJ *pFileObj, const void *pData, FILE_SIZE Size)
{
	C_MMCDRV	*self;
	C_MEMFILE	*pFile;
	
	/* upper cast */
	self  = (C_MMCDRV *)pDrvObj;
	pFile = (C_MEMFILE *)pFileObj;

	
	SysMtx_Lock(self->hMtx);
	
	/* サイズクリップ */
	if ( Size > self->MemSize - pFile->FilePos )
	{
		Size = self->MemSize - pFile->FilePos;
	}
	
	/* 書込み */
	memcpy(self->pubMemAddr + pFile->FilePos, pData, Size);
	pFile->FilePos += Size;
	
	/* ファイルサイズ拡張 */
	if ( self->FileSize < pFile->FilePos )
	{
		self->FileSize = pFile->FilePos;
	}
	
	SysMtx_Unlock(self->hMtx);
	
	return Size;
}


/* end of file */
