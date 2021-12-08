
#![allow(dead_code)]

use super::*;
//use delegate::delegate;


pub struct MmioRegion {
    addr: usize,
    size: usize,
}

impl MmioRegion {
    pub const fn new(addr: usize, size: usize) -> Self {
        MmioRegion { addr:addr, size:size }
    }
}



impl MemRegion for MmioRegion {
    fn clone(&self, offset: usize, size: usize) -> Self {
        debug_assert!(offset < self.size);
        let new_addr = self.addr + offset;
        let new_size = self.size - offset;
        debug_assert!(size <= new_size);
        let new_size = if size == 0 { new_size } else { size };
        MmioRegion { addr:new_addr, size:new_size }
    }

    fn addr(&self) -> usize {
        self.addr
    }

    fn size(&self) -> usize {
        self.size
    }
}


pub fn mmio_accesor_new<BaseType>(addr: usize, size: usize) -> MemAccesor::<MmioRegion, BaseType>
{
    MemAccesor::<MmioRegion, BaseType>::new(MmioRegion::new(addr, size))
}


/*
pub struct MmioAccesor_<BaseType> {
    accessor: MemAccesor<MmioRegion, BaseType>,
}


impl<BaseType> MmioAccesor_<BaseType> {
    pub fn new(addr: usize, size: usize) -> MemAccesor::<MmioRegion, BaseType>
    {
        MemAccesor::<MmioRegion, BaseType>::new(MmioRegion::new(addr, size))
    }
}
*/

/*
impl<BaseType> MemAccess for MmioAccesor_<BaseType> {
    delegate! {
        to self.accessor {
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


pub type MmioAccesor8 = MmioAccesor_<u8>;
pub type MmioAccesor16 = MmioAccesor_<u16>;
pub type MmioAccesor32 = MmioAccesor_<u32>;
pub type MmioAccesor64 = MmioAccesor_<u64>;
pub type MmioAccesor = MmioAccesor_<usize>;

*/