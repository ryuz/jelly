#![allow(dead_code)]

use std::format;
use std::boxed::Box;
use std::fs::File;
//use std::io;
use std::io::Read;
//use std::path::Path;
use std::string::String;
//use std::string::ToString;
use std::error::Error;
//use thiserror::Error;
use delegate::delegate;
use super::*;



fn read_file_to_string(path: String) -> Result<String, Box<dyn Error>> {
    let mut file = File::open(path)?;
    let mut buf = String::new();
    file.read_to_string(&mut buf)?;
    Ok(buf)
}

struct UdmabufRegion {
    mmap_region: MmapRegion,
    phys_addr: usize,
}


impl UdmabufRegion {
    pub fn new(udmabuf_num: usize) -> Result<Self, Box<dyn Error>> {
        let phys_addr = Self::read_phys_addr(udmabuf_num)?;
        let size      = Self::read_size(udmabuf_num)?;

        let fname = format!("/dev/udmabuf{}", udmabuf_num);
        let mmap_region = MmapRegion::new(fname, size)?;
        
        Ok(Self{mmap_region:mmap_region, phys_addr:phys_addr})
    }

    pub fn phys_addr(&self) -> usize {
        self.phys_addr
    }

    pub fn read_phys_addr(udmabuf_num: usize) -> Result<usize, Box<dyn Error>> {
        let fname = format!("/sys/class/u-dma-buf/udmabuf{}/phys_addr", udmabuf_num);
        Ok(usize::from_str_radix(&read_file_to_string(fname)?.trim()[2..], 16)?)
    }

    pub fn read_size(udmabuf_num: usize) -> Result<usize, Box<dyn Error>> {
        let fname = format!("/sys/class/u-dma-buf/udmabuf{}/size", udmabuf_num);
        Ok(read_file_to_string(fname)?.trim().parse()?)
    }
}


impl MemRegion for UdmabufRegion {
    fn clone(&self, offset: usize, size: usize) -> Self {
        UdmabufRegion {
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



pub struct UdmabufAccessor<U> {
    mem_accessor: MemAccessor<UdmabufRegion, U>,
}

impl<U> From<UdmabufAccessor<U>> for MemAccessor<UdmabufRegion, U> {
    fn from(from: UdmabufAccessor<U>) -> MemAccessor<UdmabufRegion, U> {
        from.mem_accessor
    }
}

impl<U> UdmabufAccessor<U> {
    pub fn new(udmabuf_num: usize) -> Result<Self, Box<dyn Error>> {
        Ok(Self {
            mem_accessor: MemAccessor::<UdmabufRegion, U>::new(UdmabufRegion::new(udmabuf_num)?),
        })
    }

    pub fn clone_<NewU>(&self, offset: usize, size: usize) -> UdmabufAccessor<NewU> {
        UdmabufAccessor::<NewU> {
            mem_accessor: MemAccessor::<UdmabufRegion, NewU>::new(self.mem_accessor.region().clone(offset, size)),
        }
    }

    pub fn clone(&self, offset: usize, size: usize) -> UdmabufAccessor<U> {
        self.clone_::<U>(offset, size)
    }

    pub fn clone8(&self, offset: usize, size: usize) -> UdmabufAccessor<u8> {
        self.clone_::<u8>(offset, size)
    }

    pub fn clone16(&self, offset: usize, size: usize) -> UdmabufAccessor<u16> {
        self.clone_::<u16>(offset, size)
    }

    pub fn clone32(&self, offset: usize, size: usize) -> UdmabufAccessor<u32> {
        self.clone_::<u32>(offset, size)
    }

    pub fn clone64(&self, offset: usize, size: usize) -> UdmabufAccessor<u64> {
        self.clone_::<u64>(offset, size)
    }


    delegate! {
        to self.mem_accessor.region() {
            pub fn addr(&self) -> usize;
            pub fn size(&self) -> usize;
            pub fn phys_addr(&self) -> usize;
        }
    }
}

impl<U> MemAccess for UdmabufAccessor<U> {
    fn reg_size() -> usize {
        core::mem::size_of::<U>()
    }
    
    delegate! {
        to self.mem_accessor {
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
