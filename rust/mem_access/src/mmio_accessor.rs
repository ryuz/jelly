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
    fn clone(&self, offset: usize, size: usize) -> Self {
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

    pub fn clone_<NewU>(&self, offset: usize, size: usize) -> MmioAccessor<NewU> {
        MmioAccessor::<NewU> {
            mem_accessor: MemAccessor::<MmioRegion, NewU>::new(self.mem_accessor.region().clone(offset, size)),
        }
    }

    pub fn clone(&self, offset: usize, size: usize) -> MmioAccessor<U> {
        self.clone_::<U>(offset, size)
    }

    pub fn clone8(&self, offset: usize, size: usize) -> MmioAccessor<u8> {
        self.clone_::<u8>(offset, size)
    }

    pub fn clone16(&self, offset: usize, size: usize) -> MmioAccessor<u16> {
        self.clone_::<u16>(offset, size)
    }

    pub fn clone32(&self, offset: usize, size: usize) -> MmioAccessor<u32> {
        self.clone_::<u32>(offset, size)
    }

    pub fn clone64(&self, offset: usize, size: usize) -> MmioAccessor<u64> {
        self.clone_::<u64>(offset, size)
    }

    delegate! {
        to self.mem_accessor.region() {
            pub fn addr(&self) -> usize;
            pub fn size(&self) -> usize;
        }
    }
}

impl<U> MemAccess for MmioAccessor<U> {
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
