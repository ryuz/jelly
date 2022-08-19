


use nix::fcntl::{open, OFlag};
use nix::unistd::{close, read, write};
use std::os::unix::io::RawFd;
use std::error::Error;


pub struct I2cAccessor {
    fd: RawFd,
}

// #define I2C_SLAVE        0x0703 
nix::ioctl_write_int_bad!(i2c_slave, 0x0703);


impl I2cAccessor {

    pub fn new(path: &str, adr: u8) -> Result<Self, Box<dyn Error>> {
        let fd = open(path, OFlag::O_RDWR, nix::sys::stat::Mode::empty())?;
        let mut i2c = I2cAccessor {
            fd: fd,
        };
        i2c.set_slave_address(adr)?;
        Ok(i2c)
    }

    pub fn set_slave_address(&mut self, adr: u8) -> Result<(), Box<dyn Error>> {
        unsafe { i2c_slave(self.fd, adr as libc::c_int)?; }
        Ok(())
    }

    pub fn i2c_write(&mut self, data: &[u8]) -> Result<usize, Box<dyn Error>> {
        let l = write(self.fd, data)?;
        Ok(l)
    }

    pub fn i2c_read(&mut self, buf: &mut [u8]) -> Result<usize, Box<dyn Error>> {
        let l = read(self.fd, buf)?;
        Ok(l)
    }
}


impl Drop for I2cAccessor {
    fn drop(&mut self) {
        close(self.fd);
    }
}
