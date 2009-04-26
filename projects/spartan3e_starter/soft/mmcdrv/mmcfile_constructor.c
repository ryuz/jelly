/** 
 * Hyper Operating System  Application Framework
 *
 * @file  memfile_constructor.c
 * @brief %jp{memory file コンストラクタ}%en{Memory File  constructor}
 *
 * Copyright (C) 2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "memfile_local.h"


void MemFile_Constructor(C_MEMFILE *self, const T_FILEOBJ_METHODS *pMethods, C_MMCDRV *pMmcDrv, int iMode)
{
	/* 親クラスコンストラクタ */
	FileObj_Constructor(&self->FileObj, pMethods, &pMmcDrv->DrvObj, iMode);
	
	/* メンバ変数初期化 */
	self->FilePos = 0;
}


/* end of file */
