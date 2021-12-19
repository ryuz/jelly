#![allow(dead_code)]

use super::*;
use delegate::delegate;

use libc;
use nix::sys::mman::{MapFlags, ProtFlags};
use std::boxed::Box;
use std::error::Error;
use std::fs::{File, OpenOptions};
use std::io::prelude::*;
use std::os::unix::fs::OpenOptionsExt;
use std::os::unix::prelude::AsRawFd;
use std::string::String;
use std::sync::{Arc, RwLock};

struct MmapFile {
    file: File,
    addr: *mut libc::c_void,
    size: usize,
}

impl MmapFile {
    pub fn new(path: String, size: usize) -> Result<Self, Box<dyn Error>> {
        Self::new_with_flag(path, size, 0)
    }

    pub fn new_with_flag(path: String, size: usize, flag: i32) -> Result<Self, Box<dyn Error>> {
        let file = OpenOptions::new()
            .read(true)
            .write(true)
            .custom_flags(flag)
            .open(path)?;
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

    pub fn file(&mut self) -> &File {
        &mut self.file
    }

    pub fn write(&mut self, data: &[u8]) -> Result<usize, Box<dyn Error>> {
        let size = self.file.write(data)?;
        Ok(size)
    }

    pub fn read(&mut self, buf: &mut [u8]) -> Result<usize, Box<dyn Error>> {
        let size = self.file.read(buf)?;
        Ok(size)
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
    mfile: Arc<RwLock<MmapFile>>,
    addr: usize,
    size: usize,
}

impl MmapRegion {
    pub fn new(path: String, size: usize) -> Result<Self, Box<dyn Error>> {
        Self::new_with_flag(path, size, 0)
    }

    pub fn new_with_flag(path: String, size: usize, flag: i32) -> Result<Self, Box<dyn Error>> {
        let mfile = MmapFile::new_with_flag(path, size, flag)?;
        let addr = mfile.addr();
        let size = mfile.size();
        Ok(Self {
            mfile: Arc::new(RwLock::new(mfile)),
            addr: addr,
            size: size,
        })
    }

    pub fn write(&mut self, data: &[u8]) -> Result<usize, Box<dyn Error>> {
        self.mfile.write().unwrap().write(data)
    }

    pub fn read(&mut self, buf: &mut [u8]) -> Result<usize, Box<dyn Error>> {
        self.mfile.write().unwrap().read(buf)
    }
}

impl MemRegion for MmapRegion {
    fn subclone(&self, offset: usize, size: usize) -> Self {
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

impl Clone for MmapRegion {
    fn clone(&self) -> Self {
        self.subclone(0, 0)
    }
}


pub struct MmapAccessor<U> {
    accessor: MemAccessor<MmapRegion, U>,
}

impl<U> From<MmapAccessor<U>> for MemAccessor<MmapRegion, U> {
    fn from(from: MmapAccessor<U>) -> MemAccessor<MmapRegion, U> {
        from.accessor
    }
}


impl<U> MmapAccessor<U> {
    pub fn new(path: String, size: usize) -> Result<Self, Box<dyn Error>> {
        Ok(Self {
            accessor: MemAccessor::<MmapRegion, U>::new(MmapRegion::new(path, size)?),
        })
    }

    pub fn subclone_<NewU>(&self, offset: usize, size: usize) -> MmapAccessor<NewU> {
        MmapAccessor::<NewU> {
            accessor: MemAccessor::<MmapRegion, NewU>::new(
                self.accessor.region().subclone(offset, size),
            ),
        }
    }

    pub fn subclone(&self, offset: usize, size: usize) -> MmapAccessor<U> {
        self.subclone_::<U>(offset, size)
    }

    pub fn subclone8(&self, offset: usize, size: usize) -> MmapAccessor<u8> {
        self.subclone_::<u8>(offset, size)
    }

    pub fn subclone16(&self, offset: usize, size: usize) -> MmapAccessor<u16> {
        self.subclone_::<u16>(offset, size)
    }

    pub fn subclone32(&self, offset: usize, size: usize) -> MmapAccessor<u32> {
        self.subclone_::<u32>(offset, size)
    }

    pub fn subclone64(&self, offset: usize, size: usize) -> MmapAccessor<u64> {
        self.subclone_::<u64>(offset, size)
    }
}

impl<U> Clone for MmapAccessor<U> {
    fn clone(&self) -> Self {
        self.subclone(0, 0)
    }
}


impl<U> MemAccess for MmapAccessor<U> {
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
