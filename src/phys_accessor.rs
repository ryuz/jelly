
#![allow(dead_code)]

use super::*;

// Memory mapped IO for Physical Address
pub struct PhysRegion<const ADDR: usize, const SIZE: usize> {
}

impl<const ADDR: usize, const SIZE: usize> PhysRegion<ADDR, SIZE> {
    pub const fn new() -> Self {
        PhysRegion::<ADDR, SIZE> {}
    }
}


impl<const ADDR: usize, const SIZE: usize> MemRegion for PhysRegion<ADDR, SIZE> {
    fn clone(&self, offset: usize, size: usize) -> Self {
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


pub const fn phys_accesor_new<BaseType, const ADDR: usize, const SIZE: usize>() -> MemAccesor::<PhysRegion<ADDR, SIZE>, BaseType>
{
    MemAccesor::<PhysRegion<ADDR, SIZE>, BaseType>::new(PhysRegion::<ADDR, SIZE>::new())
}

