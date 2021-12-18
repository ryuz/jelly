#![allow(dead_code)]

use std::{thread, time};
use std::fs::File;
use std::io::{self, BufRead, Write, BufReader};
use nix::sys::signal;
use nix::sys::signal::*;
use jelly_mem_access::*;
use jelly_pac::communication_pipe::*;


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

    let pipe0_rx_acc = UioAccessor::<u64>::new_from_name("uio_pl_pipe0").unwrap().clone(0x0000, 0);
    let pipe1_tx_acc = UioAccessor::<u64>::new_from_name("uio_pl_pipe1").unwrap().clone(0x0800, 0);
    let pipe2_rx_acc = UioAccessor::<u64>::new_from_name("uio_pl_pipe2").unwrap().clone(0x1000, 0);
    let pipe3_tx_acc = UioAccessor::<u64>::new_from_name("uio_pl_pipe3").unwrap().clone(0x1800, 0);
    let pipe0_rx = CommunicationPipe::new(pipe0_rx_acc, None);
    let pipe1_tx = CommunicationPipe::new(pipe1_tx_acc, None);
    let pipe2_rx = CommunicationPipe::new(pipe2_rx_acc, None);
    let pipe3_tx = CommunicationPipe::new(pipe3_tx_acc, None);
    let com0 = CommunicationPort::new(pipe1_tx, pipe0_rx);
    let com1 = CommunicationPort::new(pipe3_tx, pipe2_rx);

    println!("start\n");
    
    let mut file = File::create("output.txt").unwrap();

    while unsafe{!std::ptr::read_volatile(&END_FLAG)} {
        // COM0 recv
        if com0.polling_rx() {
            print!("{}", com0.getc() as char);
        }

        // COM1 recv
        if com1.polling_rx() {
            let mut buf: [u8; 14] = [0; 14];
            com1.read(&mut buf);

            struct Mpu9250SensorData {
                pub accel: [i16; 3],
                pub gyro: [i16; 3],
                pub temperature: i16,
            }

            let data: Mpu9250SensorData = unsafe{std::mem::transmute(buf)};
            write!(file, "{}\n", data.accel[0]);
        }

        thread::sleep(time::Duration::from_millis(1));
    }

    com0.putc('q' as u8);
    println!("end\n");
    thread::sleep(time::Duration::from_millis(1000));
}
