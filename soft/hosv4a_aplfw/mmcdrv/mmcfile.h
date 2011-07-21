/** 
 * Hyper Operating System  Application Framework
 *
 * @file  mmcfile.h
 * @brief %jp{memory file 公開ヘッダファイル}%en{Memory File public header file}
 *
 * Copyright (C) 2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#ifndef __HOS__mmcfile_h__
#define __HOS__mmcfile_h__


#include "mmcdrv_local.h"


#ifdef __cplusplus
extern "C" {
#endif

HANDLE MmcFile_Create(C_MMCDRV *pMmcDrv, int iMode);
void   MmcFile_Delete(HANDLE hFile);

#ifdef __cplusplus
}
#endif


#endif	/*  __HOS__mmcfile_h__ */


/* end of file */
