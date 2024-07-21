

use std::rc::Rc;
use std::cell::RefCell;

mod memory;
use memory::*;

mod emulation;
use emulation::*;

use std::fs::File;

fn main() {
    let mut exe_log = File::create("emu_exe_log.txt").expect("file open error");
    let mut mem_log = File::create("emu_mem_log.txt").expect("file open error");

    let mut map = MemoryMap::new();

    let mem = Memory::new(64 * 1024);
    map.add(0x8000_0000, Rc::new(RefCell::new(mem)));

    let prt = MemStdout::new(0x100);
    map.add(0x1000_0000, Rc::new(RefCell::new(prt)));


    map.load_hex32("./mem.hex", 0x8000_0000);

    run_jfive(&mut map, 0x80000000, 100000, &mut exe_log, &mut mem_log, true);
}

