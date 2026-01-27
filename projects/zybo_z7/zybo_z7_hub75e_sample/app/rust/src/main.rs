use std::error::Error;

use clap::Parser;
//use jelly_lib::linux_i2c::LinuxI2c;
use jelly_mem_access::*;

use opencv::*;
use opencv::core::*;
use opencv::imgcodecs::imread;
use opencv::imgproc::*;

/// ZYBO Z7 RTCL P3S7 High Speed Camera Application
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(short = 'f', long)]
    file: String,
}

fn main() -> Result<(), Box<dyn Error>> {
//  let args = Args::parse();
    // UIO
    println!("\nuio open");
    let uio_reg  = UioAccessor::<usize>::new_with_name("uio_reg").expect("Failed to open uio");
    let uio_vram = UioAccessor::<usize>::new_with_name("uio_vram").expect("Failed to open uio");
    println!("uio_reg  phys addr : 0x{:x}", uio_reg.phys_addr());
    println!("uio_reg  size      : 0x{:x}", uio_reg.size());
    println!("uio_vram phys addr : 0x{:x}", uio_vram.phys_addr());
    println!("uio_vram size      : 0x{:x}", uio_vram.size());

    println!("ID : {:x}", unsafe{uio_reg.read_reg(0)});

//  let args = Args::parse();
    let mut img = [[[0u8; 3]; 64]; 64];
//  let mat = imread(&args.file, opencv::imgcodecs::IMREAD_COLOR)?;
    let mat = imread("/home/ryuji/Mandrill.bmp", opencv::imgcodecs::IMREAD_COLOR)?;
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

    /*
    for y in 0..64 {
        for x in 0..64 {
            let r = (y + x) as f32 / 127.0f32;
            let g = (y + (63 - x)) as f32 / 127.0f32;
            let b = ((63 - y) + x) as f32 / 127.0f32;
            let r = r * r;
            let g = g * g;
            let b = b * b;
            let r = (r * 1023.0f32) as usize;
            let g = (g * 1023.0f32) as usize;
            let b = (b * 1023.0f32) as usize;
            let v = (b << 20) | (g << 10) | b;
            unsafe {
                uio_vram.write_reg(y*64+x, v);
            }
        }
    }
    */

    println!("done");
    Ok(())
}

