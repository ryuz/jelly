/** 
 * Hyper Operating System  Application Framework
 *
 * @file  mmcfile_destructor.c
 * @brief %jp{memory file デストラクタ}%en{Memory File  destructor}
 *
 * Copyright (C) 2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "mmcfile_local.h"


void  MmcFile_Destructor(C_MMCFILE *self)
{
	/* 親クラスデストラクタ */		
	FileObj_Destructor(&self->FileObj);
}


/* end of file */
