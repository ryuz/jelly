

pub mod mem_accessor;
pub use mem_accessor::*;

pub mod mmio_accessor;
pub use mmio_accessor::*;

pub mod uio_accessor;
pub use uio_accessor::*;


#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        let result = 2 + 2;
        assert_eq!(result, 4);
    }
}
