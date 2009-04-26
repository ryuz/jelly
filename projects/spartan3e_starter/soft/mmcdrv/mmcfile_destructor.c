/** 
 * Hyper Operating System  Application Framework
 *
 * @file  memfile_destructor.c
 * @brief %jp{memory file デストラクタ}%en{Memory File  destructor}
 *
 * Copyright (C) 2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "memfile_local.h"


void  MemFile_Destructor(C_MEMFILE *self)
{
	/* 親クラスデストラクタ */		
	FileObj_Destructor(&self->FileObj);
}


/* end of file */
