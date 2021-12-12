#![allow(dead_code)]

use super::*;
use delegate::delegate;

use libc;
use nix::sys::mman::{MapFlags, ProtFlags};
use std::boxed::Box;
use std::error::Error;
use std::fs::{File, OpenOptions};
use std::os::unix::prelude::AsRawFd;
use std::string::String;
use std::sync::Arc;

struct MmapFile {
    file: File,
    addr: *mut libc::c_void,
    size: usize,
}

impl MmapFile {
    pub fn new(path: String, size: usize) -> Result<Self, Box<dyn Error>> {
        let file = OpenOptions::new().read(true).write(true).open(path)?;
        unsafe {
            let addr = nix::sys::mman::mmap(
                0 as *mut libc::c_void,
                size as libc::size_t,
                ProtFlags::PROT_READ | ProtFlags::PROT_WRITE,
                MapFlags::MAP_SHARED,
                file.as_raw_fd(),
                0 as libc::off_t,
            )?;

            Ok(MmapFile {
                file: file,
                addr: addr,
                size: size,
            })
        }
    }

    pub fn addr(&self) -> usize {
        self.addr as usize
    }

    pub fn size(&self) -> usize {
        self.size
    }
}

impl Drop for MmapFile {
    fn drop(&mut self) {
        unsafe {
            nix::sys::mman::munmap(self.addr, self.size as libc::size_t).unwrap();
        }
    }
}

pub struct MmapRegion {
    mfile: Arc<MmapFile>,
    addr: usize,
    size: usize,
}

impl MmapRegion {
    fn new(path: String, size: usize) -> Result<Self, Box<dyn Error>> {
        let mfile = MmapFile::new(path, size)?;
        let addr = mfile.addr();
        let size = mfile.size();
        Ok(Self {
            mfile: Arc::new(mfile),
            addr: addr,
            size: size,
        })
    }
}

impl MemRegion for MmapRegion {
    fn clone(&self, offset: usize, size: usize) -> Self {
        debug_assert!(offset < self.size);
        let new_addr = self.addr + offset;
        let new_size = self.size - offset;
        debug_assert!(size <= new_size);
        let new_size = if size == 0 { new_size } else { size };
        MmapRegion {
            mfile: self.mfile.clone(),
            addr: new_addr,
            size: new_size,
        }
    }

    fn addr(&self) -> usize {
        self.addr
    }

    fn size(&self) -> usize {
        self.size
    }
}

pub struct MmapAccesor<U> {
    accesor: MemAccesor<MmapRegion, U>,
}

impl<U> From<MmapAccesor<U>> for MemAccesor<MmapRegion, U> {
    fn from(from: MmapAccesor<U>) -> MemAccesor<MmapRegion, U> {
        from.accesor
    }
}

impl<U> MmapAccesor<U> {
    pub fn new(path: String, size: usize) -> Result<Self, Box<dyn Error>> {
        Ok(Self {
            accesor: MemAccesor::<MmapRegion, U>::new(MmapRegion::new(path, size)?),
        })
    }

    pub fn clone_<NewU>(&self, offset: usize, size: usize) -> MmapAccesor<NewU> {
        MmapAccesor::<NewU> {
            accesor: MemAccesor::<MmapRegion, NewU>::new(self.accesor.region().clone(offset, size)),
        }
    }

    pub fn clone(&self, offset: usize, size: usize) -> MmapAccesor<U> {
        self.clone_::<U>(offset, size)
    }

    pub fn clone8(&self, offset: usize, size: usize) -> MmapAccesor<u8> {
        self.clone_::<u8>(offset, size)
    }

    pub fn clone16(&self, offset: usize, size: usize) -> MmapAccesor<u16> {
        self.clone_::<u16>(offset, size)
    }

    pub fn clone32(&self, offset: usize, size: usize) -> MmapAccesor<u32> {
        self.clone_::<u32>(offset, size)
    }

    pub fn clone64(&self, offset: usize, size: usize) -> MmapAccesor<u64> {
        self.clone_::<u64>(offset, size)
    }
}

impl<U> MemAccess for MmapAccesor<U> {
    fn reg_size() -> usize {
        core::mem::size_of::<U>()
    }

    delegate! {
        to self.accesor {
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
