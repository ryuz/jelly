#![allow(dead_code)]

use jelly_mem_access::*;

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


pub trait I2cAccess {
    fn write(&self, dev_adr:u8, data: &[u8]) -> usize;
    fn read(&self, dev_adr:u8, buf: &mut [u8]) -> usize;
}


pub struct JellyI2c<T: MemAccess>
{
    reg_acc: T,
    wait_irq: Option<fn()>,
}


impl<T: MemAccess> JellyI2c<T> {
    pub const fn new(reg_acc: T, wait_irq: Option<fn()>) -> Self
    {
        Self {reg_acc: reg_acc, wait_irq:wait_irq}
    }

    fn wait(&self) {
        while (unsafe{self.reg_acc.read_reg(REG_I2C_STATUS)} & 1) != 0 {
            if let Some(wait_fn) = self.wait_irq {
                wait_fn();
            }
        }
    }

    pub fn set_divider(&self, div: u16)
    {
        unsafe {
            self.reg_acc.write_reg16(REG_I2C_DIVIDER, div);
        }
    }


    pub fn putc(&self, dev_adr:u8, data: u8) -> bool
    {
        unsafe {
            // start
            self.reg_acc.write_reg8(REG_I2C_CONTROL, I2C_CONTROL_START);
            self.wait();
            
            // send
            self.reg_acc.write_reg8(REG_I2C_SEND, dev_adr<<1);
            self.wait();

            // ack check
            if (self.reg_acc.read_reg8(REG_I2C_STATUS) & 0xf) != 0 {
                return false;
            }

            // send
            self.reg_acc.write_reg8(REG_I2C_SEND, data);
            self.wait();

            // stop
            self.reg_acc.write_reg8(REG_I2C_CONTROL, I2C_CONTROL_STOP);
            self.wait();
        }
        true
    }

    pub fn getc(&self, dev_adr:u8) -> u8
    {
        unsafe {
            // start
            self.reg_acc.write_reg8(REG_I2C_CONTROL, I2C_CONTROL_START);
            self.wait();
        
            // send
            self.reg_acc.write_reg8(REG_I2C_SEND, dev_adr<<1|1);
            self.wait();

            if (self.reg_acc.read_reg8(REG_I2C_STATUS) & 0xf) != 0 {
                return 0;
            }

            // read
            self.reg_acc.write_reg8(REG_I2C_CONTROL, I2C_CONTROL_RECV);
            self.wait();
            let data = self.reg_acc.read_reg8(REG_I2C_RECV);
            
            self.reg_acc.write_reg8(REG_I2C_CONTROL, I2C_CONTROL_NAK);
            self.wait();

            data
        }
    }
}


impl<T: MemAccess> I2cAccess for JellyI2c<T> {
    fn write(&self, dev_adr:u8, data: &[u8]) -> usize
    {
        let mut len:usize = 0;

        unsafe {
            // start
            self.reg_acc.write_reg8(REG_I2C_CONTROL, I2C_CONTROL_START);
            self.wait();
            
            // send
            self.reg_acc.write_reg8(REG_I2C_SEND, dev_adr<<1);
            self.wait();

            for p in data.iter() {
                // ack check
                if (self.reg_acc.read_reg(REG_I2C_STATUS) & 0xf) != 0 {
                    break;
                }

                // send
                self.reg_acc.write_reg8(REG_I2C_SEND, *p);
                self.wait();

                len += 1;
            }

            // stop
            self.reg_acc.write_reg8(REG_I2C_CONTROL, I2C_CONTROL_STOP);
            self.wait();
        }
        len
    }

    fn read(&self, dev_adr:u8, buf: &mut [u8]) -> usize
    {
        let mut len:usize = 0;

        unsafe {
            // start
            self.reg_acc.write_reg8(REG_I2C_CONTROL, I2C_CONTROL_START);
            self.wait();
        
            // send
            self.reg_acc.write_reg8(REG_I2C_SEND, dev_adr<<1|1);
            self.wait();
            
            let last = buf.len() - 1;
            for c in buf.iter_mut() {
                if (self.reg_acc.read_reg8(REG_I2C_STATUS) & 0xf) != 0 {
                    break;
                }
                
                // read
                self.reg_acc.write_reg8(REG_I2C_CONTROL, I2C_CONTROL_RECV);
                self.wait();
                *c = self.reg_acc.read_reg8(REG_I2C_RECV);
                
                self.reg_acc.write_reg8(REG_I2C_CONTROL, if len == last {I2C_CONTROL_NAK} else {I2C_CONTROL_ACK});
                self.wait();

                len += 1;
            }
        }
        len
    }
}