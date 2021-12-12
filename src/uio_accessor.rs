#![allow(dead_code)]

use std::format;
use std::boxed::Box;
use std::string::String;
use std::string::ToString;
use std::error::Error;
use std::fs::File;
use std::io::Read;
use delegate::delegate;
use super::*;


fn read_file_to_string(path: String) -> Result<String, Box<dyn Error>> {
    let mut file = File::open(path)?;
    let mut buf = String::new();
    file.read_to_string(&mut buf)?;
    Ok(buf)
}


pub struct UioRegion {
    mmap_region: MmapRegion,
    phys_addr: usize,
}

impl UioRegion {
    pub fn new(uio_num: usize) -> Result<Self, Box<dyn Error>> {
        let phys_addr = Self::read_phys_addr(uio_num)?;
        let size = Self::read_size(uio_num)?;
        let fname = format!("/dev/uio{}", uio_num);
        Ok(UioRegion {
            mmap_region: MmapRegion::new(fname, size)?,
            phys_addr: phys_addr,
        })
    }

    pub fn read_name(uio_num: usize) -> Result<String, Box<dyn Error>> {
        let fname = format!("/sys/class/uio/uio{}/name", uio_num);
        Ok(read_file_to_string(fname)?.trim().to_string())
    }

    pub fn read_size(uio_num: usize) -> Result<usize, Box<dyn Error>> {
        let fname = format!("/sys/class/uio/uio{}/maps/map0/size", uio_num);
        Ok(usize::from_str_radix(&read_file_to_string(fname)?.trim()[2..], 16)?)
    }

    pub fn read_phys_addr(uio_num: usize) -> Result<usize, Box<dyn Error>> {
        let fname = format!("/sys/class/uio/uio{}/maps/map0/addr", uio_num);
        Ok(usize::from_str_radix(&read_file_to_string(fname)?.trim()[2..], 16)?)
    }
}


impl MemRegion for UioRegion {
    fn clone(&self, offset: usize, size: usize) -> Self {
        UioRegion {
            mmap_region: self.mmap_region.clone(offset, size),
            phys_addr: self.phys_addr + offset,
        }
    }

    delegate! {
        to self.mmap_region {
            fn addr(&self) -> usize;
            fn size(&self) -> usize;
        }
    }
}

/*
pub fn uio_accessor_new<U>(dev: Arc<UioDevice>) -> MemAccessor<UioRegion, U> {
    MemAccessor::<UioRegion, U>::new(UioRegion::new(dev))
}

pub fn uio_accessor_from_dev<U>(dev: UioDevice) -> MemAccessor<UioRegion, U> {
    uio_accessor_new::<U>(Arc::new(dev))
}

pub fn uio_accessor_from_number<U>(num: usize) -> Result<MemAccessor<UioRegion, U>, uio::UioError> {
    let dev = uio::UioDevice::new(num)?;
    Ok(uio_accessor_from_dev::<U>(dev))
}

pub fn uio_accessor_from_name<U>(name: &str) -> Result<MemAccessor<UioRegion, U>, uio::UioError> {
    for i in 0..99 {
        let dev = uio::UioDevice::new(i)?;
        let dev_name = dev.get_name()?;
        if dev_name == name {
            return Ok(uio_accessor_from_dev(dev));
        }
    }
    Err(uio::UioError::Parse)
}
*/



pub struct UioAccessor<U> {
    accessor: MemAccessor<UioRegion, U>,
}

impl<U> From<UioAccessor<U>> for MemAccessor<UioRegion, U> {
    fn from(from: UioAccessor<U>) -> MemAccessor<UioRegion, U> {
        from.accessor
    }
}

impl<U> UioAccessor<U> {
    pub fn new(uio_num: usize) -> Result<Self, Box<dyn Error>> {
        Ok(Self {
            accessor: MemAccessor::<UioRegion, U>::new(UioRegion::new(uio_num)?),
        })
    }

    pub fn new_from_name(name: &str) -> Result<Self, Box<dyn Error>> {
        for i in 0..99 {
            let dev_name = UioRegion::read_name(i)?;
            if dev_name == name {
                return Self::new(i);
            }
        }
        Self::new(100)
    }

    pub fn clone_<NewU>(&self, offset: usize, size: usize) -> UioAccessor<NewU> {
        UioAccessor::<NewU> {
            accessor: MemAccessor::<UioRegion, NewU>::new(self.accessor.region().clone(offset, size)),
        }
    }

    pub fn clone(&self, offset: usize, size: usize) -> UioAccessor<U> {
        self.clone_::<U>(offset, size)
    }

    pub fn clone8(&self, offset: usize, size: usize) -> UioAccessor<u8> {
        self.clone_::<u8>(offset, size)
    }

    pub fn clone16(&self, offset: usize, size: usize) -> UioAccessor<u16> {
        self.clone_::<u16>(offset, size)
    }

    pub fn clone32(&self, offset: usize, size: usize) -> UioAccessor<u32> {
        self.clone_::<u32>(offset, size)
    }

    pub fn clone64(&self, offset: usize, size: usize) -> UioAccessor<u64> {
        self.clone_::<u64>(offset, size)
    }
}

impl<U> MemAccess for UioAccessor<U> {
    fn reg_size() -> usize {
        core::mem::size_of::<U>()
    }

    delegate! {
        to self.accessor {
            unsafe fn write_mem_<V>(&self, offset: usize, data: V);
            unsafe fn read_mem_<V>(&self, offset: usize) -> V;
            unsafe fn write_reg_<V>(&self, reg: usize, data: V);
            unsafe fn read_reg_<V>(&self, reg: usize) -> V;

            unsafe fn write_mem(&self, offset: usize, data: usize);
            unsafe fn write_mem8(&self, offset: usize, data: u8);
            unsafe fn write_mem16(&self, offset: usize, data: u16);
            unsafe fn write_mem32(&self, offset: usize, data: u32);
            unsafe fn write_mem64(&self, offset: usize, data: u64);
            unsafe fn read_mem(&self, offset: usize) -> usize;
            unsafe fn read_mem8(&self, offset: usize) -> u8;
            unsafe fn read_mem16(&self, offset: usize) -> u16;
            unsafe fn read_mem32(&self, offset: usize) -> u32;
            unsafe fn read_mem64(&self, offset: usize) -> u64;

            unsafe fn write_reg(&self, reg: usize, data: usize);
            unsafe fn write_reg8(&self, reg: usize, data: u8);
            unsafe fn write_reg16(&self, reg: usize, data: u16);
            unsafe fn write_reg32(&self, reg: usize, data: u32);
            unsafe fn write_reg64(&self, reg: usize, data: u64);
            unsafe fn read_reg(&self, reg: usize) -> usize;
            unsafe fn read_reg8(&self, reg: usize) -> u8;
            unsafe fn read_reg16(&self, reg: usize) -> u16;
            unsafe fn read_reg32(&self, reg: usize) -> u32;
            unsafe fn read_reg64(&self, reg: usize) -> u64;
        }
    }
}
