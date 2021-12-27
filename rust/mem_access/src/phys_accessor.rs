#![allow(dead_code)]

use super::*;
use delegate::delegate;

// Memory mapped IO for Physical Address
pub struct PhysRegion<const ADDR: usize, const SIZE: usize> {}

impl<const ADDR: usize, const SIZE: usize> PhysRegion<ADDR, SIZE> {
    pub const fn new() -> Self {
        PhysRegion::<ADDR, SIZE> {}
    }
}

impl<const ADDR: usize, const SIZE: usize> MemRegion for PhysRegion<ADDR, SIZE> {
    fn subclone(&self, offset: usize, size: usize) -> Self {
        debug_assert!(offset == 0);
        debug_assert!(size == 0 || size == SIZE);
        PhysRegion::<ADDR, SIZE> {}
    }

    fn addr(&self) -> usize {
        ADDR
    }

    fn size(&self) -> usize {
        SIZE
    }
}

impl<const ADDR: usize, const SIZE: usize> Clone for PhysRegion<ADDR, SIZE> {
    fn clone(&self) -> Self {
        self.subclone(0, 0)
    }
}


pub struct PhysAccessor<U, const ADDR: usize, const SIZE: usize> {
    mem_accessor: MemAccessor<PhysRegion<ADDR, SIZE>, U>,
}

impl<U, const ADDR: usize, const SIZE: usize> From<PhysAccessor<U, ADDR, SIZE>>
    for MemAccessor<PhysRegion<ADDR, SIZE>, U>
{
    fn from(from: PhysAccessor<U, ADDR, SIZE>) -> MemAccessor<PhysRegion<ADDR, SIZE>, U> {
        from.mem_accessor
    }
}

impl<U, const ADDR: usize, const SIZE: usize> PhysAccessor<U, ADDR, SIZE> {
    pub const fn new() -> Self {
        Self {
            mem_accessor: MemAccessor::<PhysRegion<ADDR, SIZE>, U>::new(
                PhysRegion::<ADDR, SIZE>::new(),
            ),
        }
    }

    pub fn subclone_<NewU>(&self, offset: usize, size: usize) -> PhysAccessor<NewU, ADDR, SIZE> {
        PhysAccessor::<NewU, ADDR, SIZE> {
            mem_accessor: MemAccessor::<PhysRegion<ADDR, SIZE>, NewU>::new(
                self.mem_accessor.region().subclone(offset, size),
            ),
        }
    }

    pub fn subclone(&self, offset: usize, size: usize) -> PhysAccessor<U, ADDR, SIZE> {
        self.subclone_::<U>(offset, size)
    }

    pub fn subclone8(&self, offset: usize, size: usize) -> PhysAccessor<u8, ADDR, SIZE> {
        self.subclone_::<u8>(offset, size)
    }

    pub fn subclone16(&self, offset: usize, size: usize) -> PhysAccessor<u16, ADDR, SIZE> {
        self.subclone_::<u16>(offset, size)
    }

    pub fn subclone32(&self, offset: usize, size: usize) -> PhysAccessor<u32, ADDR, SIZE> {
        self.subclone_::<u32>(offset, size)
    }

    pub fn subclone64(&self, offset: usize, size: usize) -> PhysAccessor<u64, ADDR, SIZE> {
        self.subclone_::<u64>(offset, size)
    }

    delegate! {
        to self.mem_accessor.region() {
            pub fn addr(&self) -> usize;
            pub fn size(&self) -> usize;
        }
    }
}

impl<U, const ADDR: usize, const SIZE: usize> Clone for PhysAccessor<U, ADDR, SIZE> {
    fn clone(&self) -> Self {
        self.subclone(0, 0)
    }
}


impl<U, const ADDR: usize, const SIZE: usize> MemAccess for PhysAccessor<U, ADDR, SIZE> {
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
