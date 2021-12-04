#![allow(dead_code)]

use core::ptr;

const REG_I2C_STATUS    : usize = 0x00;
const REG_I2C_CONTROL   : usize = 0x01;
const REG_I2C_SEND      : usize = 0x02;
const REG_I2C_RECV      : usize = 0x03;
const REG_I2C_DIVIDER   : usize = 0x04;
const I2C_CONTROL_START : u8 = 0x01;
const I2C_CONTROL_STOP  : u8 = 0x02;
const I2C_CONTROL_ACK   : u8 = 0x04;
const I2C_CONTROL_NAK   : u8 = 0x08;
const I2C_CONTROL_RECV  : u8 = 0x10;


const REG_SIZE:usize = 8;

pub struct JellyI2c {
    base_addr: usize,
}


impl JellyI2c {
    pub const fn new(base_addr: usize) -> Self
    {
        JellyI2c {base_addr:base_addr}
    }

    unsafe fn write_reg(&self, reg_addr: usize, data: u8) {
        let addr = self.base_addr + REG_SIZE * reg_addr;
        ptr::write_volatile(addr as *mut u8, data);
    }

    unsafe fn write_reg16(&self, reg_addr: usize, data: u16) {
        let addr = self.base_addr + REG_SIZE * reg_addr;
        ptr::write_volatile(addr as *mut u16, data);
    }

    unsafe fn read_reg(&self, reg_addr: usize) -> u8 {
        let addr = self.base_addr + REG_SIZE * reg_addr;
        ptr::read_volatile(addr as *mut u8)
    }

    fn wait(&self) {
        unsafe {
            while ( self.read_reg(REG_I2C_STATUS) & 1) != 0 {}
        }
    }

    pub fn set_divider(&self, div: u16)
    {
        unsafe {
            self.write_reg16(REG_I2C_DIVIDER, div);
        }
    }

    pub fn write(&self, dev_adr:u8, data: &[u8]) -> bool
    {
        let mut nak: bool = false;

        unsafe {
            // start
            self.write_reg(REG_I2C_CONTROL, I2C_CONTROL_START);
            self.wait();
            
            // send
            self.write_reg(REG_I2C_SEND, dev_adr<<1);
            self.wait();

            for c in data.iter() {
                // ack check
                if (self.read_reg(REG_I2C_STATUS) & 0xf) != 0 {
                    nak = true;
                    break;
                }

                // send
                self.write_reg(REG_I2C_SEND, *c);
                self.wait();
            }

            // stop
            self.write_reg(REG_I2C_CONTROL, I2C_CONTROL_STOP);
            self.wait();
        }

        !nak
    }

}

