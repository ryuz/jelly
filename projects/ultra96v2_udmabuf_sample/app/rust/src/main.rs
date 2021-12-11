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


fn main() {
    println!("Memory access test");
    
    // UIO を開く
    let uio_acc = uio_accesor_from_name::<usize>("uio_pl_peri").unwrap();

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
