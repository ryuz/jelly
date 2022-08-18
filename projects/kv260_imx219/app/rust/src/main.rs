use std::error::Error;
use std::thread;
use std::time::Duration;

use jelly_mem_access::*;

mod imx219_control;
use imx219_control::*;

use i2cdev::core::*;
use i2cdev::linux::LinuxI2CDevice;

impl I2cAccess for LinuxI2CDevice {
    fn write(&mut self, data: &[u8]) -> Result<(), Box<dyn Error>> {
        match I2CDevice::write(self, data) {
            Ok(f) => Ok(f),
            Err(error) => Err(Box::new(error)),
        }
    }

    fn read(&mut self, buf: &mut [u8]) -> Result<(), Box<dyn Error>> {
        match I2CDevice::read(self, buf) {
            Ok(f) => Ok(f),
            Err(error) => Err(Box::new(error)),
        }
    }
}

fn main() {
    // start
    println!("start");

    println!("\nuio open");
    let uio_acc = UioAccessor::<usize>::new_with_name("uio_pl_peri").expect("Failed to open uio");
    println!("uio_pl_peri phys addr : 0x{:x}", uio_acc.phys_addr());
    println!("uio_pl_peri size      : 0x{:x}", uio_acc.size());

    // カメラON
    unsafe {
        uio_acc.write_reg(2, 1);
    }
    thread::sleep(Duration::from_millis(500));

    // IMX219 control
    let i2c = Box::new(LinuxI2CDevice::new("/dev/i2c-6", 0x10).expect("Failed to open i2c"));
    let mut imx219 = Imx219Control::new(i2c);

    println!("Camera-ID{:04x}", imx219.i2c_read_u16(0).unwrap());

    println!("Hello, world!");
}
