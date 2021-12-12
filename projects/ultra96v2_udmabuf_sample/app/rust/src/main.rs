#![allow(dead_code)]

use std::{thread, time};
use jelly_mem_access::*;

const REG_DMA_STATUS : usize = 0;
const REG_DMA_WSTART : usize = 1;
const REG_DMA_RSTART : usize = 2;
const REG_DMA_ADDR   : usize = 3;
const REG_DMA_WDATA0 : usize = 4;
const REG_DMA_WDATA1 : usize = 5;
const REG_DMA_RDATA0 : usize = 6;
const REG_DMA_RDATA1 : usize = 7;
const REG_DMA_CORE_ID: usize = 8;

const REG_LED_OUTPUT: usize = 0;

const REG_TIM_CONTROL: usize = 0;
const REG_TIM_COMPARE: usize = 1;
const REG_TIM_COUNTER: usize = 3;

/*
use std::fs::{File, OpenOptions};
use std::io;
use std::io::Read;
use std::path::Path;
use std::error::Error;


struct Udmabuf {}

fn read_file_to_string(path: String) -> Result<String, Box<dyn Error>> {
    let mut file = File::open(path)?;
    let mut buf = String::new();
    file.read_to_string(&mut buf)?;
    Ok(buf)
}

impl Udmabuf {
    pub fn read_size(udmabuf_num: usize) -> Result<usize, Box<dyn Error>> {
        let fname = format!("/sys/class/u-dma-buf/udmabuf{}/size", udmabuf_num);
        Ok(read_file_to_string(fname)?.trim().parse()?)
    }

    pub fn read_phys_addr(udmabuf_num: usize) -> Result<usize, Box<dyn Error>> {
        let fname = format!("/sys/class/u-dma-buf/udmabuf{}/phys_addr", udmabuf_num);
        Ok(usize::from_str_radix(&read_file_to_string(fname)?.trim()[2..], 16)?)
    }
}
*/

fn main() {

    /*
    let uio_num = 4;
    let fname = format!("/sys/class/uio/uio{}/name", uio_num);
    println!("{}", read_file_to_string(fname).unwrap().trim());
    println!("{}", Udmabuf::read_size(4).unwrap());
    return;
    */


    println!("Memory access test");
    
    // UIO を開く
//  let uio_acc = uio_accessor_from_name::<usize>("uio_pl_peri").unwrap();
//  let uio_acc = UioAccessor::<usize>::new(4).unwrap();
    let uio_acc = UioAccessor::<usize>::new_from_name("uio_pl_peri").unwrap();

    // メモリアドレスでアクセス
    unsafe { println!("{:x}", uio_acc.read_mem(0x040)); }
    unsafe { println!("{:x}", uio_acc.read_mem(0x840)); }

    // UIOの中をさらにコアごとに割り当て
    let dma0_acc = uio_acc.clone(0x00000, 0);
    let dma1_acc = uio_acc.clone(0x00800, 0);
    let led_acc  = uio_acc.clone(0x08000, 0);
    let _tim_acc  = uio_acc.clone(0x10000, 0);

    // レジスタのワードアドレスでアクセス
    println!("DAM0 ID : 0x{:x}", unsafe{dma0_acc.read_reg(REG_DMA_CORE_ID)});
    println!("DAM1 ID : 0x{:x}", unsafe{dma1_acc.read_reg(REG_DMA_CORE_ID)});

    for _ in 0..5 {
        // LED ON
        println!("LED : ON");
        unsafe { led_acc.write_reg(REG_LED_OUTPUT, 1); }
        thread::sleep(time::Duration::from_millis(500));

        // LED OFF
        println!("LED : OFF");
        unsafe { led_acc.write_reg(REG_LED_OUTPUT, 0); }
        thread::sleep(time::Duration::from_millis(500));
    }
}
