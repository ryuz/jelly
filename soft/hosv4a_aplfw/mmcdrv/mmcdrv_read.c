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



FILE_SIZE MmcDrv_Read(C_DRVOBJ *pDrvObj, C_FILEOBJ *pFileObj, void *pBuf, FILE_SIZE Size)
{
	C_MMCDRV		*self;
	C_MMCFILE		*pFile;
	FILE_SIZE		ReadSize;
	FILE_SIZE		TotalSize = 0;
	unsigned char	*pubBuf;

	/* upper cast */
	self  = (C_MMCDRV *)pDrvObj;
	pFile = (C_MMCFILE *)pFileObj;
	
	SysMtx_Lock(self->hMtx);
	
	pubBuf = (unsigned char *)pBuf;
	while ( Size >= 512 )
	{
		ReadSize = MmcDrv_BlockRead(self, (unsigned long)pFile->FilePos, (void *)pubBuf);
		Size           -= ReadSize;
		TotalSize      += ReadSize;
		pubBuf         += ReadSize;
		pFile->FilePos += ReadSize;
	}
	
	SysMtx_Unlock(self->hMtx);
	
	return TotalSize;
}


/* end of file */
