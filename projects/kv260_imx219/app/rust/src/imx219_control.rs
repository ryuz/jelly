
#![allow(dead_code)]

use std::error::Error;

pub trait I2cAccess {
    fn write(&mut self, data: &[u8]) -> Result<(), Box<dyn Error>>;
    fn read(&mut self, buf: &mut [u8]) -> Result<(), Box<dyn Error>>;
}


pub struct Imx219Control {
    i2c: Box<dyn I2cAccess>,
}


impl Imx219Control {
    pub fn new(i2c: Box<dyn I2cAccess>) -> Self {
        Self { i2c }
    }

    pub fn i2c_write(&mut self, addr: u16, data: &[u8]) -> Result<(), Box<dyn Error>>
    {
        self.i2c.write(&(addr.to_be_bytes()))?;
        self.i2c.write(data)
    }

    pub fn i2c_read(&mut self, addr: u16, buf: &mut [u8]) -> Result<(), Box<dyn Error>>
    {
        self.i2c.write(&(addr.to_be_bytes()))?;
        self.i2c.read(buf)
    }

    pub fn i2c_write_u8(&mut self, addr: u16, data: u8) -> Result<(), Box<dyn Error>>
    {
        self.i2c.write(&(addr.to_be_bytes()))?;
        self.i2c.write(&(data.to_be_bytes()))
    }

    pub fn i2c_read_u8(&mut self, addr: u16) -> Result<u8, Box<dyn Error>>
    {
        self.i2c.write(&(addr.to_be_bytes()))?;
        let mut buf: [u8; 1] = [0; 1];
        self.i2c.read(&mut buf)?;
        Ok(u8::from_be_bytes(buf))
    }

    pub fn i2c_write_u16(&mut self, addr: u16, data: u16) -> Result<(), Box<dyn Error>>
    {
        self.i2c.write(&(addr.to_be_bytes()))?;
        self.i2c.write(&(data.to_be_bytes()))
    }

    pub fn i2c_read_u16(&mut self, addr: u16) -> Result<u16, Box<dyn Error>>
    {
        self.i2c.write(&(addr.to_be_bytes()))?;
        let mut buf: [u8; 2] = [0; 2];
        self.i2c.read(&mut buf)?;
        Ok(u16::from_be_bytes(buf))
    }
}

