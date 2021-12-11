#![allow(dead_code)]

use jelly_mem_access::*;
use jelly_rtos::*;

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


pub struct JellyCommunicationPipe<T: MemAccess, const FI: ID, const FP: FLGPTN> {
    reg_acc: T,
}

impl <T: MemAccess, const FI: ID, const FP: FLGPTN> JellyCommunicationPipe<T, FI, FP>
{
    pub const fn new( reg_acc: T ) -> Self
    {
        Self { reg_acc: reg_acc }
    }

    fn wait_tx(&self) {
        unsafe {
            clr_flg(FI, !FP);
            self.reg_acc.write_reg(REG_TX_IRQ_ENABLE, 1);
            wai_flg(FI, FP, WfMode::AndWait);
            self.reg_acc.write_reg(REG_TX_IRQ_ENABLE, 0);
        }
    }

    fn wait_rx(&self) {
        unsafe {
            clr_flg(FI, !FP);
            self.reg_acc.write_reg(REG_RX_IRQ_ENABLE, 1);
            wai_flg(FI, FP, WfMode::AndWait);
            self.reg_acc.write_reg(REG_RX_IRQ_ENABLE, 0);
        }
    }

    pub fn putc(&mut self, c: u8) {
        unsafe {
            while self.reg_acc.read_reg8(REG_TX_STATUS) == 0 {
                self.wait_tx();
            }
            
            self.reg_acc.write_reg8(REG_TX_DATA, c);
        }
    }

    pub fn getc(&mut self) -> u8 {
        unsafe {
            while self.reg_acc.read_reg8(REG_RX_STATUS) == 0 {
                self.wait_rx();
            }
            
            self.reg_acc.read_reg8(REG_RX_DATA)
        }
    }
}

