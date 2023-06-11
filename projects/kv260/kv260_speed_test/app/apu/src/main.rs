#![allow(dead_code)]

use jelly_mem_access::*;

fn read_test(acc: &mut UioAccessor<usize>) {
    for _i in 0..64 {
        unsafe {
            let _ = acc.read_reg32(0);
        }
    }
}

fn write_test(acc: &mut UioAccessor<usize>) {
    for i in 0..64 {
        unsafe {
            acc.write_reg32(0, i);
        }
    }
}

fn read_write(acc: &mut UioAccessor<usize>) {
    for _i in 0..64 {
        unsafe {
            let v = acc.read_reg32(0);
            acc.write_reg32(0, v + 1);
        }
    }
}

fn acc_test(acc: &mut UioAccessor<usize>) {
    read_write(acc);
    read_test(acc);
    write_test(acc);
}

fn main() {
    println!("--- speed_test ---");

    // mmap uio
    println!("\nuio open");
    let mut uio_fpd0_acc =
        UioAccessor::<usize>::new_with_name("uio_pl_fpd0").expect("Failed to open uio");
    let mut uio_fpd1_acc =
        UioAccessor::<usize>::new_with_name("uio_pl_fpd1").expect("Failed to open uio");
    let mut uio_lpd0_acc =
        UioAccessor::<usize>::new_with_name("uio_pl_lpd0").expect("Failed to open uio");
    println!("uio_fpd0 phys addr : 0x{:x}", uio_fpd0_acc.phys_addr());
    println!("uio_fpd1 phys addr : 0x{:x}", uio_fpd1_acc.phys_addr());
    println!("uio_lpd0 phys addr : 0x{:x}", uio_lpd0_acc.phys_addr());
    println!("uio_fpd0 size      : 0x{:x}", uio_fpd0_acc.size());
    println!("uio_fpd1 size      : 0x{:x}", uio_fpd1_acc.size());
    println!("uio_lpd0 size      : 0x{:x}", uio_lpd0_acc.size());

    acc_test(&mut uio_fpd0_acc);
    acc_test(&mut uio_fpd1_acc);
    acc_test(&mut uio_lpd0_acc);
}
