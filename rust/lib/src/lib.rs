


pub mod i2c_access;
pub mod linux_i2c;
pub mod imx219_control;


#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        let result = 2 + 2;
        assert_eq!(result, 4);
    }
}
