#![allow(dead_code)]

use core::ptr;

const ID_WIDTH          : usize = 8;
const OPCODE_WIDTH      : usize = 8;
const DECODE_ID_POS     : usize = 0;
const DECODE_OPCODE_POS : usize = DECODE_ID_POS + ID_WIDTH;

const OPCODE_REF_CFG    : usize = 0x00;
const OPCODE_CPU_CTL    : usize = 0x01;
const OPCODE_WUP_TSK    : usize = 0x10;
const OPCODE_SLP_TSK    : usize = 0x11;
const OPCODE_DLY_TSK    : usize = 0x18;
const OPCODE_SIG_SEM    : usize = 0x21;
const OPCODE_WAI_SEM    : usize = 0x22;
const OPCODE_SET_FLG    : usize = 0x31;
const OPCODE_CLR_FLG    : usize = 0x32;
const OPCODE_WAI_FLG_AND: usize = 0x33;
const OPCODE_WAI_FLG_OR : usize = 0x34;

const REF_CFG_CORE_ID   : usize = 0x00;
const REF_CFG_VERSION   : usize = 0x01;
const REF_CFG_DATE      : usize = 0x04;
const CPU_CTL_TOP_TSKID : usize = 0x00;
const CPU_CTL_TOP_VALID : usize = 0x01;
const CPU_CTL_RUN_TSKID : usize = 0x04;
const CPU_CTL_RUN_VALID : usize = 0x05;
const CPU_CTL_IRQ_EN    : usize = 0x10;
const CPU_CTL_IRQ_STS   : usize = 0x11;
const CPU_CTL_IRQ_FORCE : usize = 0x1f;


#[no_mangle]
pub static JELLY_RTOS_CORE_BASE: usize = 0x80000000;
#[no_mangle]
pub static mut JELLY_RTOS_RUN_TSKID: usize = 15;
#[no_mangle]
pub static mut JELLY_RTOS_SP_TABLE: [usize; 16] = [0; 16];


fn make_addr(opcode: usize, id: usize) -> usize {
    JELLY_RTOS_CORE_BASE + 4*((opcode << DECODE_ID_POS) | (id << DECODE_ID_POS))
}

unsafe fn write_reg(opcode: usize, id: usize, val: u32) {
    ptr::write_volatile(make_addr(opcode, id) as *mut u32, val);
}

unsafe fn read_reg(opcode: usize, id: usize) -> u32 {
    ptr::read_volatile(make_addr(opcode, id) as *mut u32)
}


extern "C" {
    fn  jelly_create_context(isp:usize, entry: extern "C" fn() -> !) -> usize;
}

pub fn initialize() {
    unsafe {
        write_reg(OPCODE_CPU_CTL, CPU_CTL_RUN_TSKID, 15);
    }
}


pub fn cre_tsk(
    tskid: usize,
    stack: &mut [u8],
    entry: extern "C" fn() -> !,
) {
    let mut isp = (&mut stack[0] as *mut u8 as usize) + stack.len();
    isp = isp & !0x1f_usize;
    unsafe {
        JELLY_RTOS_SP_TABLE[tskid] = jelly_create_context(isp as usize, entry);
    }
}

pub fn wup_tsk(tskid: i32) {
    unsafe {
        let tskid: usize = if tskid < 0 {JELLY_RTOS_RUN_TSKID} else {tskid as usize};
        write_reg(OPCODE_WUP_TSK, tskid, 0);
    }
}

pub fn slp_tsk(tskid: i32) {
    unsafe {
        let tskid: usize = if tskid < 0 {JELLY_RTOS_RUN_TSKID} else {tskid as usize};
        write_reg(OPCODE_SLP_TSK, tskid, 0);
    }
}

