/** 
 *  Hyper Operating System  Application Framework
 *
 * @file  mmcdrv.h
 * @brief %jp{メモリマップドファイル用デバイスドライバ}
 *
 * Copyright (C) 2006-2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "hosaplfw.h"
#include "mmcdrv_local.h"



FILE_ERR MmcDrv_GetInformation(C_DRVOBJ *pDrvObj, char *pszInformation, int iLen)
{
	C_MMCDRV *self;
	
	/* upper cast */
	self = (C_MMCDRV *)pDrvObj;
		
	return FILE_ERR_OK;
}


/* end of file */
