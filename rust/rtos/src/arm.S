// ---------------------------------------------------------------------------
//  Jelly-RTOS ARMv7-R
//
//                                          Copyright (C) 1998-2023 by Ryuji Fuchikami
// ---------------------------------------------------------------------------


#define Mode_USR        0x10
#define Mode_FIQ        0x11
#define Mode_IRQ        0x12
#define Mode_SVC        0x13
#define Mode_MON        0x16
#define Mode_ABT        0x17
#define Mode_HYP        0x1a
#define Mode_UND        0x1b
#define Mode_SYS        0x1f

#define I_Bit           0x80
#define F_Bit           0x40
#define T_Bit           0x20

#define TOP_TSKID       (0x00100 * (_RTOS_REG_SIZE))
#define RUN_TSKID       (0x00104 * (_RTOS_REG_SIZE))
#define COPY_TSKID      (0x00108 * (_RTOS_REG_SIZE))


                .extern JELLY_RTOS_CORE_BASE
                .extern JELLY_RTOS_RUN_TSKID
                .extern JELLY_RTOS_SP_TABLE


                .text

// =================================================
//  コンテキストの作成
//  jelly_create_context(
//            isp:usize     r0 スタックポインタ
//            entry:fn      r1 実行アドレス
//        ) -> usize        r0 新しいスタックポインタ
// =================================================
                .global	jelly_create_context
                .code	32
                .func
                .type	jelly_create_context, %function
jelly_create_context:
                sub		r0, #(16*4)         // スタックを確保
                str		r1, [r0, #(15*4)]   // lr 部分にentryを設定
                mov     r1, #(Mode_SYS)     // spsr
                str		r1, [r0, #(1*4)]    // spsr 部分を設定
#ifdef _WITH_VFP    // VFP利用時
                sub		r0, #(2*4 + 16*8)
                mov     r1, #0x40000000     // fpexc の EN ビットセット
                str		r1, [r0, #(0*4)]    // spsr 部分を設定
#endif
                bx		lr                  // リターン


// =================================================
//  SVCハンドラ
//  タスクスイッチを行う(r13_svc を作業用に使う)
// =================================================
                .global jelly_svc_handler
                .align  4
                .code   32
jelly_svc_handler:
                // コンテキスト退避
                mov     r13, r0
                msr     cpsr_c, #(Mode_SYS | I_Bit)
                mov     r0, r13
                msr     cpsr_c, #(Mode_SVC | I_Bit)
                stmfd	r0!, {r1-r14}
                msr     cpsr_c, #(Mode_SYS | I_Bit)
                mov     r1, r14
                msr     cpsr_c, #(Mode_SVC | I_Bit)

context_switch: mrs     r2, spsr
                stmfd   r0!, {r1, r2}

#ifdef _WITH_VFP    // VFP利用時
                mov     sp, r0
                vpush   {d0-d15}    // VFP用レジスタ退避
                vmrs    r1, fpscr   // fpscr 取り出し
                push    {r1}        // fpscr 退避
                vmrs    r1, fpexc   // fpexc 取り出し
                push    {r1}        // fpexc 退避
                mov     r0, sp
#endif


                // 実行中タスクID取得
                ldr     r1, =JELLY_RTOS_RUN_TSKID
                ldr     r4, [r1]

                // スタック退避
                ldr     r2, =JELLY_RTOS_SP_TABLE
                str     r0, [r2, r4, lsl #2]
                
                // キューの先頭タスク取得
                ldr     r3, =JELLY_RTOS_CORE_BASE
                ldr     r3, [r3]
                ldr     r4, [r3, #COPY_TSKID]
                str     r4, [r1]

                // スタック復帰
                ldr     r0, [r2, r4, lsl #2]

                // コンテキスト復帰
#ifdef _WITH_VFP    // VFP利用時
                mov     sp, r0
                pop 	{r1}        // fpexc 復帰
                vmsr    fpexc, r1   // fpexc 設定
                pop 	{r1}        // fpscr 復帰
                vmsr    fpscr, r1   // fpscr 設定
                vpop    {d0-d15}    // VFP用レジスタ復帰
                mov     r0, sp
#endif
                ldmfd	r0!, {r1-r2}
                msr     spsr, r2
                msr     cpsr_c, #(Mode_SYS | I_Bit)
                mov     r14, r1
                msr     cpsr_c, #(Mode_SVC | I_Bit)
                ldmfd	r0!, {r1-r14}
                msr     cpsr_c, #(Mode_SYS | I_Bit)
                mov     r13, r0
                msr     cpsr_c, #(Mode_SVC | I_Bit)
                mov     r0, r13
                movs	pc, lr


// =================================================
//  IRQハンドラ
//  タスクスイッチを行う(r13_irq を作業用に使う)
// =================================================
                .global jelly_irq_handler
                .align  4
                .code   32
jelly_irq_handler:
                // アドレス補正
                subs	lr, lr, #4

                // コンテキスト退避
                mov     r13, r0
                msr     cpsr_c, #(Mode_SYS | I_Bit)
                mov     r0, r13
                msr     cpsr_c, #(Mode_IRQ | I_Bit)
                stmfd	r0!, {r1-r14}
                msr     cpsr_c, #(Mode_SYS | I_Bit)
                mov     r1, r14
                msr     cpsr_c, #(Mode_IRQ | I_Bit)
                b       context_switch


                .end


// end of file
