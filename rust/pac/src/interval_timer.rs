#![allow(dead_code)]

use jelly_mem_access::*;

const REG_CONTROL: usize = 0x00;
const REG_COMPARE: usize = 0x01;
const REG_COUNTER: usize = 0x03;

const CONTROL_ENABLE: u8 = 0x01;
const CONTROL_CLEAR: u8 = 0x02;
const CONTROL_IRQ: u8 = 0x04;

pub struct JellyIntervalTimer<T: MemAccess> {
    reg_acc: T,
    wait_irq: Option<fn()>,
}

impl<T: MemAccess> JellyIntervalTimer<T> {
    pub const fn new(reg_acc: T, wait_irq: Option<fn()>) -> Self {
        Self {
            reg_acc: reg_acc,
            wait_irq: wait_irq,
        }
    }

    pub fn set_enable(&self, enable: bool) {
        unsafe {
            self.reg_acc
                .write_reg8(REG_CONTROL, if enable { CONTROL_ENABLE } else { 0 });
        }
    }

    pub fn clear_counter(&self) {
        unsafe {
            let flag = self.reg_acc.read_reg8(REG_CONTROL) | CONTROL_CLEAR;
            self.reg_acc.write_reg8(REG_CONTROL, flag);
        }
    }

    pub fn set_compare_counter(&self, compare: u32) {
        unsafe {
            self.reg_acc.write_reg32(REG_COMPARE, compare);
        }
    }

    pub fn compare_counter(&self) -> u32 {
        unsafe { self.reg_acc.read_reg32(REG_COMPARE) }
    }

    pub fn counter(&self) -> u32 {
        unsafe { self.reg_acc.read_reg32(REG_COUNTER) }
    }

    pub fn polling_timer(&self) -> bool {
        unsafe { (self.reg_acc.read_reg8(REG_CONTROL) & CONTROL_IRQ) != 0 }
    }

    pub fn wait_timer(&self) {
        while !self.polling_timer() {
            match self.wait_irq {
                Some(callback) => callback(),
                _ => (),
            }
        }
    }
}
