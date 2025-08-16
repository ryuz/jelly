
use std::error::Error;

use crate::rtcl_p3s7_i2c::*;

struct RtclP3s7Mng {
    i2c: RtclP3s7I2c,
}

impl RtclP3s7Mng {
    pub fn new() -> Result<Self, Box<dyn Error>> {
        Ok(RtclP3s7Mng {
            i2c: RtclP3s7I2c::new("/dev/i2c-6")?,
        })
    }
}

