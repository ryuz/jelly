#![allow(dead_code)]

use super::*;
use delegate::delegate;

// for Memory mapped IO
pub struct MmioRegion {
    addr: usize,
    size: usize,
}

impl MmioRegion {
    pub const fn new(addr: usize, size: usize) -> Self {
        MmioRegion {
            addr: addr,
            size: size,
        }
    }
}

impl MemRegion for MmioRegion {
    fn subclone(&self, offset: usize, size: usize) -> Self {
        debug_assert!(offset < self.size);
        let new_addr = self.addr + offset;
        let new_size = self.size - offset;
        debug_assert!(size <= new_size);
        let new_size = if size == 0 { new_size } else { size };
        MmioRegion {
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

impl Clone for MmioRegion {
    fn clone(&self) -> Self {
        self.subclone(0, 0)
    }
}


pub struct MmioAccessor<U> {
    mem_accessor: MemAccessor<MmioRegion, U>,
}

impl<U> From<MmioAccessor<U>> for MemAccessor<MmioRegion, U> {
    fn from(from: MmioAccessor<U>) -> MemAccessor<MmioRegion, U> {
        from.mem_accessor
    }
}


impl<U> MmioAccessor<U> {
    pub const fn new(addr: usize, size: usize) -> Self {
        Self {
            mem_accessor: MemAccessor::<MmioRegion, U>::new(MmioRegion::new(addr, size)),
        }
    }

    pub fn subclone_<NewU>(&self, offset: usize, size: usize) -> MmioAccessor<NewU> {
        MmioAccessor::<NewU> {
            mem_accessor: MemAccessor::<MmioRegion, NewU>::new(
                self.mem_accessor.region().subclone(offset, size),
            ),
        }
    }

    pub fn subclone(&self, offset: usize, size: usize) -> MmioAccessor<U> {
        self.subclone_::<U>(offset, size)
    }

    pub fn subclone8(&self, offset: usize, size: usize) -> MmioAccessor<u8> {
        self.subclone_::<u8>(offset, size)
    }

    pub fn subclone16(&self, offset: usize, size: usize) -> MmioAccessor<u16> {
        self.subclone_::<u16>(offset, size)
    }

    pub fn subclone32(&self, offset: usize, size: usize) -> MmioAccessor<u32> {
        self.subclone_::<u32>(offset, size)
    }

    pub fn subclone64(&self, offset: usize, size: usize) -> MmioAccessor<u64> {
        self.subclone_::<u64>(offset, size)
    }

    delegate! {
        to self.mem_accessor.region() {
            pub fn addr(&self) -> usize;
            pub fn size(&self) -> usize;
        }
    }
}

impl<U> Clone for MmioAccessor<U> {
    fn clone(&self) -> Self {
        self.subclone(0, 0)
    }
}


impl<U> MemAccess for MmioAccessor<U> {
    fn reg_size() -> usize {
        core::mem::size_of::<U>()
    }

    delegate! {
        to self.mem_accessor {
            fn addr(&self) -> usize;
            fn size(&self) -> usize;
        
            unsafe fn copy_to<V>(&self, src_adr: usize, dst_ptr: *mut V, count: usize);
            unsafe fn copy_from<V>(&self, src_ptr: *const V, dst_adr: usize, count: usize);
            
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
