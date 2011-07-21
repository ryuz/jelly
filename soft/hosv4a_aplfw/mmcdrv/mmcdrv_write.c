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
#include "mmcfile_local.h"


FILE_SIZE MmcDrv_Write(C_DRVOBJ *pDrvObj, C_FILEOBJ *pFileObj, const void *pData, FILE_SIZE Size)
{
	C_MMCDRV			*self;
	C_MMCFILE			*pFile;
	FILE_SIZE			WriteSize;
	FILE_SIZE			TotalSize = 0;
	const unsigned char	*pubData;

	/* upper cast */
	self  = (C_MMCDRV *)pDrvObj;
	pFile = (C_MMCFILE *)pFileObj;
	
	SysMtx_Lock(self->hMtx);
	
	pubData = (const unsigned char *)pData;
	while ( Size >= 512 )
	{
		WriteSize = MmcDrv_BlockWrite(self, (unsigned long)pFile->FilePos, (void *)pubData);
		Size           -= WriteSize;
		TotalSize      += WriteSize;
		pubData        += WriteSize;
		pFile->FilePos += WriteSize;
	}
	
	SysMtx_Unlock(self->hMtx);
	
	return TotalSize;
}


/* end of file */
