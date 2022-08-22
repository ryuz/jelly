#![allow(dead_code)]

use jelly_mem_access::*;

const REG_DMA_STATUS: usize = 0;
const REG_DMA_WSTART: usize = 1;
const REG_DMA_RSTART: usize = 2;
const REG_DMA_ADDR: usize = 3;
const REG_DMA_WDATA0: usize = 4;
const REG_DMA_WDATA1: usize = 5;
const REG_DMA_RDATA0: usize = 6;
const REG_DMA_RDATA1: usize = 7;
const REG_DMA_CORE_ID: usize = 8;

const REG_LED_OUTPUT: usize = 0;

const REG_TIM_CONTROL: usize = 0;
const REG_TIM_COMPARE: usize = 1;
const REG_TIM_COUNTER: usize = 3;

fn main() {
    println!("--- udmabuf test ---");

    // mmap udmabuf
    let udmabuf_device_name = "udmabuf-jelly-sample";
    println!("\nudmabuf open");
    let udmabuf_acc = UdmabufAccessor::<usize>::new(udmabuf_device_name, false).expect("Failed to open udmabuf");
    println!("{} phys addr : 0x{:x}", udmabuf_device_name, udmabuf_acc.phys_addr());
    println!("{} size      : 0x{:x}", udmabuf_device_name, udmabuf_acc.size());

    // mmap uio
    println!("\nuio open");
    let mut uio_acc = UioAccessor::<usize>::new_with_name("uio_pl_peri").expect("Failed to open uio");
    println!("uio_pl_peri phys addr : 0x{:x}", uio_acc.phys_addr());
    println!("uio_pl_peri size      : 0x{:x}", uio_acc.size());

    // UIOの中をさらにコアごとに割り当て
    let dma0_acc = uio_acc.subclone(0x00000, 0x800);
    let dma1_acc = uio_acc.subclone(0x00800, 0x800);
    let led_acc = uio_acc.subclone(0x08000, 0x800);
    let tim_acc = uio_acc.subclone(0x10000, 0x800);

    unsafe {
        // メモリアドレスでアクセス
        println!("\n<test MemRead>");
        println!("DMA0_CORE_ID : 0x{:x}", uio_acc.read_mem(0x0040));
        println!("DMA1_CORE_ID : 0x{:x}", uio_acc.read_mem(0x0840));

        // レジスタ番号でアクセス
        println!("\n<test RegRead>");
        println!("DMA0_CORE_ID : 0x{:x}", dma0_acc.read_reg(REG_DMA_CORE_ID));
        println!("DMA1_CORE_ID : 0x{:x}", dma1_acc.read_reg(REG_DMA_CORE_ID));
        println!("\n<test DMA0 RegRead>");
        println!("DMA0_STATUS  : 0x{:x}", dma0_acc.read_reg(REG_DMA_STATUS));
        println!("DMA0_WSTART  : 0x{:x}", dma0_acc.read_reg(REG_DMA_WSTART));
        println!("DMA0_RSTART  : 0x{:x}", dma0_acc.read_reg(REG_DMA_RSTART));
        println!("DMA0_ADDR    : 0x{:x}", dma0_acc.read_reg(REG_DMA_ADDR));
        println!("DMA0_WDATA0  : 0x{:x}", dma0_acc.read_reg(REG_DMA_WDATA0));
        println!("DMA0_WDATA1  : 0x{:x}", dma0_acc.read_reg(REG_DMA_WDATA1));
        println!("DMA0_RDATA0  : 0x{:x}", dma0_acc.read_reg(REG_DMA_RDATA0));
        println!("DMA0_RDATA1  : 0x{:x}", dma0_acc.read_reg(REG_DMA_RDATA1));
        println!("DMA0_CORE_ID : 0x{:x}", dma0_acc.read_reg(REG_DMA_CORE_ID));

        // udma領域アクセス
        println!("\n<test udmabuf access>");
        let buf: [u32; 4] = [0x10101010, 0x20202020, 0x30303030, 0x40404040];
        udmabuf_acc.copy_from(&buf, 0, 1);
        println!("udmabuf[0] : 0x{:x}", udmabuf_acc.read_mem32(0x00));
        println!("udmabuf[1] : 0x{:x}", udmabuf_acc.read_mem32(0x04));
        println!("udmabuf[2] : 0x{:x}", udmabuf_acc.read_mem32(0x08));
        println!("udmabuf[3] : 0x{:x}", udmabuf_acc.read_mem32(0x0c));

        // DMA0でread
        println!("\n<DMA0 read test>");
        dma0_acc.write_reg(REG_DMA_ADDR, udmabuf_acc.phys_addr());
        dma0_acc.write_reg(REG_DMA_RSTART, 1);
        while dma0_acc.read_reg(REG_DMA_STATUS) != 0 {}
        println!(
            "REG_DMA0_RDATA0 : 0x{:x}",
            dma0_acc.read_reg(REG_DMA_RDATA0)
        );
        println!(
            "REG_DMA0_RDATA1 : 0x{:x}",
            dma0_acc.read_reg(REG_DMA_RDATA1)
        );

        // DMA1でread
        println!("\n<DMA1 read test>");
        dma1_acc.write_reg(REG_DMA_ADDR, udmabuf_acc.phys_addr());
        dma1_acc.write_reg(REG_DMA_RSTART, 1);
        while dma1_acc.read_reg(REG_DMA_STATUS) != 0 {}
        println!(
            "REG_DMA1_RDATA0 : 0x{:x}",
            dma1_acc.read_reg(REG_DMA_RDATA0)
        );
        println!(
            "REG_DMA1_RDATA1 : 0x{:x}",
            dma1_acc.read_reg(REG_DMA_RDATA1)
        );

        // DMA1でwrite
        println!("\n<DMA1 write test>");
        dma1_acc.write_reg(REG_DMA_ADDR, udmabuf_acc.phys_addr());
        dma1_acc.write_reg(REG_DMA_WDATA0, 0xfedcba9876543210usize);
        dma1_acc.write_reg(REG_DMA_WDATA1, 0x0123456789abcdefusize);
        dma1_acc.write_reg(REG_DMA_WSTART, 1);
        while dma1_acc.read_reg(REG_DMA_STATUS) != 0 {}

        // タイマ割り込みでLED点滅
        println!("\n<LED test>");
        tim_acc.write_reg(REG_TIM_COMPARE, 100000000 - 1);
        tim_acc.write_reg(REG_TIM_CONTROL, 1);
        for _ in 0..5 {
            // LED ON
            println!("LED : ON");
            led_acc.write_reg(REG_LED_OUTPUT, 1);

            // 割り込み待ち
            uio_acc.set_irq_enable(true).unwrap();
            uio_acc.wait_irq().unwrap();
            tim_acc.read_reg(REG_TIM_CONTROL); // clear interrupt

            // LED OFF
            println!("LED : OFF");
            led_acc.write_reg(REG_LED_OUTPUT, 0);

            // 割り込み待ち
            uio_acc.set_irq_enable(true).unwrap();
            uio_acc.wait_irq().unwrap();
            tim_acc.read_reg(REG_TIM_CONTROL); // clear interrupt
        }
    }
}
