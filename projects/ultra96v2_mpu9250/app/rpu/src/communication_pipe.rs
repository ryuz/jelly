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


pub struct JellyCommunicationPipe<T: MemRegion, BaseType> {
    reg_acc: MemAccesor<T, BaseType>
}

impl <T: MemRegion, BaseType> JellyCommunicationPipe<T, BaseType>
{
    pub const fn new( reg_acc: MemAccesor<T, BaseType> ) -> Self
    {
        Self { reg_acc: reg_acc }
    }

    pub fn putc(&self, c: u8) {
        unsafe {
            while self.reg_acc.read_reg8(REG_TX_STATUS) == 0 {}
            self.reg_acc.write_reg8(REG_TX_DATA, c);
        }
    }

    pub fn getc(&self) -> u8 {
        unsafe {
            while self.reg_acc.read_reg8(REG_RX_STATUS) == 0 {}
            self.reg_acc.read_reg8(REG_RX_DATA)
        }
    }
}

