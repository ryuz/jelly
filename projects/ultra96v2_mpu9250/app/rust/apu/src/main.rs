#![allow(dead_code)]

use std::{thread, time};
use nix::sys::signal;
use nix::sys::signal::*;
use jelly_mem_access::*;


const REG_COMMUNICATION_PIPE_CORE_ID      : usize = 0x00;
const REG_COMMUNICATION_PIPE_CORE_VERSION : usize = 0x01;
const REG_COMMUNICATION_PIPE_CORE_DATE    : usize = 0x02;
const REG_COMMUNICATION_PIPE_CORE_SERIAL  : usize = 0x03;
const REG_COMMUNICATION_PIPE_TX_DATA      : usize = 0x10;
const REG_COMMUNICATION_PIPE_TX_STATUS    : usize = 0x11;
const REG_COMMUNICATION_PIPE_TX_FREE_COUNT: usize = 0x12;
const REG_COMMUNICATION_PIPE_TX_IRQ_STATUS: usize = 0x14;
const REG_COMMUNICATION_PIPE_TX_IRQ_ENABLE: usize = 0x15;
const REG_COMMUNICATION_PIPE_RX_DATA      : usize = 0x18;
const REG_COMMUNICATION_PIPE_RX_STATUS    : usize = 0x19;
const REG_COMMUNICATION_PIPE_RX_FREE_COUNT: usize = 0x1a;
const REG_COMMUNICATION_PIPE_RX_IRQ_STATUS: usize = 0x1c;
const REG_COMMUNICATION_PIPE_RX_IRQ_ENABLE: usize = 0x1d;

static mut END_FLAG: bool = false;

extern "C" fn handle_signal(signum: i32) {
    println!("handler. signal={}", signum);
    unsafe {
        std::ptr::write_volatile(&mut END_FLAG, true);
    }
}


fn main() {
    let sa = SigAction::new(SigHandler::Handler(handle_signal), SaFlags::SA_RESETHAND, SigSet::empty());
    unsafe { sigaction(signal::SIGINT, &sa) }.unwrap();

    let com0_rx_acc = UioAccessor::<u64>::new_from_name("uio_pl_com0").unwrap();

    while unsafe{!std::ptr::read_volatile(&END_FLAG)} {
        // RX
        if unsafe{com0_rx_acc.read_reg(REG_COMMUNICATION_PIPE_RX_STATUS)} != 0 {
            let c: char = unsafe{com0_rx_acc.read_reg8(REG_COMMUNICATION_PIPE_RX_DATA)} as char;
            print!("{}", c);
        }

        thread::sleep(time::Duration::from_millis(1));
    }
}
