use std::error::Error;

pub trait I2cAccess {
    fn write(&mut self, data: &[u8]) -> Result<usize, Box<dyn Error>>;
    fn read(&mut self, buf: &mut [u8]) -> Result<usize, Box<dyn Error>>;
}

