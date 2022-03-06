#![allow(dead_code)]

use std::fs::File;
use std::io::{Read, BufReader};
use jelly_mem_access::*;


const REG_RISCV_CORE_ID      : usize = 0x0;
const REG_RISCV_CORE_VERSION : usize = 0x1;
const REG_RISCV_CORE_DATE    : usize = 0x2;
const REG_RISCV_MEM_OFFSET   : usize = 0x4;
const REG_RISCV_MEM_SIZE     : usize = 0x5;
const REG_RISCV_CTL_RESET    : usize = 0x8;


fn main() {
    // mmap uio
    println!("\nuio open");
    let uio_acc = UioAccessor::<usize>::new_with_name("uio_pl_peri").unwrap();
    println!("uio_pl_peri phys addr : 0x{:x}", uio_acc.phys_addr());
    println!("uio_pl_peri size      : 0x{:x}", uio_acc.size());

    unsafe {
        // メモリアドレスでアクセス
        println!("REG_RISCV_CORE_ID      : 0x{:x}", uio_acc.read_reg(REG_RISCV_CORE_ID));
        println!("REG_RISCV_CORE_VERSION : 0x{:x}", uio_acc.read_reg(REG_RISCV_CORE_VERSION));
        println!("REG_RISCV_CORE_DATE    : 0x{:x}", uio_acc.read_reg(REG_RISCV_CORE_DATE));
        println!("REG_RISCV_MEM_OFFSET   : 0x{:x}", uio_acc.read_reg(REG_RISCV_MEM_OFFSET));
        println!("REG_RISCV_MEM_SIZE     : 0x{:x}", uio_acc.read_reg(REG_RISCV_MEM_SIZE));
    }


    let mut reader = BufReader::new(File::open("../riscv/riscv_sample.bin").unwrap());
    let mut buf: [u8; 4] = [0; 4];
    let mut adr: usize = 0;
    loop {
        match reader.read(&mut buf).unwrap() {
            0 => break,
            _ => {
                let data = u32::from_le_bytes(buf);
                unsafe { uio_acc.write_reg(0x8000 + adr, data as usize); }
                adr = adr+1;
//              println!("{:x}", data)
            }
        }
    }
    unsafe { uio_acc.write_reg(REG_RISCV_CTL_RESET, 0); }
    
}

