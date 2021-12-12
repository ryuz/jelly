#![allow(dead_code)]

use super::*;
use std::sync::Arc;
use uio::UioDevice;

pub struct UioRegion {
    dev: Arc<UioDevice>,
    addr: usize,
    size: usize,
}

impl UioRegion {
    pub fn new(dev: Arc<UioDevice>) -> Self {
        let addr = dev.map_mapping(0).unwrap() as usize;
        let size = dev.map_size(0).unwrap();
        UioRegion {
            dev: dev,
            addr: addr,
            size: size,
        }
    }
}

impl MemRegion for UioRegion {
    fn clone(&self, offset: usize, size: usize) -> Self {
        debug_assert!(offset < self.size);
        let new_addr = self.addr + offset;
        let new_size = self.size - offset;
        debug_assert!(size <= new_size);
        let new_size = if size == 0 { new_size } else { size };
        UioRegion {
            dev: self.dev.clone(),
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

pub fn uio_accesor_new<U>(dev: Arc<UioDevice>) -> MemAccesor<UioRegion, U> {
    MemAccesor::<UioRegion, U>::new(UioRegion::new(dev))
}

pub fn uio_accesor_from_dev<U>(dev: UioDevice) -> MemAccesor<UioRegion, U> {
    uio_accesor_new::<U>(Arc::new(dev))
}

pub fn uio_accesor_from_number<U>(num: usize) -> Result<MemAccesor<UioRegion, U>, uio::UioError> {
    let dev = uio::UioDevice::new(num)?;
    Ok(uio_accesor_from_dev::<U>(dev))
}

pub fn uio_accesor_from_name<U>(name: &str) -> Result<MemAccesor<UioRegion, U>, uio::UioError> {
    for i in 0..99 {
        let dev = uio::UioDevice::new(i)?;
        let dev_name = dev.get_name()?;
        if dev_name == name {
            return Ok(uio_accesor_from_dev(dev));
        }
    }
    Err(uio::UioError::Parse)
}
