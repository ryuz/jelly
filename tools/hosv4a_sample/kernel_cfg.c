/* ------------------------------------------------------------------------ */
/*  HOS-V4a  kernel configuration                                           */
/*    kernel object create and initialize                                   */
/*                                                                          */
/* ------------------------------------------------------------------------ */


#include "kernel.h"
#include "arch/proc/mips/mips1/procatr.h"
#include "arch/proc/mips/mips1/proc.h"
#include "arch/irc/mips/jelly/ircatr.h"
#include "arch/irc/mips/jelly/irc.h"
#include "config/cfgknl.h"
#include "parser/parsknl.h"
#include "core/objid.h"
#include "core/objhdl.h"
#include "object/tskobj.h"
#include "object/semobj.h"
#include "object/flgobj.h"
#include "object/dtqobj.h"
#include "object/mbxobj.h"
#include "object/mtxobj.h"
#include "object/mpfobj.h"
#include "object/inhobj.h"
#include "object/isrobj.h"
#include "object/cycobj.h"
#include "kernel_id.h"

#include "ostimer.h"
#include "sample.h"



/* ------------------------------------------ */
/*                kernel heap                 */
/* ------------------------------------------ */

VP_INT _kernel_hep_memblk[((128) + sizeof(VP_INT) - 1) / sizeof(VP_INT)];



/* ------------------------------------------ */
/*               system stack                 */
/* ------------------------------------------ */

VP         _kernel_sys_stkblk[((256) + sizeof(VP) - 1) / sizeof(VP)];	/* system stack block*/




/* ------------------------------------------ */
/*             interrupt stack                */
/* ------------------------------------------ */

VP       _kernel_int_stkblk[((256) + sizeof(VP) - 1) / sizeof(VP)];
const VP _kernel_int_isp = &_kernel_int_stkblk[((256) + sizeof(VP) - 1) / sizeof(VP)];



/* ------------------------------------------ */
/*          create task objects               */
/* ------------------------------------------ */

static VP _kernel_tsk1_stk[((256) + sizeof(VP) - 1) / sizeof(VP)];
static VP _kernel_tsk2_stk[((256) + sizeof(VP) - 1) / sizeof(VP)];
static VP _kernel_tsk3_stk[((256) + sizeof(VP) - 1) / sizeof(VP)];
static VP _kernel_tsk4_stk[((256) + sizeof(VP) - 1) / sizeof(VP)];
static VP _kernel_tsk5_stk[((256) + sizeof(VP) - 1) / sizeof(VP)];

_KERNEL_T_TCB _kernel_tcb_blk_1 = {{0}, NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, (_KERNEL_TSK_T_EXINF)(1), (Sample_Task), (2), ((VB*)_kernel_tsk1_stk + sizeof(_kernel_tsk1_stk)), 0, };
_KERNEL_T_TCB _kernel_tcb_blk_2 = {{0}, NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, (_KERNEL_TSK_T_EXINF)(2), (Sample_Task), (2), ((VB*)_kernel_tsk2_stk + sizeof(_kernel_tsk2_stk)), 0, };
_KERNEL_T_TCB _kernel_tcb_blk_3 = {{0}, NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, (_KERNEL_TSK_T_EXINF)(3), (Sample_Task), (2), ((VB*)_kernel_tsk3_stk + sizeof(_kernel_tsk3_stk)), 0, };
_KERNEL_T_TCB _kernel_tcb_blk_4 = {{0}, NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, (_KERNEL_TSK_T_EXINF)(4), (Sample_Task), (2), ((VB*)_kernel_tsk4_stk + sizeof(_kernel_tsk4_stk)), 0, };
_KERNEL_T_TCB _kernel_tcb_blk_5 = {{0}, NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, (_KERNEL_TSK_T_EXINF)(5), (Sample_Task), (2), ((VB*)_kernel_tsk5_stk + sizeof(_kernel_tsk5_stk)), 0, };


_KERNEL_T_TCB *_kernel_tcb_tbl[6] =
	{
		&_kernel_tcb_blk_1,
		&_kernel_tcb_blk_2,
		&_kernel_tcb_blk_3,
		&_kernel_tcb_blk_4,
		&_kernel_tcb_blk_5,
		NULL,
	};

const ID	_kernel_max_tskid = 6;



/* ------------------------------------------ */
/*         create semaphore objects           */
/* ------------------------------------------ */

_KERNEL_T_SEMCB _kernel_semcb_blk_1 = {{0}, (1), (TA_TFIFO), (1), };
_KERNEL_T_SEMCB _kernel_semcb_blk_2 = {{0}, (1), (TA_TFIFO), (1), };
_KERNEL_T_SEMCB _kernel_semcb_blk_3 = {{0}, (1), (TA_TFIFO), (1), };
_KERNEL_T_SEMCB _kernel_semcb_blk_4 = {{0}, (1), (TA_TFIFO), (1), };
_KERNEL_T_SEMCB _kernel_semcb_blk_5 = {{0}, (1), (TA_TFIFO), (1), };
_KERNEL_T_SEMCB _kernel_semcb_blk_6 = {{0}, (1), (TA_TFIFO), (1), };
_KERNEL_T_SEMCB _kernel_semcb_blk_7 = {{0}, (1), (TA_TFIFO), (1), };


_KERNEL_T_SEMCB *_kernel_semcb_tbl[7] =
	{
		&_kernel_semcb_blk_1,
		&_kernel_semcb_blk_2,
		&_kernel_semcb_blk_3,
		&_kernel_semcb_blk_4,
		&_kernel_semcb_blk_5,
		&_kernel_semcb_blk_6,
		&_kernel_semcb_blk_7,
	};

const ID	_kernel_max_semid = 7;



/* ------------------------------------------ */
/*        create data queue objects           */
/* ------------------------------------------ */





_KERNEL_T_DTQCB *_kernel_dtqcb_tbl[15] =
	{
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
	};

const ID	_kernel_max_dtqid = 15;



/* ------------------------------------------ */
/*         create mtxaphore objects           */
/* ------------------------------------------ */



_KERNEL_T_MTXCB *_kernel_mtxcb_tbl[1] =
	{
		NULL,
	};

const ID	_kernel_max_mtxid = 1;



/* ------------------------------------------ */
/*                 system                     */
/* ------------------------------------------ */

const _KERNEL_T_SYSCB_RO _kernel_syscb_ro =
	{
		{
			TIC_NUME / TIC_DENO,
			TIC_NUME % TIC_DENO,
			TIC_DENO,
		},
	};

_KERNEL_T_SYSCB _kernel_syscb;




/* ------------------------------------------ */
/*       create cyclic handler objects        */
/* ------------------------------------------ */



_KERNEL_T_CYCCB *_kernel_cyccb_tbl[15] =
	{
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
	};

const ID	_kernel_max_cycid = 15;



/* ------------------------------------------ */
/*        define interrupt handler            */
/* ------------------------------------------ */


_KERNEL_T_INHINF _kernel_inh_tbl[2] =
	{
		{(FP)NULL},
		{(FP)NULL},
	};




/* ------------------------------------------ */
/*        interrupt control objects           */
/* ------------------------------------------ */

const INTNO _kernel_min_intno = 0;
const INTNO _kernel_max_intno = 255;

_KERNEL_T_INTINF _kernel_int_tbl[256];


_KERNEL_T_ISRCB *_kernel_isrcb_tbl[2];
const ID        _kernel_max_isrid = 2;



/* ------------------------------------------ */
/*          initialize functions              */
/* ------------------------------------------ */

/* object initialize */
void _kernel_cfg_ini(void)
{
	_KERNEL_SYS_INI_HEP(sizeof(_kernel_hep_memblk), _kernel_hep_memblk);
	_KERNEL_SYS_INI_SYSSTK((SIZE)sizeof(_kernel_sys_stkblk), (VP)(_kernel_sys_stkblk));
	_KERNEL_SYS_INI_INTSTK((SIZE)sizeof(_kernel_int_stkblk), (VP)(_kernel_int_stkblk));
}

/* start up */
void _kernel_cfg_sta(void)
{

	/* call initialize routine*/
	((FP)(OsTimer_Initialize))((VP_INT)(0));
	((FP)(Sample_Initialize))((VP_INT)(0));
}


/* ------------------------------------------------------------------------ */
/*  End of file                                                             */
/* ------------------------------------------------------------------------ */
