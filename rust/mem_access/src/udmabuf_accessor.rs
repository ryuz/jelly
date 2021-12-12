#![allow(dead_code)]

use delegate::delegate;
use super::*;

use std::fs::{File, OpenOptions};
use std::io;
use std::io::Read;
use std::path::Path;
use std::error::Error;

fn read_file_to_string(path: String) -> Result<String, Box<dyn Error>> {
    let mut file = File::open(path)?;
    let mut buf = String::new();
    file.read_to_string(&mut buf)?;
    Ok(buf)
}

struct UdmabufRegion {

}


impl UdmabufRegion {
    pub fn read_size(udmabuf_num: usize) -> Result<usize, Box<dyn Error>> {
        let fname = format!("/sys/class/u-dma-buf/udmabuf{}/size", udmabuf_num);
        Ok(read_file_to_string(fname)?.trim().parse()?)
    }

    pub fn read_phys_addr(udmabuf_num: usize) -> Result<usize, Box<dyn Error>> {
        let fname = format!("/sys/class/u-dma-buf/udmabuf{}/phys_addr", udmabuf_num);
        Ok(usize::from_str_radix(&read_file_to_string(fname)?.trim()[2..], 16)?)
    }
}

