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


FILE_POS MmcDrv_Seek(C_DRVOBJ *pDrvObj, C_FILEOBJ *pFileObj, FILE_POS Offset, int iOrign)
{
	C_MMCDRV	*self;
	C_MMCFILE	*pFile;
	
	/* upper cast */
	self  = (C_MMCDRV *)pDrvObj;
	pFile = (C_MMCFILE *)pFileObj;
	
	/* シーク */
	switch ( iOrign )
	{
	case FILE_SEEK_SET:
		pFile->FilePos  = Offset;
		break;
		
	case FILE_SEEK_CUR:
		pFile->FilePos += Offset;
		break;
		
	case FILE_SEEK_END:
		pFile->FilePos = self ->FileSize + Offset;
		break;
		
	default:
		return FILE_ERR_NG;
	}
	
	/* 範囲クリップ */
	if ( pFile->FilePos < 0 )
	{
		pFile->FilePos = 0;
	}
	if ( pFile->FilePos > self->FileSize )
	{
		pFile->FilePos = self->FileSize;
	}

	return pFile->FilePos;
}


/* end of file */
