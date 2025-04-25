#![allow(unused)]

const LK_ACC_BASE: usize = 0xa0410000;

const REG_IMG_LK_ACC_CORE_ID: usize = 0x00;
const REG_IMG_LK_ACC_CORE_VERSION: usize = 0x01;
const REG_IMG_LK_ACC_CTL_CONTROL: usize = 0x04;
const REG_IMG_LK_ACC_CTL_STATUS: usize = 0x05;
const REG_IMG_LK_ACC_CTL_INDEX: usize = 0x07;
const REG_IMG_LK_ACC_IRQ_ENABLE: usize = 0x08;
const REG_IMG_LK_ACC_IRQ_STATUS: usize = 0x09;
const REG_IMG_LK_ACC_IRQ_CLR: usize = 0x0a;
const REG_IMG_LK_ACC_IRQ_SET: usize = 0x0b;
const REG_IMG_LK_ACC_PARAM_X: usize = 0x10;
const REG_IMG_LK_ACC_PARAM_Y: usize = 0x11;
const REG_IMG_LK_ACC_PARAM_WIDTH: usize = 0x12;
const REG_IMG_LK_ACC_PARAM_HEIGHT: usize = 0x13;
const REG_IMG_LK_ACC_ACC_VALID: usize = 0x40;
const REG_IMG_LK_ACC_ACC_READY: usize = 0x41;
const REG_IMG_LK_ACC_ACC_GXX0: usize = 0x42;
const REG_IMG_LK_ACC_ACC_GXX1: usize = 0x43;
const REG_IMG_LK_ACC_ACC_GYY0: usize = 0x44;
const REG_IMG_LK_ACC_ACC_GYY1: usize = 0x45;
const REG_IMG_LK_ACC_ACC_GXY0: usize = 0x46;
const REG_IMG_LK_ACC_ACC_GXY1: usize = 0x47;
const REG_IMG_LK_ACC_ACC_EX0: usize = 0x48;
const REG_IMG_LK_ACC_ACC_EX1: usize = 0x49;
const REG_IMG_LK_ACC_ACC_EY0: usize = 0x4a;
const REG_IMG_LK_ACC_ACC_EY1: usize = 0x4b;
const REG_IMG_LK_ACC_OUT_VALID: usize = 0x60;
const REG_IMG_LK_ACC_OUT_READY: usize = 0x61;
const REG_IMG_LK_ACC_OUT_DX0: usize = 0x64;
const REG_IMG_LK_ACC_OUT_DX1: usize = 0x65;
const REG_IMG_LK_ACC_OUT_DY0: usize = 0x66;
const REG_IMG_LK_ACC_OUT_DY1: usize = 0x67;

// レジスタ書き込み
fn wrtie_reg(reg: usize, data: i64) {
    let p = (LK_ACC_BASE + 8 * reg) as *mut i64;
    unsafe {
        core::ptr::write_volatile(p, data);
    }
}

// レジスタ読み出し
fn read_reg(reg: usize) -> i64 {
    let p = (LK_ACC_BASE + 8 * reg) as *const i64;
    unsafe { core::ptr::read_volatile(p) }
}

pub fn get_id() -> u64 {
    read_reg(REG_IMG_LK_ACC_CORE_ID) as u64
}

pub fn get_version() -> u64 {
    read_reg(REG_IMG_LK_ACC_CORE_VERSION) as u64
}

pub fn get_irq_status() -> u64 {
    read_reg(REG_IMG_LK_ACC_IRQ_STATUS) as u64
}

pub fn get_acc_valid() -> u64 {
    read_reg(REG_IMG_LK_ACC_IRQ_STATUS) as u64
}

pub fn start() {
    wrtie_reg(REG_IMG_LK_ACC_IRQ_ENABLE, 0x1); // IRQ enable
}

pub fn stop() {
    wrtie_reg(REG_IMG_LK_ACC_IRQ_ENABLE, 0x0); // IRQ disaable
}

pub fn irq_handler() {
    // 読み出し
    let gx2 = read_reg(REG_IMG_LK_ACC_ACC_GXX0) as f64;
    let gy2 = read_reg(REG_IMG_LK_ACC_ACC_GYY0) as f64;
    let gxy = read_reg(REG_IMG_LK_ACC_ACC_GXY0) as f64;
    let ex = read_reg(REG_IMG_LK_ACC_ACC_EX0) as f64;
    let ey = read_reg(REG_IMG_LK_ACC_ACC_EY0) as f64;
    wrtie_reg(REG_IMG_LK_ACC_ACC_READY, 0x1);
    wrtie_reg(REG_IMG_LK_ACC_IRQ_CLR, 0x1);

    // 計算
    let det = gx2 * gy2 - gxy * gxy;
    let dx = 64.0 * -(gx2 * ex - gxy * ey) / det;
    let dy = 64.0 * -(gy2 * ey - gxy * ex) / det;

    /*
    unsafe {
        static mut irq_count: u32 = 0;
        irq_count += 1;
        if irq_count % 1000 == 0 {
            println!("dx : {}  dy : {}", dx, dy);
        }
    }
    */

    // 固定小数点化
    let dx = (dx.min(255.0).max(-255.0) * 65536.0) as i64;
    let dy = (dy.min(255.0).max(-255.0) * 65536.0) as i64;

    // 書き込み
    wrtie_reg(REG_IMG_LK_ACC_OUT_DX0, dx);
    wrtie_reg(REG_IMG_LK_ACC_OUT_DY0, dy);
    wrtie_reg(REG_IMG_LK_ACC_OUT_VALID, 0x1);
}
