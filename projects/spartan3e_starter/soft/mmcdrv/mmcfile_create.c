/** 
 * Hyper Operating System  Application Framework
 *
 * @file  memfile.h
 * @brief %jp{memory file 公開ヘッダファイル}%en{Memory File public header file}
 *
 * Copyright (C) 2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "memfile_local.h"


static const T_FILEOBJ_METHODS MemFile_FileObjMethods =
	{
		{File_Close},	/* デストラクタ */
	};


HANDLE MemFile_Create(C_MMCDRV *pMemVol, int iMode)
{
	C_MEMFILE *self;

	/* create file descriptor */
	if ( (self = (C_MEMFILE *)SysMem_Alloc(sizeof(C_MEMFILE))) == NULL )
	{
		return HANDLE_NULL;
	}
	
	/* コンストラクタ呼び出し */
	MemFile_Constructor(self, &MemFile_FileObjMethods, pMemVol, iMode);
	
	return (HANDLE)self;
}


/* end of file */
