/** 
 *  Hyper Operating System  Application Framework
 *
 * @file  mmcdrv.h
 * @brief %jp{MMC用デバイスドライバ}
 *
 * Copyright (C) 2006-2009 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#ifndef __HOS__mmcdrv_h__
#define __HOS__mmcdrv_h__


#include "system/file/drvobj.h"


#ifdef __cplusplus
extern "C" {
#endif

HANDLE MmcDrv_Create(void);				/**< 生成 */
void   MmcDrv_Delete(HANDLE hDriver);	/**< 削除 */

#ifdef __cplusplus
}
#endif


#endif	/* __HOS__mmcdrv_h__ */


/* end of file */
