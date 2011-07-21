/** 
 * Hyper Operating System  Application Framework
 *
 * @file  mmcfile.h
 * @brief %jp{memory file オブジェクト削除}%en{Memory File  delete}
 *
 * Copyright (C) 2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "mmcfile_local.h"


void MmcFile_Delete(HANDLE hFile)
{
	C_MMCFILE *self;
	
	self = (C_MMCFILE *)hFile;
	
	/* デストラクタ */
	MmcFile_Destructor(self);
	
	/* メモリ削除 */
	SysMem_Free(self);
}


/* end of file */
