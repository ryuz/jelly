

//use jelly_lib::linux_i2c::LinuxI2c;
use std::error::Error;

use jelly_lib::{i2c_access::I2cAccess, linux_i2c::LinuxI2c};
//use jelly_mem_access::*;
//use jelly_pac::video_dma_control::VideoDmaControl;


pub struct RtclP3s7I2c {
    i2c: LinuxI2c,
}

impl RtclP3s7I2c {
    pub fn new(devname: &str) -> Result<Self, Box<dyn Error>> {
        Ok(RtclP3s7I2c {
            i2c: LinuxI2c::new(devname, 0x10)?,
        })
    }

    /// Write a 16-bit register on the Spartan-7
    pub fn write_s7_reg(&mut self, addr: u16, data: u16) -> Result<(), Box<dyn Error>> {
        let addr = (addr << 1) | 1;
        let buf: [u8; 4] = [
            ((addr >> 8) & 0xff) as u8,
            ((addr >> 0) & 0xff) as u8,
            ((data >> 8) & 0xff) as u8,
            ((data >> 0) & 0xff) as u8,
        ];
        self.i2c.write(&buf)?;
        Ok(())
    }

    /// Read a 16-bit register on the Spartan-7
    pub fn read_s7_reg(&mut self, addr: u16) -> Result<u16, Box<dyn Error>> {
        let addr = addr << 1;
        let wbuf: [u8; 4] = [((addr >> 8) & 0xff) as u8, ((addr >> 0) & 0xff) as u8, 0, 0];
        self.i2c.write(&wbuf)?;
        let mut rbuf: [u8; 2] = [0; 2];
        self.i2c.read(&mut rbuf)?;
        Ok(rbuf[0] as u16 | ((rbuf[1] as u16) << 8))
    }

    /// Write a 16-bit register on the PYTHON300 SPI
    pub fn write_p3_spi(&mut self, addr: u16, data: u16) -> Result<(), Box<dyn Error>> {
        let addr = addr | (1 << 14);
        self.write_s7_reg(addr, data)
    }

    /// Read a 16-bit register on the PYTHON300 SPI
    pub fn read_p3_spi(&mut self, addr: u16) -> Result<u16, Box<dyn Error>> {
        let addr = addr | (1 << 14);
        self.read_s7_reg(addr)
    }
}
