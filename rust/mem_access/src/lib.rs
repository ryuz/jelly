#![no_std]
#![feature(const_fn_trait_bound)]

#[cfg(feature = "std")]
extern crate std;

pub mod mem_accessor;
pub use mem_accessor::*;

pub mod phys_accessor;
pub use phys_accessor::*;

pub mod mmio_accessor;
pub use mmio_accessor::*;

#[cfg(all(feature = "std", unix))]
pub mod mmap_accessor;
#[cfg(all(feature = "std", unix))]
pub use mmap_accessor::*;

#[cfg(all(feature = "std", unix))]
pub mod uio_accessor;
#[cfg(all(feature = "std", unix))]
pub use uio_accessor::*;

#[cfg(all(feature = "std", unix))]
pub mod udmabuf_accessor;
#[cfg(all(feature = "std", unix))]
pub use udmabuf_accessor::*;



#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn mmio_access() {
        type RegisterWordSize = u64;

        let mut buf: [u64; 4] = [0; 4];
        let mmio = MmioAccessor::<RegisterWordSize>::new(&mut buf as *mut u64 as usize, 32);
        unsafe {
            mmio.write_mem8 (0x00, 0x12);
            mmio.write_mem8 (0x01, 0x34);
            mmio.write_mem16(0x02, 0x4444);
            mmio.write_mem32(0x04, 0x87654321);
            mmio.write_mem64(0x08, 0x0123456789abcdef);
            assert_eq!(mmio.read_mem8 (0x00), 0x12);
            assert_eq!(mmio.read_mem8 (0x01), 0x34);
            assert_eq!(mmio.read_mem16(0x02), 0x4444);
            assert_eq!(mmio.read_mem32(0x04), 0x87654321);
            assert_eq!(mmio.read_mem64(0x08), 0x0123456789abcdef);
        }
    }

    /*
    #[test]
    fn uio_access() {
        type RegisterWordSize = u32;
        let number_of_uio = 1;  // ex.) /dev/uio1
        let uio = UioAccessor::<RegisterWordSize>::new(number_of_uio);
        uio.read_reg32(0);
    }
    */
    
}

