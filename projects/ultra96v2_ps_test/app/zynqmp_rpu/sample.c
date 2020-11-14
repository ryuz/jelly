/** 
 *  Sample program for Hyper Operating System V4 Advance
 *
 * @file  sample.c
 * @brief %jp{サンプルプログラム}%en{Sample program}
 *
 * Copyright (C) 1998-2006 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */

#include <stdlib.h>
#include <string.h>
#include "kernel.h"
#include "kernel_id.h"
#include "uart.h"


#define LEFT(num)	((num) <= 1 ? 5 : (num) - 1)
#define RIGHT(num)	((num) >= 5 ? 1 : (num) + 1)


ID mbxid;
ID mpfid;


/** %jp{メッセージ構造体} */
typedef struct t_print_msg
{
	T_MSG msg;
	char  text[32];
} T_PRINT_MSG;


/** %jp{初期化ハンドラ} */
void Sample_Initialize(VP_INT exinf)
{
	T_CMPF cmpf;
	T_CMBX cmbx;
	
	/* %jp{UART初期化} */
	Uart_Initialize();
	
	/* %jp{固定長メモリプール生成} */
	cmpf.mpfatr = TA_TFIFO;					
	cmpf.blkcnt = 3;						
	cmpf.blksz  = sizeof(T_PRINT_MSG);		
	cmpf.mpf    = NULL;						
	mpfid = acre_mpf(&cmpf);

	/* %jp{メールボックス生成} */
	cmbx.mbxatr  = TA_TFIFO | TA_TFIFO;		
	cmbx.maxmpri = 1;						
	cmbx.mprihd  = NULL;					
	mbxid = acre_mbx(&cmbx);

	/* %jp{タスク起動} */
	act_tsk(TSKID_PRINT);
	act_tsk(TSKID_SAMPLE1);
	act_tsk(TSKID_SAMPLE2);
	act_tsk(TSKID_SAMPLE3);
	act_tsk(TSKID_SAMPLE4);
	act_tsk(TSKID_SAMPLE5);
}


/** %jp{適当な時間待つ} */
void rand_wait(void)
{
	int r;

	wai_sem(SEMID_RAND);
	r = rand();
	sig_sem(SEMID_RAND);

	dly_tsk((r % 1000) + 10);
}


/** %jp{状態表示} */
void print_state(int num, char *text)
{
	T_PRINT_MSG *msg;
	VP  mem;
	
	/* %jp{メモリ取得} */
	get_mpf(mpfid, &mem);
	msg = (T_PRINT_MSG *)mem;

	/* %jp{文字列生成} */
	msg->text[0] = '0' + num;
	msg->text[1] = ' ';
	msg->text[2] = ':';
	msg->text[3] = ' ';
	strcpy(&msg->text[4], text);
	strcat(msg->text, "\n");
	
	/* %jp{表示タスクに送信} */
	snd_mbx(mbxid, (T_MSG *)msg);
}


/** %jp{サンプルタスク} */
void Sample_Task(VP_INT exinf)
{
	int num;
	
	num = (int)exinf;
	
	/* %jp{いわゆる哲学者の食事の問題} */
	for ( ; ; )
	{
		/* %jp{適当な時間考える} */
		print_state(num, "thinking");
		rand_wait();
		
		/* %jp{左右のフォークを取るまでループ} */
		for ( ; ; )
		{
			/* %jp{左から順に取る} */
			wai_sem(LEFT(num));
			if ( pol_sem(RIGHT(num)) == E_OK )
			{
				break;	/* %jp{両方取れた} */
			}
			sig_sem(LEFT(num));	/* %jp{取れなければ離す} */
			
			/* %jp{適当な時間待つ} */
			print_state(num, "hungry");
			rand_wait();

			/* %jp{右から順に取る} */
			wai_sem(RIGHT(num));
			if ( pol_sem(LEFT(num)) == E_OK )
			{
				break;	/* %jp{両方取れた} */
			}
			sig_sem(RIGHT(num));	/* %jp{取れなければ離す} */

			/* %jp{適当な時間待つ} */
			print_state(num, "hungry");
			rand_wait();
		}
		
		/* %jp{適当な時間、食べる} */
		print_state(num, "eating");
		rand_wait();
		
		/* %jp{フォークを置く} */
		sig_sem(LEFT(num));
		sig_sem(RIGHT(num));
	}
}


/** %jp{表示タスク} */
void Sample_Print(VP_INT exinf)
{
	T_PRINT_MSG *msg;
	
	for ( ; ; )
	{
		rcv_mbx(mbxid, (T_MSG **)&msg);
		Uart_PutString(msg->text);
		rel_mpf(mpfid, msg);
	}
}



/* end of file */
