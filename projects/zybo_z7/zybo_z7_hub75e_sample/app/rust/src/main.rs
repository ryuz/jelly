#![allow(unused)]

use std::error::Error;

use clap::Parser;
//use jelly_lib::linux_i2c::LinuxI2c;
use jelly_mem_access::*;

use opencv::*;
use opencv::core::*;
use opencv::imgcodecs::imread;
use opencv::imgproc::*;


const REG_CORE_ID        : usize = 0x00;
const REG_CORE_VERSION   : usize = 0x01;
const REG_CTL_CONTROL    : usize = 0x04;
const REG_PARAM_FLIP     : usize = 0x10;
const REG_PARAM_DISP     : usize = 0x20;
const REG_PARAM_INTERVAL : usize = 0x40;


/// ZYBO Z7 RTCL P3S7 High Speed Camera Application
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(short = 'f', long, default_value = "")]
    file: String,

    #[arg(short = 'v')]
    v_flip: bool,

    #[arg(short = 'h')]
    h_flip: bool,

    #[arg(long)]
    off: bool,
}

fn main() -> Result<(), Box<dyn Error>> {
    println!("HUB-75E Led Matrix Sample Program");

    // 制御レジスタ
    let uio_reg  = UioAccessor::<usize>::new_with_name("uio_reg").expect("Failed to open uio");
    println!("uio_reg  phys addr : 0x{:x}", uio_reg.phys_addr());
    println!("uio_reg  size      : 0x{:x}", uio_reg.size());

    // VRAM
    let uio_vram = UioAccessor::<usize>::new_with_name("uio_vram").expect("Failed to open uio");
    println!("uio_vram phys addr : 0x{:x}", uio_vram.phys_addr());
    println!("uio_vram size      : 0x{:x}", uio_vram.size());

    println!("ID : 0x{:x}", unsafe{uio_reg.read_reg(0)});

    let args = Args::parse();

    // 表示OFF
    if args.off {
        unsafe {
            uio_reg.write_reg(4, 0);
        }
        println!("LED off");
        return Ok(());
    }

    // 上下左右反転設定
    let mut flip = 0;
    if args.h_flip {
        flip |= 0x1;
    }
    if args.v_flip {
        flip |= 0x2;
    }
    unsafe {
        uio_reg.write_reg(REG_PARAM_FLIP, flip);
    }

    // 表示データ
    let mut img = [[[0u8; 3]; 64]; 64];

    // デフォルトでグラデーション
    for y in 0..64 {
        for x in 0..64 {
            img[y][x][0] = ((y + x) * 2) as u8; // B
            img[y][x][1] = ((y + (63 - x)) * 2) as u8; // G
            img[y][x][2] = (((63 - y) + x) * 2) as u8 ; // R
        }
    }

    // 画像読み込み
    if args.file != "" {
        println!("load image : {}", args.file);
        let mat = imread(&args.file, opencv::imgcodecs::IMREAD_COLOR)?;
        let mut resized = Mat::default();
        resize(&mat, &mut resized, Size::new(64, 64), 0.0, 0.0, INTER_LINEAR)?;

        for y in 0..64 {
            for x in 0..64 {
                let pixel = resized.at_2d::<Vec3b>(y as i32, x as i32)?;
                img[y][x][0] = pixel[0]; // B
                img[y][x][1] = pixel[1]; // G
                img[y][x][2] = pixel[2]; // R
            }
        }
    }

    // VRAM 書き込み
    for y in 0..64 {
        for x in 0..64 {
            let r = img[y][x][2] as f32 / 255.0f32;
            let g = img[y][x][1] as f32 / 255.0f32;
            let b = img[y][x][0] as f32 / 255.0f32;
            
            // 逆ガンマ補正
            let r = r.powf(2.2);
            let g = g.powf(2.2);
            let b = b.powf(2.2);

            // 10bit 階調で表示
            let r = (r * 1023.0f32) as usize;
            let g = (g * 1023.0f32) as usize;
            let b = (b * 1023.0f32) as usize;
            let v = (r << 20) | (g << 10) | b;
            unsafe {
                uio_vram.write_reg(y*64+x, v);
            }
        }
    }

    // 表示ON
    unsafe {
        uio_reg.write_reg(4, 1);
    }

    println!("done");
    Ok(())
}

