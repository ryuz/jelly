/** 
 * Hyper Operating System  Application Framework
 *
 * @file  memfile.h
 * @brief %jp{memory file オブジェクト削除}%en{Memory File  delete}
 *
 * Copyright (C) 2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "memfile_local.h"


void MemFile_Delete(HANDLE hFile)
{
	C_MEMFILE *self;
	
	self = (C_MEMFILE *)hFile;
	
	/* デストラクタ */
	MemFile_Destructor(self);
	
	/* メモリ削除 */
	SysMem_Free(self);
}


/* end of file */
