/** 
 * Hyper Operating System  Application Framework
 *
 * @file  mmcfile.h
 * @brief %jp{memory file ローカルヘッダファイル}%en{Memory File private header file}
 *
 * Copyright (C) 2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#ifndef __HOS__mmcfile_local_h__
#define __HOS__mmcfile_local_h__


#include "mmcfile.h"
#include "system/file/fileobj_local.h"
#include "system/sysapi/sysapi.h"


/* ファイルディスクリプタ */
typedef struct c_mmcfile
{
	C_FILEOBJ	FileObj;			/* 継承 */

	FILE_POS	FilePos;
} C_MMCFILE;


#ifdef __cplusplus
extern "C" {
#endif

void  MmcFile_Constructor(C_MMCFILE *self, const T_FILEOBJ_METHODS *pMethods, C_MMCDRV *pMmcDrv, int iMode);
void  MmcFile_Destructor(C_MMCFILE *self);

#ifdef __cplusplus
}
#endif



#endif	/*  __HOS__mmcfile_local_h__ */


/* end of file */
