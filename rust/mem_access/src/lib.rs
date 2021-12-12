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

#[cfg(feature = "std")]
pub mod uio_accessor;
#[cfg(feature = "std")]
pub use uio_accessor::*;

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        let result = 2 + 2;
        assert_eq!(result, 4);
    }
}
