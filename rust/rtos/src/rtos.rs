#![allow(dead_code)]

use core::ptr;
use pudding_pac::arm::cpu;

const ID_WIDTH: usize = 8;
const OPCODE_WIDTH: usize = 8;
const DECODE_ID_POS: usize = 0;
const DECODE_OPCODE_POS: usize = DECODE_ID_POS + ID_WIDTH;

const OPCODE_SYS_CFG: usize = 0x00;
const OPCODE_CPU_CTL: usize = 0x01;
const OPCODE_WUP_TSK: usize = 0x10;
const OPCODE_SLP_TSK: usize = 0x11;
const OPCODE_RSM_TSK: usize = 0x14;
const OPCODE_SUS_TSK: usize = 0x15;
const OPCODE_DLY_TSK: usize = 0x18;
const OPCODE_CHG_PRI: usize = 0x1c;
const OPCODE_SET_TMO: usize = 0x1f;
const OPCODE_REF_TSKSTAT: usize = 0x90;
const OPCODE_REF_TSKWAIT: usize = 0x91;
const OPCODE_REF_WUPCNT: usize = 0x92;
const OPCODE_REF_SUSCNT: usize = 0x93;
const OPCODE_REF_TIMCNT: usize = 0x94;
const OPCODE_REF_ERR: usize = 0x98;
const OPCODE_GET_PRI: usize = 0x9c;
const OPCODE_SIG_SEM: usize = 0x21;
const OPCODE_WAI_SEM: usize = 0x22;
const OPCODE_POL_SEM: usize = 0x23;
const OPCODE_REF_SEMCNT: usize = 0xa0;
const OPCODE_REF_SEMQUE: usize = 0xa1;
const OPCODE_SET_FLG: usize = 0x31;
const OPCODE_CLR_FLG: usize = 0x32;
const OPCODE_WAI_FLG_AND: usize = 0x33;
const OPCODE_WAI_FLG_OR: usize = 0x34;
const OPCODE_ENA_FLG_EXT: usize = 0x3a;
const OPCODE_REF_FLGPTN: usize = 0xb0;
const OPCODE_SET_TIM: usize = 0x70;
const OPCODE_SET_PSCL: usize = 0x72;
const OPCODE_GET_TIM: usize = 0xf0;
const OPCODE_SYSTIM_LO: usize = 0xf2;
const OPCODE_SYSTIM_HI: usize = 0xf3;

const SYS_CFG_CORE_ID: usize = 0x00;
const SYS_CFG_VERSION: usize = 0x01;
const SYS_CFG_DATE: usize = 0x04;
const SYS_CFG_CLOCK_RATE: usize = 0x07;
const SYS_CFG_TMAX_TSKID: usize = 0x20;
const SYS_CFG_TMAX_SEMID: usize = 0x21;
const SYS_CFG_TSKPRI_WIDTH: usize = 0x30;
const SYS_CFG_SEMCNT_WIDTH: usize = 0x31;
const SYS_CFG_FLGPTN_WIDTH: usize = 0x32;
const SYS_CFG_SYSTIM_WIDTH: usize = 0x34;
const SYS_CFG_RELTIM_WIDTH: usize = 0x35;
const SYS_CFG_SOFT_RESET: usize = 0xff;

const CPU_CTL_TOP_TSKID: usize = 0x00;
const CPU_CTL_RUN_TSKID: usize = 0x04;
const CPU_CTL_COPY_TSKID: usize = 0x08;
const CPU_CTL_IRQ_EN: usize = 0x10;
const CPU_CTL_IRQ_STS: usize = 0x11;
const CPU_CTL_IRQ_FORCE: usize = 0x1f;
const CPU_CTL_SCRATCH0: usize = 0xe0;
const CPU_CTL_SCRATCH1: usize = 0xe1;
const CPU_CTL_SCRATCH2: usize = 0xe2;
const CPU_CTL_SCRATCH3: usize = 0xe3;

const JELLY_RTOS_REG_SIZE: usize = if cfg!(feature = "reg64bit") { 8 } else { 4 };

#[no_mangle]
pub static mut JELLY_RTOS_CORE_BASE: usize = 0x80000000;
#[no_mangle]
pub static mut JELLY_RTOS_RUN_TSKID: usize = 0;
#[no_mangle]
pub static mut JELLY_RTOS_SP_TABLE: [usize; 16] = [0; 16];


fn make_addr(opcode: usize, id: usize) -> usize {
    unsafe {
        JELLY_RTOS_CORE_BASE
            + (JELLY_RTOS_REG_SIZE * ((opcode << DECODE_OPCODE_POS) | (id << DECODE_ID_POS)))
    }
}

unsafe fn write_reg(opcode: usize, id: usize, val: u32) {
    let addr = make_addr(opcode, id);
    ptr::write_volatile(addr as *mut u32, val);
}

unsafe fn read_reg(opcode: usize, id: usize) -> u32 {
    let addr = make_addr(opcode, id);
    ptr::read_volatile(addr as *mut u32)
}


extern "C" {
    fn jelly_create_context(isp: usize, entry: extern "C" fn() -> !) -> usize;
}

pub(crate) struct SystemCall {}

impl SystemCall {
    pub(crate) fn new() -> Self {
        unsafe {
            cpu::irq_disable();
            Self {}
        }
    }
}

impl Drop for SystemCall {
    fn drop(&mut self) {
        unsafe {
            if sns_dpn() {
                cpu::svc0();
            }
            cpu::irq_enable();
        }
    }
}

// 初期化
pub fn initialize(core_base: usize) {
    unsafe {
        // アドレス設定
        JELLY_RTOS_CORE_BASE = core_base;
        
        // ID確認
        assert!(read_reg(OPCODE_SYS_CFG, SYS_CFG_CORE_ID) == 0x834f5452);
        
        // ソフトリセット
        write_reg(OPCODE_SYS_CFG, SYS_CFG_SOFT_RESET, 1);

        // 割り込み許可
        write_reg(OPCODE_CPU_CTL, CPU_CTL_IRQ_EN, 1);
        cpu::irq_enable();
    }
}

pub fn cre_tsk(tskid: usize, stack: &mut [u8], entry: extern "C" fn() -> !) {
    let mut isp = (&mut stack[0] as *mut u8 as usize) + stack.len();
    isp &= !0x0f_usize; // align
    unsafe {
        JELLY_RTOS_SP_TABLE[tskid] = jelly_create_context(isp as usize, entry);
    }
}

pub fn wup_tsk(tskid: i32) {
    unsafe {
        let tskid: usize = if tskid < 0 {
            JELLY_RTOS_RUN_TSKID
        } else {
            tskid as usize
        };

        let _sc = SystemCall::new();
        write_reg(OPCODE_WUP_TSK, tskid, 0);
    }
}

pub fn slp_tsk(tskid: i32) {
    unsafe {
        let tskid: usize = if tskid < 0 {
            JELLY_RTOS_RUN_TSKID
        } else {
            tskid as usize
        };

        let _sc = SystemCall::new();
        write_reg(OPCODE_SLP_TSK, tskid, 0);
    }
}

pub fn dly_tsk(tskid: i32, dlytim: u32) {
    unsafe {
        let tskid: usize = if tskid < 0 {
            JELLY_RTOS_RUN_TSKID
        } else {
            tskid as usize
        };

        let _sc = SystemCall::new();
        write_reg(OPCODE_DLY_TSK, tskid, dlytim);
    }
}

pub fn sig_sem(semid: i32) {
    unsafe {
        let _sc = SystemCall::new();
        write_reg(OPCODE_SIG_SEM, semid as usize, 0);
    }
}

pub fn wai_sem(semid: i32) {
    unsafe {
        let _sc = SystemCall::new();
        write_reg(OPCODE_WAI_SEM, semid as usize, 0);
    }
}

pub fn pol_sem(semid: i32) -> bool {
    unsafe { read_reg(OPCODE_POL_SEM, semid as usize) != 0 }
}


pub fn ena_extflg(flgptn: u32) {
    unsafe {
        let _sc = SystemCall::new();
        write_reg(OPCODE_ENA_FLG_EXT, 0, flgptn);
    }
}

pub fn set_flg(flgptn: u32) {
    unsafe {
        let _sc = SystemCall::new();
        write_reg(OPCODE_SET_FLG, 0, flgptn);
    }
}

pub fn clr_flg(flgptn: u32) {
    unsafe {
        let _sc = SystemCall::new();
        write_reg(OPCODE_CLR_FLG, 0, flgptn);
    }
}

pub enum WfMode {
    AndWait = 0,
    OrWait = 1,
}

pub fn wai_flg(waiptn: u32, wfmode: WfMode) {
    unsafe {
        let tskid: usize = JELLY_RTOS_RUN_TSKID;

        let _sc = SystemCall::new();
        match wfmode {
            WfMode::AndWait => write_reg(OPCODE_WAI_FLG_AND, tskid as usize, waiptn),
            WfMode::OrWait => write_reg(OPCODE_WAI_FLG_OR, tskid as usize, waiptn),
        }
    }
}

pub fn loc_cpu() {
    unsafe {
        cpu::irq_disable();
    }
}

pub fn unl_cpu() {
    unsafe {
        let _sc = SystemCall::new();
        cpu::irq_disable();
    }
}

pub fn sns_dpn() -> bool {
    unsafe { read_reg(OPCODE_CPU_CTL, CPU_CTL_IRQ_STS) != 0 }
}



pub fn set_scratch(id : usize, data: u32) {
    unsafe {
        match id {
        0 => write_reg(OPCODE_CPU_CTL, CPU_CTL_SCRATCH0, data),
        1 => write_reg(OPCODE_CPU_CTL, CPU_CTL_SCRATCH1, data),
        2 => write_reg(OPCODE_CPU_CTL, CPU_CTL_SCRATCH2, data),
        3 => write_reg(OPCODE_CPU_CTL, CPU_CTL_SCRATCH3, data),
        _ => {},
        }
    }
}