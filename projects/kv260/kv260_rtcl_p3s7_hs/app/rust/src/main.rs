#![allow(unused)]

use std::error::Error;
//use std::thread;
//use std::time::Duration;

use jelly_lib::{i2c_access::I2cAccess, linux_i2c::LinuxI2c};
use jelly_mem_access::*;
use jelly_pac::video_dma_control::VideoDmaControl;

const CAMREG_CORE_ID: u16 = 0x0000;
const CAMREG_CORE_VERSION: u16 = 0x0001;
const CAMREG_RECV_RESET: u16 = 0x0010;
const CAMREG_ALIGN_RESET: u16 = 0x0020;
const CAMREG_ALIGN_PATTERN: u16 = 0x0022;
const CAMREG_ALIGN_STATUS: u16 = 0x0028;
const CAMREG_DPHY_CORE_RESET: u16 = 0x0080;
const CAMREG_DPHY_SYS_RESET: u16 = 0x0081;
const CAMREG_DPHY_INIT_DONE: u16 = 0x0088;

const SYSREG_ID: usize = 0x0000;
const SYSREG_DPHY_SW_RESET: usize = 0x0001;
const SYSREG_CAM_ENABLE: usize = 0x0002;
const SYSREG_CSI_DATA_TYPE: usize = 0x0003;
const SYSREG_DPHY_INIT_DONE: usize = 0x0004;
const SYSREG_FPS_COUNT: usize = 0x0006;
const SYSREG_FRAME_COUNT: usize = 0x0007;
const SYSREG_IMAGE_WIDTH: usize = 0x0008;
const SYSREG_IMAGE_HEIGHT: usize = 0x0009;
const SYSREG_BLACK_WIDTH: usize = 0x000a;
const SYSREG_BLACK_HEIGHT: usize = 0x000b;

const TIMGENREG_CORE_ID: usize = 0x0000;
const TIMGENREG_CORE_VERSION: usize = 0x0001;
const TIMGENREG_CTL_CONTROL: usize = 0x0004;
const TIMGENREG_CTL_STATUS: usize = 0x0005;
const TIMGENREG_CTL_TIMER: usize = 0x0008;
const TIMGENREG_PARAM_PERIOD: usize = 0x0010;
const TIMGENREG_PARAM_TRIG0_START: usize = 0x0020;
const TIMGENREG_PARAM_TRIG0_END: usize = 0x0021;
const TIMGENREG_PARAM_TRIG0_POL: usize = 0x0022;

fn main() -> Result<(), Box<dyn Error>> {
    println!("Hello, world!");

    // UIO
    println!("\nuio open");
    let uio_acc = UioAccessor::<usize>::new_with_name("uio_pl_peri").expect("Failed to open uio");
    println!("uio_pl_peri phys addr : 0x{:x}", uio_acc.phys_addr());
    println!("uio_pl_peri size      : 0x{:x}", uio_acc.size());

    let reg_sys = uio_acc.subclone(0x00000000, 0x400);
    let reg_timgen = uio_acc.subclone(0x00010000, 0x400);
    let reg_fmtr = uio_acc.subclone(0x00100000, 0x400);
    let reg_wdma_img = uio_acc.subclone(0x00210000, 0x400);
    let reg_wdma_blk = uio_acc.subclone(0x00220000, 0x400);

    println!("CORE ID");
    println!("reg_sys      : {:08x}", unsafe { reg_sys.read_reg(0) });
    println!("reg_timgen   : {:08x}", unsafe { reg_timgen.read_reg(0) });
    println!("reg_fmtr     : {:08x}", unsafe { reg_fmtr.read_reg(0) });
    println!("reg_wdma_img : {:08x}", unsafe { reg_wdma_img.read_reg(0) });

    let mut cam = RtclP3s7Cmd::new("/dev/i2c-6")?;

    println!(
        "Spartan-7 CORE_ID      : {:08x}",
        cam.read_s7_reg(CAMREG_CORE_ID)?
    );
    println!(
        "Spartan-7 CORE_VERSION : {:08x}",
        cam.read_s7_reg(CAMREG_CORE_VERSION)?
    );

    // 受信側 DPHY リセット
    unsafe {
        reg_sys.write_reg(SYSREG_DPHY_SW_RESET, 1);
    }

    // カメラ板初期化
    unsafe {
        reg_sys.write_reg(SYSREG_CAM_ENABLE, 0);
    } // センサー電源OFF
    cam.write_s7_reg(CAMREG_DPHY_CORE_RESET, 1); // 受信側 DPHY リセット
    cam.write_s7_reg(CAMREG_DPHY_SYS_RESET, 1); // 受信側 DPHY リセット
    std::thread::sleep(std::time::Duration::from_millis(10));

    // 受信側 DPHY 解除 (必ずこちらを先に解除)
    unsafe {
        reg_sys.write_reg(SYSREG_DPHY_SW_RESET, 0);
    }

    // センサー電源ON
    unsafe {
        reg_sys.write_reg(SYSREG_CAM_ENABLE, 1);
    }
    std::thread::sleep(std::time::Duration::from_millis(10));

    // センサー基板 DPHY-TX リセット解除
    cam.write_s7_reg(CAMREG_DPHY_CORE_RESET, 0)?;
    cam.write_s7_reg(CAMREG_DPHY_SYS_RESET, 0)?;
    std::thread::sleep(std::time::Duration::from_millis(10));
    let dphy_tx_init_done = cam.read_s7_reg(CAMREG_DPHY_INIT_DONE)?;
    if dphy_tx_init_done == 0 {
        eprintln!("!!ERROR!! CAM DPHY TX init_done = 0");
        return Err("CAM DPHY TX init_done = 0".into());
    }

    // ここで RX 側も init_done が来る
    let dphy_rx_init_done = unsafe { reg_sys.read_reg(SYSREG_DPHY_INIT_DONE) };
    if dphy_rx_init_done == 0 {
        eprintln!("!!ERROR!! KV260 DPHY RX init_done = 0");
        return Err("KV260 DPHY RX init_done = 0".into());
    }

    let width = 256;
    let height = 256;

    // カメラOFF
    unsafe { reg_sys.write_reg(SYSREG_CAM_ENABLE, 0) };
    std::thread::sleep(std::time::Duration::from_millis(10));
    Ok(())
}

struct RtclP3s7Cmd {
    i2c: LinuxI2c,
}

impl RtclP3s7Cmd {
    pub fn new(devname: &str) -> Result<Self, Box<dyn Error>> {
        Ok(RtclP3s7Cmd {
            i2c: LinuxI2c::new(devname, 0x10)?,
        })
    }

    pub fn write_s7_reg(&mut self, addr: u16, data: u16) -> Result<(), Box<dyn Error>> {
        let addr = (addr << 1) | 1;
        let buf: [u8; 4] = [
            ((addr >> 8) & 0xff) as u8,
            ((addr >> 0) & 0xff) as u8,
            ((data >> 8) & 0xff) as u8,
            ((data >> 0) & 0xff) as u8,
        ];
        self.i2c.write(&buf)?;
        Ok(())
    }

    pub fn read_s7_reg(&mut self, addr: u16) -> Result<u16, Box<dyn Error>> {
        let addr = (addr << 1);
        let wbuf: [u8; 4] = [((addr >> 8) & 0xff) as u8, ((addr >> 0) & 0xff) as u8, 0, 0];
        self.i2c.write(&wbuf)?;
        let mut rbuf: [u8; 2] = [0; 2];
        self.i2c.read(&mut rbuf)?;
        Ok(rbuf[0] as u16 | ((rbuf[1] as u16) << 8))
    }

    pub fn write_p3_spi(&mut self, addr: u16, data: u16) -> Result<(), Box<dyn Error>> {
        let addr = addr | (1 << 14);
        self.write_s7_reg(addr, data)
    }

    pub fn read_p3_spi(&mut self, addr: u16, data: u16) -> Result<(u16), Box<dyn Error>> {
        let addr = addr | (1 << 14);
        self.read_s7_reg(addr)
    }
}
