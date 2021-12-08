
#![allow(dead_code)]

use core::ptr;
use core::marker::PhantomData;
use delegate::delegate;


pub trait Region {
    fn clone(&self, offset: usize, size: usize) -> Self;
    fn addr(&self) -> usize;
    fn size(&self) -> usize;
}

pub trait Access {
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

pub struct Accesor<T: Region, BaseType> {
    region: T,
    phantom: PhantomData<BaseType>,
}

impl<T: Region, BaseType> Accesor<T, BaseType> {
    pub fn new(region: T) -> Self
    {
        Accesor::<T, BaseType> { region: region, phantom: PhantomData }
    }

    fn reg_size() -> usize {
        core::mem::size_of::<BaseType>()
    }
}

impl <T: Region, BaseType> Access for Accesor<T, BaseType> {
    unsafe fn write_mem(&self, offset: usize, data: usize)
    {
        debug_assert!(offset + core::mem::size_of::<usize>() <= self.region.size());
        let addr = self.region.addr() + offset;
        ptr::write_volatile(addr as *mut usize, data);
    }

    unsafe fn write_mem8(&self, offset: usize, data: u8)
    {
        debug_assert!(offset + core::mem::size_of::<u8>() <= self.region.size());
        let addr = self.region.addr() + offset;
        ptr::write_volatile(addr as *mut u8, data);
    }

    unsafe fn write_mem16(&self, offset: usize, data: u16)
    {
        debug_assert!(offset + core::mem::size_of::<u16>() <= self.region.size());
        let addr = self.region.addr() + offset;
        ptr::write_volatile(addr as *mut u16, data);
    }

    unsafe fn write_mem32(&self, offset: usize, data: u32)
    {
        debug_assert!(offset + core::mem::size_of::<u32>() <= self.region.size());
        let addr = self.region.addr() + offset;
        ptr::write_volatile(addr as *mut u32, data);
    }

    unsafe fn write_mem64(&self, offset: usize, data: u64)
    {
        debug_assert!(offset + core::mem::size_of::<u64>() <= self.region.size());
        let addr = self.region.addr() + offset;
        ptr::write_volatile(addr as *mut u64, data);
    }

    unsafe fn read_mem(&self, offset: usize) -> usize {
        debug_assert!(offset + core::mem::size_of::<usize>() <= self.region.size());
        let addr = self.region.addr() + offset;
        ptr::read_volatile(addr as *mut usize)
    }

    unsafe fn read_mem8(&self, offset: usize) -> u8 {
        debug_assert!(offset + core::mem::size_of::<u8>() <= self.region.size());
        let addr = self.region.addr() + offset;
        ptr::read_volatile(addr as *mut u8)
    }

    unsafe fn read_mem16(&self, offset: usize) -> u16 {
        debug_assert!(offset + core::mem::size_of::<u16>() <= self.region.size());
        let addr = self.region.addr() + offset;
        ptr::read_volatile(addr as *mut u16)
    }

    unsafe fn read_mem32(&self, offset: usize) -> u32 {
        debug_assert!(offset + core::mem::size_of::<u32>() <= self.region.size());
        let addr = self.region.addr() + offset;
        ptr::read_volatile(addr as *mut u32)
    }

    unsafe fn read_mem64(&self, offset: usize) -> u64 {
        debug_assert!(offset + core::mem::size_of::<u64>() <= self.region.size());
        let addr = self.region.addr() + offset;
        ptr::read_volatile(addr as *mut u64)
    }


    unsafe fn write_reg(&self, reg: usize, data: usize)
    {
        self.write_mem(reg * Self::reg_size(), data);
    }

    unsafe fn write_reg8(&self, reg: usize, data: u8)
    {
        self.write_mem8(reg * Self::reg_size(), data);
    }

    unsafe fn write_reg16(&self, reg: usize, data: u16)
    {
        self.write_mem16(reg * Self::reg_size(), data);
    }

    unsafe fn write_reg32(&self, reg: usize, data: u32)
    {
        self.write_mem32(reg * Self::reg_size(), data);
    }

    unsafe fn write_reg64(&self, reg: usize, data: u64)
    {
        self.write_mem64(reg * Self::reg_size(), data);
    }

    unsafe fn read_reg(&self, reg: usize) -> usize {
        self.read_mem(reg * Self::reg_size())
    }

    unsafe fn read_reg8(&self, reg: usize) -> u8 {
        self.read_mem8(reg * Self::reg_size())
    }

    unsafe fn read_reg16(&self, reg: usize) -> u16 {
        self.read_mem16(reg * Self::reg_size())
    }

    unsafe fn read_reg32(&self, reg: usize) -> u32 {
        self.read_mem32(reg * Self::reg_size())
    }

    unsafe fn read_reg64(&self, reg: usize) -> u64 {
        self.read_mem64(reg * Self::reg_size())
    }
}


pub struct MemRegion {
    addr: usize,
    size: usize,
}

impl MemRegion {
    pub const fn new(addr: usize, size: usize) -> Self {
        MemRegion { addr:addr, size:size }
    }
}

impl Region for MemRegion {
    fn clone(&self, offset: usize, size: usize) -> Self {
        debug_assert!(offset < self.size);
        let new_addr = self.addr + offset;
        let new_size = self.size - offset;
        debug_assert!(size <= new_size);
        let new_size = if size == 0 { new_size } else { size };
        MemRegion { addr:new_addr, size:new_size }
    }

    fn addr(&self) -> usize {
        self.addr
    }

    fn size(&self) -> usize {
        self.size
    }
}

pub struct MemAccesor_<BaseType> {
    accessor: Accesor<MemRegion, BaseType>,
}


impl<BaseType> MemAccesor_<BaseType> {
    pub fn new(addr: usize, size: usize) -> Self
    {
        Self { accessor: Accesor::<MemRegion, BaseType>::new(MemRegion::new(addr, size)) }
    }
}


impl<BaseType> Access for MemAccesor_<BaseType> {
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


pub type MemAccesor8 = MemAccesor_<u8>;
pub type MemAccesor16 = MemAccesor_<u16>;
pub type MemAccesor32 = MemAccesor_<u32>;
pub type MemAccesor64 = MemAccesor_<u64>;
pub type MemAccesor = MemAccesor_<usize>;

