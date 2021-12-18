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
