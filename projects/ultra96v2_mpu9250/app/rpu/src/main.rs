#![no_std]
#![no_main]
#![feature(asm)]
#![feature(const_fn_trait_bound)]
#![feature(const_fn_fn_ptr_basics)]
#![feature(const_mut_refs)]
//#![feature(min_const_generics)]


use core::fmt::{self, Write};
use pudding_pac::arm::cpu;
use core::panic::PanicInfo;
mod bootstrap;
mod i2c;
mod communication_pipe;

use jelly_rtos::rtos;
use jelly_mem_access::*;
use communication_pipe::*;


//#[macro_use]
//pub mod uart;
//use uart::*;


#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    println!("\r\n!!!panic!!!");
    loop {}
}


static mut COM0:JellyCommunicationPipe::<MmioRegion, u64> = JellyCommunicationPipe::<MmioRegion, u64>::new(mmio_accesor_new::<u64>(0x8008_0000, 0x800));


#[macro_export]
macro_rules! print {
    ($($arg:tt)*) => ($crate::_print(format_args!($($arg)*)));
}

#[macro_export]
macro_rules! println {
    ($fmt:expr) => (print!(concat!($fmt, "\n")));
    ($fmt:expr, $($arg:tt)*) => (print!(concat!($fmt, "\n"), $($arg)*));
}

pub fn _print(args: fmt::Arguments) {
    let mut writer = ComWriter {};
    writer.write_fmt(args).unwrap();
}

struct ComWriter;

impl Write for ComWriter {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for c in s.bytes() {
            unsafe{COM0.putc(c as u8)};
        }
        Ok(())
    }
}


fn com0_wait_tx(com: &mut JellyCommunicationPipe::<MmioRegion, u64>)
{
    rtos::clr_flg(1, !0x01);
    com.set_irq_tx_enable(true);
    rtos::wai_flg(1, 0x01, rtos::WfMode::AndWait);
    com.set_irq_tx_enable(false);
}


// main
#[no_mangle]
pub unsafe extern "C" fn main() -> ! {
    wait(10000000);
    println!("\nJelly-RTOS start\n");
    wait(10000);

    COM0.set_wait_tx(Some(com0_wait_tx));

//  memdump(0x80000000, 16);

//  let acc_peri = mmio_accesor_new::<usize>(0x80000000, 0x10000000);
//  let acc_com = acc_peri.clone64(0x08_0000, 0x1000);
//  let acc_i2c = acc_peri.clone64(0x80_0000, 0x1000);
//  let acc_led = acc_peri.clone64(0x88_0000, 0x1000);
//  println!("rtos core_id      : 0x{:08x}", acc_peri.read_reg(0));
//  println!("com  core_id      : 0x{:08x}", acc_com.read_reg(0));

    rtos::initialize(0x80000000);

    rtos::ena_extflg(1, 0x1f);

    println!("core_id      : 0x{:08x}", rtos::core_id     ());
    println!("core_version : 0x{:08x}", rtos::core_version());
    println!("core_date    : 0x{:08x}", rtos::core_date   ());
    println!("clock_rate   : {}", rtos::clock_rate  ());
    println!("max_tskid    : {}", rtos::max_tskid   ());
    println!("max_semid    : {}", rtos::max_semid   ());
    println!("max_flgid    : {}", rtos::max_flgid   ());
    println!("tskpri_width : {}", rtos::tskpri_width());
    println!("semcnt_width : {}", rtos::semcnt_width());
    println!("flgptn_width : {}", rtos::flgptn_width());
    println!("systim_width : {}", rtos::systim_width());
    println!("reltim_width : {}", rtos::reltim_width());

    // 時間単位を us 単位にする
    let pscl:u32 = rtos::clock_rate() / 1000000 - 1;
    println!("set_pscl({})\n", pscl);
    rtos::set_pscl(pscl);

    // タスクスタート
    static mut STACK1: [u8; 4096] = [0; 4096];
    rtos::cre_tsk(1, &mut STACK1, task1);
    rtos::wup_tsk(1);

    // アイドルループ
    loop {
        cpu::wfi();
    }
}


const MPU9250_ADDRESS: u8 =     0x68;    // 7bit address
//const AK8963_ADDRESS: u8 =      0x0C;    // Address of magnetometer

extern "C" fn task1() -> ! {
    println!("Task Start");
    
    let i2c_acc = mmio_accessor::mmio_accesor_new::<u64>(0x80800000, 0x100);
    let i2c = i2c::JellyI2c::<MmioRegion, u64, 1, 0x10>::new(i2c_acc);
    i2c.set_divider(50 - 1);
    
    i2c.write(MPU9250_ADDRESS, &[0x75]);
    let mut who_am_i: [u8; 1] = [0u8; 1];
    i2c.read(MPU9250_ADDRESS, &mut who_am_i);
    println!("WHO_AM_I(exp:0x71):0x{:02x}", who_am_i[0]);

    // 起動
    i2c.write(MPU9250_ADDRESS, &[0x6b, 0x00]);
    i2c.write(MPU9250_ADDRESS, &[0x37, 0x02]);

    loop {
        let mut buf = [0u8; 14];
        i2c.write(MPU9250_ADDRESS, &[0x3b]);
        i2c.read(MPU9250_ADDRESS, &mut buf);
        
        let accel0       = ((buf[ 0] as i16) << 8) | (buf[ 1] as i16);
        let accel1       = ((buf[ 2] as i16) << 8) | (buf[ 3] as i16);
        let accel2       = ((buf[ 4] as i16) << 8) | (buf[ 5] as i16);
        let temperature  = ((buf[ 6] as i16) << 8) | (buf[ 7] as i16);
        let gyro0        = ((buf[ 8] as i16) << 8) | (buf[ 9] as i16);
        let gyro1        = ((buf[10] as i16) << 8) | (buf[11] as i16);
        let gyro2        = ((buf[12] as i16) << 8) | (buf[13] as i16);
        println!("accel0      : {}", accel0     );
        println!("accel1      : {}", accel1     );
        println!("accel2      : {}", accel2     );
        println!("gyro0       : {}", gyro0      );
        println!("gyro1       : {}", gyro1      );
        println!("gyro2       : {}", gyro2      );
        println!("temperature : {}\n", temperature);

        rtos::dly_tsk(1000000);
    }
}


// ループによるウェイト
fn wait(n: i32) {
    let mut v: i32 = 0;
    for i in 1..n {
        unsafe { core::ptr::write_volatile(&mut v, i) };
    }
}


#[allow(dead_code)]
pub fn memdump(addr: usize, len: usize) {
    unsafe {
        for offset in 0..len {
            if offset % 4 == 0 {
                print!("{:08X}:", addr + offset * 4);
            }
            print!(
                " {:08X}",
                core::ptr::read_volatile((addr + offset * 4) as *mut u32)
            );
            if offset % 4 == 3 || offset + 1 == len {
                println!("");
            }
        }
    }
}
