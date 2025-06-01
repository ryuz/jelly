#![allow(dead_code)]
#![no_main]
#![no_std]

#[macro_use]
mod uart;
use uart::*;

//mod i2c_access_imx219;
//mod i2c_imx219;
mod imx219_control;
use imx219_control::Imx219Control;

use jelly_mem_access::*;
use jelly_pac::i2c::*;


use core::panic::PanicInfo;

#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {}
}

const REG_LED: usize  = 0x10000100;
const REG_GPIO: usize = 0x10000104;
const IMX219_DEVADR: u8 =     0x10;    // 7bit address

const CMD_MAX_LEN: usize = 64;


// カメラ電源ON
fn camera_power_on() {
    wrtie_reg(REG_GPIO, 1); // GPIOピンをHIGHに設定
    cpu_wait();
}

// カメラ電源OFF
fn camera_power_off() {
    wrtie_reg(REG_GPIO, 0); // GPIOピンをLOWに設定
    cpu_wait();
}



#[no_mangle]
#[allow(improper_ctypes_definitions)]
pub unsafe extern "C" fn main() -> Result<(), &'static str> {
    println!("start");

    // I2Cアクセサの初期化
    type I2cAccessor = PhysAccessor<u32, 0x10000200, 0x100>;
    let  i2c = JellyI2c::<I2cAccessor>::new(I2cAccessor::new().into(), None);

    // カメラリセット
    camera_power_off();
    camera_power_on();

    // I2C アクセステスト(IDを読んでみる)
    let mut model_id: [u8; 2] = [0u8; 2];
    i2c.write(IMX219_DEVADR, &[0x00, 0x00]);
    i2c.read(IMX219_DEVADR, &mut model_id);
    println!("model_id: 0x{:02x}{:02x}", model_id[0], model_id[1]);

    // IMX219 制御生成
    let mut imx219 = Imx219Control::new();

    // リセット
    println!("reset");
    imx219.reset()?;

    // カメラID取得
    println!("sensor model ID:{:04x}", imx219.get_model_id().unwrap());

    // camera 設定
    let pixel_clock: f64 = 91000000.0;
    let binning: bool = true;
    let width: i32 = 1280;// / 2;
    let height: i32 = 720;// / 2;
    let aoi_x: i32 = -1;
    let aoi_y: i32 = -1;
    imx219.set_pixel_clock(pixel_clock)?;
    imx219.set_aoi(width, height, aoi_x, aoi_y, binning, binning)?;
    imx219.start()?;

    // 設定
    let frame_rate: f64 = 30.0;
    let exposure: f64 = 0.015;
    let a_gain: f64 = 20.0;
    let d_gain: f64 = 0.0;
    let flip_h: bool = false;
    let flip_v: bool = false;
    imx219.set_frame_rate(frame_rate)?;
    imx219.set_exposure_time(exposure)?;
    imx219.set_gain(a_gain)?;
    imx219.set_digital_gain(d_gain)?;
    imx219.set_flip(flip_h, flip_v)?;

//  let id = imx219.get_model_id()?;
//  println!("model_id: 0x{:04x}", id);

    // カメラ設定完了
    imx219.setup()?;
    println!("camera setup done");

    // コマンドプロンプト
    loop {
        // コマンド入力
        let mut cmd_buf = [0u8; CMD_MAX_LEN];
        let cmd_len = command_input(&mut cmd_buf);
        let com_str = core::str::from_utf8(&cmd_buf[0..cmd_len]).unwrap_or("INVALID_UTF8");
 //     println!("command: {}", com_str);
 
 
        let mut tokens: [&str; 3] = ["", "", ""];
        let mut idx = 0;
        for part in com_str.trim().split_whitespace() {
            if idx < 3 {
                tokens[idx] = part;
                idx += 1;
            } else {
                break;
            }
        }
        if tokens[0].is_empty() {
            continue;
        }
        match tokens[0] {
            "help" => {
                println!("Available commands:");
                println!("  help - Show this help message");
                println!("  i2cw8  <addr> <8bit  data> - Write <8bit data> to I2C address <addr>");
                println!("  i2cw16 <addr> <16bit data> - Write <16bit <data> to I2C address <addr>");
                println!("  i2cr8  <addr> - Read 8bit data from I2C address <addr>");
                println!("  i2cr16 <addr> - Read 16bit data from I2C address <addr>");
                println!("  cam on     - Turn camera power ON");
                println!("  cam off    - Turn camera power OFF");
                // 他のコマンドもここに追加
            },
            "i2cw8" => {
                if !tokens[1].is_empty() && !tokens[2].is_empty() {
                    let addr = tokens[1].parse::<u16>().or_else(|_| u16::from_str_radix(tokens[1].trim_start_matches("0x"), 16)).unwrap_or(0);
                    let data = tokens[2].parse::<u8>().or_else(|_| u8::from_str_radix(tokens[2].trim_start_matches("0x"), 16)).unwrap_or(0);
                    imx219.i2c_write_u8(addr, data).unwrap_or_else(|e| {
                        println!("I2C write error: {}", e);
                    });
                    println!("I2C write: addr=0x{:02x} data=0x{:02x}", addr, data);
                } else {
                    println!("Usage: i2cw8 <addr> <data>");
                }
            },
            "i2cw16" => {
                if !tokens[1].is_empty() && !tokens[2].is_empty() {
                    let addr = tokens[1].parse::<u16>().or_else(|_| u16::from_str_radix(tokens[1].trim_start_matches("0x"), 16)).unwrap_or(0);
                    let data = tokens[2].parse::<u16>().or_else(|_| u16::from_str_radix(tokens[2].trim_start_matches("0x"), 16)).unwrap_or(0);
                    imx219.i2c_write_u16(addr, data).unwrap_or_else(|e| {
                        println!("I2C write error: {}", e);
                    });
                    println!("I2C write: addr=0x{:02x} data=0x{:02x}", addr, data);
                } else {
                    println!("Usage: i2cw16 <addr> <data>");
                }
            },
            "i2cr8" => {
                if !tokens[1].is_empty() {
                    let addr = tokens[1].parse::<u16>().or_else(|_| u16::from_str_radix(tokens[1].trim_start_matches("0x"), 16)).unwrap_or(0);
                    match imx219.i2c_read_u8(addr) {
                        Ok(data) => println!("I2C read: addr=0x{:02x} data=0x{:02x}", addr, data),
                        Err(e) => println!("I2C read error: {}", e),
                    }
                } else {
                    println!("Usage: i2cr8 <addr>");
                }
            },
            "i2cr16" => {
                if !tokens[1].is_empty() {
                    let addr = tokens[1].parse::<u16>().or_else(|_| u16::from_str_radix(tokens[1].trim_start_matches("0x"), 16)).unwrap_or(0);
                    match imx219.i2c_read_u16(addr) {
                        Ok(data) => println!("I2C read: addr=0x{:02x} data=0x{:04x}", addr, data),
                        Err(e) => println!("I2C read error: {}", e),
                    }
                } else {
                    println!("Usage: i2cr16 <addr>");
                }
            },
            "cam" if tokens[1] == "on" => {
                camera_power_on();
                println!("Camera power ON");
            },
            "cam" if tokens[1] == "off" => {
                camera_power_off();
                println!("Camera power OFF");
            },
            _ => {
                println!("Unknown command: {}", com_str);
            }
        }
    }
}


fn cpu_wait() {
    let mut v = 0;
    let p = &mut v as *mut i32;
    for i in 0..100000 {
        unsafe {
            core::ptr::write_volatile(p, i);
        }
    }
}


// レジスタ書き込み
#[allow(dead_code)]
fn wrtie_reg(adr: usize, data: u32) {
    let p = adr as *mut u32;
    unsafe {
        core::ptr::write_volatile(p, data);
    }
}

// レジスタ読み出し
#[allow(dead_code)]
fn read_reg(adr: usize) -> u32 {
    let p = adr as *mut u32;
    unsafe { core::ptr::read_volatile(p) }
}



fn command_input(command_buffer: &mut [u8; CMD_MAX_LEN]) -> usize
{
    loop {
        let mut buffer_idx = 0;
        print!("> ");
        loop {
            let c = uart_getc();
            match c {
                b'\r' | b'\n' => {
                    uart_putc(b'\r');
                    uart_putc(b'\n');
                    if buffer_idx > 0 {
                        return buffer_idx;
                    }
                    break;
                },
                0x7F | 0x08 => { // Backspace (ASCII DEL or BS)
                    if buffer_idx > 0 {
                        buffer_idx -= 1;
                        uart_putc(0x08); // カーソルを戻す
                        uart_putc(b' '); // 文字を消す
                        uart_putc(0x08); // カーソルを戻す
                    }
                },
                _ => { // その他の文字はバッファに格納し、エコーバック
                    if buffer_idx < command_buffer.len() {
                        command_buffer[buffer_idx] = c;
                        buffer_idx += 1;
                        uart_putc(c); // エコーバック
                    }
                }
            }
        }
    }
}


/*
fn process_command(imx219 : &mut Imx219Control, command: &str) {
    // コマンドを処理するロジックをここに実装
    // Vecが使えないため、split_whitespaceで最大3個まで手動で分割
    let mut tokens: [&str; 3] = ["", "", ""];
    let mut idx = 0;
    for part in command.trim().split_whitespace() {
        if idx < 3 {
            tokens[idx] = part;
            idx += 1;
        } else {
            break;
        }
    }
    if tokens[0].is_empty() {
        return;
    }
    match tokens[0] {
        "help" => {
            println!("Available commands:");
            println!("  help - Show this help message");
            println!("  i2cw <addr> <data> - Write 8bit <data> to I2C address <addr>");
            // 他のコマンドもここに追加
        },
        "i2cw" => {
            if !tokens[1].is_empty() && !tokens[2].is_empty() {
                let addr = tokens[1].parse::<u8>().or_else(|_| u8::from_str_radix(tokens[1].trim_start_matches("0x"), 16)).unwrap_or(0);
                let data = tokens[2].parse::<u8>().or_else(|_| u8::from_str_radix(tokens[2].trim_start_matches("0x"), 16)).unwrap_or(0);
                imx219.i2c_write_u8(addr, data).unwrap_or_else(|e| {
                    println!("I2C write error: {}", e);
                });
                println!("I2C write: addr=0x{:02x} data=0x{:02x}", addr, data);
            } else {
                println!("Usage: i2cw <addr> <data>");
            }
        },
        _ => {
            println!("Unknown command: {}", command);
        }
    }
}
*/