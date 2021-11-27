#![allow(dead_code)]

use super::*;
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
const OPCODE_DLY_TSK: usize = 0x18;
const OPCODE_SIG_SEM: usize = 0x21;
const OPCODE_WAI_SEM: usize = 0x22;
const OPCODE_POL_SEM: usize = 0x23;
const OPCODE_SET_FLG: usize = 0x31;
const OPCODE_CLR_FLG: usize = 0x32;
const OPCODE_WAI_FLG_AND: usize = 0x33;
const OPCODE_WAI_FLG_OR: usize = 0x34;

const SYS_CFG_CORE_ID: usize = 0x00;
const SYS_CFG_VERSION: usize = 0x01;
const SYS_CFG_DATE: usize = 0x04;
const SYS_CFG_TASKS: usize = 0x20;
const SYS_CFG_SEMAPHORES: usize = 0x21;
const SYS_CFG_TSKPRI_WIDTH: usize = 0x30;
const SYS_CFG_SEMCNT_WIDTH: usize = 0x31;
const SYS_CFG_FLGPTN_WIDTH: usize = 0x32;
const SYS_CFG_SYSTIM_WIDTH: usize = 0x34;
const SYS_CFG_RELTIM_WIDTH: usize = 0x35;
const SYS_CFG_SOFT_RESET: usize = 0xff;

const CPU_CTL_TOP_TSKID: usize = 0x00;
const CPU_CTL_TOP_VALID: usize = 0x01;
const CPU_CTL_RUN_TSKID: usize = 0x04;
const CPU_CTL_RUN_VALID: usize = 0x05;
//const CPU_CTL_IDLE_TSKID: usize = 0x7;
const CPU_CTL_COPY_TSKID: usize = 0x8;
const CPU_CTL_IRQ_EN: usize = 0x10;
const CPU_CTL_IRQ_STS: usize = 0x11;
const CPU_CTL_IRQ_FORCE: usize = 0x1f;
const CPU_CTL_SCRATCH0: usize = 0xe0;
const CPU_CTL_SCRATCH1: usize = 0xe1;
const CPU_CTL_SCRATCH2: usize = 0xe2;
const CPU_CTL_SCRATCH3: usize = 0xe3;


#[no_mangle]
pub static JELLY_RTOS_CORE_BASE: usize = 0x80000000;
#[no_mangle]
pub static mut JELLY_RTOS_RUN_TSKID: usize = 15;
#[no_mangle]
pub static mut JELLY_RTOS_SP_TABLE: [usize; 16] = [0; 16];

fn make_addr(opcode: usize, id: usize) -> usize {
    JELLY_RTOS_CORE_BASE + 4 * ((opcode << DECODE_OPCODE_POS) | (id << DECODE_ID_POS))
}

unsafe fn write_reg(opcode: usize, id: usize, val: u32) {
    let addr = make_addr(opcode, id);
//    println!("[write] 0x{:08x} <= 0x{:08x}", addr, val);
//    wait(10000);
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
            if sns_dpn() { cpu::svc0(); }
            cpu::irq_enable();
        }
    }
}


// 初期化
pub fn initialize() {
    unsafe {
        // ソフトリセット
        write_reg(OPCODE_SYS_CFG, SYS_CFG_SOFT_RESET, 1);
        
//        println!("TASKS : {}", read_reg(OPCODE_SYS_CFG, SYS_CFG_TASKS));

        // カレントタスク設定
//      write_reg(OPCODE_CPU_CTL, CPU_CTL_RUN_TSKID, 15);
//      write_reg(OPCODE_WUP_TSK, 15, 15);
        write_reg(OPCODE_CPU_CTL, CPU_CTL_IRQ_EN, 1);

        cpu::irq_enable();
    }
}



pub fn cre_tsk(tskid: usize, stack: &mut [u8], entry: extern "C" fn() -> !) {
    let mut isp = (&mut stack[0] as *mut u8 as usize) + stack.len();
    isp &= !0x0f_usize; // align
    unsafe {
//        println!("[entry] task{} : 0x{:08x}", tskid, entry as usize);
//        println!("[isp] task{} : 0x{:08x}", tskid, isp);
        JELLY_RTOS_SP_TABLE[tskid] = jelly_create_context(isp as usize, entry);
//        println!("[sp] task{} : 0x{:08x}", tskid, JELLY_RTOS_SP_TABLE[tskid]);
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
    unsafe {
        read_reg(OPCODE_POL_SEM, semid as usize) != 0
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


pub fn sns_dpn() -> bool
{
    unsafe {
        read_reg(OPCODE_CPU_CTL, CPU_CTL_IRQ_STS) != 0
    }
}


