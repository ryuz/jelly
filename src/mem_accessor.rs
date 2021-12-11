
#![allow(dead_code)]

use core::ptr;
use core::marker::PhantomData;


pub trait MemRegion {
    fn clone(&self, offset: usize, size: usize) -> Self;
    fn addr(&self) -> usize;
    fn size(&self) -> usize;
}

pub trait MemAccess {
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

pub struct MemAccesor<T: MemRegion, BaseType> {
    region: T,
    phantom: PhantomData<BaseType>,
}

impl<T: MemRegion + Sized, BaseType> MemAccesor<T, BaseType> {
    pub const fn new(region: T) -> Self
    {
        MemAccesor::<T, BaseType> { region: region, phantom: PhantomData }
    }
    
    fn reg_size() -> usize {
        core::mem::size_of::<BaseType>()
    }

    pub fn clone(&self, offset: usize, size: usize) -> MemAccesor<T, BaseType> {
        MemAccesor::<T, BaseType>::new(self.region.clone(offset, size))
    }

    pub fn clone8(&self, offset: usize, size: usize) -> MemAccesor<T, u8> {
        MemAccesor::<T, u8>::new(self.region.clone(offset, size))
    }

    pub fn clone16(&self, offset: usize, size: usize) -> MemAccesor<T, u16> {
        MemAccesor::<T, u16>::new(self.region.clone(offset, size))
    }

    pub fn clone32(&self, offset: usize, size: usize) -> MemAccesor<T, u32> {
        MemAccesor::<T, u32>::new(self.region.clone(offset, size))
    }

    pub fn clone64(&self, offset: usize, size: usize) -> MemAccesor<T, u64> {
        MemAccesor::<T, u64>::new(self.region.clone(offset, size))
    }
}


impl <T: MemRegion, BaseType> MemAccess for MemAccesor<T, BaseType> {
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

