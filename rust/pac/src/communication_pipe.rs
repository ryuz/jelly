#![allow(dead_code)]

use jelly_mem_access::*;


const REG_CORE_ID      :usize = 0x00;
const REG_CORE_VERSION :usize = 0x01;
const REG_CORE_DATE    :usize = 0x02;
const REG_CORE_SERIAL  :usize = 0x03;
const REG_TX_DATA      :usize = 0x10;
const REG_TX_STATUS    :usize = 0x11;
const REG_TX_FREE_COUNT:usize = 0x12;
const REG_TX_IRQ_STATUS:usize = 0x14;
const REG_TX_IRQ_ENABLE:usize = 0x15;
const REG_RX_DATA      :usize = 0x18;
const REG_RX_STATUS    :usize = 0x19;
const REG_RX_FREE_COUNT:usize = 0x1a;
const REG_RX_IRQ_STATUS:usize = 0x1c;
const REG_RX_IRQ_ENABLE:usize = 0x1d;


pub trait PipeSend {
    fn polling_tx(&self) -> bool;
    fn putc(&self, c: u8);
    fn write(&self, data: &[u8]);
}

pub trait PipeRecv {
    fn polling_rx(&self) -> bool;
    fn getc(&self) -> u8;
    fn read(&self, buf: &mut [u8]);
}

pub struct JellyCommunicationPipe<T: MemAccess> {
    reg_acc: T,
    wait_irq: Option<fn()>,
}

impl <T: MemAccess> JellyCommunicationPipe<T>
{
    pub const fn new( reg_acc: T, wait_irq: Option<fn()>) -> Self
    {
        Self { reg_acc: reg_acc, wait_irq: wait_irq }
    }

    unsafe fn set_tx_irq_enable(&self, enable : bool) {
        self.reg_acc.write_reg(REG_TX_IRQ_ENABLE, if enable {1} else {0});
    }

    unsafe fn set_rx_irq_enable(&self, enable : bool) {
        self.reg_acc.write_reg(REG_RX_IRQ_ENABLE, if enable {1} else {0});
    }

    fn wait_tx(&self) {
        while !self.polling_tx() {
            unsafe{ self.set_tx_irq_enable(true); }
            match self.wait_irq {
                    Some(callback) => callback(),
                _ => (),
            }
            unsafe{ self.set_tx_irq_enable(false); }
        }
    }

    fn wait_rx(&self) {
        while !self.polling_rx() {
            unsafe{ self.set_rx_irq_enable(true); }
            match self.wait_irq {
                    Some(callback) => callback(),
                _ => (),
            }
            unsafe{ self.set_rx_irq_enable(false); }
        }
    }
}


impl<T: MemAccess> PipeSend for JellyCommunicationPipe<T>
{
    fn polling_tx(&self) -> bool{
        unsafe { self.reg_acc.read_reg8(REG_TX_STATUS) != 0 }
    }

    fn putc(&self, c: u8) {
        self.wait_tx();
        unsafe { self.reg_acc.write_reg8(REG_TX_DATA, c); }
    }

    fn write(&self, data: &[u8]) {
        for c in data.iter() {
            self.putc(*c);
        }
    }
}

impl<T: MemAccess> PipeRecv for JellyCommunicationPipe<T>
{

    fn polling_rx(&self) -> bool{
        unsafe { self.reg_acc.read_reg8(REG_RX_STATUS) != 0 }
    }

    fn getc(&self) -> u8 {
        self.wait_rx();
        unsafe { self.reg_acc.read_reg8(REG_RX_DATA) }
    }

    fn read(&self, buf: &mut [u8]) {
        for c in buf.iter_mut() {
            *c = self.getc();
        }
    }
}



use delegate::delegate;

pub struct CommunicationPort<TX: PipeSend, RX: PipeRecv> {
    pipe_tx: TX,
    pipe_rx: RX,
}

impl<TX: PipeSend, RX: PipeRecv> CommunicationPort<TX, RX> {
    pub const fn new(pipe_tx: TX, pipe_rx: RX) -> Self {
        Self { pipe_tx: pipe_tx, pipe_rx: pipe_rx }
    }
}

impl<TX: PipeSend, RX: PipeRecv> PipeSend for CommunicationPort<TX, RX> {
    delegate! {
        to self.pipe_tx {
            fn polling_tx(&self) -> bool;
            fn putc(&self, c: u8);
            fn write(&self, data: &[u8]);
        }
    }
}

impl<TX: PipeSend, RX: PipeRecv> PipeRecv for CommunicationPort<TX, RX> {
    delegate! {
        to self.pipe_rx {
            fn polling_rx(&self) -> bool;
            fn getc(&self) -> u8;
            fn read(&self, buf: &mut [u8]);
        }
    }
}

