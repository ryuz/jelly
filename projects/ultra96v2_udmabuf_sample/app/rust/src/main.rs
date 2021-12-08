
use uio::UioDevice;

mod mem_accessor;

use mem_accessor::{MemAccesor, Access};


fn open_uio(name: &str) -> Result<UioDevice, uio::UioError>
{
    for i in 0..99 {
        let dev = uio::UioDevice::new(i)?;
        let dev_name = dev.get_name()?;
        if dev_name == name {
            return Ok(dev);
        }
    }
    Err(uio::UioError::Parse)
}  


fn main() {
    println!("Hello, world!");

    let dev = open_uio("uio_pl_peri").unwrap();

    println!("uio_name : {}", dev.get_name().unwrap());
    println!("uio_addr : 0x{:x}", dev.map_addr(0).unwrap());
    println!("uio_size : 0x{:x}", dev.map_size(0).unwrap());

    let addr = dev.map_mapping(0).unwrap();
    let addr = addr as usize;
    unsafe { println!("{:x}", std::ptr::read_volatile((addr + 0x040) as *mut u32)); }
    unsafe { println!("{:x}", std::ptr::read_volatile((addr + 0x840) as *mut u32)); }

    let acc = MemAccesor::new(addr, dev.map_size(0).unwrap());
    unsafe { println!("{:x}", acc.read_mem(0x040)); }
    unsafe { println!("{:x}", acc.read_mem(0x840)); }
}
