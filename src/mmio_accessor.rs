#![allow(dead_code)]

use super::*;

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

pub const fn mmio_accesor_new<U>(addr: usize, size: usize) -> MemAccesor<MmioRegion, U> {
    MemAccesor::<MmioRegion, U>::new(MmioRegion::new(addr, size))
}

struct MmioAccesor<U> {
    accesor: MemAccesor<MmioRegion, U>,
}

impl<U> MmioAccesor<U> {
    pub const fn new(addr: usize, size: usize) -> Self {
        Self {
            accesor: MemAccesor::<MmioRegion, U>::new(MmioRegion::new(addr, size)),
        }
    }

    fn reg_size() -> usize {
        core::mem::size_of::<U>()
    }

    pub fn clone_<NewU>(&self, offset: usize, size: usize) -> MmioAccesor<NewU> {
        MmioAccesor::<NewU> {
            accesor: MemAccesor::<MmioRegion, NewU>::new(self.accesor.region().clone(offset, size)),
        }
    }

    pub fn clone(&self, offset: usize, size: usize) -> MmioAccesor<U> {
        self.clone_::<U>(offset, size)
    }

    pub fn clone8(&self, offset: usize, size: usize) -> MmioAccesor<u8> {
        self.clone_::<u8>(offset, size)
    }

    pub fn clone16(&self, offset: usize, size: usize) -> MmioAccesor<u16> {
        self.clone_::<u16>(offset, size)
    }

    pub fn clone32(&self, offset: usize, size: usize) -> MmioAccesor<u32> {
        self.clone_::<u32>(offset, size)
    }

    pub fn clone64(&self, offset: usize, size: usize) -> MmioAccesor<u64> {
        self.clone_::<u64>(offset, size)
    }
}
