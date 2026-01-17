

//use std::fs::File;
//use std::io::{self, BufRead, BufReader};
use std::io::Result;
use jelly_mem_access::*;


fn main() -> Result<()> {
    println!("Hello JFive");

    // UIOを開く
    let uio_acc = UioAccessor::<u32>::new_with_name("uio_pl_peri").expect("Failed to open uio");

    // UIOの中をさらにコアごとに割り当て
    let jfive_ctl = uio_acc.subclone(0x00000000, 0x04000);
    let jfive_mem = uio_acc.subclone(0x00100000, 0x10000);
    
    // コア停止
    unsafe{jfive_ctl.write_reg_u32(4, 0)};

    // ID確認
    println!("CORE_ID  : 0x{:08x}", unsafe{jfive_ctl.read_reg_u32(0x00)});
    println!("CORE_VER : 0x{:08x}", unsafe{jfive_ctl.read_reg_u32(0x01)});

    // 16進数のテキストファイルを１行づつ読み込んでメモリに書き込む
    let mut addr = 0x00000000;
    /*
    let file = File::open("../../jfive/jfive_sample.hex")?;
    let reader = BufReader::new(file);
    for line in reader.lines() {
        let line = line?;
        let data = u32::from_str_radix(&line, 16).unwrap();
        unsafe { jfive_mem.write_mem_u32(addr, data); }
        addr += 4;
        if addr >= 0x4000 { break; }
    }
    */

    let jfive_bin = include_bytes!("../jfive_sample.bin");
    for chunk in jfive_bin.chunks(4) {
        let data = u32::from_le_bytes([chunk[0], chunk[1], chunk[2], chunk[3]]);
        unsafe { jfive_mem.write_mem_u32(addr, data); }
        addr += 4;
    }

    // コア動作開始
    unsafe{jfive_ctl.write_reg_u32(4, 1)};
    println!("JFive started.");

    Ok(())
}
