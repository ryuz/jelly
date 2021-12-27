#![no_std]
#![no_main]
#![feature(asm)]
#![feature(const_fn_trait_bound)]
#![feature(const_fn_fn_ptr_basics)]
#![feature(const_mut_refs)]


use core::fmt::{self, Write};
use pudding_pac::arm::cpu;
use core::panic::PanicInfo;

use jelly_rtos::rtos;
use jelly_mem_access::*;
use jelly_pac::communication_pipe::*;
use jelly_pac::interval_timer::*;
use jelly_pac::i2c::*;

mod bootstrap;
//mod communication_pipe;

//mod i2c;
//use i2c::*;

mod mpu9250;
use mpu9250::*;


//#[macro_use]

pub mod uart;
//use uart::*;


#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    println!("\r\n!!!panic!!!");
    loop {}
}


fn wait_irq<const FLGID: rtos::ID, const WAIPTN: rtos::FLGPTN>() {
    rtos::clr_flg(FLGID, !WAIPTN);
    rtos::wai_flg(FLGID, WAIPTN, rtos::WfMode::AndWait);
}

// APUとの通信用 COMパイプ定義
type ComAccessor = MmioAccessor::<u64>;
type ComPipe = JellyCommunicationPipe::<ComAccessor>;
type ComPort = CommunicationPort::<ComPipe, ComPipe>;

//static COM0: ComPipe = ComPipe::new(ComAccessor::new(0x8008_0000, 0x800), Some(wait_irq::<1, 0x01>));
//static COM2: ComPipe = ComPipe::new(ComAccessor::new(0x8008_1000, 0x800), Some(wait_irq::<1, 0x04>));

static COM0: ComPort = ComPort::new(
                            ComPipe::new(ComAccessor::new(0x8008_0000, 0x800), Some(wait_irq::<1, 0x01>)),
                            ComPipe::new(ComAccessor::new(0x8008_0800, 0x800), Some(wait_irq::<1, 0x02>)));
static COM1: ComPort = ComPort::new(
                            ComPipe::new(ComAccessor::new(0x8008_1000, 0x800), Some(wait_irq::<1, 0x04>)),
                            ComPipe::new(ComAccessor::new(0x8008_1800, 0x800), Some(wait_irq::<1, 0x08>)));
    

// COM0 に print! を割り当て
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
            COM0.putc(c as u8);
        }
        Ok(())
    }
}


// main
#[no_mangle]
pub unsafe extern "C" fn main() -> ! {
    wait(10000000);
    println!("\nJelly-RTOS start\n");
    wait(10000);
    uart::uart_puts("run mpu9250 sample\r\n");

//  memdump(0x80000000, 16);

    rtos::initialize(0x80000000);

    rtos::ena_extflg(1, 0x3f);

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


extern "C" fn task1() -> ! {
    println!("Task Start");

    // timer
    type TimAccessor = PhysAccessor<u64, 0x8040_0000, 0x100>;
    let  tim = JellyIntervalTimer::<TimAccessor>::new(TimAccessor::new(), Some(wait_irq::<1, 0x10>));
    tim.set_compare_counter(250000-1);  // 1kHz
    tim.set_enable(true);

    // PhysAccessor を使う場合
    type I2cAccessor = PhysAccessor<u64, 0x8080_0000, 0x100>;
//  let  i2c = i2c::JellyI2c::<I2cAccessor, 1, 0x20>::new(I2cAccessor::new().into());
    let  i2c = JellyI2c::<I2cAccessor>::new(I2cAccessor::new().into(), Some(wait_irq::<1, 0x20>));
    
    // MmioAccessor を使う場合
//  let i2c_acc = MmioAccessor::<u64>::new(0x8080_0000, 0x100);
//  let i2c = i2c::JellyI2c::<MmioAccessor<u64>, 1, 0x20>::new(i2c_acc);

    i2c.set_divider(50 - 1);
    
    let imu = Mpu9250::new(i2c);

    println!("WHO_AM_I(exp:0x71):0x{:02x}", imu.read_who_am_i());

    let mut times: i32 = 0;
    while !COM0.polling_rx() {
        tim.wait_timer();
        let data = imu.read_sensor_data();
        
        if times % 1000 == 0 {
            println!("accel0      : {}", data.accel[0]     );
            println!("accel1      : {}", data.accel[1]     );
            println!("accel2      : {}", data.accel[2]     );
            println!("gyro0       : {}", data.gyro[0]      );
            println!("gyro1       : {}", data.gyro[1]      );
            println!("gyro2       : {}", data.gyro[2]      );
            println!("temperature : {}\n", data.temperature);
        }

        let data: [u8; 14] = unsafe { core::mem::transmute(data) };
        COM1.write(&data);
        
//      rtos::dly_tsk(1000000 / 100);

        times += 1;
    }

    uart::uart_puts("[END] mpu9250 sample\r\n");
    loop{}
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
